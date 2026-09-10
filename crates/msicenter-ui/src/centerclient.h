#pragma once

#include <QDateTime>
#include <QJsonArray>
#include <QJsonObject>
#include <QObject>
#include <QStringList>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <functional>
#include <QVector>

class QDBusMessage;

// Thin, read-only-ish D-Bus client for org.msilinux.Center.
// Milestone 1: fetch JSON properties and expose parsed summaries to QML.
// Milestone 2: write controls call the daemon's gated methods; Polkit,
// firmware and opt-in gates are enforced daemon-side, the UI only reports
// the daemon's reply or error verbatim.
class CenterClient : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString profileText READ profileText NOTIFY changed)
    Q_PROPERTY(QString supportText READ supportText NOTIFY changed)
    Q_PROPERTY(QString ecFirmware READ ecFirmware NOTIFY changed)
    Q_PROPERTY(QString ecShift READ ecShift NOTIFY changed)
    Q_PROPERTY(QString ecFanMode READ ecFanMode NOTIFY changed)
    Q_PROPERTY(QStringList fanModes READ fanModes NOTIFY changed)
    Q_PROPERTY(bool coolerBoostOn READ coolerBoostOn NOTIFY changed)
    Q_PROPERTY(bool coolerBoostValid READ coolerBoostValid NOTIFY changed)
    Q_PROPERTY(int coolerBoostAutoOffSeconds READ coolerBoostAutoOffSeconds
                   WRITE setCoolerBoostAutoOffSeconds NOTIFY changed)
    Q_PROPERTY(int coolerBoostRemainingSeconds READ coolerBoostRemainingSeconds
                   NOTIFY changed)
    Q_PROPERTY(bool superBatteryOn READ superBatteryOn NOTIFY changed)
    Q_PROPERTY(bool superBatteryValid READ superBatteryValid NOTIFY changed)
    Q_PROPERTY(QString webcamText READ webcamText NOTIFY changed)
    Q_PROPERTY(bool webcamOn READ webcamOn NOTIFY changed)
    Q_PROPERTY(bool webcamValid READ webcamValid NOTIFY changed)
    Q_PROPERTY(bool webcamBlockOn READ webcamBlockOn NOTIFY changed)
    Q_PROPERTY(bool webcamBlockValid READ webcamBlockValid NOTIFY changed)
    Q_PROPERTY(QString fnWinText READ fnWinText NOTIFY changed)
    Q_PROPERTY(QString fnKey READ fnKey NOTIFY changed)
    Q_PROPERTY(QString ecFirmwareDate READ ecFirmwareDate NOTIFY changed)
    Q_PROPERTY(QString ecTemps READ ecTemps NOTIFY changed)
    Q_PROPERTY(QString fanText READ fanText NOTIFY changed)
    Q_PROPERTY(QVariantList fanEntries READ fanEntries NOTIFY changed)
    Q_PROPERTY(QVariantList cpuCores READ cpuCores NOTIFY changed)
    Q_PROPERTY(QVariantList gpus READ gpus NOTIFY changed)
    Q_PROPERTY(QString batteryState READ batteryState NOTIFY changed)
    Q_PROPERTY(int capacityPercent READ capacityPercent NOTIFY changed)
    Q_PROPERTY(int chargeStartPercent READ chargeStartPercent NOTIFY changed)
    Q_PROPERTY(int chargeEndPercent READ chargeEndPercent NOTIFY changed)
    Q_PROPERTY(int travelDays READ travelDays WRITE setTravelDays NOTIFY changed)
    Q_PROPERTY(bool travelActive READ travelActive NOTIFY changed)
    Q_PROPERTY(QString travelRestoreText READ travelRestoreText NOTIFY changed)
    Q_PROPERTY(QString capsText READ capsText NOTIFY changed)
    Q_PROPERTY(QString rgbControllerText READ rgbControllerText NOTIFY changed)
    Q_PROPERTY(QString diagnosticReport READ diagnosticReport NOTIFY changed)
    Q_PROPERTY(QString lastError READ lastError NOTIFY changed)
    Q_PROPERTY(QString actionMessage READ actionMessage NOTIFY changed)
    Q_PROPERTY(bool actionError READ actionError NOTIFY changed)
    Q_PROPERTY(QStringList sceneNames READ sceneNames NOTIFY changed)
    Q_PROPERTY(QString sceneResultText READ sceneResultText NOTIFY changed)
    Q_PROPERTY(bool sceneApplying READ sceneApplying NOTIFY changed)
    Q_PROPERTY(bool restoreSceneOnStart READ restoreSceneOnStart
                   WRITE setRestoreSceneOnStart NOTIFY changed)
    Q_PROPERTY(QString restoreSceneName READ restoreSceneName
                   WRITE setRestoreSceneName NOTIFY changed)
    Q_PROPERTY(QString lastAppliedScene READ lastAppliedScene NOTIFY changed)
    Q_PROPERTY(QStringList restoreSceneChoices READ restoreSceneChoices NOTIFY changed)
    Q_PROPERTY(int restoreSceneChoiceIndex READ restoreSceneChoiceIndex NOTIFY changed)
    Q_PROPERTY(bool powerSceneSwitch READ powerSceneSwitch
                   WRITE setPowerSceneSwitch NOTIFY changed)
    Q_PROPERTY(QString acSceneName READ acSceneName NOTIFY changed)
    Q_PROPERTY(QString batterySceneName READ batterySceneName NOTIFY changed)
    Q_PROPERTY(QString powerSourceText READ powerSourceText NOTIFY changed)
    Q_PROPERTY(QStringList sceneChoicesWithNone READ sceneChoicesWithNone NOTIFY changed)
    Q_PROPERTY(int acSceneChoiceIndex READ acSceneChoiceIndex NOTIFY changed)
    Q_PROPERTY(int batterySceneChoiceIndex READ batterySceneChoiceIndex NOTIFY changed)
    Q_PROPERTY(bool batteryLevelRules READ batteryLevelRules
                   WRITE setBatteryLevelRules NOTIFY changed)
    Q_PROPERTY(int batteryLowPercent READ batteryLowPercent
                   WRITE setBatteryLowPercent NOTIFY changed)
    Q_PROPERTY(int batteryHighPercent READ batteryHighPercent
                   WRITE setBatteryHighPercent NOTIFY changed)
    Q_PROPERTY(int batteryLowSceneChoiceIndex READ batteryLowSceneChoiceIndex NOTIFY changed)
    Q_PROPERTY(int batteryHighSceneChoiceIndex READ batteryHighSceneChoiceIndex NOTIFY changed)
    Q_PROPERTY(bool sceneSchedule READ sceneSchedule WRITE setSceneSchedule NOTIFY changed)
    Q_PROPERTY(QVariantList scheduleRules READ scheduleRules NOTIFY changed)
    Q_PROPERTY(bool tempAlert READ tempAlert WRITE setTempAlert NOTIFY changed)
    Q_PROPERTY(int tempAlertCelsius READ tempAlertCelsius
                   WRITE setTempAlertCelsius NOTIFY changed)
    Q_PROPERTY(int tempAlertHoldSeconds READ tempAlertHoldSeconds
                   WRITE setTempAlertHoldSeconds NOTIFY changed)
    Q_PROPERTY(int tempAlertCooldownSeconds READ tempAlertCooldownSeconds
                   WRITE setTempAlertCooldownSeconds NOTIFY changed)
    Q_PROPERTY(int historyWindowMinutes READ historyWindowMinutes
                   WRITE setHistoryWindowMinutes NOTIFY changed)
    Q_PROPERTY(QVariantList historyCpu READ historyCpu NOTIFY changed)
    Q_PROPERTY(QVariantList historyRpm READ historyRpm NOTIFY changed)
    Q_PROPERTY(int historyMaxRpm READ historyMaxRpm NOTIFY changed)
    Q_PROPERTY(QString writeLogText READ writeLogText NOTIFY changed)

