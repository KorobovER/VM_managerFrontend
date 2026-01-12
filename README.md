# CrystalCloudClient - Инструкция по установке

## Требования

- Windows 7 или выше
- PowerShell 3.0 или выше
- **Права администратора НЕ требуются** (регистрация для текущего пользователя)

## Установка

### 1. Распаковка файлов

Скопируйте следующие файлы в одну папку, например `C:\CrystalCloudClient\`:

- `CrystalCloudClient.exe` — приложение для подключения к видеопотоку
- `register-crystalcloudeapp-protocol-user.ps1` — скрипт регистрации протокола
- `crystalcloudeapp-handler.ps1` — обработчик протокола для браузера

### 2. Обновление путей в скриптах

**Отредактируйте `crystalcloudeapp-handler.ps1`:**

Откройте файл в текстовом редакторе (Блокнот) и измените строки 3-4:

```powershell
$appPath = "C:\CrystalCloudClient\CrystalCloudClient.exe"
$logFile = "C:\CrystalCloudClient\crystalcloudeapp-launch.log"
```

Замените `C:\CrystalCloudClient\` на реальный путь, где вы разместили файлы.

**Отредактируйте `register-crystalcloudeapp-protocol-user.ps1`:**

Откройте файл в текстовом редакторе и измените строку 2:

```powershell
$handlerPath = "C:\CrystalCloudClient\crystalcloudeapp-handler.ps1"
```

Используйте тот же путь, что и выше.

### 3. Регистрация протокола Windows

1. Откройте **PowerShell** (обычный, не от администратора):

   - Нажмите `Win + R`
   - Введите `powershell` и нажмите Enter

2. Выполните команду (замените путь на реальный):

```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\CrystalCloudClient\register-crystalcloudeapp-protocol-user.ps1"
```

3. Если всё прошло успешно, вы увидите сообщение:

```
Протокол crystalcloudeapp:// успешно зарегистрирован в HKCU!
Handler: C:\CrystalCloudClient\crystalcloudeapp-handler.ps1
```

### 4. Проверка работы (опционально)

Протестируйте протокол командой:

```powershell
Start-Process "crystalcloudeapp://?-i=test.example.com&-p=12345"
```

Проверьте лог-файл:

```powershell
Get-Content "C:\CrystalCloudClient\crystalcloudeapp-launch.log"
```

В логе должны быть записи о запуске приложения с параметрами `-i` и `-p`.

### 5. Готово!

Теперь при клике на кнопку "Запустить приложение" на веб-сайте:

- Приложение автоматически запустится с правильными параметрами подключения
- Окно PowerShell не будет показываться (работает в скрытом режиме)
- Все действия логируются в файл `crystalcloudeapp-launch.log`

## Устранение неполадок

Если приложение не запускается:

1. Проверьте лог-файл: `C:\CrystalCloudClient\crystalcloudeapp-launch.log`
2. Убедитесь, что пути в скриптах указаны правильно
3. Проверьте, что файл `CrystalCloudClient.exe` существует по указанному пути
4. Перерегистрируйте протокол, выполнив шаг 3 заново
