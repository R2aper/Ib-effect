 package main

import (
  "fmt"
  "math"
)

// ============================================================================
// 1. ВСТРОЕННЫЙ КАЛЬКУЛЯТОР CVSS 3.1 (п. 13 Методики ФСТЭК 2025 г., стр. 4-5)
// Точная реализация формулы https://bdu.fstec.ru/calc31 и FIRST.org CVSS v3.1
// ============================================================================

type CVSS31Vector struct {
  AV float64 // Вектор атаки: Network=0.85, Adjacent=0.62, Local=0.55, Physical=0.20
  AC float64 // Сложность: Low=0.77, High=0.44
  PR float64 // Привилегии (при S:U): None=0.85, Low=0.62, High=0.27
  UI float64 // Взаимодействие: None=0.85, Required=0.62
  ScopeChanged bool // Влияние на другие компоненты: false (U), true (C)
  C  float64 // Конфиденциальность: High=0.56, Low=0.22, None=0.0
  I  float64 // Целостность: High=0.56, Low=0.22, None=0.0
  A  float64 // Доступность: High=0.56, Low=0.22, None=0.0
}

// Округление вверх до 1 знака после запятой по стандарту CVSS 3.1
func roundUpCVSS(val float64) float64 {
  intInput := math.Round(val * 100000)
  if int(intInput)%10000 == 0 {
    return intInput / 100000.0
  }
  return (math.Floor(intInput/10000.0) + 1.0) / 10.0
}

func (v CVSS31Vector) CalculateBaseScore() float64 {
  iss := 1.0 - ((1.0 - v.C) * (1.0 - v.I) * (1.0 - v.A))
  var impact float64
  if !v.ScopeChanged {
    impact = 6.42 * iss
  } else {
    impact = 7.52*(iss-0.029) - 3.25*math.Pow(iss-0.02, 15)
  }
  if impact <= 0 {
    return 0.0
  }
  exploitability := 8.22 * v.AV * v.AC * v.PR * v.UI
  if !v.ScopeChanged {
    return roundUpCVSS(math.Min(impact+exploitability, 10.0))
  }
  return roundUpCVSS(math.Min(1.08*(impact+exploitability), 10.0))
}

// ============================================================================
// 2. ТАБЛИЦА 1 И ТАБЛИЦА 2 МЕТОДИКИ ФСТЭК РОССИИ ОТ 30.06.2025 (стр. 4-9)
// ============================================================================

type ComponentType float64 // k * K (при k = 0.5) — Таблица 1, п. 1 (стр. 7)
const (
  CompCriticalBusiness ComponentType = 0.5 * 1.1 // 0.55: Важные бизнес-процессы
  CompFirewallGateway  ComponentType = 0.5 * 0.9 // 0.45: Межсетевые экраны и шлюзы
  CompTelecomControl   ComponentType = 0.5 * 0.8 // 0.40: Телеком-оборудование
  CompServer           ComponentType = 0.5 * 0.7 // 0.35: Серверы (ЦВУ)
  CompWorkstation      ComponentType = 0.5 * 0.5 // 0.25: АРМ пользователей
  CompStorage          ComponentType = 0.5 * 0.4 // 0.20: СХД
  CompOther            ComponentType = 0.5 * 0.1 // 0.05: Другие компоненты
)

type ComponentShare float64 // l * L (при l = 0.2) — Таблица 1, п. 2 (стр. 7-8)
const (
  ShareOver70  ComponentShare = 0.2 * 1.0 // 0.20: Более 70%
  Share50To70  ComponentShare = 0.2 * 0.8 // 0.16: 50-70%
  Share10To50  ComponentShare = 0.2 * 0.6 // 0.12: 10-50%
  ShareUnder10 ComponentShare = 0.2 * 0.5 // 0.10: Менее 10%
)

type PerimeterAccess float64 // p * P (при p = 0.3) — Таблица 1, п. 3 (стр. 8)
const (
  PerimeterInternet PerimeterAccess = 0.3 * 1.1 // 0.33: Доступно из сети «Интернет»
  PerimeterInternal PerimeterAccess = 0.3 * 0.6 // 0.18: Недоступно из сети «Интернет»
)