public:
    explicit CenterClient(QObject *parent = nullptr);

    QString profileText() const { return m_profile; }
    QString supportText() const { return m_support; }
    QString ecFirmware() const { return m_ecFirmware; }
    QString ecShift() const { return m_ecShift; }
    QString ecFanMode() const { return m_ecFanMode; }
    QStringList fanModes() const { return m_fanModes; }
    bool coolerBoostOn() const { return m_coolerBoost; }
    bool coolerBoostValid() const { return m_hasCoolerBoost; }
    int coolerBoostAutoOffSeconds() const { return m_coolerBoostAutoOffSeconds; }
    int coolerBoostRemainingSeconds() const;
    bool superBatteryOn() const { return m_superBattery; }
    bool superBatteryValid() const { return m_hasSuperBattery; }
    QString webcamText() const { return m_webcamText; }
    bool webcamOn() const { return m_webcamOn; }
    bool webcamValid() const { return m_hasWebcam; }
    bool webcamBlockOn() const { return m_webcamBlockOn; }
    bool webcamBlockValid() const { return m_hasWebcamBlock; }
    QString fnWinText() const { return m_fnWinText; }
    QString fnKey() const { return m_fnKey; }
    QString ecFirmwareDate() const { return m_ecFirmwareDate; }
    QString ecTemps() const { return m_ecTemps; }
    QString fanText() const { return m_fanText; }
    QVariantList fanEntries() const { return m_fanEntries; }
    QVariantList cpuCores() const { return m_cpuCores; }
    QVariantList gpus() const { return m_gpus; }
    QString fanRpmShort() const { return m_fanRpmShort; }
    QString batteryState() const { return m_battery; }
    int capacityPercent() const { return m_capacity; }
    int chargeStartPercent() const { return m_chargeStart; }
    int chargeEndPercent() const { return m_chargeEnd; }
    int travelDays() const { return m_travelDays; }
    bool travelActive() const { return m_travelActive; }
    QString travelRestoreText() const;
    QString capsText() const { return m_caps; }
    QString rgbControllerText() const { return m_rgbController; }
    QString diagnosticReport() const { return m_diagnosticReport; }
    QString lastError() const { return m_error; }
    QString actionMessage() const { return m_actionMessage; }
    bool actionError() const { return m_actionError; }
    QStringList sceneNames() const { return m_sceneNames; }
    QString sceneResultText() const { return m_sceneResultText; }
    bool sceneApplying() const { return m_sceneApplying; }
    bool restoreSceneOnStart() const { return m_restoreSceneOnStart; }
    QString restoreSceneName() const { return m_restoreSceneName; }
    QString lastAppliedScene() const { return m_lastAppliedScene; }
    QStringList restoreSceneChoices() const;
    int restoreSceneChoiceIndex() const;
    bool powerSceneSwitch() const { return m_powerSceneSwitch; }
    QString acSceneName() const { return m_acSceneName; }
    QString batterySceneName() const { return m_batterySceneName; }
    QString powerSourceText() const;
    QStringList sceneChoicesWithNone() const;
    int acSceneChoiceIndex() const;
    int batterySceneChoiceIndex() const;
    bool batteryLevelRules() const { return m_batteryLevelRules; }
    int batteryLowPercent() const { return m_batteryLowPercent; }
    int batteryHighPercent() const { return m_batteryHighPercent; }
    int batteryLowSceneChoiceIndex() const;
    int batteryHighSceneChoiceIndex() const;
    bool sceneSchedule() const { return m_sceneSchedule; }
    QVariantList scheduleRules() const;
    bool tempAlert() const { return m_tempAlert; }
    int tempAlertCelsius() const { return m_tempAlertCelsius; }
    int tempAlertHoldSeconds() const { return m_tempAlertHoldSeconds; }
    int tempAlertCooldownSeconds() const { return m_tempAlertCooldownSeconds; }
    int historyWindowMinutes() const { return m_historyWindowMinutes; }
    QVariantList historyCpu() const;
    QVariantList historyRpm() const;
    int historyMaxRpm() const;
    QString writeLogText() const { return m_writeLogLines.join(QLatin1Char('\n')); }
    int cpuTempC() const { return m_cpuTemp; }
    int gpuTempC() const { return m_gpuTemp; }

    // First full refresh summary for console/CI use ("connected: ...").
    QString summary() const {
        return QStringLiteral(
                   "connected: profile=%1 support=%2 fan_mode=%3 fan=%4 battery=%5")
            .arg(m_profile, m_support, m_ecFanMode, m_fanText, m_battery);
    }

