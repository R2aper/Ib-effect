$itJson = [System.IO.File]::ReadAllText((Join-Path (Get-Location) "bdu_it_threats.json"), [System.Text.Encoding]::UTF8)
$asutpJson = [System.IO.File]::ReadAllText((Join-Path (Get-Location) "bdu_asutp_catalog.json"), [System.Text.Encoding]::UTF8)

$prefix = ".pragma library`r`n`r`nvar itThreats = "
$mid = ";`r`n`r`nvar asutpCatalog = "
$suffix = @'
;

function getItThreats() {
    return itThreats;
}

function getAsutpCatalog() {
    return asutpCatalog;
}

function getInfluenceObjects() {
    return asutpCatalog.objects || [];
}

function getAsutpThreats() {
    return asutpCatalog.threats || [];
}

function getAsutpScenarios() {
    return asutpCatalog.scenarios || [];
}

function getAsutpMethods() {
    return asutpCatalog.methods || [];
}

function getObjectThreatsMap() {
    return asutpCatalog.object_threats_map || {};
}

function getThreatsForObject(oaCode) {
    if (!oaCode) return asutpCatalog.threats || [];
    var map = asutpCatalog.object_threats_map || {};
    var codes = map[oaCode];
    if (!codes || codes.length === 0) return asutpCatalog.threats || [];
    var res = [];
    var allTh = asutpCatalog.threats || [];
    for (var i = 0; i < allTh.length; i++) {
        if (codes.indexOf(allTh[i].code) !== -1) {
            res.push(allTh[i]);
        }
    }
    return res;
}
'@

$outPath = Join-Path (Get-Location) "ui\BduData.js"
$content = $prefix + $itJson + $mid + $asutpJson + $suffix
[System.IO.File]::WriteAllText($outPath, $content, [System.Text.Encoding]::UTF8)
Write-Output "Written ui\BduData.js, total length: $($content.Length)"
