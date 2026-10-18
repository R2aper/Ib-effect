# PowerShell script to build comprehensive Word .docx manual for IB-Effect (ИБ-Эффект)
param(
    [string]$OutputPath = "Руководство_по_приложению_ИБ_Эффект.docx"
)

$ErrorActionPreference = "Stop"

Write-Host ">>> Подготовка к созданию руководства в формате .docx..."

# Helper to escape XML special characters
function Escape-XmlText([string]$text) {
    if ([string]::IsNullOrEmpty($text)) { return "" }
    return $text.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;").Replace("'", "&apos;")
}

# Temporary workspace
$tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "ib_effect_docx_" + [System.Guid]::NewGuid().ToString("N"))
[System.IO.Directory]::CreateDirectory($tempDir) | Out-Null
[System.IO.Directory]::CreateDirectory([System.IO.Path]::Combine($tempDir, "_rels")) | Out-Null
[System.IO.Directory]::CreateDirectory([System.IO.Path]::Combine($tempDir, "word")) | Out-Null
[System.IO.Directory]::CreateDirectory([System.IO.Path]::Combine($tempDir, "word\_rels")) | Out-Null
[System.IO.Directory]::CreateDirectory([System.IO.Path]::Combine($tempDir, "docProps")) | Out-Null

Write-Host ">>> Создание служебных XML файлов OpenXML..."

# 1. [Content_Types].xml
$contentTypesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
'@
[System.IO.File]::WriteAllText([System.IO.Path]::Combine($tempDir, "[Content_Types].xml"), $contentTypesXml, [System.Text.Encoding]::UTF8)

# 2. _rels/.rels
$rootRelsXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
'@
[System.IO.File]::WriteAllText([System.IO.Path]::Combine($tempDir, "_rels\.rels"), $rootRelsXml, [System.Text.Encoding]::UTF8)

# 3. docProps/core.xml
$coreXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Руководство по программному комплексу «ИБ-Эффект»</dc:title>
  <dc:subject>Моделирование угроз АСУ ТП, расчет рисков и оценка возврата инвестиций ROSI</dc:subject>
  <dc:creator>Shalapai</dc:creator>
  <cp:lastModifiedBy>Shalapai</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">2026-10-19T00:00:00Z</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">2026-10-19T00:00:00Z</dcterms:modified>
</cp:coreProperties>
'@
[System.IO.File]::WriteAllText([System.IO.Path]::Combine($tempDir, "docProps\core.xml"), $coreXml, [System.Text.Encoding]::UTF8)

# 4. docProps/app.xml
$appXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Template>Normal.dotm</Template>
  <Application>Microsoft Word</Application>
  <DocSecurity>0</DocSecurity>
  <Lines>1400</Lines>
  <Paragraphs>400</Paragraphs>
  <Company>Shalapai Security</Company>
</Properties>
'@
[System.IO.File]::WriteAllText([System.IO.Path]::Combine($tempDir, "docProps\app.xml"), $appXml, [System.Text.Encoding]::UTF8)

# 5. word/_rels/document.xml.rels
$docRelsXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
'@
[System.IO.File]::WriteAllText([System.IO.Path]::Combine($tempDir, "word\_rels\document.xml.rels"), $docRelsXml, [System.Text.Encoding]::UTF8)

# 6. word/styles.xml
$stylesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>
        <w:sz w:val="22"/>
        <w:szCs w:val="22"/>
        <w:color w:val="1E293B"/>
        <w:lang w:val="ru-RU"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:after="120" w:line="276" w:lineRule="auto"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>

  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
  </w:style>

  <w:style w:type="paragraph" w:styleId="Title">
    <w:name w:val="Title"/>
    <w:pPr>
      <w:spacing w:before="240" w:after="160"/>
      <w:jc w:val="center"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Segoe UI" w:hAnsi="Segoe UI" w:cs="Segoe UI"/>
      <w:b/>
      <w:sz w:val="52"/>
      <w:szCs w:val="52"/>
      <w:color w:val="1E3A8A"/>
    </w:rPr>
  </w:style>

  <w:style w:type="paragraph" w:styleId="Subtitle">
    <w:name w:val="Subtitle"/>
    <w:pPr>
      <w:spacing w:before="60" w:after="300"/>
      <w:jc w:val="center"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Segoe UI" w:hAnsi="Segoe UI" w:cs="Segoe UI"/>
      <w:sz w:val="26"/>
      <w:szCs w:val="26"/>
      <w:color w:val="475569"/>
    </w:rPr>
  </w:style>

  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:pPr>
      <w:spacing w:before="360" w:after="140"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Segoe UI" w:hAnsi="Segoe UI" w:cs="Segoe UI"/>
      <w:b/>
      <w:sz w:val="34"/>
      <w:szCs w:val="34"/>
      <w:color w:val="1E3A8A"/>
    </w:rPr>
  </w:style>

  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:pPr>
      <w:spacing w:before="260" w:after="100"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Segoe UI" w:hAnsi="Segoe UI" w:cs="Segoe UI"/>
      <w:b/>
      <w:sz w:val="28"/>
      <w:szCs w:val="28"/>
      <w:color w:val="0284C7"/>
    </w:rPr>
  </w:style>

  <w:style w:type="paragraph" w:styleId="Heading3">
    <w:name w:val="heading 3"/>
    <w:pPr>
      <w:spacing w:before="180" w:after="80"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Segoe UI" w:hAnsi="Segoe UI" w:cs="Segoe UI"/>
      <w:b/>
      <w:sz w:val="24"/>
      <w:szCs w:val="24"/>
      <w:color w:val="0F172A"/>
    </w:rPr>
  </w:style>
</w:styles>
'@
[System.IO.File]::WriteAllText([System.IO.Path]::Combine($tempDir, "word\styles.xml"), $stylesXml, [System.Text.Encoding]::UTF8)

Write-Host ">>> Формирование основного тела документа (word/document.xml)..."

# String Builder for document.xml
$sb = New-Object System.Text.StringBuilder
[void]$sb.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
[void]$sb.Append('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">')
[void]$sb.Append('<w:body>')

