@echo off
REM Скрипт для запуска RDP подключения
REM Использование: launch-rdp.bat 127.0.0.1 9001

if "%1"=="" (
    echo Использование: launch-rdp.bat ^<host^> ^<port^>
    exit /b 1
)

if "%2"=="" (
    echo Использование: launch-rdp.bat ^<host^> ^<port^>
    exit /b 1
)

set HOST=%1
set PORT=%2

echo Запуск RDP подключения к %HOST%:%PORT%...
mstsc /v:%HOST%:%PORT%

exit /b 0