type Exploitability float64 // I_at = e * E (при e = 1.0) — Таблица 1, п. 4 (стр. 8)
const (
  ExploitRealAttacks Exploitability = 1.0 * 0.6 // 0.60: Эксплуатируется в реальных атаках
  ExploitExists      Exploitability = 1.0 * 0.3 // 0.30: Имеются сведения о наличии эксплойта
  ExploitUnknown     Exploitability = 1.0 * 0.1 // 0.10: Отсутствуют сведения об эксплуатации
)
type ConsequenceH float64 // I_imp = h * H (при h = 1.0) — Таблица 1, п. 5 (стр. 8-9)
const (
  ConseqCodeExecOrPrivEsc ConsequenceH = 1.0 * 0.50 // 0.50: Выполнение произвольного кода / Повышение привилегий
  ConseqSecurityBypass    ConsequenceH = 1.0 * 0.40 // 0.40: Обход механизмов безопасности
  ConseqCodeInjection     ConsequenceH = 1.0 * 0.34 // 0.34: Внедрение кода
  ConseqSensitiveLeak     ConsequenceH = 1.0 * 0.30 // 0.30: Получение конфиденциальной информации / Нарушение целостности
  ConseqDoS               ConsequenceH = 1.0 * 0.26 // 0.26: Отказ в обслуживании (DoS)
  ConseqOverwriteFiles    ConsequenceH = 1.0 * 0.22 // 0.22: Перезапись произвольных файлов
  ConseqWriteLocal        ConsequenceH = 1.0 * 0.20 // 0.20: Запись локальных файлов
  ConseqReadLocal         ConsequenceH = 1.0 * 0.18 // 0.18: Чтение локальных файлов
)

// Пункт 12 (стр. 4) Методики ФСТЭК 2025 г.: V = I_cvss * I_infr * (I_at + I_imp)
func CalcV(iCVSS float64, k ComponentType, l ComponentShare, p PerimeterAccess, e Exploitability, h ConsequenceH) float64 {
  iInfr := float64(k) + float64(l) + float64(p) // п. 14 (стр. 5)
  return iCVSS * iInfr * (float64(e) + float64(h))
}

// Таблица 2 (стр. 9) Методики ФСТЭК 2025 г.: перевод V в 4 уровня критичности (1..4)
type Level int

const (
  Low      Level = 1 // V < 2.0 (Низкий)
  Medium   Level = 2 // 2.0 <= V < 5.0 (Средний)
  High     Level = 3 // 5.0 <= V <= 8.0 (Высокий)
  Critical Level = 4 // V > 8.0 (Критический)
)

func VToFSTECLevel(v float64) (Level, string) {
  switch {
  case v > 8.0:
    return Critical, "Критический (V > 8,0 — до 24 часов по п. 21)"
  case v >= 5.0:
    return High, "Высокий (5,0 <= V <= 8,0 — до 7 дней по п. 21)"
  case v >= 2.0:
    return Medium, "Средний (2,0 <= V < 5,0 — до 4 недель по п. 21)"
  default:
    return Low, "Низкий (V < 2,0 — до 4 месяцев по п. 21)"
  }
}

func main() {
  // ПРОВЕРКА ПРИМЕРА 1 ИЗ МЕТОДИКИ ФСТЭК 2025 (стр. 12-13, BDU:2025-01611):
  // Вектор со стр. 12: AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H
  vec := CVSS31Vector{AV: 0.85, AC: 0.77, PR: 0.62, UI: 0.85, ScopeChanged: false, C: 0.56, I: 0.56, A: 0.56}
  iCVSS := vec.CalculateBaseScore() // Ровно 8.8, как в Примере 1 на стр. 12!

  v := CalcV(iCVSS, CompFirewallGateway, Share10To50, PerimeterInternet, ExploitUnknown, ConseqCodeExecOrPrivEsc)
  lvl, desc := VToFSTECLevel(v)

  fmt.Printf("Рассчитанный I_cvss по формуле CVSS 3.1: %.1f\n", iCVSS)
  fmt.Printf("Уровень критичности V (Пример 1 ФСТЭК, стр. 13): %.2f -> Уровень %d [%s]\n", v, lvl, desc)
}
