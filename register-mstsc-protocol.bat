@echo off
REM Регистрация mstsc:// протокола в Windows

setlocal enabledelayedexpansion

REM Проверяем права администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Ошибка: требуются права администратора!
    echo Пожалуйста, запустите этот скрипт от имени администратора.
    pause
    exit /b 1
)

REM Получаем путь к текущей директории
set "SCRIPT_DIR=%~dp0"

REM Создаем вспомогательный скрипт для обработки параметров
set "HANDLER_SCRIPT=%SCRIPT_DIR%mstsc-handler.ps1"

REM Создаем PowerShell скрипт-обработчик
(
    echo $uri = $args[0]
    echo $host_port = $uri -replace 'mstsc://', ''
    echo if ($host_port) {
    echo     mstsc /v:$host_port
    echo }
) > "%HANDLER_SCRIPT%"

REM Добавляем запись в реестр для регистрации протокола
reg add "HKEY_CLASSES_ROOT\mstsc" /ve /d "URL:Remote Desktop Protocol" /f
reg add "HKEY_CLASSES_ROOT\mstsc" /v "URL Protocol" /d "" /f
reg add "HKEY_CLASSES_ROOT\mstsc\shell\open\command" /ve /d "powershell.exe -NoExit -ExecutionPolicy Bypass -File \"%HANDLER_SCRIPT%\" \"%%%%1\"" /f

echo.
echo Протокол mstsc:// успешно зарегистрирован!
echo Обработчик: %HANDLER_SCRIPT%
echo.
echo Теперь вы можете использовать mstsc://host:port для подключения через RDP
echo.
pause
