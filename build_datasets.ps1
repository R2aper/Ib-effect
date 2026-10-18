[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.IO.Compression.FileSystem

$UBI = [char]0x0423 + [char]0x0411 + [char]0x0418 # "УБИ"
$OA  = [char]0x041E + [char]0x0410               # "ОА"

function Strip-Html {
    param([string]$html)
    if ([string]::IsNullOrEmpty($html)) { return "" }
    $text = [System.Text.RegularExpressions.Regex]::Replace($html, '<[^>]+>', ' ')
    $text = $text.Replace('&nbsp;', ' ').Replace('&quot;', '"').Replace('&lt;', '<').Replace('&gt;', '>').Replace('&amp;', '&')
    $text = [System.Text.RegularExpressions.Regex]::Replace($text, '\s+', ' ').Trim()
    return $text
}

Write-Output "Step 1: Converting thrlist.xlsx -> bdu_it_threats.json..."
$zipPath = Join-Path $env:USERPROFILE "Downloads\thrlist.xlsx"
$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)

$sstEntry = $zip.GetEntry("xl/sharedStrings.xml")
$sstStream = $sstEntry.Open()
[xml]$sstXml = (New-Object System.IO.StreamReader($sstStream, [System.Text.Encoding]::UTF8)).ReadToEnd()
$sstStream.Dispose()

$strings = @()
foreach ($si in $sstXml.sst.si) {
    if ($si.t) {
        $strings += $si.t
    } elseif ($si.r) {
        $t = ""
        foreach ($r in $si.r) { $t += $r.t }
        $strings += $t
    } else {
        $strings += ""
    }
}

$sheetEntry = $zip.GetEntry("xl/worksheets/sheet1.xml")
$sheetStream = $sheetEntry.Open()
[xml]$sheetXml = (New-Object System.IO.StreamReader($sheetStream, [System.Text.Encoding]::UTF8)).ReadToEnd()
$sheetStream.Dispose()
$zip.Dispose()

$rows = $sheetXml.worksheet.sheetData.row
$itThreats = @()

for ($i = 2; $i -lt $rows.Count; $i++) {
    $r = $rows[$i]
    $rowMap = @{}
    foreach ($c in $r.c) {
        $colLetter = [System.Text.RegularExpressions.Regex]::Replace($c.r, '\d+', '')
        $val = $c.v
        if ($c.t -eq "s") {
            $val = $strings[[int]$val]
        }
        $rowMap[$colLetter] = $val
    }

    $rawId = $rowMap['A']
    if ([string]::IsNullOrWhiteSpace($rawId)) { continue }

    $num = 0
    if ([int]::TryParse($rawId, [ref]$num)) {
        $idStr = "$UBI." + $num.ToString("D3")
    } else {
        $idStr = "$UBI.$rawId"
    }

    $desc = $rowMap['C']
    if ($desc) {
        $desc = $desc.Replace('_x000D_', '').Trim()
    } else {
        $desc = ""
    }

    $item = [PSCustomObject]@{
        id = $idStr
        numeric_id = $num
        name = [string]$rowMap['B']
        description = $desc
        violator_source = [string]$rowMap['D']
        target_object = [string]$rowMap['E']
        confidentiality = ($rowMap['F'] -eq '1')
        integrity = ($rowMap['G'] -eq '1')
        availability = ($rowMap['H'] -eq '1')
        status = [string]$rowMap['K']
    }
    $itThreats += $item
}

$itJson = $itThreats | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "bdu_it_threats.json"), $itJson, [System.Text.Encoding]::UTF8)
Write-Output "Successfully written bdu_it_threats.json with $($itThreats.Count) threats."

Write-Output "Step 2: Normalizing ASUTP threats -> bdu_asutp_catalog.json..."
$rawAsutp = Get-Content -Encoding UTF8 (Join-Path (Get-Location) "asutp_threats.json") -Raw | ConvertFrom-Json

# 1. Objects (14 items)
$asutpObjects = @()
$objBaseline = @{
    "$OA.001" = @{ asset_type = "Operator Workstation"; default_criticality = 3; category = "Workstation" }
    "$OA.002" = @{ asset_type = "Engineering Workstation"; default_criticality = 4; category = "Workstation" }
    "$OA.003" = @{ asset_type = "Industrial Server (SCADA/DCS)"; default_criticality = 4; category = "Server" }
    "$OA.004" = @{ asset_type = "Historian Server"; default_criticality = 3; category = "Server" }
    "$OA.005" = @{ asset_type = "HMI Operator Panel"; default_criticality = 3; category = "Field Device" }
    "$OA.006" = @{ asset_type = "PLC (Programmable Logic Controller)"; default_criticality = 4; category = "Controller" }
    "$OA.007" = @{ asset_type = "Safety Instrumented System (SIS / ESD)"; default_criticality = 4; category = "Controller" }
    "$OA.008" = @{ asset_type = "Sensors & Actuators (Field Instruments)"; default_criticality = 2; category = "Field Device" }
    "$OA.009" = @{ asset_type = "Removable Storage Media (USB / Flash)"; default_criticality = 4; category = "Removable Media" }
    "$OA.010" = @{ asset_type = "IIoT Device"; default_criticality = 2; category = "IoT" }
    "$OA.011" = @{ asset_type = "Active Network Equipment (Industrial Switch)"; default_criticality = 3; category = "Network" }
    "$OA.012" = @{ asset_type = "Security Appliances (Industrial FW, Data Diode)"; default_criticality = 4; category = "Security" }
    "$OA.013" = @{ asset_type = "Mobile Device (Field Tablet)"; default_criticality = 2; category = "Mobile" }
    "$OA.014" = @{ asset_type = "Wireless Equipment (Wi-Fi / Zigbee / LoRa)"; default_criticality = 3; category = "Network" }
}

