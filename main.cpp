#include <QGuiApplication>
#include <QQmlContext>
#include <QQmlApplicationEngine>

#include "RiskCalculator.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);

    RiskCalculator riskCalculator;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("riskCalculator", &riskCalculator);
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("New", "Main");

    return QGuiApplication::exec();
}
