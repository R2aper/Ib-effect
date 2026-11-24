package main

/*
ФСТЭК(2025)
11. Оценка уровня критичности уязвимостей программных, программно-
аппаратных средств применительно к информационным системам включает:
1) определение перечня программных, программно-аппаратных средств,
подверженных уязвимостям;
2) определение мест установки программных, программно-аппаратных
средств, подверженных уязвимостям (например, на периметре информационных
систем, во внутреннем сегменте систем, при реализации критических процессов
(бизнес-процессов) и других сегментах информационной системы);
3) расчет уровня критичности уязвимости программных, программно-
аппаратных средств в системе (V ).
*/

import (
	"fmt"
	"math"
)

type ThreatScenario struct {
	CodeBDU       string         // Код УБИ / BDU (или "Собственный сценарий по п. 5.3.3")
	Title         string         // Описание сценария
	FromBDU       bool           // Найдена ли готовая карточка в БДУ ФСТЭК
	CVSSScore     float64        // Если найдена в БДУ: готовый I_cvss (0..10)
	ExploitStatus Exploitability // Если найдена в БДУ: готовый I_at
	Consequence   ConsequenceH   // Последствие H из Таблицы 1 ФСТЭК 2025
}

// Связка Основного актива (КТ) и Вспомогательного актива (Прил. B.1, B.2, B.3 ГОСТ 27005-2010)
type AssetKT struct {
	PrimaryAssetName     string          // Основной актив: Информация КТ / Бизнес-процесс
	SupportingAssetName  string          // Вспомогательный актив: Сервер, СУБД, Git, АРМ
	Regime98FZCompliant  bool            // Соблюдены ли 5 мер ч. 1 ст. 10 98-ФЗ «О коммерческой тайне»
	DirectRecoveryCost   float64         // Прямое влияние (п. 8.2.2.2, Прил. В.3): восстановление и замена, руб.
	IndirectBusinessLoss float64         // Косвенное влияние (Прил. В.3 ГОСТ + У2 Прил. 4 ФСТЭК 2021): упущенная выгода, штрафы, потеря преимущества, руб.
	CompType             ComponentType   // Параметр k * K (Таблица 1 ФСТЭК 2025)
	Share                ComponentShare  // Параметр l * L (Таблица 1 ФСТЭК 2025)
	Perimeter            PerimeterAccess // Параметр p * P (Таблица 1 ФСТЭК 2025)
}

type CompensatingMeasure struct {
	Name    string
	CostTCO float64 // Стоимость внедрения и поддержки меры (п. 9.2 ГОСТ 27005), руб.

	// Мера влияет на L и P коэффициенты согласно таблице( Значения весовых коэффициентов и оценок показателей, определяющих влияние уязвимости на информационную систему)
	NewShare     ComponentShare
	NewPerimeter PerimeterAccess
}

// K: Тип компонента ИС
type ComponentType float64

// k * K
// k = 0.5
const (
	CompCriticalBusiness ComponentType = 0.5 * 1.11 //  Реализация важных бизнес-процессов
	CompFirewallGateway  ComponentType = 0.5 * 0.9  //  Межсетевые экраны, сетевые устройства и шлюзы
	CompTelecomControl   ComponentType = 0.5 * 0.8  //  Телеком-оборудование, управление сетью
	CompServer           ComponentType = 0.5 * 0.7  //  Серверы (центральные вычислительные узлы)
	CompWorkstation      ComponentType = 0.5 * 0.5  //  Пользовательские устройства (АРМ)
	CompStorage          ComponentType = 0.5 * 0.4  //  Системы хранения данных (СХД)
	CompOther            ComponentType = 0.5 * 0.1  //  Другие компоненты
)

// L: Доля уязвимых компонентов ИС
type ComponentShare float64

// l * L
// l = 0.2
const (
	ShareOver70  ComponentShare = 0.2 * 1.0 // Более 70% компонентов
	Share50To70  ComponentShare = 0.2 * 0.8 // 50-70% компонентов
	Share10To50  ComponentShare = 0.2 * 0.6 // 10-50% компонентов
	ShareUnder10 ComponentShare = 0.2 * 0.5 // Менее 10% компонентов
)

