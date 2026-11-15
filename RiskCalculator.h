#pragma once

#include <QList>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

namespace RiskModel {
Q_NAMESPACE

// ---------------------------- Коэффициенты ----------------------------

// K: тип компонента ИС (k = 0.5)
enum class ComponentType {
  CriticalBusiness =
      0, // Уязвимости подвержены компоненты системы, обеспечивающие реализацию
         // важных процессов (бизнес-процессов), функций, полномочий
  FirewallGateway, // Уязвимости подвержены межсетевые экраны/сетевые устройства
                   // и шлюзы
  TelecomControl,  // Уязвимости подвержены телекоммуникационное оборудование,
                   // система управления сетью передачи данных
  Server, // Уязвимости подвержены серверы (центральные вычислительные узлы)
  Workstation, // Уязвимости подвержены пользовательские устройства
               // (автоматизированные рабочие места)
  Storage,     // Уязвимости подвержены системы хранения данных
  Other        // Уязвимости подвержены другие компоненты
};
Q_ENUM_NS(ComponentType)

// L: доля уязвимых компонентов (l = 0.2)
enum class ComponentShare {
  Over70 = 0, // > 70 %
  From50To70, // 50-70 %
  From10To50, // 10-50 %
  Under10     // < 10 %
};
Q_ENUM_NS(ComponentShare)

// P: влияние на защиту периметра (p = 0.3)
enum class PerimeterAccess {
  Internet = 0, // Доступно из сети "Интернет"
  Internal      // Недоступно из сети "Интернет"
};
Q_ENUM_NS(PerimeterAccess)

// E: возможность эксплуатации (e = 1.0)
enum class Exploitability {
  RealAttacks = 0, // Эксплуатируется в реальных атаках
  KnownExploit,    // Есть сведения об эксплойте
  Unknown          // Сведений нет
};
Q_ENUM_NS(Exploitability)

// H: последствия эксплуатации (h = 1.0)
enum class Consequence {
  CodeExecOrPrivEsc = 0, // Выполнение кода / повышение привилегий
  SecurityBypass,        // Обход механизмов безопасности
  CodeInjection,         // Внедрение кода
  SensitiveLeak,         // Получение конфиденциальной информации
  DenialOfService,       // DoS
  FileOverwrite,         // Перезапись произвольных файлов
  LocalFileWrite,        // Запись локальных файлов
  LocalFileRead          // Чтение локальных файлов
};
Q_ENUM_NS(Consequence)

// Взвешенные коэффициенты (уже умноженные на k, l, p, e, h)
double coefficient(ComponentType v);   // k * K
double coefficient(ComponentShare v);  // l * L
double coefficient(PerimeterAccess v); // p * P
double coefficient(Exploitability v);  // e * E = I_at
double coefficient(Consequence v);     // h * H = I_imp

} // namespace RiskModel

// ---------------------------- Входные данные ----------------------------

struct ThreatScenario {
  Q_GADGET
  Q_PROPERTY(QString codeBDU MEMBER codeBDU)
  Q_PROPERTY(QString title MEMBER title)
  Q_PROPERTY(bool fromBDU MEMBER fromBDU)
  Q_PROPERTY(double cvssScore MEMBER cvssScore) // I_cvss
  Q_PROPERTY(RiskModel::Exploitability exploitability MEMBER exploitability)
  Q_PROPERTY(RiskModel::Consequence consequence MEMBER consequence)
public:
  QString codeBDU;
  QString title;
  bool fromBDU = false;
  double cvssScore = 0.0;
  RiskModel::Exploitability exploitability = RiskModel::Exploitability::Unknown;
  RiskModel::Consequence consequence =
      RiskModel::Consequence::CodeExecOrPrivEsc;
};

struct CompensatingMeasure {
  Q_GADGET
  Q_PROPERTY(QString name MEMBER name)
  Q_PROPERTY(double costTCO MEMBER costTCO) // руб.
  Q_PROPERTY(bool affectsShare MEMBER affectsShare)
  Q_PROPERTY(bool affectsPerimeter MEMBER affectsPerimeter)
  Q_PROPERTY(RiskModel::ComponentShare newShare MEMBER newShare)
  Q_PROPERTY(RiskModel::PerimeterAccess newPerimeter MEMBER newPerimeter)
public:
  QString name;
  double costTCO = 0.0;
  bool affectsShare = false;
  bool affectsPerimeter = false;
  RiskModel::ComponentShare newShare = RiskModel::ComponentShare::Under10;
  RiskModel::PerimeterAccess newPerimeter =
      RiskModel::PerimeterAccess::Internal;
};

