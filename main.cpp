#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFile>
#include <QTextStream>
#include <QDir>
#include <QDateTime>

class ReportExporter : public QObject {
    Q_OBJECT
public:
    explicit ReportExporter(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE bool saveReport(const QString &fileName, const QString &content) {
        QFile file(fileName);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            return false;
        }
        QTextStream out(&file);
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
        out.setEncoding(QStringConverter::Utf8);
#endif
        out << content;
        file.close();
        return true;
    }
};

#include "main.moc"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    auto *exporter = new ReportExporter(&app);
    engine.rootContext()->setContextProperty("ReportExporter", exporter);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("Ibe", "Main");

    return QCoreApplication::exec();
}