// P: Влияние на защиту периметра ИС
type PerimeterAccess float64

// p * P
// p = 0.3
const (
	PerimeterInternet PerimeterAccess = 0.3 * 1.11 // Доступно из сети «Интернет»
	PerimeterInternal PerimeterAccess = 0.3 * 0.6  // Недоступно из сети «Интернет»
)

// E: Показатель эксплуатации уязвимости
type Exploitability float64

// I_at = e * E
// e = 1.0
const (
	ExploitRealAttacks Exploitability = 0.60 // Эксплуатируется в реальных компьютерных атаках
	ExploitExists      Exploitability = 0.30 // Имеются сведения о наличии средств эксплуатации (эксплойта)
	ExploitUnknown     Exploitability = 0.10 // Отсутствуют сведения об эксплуатации
)

// H: Показатель последствий эксплуатации
type ConsequenceH float64

// I_imp = h * H
// h = 1.0
const (
	ConseqCodeExecOrPrivEsc ConsequenceH = 1.0 * 0.50 // Выполнение произвольного кода / Повышение привилегий
	ConseqSecurityBypass    ConsequenceH = 1.0 * 0.40 // Обход механизмов безопасности
	ConseqCodeInjection     ConsequenceH = 1.0 * 0.34 // Внедрение кода
	ConseqSensitiveLeak     ConsequenceH = 1.0 * 0.30 // Получение конфиденциальной информации (КТ) / Нарушение целостности
	ConseqDoS               ConsequenceH = 1.0 * 0.26 // Отказ в обслуживании (DoS)
	ConseqOverwriteFiles    ConsequenceH = 1.0 * 0.22 // Перезапись произвольных файлов
	ConseqWriteLocal        ConsequenceH = 1.0 * 0.20 // Запись локальных файлов
	ConseqReadLocal         ConsequenceH = 1.0 * 0.18 // Чтение локальных файлов
)

func getCriticalityText(v float64) string {
	switch {
	case v > 8.0:
		return "Критический — устранить до 24 ч"
	case v >= 5.0:
		return "Высокий — устранить до 7 дней"
	case v >= 2.0:
		return "Средний — устранить до 4 недель"
	default:
		return "Низкий — до 4 месяцев (Приемлемый)"
	}
}

// Полная ценность актива ( последствия инцидента SLE в денежном выражении по п. 8.2.2.2 ГОСТ 27005)
func (a AssetKT) TotalImpactSLE() float64 {
	return a.DirectRecoveryCost + a.IndirectBusinessLoss
}

// V = I_cvss * I_infr * (I_at + I_imp)
// I_cvss - Показатель, характеризующий уровень опасности уязвимости
// I_infr - Показатель, характеризующий влияние уязвимости программных, программно-аппаратных средств на функционирование информационных систем
// I_at - Показатель, характеризующий возможность эксплуатации уязвимости программных, программно-аппаратных средств в информационных системах
// I_imp - Показатель, характеризующий последствия эксплуатации уязвимости программных, программно-аппаратных средств в информационных системах
func Vulnerability_Level(I_cvss float64, I_infr float64, I_at float64, I_imp float64) float64 {
	return I_cvss * I_infr * (I_at + I_imp)
}

// Берется из описания угрозы
func Calculate_I_cvss(t ThreatScenario) float64 {
	return t.CVSSScore
}

// I_infr = k*K + l*L + p*P
// K - Показатель, характеризующий тип компонента информационной системы, подверженного уязвимости;
// L - Показатель, характеризующий количество уязвимых компонентов информационной системы (автоматизированных рабочих мест, серверов и других компонент)
// P - Показатель, характеризующий влияние уязвимого компонента на защищенность периметра информационной системы или периметра сегмента информационной системы
// k,l,p - Весовые коэффициенты показателей
func CalcIinfr(kxK ComponentType, lxL ComponentShare, pxP PerimeterAccess) float64 {
	return float64(kxK) + float64(lxL) + float64(pxP)
}