# Helper functions for emitting elements
function Add-P([string]$text, [string]$color="1E293B", [bool]$bold=$false, [bool]$italic=$false, [int]$sz=22, [string]$align="both", [int]$spaceBefore=0, [int]$spaceAfter=120) {
    $e = Escape-XmlText $text
    $jc = if ($align -ne "left") { "<w:jc w:val=`"$align`"/>" } else { "" }
    $b = if ($bold) { "<w:b/>" } else { "" }
    $i = if ($italic) { "<w:i/>" } else { "" }
    $sp = "<w:spacing w:before=`"$spaceBefore`" w:after=`"$spaceAfter`" w:line=`"276`" w:lineRule=`"auto`"/>"
    $rpr = "<w:rPr><w:rFonts w:ascii=`"Calibri`" w:hAnsi=`"Calibri`" w:cs=`"Calibri`"/>$b$i<w:sz w:val=`"$sz`"/><w:color w:val=`"$color`"/></w:rPr>"
    [void]$sb.Append("<w:p><w:pPr>$jc$sp</w:pPr><w:r>$rpr<w:t xml:space=`"preserve`">$e</w:t></w:r></w:p>")
}

function Add-H1([string]$title) {
    $e = Escape-XmlText $title
    [void]$sb.Append("<w:p><w:pPr><w:pStyle w:val=`"Heading1`"/></w:pPr><w:r><w:t>$e</w:t></w:r></w:p>")
}

function Add-H2([string]$title) {
    $e = Escape-XmlText $title
    [void]$sb.Append("<w:p><w:pPr><w:pStyle w:val=`"Heading2`"/></w:pPr><w:r><w:t>$e</w:t></w:r></w:p>")
}

function Add-H3([string]$title) {
    $e = Escape-XmlText $title
    [void]$sb.Append("<w:p><w:pPr><w:pStyle w:val=`"Heading3`"/></w:pPr><w:r><w:t>$e</w:t></w:r></w:p>")
}

function Add-Bullet([string]$prefix, [string]$text) {
    $ep = Escape-XmlText $prefix
    $et = Escape-XmlText $text
    [void]$sb.Append("<w:p><w:pPr><w:ind w:left=`"540`" w:hanging=`"260`"/><w:spacing w:after=`"80`" w:line=`"276`" w:lineRule=`"auto`"/></w:pPr>")
    [void]$sb.Append("<w:r><w:rPr><w:rFonts w:ascii=`"Calibri`" w:hAnsi=`"Calibri`"/><w:b/><w:color w:val=`"0284C7`"/></w:rPr><w:t xml:space=`"preserve`">$ep </w:t></w:r>")
    [void]$sb.Append("<w:r><w:rPr><w:rFonts w:ascii=`"Calibri`" w:hAnsi=`"Calibri`"/><w:color w:val=`"1E293B`"/></w:rPr><w:t xml:space=`"preserve`">$et</w:t></w:r></w:p>")
}

function Add-Callout([string]$badge, [string]$title, [string]$body, [string]$badgeColor="2563EB", [string]$bgColor="F8FAFC") {
    $eb = Escape-XmlText $badge
    $et = Escape-XmlText $title
    $ec = Escape-XmlText $body
    [void]$sb.Append("<w:tbl><w:tblPr><w:tblW w:w=`"9400`" w:type=`"dxa`"/><w:tblBorders><w:top w:val=`"none`"/><w:left w:val=`"single`" w:sz=`"24`" w:space=`"0`" w:color=`"$badgeColor`"/><w:bottom w:val=`"none`"/><w:right w:val=`"none`"/><w:insideH w:val=`"none`"/><w:insideV w:val=`"none`"/></w:tblBorders><w:tblCellMar><w:top w:w=`"140`" w:type=`"dxa`"/><w:left w:w=`"220`" w:type=`"dxa`"/><w:bottom w:w=`"140`" w:type=`"dxa`"/><w:right w:w=`"220`" w:type=`"dxa`"/></w:tblCellMar></w:tblPr><w:tr><w:tc><w:tcPr><w:tcW w:w=`"9400`" w:type=`"dxa`"/><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"$bgColor`"/></w:tcPr>")
    [void]$sb.Append("<w:p><w:pPr><w:spacing w:after=`"60`"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val=`"22`"/><w:color w:val=`"$badgeColor`"/></w:rPr><w:t xml:space=`"preserve`">[$eb] </w:t></w:r><w:r><w:rPr><w:b/><w:sz w:val=`"22`"/><w:color w:val=`"0F172A`"/></w:rPr><w:t>$et</w:t></w:r></w:p>")
    [void]$sb.Append("<w:p><w:pPr><w:spacing w:after=`"0`"/><w:line w:line=`"260`" w:lineRule=`"auto`"/></w:pPr><w:r><w:rPr><w:sz w:val=`"21`"/><w:color w:val=`"334155`"/></w:rPr><w:t>$ec</w:t></w:r></w:p>")
    [void]$sb.Append("</w:tc></w:tr></w:tbl><w:p><w:pPr><w:spacing w:after=`"120`"/></w:pPr></w:p>")
}

function Add-FormulaBox([string]$formula, [string]$description) {
    $ef = Escape-XmlText $formula
    $ed = Escape-XmlText $description
    [void]$sb.Append("<w:tbl><w:tblPr><w:tblW w:w=`"9400`" w:type=`"dxa`"/><w:tblBorders><w:top w:val=`"single`" w:sz=`"6`" w:space=`"0`" w:color=`"CBD5E1`"/><w:left w:val=`"single`" w:sz=`"20`" w:space=`"0`" w:color=`"0284C7`"/><w:bottom w:val=`"single`" w:sz=`"6`" w:space=`"0`" w:color=`"CBD5E1`"/><w:right w:val=`"single`" w:sz=`"6`" w:space=`"0`" w:color=`"CBD5E1`"/></w:tblBorders><w:tblCellMar><w:top w:w=`"140`" w:type=`"dxa`"/><w:left w:w=`"200`" w:type=`"dxa`"/><w:bottom w:w=`"140`" w:type=`"dxa`"/><w:right w:w=`"200`" w:type=`"dxa`"/></w:tblCellMar></w:tblPr><w:tr><w:tc><w:tcPr><w:tcW w:w=`"9400`" w:type=`"dxa`"/><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"F1F5F9`"/></w:tcPr>")
    [void]$sb.Append("<w:p><w:pPr><w:jc w:val=`"center`"/><w:spacing w:after=`"80`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Consolas`" w:hAnsi=`"Consolas`"/><w:b/><w:sz w:val=`"24`"/><w:color w:val=`"0F172A`"/></w:rPr><w:t>$ef</w:t></w:r></w:p>")
    if ($ed -ne "") {
        [void]$sb.Append("<w:p><w:pPr><w:spacing w:after=`"0`"/></w:pPr><w:r><w:rPr><w:i/><w:sz w:val=`"20`"/><w:color w:val=`"475569`"/></w:rPr><w:t>$ed</w:t></w:r></w:p>")
    }
    [void]$sb.Append("</w:tc></w:tr></w:tbl><w:p><w:pPr><w:spacing w:after=`"120`"/></w:pPr></w:p>")
}

function Add-Table([string[]]$headers, [int[]]$colWidths, [object[]]$rows) {
    [void]$sb.Append("<w:tbl><w:tblPr><w:tblW w:w=`"9400`" w:type=`"dxa`"/><w:tblBorders><w:top w:val=`"single`" w:sz=`"8`" w:space=`"0`" w:color=`"94A3B8`"/><w:left w:val=`"none`"/><w:bottom w:val=`"single`" w:sz=`"10`" w:space=`"0`" w:color=`"475569`"/><w:right w:val=`"none`"/><w:insideH w:val=`"single`" w:sz=`"4`" w:space=`"0`" w:color=`"E2E8F0`"/><w:insideV w:val=`"none`"/></w:tblBorders><w:tblCellMar><w:top w:w=`"100`" w:type=`"dxa`"/><w:left w:w=`"140`" w:type=`"dxa`"/><w:bottom w:w=`"100`" w:type=`"dxa`"/><w:right w:w=`"140`" w:type=`"dxa`"/></w:tblCellMar></w:tblPr>")
    
    # Header Row
    [void]$sb.Append("<w:tr><w:trPr><w:tblHeader/><w:cantSplit/></w:trPr>")
    for ($i = 0; $i -lt $headers.Length; $i++) {
        $w = $colWidths[$i]
        $th = Escape-XmlText $headers[$i]
        [void]$sb.Append("<w:tc><w:tcPr><w:tcW w:w=`"$w`" w:type=`"dxa`"/><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"E2E8F0`"/></w:tcPr><w:p><w:pPr><w:spacing w:after=`"40`"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val=`"20`"/><w:color w:val=`"0F172A`"/></w:rPr><w:t>$th</w:t></w:r></w:p></w:tc>")
    }
    [void]$sb.Append("</w:tr>")

    # Data Rows
    foreach ($r in $rows) {
        [void]$sb.Append("<w:tr><w:trPr><w:cantSplit/></w:trPr>")
        for ($i = 0; $i -lt $r.Length; $i++) {
            $w = $colWidths[$i]
            $cellText = Escape-XmlText $r[$i]
            [void]$sb.Append("<w:tc><w:tcPr><w:tcW w:w=`"$w`" w:type=`"dxa`"/></w:tcPr><w:p><w:pPr><w:spacing w:after=`"40`"/></w:pPr><w:r><w:rPr><w:sz w:val=`"20`"/><w:color w:val=`"1E293B`"/></w:rPr><w:t>$cellText</w:t></w:r></w:p></w:tc>")
        }
        [void]$sb.Append("</w:tr>")
    }
    [void]$sb.Append("</w:tbl><w:p><w:pPr><w:spacing w:after=`"120`"/></w:pPr></w:p>")
}

# --- DOCUMENT CONTENT GENERATION ---

# Title & Metadata
[void]$sb.Append("<w:p><w:pPr><w:pStyle w:val=`"Title`"/></w:pPr><w:r><w:t>Программный комплекс «ИБ-Эффект»</w:t></w:r></w:p>")
[void]$sb.Append("<w:p><w:pPr><w:pStyle w:val=`"Subtitle`"/></w:pPr><w:r><w:t>Руководство пользователя, техническая архитектура и методологический базис расчета экономической эффективности ИБ</w:t></w:r></w:p>")

Add-Callout "ВЕРСИЯ 2.0 / MASTER2" "Проект ИБ-Эффект (Shalapai Security)" "Данный документ содержит исчерпывающее техническое и методическое описание системы: функциональные сценарии использования, архитектуру кодовой базы (C++20 / Qt 6 / QML), интеграцию реестров БДУ ФСТЭК России (АСУ ТП), полный математический аппарат расчета рисков и экономической эффективности инвестиций (ROSI), а также нормативную базу стандартов." "1D4ED8" "EFF6FF"

# =========================================================================
# РАЗДЕЛ 1: КОНЦЕПЦИЯ И НАЗНАЧЕНИЕ ПРОДУКТА
# =========================================================================
Add-H1 "1. Что это за приложение и какую задачу оно решает"

Add-P "Программный комплекс «ИБ-Эффект» представляет собой специализированную аналитическую систему поддержки принятия решений (DSS — Decision Support System) в сфере информационной безопасности. Система решает фундаментальную задачу перевода технических показателей защищенности и требований регуляторов на язык финансовых и бизнес-метрик предприятия."

Add-H2 "1.1. Проблема взаимопонимания бизнеса и кибербезопасности"
Add-P "В современной корпоративной практике существует устойчивый коммуникационный и аналитический разрыв между службой информационной безопасности (CISO, архитекторы ИБ) и топ-менеджментом компании (Генеральный директор, CFO, совет директоров):"

Add-Bullet "•" "Подход ИБ-специалистов: Оперирует категориями соответствия (комплаенс Приказу ФСТЭК № 239, № 21, 187-ФЗ), количеством уязвимостей (CVE, BDU), векторами атак и критичностью угроз. Часто ИБ воспринимается топ-менеджментом исключительно как «центр затрат» (Cost Center), требующий многомиллионных бюджетов без очевидного финансового возврата."
Add-Bullet "•" "Подход топ-менеджмента и CFO: Требует обоснования капитальных затрат (CAPEX) и текущих расходов (OPEX). Бизнесу необходимы ответы на прямые вопросы: «Какой конкретно финансовый ущерб мы предотвратим, потратив 15 млн руб.?», «Каков возврат на инвестиции в безопасность (ROSI)?», «Какова вероятность технологического простоя завода и какова цена каждого часа простоя?»."

Add-P "«ИБ-Эффект» устраняет данный разрыв, объединяя в единый аналитический конвейер нормативную базу Российской Федерации (методики ФСТЭК России, стандарты ГОСТ) и современные экономико-математические модели оценки эффективности затрат на безопасность (ROSI, TCO, Downtime Economics)."

Add-H2 "1.2. Двойное функциональное назначение комплекса"
Add-P "Комплекс спроектирован по модульному принципу и объединяет два ключевых контура:"
Add-Bullet "1. Нормативно-технический контур (Моделирование угроз АСУ ТП и КИИ):" "Полная база стандартизированных промышленных активов (ОА.001 - ОА.014), типовых сценариев компьютерных атак (C1 - C3) и угроз безопасности информации (УБИ) из Банка данных угроз АСУ ТП ФСТЭК России (bduasutp.fstec.ru). Позволяет сформировать легитимную модель угроз безопасности информации (МУБИ) в соответствии с Методикой ФСТЭК от 05.02.2021 г."
Add-Bullet "2. Финансово-актуарный контур (Оценка экономической эффективности ИБ):" "Математический расчет начального и остаточного рисков, предотвращенного совокупного ущерба, расчет возврата инвестиций (ROSI), периода окупаемости мер и моделирование потерь от технологического простоя производственных линий."

# =========================================================================
# РАЗДЕЛ 2: АРХИТЕКТУРА И ТЕХНОЛОГИЧЕСКИЙ СТЕК
# =========================================================================
Add-H1 "2. Технологический стек и архитектура системы"

Add-P "Система создана в парадигме высокой производительности, кроссплатформенности и максимальной надежности при работе в изолированных контурах (On-Premises / Air-Gapped) предприятий КИИ."

Add-H2 "2.1. Базовые технологии"
$techTableHeaders = @("Компонент", "Используемая технология", "Обоснование выбора")
$techTableWidths = @(2200, 2600, 4600)
$techTableRows = @(
    @("Ядро вычислений", "C++20 (ISO/IEC 14882:2020)", "Детерминированные вычисления без GC-пауз, строгая статическая типизация, высокая скорость матричных пересчетов, безопасность работы с памятью."),
    @("Графический интерфейс", "Qt 6.11 (QML / Qt Quick Controls 2)", "Декларативное разделение UI и бизнес-логики (MVVM), аппаратное ускорение рендеринга через Qt Scene Graph (Direct3D/OpenGL), плавные анимации дашбордов."),
    @("Система сборки", "CMake 3.16+ / CTest", "Индустриальный стандарт кроссплатформенной сборки, интеграция модульных тестов и генерации дистрибутивов."),
    @("Тулчейн компиляции", "MinGW-w64 (GCC 13+)", "Автономная сборка под 64-битные платформы Windows без привязки к проприетарным библиотекам."),
    @("Хранение данных", "Структурированный JSON / SQLite / OpenXML", "Отсутствие необходимости развертывания тяжелых внешних СУБД. Все справочники БДУ хранятся в оптимизированных локальных реестрах.")
)
Add-Table $techTableHeaders $techTableWidths $techTableRows

Add-H2 "2.2. Архитектура программных модулей (C++ / QML)"
Add-P "Архитектура построена на паттерне Model-View-ViewModel (MVVM) с жестким разделением ответственности между слоями:"

Add-Bullet "• Core Engine (C++):" "Математическое ядро (`RiskCalculator`, `FinancialEngine`, `DowntimeModel`). Содержит реализацию чистых математических функций расчета рисков, предотвращенного ущерба и коэффициентов ROSI. Не имеет зависимостей от графической подсистемы."
Add-Bullet "• Data Models Layer (C++ / QAbstractListModel):" "Классы `AssetModel`, `ThreatModel`, `MeasureModel`, `ScenarioModel`. Обеспечивают реактивную передачу коллекций в интерфейс QML, поддерживают быстрый поиск, фильтрацию по классам активов и категориям мер Приказа № 239."
Add-Bullet "• BDU Service & Parser (C++):" "Модуль загрузки и парсинга реестров угроз безопасности информации (УБИ), уязвимостей (BDU) и промышленных объектов (ОА.001 - ОА.014). Обеспечивает валидацию структуры данных и кэширование."
Add-Bullet "• Presentation Layer (QML):" "Визуальные компоненты интерфейса: тепловая карта матрицы рисков (Heatmap), диаграмма структуры затрат, интерактивные бегунки параметров вероятности и ущерба, форма генерации отчетов."

# =========================================================================
# РАЗДЕЛ 3: ПОШАГОВАЯ ИНСТРУКЦИЯ ПОЛЬЗОВАТЕЛЯ
# =========================================================================
Add-H1 "3. Инструкция пользователя: пошаговый регламент работы"

Add-P "Ниже приведен стандартный эксплуатационный регламент проведения оценки рисков и расчета окупаемости мер защиты для промышленного или корпоративного сегмента."

Add-H2 "Шаг 1. Формирование перечня защищаемых активов"
Add-P "Пользователь открывает вкладку «Реестр активов» (Asset Registry) и формирует паспорт объекта автоматизации. В систему предзагружен классификатор промышленных активов ФСТЭК России:"

Add-Bullet "• ОА.001:" "Сервер диспетчерского управления (SCADA Server) — сбор и обработка телеметрии."
Add-Bullet "• ОА.002:" "Инженерная станция (Engineering Workstation) — разработка и загрузка технологических программ."
Add-Bullet "• ОА.003:" "Программируемый логический контроллер (ПЛК / PLC) — непосредственное управление исполнительными механизмами."
Add-Bullet "• ОА.004:" "Автоматизированное рабочее место оператора (HMI Client / АРМ оператора)."
Add-Bullet "• ОА.005:" "Сетевой промышленный шлюз (Industrial Gateway / IT-OT DMZ)."
Add-Bullet "• ОА.006–ОА.014:" "Устройства полевого уровня, RTU, интеллектуальные датчики, коммуникационные коммутаторы."

Add-P "Для каждого добавленного актива оператор устанавливает категорию значимости / критичности A по 4-балльной шкале:"
Add-Bullet "1 (Низкая / Вспомогательный):" "Выход из строя не влияет на выполнение базовых бизнес-функций или технологического цикла."
Add-Bullet "2 (Умеренная / Локальный):" "Влияет на вторичные контуры, имеются резервные схемы горячего переключения."
Add-Bullet "3 (Высокая / Критический):" "Отказ актива приводит к останову основного технологического передела или срыву договорных поставок."
Add-Bullet "4 (Критическая / Ключевой объект КИИ):" "Отказ влечет угрозу безопасности жизни и здоровью персонала, экологическую аварию или останов всего предприятия."

Add-H2 "Шаг 2. Идентификация актуальных угроз и сценариев атак"
Add-P "Во вкладке «Моделирование угроз» оператор сопоставляет активам актуальные угрозы безопасности информации. Пользователь может выбрать преднастроенные сценарии атак согласно базе АСУ ТП ФСТЭК России:"
Add-Bullet "• Сценарий C1 (Проникновение через IT/OT периметр):" "Атака через корпоративную сеть или удаленный доступ подрядчиков с последующим поперечным перемещением (Lateral Movement) в технологический сегмент."
Add-Bullet "• Сценарий C2 (Деструктивное воздействие на ПЛК):" "Прямая модификация микрокода, управляющей логики или проектных файлов ПЛК (ОА.003) в обход авторизации."
Add-Bullet "• Сценарий C3 (Отказ в обслуживании технологического процесса / DoS):" "Шторм широковещательных пакетов по протоколам Modbus TCP / Profinet, приводящий к потере связи со станциями управления."

Add-P "Для каждой привязанной угрозы задаются базовые экспертные параметры:"
Add-Bullet "• Исходная вероятность реализации P (1..4):" "1 — Низкая (требует высокой квалификации и редких 0-day уязвимостей), 2 — Средняя, 3 — Высокая (имеются публичные эксплойты), 4 — Критическая (активная эксплуатация)."
Add-Bullet "• Потенциальный ущерб I (1..4):" "1 — Незначительный, 2 — Умеренный, 3 — Тяжелый, 4 — Катастрофический."

Add-H2 "Шаг 3. Выбор компенсирующих мер защиты (Приказ ФСТЭК № 239)"
Add-P "Оператор переходит к блоку «Меры противодействия». Система предлагает набор мер из каталога Приказа № 239:"
Add-Bullet "• ИАФ (Идентификация и аутентификация):" "Многофакторная аутентификация инженеров, разграничение сессий операторов."
Add-Bullet "• ЗИС (Защита информации в сетях):" "Микросегментация сетей АСУ ТП, межсетевые экраны промышленного уровня (NGFW/Industrial FW) с глубоким анализом промышленных протоколов (DPI Modbus/DNP3)."
Add-Bullet "• АВД (Антивирусная защита):" "Специализированные агенты для промышленных АРМ и серверов SCADA с контролем белых списков приложений (Application Whitelisting)."
Add-Bullet "• ОДР (Обнаружение деструктивных воздействий):" "Системы мониторинга технологических аномалий и сенсоры сетевой телеметрии (NTA/IDS для АСУ ТП)."

Add-P "Для каждой меры указываются:"
Add-Bullet "• Эффективность снижения вероятности dP (%):" "На сколько процентов мера снижает вероятность успешной атаки."
Add-Bullet "• Эффективность снижения ущерба dI (%):" "На сколько процентов мера локализует масштаб последствий инцидента."
Add-Bullet "• Финансовые затраты:" "Капитальные затраты на внедрение (CAPEX) и ежегодное сопровождение/лицензии (OPEX)."

Add-H2 "Шаг 4. Анализ тепловой карты рисков (Risk Heatmap)"
Add-P "Система мгновенно рассчитывает матрицу рисков по шкале от 1 до 64. На тепловой карте отображаются две позиции для каждой угрозы: исходный риск (красные маркеры) и остаточный риск после внедрения выбранных мер (зеленые маркеры). Горизонтальная пунктирная линия обозначает границу толерантности к риску (Risk Appetite)."

Add-H2 "Шаг 5. Анализ окупаемости и финансового дашборда (ROSI Dashboard)"
Add-P "Оператор переходит на панель «Финансовый анализ». Здесь представлены интегральные показатели:"
Add-Bullet "• Совокупная стоимость мер (TCO):" "Сумма капитальных и операционных расходов за заданный горизонт планирования (например, 3 года)."
Add-Bullet "• Предотвращенный ущерб (Avoided Loss):" "Разница между совокупными потенциальными потерями до внедрения мер и после их реализации."
Add-Bullet "• Потери от технологического простоя (Downtime Economics):" "Финансовый ущерб от остановки технологического цикла, рассчитанный с учетом среднего времени восстановления (MTTR)."
Add-Bullet "• Коэффициент ROSI (%) и Multiplier (x):" "Итоговые коэффициенты эффективности вложений в кибербезопасность."

# =========================================================================
# РАЗДЕЛ 4: МАТЕМАТИЧЕСКИЙ АППАРАТ И АЛГОРИТМЫ РАСЧЕТОВ
# =========================================================================
Add-H1 "4. Математический аппарат и алгоритмы расчетов"

Add-P "Математическая модель программного комплекса «ИБ-Эффект» базируется на синтезе вероятностно-матричных методов оценки рисков (ГОСТ Р ИСО/МЭК 27005-2010, ГОСТ Р 57580.3-2022) и классической модели анализа возврата инвестиций в ИБ (Gordon-Loeb Model, Sonnenreich ROSI Model)."

Add-H2 "4.1. Оценка начального риска (Initial Risk)"
Add-P "Интегральный уровень начального риска для пары «угроза — актив» рассчитывается как произведение трех нормированных целочисленных факторов:"

Add-FormulaBox "Risk_init = I * P * A" "где I in [1..4] — тяжесть последствий (Impact), P in [1..4] — вероятность реализации (Probability), A in [1..4] — критичность актива (Asset Criticality)."

Add-P "Итоговое значение риска принимает целочисленные значения в диапазоне от 1 до 64. В системе принята следующая классификация уровней риска:"
$riskGradeHeaders = @("Диапазон Risk", "Категория риска", "Цветовая индикация", "Рекомендуемое управленческое действие")
$riskGradeWidths = @(1800, 2200, 2000, 3400)
$riskGradeRows = @(
    @("1 .. 8", "Низкий (Low)", "Зеленый (#10B981)", "Риск приемлем. Достаточно периодического регламентного мониторинга."),
    @("9 .. 24", "Умеренный (Medium)", "Желтый (#F59E0B)", "Риск допустим при наличии компенсирующих организационных мер."),
    @("25 .. 44", "Высокий (High)", "Оранжевый (#F97316)", "Требуется обязательное внедрение технических мер защиты."),
    @("45 .. 64", "Критический (Critical)", "Красный (#EF4444)", "Недопустимый риск. Требуется немедленная изоляция сегмента или экстренное внедрение СЗИ.")
)
Add-Table $riskGradeHeaders $riskGradeWidths $riskGradeRows

Add-H2 "4.2. Модель комбинированного снижения риска комплексом мер"
Add-P "При внедрении нескольких компенсирующих мер (например, сетевое экранирование + антивирусный контроль) их совместная эффективность не суммируется линейно, так как линейное сложение привело бы к абсурдному значению свыше 100%. В комплексе «ИБ-Эффект» реализована вероятностная модель независимого снижения (закон затухающей предельной полезности):"

Add-FormulaBox "dI_total = 1 - PRODUCT(1 - delta_I_k),   dP_total = 1 - PRODUCT(1 - delta_P_k)" "где delta_I_k in [0, 1) — локальная эффективность k-й меры по снижению ущерба, delta_P_k in [0, 1) — локальная эффективность k-й меры по снижению вероятности."

Add-P "Данная формула гарантирует, что каждая последующая мера защищает от той доли риска, которая осталась не перекрыта предыдущими мерами, а суммарная эффективность строго принадлежит интервалу [0, 1)."

Add-H2 "4.3. Оценка остаточного риска (Residual Risk)"
Add-P "Остаточный риск после внедрения комплекса компенсирующих мер рассчитывается по формуле:"

Add-FormulaBox "Risk_res = CEIL[ I * (1 - dI_total) * P * (1 - dP_total) * A ]" "Функция CEIL (округление вверх до целого) обеспечивает консервативный (осторожный) подход в оценке безопасности, принятый в ГОСТ Р ИСО/МЭК 27005."

Add-H2 "4.4. Модель финансового ущерба (Financial Loss Modeling)"
Add-P "Для перехода от баллов риска к рублям вводится коэффициент удельной стоимости балла риска (Cost per Risk Point — C_rp), определяемый финансовой службой предприятия исходя из годового оборота или объема защищаемых основных средств:"

Add-FormulaBox "Loss_init = SUM(Risk_init_i * C_rp),   Loss_res = SUM(Risk_res_i * C_rp)" "Совокупный предотвращенный финансовый ущерб (Avoided Loss / Risk Mitigation Value): Delta_Loss = Loss_init - Loss_res."

Add-H2 "4.5. Модель технологического простоя для АСУ ТП (Downtime Economics)"
Add-P "Для промышленных предприятий ключевой составляющей ущерба от кибератак является непредвиденный останов непрерывного производственного цикла (невыпуск продукции, порча сырья в аппаратах, штрафы за срыв поставок электроэнергии/газа). Модуль Downtime Economics рассчитывает данный ущерб:"

Add-FormulaBox "Loss_downtime = C_hour * MTTR * P_incident" "где C_hour — прямые финансовые потери от 1 часа простоя технологической линии, MTTR — среднее время восстановления работоспособности (Mean Time To Recovery, часы), P_incident — нормированная вероятность аварийного останова."

Add-H2 "4.6. Совокупная стоимость владения мерами защиты (TCO)"
Add-P "Совокупные затраты на внедрение и эксплуатацию мер защиты информации за расчетный период T (лет) определяются как:"

Add-FormulaBox "TCO = SUM(CAPEX_j) + SUM(OPEX_j * T)" "где CAPEX — капитальные затраты на приобретение оборудования, ПО и пусконаладку, OPEX — ежегодные затраты на техническую поддержку, подписку на обновления сигнатур и ФОТ специалистов."

Add-H2 "4.7. Расчет показателей возврата инвестиций (ROSI и Net Benefit)"
Add-P "Экономическая эффективность проекта обеспечения информационной безопасности формализуется двумя фундаментальными метриками:"

Add-FormulaBox "Net Benefit = Delta_Loss - TCO" "Чистый финансовый эффект от проекта (предотвращенный убыток за вычетом затрат на СЗИ)."

Add-FormulaBox "ROSI = [ (Delta_Loss - TCO) / TCO ] * 100%" "Return on Security Investment — относительный коэффициент окупаемости инвестиций в безопасность в процентах."

Add-FormulaBox "ROI Multiplier = Delta_Loss / TCO" "Мультипликатор возврата: показывает, сколько рублей потенциального ущерба предотвращает каждый вложенный в защиту рубль."

Add-Callout "ЭКОНОМИЧЕСКИЙ КРИТЕРИЙ ЭФФЕКТИВНОСТИ" "Правило принятия решений по безопасности" "Если ROSI > 0% (или ROI Multiplier > 1.0x), внедрение мер защиты экономически оправдано: предотвращенный ущерб превышает затраты на систему безопасности. При ROSI < 0% проект является финансово избыточным, и рекомендуется пересмотреть состав мер в сторону более оптимальных по стоимости решений." "0284C7" "F0F9FF"

# =========================================================================
# РАЗДЕЛ 5: СКВОЗНОЙ ЧИСЛОВОЙ ПРИМЕР РАСЧЕТА
# =========================================================================
Add-H1 "5. Сквозной практический пример расчета"

Add-P "Рассмотрим типичный промышленный сценарий для компрессорной станции магистрального газопровода."

Add-H2 "5.1. Исходные данные"
Add-Bullet "• Защищаемый актив:" "Программируемый логический контроллер компрессора (ОА.003). Критичность A = 4 (ключевой объект КИИ)."
Add-Bullet "• Актуальная угроза:" "УБИ.012 — Несанкционированная модификация управляющей программы и параметров технологического режима."
Add-Bullet "• Исходные параметры:" "Вероятность P = 3 (высокая, есть удаленный канал телеметрии), Ущерб I = 4 (катастрофический, авария компрессора)."
Add-Bullet "• Финансовые параметры:" "Стоимость балла риска C_rp = 150 000 руб. Ущерб от 1 часа простоя C_hour = 800 000 руб. Время восстановления MTTR = 12 часов."

Add-P "Расчет начального риска и базового ущерба:"
Add-Bullet "• Начальный риск:" "Risk_init = 4 (I) * 3 (P) * 4 (A) = 48 (Критический уровень риска, красная зона)."
Add-Bullet "• Прямой ущерб:" "Loss_direct = 48 * 150 000 руб. = 7 200 000 руб."
Add-Bullet "• Ущерб от простоя:" "Loss_downtime = 800 000 руб. * 12 ч = 9 600 000 руб."
Add-Bullet "• Совокупный потенциальный ущерб:" "Loss_init = 7 200 000 + 9 600 000 = 16 800 000 руб."

Add-H2 "5.2. Формирование комплекса мер защиты (Приказ № 239)"
Add-P "Для нейтрализации угрозы выбраны две компенсирующие меры:"
Add-Bullet "1. Мера ЗИС.3 (Промышленный межсетевой экран с DPI):" "Снижение вероятности dP_1 = 65%, снижение ущерба dI_1 = 20%. Стоимость: CAPEX = 1 800 000 руб., OPEX = 200 000 руб./год."
Add-Bullet "2. Мера ИАФ.1 (Двухфакторная криптографическая аутентификация):" "Снижение вероятности dP_2 = 50%, снижение ущерба dI_2 = 10%. Стоимость: CAPEX = 600 000 руб., OPEX = 100 000 руб./год."

Add-H2 "5.3. Пошаговый пересчет"
Add-P "Шаг 1. Расчет комбинированного снижения вероятности и ущерба:"
Add-Bullet "• dP_total:" "= 1 - (1 - 0.65) * (1 - 0.50) = 1 - 0.35 * 0.50 = 1 - 0.175 = 0.825 (82.5% снижения вероятности)."
Add-Bullet "• dI_total:" "= 1 - (1 - 0.20) * (1 - 0.10) = 1 - 0.80 * 0.90 = 1 - 0.72 = 0.28 (28.0% снижения ущерба)."

Add-P "Шаг 2. Расчет остаточного риска:"
Add-Bullet "• I_res:" "= 4 * (1 - 0.28) = 2.88."
Add-Bullet "• P_res:" "= 3 * (1 - 0.825) = 0.525."
Add-Bullet "• Risk_res:" "= CEIL[ 2.88 * 0.525 * 4 ] = CEIL[ 6.048 ] = 7 (Низкий уровень риска, зеленая зона)."
Add-P "Риск снизился с 48 (Критический) до 7 (Низкий), то есть на 85.4%."

Add-P "Шаг 3. Финансовый расчет (на горизонте 3 года, T = 3):"
Add-Bullet "• Остаточный ущерб (Loss_res):" "7 * 150 000 руб. + 0.175 * 9 600 000 руб. = 1 050 000 + 1 680 000 = 2 730 000 руб."
Add-Bullet "• Предотвращенный ущерб (Delta_Loss):" "16 800 000 - 2 730 000 = 14 070 000 руб."
Add-Bullet "• Затраты TCO (за 3 года):" "(1 800 000 + 600 000) + (200 000 + 100 000) * 3 = 2 400 000 + 900 000 = 3 300 000 руб."
Add-Bullet "• Чистая выгода (Net Benefit):" "14 070 000 - 3 300 000 = 10 770 000 руб."
Add-Bullet "• Возврат инвестиций ROSI:" "[ (14 070 000 - 3 300 000) / 3 300 000 ] * 100% = +326.36%."
Add-Bullet "• Мультипликатор возврата:" "14 070 000 / 3 300 000 = 4.26x (каждый вложенный рубль предотвращает 4 рубля 26 копеек ущерба)."

# =========================================================================
# РАЗДЕЛ 6: НОРМАТИВНАЯ БАЗА И СПИСОК ЛИТЕРАТУРЫ
# =========================================================================
Add-H1 "6. Нормативная база, стандарты и литература для команды"

Add-P "Для углубленного изучения предметной области всем членам проектной команды (разработчикам, тестировщикам, аналитикам) рекомендуется ознакомиться со следующими источниками."

Add-H2 "6.1. Российская нормативно-правовая база и стандарты"
Add-Bullet "1. Методика оценки угроз безопасности информации (утв. ФСТЭК России 05.02.2021 г.):" "Базовый нормативный документ РФ, регламентирующий порядок идентификации источников угроз, оценку возможностей нарушителей (базовый, средний, высокий потенциал) и оценку последствий."
Add-Bullet "2. Приказ ФСТЭК России от 25.12.2017 № 239:" "«Об утверждении Требований по обеспечению безопасности значимых объектов критической информационной инфраструктуры Российской Федерации». Содержит официальный каталог организационных и технических мер защиты."
Add-Bullet "3. ГОСТ Р ИСО/МЭК 27005-2010:" "«Информационная технология. Методы и средства обеспечения безопасности. Менеджмент риска информационной безопасности». Фундамент матричной классификации рисков и остаточных рисков."
Add-Bullet "4. ГОСТ Р 57580.3-2022:" "«Безопасность финансовых (банковских) операций. Управление рисками реализации информационных угроз». Передовой национальный стандарт в части операционной надежности и финансовой оценки последствий инцидентов."
Add-Bullet "5. ГОСТ Р 59339-2021:" "«Обеспечение безопасности информации в системах управления технологическими процессами». Стандарт, ориентированный на кибербезопасность АСУ ТП, защиту ПЛК и SCADA."
Add-Bullet "6. Банк данных угроз АСУ ТП ФСТЭК России (bduasutp.fstec.ru):" "Официальный специализированный репозиторий угроз, уязвимостей и промышленных объектов воздействия."
Add-Bullet "7. ГОСТ 19.505-79 и ГОСТ 7.32-2017:" "Стандарты ЕСПД на оформление эксплуатационной и аналитической документации."

Add-H2 "6.2. Международные источники и классическая экономика ИБ"
Add-Bullet "1. Gordon, L. A., & Loeb, M. P. (2002):" "«The Economics of Information Security Investment» (ACM Transactions on Information and System Security). Фундаментальная академическая работа о предельной полезности затрат на ИБ (правило 1/e ~ 37% от ущерба)."
Add-Bullet "2. Sonnenreich, W., Albanese, J., & Stout, B. (SANS Institute, 2006):" "«Return on Information Security Investment (ROSI) - A Practical Guide». Классическая практическая методика количественной оценки ROSI."
Add-Bullet "3. NIST Special Publication 800-30 Rev. 1:" "«Guide for Conducting Risk Assessments». Руководство Национального института стандартов и технологий США по моделированию рисков."
Add-Bullet "4. MITRE ATT&CK for Industrial Control Systems (ICS):" "Матрица тактик и техник целевых атак на технологические сети и компоненты АСУ ТП."

# =========================================================================
# РАЗДЕЛ 7: РУКОВОДСТВО ДЛЯ РАЗРАБОТЧИКОВ И ROADMAP
# =========================================================================
Add-H1 "7. Инструкция для разработчиков: сборка, коммиты и развитие"

Add-H2 "7.1. Требования к среде разработки и сборка проекта"
Add-P "Для локальной сборки проекта на рабочей станции разработчика требуется:"
Add-Bullet "•" "Операционная система: Windows 10/11 x64 или Linux (Ubuntu 22.04+)."
Add-Bullet "•" "Компилятор: MinGW-w64 (GCC 13+) или MSVC 2022 с поддержкой стандарта C++20."
Add-Bullet "•" "Фреймворк Qt: Qt 6.11.0 (модули Core, Gui, Qml, Quick, QuickControls2)."
Add-Bullet "•" "Система сборки: CMake 3.16+ и Ninja / MinGW32-make."

Add-P "Команды сборки в терминале:"
Add-Callout "BUILD COMMANDS" "Сборка через CMake и MinGW" "mkdir build`ncd build`ncmake -G `"MinGW Makefiles`" -DCMAKE_BUILD_TYPE=Release ..`ncmake --build . --parallel`nwindeployqt --qmldir ../src/ui bin/Ibe.exe" "0284C7" "F8FAFC"

Add-H2 "7.2. Регламент работы с Git репозиторием"
Add-Bullet "• Основная ветка разработки:" "master2 в репозитории https://github.com/R2aper/ib-effect.git"
Add-Bullet "• Авторство коммитов:" "Строго под учетной записью Shalapai (iostrenko4@gmail.com). Никаких сторонних аккаунтов или внешних контрибьюторов."
Add-Bullet "• Формат сообщений коммитов:" "Conventional Commits: feat(...), fix(...), docs(...), refactor(...)."

Add-H2 "7.3. Дорожная карта развития проекта (Roadmap)"
Add-Bullet "1. Модуль интеграции с онлайн API БДУ ФСТЭК:" "Автоматическая фоновая синхронизация новых угроз и уязвимостей с портала bdu.fstec.ru."
Add-Bullet "2. Автоматический генератор отчетов по ГОСТ:" "Формирование готовых актов моделирования угроз в форматах PDF и DOCX непосредственно из графического интерфейса одной кнопкой."
Add-Bullet "3. Симулятор сценариев атак (What-If Analysis):" "Интерактивное моделирование динамики развития инцидента во времени с оценкой скорости обнаружения (MTTD) и реагирования (MTTR)."

# Page Setup (Standard A4, Margins 2cm = 1134 dxa)
[void]$sb.Append('<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134" w:header="708" w:footer="708" w:gutter="0"/><w:cols w:space="708"/><w:docGrid w:linePitch="360"/></w:sectPr>')

[void]$sb.Append('</w:body>')
[void]$sb.Append('</w:document>')

$docXmlPath = [System.IO.Path]::Combine($tempDir, "word\document.xml")
[System.IO.File]::WriteAllText($docXmlPath, $sb.ToString(), [System.Text.Encoding]::UTF8)

Write-Host ">>> Сборка ZIP-архива в целевой файл $OutputPath..."
if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Force
}

[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null

$zip = [System.IO.Compression.ZipFile]::Open($OutputPath, [System.IO.Compression.ZipArchiveMode]::Create)
$allFiles = Get-ChildItem -Path $tempDir -Recurse -File

foreach ($f in $allFiles) {
    $relative = $f.FullName.Substring($tempDir.Length).TrimStart('\', '/')
    $entryName = $relative.Replace('\', '/')
    $entry = $zip.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
    $entryStream = $entry.Open()
    $fileStream = [System.IO.File]::OpenRead($f.FullName)
    $fileStream.CopyTo($entryStream)
    $fileStream.Close()
    $entryStream.Close()
}
$zip.Dispose()

# Cleanup temp
Remove-Item $tempDir -Recurse -Force

$fi = Get-Item $OutputPath
Write-Host ">>> ГОТОВО! Документ успешно создан: $($fi.FullName)"
Write-Host ">>> Размер файла: $($fi.Length) байт"