foreach ($o in $rawAsutp.influence_objects) {
    $meta = $objBaseline[$o.code]
    $crit = 3
    $cat = "General"
    if ($meta) {
        $crit = $meta.default_criticality
        $cat = $meta.category
    }
    $asutpObjects += [PSCustomObject]@{
        id = $o.id
        code = $o.code
        title = $o.title
        description = (Strip-Html $o.description)
        default_criticality = $crit
        category = $cat
    }
}
$asutpObjects = $asutpObjects | Sort-Object code

# 2. Threats (10 items)
$asutpThreats = @()
foreach ($th in $rawAsutp.threats) {
    $asutpThreats += [PSCustomObject]@{
        id = $th.id
        code = $th.code
        title = $th.title
        description = (Strip-Html $th.description)
    }
}
$asutpThreats = $asutpThreats | Sort-Object code

# 3. Attack Methods (SPA, 171 items)
$asutpMethods = @()
foreach ($g in $rawAsutp.method_implement_threat_groups) {
    $groupTitle = $g.title
    foreach ($m in $g.method_implement_threats) {
        $asutpMethods += [PSCustomObject]@{
            id = $m.id
            code = $m.code
            title = $m.title
            group = $groupTitle
        }
    }
}
$asutpMethods = $asutpMethods | Sort-Object code

# 4. Scenarios (49 items)
$asutpScenarios = @()
foreach ($st in $rawAsutp.typical_scenario_types) {
    $typeName = $st.title
    foreach ($sc in $st.typical_scenarios) {
        $m = [System.Text.RegularExpressions.Regex]::Match($sc.title, '^([СC]\d+\.\d+)')
        $code = if ($m.Success) { $m.Groups[1].Value } else { "" }

        $steps = @()
        if ($sc.attack_steps) {
            foreach ($step in $sc.attack_steps) {
                $steps += [PSCustomObject]@{
                    step_number = $step.attack_step
                    description = (Strip-Html $step.attack_step_description)
                    threat_code = if ($step.threat) { $step.threat.code } else { "" }
                    threat_title = if ($step.threat) { $step.threat.title } else { "" }
                }
            }
        }

        $asutpScenarios += [PSCustomObject]@{
            id = $sc.id
            code = $code
            title = $sc.title
            scenario_type = $typeName
            step_count = $steps.Count
            steps = $steps
        }
    }
}
$asutpScenarios = $asutpScenarios | Sort-Object code

# 5. Violators (4 items)
$asutpViolators = @()
foreach ($v in $rawAsutp.violators) {
    $asutpViolators += [PSCustomObject]@{
        id = $v.id
        title = $v.title
        description = (Strip-Html $v.description)
    }
}

# 6. Object-to-Threats Mapping Matrix
$UTP = [char]0x0423 + [char]0x0422 + [char]0x041F # "УТП"
$mapping = @{
    "$OA.001" = @("$UTP:01", "$UTP:02", "$UTP:03", "$UTP:07", "$UTP:10")
    "$OA.002" = @("$UTP:01", "$UTP:02", "$UTP:03", "$UTP:05", "$UTP:06", "$UTP:07", "$UTP:10")
    "$OA.003" = @("$UTP:01", "$UTP:02", "$UTP:03", "$UTP:04", "$UTP:06", "$UTP:07")
    "$OA.004" = @("$UTP:01", "$UTP:02", "$UTP:04", "$UTP:07")
    "$OA.005" = @("$UTP:02", "$UTP:03", "$UTP:05", "$UTP:07")
    "$OA.006" = @("$UTP:03", "$UTP:05", "$UTP:06", "$UTP:08", "$UTP:10")
    "$OA.007" = @("$UTP:05", "$UTP:06", "$UTP:08", "$UTP:10")
    "$OA.008" = @("$UTP:05", "$UTP:08", "$UTP:09")
    "$OA.009" = @("$UTP:01", "$UTP:02", "$UTP:05", "$UTP:07")
    "$OA.010" = @("$UTP:01", "$UTP:03", "$UTP:05", "$UTP:08", "$UTP:10")
    "$OA.011" = @("$UTP:02", "$UTP:03", "$UTP:04", "$UTP:06")
    "$OA.012" = @("$UTP:02", "$UTP:03", "$UTP:06", "$UTP:07")
    "$OA.013" = @("$UTP:01", "$UTP:02", "$UTP:03", "$UTP:07")
    "$OA.014" = @("$UTP:02", "$UTP:03", "$UTP:04", "$UTP:06", "$UTP:10")
}

$catalog = [PSCustomObject]@{
    objects = $asutpObjects
    threats = $asutpThreats
    methods = $asutpMethods
    scenarios = $asutpScenarios
    violators = $asutpViolators
    object_threats_map = $mapping
}

$catJson = $catalog | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "bdu_asutp_catalog.json"), $catJson, [System.Text.Encoding]::UTF8)
Write-Output "Successfully written bdu_asutp_catalog.json."
