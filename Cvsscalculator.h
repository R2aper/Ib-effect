#pragma once

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

namespace Cvss31 {

struct Metrics {
  char av = 'N'; // N, A, L, P
  char ac = 'L'; // L, H
  char pr = 'N'; // N, L, H
  char ui = 'N'; // N, R
  char s = 'U';  // U, C
  char c = 'H';  // N, L, H
  char i = 'H';  // N, L, H
  char a = 'H';  // N, L, H
};

struct Result {
  double baseScore = 0.0; // итоговая оценка (Округлённое до 0.1)
  double exploitability =
      0.0;             // подоценка эксплойтабельности (Округлённое до 0.1)
  double impact = 0.0; // подоценка последствий (Округлённое до 0.1, >= 0)
};

double roundUp(double value);

Result calculate(const Metrics &m);

} // namespace Cvss31

class CvssCalculator : public QObject {
  Q_OBJECT
  QML_ELEMENT

  Q_PROPERTY(QString av READ av WRITE setAv NOTIFY avChanged FINAL)
  Q_PROPERTY(QString ac READ ac WRITE setAc NOTIFY acChanged FINAL)
  Q_PROPERTY(QString pr READ pr WRITE setPr NOTIFY prChanged FINAL)
  Q_PROPERTY(QString ui READ ui WRITE setUi NOTIFY uiChanged FINAL)
  Q_PROPERTY(QString s READ s WRITE setS NOTIFY sChanged FINAL)
  Q_PROPERTY(QString c READ c WRITE setC NOTIFY cChanged FINAL)
  Q_PROPERTY(QString i READ i WRITE setI NOTIFY iChanged FINAL)
  Q_PROPERTY(QString a READ a WRITE setA NOTIFY aChanged FINAL)

  Q_PROPERTY(double score READ score NOTIFY resultChanged FINAL)
  Q_PROPERTY(
      double exploitability READ exploitability NOTIFY resultChanged FINAL)
  Q_PROPERTY(double impact READ impact NOTIFY resultChanged FINAL)
  Q_PROPERTY(QString severity READ severity NOTIFY resultChanged FINAL)
  Q_PROPERTY(QString vectorString READ vectorString NOTIFY resultChanged FINAL)

public:
  explicit CvssCalculator(QObject *parent = nullptr);

  QString av() const { return m_av; }
  QString ac() const { return m_ac; }
  QString pr() const { return m_pr; }
  QString ui() const { return m_ui; }
  QString s() const { return m_s; }
  QString c() const { return m_c; }
  QString i() const { return m_i; }
  QString a() const { return m_a; }

  void setAv(const QString &v);
  void setAc(const QString &v);
  void setPr(const QString &v);
  void setUi(const QString &v);
  void setS(const QString &v);
  void setC(const QString &v);
  void setI(const QString &v);
  void setA(const QString &v);

  double score() const { return m_result.baseScore; }
  double exploitability() const { return m_result.exploitability; }
  double impact() const { return m_result.impact; }
  QString severity() const { return severityFor(m_result.baseScore); }
  QString vectorString() const;

  // Разбор строки вида "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H"
  // При ошибке состояние не меняется, возвращается false
  Q_INVOKABLE bool applyVector(const QString &vector);

  Q_INVOKABLE void copyVectorToClipboard() const;

  // Текстовая оценка по шкале: >=9.0 Критический, >=7.0 Высокий, >=4.0 Средний,
  // >0 Низкий, иначе "None.
  Q_INVOKABLE static QString severityFor(double score);

signals:
  void avChanged();
  void acChanged();
  void prChanged();
  void uiChanged();
  void sChanged();
  void cChanged();
  void iChanged();
  void aChanged();
  void resultChanged();

private:
  // Присваивает значение, если оно допустимо и отличается от текущего.
  static bool assign(QString &field, const QString &value, const char *allowed);
  void recalc();

  QString m_av = QStringLiteral("N");
  QString m_ac = QStringLiteral("L");
  QString m_pr = QStringLiteral("N");
  QString m_ui = QStringLiteral("N");
  QString m_s = QStringLiteral("U");
  QString m_c = QStringLiteral("H");
  QString m_i = QStringLiteral("H");
  QString m_a = QStringLiteral("H");

  Cvss31::Result m_result;
};
