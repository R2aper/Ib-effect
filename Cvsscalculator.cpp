#include "cvsscalculator.h"

#include <QClipboard>
#include <QDebug>
#include <QGuiApplication>
#include <QHash>
#include <QLatin1String>
#include <QStringList>

#include <algorithm>
#include <cmath>

using namespace Qt::StringLiterals;

namespace Cvss31 {

namespace {

double avWeight(char v) {
  switch (v) {
  case 'N':
    return 0.85;
  case 'A':
    return 0.62;
  case 'L':
    return 0.55;
  case 'P':
    return 0.20;
  }
  return 0.85;
}

double acWeight(char v) { return v == 'H' ? 0.44 : 0.77; }

double prWeight(char v, bool scopeChanged) {
  switch (v) {
  case 'N':
    return 0.85;
  case 'L':
    return scopeChanged ? 0.68 : 0.62;
  case 'H':
    return scopeChanged ? 0.50 : 0.27;
  }
  return 0.85;
}

double uiWeight(char v) { return v == 'R' ? 0.62 : 0.85; }

// C / I / A
double ciaWeight(char v) {
  switch (v) {
  case 'N':
    return 0.00;
  case 'L':
    return 0.22;
  case 'H':
    return 0.56;
  }
  return 0.56;
}

double round1(double v) { return std::round(v * 10.0) / 10.0; }

} // namespace

double roundUp(double value) {
  const long long intInput = std::llround(value * 100000.0);
  if (intInput % 10000 == 0)
    return static_cast<double>(intInput) / 100000.0;
  return static_cast<double>(intInput / 10000 + 1) / 10.0;
}

Result calculate(const Metrics &m) {
  const bool changed = (m.s == 'C');

  const double exploitability = 8.22 * avWeight(m.av) * acWeight(m.ac) *
                                prWeight(m.pr, changed) * uiWeight(m.ui);

  const double iss = 1.0 - (1.0 - ciaWeight(m.c)) * (1.0 - ciaWeight(m.i)) *
                               (1.0 - ciaWeight(m.a));

  const double impact =
      changed ? 7.52 * (iss - 0.029) - 3.25 * std::pow(iss - 0.02, 15)
              : 6.42 * iss;

  Result r;
  r.exploitability = round1(exploitability);
  r.impact = std::max(0.0, round1(impact));

  if (impact <= 0.0)
    r.baseScore = 0.0;
  else if (changed)
    r.baseScore = roundUp(std::min(1.08 * (impact + exploitability), 10.0));
  else
    r.baseScore = roundUp(std::min(impact + exploitability, 10.0));

  return r;
}

} // namespace Cvss31

// ===========================================================================
// QML-обёртка
// ===========================================================================
CvssCalculator::CvssCalculator(QObject *parent) : QObject(parent) { recalc(); }

bool CvssCalculator::assign(QString &field, const QString &value,
                            const char *allowed) {
  if (value.size() != 1 || !QLatin1String(allowed).contains(value.at(0))) {
    qWarning() << "CvssCalculator: недопустимое значение метрики" << value
               << "(допустимо:" << allowed << ")";
    return false;
  }
  if (field == value)
    return false;
  field = value;
  return true;
}

void CvssCalculator::setAv(const QString &v) {
  if (assign(m_av, v, "NALP")) {
    emit avChanged();
    recalc();
  }
}

void CvssCalculator::setAc(const QString &v) {
  if (assign(m_ac, v, "LH")) {
    emit acChanged();
    recalc();
  }
}

void CvssCalculator::setPr(const QString &v) {
  if (assign(m_pr, v, "NLH")) {
    emit prChanged();
    recalc();
  }
}

void CvssCalculator::setUi(const QString &v) {
  if (assign(m_ui, v, "NR")) {
    emit uiChanged();
    recalc();
  }
}

void CvssCalculator::setS(const QString &v) {
  if (assign(m_s, v, "UC")) {
    emit sChanged();
    recalc();
  }
}

void CvssCalculator::setC(const QString &v) {
  if (assign(m_c, v, "NLH")) {
    emit cChanged();
    recalc();
  }
}

void CvssCalculator::setI(const QString &v) {
  if (assign(m_i, v, "NLH")) {
    emit iChanged();
    recalc();
  }
}

void CvssCalculator::setA(const QString &v) {
  if (assign(m_a, v, "NLH")) {
    emit aChanged();
    recalc();
  }
}

void CvssCalculator::recalc() {
  Cvss31::Metrics m;
  m.av = m_av.at(0).toLatin1();
  m.ac = m_ac.at(0).toLatin1();
  m.pr = m_pr.at(0).toLatin1();
  m.ui = m_ui.at(0).toLatin1();
  m.s = m_s.at(0).toLatin1();
  m.c = m_c.at(0).toLatin1();
  m.i = m_i.at(0).toLatin1();
  m.a = m_a.at(0).toLatin1();

  m_result = Cvss31::calculate(m);
  emit resultChanged();
}

QString CvssCalculator::vectorString() const {
  return u"CVSS:3.1/AV:%1/AC:%2/PR:%3/UI:%4/S:%5/C:%6/I:%7/A:%8"_s.arg(
      m_av, m_ac, m_pr, m_ui, m_s, m_c, m_i, m_a);
}

QString CvssCalculator::severityFor(double score) {
  if (score >= 9.0)
    return u"Критический"_s;
  if (score >= 7.0)
    return u"Высокий"_s;
  if (score >= 4.0)
    return u"Средний"_s;
  if (score > 0.0)
    return u"Низкий"_s;

  return u"None"_s;
}

bool CvssCalculator::applyVector(const QString &vector) {
  const QStringList parts = vector.trimmed().split(u'/', Qt::SkipEmptyParts);
  if (parts.size() != 9 || parts.first() != "CVSS:3.1"_L1)
    return false;

  static const struct {
    const char *key;
    const char *allowed;
  } kMetrics[] = {
      {"AV", "NALP"}, {"AC", "LH"}, {"PR", "NLH"}, {"UI", "NR"},
      {"S", "UC"},    {"C", "NLH"}, {"I", "NLH"},  {"A", "NLH"},
  };

  QHash<QString, QString> values;
  for (int k = 1; k < parts.size(); ++k) {
    const int colon = parts.at(k).indexOf(u':');
    if (colon <= 0)
      return false;
    values.insert(parts.at(k).left(colon), parts.at(k).mid(colon + 1));
  }

  for (const auto &mt : kMetrics) {
    const QString v = values.value(QLatin1String(mt.key));
    if (v.size() != 1 || !QLatin1String(mt.allowed).contains(v.at(0)))
      return false;
  }

  bool changed = false;
  auto apply = [&](QString &field, const char *key,
                   void (CvssCalculator::*sig)()) {
    const QString v = values.value(QLatin1String(key));
    if (field != v) {
      field = v;
      (this->*sig)();
      changed = true;
    }
  };
  apply(m_av, "AV", &CvssCalculator::avChanged);
  apply(m_ac, "AC", &CvssCalculator::acChanged);
  apply(m_pr, "PR", &CvssCalculator::prChanged);
  apply(m_ui, "UI", &CvssCalculator::uiChanged);
  apply(m_s, "S", &CvssCalculator::sChanged);
  apply(m_c, "C", &CvssCalculator::cChanged);
  apply(m_i, "I", &CvssCalculator::iChanged);
  apply(m_a, "A", &CvssCalculator::aChanged);

  if (changed)
    recalc();

  return true;
}

void CvssCalculator::copyVectorToClipboard() const {
  if (QClipboard *cb = QGuiApplication::clipboard())
    cb->setText(vectorString());
}
