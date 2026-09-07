#include "centerclient.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDBusPendingCallWatcher>
#include <QDBusVariant>
#include <QDebug>
#include <QClipboard>
#include <QDateTime>
#include <QDir>
#include <QTime>
#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
#include <QSet>
#include <QGuiApplication>
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
    m_coolerBoostOffTimer.setSingleShot(true);
    connect(&m_coolerBoostOffTimer, &QTimer::timeout, this,
            &CenterClient::onCoolerBoostAutoOffTimeout);
    m_coolerBoostTick.setInterval(1000);
    connect(&m_coolerBoostTick, &QTimer::timeout, this, [this] { emit changed(); });
    connect(&m_timer, &QTimer::timeout, this, &CenterClient::maybeApplySchedule);
    loadUiSettings();
    loadWriteLog();
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
    fetchProperty(kDeviceIface, "DiagnosticReport");
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
                    QTimer::singleShot(0, this, [this] {
                        maybeApplyStartupScene();
                        maybeApplySchedule();
                    });
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
        } else if (property == "DiagnosticReport") {
            m_diagnosticReport = QString::fromUtf8(
                QJsonDocument(doc).toJson(QJsonDocument::Indented));
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

namespace {
int clampAutoOffSeconds(int seconds) {
    static const int kAllowed[] = {0, 30, 60, 120, 300, 600, 900};
    int best = 0;
    int bestDiff = qAbs(seconds);
    for (int allowed : kAllowed) {
        const int diff = qAbs(seconds - allowed);
        if (diff < bestDiff) {
            best = allowed;
            bestDiff = diff;
        }
    }
    return best;
}

int clampTravelDays(int days) {
    static const int kAllowed[] = {3, 7, 14, 30};
    int best = 7;
    int bestDiff = qAbs(days - 7);
    for (int allowed : kAllowed) {
        const int diff = qAbs(days - allowed);
        if (diff < bestDiff) {
            best = allowed;
            bestDiff = diff;
        }
    }
    return best;
}

int clampMinuteOfDay(int minute) {
    return qBound(0, minute, 23 * 60 + 59);
}

QString minuteToHm(int minute) {
    minute = clampMinuteOfDay(minute);
    return QStringLiteral("%1:%2")
        .arg(minute / 60, 2, 10, QLatin1Char('0'))
        .arg(minute % 60, 2, 10, QLatin1Char('0'));
}

int hmToMinute(const QString &text) {
    QTime time = QTime::fromString(text, QStringLiteral("HH:mm"));
    if (!time.isValid())
        time = QTime::fromString(text, QStringLiteral("H:mm"));
    if (!time.isValid())
        return 9 * 60;
    return time.hour() * 60 + time.minute();
}

bool minuteInWindow(int start, int end, int now) {
    if (start == end)
        return false;
    if (start < end)
        return now >= start && now < end;
    return now >= start || now < end;
}

int weekdayBit(int qtDayOfWeek) {
    if (qtDayOfWeek < 1 || qtDayOfWeek > 7)
        return -1;
    return qtDayOfWeek == 7 ? 6 : qtDayOfWeek - 1;
}
} // namespace

void CenterClient::setCoolerBoostAutoOffSeconds(int seconds) {
    const int clamped = clampAutoOffSeconds(seconds);
    if (clamped == m_coolerBoostAutoOffSeconds)
        return;
    m_coolerBoostAutoOffSeconds = clamped;
    saveUiSettings();
    if (m_coolerBoost && clamped > 0)
        armCoolerBoostAutoOff();
    else
        cancelCoolerBoostAutoOff();
    emit changed();
}

int CenterClient::coolerBoostRemainingSeconds() const {
    if (!m_coolerBoostOffTimer.isActive())
        return 0;
    const int ms = m_coolerBoostOffTimer.remainingTime();
    if (ms <= 0)
        return 0;
    return (ms + 999) / 1000;
}

void CenterClient::armCoolerBoostAutoOff() {
    m_coolerBoostOffTimer.stop();
    m_coolerBoostTick.stop();
    m_coolerBoostSeenOnDuringTimer = m_coolerBoost;
    if (m_coolerBoostAutoOffSeconds <= 0) {
        emit changed();
        return;
    }
    m_coolerBoostOffTimer.start(m_coolerBoostAutoOffSeconds * 1000);
    m_coolerBoostTick.start();
    emit changed();
}

void CenterClient::cancelCoolerBoostAutoOff() {
    const bool wasActive = m_coolerBoostOffTimer.isActive()
                           || m_coolerBoostTick.isActive();
    m_coolerBoostOffTimer.stop();
    m_coolerBoostTick.stop();
    m_coolerBoostSeenOnDuringTimer = false;
    if (wasActive)
        emit changed();
}

void CenterClient::onCoolerBoostAutoOffTimeout() {
    m_coolerBoostTick.stop();
    m_coolerBoostAutoOffFiring = true;
    emit changed();
    setCoolerBoost(false);
}

QString CenterClient::configDir() const {
    const QString path = QString::fromLocal8Bit(qgetenv("XDG_CONFIG_HOME"));
    const QString base = path.isEmpty()
                             ? QDir::homePath() + QStringLiteral("/.config")
                             : path;
    return base + QStringLiteral("/msi-linux-center");
}

QString CenterClient::uiSettingsFilePath() const {
    return configDir() + QStringLiteral("/ui.json");
}

QString CenterClient::writeLogFilePath() const {
    return configDir() + QStringLiteral("/writes.log");
}

void CenterClient::loadWriteLog() {
    QFile file(writeLogFilePath());
    if (!file.open(QIODevice::ReadOnly))
        return;
    const QStringList lines = QString::fromUtf8(file.readAll()).split(
        QLatin1Char('\n'), Qt::SkipEmptyParts);
    file.close();
    const int extra = lines.size() - kMaxWriteLogLines;
    m_writeLogLines = extra > 0 ? lines.mid(extra) : lines;
}

void CenterClient::appendWriteLog(bool ok, const QString &title,
                                  const QString &detail) {
    QString clean = detail;
    clean.replace(QLatin1Char('\n'), QLatin1Char(' '));
    clean.replace(QLatin1Char('\t'), QLatin1Char(' '));
    const QString line =
        QDateTime::currentDateTime().toString(Qt::ISODate) + QLatin1Char(' ')
        + (ok ? QStringLiteral("ok") : QStringLiteral("FAIL")) + QLatin1Char(' ')
        + title + QStringLiteral("  ") + clean;
    m_writeLogLines.append(line);
    while (m_writeLogLines.size() > kMaxWriteLogLines)
        m_writeLogLines.removeFirst();
    if (!QDir().mkpath(configDir()))
        return;
    QFile file(writeLogFilePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return;
    file.write(m_writeLogLines.join(QLatin1Char('\n')).toUtf8());
    file.write("\n");
}

void CenterClient::copyWriteLog() {
    if (m_writeLogLines.isEmpty()) {
        emit actionDone(false, QStringLiteral("Write log"),
                        QStringLiteral("no writes recorded yet"));
        return;
    }
    QGuiApplication::clipboard()->setText(writeLogText() + QLatin1Char('\n'));
    emit actionDone(true, QStringLiteral("Write log"),
                    QStringLiteral("%1 lines copied").arg(m_writeLogLines.size()));
}

void CenterClient::loadUiSettings() {
    QFile file(uiSettingsFilePath());
    if (!file.open(QIODevice::ReadOnly))
        return;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();
    if (!doc.isObject())
        return;
    const QJsonObject root = doc.object();
    m_coolerBoostAutoOffSeconds = clampAutoOffSeconds(
        root.value(QStringLiteral("cooler_boost_auto_off_seconds")).toInt(0));
    m_travelDays = clampTravelDays(root.value(QStringLiteral("travel_days")).toInt(7));
    const QString at = root.value(QStringLiteral("travel_restore_at")).toString();
    const int start = root.value(QStringLiteral("travel_restore_start")).toInt(-1);
    const int end = root.value(QStringLiteral("travel_restore_end")).toInt(-1);
    m_travelRestoreAt = QDateTime::fromString(at, Qt::ISODate);
    if (m_travelRestoreAt.isValid() && start >= 0 && end <= 100 && start < end) {
        m_travelRestoreStart = start;
        m_travelRestoreEnd = end;
        m_travelActive = true;
    }
    m_restoreSceneOnStart =
        root.value(QStringLiteral("restore_scene_on_start")).toBool(false);
    m_restoreSceneName =
        root.value(QStringLiteral("restore_scene_name")).toString();
    m_lastAppliedScene =
        root.value(QStringLiteral("last_applied_scene")).toString();
    m_powerSceneSwitch =
        root.value(QStringLiteral("power_scene_switch")).toBool(false);
    m_acSceneName = root.value(QStringLiteral("ac_scene_name")).toString();
    m_batterySceneName =
        root.value(QStringLiteral("battery_scene_name")).toString();
    m_batteryLevelRules =
        root.value(QStringLiteral("battery_level_rules")).toBool(false);
    m_batteryLowPercent = qBound(
        5, root.value(QStringLiteral("battery_low_percent")).toInt(30), 95);
    m_batteryHighPercent = qBound(
        10, root.value(QStringLiteral("battery_high_percent")).toInt(80), 100);
    if (m_batteryLowPercent >= m_batteryHighPercent)
        m_batteryHighPercent = qMin(100, m_batteryLowPercent + 1);
    m_batteryLowScene = root.value(QStringLiteral("battery_low_scene")).toString();
    m_batteryHighScene =
        root.value(QStringLiteral("battery_high_scene")).toString();
    m_sceneSchedule =
        root.value(QStringLiteral("scene_schedule_enabled")).toBool(false);
    loadScheduleRules(root.value(QStringLiteral("scene_schedule")).toArray());
    m_tempAlert = root.value(QStringLiteral("temp_alert")).toBool(false);
    m_tempAlertCelsius = qBound(
        70, root.value(QStringLiteral("temp_alert_celsius")).toInt(90), 100);
    m_tempAlertHoldSeconds = qBound(
        5, root.value(QStringLiteral("temp_alert_hold_seconds")).toInt(10), 60);
    m_tempAlertCooldownSeconds = qBound(
        30, root.value(QStringLiteral("temp_alert_cooldown_seconds")).toInt(120),
        600);
    const int window =
        root.value(QStringLiteral("history_window_minutes")).toInt(15);
    m_historyWindowMinutes = (window == 30 || window == 60) ? window : 15;
}

void CenterClient::saveUiSettings() {
    QJsonObject root;
    root.insert(QStringLiteral("cooler_boost_auto_off_seconds"),
                m_coolerBoostAutoOffSeconds);
    root.insert(QStringLiteral("travel_days"), m_travelDays);
    if (m_travelActive && m_travelRestoreAt.isValid()) {
        root.insert(QStringLiteral("travel_restore_start"), m_travelRestoreStart);
        root.insert(QStringLiteral("travel_restore_end"), m_travelRestoreEnd);
        root.insert(QStringLiteral("travel_restore_at"),
                    m_travelRestoreAt.toUTC().toString(Qt::ISODate));
    }
    root.insert(QStringLiteral("restore_scene_on_start"), m_restoreSceneOnStart);
    root.insert(QStringLiteral("restore_scene_name"), m_restoreSceneName);
    root.insert(QStringLiteral("last_applied_scene"), m_lastAppliedScene);
    root.insert(QStringLiteral("power_scene_switch"), m_powerSceneSwitch);
    root.insert(QStringLiteral("ac_scene_name"), m_acSceneName);
    root.insert(QStringLiteral("battery_scene_name"), m_batterySceneName);
    root.insert(QStringLiteral("battery_level_rules"), m_batteryLevelRules);
    root.insert(QStringLiteral("battery_low_percent"), m_batteryLowPercent);
    root.insert(QStringLiteral("battery_high_percent"), m_batteryHighPercent);
    root.insert(QStringLiteral("battery_low_scene"), m_batteryLowScene);
    root.insert(QStringLiteral("battery_high_scene"), m_batteryHighScene);
    root.insert(QStringLiteral("scene_schedule_enabled"), m_sceneSchedule);
    root.insert(QStringLiteral("scene_schedule"), scheduleRulesJson());
    root.insert(QStringLiteral("temp_alert"), m_tempAlert);
    root.insert(QStringLiteral("temp_alert_celsius"), m_tempAlertCelsius);
    root.insert(QStringLiteral("temp_alert_hold_seconds"), m_tempAlertHoldSeconds);
    root.insert(QStringLiteral("temp_alert_cooldown_seconds"),
                m_tempAlertCooldownSeconds);
    root.insert(QStringLiteral("history_window_minutes"), m_historyWindowMinutes);
    if (!QDir().mkpath(configDir()))
        return;
    QFile file(uiSettingsFilePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return;
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
}

void CenterClient::setSuperBattery(bool enabled) {
    callMethod(QStringLiteral("SetSuperBattery"), {QVariant(enabled)});
}

void CenterClient::setWebcam(bool enabled) {
    callMethod(QStringLiteral("SetWebcam"), {QVariant(enabled)});
}

void CenterClient::setWebcamBlock(bool enabled) {
    callMethod(QStringLiteral("SetWebcamBlock"), {QVariant(enabled)});
}

void CenterClient::setFnKey(const QString &position) {
    callMethod(QStringLiteral("SetFnKey"), {QVariant(position)});
}

void CenterClient::setBatteryThresholds(int start, int end) {
    // The daemon signature is (yy); marshal as bytes, not ints.
    callMethod(QStringLiteral("SetBatteryThresholds"),
               {QVariant::fromValue<quint8>(quint8(start)),
                QVariant::fromValue<quint8>(quint8(end))});
}

QString CenterClient::travelRestoreText() const {
    if (!m_travelActive || !m_travelRestoreAt.isValid())
        return QString();
    return QStringLiteral("Restores %1–%2% on %3 (this app + battery opt-in + Polkit).")
        .arg(m_travelRestoreStart)
        .arg(m_travelRestoreEnd)
        .arg(m_travelRestoreAt.toLocalTime().toString(QStringLiteral("dd MMM yyyy hh:mm")));
}

void CenterClient::setTravelDays(int days) {
    const int clamped = clampTravelDays(days);
    if (clamped == m_travelDays)
        return;
    m_travelDays = clamped;
    saveUiSettings();
    emit changed();
}

void CenterClient::startTravel(int days) {
    if (m_chargeStart < 0 || m_chargeEnd < 0 || m_chargeStart >= m_chargeEnd) {
        m_actionError = true;
        m_actionMessage = QStringLiteral("Travel: charge limits unavailable");
        emit changed();
        emit actionDone(false, QStringLiteral("Travel"), m_actionMessage);
        return;
    }
    m_travelDays = clampTravelDays(days);
    if (!m_travelActive) {
        m_travelRestoreStart = m_chargeStart;
        m_travelRestoreEnd = m_chargeEnd;
    }
    m_travelRestoreAt = QDateTime::currentDateTimeUtc().addDays(m_travelDays);
    m_travelRestoreFailed = false;
    if (m_chargeEnd >= 100 && m_chargeStart < 100) {
        m_travelActive = true;
        saveUiSettings();
        m_actionError = false;
        m_actionMessage = travelRestoreText();
        emit changed();
        emit actionDone(true, QStringLiteral("Travel"),
                        QStringLiteral("already 100% end · %1").arg(m_actionMessage));
        return;
    }
    m_travelArming = true;
    setBatteryThresholds(m_chargeStart, 100);
}

void CenterClient::cancelTravel() {
    if (!m_travelActive) {
        emit actionDone(false, QStringLiteral("Travel"),
                        QStringLiteral("no trip in progress"));
        return;
    }
    m_travelRestoreFailed = false;
    m_travelRestoreInFlight = true;
    setBatteryThresholds(m_travelRestoreStart, m_travelRestoreEnd);
}

void CenterClient::clearTravel() {
    m_travelActive = false;
    m_travelRestoreStart = -1;
    m_travelRestoreEnd = -1;
    m_travelRestoreAt = QDateTime();
    m_travelArming = false;
    m_travelRestoreInFlight = false;
    m_travelRestoreFailed = false;
    saveUiSettings();
}

void CenterClient::maybeRestoreTravel() {
    if (!m_travelActive || m_travelRestoreInFlight || m_travelRestoreFailed
        || m_travelArming || !m_travelRestoreAt.isValid())
        return;
    if (QDateTime::currentDateTimeUtc() < m_travelRestoreAt)
        return;
    m_travelRestoreInFlight = true;
    setBatteryThresholds(m_travelRestoreStart, m_travelRestoreEnd);
}

QStringList CenterClient::restoreSceneChoices() const {
    const QString last = m_lastAppliedScene.isEmpty()
                             ? QStringLiteral("Last applied")
                             : QStringLiteral("Last applied (%1)").arg(m_lastAppliedScene);
    return QStringList{last} + m_sceneNames;
}

int CenterClient::restoreSceneChoiceIndex() const {
    if (m_restoreSceneName.isEmpty())
        return 0;
    const int index = m_sceneNames.indexOf(m_restoreSceneName);
    return index >= 0 ? index + 1 : 0;
}

void CenterClient::setRestoreSceneOnStart(bool enabled) {
    if (enabled == m_restoreSceneOnStart)
        return;
    m_restoreSceneOnStart = enabled;
    saveUiSettings();
    emit changed();
}

void CenterClient::setRestoreSceneName(const QString &name) {
    if (name == m_restoreSceneName)
        return;
    m_restoreSceneName = name;
    saveUiSettings();
    emit changed();
}

void CenterClient::setRestoreSceneChoiceIndex(int index) {
    if (index <= 0) {
        setRestoreSceneName(QString());
        return;
    }
    const int sceneIndex = index - 1;
    if (sceneIndex < 0 || sceneIndex >= m_sceneNames.size())
        return;
    setRestoreSceneName(m_sceneNames.at(sceneIndex));
}

void CenterClient::maybeApplyStartupScene() {
    if (m_startupRestoreDone)
        return;
    if (m_sceneSchedule && matchingScheduleRule(QDateTime::currentDateTime()) >= 0) {
        m_startupRestoreDone = true;
        return;
    }
    if (!m_restoreSceneOnStart) {
        m_startupRestoreDone = true;
        return;
    }
    if (m_travelRestoreInFlight && m_startupRestoreDeferrals < 5) {
        ++m_startupRestoreDeferrals;
        QTimer::singleShot(2000, this, &CenterClient::maybeApplyStartupScene);
        return;
    }
    m_startupRestoreDone = true;
    QString name = m_restoreSceneName;
    if (name.isEmpty())
        name = m_lastAppliedScene;
    if (name.isEmpty() || !m_sceneNames.contains(name)) {
        emit actionDone(false, QStringLiteral("Startup scene"),
                        name.isEmpty() ? QStringLiteral("none saved yet")
                                       : QStringLiteral("not found: %1").arg(name));
        return;
    }
    qInfo().noquote() << "center: startup scene" << name;
    applyScene(name);
}

QString CenterClient::powerSourceText() const {
    if (!m_powerOnAcKnown)
        return QStringLiteral("power: unknown");
    return m_powerOnAc ? QStringLiteral("power: AC")
                       : QStringLiteral("power: battery");
}

QStringList CenterClient::sceneChoicesWithNone() const {
    return QStringList{QStringLiteral("(none)")} + m_sceneNames;
}

int CenterClient::sceneChoiceIndex(const QString &name) const {
    if (name.isEmpty())
        return 0;
    const int index = m_sceneNames.indexOf(name);
    return index >= 0 ? index + 1 : 0;
}

int CenterClient::acSceneChoiceIndex() const {
    return sceneChoiceIndex(m_acSceneName);
}

int CenterClient::batterySceneChoiceIndex() const {
    return sceneChoiceIndex(m_batterySceneName);
}

void CenterClient::setSceneChoiceName(QString *dest, int index) {
    QString name;
    if (index > 0 && index <= m_sceneNames.size())
        name = m_sceneNames.at(index - 1);
    if (name == *dest)
        return;
    *dest = name;
    saveUiSettings();
    emit changed();
}

void CenterClient::setPowerSceneSwitch(bool enabled) {
    if (enabled == m_powerSceneSwitch)
        return;
    m_powerSceneSwitch = enabled;
    saveUiSettings();
    emit changed();
}

void CenterClient::setAcSceneChoiceIndex(int index) {
    setSceneChoiceName(&m_acSceneName, index);
}

void CenterClient::setBatterySceneChoiceIndex(int index) {
    setSceneChoiceName(&m_batterySceneName, index);
}

void CenterClient::maybeSwitchPowerScene(bool onAc) {
    if (!m_powerOnAcKnown) {
        m_powerOnAc = onAc;
        m_powerOnAcKnown = true;
        emit changed();
        return;
    }
    if (m_powerOnAc == onAc)
        return;
    m_powerOnAc = onAc;
    emit changed();
    if (!m_powerSceneSwitch)
        return;
    const QString name = onAc ? m_acSceneName : m_batterySceneName;
    qInfo().noquote() << "center: power scene" << (onAc ? "AC" : "battery")
                      << name;
    applyNamedAutoScene(name);
}

void CenterClient::applyNamedAutoScene(const QString &name) {
    if (name.isEmpty() || !m_sceneNames.contains(name))
        return;
    if (m_sceneApplying) {
        m_pendingPowerScene = name;
        return;
    }
    applyScene(name);
}

int CenterClient::batteryLowSceneChoiceIndex() const {
    return sceneChoiceIndex(m_batteryLowScene);
}

int CenterClient::batteryHighSceneChoiceIndex() const {
    return sceneChoiceIndex(m_batteryHighScene);
}

void CenterClient::setBatteryLevelRules(bool enabled) {
    if (enabled == m_batteryLevelRules)
        return;
    m_batteryLevelRules = enabled;
    saveUiSettings();
    emit changed();
}

void CenterClient::setBatteryLowPercent(int percent) {
    int value = qBound(5, percent, 95);
    int high = m_batteryHighPercent;
    if (value >= high)
        high = qMin(100, value + 1);
    if (value == m_batteryLowPercent && high == m_batteryHighPercent)
        return;
    m_batteryLowPercent = value;
    m_batteryHighPercent = high;
    saveUiSettings();
    emit changed();
}

void CenterClient::setBatteryHighPercent(int percent) {
    int value = qBound(10, percent, 100);
    if (value <= m_batteryLowPercent)
        value = qMin(100, m_batteryLowPercent + 1);
    if (value == m_batteryHighPercent)
        return;
    m_batteryHighPercent = value;
    saveUiSettings();
    emit changed();
}

void CenterClient::setBatteryLowSceneChoiceIndex(int index) {
    setSceneChoiceName(&m_batteryLowScene, index);
}

void CenterClient::setBatteryHighSceneChoiceIndex(int index) {
    setSceneChoiceName(&m_batteryHighScene, index);
}

void CenterClient::maybeBatteryLevelRules(int capacity, bool discharging,
                                          bool charging) {
    if (capacity < 0)
        return;
    const int previous = m_lastCapacity;
    m_lastCapacity = capacity;
    if (previous < 0 || !m_batteryLevelRules)
        return;
    if (discharging && previous >= m_batteryLowPercent
        && capacity < m_batteryLowPercent) {
        qInfo().noquote() << "center: battery low crossing" << capacity;
        applyNamedAutoScene(m_batteryLowScene);
    } else if (charging && previous <= m_batteryHighPercent
               && capacity > m_batteryHighPercent) {
        qInfo().noquote() << "center: battery high crossing" << capacity;
        applyNamedAutoScene(m_batteryHighScene);
    }
}

QVariantList CenterClient::scheduleRules() const {
    QVariantList list;
    for (const ScheduleRule &rule : m_scheduleRules) {
        QVariantMap row;
        row.insert(QStringLiteral("days"), int(rule.days));
        row.insert(QStringLiteral("startHour"), rule.startMinute / 60);
        row.insert(QStringLiteral("startMinute"), rule.startMinute % 60);
        row.insert(QStringLiteral("endHour"), rule.endMinute / 60);
        row.insert(QStringLiteral("endMinute"), rule.endMinute % 60);
        row.insert(QStringLiteral("scene"), rule.scene);
        list.append(row);
    }
    return list;
}

void CenterClient::loadScheduleRules(const QJsonArray &rules) {
    m_scheduleRules.clear();
    for (const QJsonValue &value : rules) {
        if (m_scheduleRules.size() >= kMaxScheduleRules)
            break;
        const QJsonObject object = value.toObject();
        ScheduleRule rule;
        rule.days = quint8(object.value(QStringLiteral("days")).toInt(0) & 0x7f);
        rule.startMinute =
            clampMinuteOfDay(hmToMinute(object.value(QStringLiteral("start")).toString()));
        rule.endMinute =
            clampMinuteOfDay(hmToMinute(object.value(QStringLiteral("end")).toString()));
        rule.scene = object.value(QStringLiteral("scene")).toString();
        m_scheduleRules.append(rule);
    }
}

QJsonArray CenterClient::scheduleRulesJson() const {
    QJsonArray array;
    for (const ScheduleRule &rule : m_scheduleRules) {
        QJsonObject object;
        object.insert(QStringLiteral("days"), int(rule.days));
        object.insert(QStringLiteral("start"), minuteToHm(rule.startMinute));
        object.insert(QStringLiteral("end"), minuteToHm(rule.endMinute));
        object.insert(QStringLiteral("scene"), rule.scene);
        array.append(object);
    }
    return array;
}

int CenterClient::matchingScheduleRule(const QDateTime &when) const {
    const int bit = weekdayBit(when.date().dayOfWeek());
    if (bit < 0)
        return -1;
    const int now = when.time().hour() * 60 + when.time().minute();
    for (int index = 0; index < m_scheduleRules.size(); ++index) {
        const ScheduleRule &rule = m_scheduleRules.at(index);
        if ((rule.days & (1u << bit)) == 0)
            continue;
        if (!minuteInWindow(rule.startMinute, rule.endMinute, now))
            continue;
        return index;
    }
    return -1;
}

void CenterClient::maybeApplySchedule() {
    if (!m_sceneSchedule) {
        m_activeScheduleRule = -1;
        return;
    }
    const int match = matchingScheduleRule(QDateTime::currentDateTime());
    if (match == m_activeScheduleRule)
        return;
    m_activeScheduleRule = match;
    if (match < 0)
        return;
    const QString name = m_scheduleRules.at(match).scene;
    qInfo().noquote() << "center: schedule scene" << name;
    applyNamedAutoScene(name);
}

void CenterClient::setTempAlert(bool enabled) {
    if (enabled == m_tempAlert)
        return;
    m_tempAlert = enabled;
    if (!enabled)
        m_tempOverSince = QDateTime();
    saveUiSettings();
    emit changed();
}

void CenterClient::setTempAlertCelsius(int celsius) {
    const int value = qBound(70, celsius, 100);
    if (value == m_tempAlertCelsius)
        return;
    m_tempAlertCelsius = value;
    saveUiSettings();
    emit changed();
}

void CenterClient::setTempAlertHoldSeconds(int seconds) {
    const int value = qBound(5, seconds, 60);
    if (value == m_tempAlertHoldSeconds)
        return;
    m_tempAlertHoldSeconds = value;
    saveUiSettings();
    emit changed();
}

void CenterClient::setTempAlertCooldownSeconds(int seconds) {
    const int value = qBound(30, seconds, 600);
    if (value == m_tempAlertCooldownSeconds)
        return;
    m_tempAlertCooldownSeconds = value;
    saveUiSettings();
    emit changed();
}

void CenterClient::maybeTemperatureAlert() {
    if (!m_tempAlert || m_cpuTemp <= 0) {
        m_tempOverSince = QDateTime();
        return;
    }
    const QDateTime now = QDateTime::currentDateTimeUtc();
    if (m_cpuTemp < m_tempAlertCelsius) {
        m_tempOverSince = QDateTime();
        return;
    }
    if (!m_tempOverSince.isValid())
        m_tempOverSince = now;
    if (m_tempOverSince.secsTo(now) < m_tempAlertHoldSeconds)
        return;
    if (m_tempAlertLast.isValid()
        && m_tempAlertLast.secsTo(now) < m_tempAlertCooldownSeconds)
        return;
    m_tempAlertLast = now;
    qInfo().noquote() << "center: CPU temp alert" << m_cpuTemp << "C";
    emit actionDone(
        false, QStringLiteral("Temperature"),
        QStringLiteral("CPU %1 °C for %2 s (threshold %3 °C)")
            .arg(m_cpuTemp)
            .arg(m_tempAlertHoldSeconds)
            .arg(m_tempAlertCelsius));
}

void CenterClient::trimHistory(qint64 nowMs) {
    const qint64 keepMs = 60ll * 60ll * 1000ll;
    while (!m_history.isEmpty() && nowMs - m_history.first().ms > keepMs)
        m_history.removeFirst();
}

void CenterClient::maybeRecordHistory() {
    if (m_cpuTemp <= 0 && m_fanRpmMax <= 0)
        return;
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (m_lastHistoryMs > 0 && now - m_lastHistoryMs < 2000)
        return;
    m_lastHistoryMs = now;
    m_history.append({now, m_cpuTemp, m_fanRpmMax});
    trimHistory(now);
}

QVariantList CenterClient::historyCpu() const {
    const qint64 from =
        QDateTime::currentMSecsSinceEpoch()
        - qint64(m_historyWindowMinutes) * 60 * 1000;
    QVariantList values;
    for (const HistorySample &sample : m_history) {
        if (sample.ms < from || sample.cpu <= 0)
            continue;
        values.append(sample.cpu);
    }
    return values;
}

QVariantList CenterClient::historyRpm() const {
    const qint64 from =
        QDateTime::currentMSecsSinceEpoch()
        - qint64(m_historyWindowMinutes) * 60 * 1000;
    QVariantList values;
    for (const HistorySample &sample : m_history) {
        if (sample.ms < from || sample.rpm <= 0)
            continue;
        values.append(sample.rpm);
    }
    return values;
}

int CenterClient::historyMaxRpm() const {
    int maxRpm = 1;
    for (const QVariant &value : historyRpm())
        maxRpm = qMax(maxRpm, value.toInt());
    return maxRpm;
}

void CenterClient::setHistoryWindowMinutes(int minutes) {
    const int value = (minutes == 30 || minutes == 60) ? minutes : 15;
    if (value == m_historyWindowMinutes)
        return;
    m_historyWindowMinutes = value;
    saveUiSettings();
    emit changed();
}

void CenterClient::copyHistoryCsv() {
    const qint64 from =
        QDateTime::currentMSecsSinceEpoch()
        - qint64(m_historyWindowMinutes) * 60 * 1000;
    QString csv = QStringLiteral("time,cpu_c,rpm\n");
    int rows = 0;
    for (const HistorySample &sample : m_history) {
        if (sample.ms < from)
            continue;
        csv += QDateTime::fromMSecsSinceEpoch(sample.ms).toString(Qt::ISODate);
        csv += QLatin1Char(',');
        csv += sample.cpu > 0 ? QString::number(sample.cpu) : QString();
        csv += QLatin1Char(',');
        csv += sample.rpm > 0 ? QString::number(sample.rpm) : QString();
        csv += QLatin1Char('\n');
        ++rows;
    }
    if (rows == 0) {
        emit actionDone(false, QStringLiteral("History"),
                        QStringLiteral("no samples yet"));
        return;
    }
    QGuiApplication::clipboard()->setText(csv);
    emit actionDone(true, QStringLiteral("History"),
                    QStringLiteral("%1 samples copied as CSV").arg(rows));
}

void CenterClient::setSceneSchedule(bool enabled) {
    if (enabled == m_sceneSchedule)
        return;
    m_sceneSchedule = enabled;
    m_activeScheduleRule = -2;
    saveUiSettings();
    emit changed();
    if (enabled)
        maybeApplySchedule();
}

void CenterClient::addScheduleRule() {
    if (m_scheduleRules.size() >= kMaxScheduleRules)
        return;
    ScheduleRule rule;
    rule.days = 0x1f; // Mon–Fri
    m_scheduleRules.append(rule);
    saveUiSettings();
    emit changed();
}

void CenterClient::removeScheduleRule(int index) {
    if (index < 0 || index >= m_scheduleRules.size())
        return;
    m_scheduleRules.removeAt(index);
    m_activeScheduleRule = -2;
    saveUiSettings();
    emit changed();
}

void CenterClient::toggleScheduleDay(int index, int dayBit) {
    if (index < 0 || index >= m_scheduleRules.size() || dayBit < 0 || dayBit > 6)
        return;
    m_scheduleRules[index].days ^= quint8(1u << dayBit);
    m_activeScheduleRule = -2;
    saveUiSettings();
    emit changed();
}

void CenterClient::setScheduleRuleStart(int index, int hour, int minute) {
    if (index < 0 || index >= m_scheduleRules.size())
        return;
    const int value = clampMinuteOfDay(hour * 60 + minute);
    if (m_scheduleRules[index].startMinute == value)
        return;
    m_scheduleRules[index].startMinute = value;
    m_activeScheduleRule = -2;
    saveUiSettings();
    emit changed();
}

void CenterClient::setScheduleRuleEnd(int index, int hour, int minute) {
    if (index < 0 || index >= m_scheduleRules.size())
        return;
    const int value = clampMinuteOfDay(hour * 60 + minute);
    if (m_scheduleRules[index].endMinute == value)
        return;
    m_scheduleRules[index].endMinute = value;
    m_activeScheduleRule = -2;
    saveUiSettings();
    emit changed();
}

void CenterClient::setScheduleRuleScene(int index, int sceneChoiceIndex) {
    if (index < 0 || index >= m_scheduleRules.size())
        return;
    QString name;
    if (sceneChoiceIndex > 0 && sceneChoiceIndex <= m_sceneNames.size())
        name = m_sceneNames.at(sceneChoiceIndex - 1);
    if (m_scheduleRules[index].scene == name)
        return;
    m_scheduleRules[index].scene = name;
    m_activeScheduleRule = -2;
    saveUiSettings();
    emit changed();
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
    if (method == QStringLiteral("SetWebcam"))
        return QStringLiteral("Webcam");
    if (method == QStringLiteral("SetWebcamBlock"))
        return QStringLiteral("Webcam block");
    if (method == QStringLiteral("SetFnKey"))
        return QStringLiteral("Fn key");
    if (method == QStringLiteral("SetBatteryThresholds")) {
        if (m_travelArming)
            return QStringLiteral("Travel");
        if (m_travelRestoreInFlight)
            return QStringLiteral("Travel restore");
        return QStringLiteral("Battery limit");
    }
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
        || method == QStringLiteral("SetSuperBattery")
        || method == QStringLiteral("SetWebcam")
        || method == QStringLiteral("SetWebcamBlock"))
        return args.value(0).toBool()
                   ? QStringLiteral("on")
                   : (m_coolerBoostAutoOffFiring
                          ? QStringLiteral("off (timer)")
                          : QStringLiteral("off"));
    if (method == QStringLiteral("SetFnKey"))
        return args.value(0).toString();
    if (method == QStringLiteral("SetBatteryThresholds")) {
        if (m_travelArming && m_travelRestoreAt.isValid())
            return QStringLiteral("to 100% until %1; then %2–%3%")
                .arg(m_travelRestoreAt.toLocalTime().toString(
                    QStringLiteral("dd MMM yyyy")),
                     QString::number(m_travelRestoreStart),
                     QString::number(m_travelRestoreEnd));
        if (m_travelRestoreInFlight)
            return QStringLiteral("restored %1–%2%")
                .arg(m_travelRestoreStart)
                .arg(m_travelRestoreEnd);
        return QStringLiteral("%1% – %2%")
            .arg(args.value(0).toInt())
            .arg(args.value(1).toInt());
    }
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
    if (method == QStringLiteral("SetCoolerBoost")) {
        if (ok && args.value(0).toBool())
            armCoolerBoostAutoOff();
        else if (ok)
            cancelCoolerBoostAutoOff();
    }
    bool travelRestoreOk = false;
    if (method == QStringLiteral("SetBatteryThresholds")) {
        if (m_travelArming) {
            if (ok) {
                m_travelActive = true;
                saveUiSettings();
            } else if (!m_travelActive) {
                m_travelRestoreStart = -1;
                m_travelRestoreEnd = -1;
                m_travelRestoreAt = QDateTime();
            }
        }
        if (m_travelRestoreInFlight) {
            if (ok)
                travelRestoreOk = true;
            else
                m_travelRestoreFailed = true;
        }
    }
    const QString title = actionTitle(method);
    const QString detail = ok ? actionDetail(method, args) : reply.errorMessage();
    appendWriteLog(ok, title, detail);
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
    if (method == QStringLiteral("SetCoolerBoost"))
        m_coolerBoostAutoOffFiring = false;
    if (method == QStringLiteral("SetBatteryThresholds")) {
        m_travelArming = false;
        m_travelRestoreInFlight = false;
        if (travelRestoreOk)
            clearTravel();
    }
}

void CenterClient::reloadScenes() {
    if (!QFileInfo::exists(scenesFilePath()))
        mergeExampleScenes(false);
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

void CenterClient::addExampleScenes() {
    mergeExampleScenes(true);
    reloadScenes();
}

bool CenterClient::mergeExampleScenes(bool announce) {
    QFile example(QStringLiteral(":/examples/scenes.example.json"));
    if (!example.open(QIODevice::ReadOnly)) {
        if (announce) {
            m_actionError = true;
            m_actionMessage = QStringLiteral("bundled example scenes missing");
            emit changed();
            emit actionDone(false, QStringLiteral("Scenes"), m_actionMessage);
        }
        return false;
    }
    QJsonParseError error{};
    const QJsonDocument exampleDoc =
        QJsonDocument::fromJson(example.readAll(), &error);
    example.close();
    if (error.error != QJsonParseError::NoError || !exampleDoc.isObject()) {
        if (announce) {
            m_actionError = true;
            m_actionMessage = QStringLiteral("invalid bundled example scenes");
            emit changed();
            emit actionDone(false, QStringLiteral("Scenes"), m_actionMessage);
        }
        return false;
    }
    const QJsonArray exampleScenes =
        exampleDoc.object().value(QStringLiteral("scenes")).toArray();

    QJsonArray userScenes;
    QFile user(scenesFilePath());
    if (user.exists()) {
        if (!user.open(QIODevice::ReadOnly)) {
            if (announce) {
                m_actionError = true;
                m_actionMessage =
                    QStringLiteral("cannot read %1").arg(scenesFilePath());
                emit changed();
                emit actionDone(false, QStringLiteral("Scenes"), m_actionMessage);
            }
            return false;
        }
        const QJsonDocument userDoc =
            QJsonDocument::fromJson(user.readAll(), &error);
        user.close();
        if (error.error != QJsonParseError::NoError || !userDoc.isObject()) {
            if (announce) {
                m_actionError = true;
                m_actionMessage = QStringLiteral("invalid %1").arg(scenesFilePath());
                emit changed();
                emit actionDone(false, QStringLiteral("Scenes"), m_actionMessage);
            }
            return false;
        }
        userScenes = userDoc.object().value(QStringLiteral("scenes")).toArray();
    }

    QSet<QString> names;
    for (const QJsonValue &value : userScenes)
        names.insert(value.toObject().value(QStringLiteral("name")).toString());

    QStringList added;
    for (const QJsonValue &value : exampleScenes) {
        const QString name = value.toObject().value(QStringLiteral("name")).toString();
        if (name.isEmpty() || names.contains(name))
            continue;
        userScenes.append(value);
        names.insert(name);
        added << name;
    }

    if (added.isEmpty() && user.exists()) {
        if (announce) {
            m_actionError = false;
            m_actionMessage = QStringLiteral("example scenes already present");
            emit changed();
            emit actionDone(true, QStringLiteral("Scenes"), m_actionMessage);
        }
        return true;
    }

    QJsonObject root;
    root.insert(QStringLiteral("scenes"), userScenes);
    if (!QDir().mkpath(configDir()))
        return false;
    if (!user.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        if (announce) {
            m_actionError = true;
            m_actionMessage = QStringLiteral("cannot write %1").arg(scenesFilePath());
            emit changed();
            emit actionDone(false, QStringLiteral("Scenes"), m_actionMessage);
        }
        return false;
    }
    user.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    user.close();
    if (announce) {
        m_actionError = false;
        m_actionMessage = QStringLiteral("added %1").arg(added.join(QStringLiteral(", ")));
        emit changed();
        emit actionDone(true, QStringLiteral("Scenes"), m_actionMessage);
    }
    return true;
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
        m_batchTitle = QStringLiteral("Scene");
        if (m_lastAppliedScene != name) {
            m_lastAppliedScene = name;
            saveUiSettings();
        }
        emit changed();
        runNextSceneStep();
        return;
    }
    m_actionError = true;
    m_actionMessage = QStringLiteral("scene not found: %1").arg(name);
    emit changed();
}

void CenterClient::panicReset() {
    if (m_sceneApplying)
        return;
    m_sceneSteps = {
        {QStringLiteral("cooler_boost"), QStringLiteral("SetCoolerBoost"),
         {QVariant(false)}},
        {QStringLiteral("super_battery"), QStringLiteral("SetSuperBattery"),
         {QVariant(false)}},
        {QStringLiteral("fan_mode"), QStringLiteral("SetFanMode"),
         {QVariant(QStringLiteral("auto"))}},
    };
    m_sceneResults.clear();
    m_sceneResultText.clear();
    m_sceneStepIndex = 0;
    m_sceneApplying = true;
    m_sceneName = QStringLiteral("Panic reset");
    m_batchTitle = QStringLiteral("Panic reset");
    emit changed();
    runNextSceneStep();
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
    if (settings.value("webcam").isBool()) {
        steps.push_back({QStringLiteral("webcam"), QStringLiteral("SetWebcam"),
                         {QVariant(settings.value("webcam").toBool())}});
    }
    if (settings.value("webcam_block").isBool()) {
        steps.push_back(
            {QStringLiteral("webcam_block"), QStringLiteral("SetWebcamBlock"),
             {QVariant(settings.value("webcam_block").toBool())}});
    }
    const QString fnKey = settings.value("fn_key").toString();
    if (fnKey == QLatin1String("left") || fnKey == QLatin1String("right")) {
        steps.push_back({QStringLiteral("fn_key"), QStringLiteral("SetFnKey"),
                         {QVariant(fnKey)}});
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
            color.toInt(&ok, 16);
            if (ok) {
                QString mode = rgb.value("mode").toString().trimmed().toLower();
                if (mode == QLatin1String("breathing"))
                    mode = QStringLiteral("breath");
                quint8 modeId = 1;
                if (mode == QLatin1String("breath"))
                    modeId = 2;
                else if (mode == QLatin1String("cycle"))
                    modeId = 3;
                else if (mode == QLatin1String("wave"))
                    modeId = 4;
                if (modeId == 1 && (mode.isEmpty() || mode == QLatin1String("steady"))) {
                    const int value = color.toInt(&ok, 16);
                    steps.push_back(
                        {QStringLiteral("rgb"), QStringLiteral("SetRgbColor"),
                         {byte(zones), byte((value >> 16) & 0xff),
                          byte((value >> 8) & 0xff), byte(value & 0xff)}});
                } else if (modeId >= 2) {
                    int speed = rgb.value("speed").toInt(3);
                    if (speed <= 0)
                        speed = 3;
                    if (speed > 600)
                        speed = 600;
                    int direction = rgb.value("wave_direction").toInt(1);
                    if (direction != 0)
                        direction = 1;
                    steps.push_back(
                        {QStringLiteral("rgb"),
                         QStringLiteral("SetRgbPresetEffect"),
                         {byte(zones), byte(modeId),
                          QVariant::fromValue<quint16>(quint16(speed * 100)),
                          QVariant(color), byte(direction)}});
                }
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
        const QString prefix = m_batchTitle.isEmpty() ? QStringLiteral("scene")
                                                      : m_batchTitle;
        m_sceneResultText = QStringLiteral("%1: %2 ok, %3 failed")
                                .arg(prefix)
                                .arg(m_sceneResults.size() - failed)
                                .arg(failed);
        for (const QString &line : m_sceneResults)
            m_sceneResultText += QStringLiteral("\n") + line;
        emit changed();
        refreshNow();
        const QString title = m_batchTitle.isEmpty() ? QStringLiteral("Scene")
                                                     : m_batchTitle;
        emit actionDone(failed == 0, title,
                        QStringLiteral("'%1': %2 ok, %3 failed")
                            .arg(m_sceneName)
                            .arg(m_sceneResults.size() - failed)
                            .arg(failed));
        if (!m_pendingPowerScene.isEmpty()) {
            const QString pending = m_pendingPowerScene;
            m_pendingPowerScene.clear();
            QTimer::singleShot(0, this, [this, pending] { applyScene(pending); });
        }
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
    if (m_coolerBoostOffTimer.isActive()) {
        if (m_coolerBoost)
            m_coolerBoostSeenOnDuringTimer = true;
        else if (m_coolerBoostSeenOnDuringTimer)
            cancelCoolerBoostAutoOff();
    }
    const QJsonValue superBattery = ec.value("super_battery");
    m_hasSuperBattery = superBattery.isBool();
    m_superBattery = superBattery.toBool(false);
    const QJsonValue webcam = ec.value("webcam");
    m_hasWebcam = webcam.isBool();
    m_webcamOn = webcam.toBool(false);
    const QJsonValue webcamBlock = ec.value("webcam_block");
    m_hasWebcamBlock = webcamBlock.isBool();
    m_webcamBlockOn = webcamBlock.toBool(false);
    if (!m_hasWebcam) {
        m_webcamText = QStringLiteral("unavailable");
    } else if (webcamBlock.isBool() && webcamBlock.toBool()) {
        m_webcamText = QStringLiteral("blocked");
    } else {
        m_webcamText = m_webcamOn ? QStringLiteral("on") : QStringLiteral("off");
    }
    const QString fnKey = ec.value("fn_key").toString();
    m_fnKey = fnKey;
    const QString winKey = ec.value("win_key").toString();
    if (fnKey.isEmpty() && winKey.isEmpty()) {
        m_fnWinText = QStringLiteral("unavailable");
    } else {
        m_fnWinText = QStringLiteral("Fn %1 · Win %2")
                          .arg(fnKey.isEmpty() ? QStringLiteral("?") : fnKey,
                               winKey.isEmpty() ? QStringLiteral("?") : winKey);
    }
    m_ecFirmwareDate = ec.value("firmware_date").toString();
    const int cpu = ec.value("cpu_temperature_c").toInt(-1);
    const int gpu = ec.value("gpu_temperature_c").toInt(-1);
    // 0 or missing means the sensor is not readable (e.g. the dGPU is
    // powered off); show n/a instead of an impossible 0 C.
    auto temp = [](int value) {
        return value > 0 ? QStringLiteral("%1 °C").arg(value)
                         : QStringLiteral("n/a");
    };
    m_ecTemps = QStringLiteral("%1 / %2 (cpu / gpu)").arg(temp(cpu), temp(gpu));
    m_cpuTemp = cpu;
    m_gpuTemp = gpu;
    maybeTemperatureAlert();
    maybeRecordHistory();
}

void CenterClient::parseFans(const QJsonArray &fans) {
    QStringList parts;
    QStringList rpms;
    for (const QJsonValue &value : fans) {
        const QJsonObject fan = value.toObject();
        const int rpm = fan.value("rpm").toInt();
        parts << QStringLiteral("%1: %2 rpm")
                     .arg(fan.value("channel").toString(),
                          QString::number(rpm));
        if (rpm > 0)
            rpms << QString::number(rpm);
    }
    m_fanText = parts.isEmpty() ? QStringLiteral("unavailable")
                                : parts.join(QStringLiteral(", "));
    m_fanRpmShort = rpms.isEmpty() ? QString()
                                   : rpms.join(QLatin1Char('/')) + QStringLiteral(" rpm");
    int rpmMax = 0;
    for (const QString &rpm : rpms)
        rpmMax = qMax(rpmMax, rpm.toInt());
    m_fanRpmMax = rpmMax;
    maybeRecordHistory();
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
    const QString status = battery.value("status").toString();
    const bool discharging =
        status.compare(QLatin1String("Discharging"), Qt::CaseInsensitive) == 0;
    const bool charging =
        status.compare(QLatin1String("Charging"), Qt::CaseInsensitive) == 0;
    if (discharging)
        maybeSwitchPowerScene(false);
    else if (charging
             || status.compare(QLatin1String("Full"), Qt::CaseInsensitive) == 0
             || status.compare(QLatin1String("Not charging"), Qt::CaseInsensitive)
                    == 0)
        maybeSwitchPowerScene(true);
    maybeBatteryLevelRules(m_capacity, discharging, charging);
    maybeRestoreTravel();
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
    return configDir() + QStringLiteral("/scenes.json");
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

void CenterClient::copyDiagnosticReport() {
    if (m_diagnosticReport.trimmed().isEmpty()) {
        emit actionDone(false, QStringLiteral("Diagnostics"),
                        QStringLiteral("report not loaded yet"));
        return;
    }
    QGuiApplication::clipboard()->setText(m_diagnosticReport);
    emit actionDone(true, QStringLiteral("Diagnostics"),
                    QStringLiteral("report copied (serials redacted)"));
}