func Calculate_I_at(exE Exploitability) float64 {
	return float64(exE)
}

func Calculate_I_imp(hxH ConsequenceH) float64 {
	return float64(hxH)
}

func Calculate_CVSS31() float64 {
	// TODO
	return 0.0
}

func CalculateRiskAndROSI(asset AssetKT, threat ThreatScenario, measure CompensatingMeasure) {
	cvssBase, iAtBase, iImpBase := threat.CVSSScore, float64(threat.ExploitStatus), float64(threat.Consequence)
	iInfrBase := CalcIinfr(asset.CompType, asset.Share, asset.Perimeter)

	// 1. Базовый индекс V по п. 12 Методики ФСТЭК 2025: V = I_cvss * I_infr * (I_at + I_imp)
	vBase := Vulnerability_Level(cvssBase, iInfrBase, iAtBase, iImpBase)

	// 2. Пересчет параметров после применения меры (п. 19, 22, 25 Методики ФСТЭК 2025)
	effK := float64(asset.CompType)
	effL := float64(measure.NewShare)
	effP := float64(measure.NewPerimeter)
	effCVSS := cvssBase
	effImp := iImpBase
	effSLE := asset.TotalImpactSLE()

	effIinfr := CalcIinfr(ComponentType(effK), ComponentShare(effL), PerimeterAccess(effP))
	vResidual := Vulnerability_Level(effCVSS, effIinfr, iAtBase, effImp)

	// Странная херня
	// 3. Перевод V в вероятность сценария инцидента (относительно порога критичности V = 8.0 по Таблице 2)
	probBase := math.Min(vBase/8.0, 1.0)
	probRes := math.Min(vResidual/8.0, 1.0)

	// 4. Ожидаемый убыток по ГОСТ Р ИСО/МЭК 27005-2010 (Таблица Е.2: Последствия * Вероятность)
	aleBase := asset.TotalImpactSLE() * probBase
	aleRes := effSLE * probRes

	// 5. Анализ «затраты — выгоды» и рентабельность инвестиций (п. 9.1, 9.2 ГОСТ Р ИСО/МЭК 27005-2010)
	// Стандартные форумлы ROSI
	avoidedLoss := aleBase - aleRes
	netBenefit := avoidedLoss - measure.CostTCO
	netROSI := (netBenefit / measure.CostTCO) * 100.0

	// Вывод отчета для защиты перед руководством
	fmt.Println("======================================================================")
	fmt.Printf("ОСНОВНОЙ АКТИВ (КТ): %s\n", asset.PrimaryAssetName)
	fmt.Printf("ВСПОМОГАТЕЛЬНЫЙ АКТИВ: %s (I_infr = %.2f)\n", asset.SupportingAssetName, iInfrBase)
	fmt.Printf("ЦЕННОСТЬ АКТИВА (ГОСТ 27005 / У2 ФСТЭК): %.0f ₽ (Прямой: %.0f ₽ + Косвенный: %.0f ₽)\n",
		asset.TotalImpactSLE(), asset.DirectRecoveryCost, asset.IndirectBusinessLoss)
	if !asset.Regime98FZCompliant {
		fmt.Println("[!] ВНИМАНИЕ: Не выполнены условия ст. 10 98-ФЗ! Взыскать ущерб в суде невозможно.")
	}
	fmt.Println("----------------------------------------------------------------------")
	fmt.Printf("СЦЕНАРИЙ УГРОЗЫ: [%s] %s\n", threat.CodeBDU, threat.Title)
	fmt.Printf("  • ДО ЗАЩИТЫ:    V = %.2f (%s) | Вероятность: %.0f%% | Ожидаемый убыток: %.0f ₽\n",
		vBase, getCriticalityText(vBase), probBase*100, aleBase)
	fmt.Printf("  • МЕРА ЗАЩИТЫ:  %s (Стоимость: %.0f ₽)\n", measure.Name, measure.CostTCO)
	fmt.Printf("  • ПОСЛЕ ЗАЩИТЫ: V = %.2f (%s) | Вероятность: %.0f%% | Остаточный убыток: %.0f ₽\n",
		vResidual, getCriticalityText(vResidual), probRes*100, aleRes)
	fmt.Println("----------------------------------------------------------------------")
	fmt.Printf("ПРЕДОТВРАЩЕННЫЙ УЩЕРБ:       %.0f ₽\n", avoidedLoss)
	fmt.Printf("ЧИСТАЯ ВЫГОДА (Net Benefit): %.0f ₽\n", netBenefit)
	fmt.Printf("РЕНТАБЕЛЬНОСТЬ (Net ROSI):   +%.1f%%\n", netROSI)
}

