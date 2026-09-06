#include "centerclient.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDBusPendingCallWatcher>
#include <QDBusVariant>
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonParseError>

namespace {
constexpr auto kService = "org.msilinux.Center";
constexpr auto kPath = "/org/msilinux/Center";
constexpr auto kDeviceIface = "org.msilinux.Center1.Device";
constexpr auto kSensorsIface = "org.msilinux.Center1.Sensors";

// Daemon JSON properties are serde-encoded. Object/array values arrive as
// JSON documents; plain string fields arrive as quoted JSON strings, which
// QJsonDocument cannot represent (object/array only), so strip the quotes.
QString plainString(const QString &json) {
    QString s = json.trimmed();
    if (s.size() >= 2 && s.startsWith(QLatin1Char('"'))
        && s.endsWith(QLatin1Char('"'))) {
        s = s.mid(1, s.size() - 2);
    }
    return s;
}
} // namespace

CenterClient::CenterClient(QObject *parent) : QObject(parent) {
    m_timer.setInterval(2000);
    connect(&m_timer, &QTimer::timeout, this, &CenterClient::refreshNow);
    QTimer::singleShot(0, this, [this] { start(); });
}

void CenterClient::start() {
    QDBusConnection bus = QDBusConnection::systemBus();
    qInfo().noquote() << "center: system bus connected:" << bus.isConnected();
    if (!bus.isConnected()) {
        m_error = "system D-Bus unavailable";
        emit changed();
        return;
    }
    // StateChanged is emitted by the daemon after every Refresh and every
    // write. Re-read properties only; calling Refresh here would loop.
    bus.connect(kService, kPath, kDeviceIface, "StateChanged", this,
                SLOT(fetchAll()));
    m_timer.start();
    refreshNow();
}

void CenterClient::refreshNow() {
    // Ask the daemon to refresh, then re-read every property on completion.
    QDBusMessage refresh = QDBusMessage::createMethodCall(
        kService, kPath, kDeviceIface, "Refresh");
    QDBusPendingCall call = QDBusConnection::systemBus().asyncCall(refresh);
    auto *watcher = new QDBusPendingCallWatcher(call, this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this,
            [this](QDBusPendingCallWatcher *w) {
                w->deleteLater();
                fetchAll();
            });
}

void CenterClient::fetchAll() {
    fetchProperty(kDeviceIface, "MatchedProfile");
    fetchProperty(kDeviceIface, "SupportTier");
    fetchProperty(kDeviceIface, "RuntimeCapabilities");
    fetchProperty(kDeviceIface, "RgbController");
    fetchProperty(kSensorsIface, "EcState");
    fetchProperty(kSensorsIface, "FanRpm");
    fetchProperty(kSensorsIface, "Battery");
}

void CenterClient::fetchProperty(const QString &iface, const QString &property) {
    ++m_inFlight;
    QDBusMessage get = QDBusMessage::createMethodCall(
        kService, kPath, "org.freedesktop.DBus.Properties", "Get");
    get << iface << property;
    QDBusPendingCall call = QDBusConnection::systemBus().asyncCall(get);
    auto *watcher = new QDBusPendingCallWatcher(call, this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this,
            [this, property](QDBusPendingCallWatcher *w) {
                w->deleteLater();
                QDBusMessage reply = w->reply();
                if (reply.type() != QDBusMessage::ReplyMessage) {
                    m_error = reply.errorMessage();
                    qWarning().noquote()
                        << "center:" << property << "error:" << m_error;
                    emit changed();
                } else {
                    const QVariant v = reply.arguments().constFirst()
                                           .value<QDBusVariant>()
                                           .variant();
                    handleJson(property, v.toString());
                }
                if (--m_inFlight == 0 && !m_loggedFirstSummary) {
                    m_loggedFirstSummary = true;
                    qInfo().noquote() << summary();
                }
            });
}

void CenterClient::handleJson(const QString &property, const QString &json) {
    // Plain string fields arrive as quoted JSON strings. QJsonDocument
    // rejects scalar documents with IllegalValue, so handle them first.
    if (property == "MatchedProfile") {
        m_profile = plainString(json);
    } else if (property == "SupportTier") {
        m_support = plainString(json);
    } else {
        QJsonParseError error{};
        const QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8(), &error);
        if (error.error != QJsonParseError::NoError) {
            m_error = QStringLiteral("%1: JSON parse error: %2")
                          .arg(property, error.errorString());
            emit changed();
            return;
        }
        if (property == "EcState") {
            if (doc.isObject())
                parseEc(doc.object());
        } else if (property == "FanRpm") {
            if (doc.isArray())
                parseFans(doc.array());
        } else if (property == "Battery") {
            if (doc.isObject())
                parseBattery(doc.object());
        } else if (property == "RuntimeCapabilities") {
            if (doc.isArray())
                parseCaps(doc.array());
        } else if (property == "RgbController") {
            if (doc.isObject()) {
                const QJsonObject rgb = doc.object();
                const QString name = rgb.value("controller_name").toString();
                const QString serial = rgb.value("controller_serial").toString();
                m_rgbController = name.isEmpty()
                                      ? QStringLiteral("not detected")
                                      : (serial.isEmpty()
                                             ? name
                                             : QStringLiteral("%1 (%2)").arg(name, serial));
            }
        }
    }
    emit changed();
}

void CenterClient::setFanMode(const QString &mode) {
    callMethod(QStringLiteral("SetFanMode"), {QVariant(mode)});
}

