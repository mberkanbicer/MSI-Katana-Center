#include "centerclient.h"

#include <QDebug>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QGuiApplication>

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("msicenter-ui"));
    app.setApplicationDisplayName(QStringLiteral("MSI Linux Center"));

    CenterClient client;
    qInfo().noquote() << "msicenter-ui starting (read-only dashboard)";
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("center"), &client);
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;
    return app.exec();
}