public slots:
    void refreshNow();
    void fetchAll();
    void setFanMode(const QString &mode);
    void setCoolerBoost(bool enabled);
    void setCoolerBoostAutoOffSeconds(int seconds);
    void setSuperBattery(bool enabled);
    void setWebcam(bool enabled);
    void setWebcamBlock(bool enabled);
    void setFnKey(const QString &position);
    void setBatteryThresholds(int start, int end);
    void setTravelDays(int days);
    void startTravel(int days);
    void cancelTravel();
    void setRgbColorFromHex(int zones, const QString &hex);
    void setRgbEffectPreset(int zones, int mode, int speedSeconds,
                            const QString &hex, int waveDirection = 1);
    void reloadScenes();
    void applyScene(const QString &name);
    void setRestoreSceneOnStart(bool enabled);
    void setRestoreSceneName(const QString &name);
    void setRestoreSceneChoiceIndex(int index);
    void setPowerSceneSwitch(bool enabled);
    void setAcSceneChoiceIndex(int index);
    void setBatterySceneChoiceIndex(int index);
    void setBatteryLevelRules(bool enabled);
    void setBatteryLowPercent(int percent);
    void setBatteryHighPercent(int percent);
    void setBatteryLowSceneChoiceIndex(int index);
    void setBatteryHighSceneChoiceIndex(int index);
    void setSceneSchedule(bool enabled);
    void addScheduleRule();
    void removeScheduleRule(int index);
    void toggleScheduleDay(int index, int dayBit);
    void setScheduleRuleStart(int index, int hour, int minute);
    void setScheduleRuleEnd(int index, int hour, int minute);
    void setScheduleRuleScene(int index, int sceneChoiceIndex);
    void setTempAlert(bool enabled);
    void setTempAlertCelsius(int celsius);
    void setTempAlertHoldSeconds(int seconds);
    void setTempAlertCooldownSeconds(int seconds);
    void setHistoryWindowMinutes(int minutes);
    void copyHistoryCsv();
    void copyWriteLog();
    void panicReset();
    void addExampleScenes();
    Q_INVOKABLE void importScenes();
    Q_INVOKABLE void exportScenes();
    Q_INVOKABLE void copyDiagnosticReport();

