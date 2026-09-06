#include "centerclient.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDBusPendingCallWatcher>
#include <QDBusVariant>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonParseError>
#include <algorithm>

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
    reloadScenes();
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
    bool ok = false;
    if (reply.type() == QDBusMessage::ReplyMessage) {
        ok = true;
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
    if (m_actionCallback) {
        std::function<void(bool, const QString &)> callback =
            std::move(m_actionCallback);
        callback(ok, m_actionMessage);
    } else {
        // Refresh cached state after any write attempt (success or gate
        // refusal) when nobody is chaining steps.
        refreshNow();
    }
}

void CenterClient::reloadScenes() {
    m_sceneNames.clear();
    m_scenes = QJsonArray();
    const QString path = QString::fromLocal8Bit(qgetenv("XDG_CONFIG_HOME"));
    const QString base = path.isEmpty()
                             ? QDir::homePath() + QStringLiteral("/.config")
                             : path;
    QFile file(base + QStringLiteral("/msi-linux-center/scenes.json"));
    if (!file.open(QIODevice::ReadOnly)) {
        emit changed();
        return;
    }
    const QJsonDocument doc =
        QJsonDocument::fromJson(file.readAll());
    file.close();
    const QJsonArray scenes = doc.object().value("scenes").toArray();
    for (const QJsonValue &value : scenes) {
        const QString name = value.toObject().value("name").toString();
        if (!name.isEmpty()) {
            m_sceneNames << name;
            m_scenes.append(value);
        }
    }
    emit changed();
}

void CenterClient::applyScene(const QString &name) {
    if (m_sceneApplying)
        return;
    for (const QJsonValue &value : m_scenes) {
        const QJsonObject scene = value.toObject();
        if (scene.value("name").toString() != name)
            continue;
        m_sceneSteps = sceneSteps(scene.value("settings").toObject());
        m_sceneResults.clear();
        m_sceneResultText.clear();
        m_sceneStepIndex = 0;
        m_sceneApplying = true;
        emit changed();
        runNextSceneStep();
        return;
    }
    m_actionError = true;
    m_actionMessage = QStringLiteral("scene not found: %1").arg(name);
    emit changed();
}

QVector<CenterClient::SceneStep> CenterClient::sceneSteps(
    const QJsonObject &settings) const {
    QVector<SceneStep> steps;
    auto byte = [](int value) {
        return QVariant::fromValue<quint8>(quint8(value));
    };
    const QString fanMode = settings.value("fan_mode").toString();
    if (!fanMode.isEmpty()) {
        steps.push_back({QStringLiteral("fan_mode"),
                         QStringLiteral("SetFanMode"), {QVariant(fanMode)}});
    }
    if (settings.value("cooler_boost").isBool()) {
        steps.push_back(
            {QStringLiteral("cooler_boost"), QStringLiteral("SetCoolerBoost"),
             {QVariant(settings.value("cooler_boost").toBool())}});
    }
    if (settings.value("super_battery").isBool()) {
        steps.push_back(
            {QStringLiteral("super_battery"), QStringLiteral("SetSuperBattery"),
             {QVariant(settings.value("super_battery").toBool())}});
    }
    const int start = settings.value("battery_start").toInt(-1);
    const int end = settings.value("battery_end").toInt(-1);
    if (start >= 0 && end >= 0 && start < end && end <= 100) {
        steps.push_back({QStringLiteral("battery_thresholds"),
                         QStringLiteral("SetBatteryThresholds"),
                         {byte(start), byte(end)}});
    }
    const QJsonObject rgb = settings.value("rgb").toObject();
    if (!rgb.isEmpty()) {
        const int zones = rgb.value("zones").toInt(-1);
        const QString color = rgb.value("color").toString();
        if (zones >= 0 && zones <= 15 && color.size() == 6) {
            bool ok = false;
            const int value = color.toInt(&ok, 16);
            if (ok) {
                steps.push_back(
                    {QStringLiteral("rgb"), QStringLiteral("SetRgbColor"),
                     {byte(zones), byte((value >> 16) & 0xff),
                      byte((value >> 8) & 0xff), byte(value & 0xff)}});
            }
        }
    }
    return steps;
}

void CenterClient::runNextSceneStep() {
    if (m_sceneStepIndex >= m_sceneSteps.size()) {
        m_sceneApplying = false;
        const int failed = std::count_if(
            m_sceneResults.constBegin(), m_sceneResults.constEnd(),
            [](const QString &line) { return line.startsWith(QStringLiteral("FAIL")); });
        m_sceneResultText = QStringLiteral("scene: %1 ok, %2 failed")
                                .arg(m_sceneResults.size() - failed)
                                .arg(failed);
        for (const QString &line : m_sceneResults)
            m_sceneResultText += QStringLiteral("\n") + line;
        emit changed();
        refreshNow();
        return;
    }
    const SceneStep &step = m_sceneSteps.at(m_sceneStepIndex);
    const int index = m_sceneStepIndex;
    callMethod(step.method, step.args);
    // The reply arrives asynchronously; handle it through handleAction,
    // which invokes m_actionCallback below.
    m_actionCallback = [this, index, step](bool ok, const QString &message) {
        QString line = QStringLiteral("%1 %2: ").arg(ok ? QStringLiteral("ok")
                                                        : QStringLiteral("FAIL"),
                                                     step.label);
        if (ok) {
            line += QStringLiteral("applied");
        } else {
            line += message.section(QStringLiteral(": "), 1).trimmed();
        }
        m_sceneResults.append(line);
        m_sceneStepIndex = index + 1;
        runNextSceneStep();
    };
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
