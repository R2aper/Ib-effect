#pragma once

#include "services.h"

class AppServices final : public QObject {
  Q_OBJECT
  Q_PROPERTY(QString providerMode READ providerMode CONSTANT)
  Q_PROPERTY(AuthService *auth READ auth CONSTANT)
  Q_PROPERTY(AssetService *assets READ assets CONSTANT)
  Q_PROPERTY(RiskService *risks READ risks CONSTANT)
  Q_PROPERTY(MeasureService *measures READ measures CONSTANT)
  Q_PROPERTY(DashboardService *dashboard READ dashboard CONSTANT)
  Q_PROPERTY(EconomicsService *economics READ economics CONSTANT)

public:
  explicit AppServices(QObject *parent = nullptr);

  QString providerMode() const;
  AuthService *auth() const;
  AssetService *assets() const;
  RiskService *risks() const;
  MeasureService *measures() const;
  DashboardService *dashboard() const;
  EconomicsService *economics() const;

private:
  DataProvider *m_provider;
  AuthService *m_auth;
  AssetService *m_assets;
  RiskService *m_risks;
  MeasureService *m_measures;
  DashboardService *m_dashboard;
  EconomicsService *m_economics;
};
