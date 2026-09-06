#include "centerclient.h"

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

// Builds a small amber "fan/gear" style pixmap for the tray icon without
// depending on an icon theme.
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
        QAction *toggleAction = menu->addAction(QStringLiteral("Show / Hide"));
        QAction *refreshAction = menu->addAction(QStringLiteral("Refresh"));
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