func main() {
	// КЕЙС 1: Угроза найдена в БДУ ФСТЭК
	dbAsset := AssetKT{
		PrimaryAssetName:     "Клиентская база и условия контрактов (Режим КТ)",
		SupportingAssetName:  "Центральный сервер СУБД PostgreSQL",
		Regime98FZCompliant:  true,
		DirectRecoveryCost:   1_200_000,            // Восстановление сервера, форензика
		IndirectBusinessLoss: 6_800_000,            // Потеря клиентов, штрафы по договорам (У2 Таблицы 4.1 ФСТЭК 2021)
		CompType:             CompCriticalBusiness, // 0.55
		Share:                Share50To70,          // 0.16
		Perimeter:            PerimeterInternet,    // 0.33 (доступен через внешний веб-сервис)
	}

	bduThreat := ThreatScenario{
		CodeBDU:       "BDU:2025-01611 / УБИ.027",
		Title:         "Эксплуатация уязвимости периметра с повышением привилегий и кражей БД",
		FromBDU:       true,
		CVSSScore:     8.8,                     // Из Примера 1 Методики ФСТЭК 2025
		ExploitStatus: ExploitExists,           // 0.30
		Consequence:   ConseqCodeExecOrPrivEsc, // 0.50
	}

	netMeasure := CompensatingMeasure{
		Name:    "Изоляция СУБД во внутренний сегмент (МЭ) + патчинг (п. 22, 25 ФСТЭК 2025)",
		CostTCO: 450_000,
	}

	CalculateRiskAndROSI(dbAsset, bduThreat, netMeasure)

	// КЕЙС 2: Пользователь НЕ нашел свою угрозу в БДУ -> работает Конструктор по ФСТЭК 2021
	gitAsset := AssetKT{
		PrimaryAssetName:     "Исходный код и алгоритмы (Секрет производства / Ноу-хау)",
		SupportingAssetName:  "АРМ разработчиков и внутренний Git-сервер",
		Regime98FZCompliant:  true,
		DirectRecoveryCost:   3_000_000,         // Себестоимость разработки (ФОТ)
		IndirectBusinessLoss: 7_000_000,         // Потеря конкурентного преимущества (У2 Таблицы 4.1 ФСТЭК 2021)
		CompType:             CompWorkstation,   // 0.25 (АРМ)
		Share:                ShareOver70,       // 0.20 (>70% АРМ имеют доступ к репозиторию)
		Perimeter:            PerimeterInternal, // 0.18 (внутри сети)
	}
	customInsiderThreat := ThreatScenario{
		CodeBDU:     "Конструктор УБИ (п. 5.3.3 ФСТЭК 2021)",
		Title:       "Копирование исходного кода инсайдером / увольняющимся сотрудником на флешку (Тактика Т9.10)",
		FromBDU:     false,               // В БДУ CVE нет! Считаем автоматически по параметрам ФСТЭК 2021
		Consequence: ConseqSensitiveLeak, // 0.30: Получение конфиденциальной информации (Таблица 1 ФСТЭК 2025)
		CVSSScore:   Calculate_CVSS31(),
	}

	dlpMeasure := CompensatingMeasure{
		Name:         "Внедрение Endpoint DLP + блокировка USB-носителей (п. 25 ФСТЭК 2025)",
		CostTCO:      600_000,
		NewShare:     0.16,
		NewPerimeter: 0.3,
	}

	fmt.Println()
	CalculateRiskAndROSI(gitAsset, customInsiderThreat, dlpMeasure)
}
