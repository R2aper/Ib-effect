@echo off
chcp 65001 >nul
echo ========================================================
echo   Сборка и развертывание Net ROSI Calculator в папку dist
echo ========================================================

set QT_DIR=C:\Qt\6.11.0\mingw_64
set MINGW_DIR=C:\Qt\Tools\mingw1310_64
set CMAKE_DIR=C:\Qt\Tools\CMake_64\bin
set NINJA_DIR=C:\Qt\Tools\Ninja

set PATH=%CMAKE_DIR%;%MINGW_DIR%\bin;%QT_DIR%\bin;%NINJA_DIR%;%PATH%

set BUILD_DIR=%~dp0build\Desktop_Qt_6_11_0_MinGW_64_bit-Debug
set DIST_DIR=%~dp0dist

echo [1/2] Компиляция проекта...
ninja.exe -C "%BUILD_DIR%"
if errorlevel 1 (
    echo [ОШИБКА] Ошибка при компиляции.
    pause
    exit /b 1
)

echo.
echo [2/2] Установка (копирование exe, bdu.sqlite, DLL и QML плагинов)...
cmake.exe --install "%BUILD_DIR%" --prefix "%DIST_DIR%"
if errorlevel 1 (
    echo [ОШИБКА] Ошибка при установке.
    pause
    exit /b 1
)

echo.
echo ========================================================
echo УСПЕШНО ЗАВЕРШЕНО!
echo Автономное приложение собрано в папку:
echo   %DIST_DIR%\bin
echo Файл для запуска:
echo   %DIST_DIR%\bin\appNew.exe
echo ========================================================
pause