struct AssetKT {
  Q_GADGET
  Q_PROPERTY(QString primaryAssetName MEMBER primaryAssetName)
  Q_PROPERTY(QString supportingAssetName MEMBER supportingAssetName)
  Q_PROPERTY(double directRecoveryCost MEMBER directRecoveryCost)
  Q_PROPERTY(double indirectBusinessLoss MEMBER indirectBusinessLoss)
  Q_PROPERTY(RiskModel::ComponentType componentType MEMBER componentType)
  Q_PROPERTY(RiskModel::ComponentShare share MEMBER share)
  Q_PROPERTY(RiskModel::PerimeterAccess perimeter MEMBER perimeter)
public:
  QString primaryAssetName;
  QString supportingAssetName;
  double directRecoveryCost = 0.0;
  double indirectBusinessLoss = 0.0;
  RiskModel::ComponentType componentType = RiskModel::ComponentType::Other;
  RiskModel::ComponentShare share = RiskModel::ComponentShare::Under10;
  RiskModel::PerimeterAccess perimeter = RiskModel::PerimeterAccess::Internal;

  double totalImpactSLE() const {
    return directRecoveryCost + indirectBusinessLoss;
  }
};

// ---------------------------- Результат расчёта ----------------------------

struct RiskResult {
  Q_GADGET
  Q_PROPERTY(bool valid MEMBER valid)
  Q_PROPERTY(QString error MEMBER error)
  Q_PROPERTY(double assetValue MEMBER assetValue)
  Q_PROPERTY(double iInfrBase MEMBER iInfrBase)
  Q_PROPERTY(double iInfrResidual MEMBER iInfrResidual)
  Q_PROPERTY(double vBase MEMBER vBase)
  Q_PROPERTY(double vResidual MEMBER vResidual)
  Q_PROPERTY(QString criticalityBase MEMBER criticalityBase)
  Q_PROPERTY(QString criticalityResidual MEMBER criticalityResidual)
  Q_PROPERTY(double probabilityBase MEMBER probabilityBase)
  Q_PROPERTY(double probabilityResidual MEMBER probabilityResidual)
  Q_PROPERTY(double aleBase MEMBER aleBase)
  Q_PROPERTY(double aleResidual MEMBER aleResidual)
  Q_PROPERTY(double avoidedLoss MEMBER avoidedLoss)
  Q_PROPERTY(double netBenefit MEMBER netBenefit)
  Q_PROPERTY(double rosiPercent MEMBER rosiPercent)
public:
  bool valid = false;
  QString error;

  double assetValue = 0.0;
  double iInfrBase = 0.0;
  double iInfrResidual = 0.0;
  double vBase = 0.0;
  double vResidual = 0.0;
  QString criticalityBase;
  QString criticalityResidual;
  double probabilityBase = 0.0;
  double probabilityResidual = 0.0;
  double aleBase = 0.0;
  double aleResidual = 0.0;
  double avoidedLoss = 0.0;
  double netBenefit = 0.0;
  double rosiPercent = 0.0;

  QVariantMap toVariantMap() const;
};

// ---------------------------- Главный класс калькулятора ----------------------------

class RiskCalculator : public QObject {
  Q_OBJECT

  // Свойства для списков сущностей
  Q_PROPERTY(QVariantList assets READ assets NOTIFY assetsChanged FINAL)
  Q_PROPERTY(QVariantList vulnerabilities READ vulnerabilities NOTIFY vulnerabilitiesChanged FINAL)
  Q_PROPERTY(QVariantList measures READ measures NOTIFY measuresChanged FINAL)

  // Свойства для вкладки «Экономика»
  Q_PROPERTY(QVariantList economicScenarios READ economicScenarios NOTIFY dataChanged FINAL)
  Q_PROPERTY(QVariantMap portfolioSummary READ portfolioSummary NOTIFY dataChanged FINAL)

  // Финансовые показатели
  Q_PROPERTY(bool hasValidRosi READ hasValidRosi NOTIFY dataChanged FINAL)
  Q_PROPERTY(double netRosiPercent READ netRosiPercent NOTIFY dataChanged FINAL)
  Q_PROPERTY(double netBenefit READ netBenefit NOTIFY dataChanged FINAL)
  Q_PROPERTY(double totalAvoidedLoss READ totalAvoidedLoss NOTIFY dataChanged FINAL)
  Q_PROPERTY(double totalTco READ totalTco NOTIFY dataChanged FINAL)

