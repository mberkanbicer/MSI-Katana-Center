#include "centerclient.h"

#include <QAction>
#include <QApplication>
#include <QDebug>
#include <QKeySequence>
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
        QStringList text = parts;
        if (!client->webcamText().isEmpty()
            && client->webcamText() != QStringLiteral("unavailable")) {
            text << QStringLiteral("cam %1").arg(client->webcamText());
        }
        if (client->cpuTempC() > 0) {
            text << QStringLiteral("cpu %1 °C").arg(client->cpuTempC());
            if (client->gpuTempC() > 0)
                text << QStringLiteral("gpu %1 °C").arg(client->gpuTempC());
        }
        text << (client->capacityPercent() >= 0
                     ? QStringLiteral("bat %1%").arg(client->capacityPercent())
                     : QStringLiteral("bat n/a"));
        line->setText(text.join(QStringLiteral(" · ")));
    }
};

    struct QuickActions {
    QMenu *fanMenu = nullptr;
    QMenu *sceneMenu = nullptr;
    QAction *coolerBoostOn = nullptr;
    QAction *coolerBoostOff = nullptr;
    QAction *superBatteryOn = nullptr;
    QAction *superBatteryOff = nullptr;
    QStringList lastFanModes;
    QStringList lastSceneNames;

    void refresh(CenterClient *client) {
        const QStringList scenes = client->sceneNames();
        if (sceneMenu && scenes != lastSceneNames) {
            lastSceneNames = scenes;
            sceneMenu->clear();
            if (scenes.isEmpty()) {
                QAction *empty = sceneMenu->addAction(QStringLiteral("No scenes"));
                empty->setEnabled(false);
            } else {
                for (const QString &name : scenes) {
                    QAction *action = sceneMenu->addAction(name);
                    QObject::connect(action, &QAction::triggered, client,
                                     [client, name] { client->applyScene(name); });
                }
            }
        }
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
    TrayStatus trayStatus;
    QuickActions quick;
    if (trayAvailable) {
        tray.setIcon(makeTrayIcon());
        tray.setToolTip(QStringLiteral("MSI Linux Center"));
        QMenu *menu = new QMenu();
        trayStatus.line = menu->addAction(QStringLiteral("connecting…"));
        trayStatus.line->setEnabled(false);
        menu->addSeparator();
        QAction *toggleAction = menu->addAction(QStringLiteral("Show / Hide"));
        QAction *refreshAction = menu->addAction(QStringLiteral("Refresh"));

        QMenu *quickMenu = menu->addMenu(QStringLiteral("Quick actions"));
        quick.fanMenu = quickMenu->addMenu(QStringLiteral("Fan mode"));
        quick.sceneMenu = quickMenu->addMenu(QStringLiteral("Apply scene"));

        QMenu *rgbMenu = quickMenu->addMenu(QStringLiteral("Keyboard RGB"));
        const struct {
            const char *label;
            const char *hex;
        } rgbItems[] = {{"Steady red", "ff0000"},  {"Steady green", "00ff00"},
                        {"Steady blue", "0000ff"}, {"Steady amber", "e2a35b"},
                        {"Steady white", "ffffff"}, {"Turn off", "000000"}};
        for (const auto &item : rgbItems) {
            QAction *action = rgbMenu->addAction(QString::fromUtf8(item.label));
            const QString hex = QString::fromUtf8(item.hex);
            QObject::connect(action, &QAction::triggered, &client,
                             [&client, hex] { client.setRgbColorFromHex(15, hex); });
        }
        rgbMenu->addSeparator();
        const struct {
            const char *label;
            int mode;
        } rgbEffects[] = {{"Breathing amber", 2},
                          {"Cycle amber", 3},
                          {"Wave amber", 4}};
        for (const auto &item : rgbEffects) {
            QAction *action = rgbMenu->addAction(QString::fromUtf8(item.label));
            const int mode = item.mode;
            QObject::connect(action, &QAction::triggered, &client, [&client, mode] {
                client.setRgbEffectPreset(15, mode, 3, QStringLiteral("e2a35b"), 1);
            });
        }

        quick.coolerBoostOn = quickMenu->addAction(QStringLiteral("Cooler Boost: on"));
        quick.coolerBoostOff = quickMenu->addAction(QStringLiteral("Cooler Boost: off"));
        quick.superBatteryOn = quickMenu->addAction(QStringLiteral("Super Battery: on"));
        quick.superBatteryOff = quickMenu->addAction(QStringLiteral("Super Battery: off"));
        QAction *webcamOn = quickMenu->addAction(QStringLiteral("Webcam: on"));
        QAction *webcamOff = quickMenu->addAction(QStringLiteral("Webcam: off"));
        QObject::connect(webcamOn, &QAction::triggered, &client,
                         [&client] { client.setWebcam(true); });
        QObject::connect(webcamOff, &QAction::triggered, &client,
                         [&client] { client.setWebcam(false); });
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

        QMenu *shortcutMenu = quickMenu->addMenu(QStringLiteral("Shortcuts"));
        auto addAppShortcut = [shortcutMenu, menu, &client](const QString &label,
                                                            const QString &keys,
                                                            auto handler) {
            auto *action = new QAction(label, menu);
            action->setShortcut(QKeySequence(keys));
            action->setShortcutContext(Qt::ApplicationShortcut);
            shortcutMenu->addAction(action);
            QObject::connect(action, &QAction::triggered, &client, handler);
        };
        addAppShortcut(QStringLiteral("Toggle Cooler Boost"),
                       QStringLiteral("Ctrl+Shift+C"), [&client] {
                           client.setCoolerBoost(!client.coolerBoostOn());
                       });
        addAppShortcut(QStringLiteral("Toggle Super Battery"),
                       QStringLiteral("Ctrl+Shift+B"), [&client] {
                           client.setSuperBattery(!client.superBatteryOn());
                       });
        addAppShortcut(QStringLiteral("Keyboard RGB off"),
                       QStringLiteral("Ctrl+Shift+L"), [&client] {
                           client.setRgbColorFromHex(15, QStringLiteral("000000"));
                       });

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
