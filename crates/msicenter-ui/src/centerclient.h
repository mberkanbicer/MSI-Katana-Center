#pragma once

#include <QJsonArray>
#include <QJsonObject>
#include <QObject>
#include <QStringList>
#include <QTimer>
#include <QVariantList>
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
    Q_PROPERTY(bool superBatteryOn READ superBatteryOn NOTIFY changed)
    Q_PROPERTY(bool superBatteryValid READ superBatteryValid NOTIFY changed)
    Q_PROPERTY(QString ecTemps READ ecTemps NOTIFY changed)
    Q_PROPERTY(QString fanText READ fanText NOTIFY changed)
    Q_PROPERTY(QString batteryState READ batteryState NOTIFY changed)
    Q_PROPERTY(int capacityPercent READ capacityPercent NOTIFY changed)
    Q_PROPERTY(int chargeStartPercent READ chargeStartPercent NOTIFY changed)
    Q_PROPERTY(int chargeEndPercent READ chargeEndPercent NOTIFY changed)
    Q_PROPERTY(QString capsText READ capsText NOTIFY changed)
    Q_PROPERTY(QString rgbControllerText READ rgbControllerText NOTIFY changed)
    Q_PROPERTY(QString lastError READ lastError NOTIFY changed)
    Q_PROPERTY(QString actionMessage READ actionMessage NOTIFY changed)
    Q_PROPERTY(bool actionError READ actionError NOTIFY changed)
    Q_PROPERTY(QStringList sceneNames READ sceneNames NOTIFY changed)
    Q_PROPERTY(QString sceneResultText READ sceneResultText NOTIFY changed)
    Q_PROPERTY(bool sceneApplying READ sceneApplying NOTIFY changed)

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
    bool superBatteryOn() const { return m_superBattery; }
    bool superBatteryValid() const { return m_hasSuperBattery; }
    QString ecTemps() const { return m_ecTemps; }
    QString fanText() const { return m_fanText; }
    QString batteryState() const { return m_battery; }
    int capacityPercent() const { return m_capacity; }
    int chargeStartPercent() const { return m_chargeStart; }
    int chargeEndPercent() const { return m_chargeEnd; }
    QString capsText() const { return m_caps; }
    QString rgbControllerText() const { return m_rgbController; }
    QString lastError() const { return m_error; }
    QString actionMessage() const { return m_actionMessage; }
    bool actionError() const { return m_actionError; }
    QStringList sceneNames() const { return m_sceneNames; }
    QString sceneResultText() const { return m_sceneResultText; }
    bool sceneApplying() const { return m_sceneApplying; }
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
    void setSuperBattery(bool enabled);
    void setBatteryThresholds(int start, int end);
    void setRgbColorFromHex(int zones, const QString &hex);
    void setRgbEffectPreset(int zones, int mode, int speedSeconds,
                            const QString &hex, int waveDirection = 1);
    void reloadScenes();
    void applyScene(const QString &name);
    Q_INVOKABLE void importScenes();
    Q_INVOKABLE void exportScenes();

signals:
    void changed();
    // One-shot write feedback for the OSD overlay: ok flag, a short human
    // title ("Fan mode", "Scene"...) and a one-line detail.
    void actionDone(bool ok, const QString &title, const QString &detail);

private:
    struct SceneStep {
        QString label;
        QString method;
        QVariantList args;
    };

    void start();
    void fetchProperty(const QString &iface, const QString &property);
    void handleJson(const QString &property, const QString &json);
    void callMethod(const QString &method, const QVariantList &args);
    QString scenesFilePath() const;
    void handleAction(const QString &method, const QVariantList &args,
                      const QDBusMessage &reply);
    QString actionTitle(const QString &method) const;
    QString actionDetail(const QString &method, const QVariantList &args) const;
    void parseEc(const QJsonObject &ec);
    void parseFans(const QJsonArray &fans);
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
    QString m_ecTemps;
    QString m_fanText;
    QString m_battery;
    int m_capacity = -1;
    int m_chargeStart = -1;
    int m_chargeEnd = -1;
    QString m_caps;
    QString m_rgbController;
    QString m_error;
    QString m_actionMessage;
    bool m_actionError = false;
    int m_cpuTemp = -1;
    int m_gpuTemp = -1;
    QTimer m_timer;
    int m_inFlight = 0;
    bool m_loggedFirstSummary = false;
    QJsonArray m_scenes;
    QStringList m_sceneNames;
    QVector<SceneStep> m_sceneSteps;
    QStringList m_sceneResults;
    QString m_sceneResultText;
    int m_sceneStepIndex = 0;
    bool m_sceneApplying = false;
    QString m_sceneName;
    std::function<void(bool, const QString &)> m_actionCallback;
};
