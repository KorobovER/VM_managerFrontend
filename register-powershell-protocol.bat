@echo off
REM Регистрация powershell:// протокола в Windows

REM Проверяем права администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Ошибка: требуются права администратора!
    echo Пожалуйста, запустите этот скрипт от имени администратора.
    pause
    exit /b 1
)

REM Добавляем запись в реестр для регистрации протокола
REM Просто открываем PowerShell без параметров
reg add "HKEY_CLASSES_ROOT\powershell" /ve /d "URL:PowerShell Protocol" /f
reg add "HKEY_CLASSES_ROOT\powershell" /v "URL Protocol" /d "" /f
reg add "HKEY_CLASSES_ROOT\powershell\shell\open\command" /ve /d "powershell.exe -NoExit" /f

echo.
echo Протокол powershell:// успешно зарегистрирован!
echo При клике на powershell:// будет открыт PowerShell
echo.
pause