signals:
    void changed();
    // One-shot write feedback for the OSD overlay: ok flag, a short human
    // title ("Fan mode", "Scene"...) and a one-line detail.
    void actionDone(bool ok, const QString &title, const QString &detail);

private:
    enum class ActionContext {
        Regular,
        Scene,
        TravelArming,
        TravelRestore,
    };

    struct SceneStep {
        QString label;
        QString method;
        QVariantList args;
    };

    void start();
    void fetchProperty(const QString &iface, const QString &property,
                       quint64 refreshGeneration);
    void handleJson(const QString &property, const QString &json,
                    quint64 refreshGeneration);
    void requestBatteryThresholds(int start, int end, ActionContext context);
    void callMethod(const QString &method, const QVariantList &args,
                    ActionContext context = ActionContext::Regular);
    QString configDir() const;
    QString scenesFilePath() const;
    bool mergeExampleScenes(bool announce);
    QString uiSettingsFilePath() const;
    QString writeLogFilePath() const;
    void loadWriteLog();
    void appendWriteLog(bool ok, const QString &title, const QString &detail);
    void loadUiSettings();
    void saveUiSettings();
    void armCoolerBoostAutoOff();
    void cancelCoolerBoostAutoOff();
    void onCoolerBoostAutoOffTimeout();
    void maybeRestoreTravel();
    void clearTravel();
    void maybeApplyStartupScene();
    void maybeSwitchPowerScene(bool onAc);
    void maybeBatteryLevelRules(int capacity, bool discharging, bool charging);
    void applyNamedAutoScene(const QString &name);
    void maybeApplySchedule();
    void maybeTemperatureAlert();
    void maybeRecordHistory();
    void trimHistory(qint64 nowMs);
    int matchingScheduleRule(const QDateTime &when) const;
    void loadScheduleRules(const QJsonArray &rules);
    QJsonArray scheduleRulesJson() const;
    int sceneChoiceIndex(const QString &name) const;
    void setSceneChoiceName(QString *dest, int index);
    void handleAction(const QString &method, const QVariantList &args,
                      const QDBusMessage &reply, quint64 requestId,
                      ActionContext context);
    QString actionTitle(const QString &method,
                        ActionContext context = ActionContext::Regular) const;
    QString actionDetail(const QString &method, const QVariantList &args,
                         ActionContext context = ActionContext::Regular) const;
    void parseEc(const QJsonObject &ec);
    void parseFans(const QJsonArray &fans);
    void parseCpuCores(const QJsonArray &cores);
    void parseGpus(const QJsonArray &gpus);
    void parseBattery(const QJsonObject &battery);
    void parseCaps(const QJsonArray &caps);
    QVector<SceneStep> sceneSteps(const QJsonObject &settings) const;
    void runNextSceneStep();

    QString m_profile;
    QString m_support;
    QString m_ecFirmware;
    QString m_ecShift;
    QString m_ecFanMode;
    QStringList m_fanModes;
    bool m_coolerBoost = false;
    bool m_hasCoolerBoost = false;
    bool m_superBattery = false;
    bool m_hasSuperBattery = false;
    bool m_webcamOn = false;
    bool m_hasWebcam = false;
    bool m_webcamBlockOn = false;
    bool m_hasWebcamBlock = false;
    QString m_webcamText;
    QString m_fnWinText;
    QString m_fnKey;
    QString m_ecFirmwareDate;
    QString m_ecTemps;
    QString m_fanText;
    QVariantList m_fanEntries;
    QVariantList m_cpuCores;
    QVariantList m_gpus;
    QString m_fanRpmShort;
    QString m_battery;
    int m_capacity = -1;
    int m_chargeStart = -1;
    int m_chargeEnd = -1;
    QString m_caps;
    QString m_rgbController;
    QString m_diagnosticReport;
    QString m_error;
    QString m_actionMessage;
    bool m_actionError = false;
    int m_cpuTemp = -1;
    int m_gpuTemp = -1;
    QTimer m_timer;
    QTimer m_coolerBoostOffTimer;
    QTimer m_coolerBoostTick;
    int m_coolerBoostAutoOffSeconds = 0;
    bool m_coolerBoostAutoOffFiring = false;
    bool m_coolerBoostSeenOnDuringTimer = false;
    int m_travelDays = 7;
    bool m_travelActive = false;
    int m_travelRestoreStart = -1;
    int m_travelRestoreEnd = -1;
    QDateTime m_travelRestoreAt;
    bool m_travelArming = false;
    bool m_travelRestoreInFlight = false;
    bool m_travelRestoreFailed = false;
    quint64 m_nextActionId = 0;
    quint64 m_sceneRequestId = 0;
    quint64 m_travelRequestId = 0;
    int m_inFlight = 0;
    bool m_loggedFirstSummary = false;
    quint64 m_refreshGeneration = 0;
    QJsonArray m_scenes;
    QStringList m_sceneNames;
    QVector<SceneStep> m_sceneSteps;
    QStringList m_sceneResults;
    QString m_sceneResultText;
    int m_sceneStepIndex = 0;
    bool m_sceneApplying = false;
    QString m_sceneName;
    QString m_batchTitle;
    bool m_restoreSceneOnStart = false;
    QString m_restoreSceneName;
    QString m_lastAppliedScene;
    bool m_startupRestoreDone = false;
    int m_startupRestoreDeferrals = 0;
    bool m_powerSceneSwitch = false;
    QString m_acSceneName;
    QString m_batterySceneName;
    bool m_powerOnAc = false;
    bool m_powerOnAcKnown = false;
    QString m_pendingPowerScene;
    bool m_batteryLevelRules = false;
    int m_batteryLowPercent = 30;
    int m_batteryHighPercent = 80;
    QString m_batteryLowScene;
    QString m_batteryHighScene;
    int m_lastCapacity = -1;
    struct ScheduleRule {
        quint8 days = 0;
        int startMinute = 9 * 60;
        int endMinute = 17 * 60;
        QString scene;
    };
    bool m_sceneSchedule = false;
    QVector<ScheduleRule> m_scheduleRules;
    int m_activeScheduleRule = -2;
    static constexpr int kMaxScheduleRules = 8;
    bool m_tempAlert = false;
    int m_tempAlertCelsius = 90;
    int m_tempAlertHoldSeconds = 10;
    int m_tempAlertCooldownSeconds = 120;
    QDateTime m_tempOverSince;
    QDateTime m_tempAlertLast;
    struct HistorySample {
        qint64 ms = 0;
        int cpu = -1;
        int rpm = 0;
    };
    QVector<HistorySample> m_history;
    qint64 m_lastHistoryMs = 0;
    int m_fanRpmMax = 0;
    int m_historyWindowMinutes = 15;
    QStringList m_writeLogLines;
    static constexpr int kMaxWriteLogLines = 200;
    std::function<void(bool, const QString &)> m_actionCallback;
};
