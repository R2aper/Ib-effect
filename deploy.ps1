# deploy.ps1 - Скрипт сборки и развертывания Net ROSI Calculator
$ErrorActionPreference = "Stop"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Сборка и развертывание Net ROSI Calculator в dist" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }

$env:PATH = "C:\Qt\Tools\CMake_64\bin;C:\Qt\Tools\mingw1310_64\bin;C:\Qt\6.11.0\mingw_64\bin;C:\Qt\Tools\Ninja;" + $env:PATH

$buildDir = "$scriptDir\build\Desktop_Qt_6_11_0_MinGW_64_bit-Debug"
$distDir  = "$scriptDir\dist"

Write-Host "`n[1/2] Компиляция проекта..." -ForegroundColor Yellow
& ninja.exe -C $buildDir
if ($LASTEXITCODE -ne 0) {
    Write-Error "Ошибка при сборке ninja."
    exit 1
}

Write-Host "`n[2/2] Установка и сборка зависимостей (cmake --install)..." -ForegroundColor Yellow
& cmake.exe --install $buildDir --prefix $distDir
if ($LASTEXITCODE -ne 0) {
    Write-Error "Ошибка при cmake --install."
    exit 1
}

Write-Host "`n========================================================" -ForegroundColor Green
Write-Host "УСПЕШНО ЗАВЕРШЕНО!" -ForegroundColor Green
Write-Host "Автономное приложение готово в папке:" -ForegroundColor Green
Write-Host "  $distDir\bin" -ForegroundColor White
Write-Host "Файл запуска:" -ForegroundColor Green
Write-Host "  $distDir\bin\appNew.exe" -ForegroundColor White
Write-Host "========================================================" -ForegroundColor Green