  // Количественные показатели
  Q_PROPERTY(int totalAssetsCount READ totalAssetsCount NOTIFY assetsChanged FINAL)
  Q_PROPERTY(int totalVulnsCount READ totalVulnsCount NOTIFY vulnerabilitiesChanged FINAL)
  Q_PROPERTY(int totalMeasuresCount READ totalMeasuresCount NOTIFY measuresChanged FINAL)

public:
  explicit RiskCalculator(QObject *parent = nullptr);

  // Статические методы формул
  static double vulnerabilityLevel(double iCvss, double iInfr, double iAt, double iImp);
  static double calcIinfr(RiskModel::ComponentType k, RiskModel::ComponentShare l, RiskModel::PerimeterAccess p);
  static QString criticalityText(double v);
  static QString slaFromV(double v);
  static double probabilityFromV(double v);
  static double calculateCVSS31(const ThreatScenario &threat);

  RiskResult calculate(const AssetKT &asset, const ThreatScenario &threat,
                       const CompensatingMeasure &measure) const;

  Q_INVOKABLE QVariantMap calculateFromMap(const QVariantMap &asset,
                                           const QVariantMap &threat,
                                           const QVariantMap &measure) const;

  // --- Управление активами ---
  Q_INVOKABLE QVariantMap addAsset(const QVariantMap &assetData = QVariantMap());
  Q_INVOKABLE bool updateAsset(const QVariantMap &assetData);
  Q_INVOKABLE bool deleteAsset(const QString &id);
  Q_INVOKABLE QVariantMap getAsset(const QString &id) const;

  // --- Привязка мер и уязвимостей к активам ---
  Q_INVOKABLE bool linkMeasureToAsset(const QString &assetId, const QString &measureIdOrTitle);
  Q_INVOKABLE bool unlinkMeasureFromAsset(const QString &assetId, const QString &measureIdOrTitle);
  Q_INVOKABLE bool linkVulnerabilityToAsset(const QString &assetId, const QString &vulnIdOrTitle);
  Q_INVOKABLE bool unlinkVulnerabilityFromAsset(const QString &assetId, const QString &vulnIdOrTitle);

  // --- Управление уязвимостями ---
  Q_INVOKABLE QVariantMap addVulnerability(const QVariantMap &vulnData = QVariantMap());
  Q_INVOKABLE bool updateVulnerability(const QVariantMap &vulnData);
  Q_INVOKABLE bool deleteVulnerability(const QString &id);
  Q_INVOKABLE QVariantMap getVulnerability(const QString &id) const;

  // --- Управление мерами ---
  Q_INVOKABLE QVariantMap addMeasure(const QVariantMap &measureData = QVariantMap());
  Q_INVOKABLE bool updateMeasure(const QVariantMap &measureData);
  Q_INVOKABLE bool deleteMeasure(const QString &id);
  Q_INVOKABLE QVariantMap getMeasure(const QString &id) const;

  // --- Пересчет и форматирование ---
  Q_INVOKABLE void recalculateAll();
  Q_INVOKABLE QString formatNumber(double value, int decimals = 1) const;
  Q_INVOKABLE QString formatRub(double value) const;
  Q_INVOKABLE QString formatPercent(double value, int decimals = 1) const;

  // Геттеры свойств
  QVariantList assets() const { return m_assets; }
  QVariantList vulnerabilities() const { return m_vulnerabilities; }
  QVariantList measures() const { return m_measures; }
  QVariantList economicScenarios() const { return m_economicScenarios; }
  QVariantMap portfolioSummary() const { return m_portfolioSummary; }

  bool hasValidRosi() const;
  double netRosiPercent() const;
  double netBenefit() const;
  double totalAvoidedLoss() const;
  double totalTco() const;

  int totalAssetsCount() const { return m_assets.size(); }
  int totalVulnsCount() const { return m_vulnerabilities.size(); }
  int totalMeasuresCount() const { return m_measures.size(); }

signals:
  void calculated(const QVariantMap &result);
  void dataChanged();
  void assetsChanged();
  void vulnerabilitiesChanged();
  void measuresChanged();

private:
  void initDefaultData();
  void updateEconomicScenarios();

  QVariantList m_assets;
  QVariantList m_vulnerabilities;
  QVariantList m_measures;
  QVariantList m_economicScenarios;
  QVariantMap m_portfolioSummary;
};
