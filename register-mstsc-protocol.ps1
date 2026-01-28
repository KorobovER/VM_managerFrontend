# Скрипт для регистрации mstsc:// протокола в Windows
# Запустить с правами администратора

# Путь к реестру для регистрации протокола
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\URL Scheme Handlers\mstsc"

# Создаем запись в реестре (перезаписываем если существует)
New-Item -Path $regPath -Force | Out-Null

# Устанавливаем значение по умолчанию (описание протокола)
Set-ItemProperty -Path $regPath -Name "(Default)" -Value "URL:mstsc Protocol" -Force

# Устанавливаем флаг URL Protocol
Set-ItemProperty -Path $regPath -Name "URL Protocol" -Value "" -Force

# Создаем подключ для команды запуска
$commandPath = "$regPath\shell\open\command"
New-Item -Path $commandPath -Force | Out-Null

# Устанавливаем команду запуска с полным путем к mstsc.exe
# %1 будет заменена на параметр из mstsc://host:port
Set-ItemProperty -Path $commandPath -Name "(Default)" -Value "`"C:\Windows\System32\mstsc.exe`" /v:%1" -Force

Write-Host "Протокол mstsc:// успешно зарегистрирован"
Write-Host "Теперь можно использовать ссылки вида: mstsc://127.0.0.1:9001"
