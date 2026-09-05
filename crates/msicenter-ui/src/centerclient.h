#pragma once

#include <QJsonObject>
#include <QObject>
#include <QTimer>

// Thin, read-only D-Bus client for org.msilinux.Center.
// Milestone 1: fetch JSON properties and expose parsed summaries to QML.
// Writes and Polkit flows are intentionally not implemented yet.
class CenterClient : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString profileText READ profileText NOTIFY changed)
    Q_PROPERTY(QString supportText READ supportText NOTIFY changed)
    Q_PROPERTY(QString ecFirmware READ ecFirmware NOTIFY changed)
    Q_PROPERTY(QString ecShift READ ecShift NOTIFY changed)
    Q_PROPERTY(QString ecFanMode READ ecFanMode NOTIFY changed)
    Q_PROPERTY(QString ecTemps READ ecTemps NOTIFY changed)
    Q_PROPERTY(QString fanText READ fanText NOTIFY changed)
    Q_PROPERTY(QString batteryState READ batteryState NOTIFY changed)
    Q_PROPERTY(QString capsText READ capsText NOTIFY changed)
    Q_PROPERTY(QString lastError READ lastError NOTIFY changed)

public:
    explicit CenterClient(QObject *parent = nullptr);

    QString profileText() const { return m_profile; }
    QString supportText() const { return m_support; }
    QString ecFirmware() const { return m_ecFirmware; }
    QString ecShift() const { return m_ecShift; }
    QString ecFanMode() const { return m_ecFanMode; }
    QString ecTemps() const { return m_ecTemps; }
    QString fanText() const { return m_fanText; }
    QString batteryState() const { return m_battery; }
    QString capsText() const { return m_caps; }
    QString lastError() const { return m_error; }

    // First full refresh summary for console/CI use ("connected: ...").
    QString summary() const {
        return QStringLiteral(
                   "connected: profile=%1 support=%2 fan_mode=%3 fan=%4 battery=%5")
            .arg(m_profile, m_support, m_ecFanMode, m_fanText, m_battery);
    }

public slots:
    void refreshNow();
    void fetchAll();

signals:
    void changed();

private:
    void start();
    void fetchProperty(const QString &iface, const QString &property);
    void handleJson(const QString &property, const QString &json);
    void parseEc(const QJsonObject &ec);
    void parseFans(const QJsonArray &fans);
    void parseBattery(const QJsonObject &battery);
    void parseCaps(const QJsonArray &caps);

    QString m_profile;
    QString m_support;
    QString m_ecFirmware;
    QString m_ecShift;
    QString m_ecFanMode;
    QString m_ecTemps;
    QString m_fanText;
    QString m_battery;
    QString m_caps;
    QString m_error;
    QTimer m_timer;
    int m_inFlight = 0;
    bool m_loggedFirstSummary = false;
};
