#include "centerclient.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDBusPendingCallWatcher>
#include <QDBusVariant>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
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
        emit actionDone(false, actionTitle(QStringLiteral("SetRgbColor")),
                        QStringLiteral("invalid color '%1'").arg(hex));
        return;
    }
    bool ok = false;
    const int value = cleaned.toInt(&ok, 16);
    if (!ok || value < 0) {
        m_actionError = true;
        m_actionMessage = QStringLiteral("RGB: invalid color '%1'").arg(hex);
        emit changed();
        emit actionDone(false, actionTitle(QStringLiteral("SetRgbColor")),
                        QStringLiteral("invalid color '%1'").arg(hex));
        return;
    }
    callMethod(QStringLiteral("SetRgbColor"),
               {QVariant::fromValue<quint8>(quint8(zones)),
                QVariant::fromValue<quint8>(quint8((value >> 16) & 0xff)),
                QVariant::fromValue<quint8>(quint8((value >> 8) & 0xff)),
                QVariant::fromValue<quint8>(quint8(value & 0xff))});
}

void CenterClient::setRgbEffectPreset(int zones, int mode, int speedSeconds,
                                      const QString &hex, int waveDirection) {
    const QString cleaned = hex.trimmed();
    if (cleaned.size() != 6) {
        m_actionError = true;
        m_actionMessage = QStringLiteral("RGB: invalid color '%1'").arg(hex);
        emit changed();
        emit actionDone(false, actionTitle(QStringLiteral("SetRgbPresetEffect")),
                        QStringLiteral("invalid color '%1'").arg(hex));
        return;
    }
    callMethod(QStringLiteral("SetRgbPresetEffect"),
               {QVariant::fromValue<quint8>(quint8(zones)),
                QVariant::fromValue<quint8>(quint8(mode)),
                QVariant::fromValue<quint16>(quint16(speedSeconds * 100)),
                QVariant(cleaned),
                QVariant::fromValue<quint8>(quint8(waveDirection))});
}

void CenterClient::callMethod(const QString &method, const QVariantList &args) {
    QDBusMessage msg = QDBusMessage::createMethodCall(
        kService, kPath, kDeviceIface, method);
    for (const QVariant &arg : args)
        msg << arg;
    QDBusPendingCall call = QDBusConnection::systemBus().asyncCall(msg);
    auto *watcher = new QDBusPendingCallWatcher(call, this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this,
            [this, method, args](QDBusPendingCallWatcher *w) {
                w->deleteLater();
                handleAction(method, args, w->reply());
            });
}

QString CenterClient::actionTitle(const QString &method) const {
    if (method == QStringLiteral("SetFanMode"))
        return QStringLiteral("Fan mode");
    if (method == QStringLiteral("SetCoolerBoost"))
        return QStringLiteral("Cooler Boost");
    if (method == QStringLiteral("SetSuperBattery"))
        return QStringLiteral("Super Battery");
    if (method == QStringLiteral("SetBatteryThresholds"))
        return QStringLiteral("Battery limit");
    if (method == QStringLiteral("SetRgbColor"))
        return QStringLiteral("RGB color");
    if (method == QStringLiteral("SetRgbPresetEffect"))
        return QStringLiteral("RGB effect");
    if (method == QStringLiteral("SaveRgbState"))
        return QStringLiteral("RGB flash save");
    return method;
}

QString CenterClient::actionDetail(const QString &method,
                                   const QVariantList &args) const {
    if (method == QStringLiteral("SetFanMode"))
        return args.value(0).toString();
    if (method == QStringLiteral("SetCoolerBoost")
        || method == QStringLiteral("SetSuperBattery"))
        return args.value(0).toBool() ? QStringLiteral("on")
                                      : QStringLiteral("off");
    if (method == QStringLiteral("SetBatteryThresholds"))
        return QStringLiteral("%1% – %2%")
            .arg(args.value(0).toInt())
            .arg(args.value(1).toInt());
    if (method == QStringLiteral("SetRgbPresetEffect")) {
        const QString modeName =
            [](int mode) {
                switch (mode) {
                case 2: return QStringLiteral("breathing");
                case 3: return QStringLiteral("cycle");
                case 4: return QStringLiteral("wave");
                default: return QStringLiteral("steady");
                }
            }(args.value(1).toInt());
        return QStringLiteral("%1 · %2 s (non-persistent)")
            .arg(modeName, QString::number(args.value(2).toInt() / 100));
    }
    if (method == QStringLiteral("SetRgbColor")) {
        auto byte = [&args](int index) {
            return QStringLiteral("%1").arg(args.value(index).toInt(), 2, 16,
                                            QLatin1Char('0'));
        };
        return QStringLiteral("#%1%2%3 (non-persistent)")
            .arg(byte(1), byte(2), byte(3));
    }
    return QString();
}