void CenterClient::setCoolerBoost(bool enabled) {
    callMethod(QStringLiteral("SetCoolerBoost"), {QVariant(enabled)});
}

void CenterClient::setSuperBattery(bool enabled) {
    callMethod(QStringLiteral("SetSuperBattery"), {QVariant(enabled)});
}

void CenterClient::setBatteryThresholds(int start, int end) {
    // The daemon signature is (yy); marshal as bytes, not ints.
    callMethod(QStringLiteral("SetBatteryThresholds"),
               {QVariant::fromValue<quint8>(quint8(start)),
                QVariant::fromValue<quint8>(quint8(end))});
}

void CenterClient::setRgbColorFromHex(int zones, const QString &hex) {
    const QString cleaned = hex.trimmed();
    if (cleaned.size() != 6) {
        m_actionError = true;
        m_actionMessage = QStringLiteral("RGB: invalid color '%1'").arg(hex);
        emit changed();
        return;
    }
    bool ok = false;
    const int value = cleaned.toInt(&ok, 16);
    if (!ok || value < 0) {
        m_actionError = true;
        m_actionMessage = QStringLiteral("RGB: invalid color '%1'").arg(hex);
        emit changed();
        return;
    }
    callMethod(QStringLiteral("SetRgbColor"),
               {QVariant::fromValue<quint8>(quint8(zones)),
                QVariant::fromValue<quint8>(quint8((value >> 16) & 0xff)),
                QVariant::fromValue<quint8>(quint8((value >> 8) & 0xff)),
                QVariant::fromValue<quint8>(quint8(value & 0xff))});
}

void CenterClient::callMethod(const QString &method, const QVariantList &args) {
    QDBusMessage msg = QDBusMessage::createMethodCall(
        kService, kPath, kDeviceIface, method);
    for (const QVariant &arg : args)
        msg << arg;
    QDBusPendingCall call = QDBusConnection::systemBus().asyncCall(msg);
    auto *watcher = new QDBusPendingCallWatcher(call, this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this,
            [this, method](QDBusPendingCallWatcher *w) {
                w->deleteLater();
                handleAction(method, w->reply());
            });
}

void CenterClient::handleAction(const QString &method,
                                const QDBusMessage &reply) {
    if (reply.type() == QDBusMessage::ReplyMessage) {
        m_actionError = false;
        m_actionMessage = QStringLiteral("%1: applied").arg(method);
        qInfo().noquote() << "center:" << method << "applied";
    } else {
        m_actionError = true;
        m_actionMessage = QStringLiteral("%1: %2").arg(method, reply.errorMessage());
        qWarning().noquote() << "center:" << method
                             << "rejected:" << reply.errorMessage();
    }
    emit changed();
    // Refresh cached state after any write attempt (success or gate refusal).
    refreshNow();
}

void CenterClient::parseEc(const QJsonObject &ec) {
    m_ecFirmware = ec.value("firmware").toString();
    m_ecShift = ec.value("shift_mode").toString();
    m_ecFanMode = ec.value("fan_mode").toString();
    QStringList modes;
    for (const QJsonValue &value : ec.value("available_fan_modes").toArray())
        modes << value.toString();
    m_fanModes = modes;
    const QJsonValue cooler = ec.value("cooler_boost");
    m_hasCoolerBoost = cooler.isBool();
    m_coolerBoost = cooler.toBool(false);
    const QJsonValue superBattery = ec.value("super_battery");
    m_hasSuperBattery = superBattery.isBool();
    m_superBattery = superBattery.toBool(false);
    const int cpu = ec.value("cpu_temperature_c").toInt(-1);
    const int gpu = ec.value("gpu_temperature_c").toInt(-1);
    m_ecTemps = QStringLiteral("%1 °C / %2 °C (cpu/gpu)")
                    .arg(cpu >= 0 ? QString::number(cpu) : QStringLiteral("?"),
                         gpu >= 0 ? QString::number(gpu) : QStringLiteral("?"));
}

void CenterClient::parseFans(const QJsonArray &fans) {
    QStringList parts;
    for (const QJsonValue &value : fans) {
        const QJsonObject fan = value.toObject();
        parts << QStringLiteral("%1: %2 rpm")
                     .arg(fan.value("channel").toString(),
                          QString::number(fan.value("rpm").toInt()));
    }
    m_fanText = parts.isEmpty() ? QStringLiteral("unavailable")
                                : parts.join(QStringLiteral(", "));
}

void CenterClient::parseBattery(const QJsonObject &battery) {
    m_battery = QStringLiteral("%1, %2% (start %3% / end %4%)")
                    .arg(battery.value("status").toString(),
                         QString::number(battery.value("capacity_percent").toInt()),
                         QString::number(battery.value("charge_start_percent").toInt(-1)),
                         QString::number(battery.value("charge_end_percent").toInt(-1)));
    m_chargeStart = battery.value("charge_start_percent").toInt(-1);
    m_chargeEnd = battery.value("charge_end_percent").toInt(-1);
}

void CenterClient::parseCaps(const QJsonArray &caps) {
    QStringList parts;
    for (const QJsonValue &value : caps) {
        const QJsonObject cap = value.toObject();
        parts << QStringLiteral("%1 (readable: %2)")
                     .arg(cap.value("feature").toString(),
                          cap.value("readable").toBool() ? QStringLiteral("yes")
                                                         : QStringLiteral("no"));
    }
    m_caps = parts.join(QStringLiteral(" | "));
}
