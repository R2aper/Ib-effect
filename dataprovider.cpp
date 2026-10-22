#include "dataprovider.h"

#include <QTimer>

HttpDataProvider::HttpDataProvider(QObject *parent) : DataProvider(parent) {}

QString HttpDataProvider::modeName() const { return QStringLiteral("http"); }

void HttpDataProvider::request(const QString &requestId,
                               const QString &operation,
                               const QVariantMap &payload) {
  Q_UNUSED(payload);
  QTimer::singleShot(0, this, [this, requestId, operation] {
    emit requestFinished(requestId, operation, false, {},
                         QStringLiteral("TODO: HTTP"));
  });
}

