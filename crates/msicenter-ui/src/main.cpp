#include "centerclient.h"

#include <QAction>
#include <QApplication>
#include <QDebug>
#include <QMenu>
#include <QPixmap>
#include <QPainter>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QSystemTrayIcon>

// Builds a small amber "M" pixmap for the tray icon without depending on
// an icon theme.
static QIcon makeTrayIcon() {
    QPixmap pixmap(64, 64);
    pixmap.fill(Qt::transparent);
    QPainter painter(&pixmap);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.setPen(Qt::NoPen);
    painter.setBrush(QColor("#E2A35B"));
    painter.drawRoundedRect(6, 6, 52, 52, 14, 14);
    painter.setBrush(QColor("#1B1815"));
    QFont font = painter.font();
    font.setPixelSize(30);
    font.setBold(true);
    painter.setFont(font);
    painter.drawText(pixmap.rect(), Qt::AlignCenter, QStringLiteral("M"));
    return QIcon(pixmap);
}

// Quick actions below only trigger the same Polkit-gated daemon methods as
// the UI pages; opt-in/firmware gates and Polkit prompts still apply.
struct TrayStatus {
    QAction *line = nullptr;

    void refresh(CenterClient *client) {
        if (!line)
            return;
        const QStringList parts = {
            QStringLiteral("fan %1").arg(client->ecFanMode()),
            QStringLiteral("cb %1").arg(client->coolerBoostValid()
                                            ? (client->coolerBoostOn()
                                                   ? QStringLiteral("on")
                                                   : QStringLiteral("off"))
                                            : QStringLiteral("n/a")),
            QStringLiteral("sb %1").arg(client->superBatteryValid()
                                            ? (client->superBatteryOn()
                                                   ? QStringLiteral("on")
                                                   : QStringLiteral("off"))
                                            : QStringLiteral("n/a"))};
        QString battery = QStringLiteral("bat n/a");
        if (client->capacityPercent() >= 0)
            battery = QStringLiteral("bat %1%").arg(client->capacityPercent());
        line->setText(parts.join(QStringLiteral(" · ")) + QStringLiteral(" · ") + battery);
    }
};

    struct QuickActions {
    QMenu *fanMenu = nullptr;
    QAction *coolerBoostOn = nullptr;
    QAction *coolerBoostOff = nullptr;
    QAction *superBatteryOn = nullptr;
    QAction *superBatteryOff = nullptr;
    QStringList lastFanModes;

    void refresh(CenterClient *client) {
        const QStringList modes = client->fanModes();
        if (modes != lastFanModes && !modes.isEmpty()) {
            lastFanModes = modes;
            fanMenu->clear();
            for (const QString &mode : modes) {
                QString label = mode;
                if (!label.isEmpty())
                    label[0] = label[0].toUpper();
                QAction *action = fanMenu->addAction(label);
                action->setCheckable(true);
                QObject::connect(action, &QAction::triggered, client,
                                 [client, mode] { client->setFanMode(mode); });
            }
        }
        const auto actions = fanMenu->actions();
        const QString current = client->ecFanMode();
        for (QAction *action : actions)
            action->setChecked(action->text().compare(current,
                                                      Qt::CaseInsensitive) == 0);
        coolerBoostOn->setChecked(client->coolerBoostOn());
        coolerBoostOff->setChecked(!client->coolerBoostOn());
        superBatteryOn->setChecked(client->superBatteryOn());
        superBatteryOff->setChecked(!client->superBatteryOn());
    }
};

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("msicenter-ui"));
    app.setApplicationDisplayName(QStringLiteral("MSI Linux Center"));
    QQuickStyle::setStyle(QStringLiteral("Material"));

    CenterClient client;
    qInfo().noquote() << "msicenter-ui starting";
    QQmlApplicationEngine engine;

    const bool trayAvailable = QSystemTrayIcon::isSystemTrayAvailable();
    engine.rootContext()->setContextProperty(QStringLiteral("center"), &client);
    engine.rootContext()->setContextProperty(QStringLiteral("trayAvailable"),
                                             trayAvailable);
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    QSystemTrayIcon tray;
    if (trayAvailable) {
        tray.setIcon(makeTrayIcon());
        tray.setToolTip(QStringLiteral("MSI Linux Center"));
        QMenu *menu = new QMenu();
        TrayStatus trayStatus;
        trayStatus.line = menu->addAction(QStringLiteral("connecting…"));
        trayStatus.line->setEnabled(false);
        menu->addSeparator();
        QAction *toggleAction = menu->addAction(QStringLiteral("Show / Hide"));
        QAction *refreshAction = menu->addAction(QStringLiteral("Refresh"));

        QMenu *quickMenu = menu->addMenu(QStringLiteral("Quick actions"));
        QuickActions quick;
        quick.fanMenu = quickMenu->addMenu(QStringLiteral("Fan mode"));
        quick.coolerBoostOn = quickMenu->addAction(QStringLiteral("Cooler Boost: on"));
        quick.coolerBoostOff = quickMenu->addAction(QStringLiteral("Cooler Boost: off"));
        quick.superBatteryOn = quickMenu->addAction(QStringLiteral("Super Battery: on"));
        quick.superBatteryOff = quickMenu->addAction(QStringLiteral("Super Battery: off"));
        for (auto *action : {quick.coolerBoostOn, quick.coolerBoostOff}) {
            action->setCheckable(true);
            const bool enabled = action == quick.coolerBoostOn;
            QObject::connect(action, &QAction::triggered, &client,
                             [&client, enabled] { client.setCoolerBoost(enabled); });
        }
        for (auto *action : {quick.superBatteryOn, quick.superBatteryOff}) {
            action->setCheckable(true);
            const bool enabled = action == quick.superBatteryOn;
            QObject::connect(action, &QAction::triggered, &client,
                             [&client, enabled] { client.setSuperBattery(enabled); });
        }
        QObject::connect(&client, &CenterClient::changed, &client,
                         [&quick, &client, &trayStatus, &tray] {
                             trayStatus.refresh(&client);
                             tray.setToolTip(trayStatus.line->text());
                             quick.refresh(&client);
                         });

        menu->addSeparator();
        QAction *quitAction = menu->addAction(QStringLiteral("Quit"));
        tray.setContextMenu(menu);

        auto *window =
            qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        const auto toggleWindow = [window]() {
            if (!window)
                return;
            window->setVisible(!window->isVisible());
        };
        QObject::connect(toggleAction, &QAction::triggered, window, toggleWindow);
        QObject::connect(refreshAction, &QAction::triggered, &client,
                         &CenterClient::refreshNow);
        QObject::connect(quitAction, &QAction::triggered, &app,
                         &QApplication::quit);
        QObject::connect(&tray, &QSystemTrayIcon::activated, window,
                         [toggleWindow](QSystemTrayIcon::ActivationReason reason) {
                             if (reason == QSystemTrayIcon::Trigger)
                                 toggleWindow();
                         });
        tray.show();
    }

    return app.exec();
}