void CenterClient::handleAction(const QString &method,
                                const QVariantList &args,
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
        emit actionDone(ok, actionTitle(method),
                        ok ? actionDetail(method, args) : reply.errorMessage());
    }
}

void CenterClient::reloadScenes() {
    m_sceneNames.clear();
    m_scenes = QJsonArray();
    QFile file(scenesFilePath());
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
        m_sceneName = name;
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
        emit actionDone(failed == 0, QStringLiteral("Scene"),
                        QStringLiteral("'%1': %2 ok, %3 failed")
                            .arg(m_sceneName)
                            .arg(m_sceneResults.size() - failed)
                            .arg(failed));
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
    // 0 or missing means the sensor is not readable (e.g. the dGPU is
    // powered off); show n/a instead of an impossible 0 C.
    auto temp = [](int value) {
        return value > 0 ? QStringLiteral("%1 °C").arg(value)
                         : QStringLiteral("n/a");
    };
    m_ecTemps = QStringLiteral("%1 / %2 (cpu / gpu)").arg(temp(cpu), temp(gpu));
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
    m_capacity = battery.value("capacity_percent").toInt(-1);
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

QString CenterClient::scenesFilePath() const {
    const QString path = QString::fromLocal8Bit(qgetenv("XDG_CONFIG_HOME"));
    const QString base = path.isEmpty()
                             ? QDir::homePath() + QStringLiteral("/.config")
                             : path;
    return base + QStringLiteral("/msi-linux-center/scenes.json");
}

// Structural validation mirroring the CLI scene rules (serde schema +
// scene::validate_scene): known keys only, bounded values, hex colors.
namespace {
bool validHexColor(const QString &text) {
    if (text.size() != 6)
        return false;
    for (const QChar &ch : text) {
        const bool hex = (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f')
                         || (ch >= 'A' && ch <= 'F');
        if (!hex)
            return false;
    }
    return true;
}

QString validateSceneEntry(const QJsonValue &value, int index) {
    const QString where = QStringLiteral("scene %1").arg(index + 1);
    const QJsonObject entry = value.toObject();
    const QString name = entry.value("name").toString();
    if (name.isEmpty())
        return where + ": missing or empty 'name'";
    const QJsonObject settings = entry.value("settings").toObject();
    if (settings.isEmpty())
        return QString();
    const QStringList known = {
        QStringLiteral("fan_mode"),       QStringLiteral("cooler_boost"),
        QStringLiteral("super_battery"),  QStringLiteral("battery_start"),
        QStringLiteral("battery_end"),    QStringLiteral("rgb")};
    for (const QString &key : settings.keys()) {
        if (!known.contains(key))
            return where + ": unknown settings key '" + key + "'";
    }
    if (settings.contains(QStringLiteral("fan_mode"))
        && !settings.value("fan_mode").isString())
        return where + ": 'fan_mode' must be a string";
    for (const char *key : {"cooler_boost", "super_battery"}) {
        if (settings.contains(QLatin1String(key))
            && !settings.value(QLatin1String(key)).isBool())
            return where + QStringLiteral(": '%1' must be a boolean").arg(key);
    }
    for (const char *key : {"battery_start", "battery_end"}) {
        const QJsonValue v = settings.value(QLatin1String(key));
        if (!v.isUndefined() && (!v.isDouble() || v.toInt() < 0 || v.toInt() > 100))
            return where + QStringLiteral(": '%1' must be 0-100").arg(key);
    }
    if (settings.contains(QStringLiteral("battery_start"))
        && settings.contains(QStringLiteral("battery_end"))
        && settings.value("battery_start").toInt()
               >= settings.value("battery_end").toInt())
        return where + ": battery_start must be below battery_end";
    const QJsonObject rgb = settings.value("rgb").toObject();
    if (!rgb.isEmpty()) {
        const int zones = rgb.value("zones").toInt(-1);
        const QString color = rgb.value("color").toString();
        if (zones < 0 || zones > 15)
            return where + ": 'rgb.zones' must be a zone bitmask (0-15)";
        if (!validHexColor(color))
            return where + ": 'rgb.color' must be RRGGBB hex";
    }
    return QString();
}
} // namespace

void CenterClient::importScenes() {
    const QString fileName = QFileDialog::getOpenFileName(
        nullptr, QStringLiteral("Import scenes"),
        QDir::homePath(), QStringLiteral("JSON (*.json)"));
    if (fileName.isEmpty())
        return; // user cancelled

    QFile file(fileName);
    if (!file.open(QIODevice::ReadOnly)) {
        m_actionError = true;
        m_actionMessage = QStringLiteral("cannot read %1").arg(fileName);
        emit changed();
        emit actionDone(false, QStringLiteral("Scenes import"),
                        m_actionMessage);
        return;
    }
    const QByteArray bytes = file.readAll();
    file.close();

    QJsonParseError error{};
    const QJsonDocument doc = QJsonDocument::fromJson(bytes, &error);
    if (error.error != QJsonParseError::NoError || !doc.isObject()) {
        m_actionError = true;
        m_actionMessage = QStringLiteral("invalid JSON: %1").arg(error.errorString());
        emit changed();
        emit actionDone(false, QStringLiteral("Scenes import"), m_actionMessage);
        return;
    }
    const QJsonArray scenes = doc.object().value("scenes").toArray();
    if (!doc.object().contains(QStringLiteral("scenes")) || scenes.isEmpty()) {
        m_actionError = true;
        m_actionMessage = QStringLiteral("no 'scenes' array found");
        emit changed();
        emit actionDone(false, QStringLiteral("Scenes import"), m_actionMessage);
        return;
    }
    for (int index = 0; index < scenes.size(); ++index) {
        const QString problem = validateSceneEntry(scenes.at(index), index);
        if (!problem.isEmpty()) {
            m_actionError = true;
            m_actionMessage = QStringLiteral("invalid %1").arg(problem);
            emit changed();
            emit actionDone(false, QStringLiteral("Scenes import"), m_actionMessage);
            return;
        }
    }

    QFile target(scenesFilePath());
    if (!QDir().mkpath(QFileInfo(target).absolutePath())
        || !target.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        m_actionError = true;
        m_actionMessage = QStringLiteral("cannot write %1").arg(scenesFilePath());
        emit changed();
        emit actionDone(false, QStringLiteral("Scenes import"), m_actionMessage);
        return;
    }
    target.write(bytes);
    target.close();
    m_actionError = false;
    m_actionMessage = QStringLiteral("imported %1 scene(s) from %2")
                          .arg(scenes.size())
                          .arg(QFileInfo(fileName).fileName());
    emit changed();
    emit actionDone(true, QStringLiteral("Scenes import"), m_actionMessage);
    reloadScenes();
}

void CenterClient::exportScenes() {
    QFile source(scenesFilePath());
    if (!source.exists()) {
        m_actionError = true;
        m_actionMessage = QStringLiteral("no scene file yet at %1").arg(scenesFilePath());
        emit changed();
        emit actionDone(false, QStringLiteral("Scenes export"), m_actionMessage);
        return;
    }
    const QString fileName = QFileDialog::getSaveFileName(
        nullptr, QStringLiteral("Export scenes"),
        QDir::homePath() + QStringLiteral("/scenes.json"), QStringLiteral("JSON (*.json)"));
    if (fileName.isEmpty())
        return; // user cancelled
    if (!source.open(QIODevice::ReadOnly)) {
        m_actionError = true;
        m_actionMessage = QStringLiteral("cannot read %1").arg(scenesFilePath());
        emit changed();
        emit actionDone(false, QStringLiteral("Scenes export"), m_actionMessage);
        return;
    }
    const QByteArray bytes = source.readAll();
    source.close();
    QFile target(fileName);
    if (!target.open(QIODevice::WriteOnly | QIODevice::Truncate)
        || target.write(bytes) != bytes.size()) {
        m_actionError = true;
        m_actionMessage = QStringLiteral("cannot write %1").arg(fileName);
        emit changed();
        emit actionDone(false, QStringLiteral("Scenes export"), m_actionMessage);
        return;
    }
    target.close();
    m_actionError = false;
    m_actionMessage = QStringLiteral("exported to %1").arg(fileName);
    emit changed();
    emit actionDone(true, QStringLiteral("Scenes export"), m_actionMessage);
}
