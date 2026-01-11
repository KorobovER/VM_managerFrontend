# CrystalCloudClient - Инструкция по установке

## Требования

- Windows 7 или выше
- PowerShell 3.0 или выше
- Права администратора для регистрации протокола

## Установка

### 1. Распаковка файлов

Распакуйте следующие файлы в одну папку, например `C:\Program Files\CrystalCloudClient\`:

- `CrystalCloudClient.exe` — приложение для подключения к видеопотоку
- `register-crystalcloudeapp-protocol.ps1` — скрипт регистрации протокола
- `crystalcloudeapp-handler.ps1` — обработчик протокола для браузера

### 2. Обновление путей в скриптах

**Отредактируйте `register-crystalcloudeapp-protocol.ps1`:**

Откройте файл в текстовом редакторе и измените строку 4:

```powershell
$appPath = "C:\Program Files\CrystalCloudClient\CrystalCloudClient.exe"
```

Замените `C:\Program Files\CrystalCloudClient\` на реальный путь, где вы разместили файлы.

**Отредактируйте `crystalcloudeapp-handler.ps1`:**

Откройте файл в текстовом редакторе и измените строку 3:

```powershell
$appPath = "C:\Program Files\CrystalCloudClient\CrystalCloudClient.exe"
```

Используйте тот же путь, что и выше.

### 3. Регистрация протокола Windows

1. Откройте **PowerShell** от администратора:

   - Нажмите `Win + X`
   - Выберите "Windows PowerShell (администратор)"

2. Выполните команду (замените путь на реальный):

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Program Files\CrystalCloudClient\register-crystalcloudeapp-protocol.ps1"
```

3. Если всё прошло успешно, вы увидите сообщение:

```
Протокол crystalcloudeapp:// успешно зарегистрирован в HKLM!
Приложение: C:\Program Files\CrystalCloudClient\CrystalCloudClient.exe
```

### 4. Готово!

Теперь при клике на кнопку "Запустить приложение" на веб-сайте приложение будет автоматически запускаться с правильными параметрами подключения.
