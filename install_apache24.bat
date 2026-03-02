@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Проверка прав администратора
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] ОШИБКА: Запустите скрипт от имени АДМИНИСТРАТОРА.
    pause
    exit /b
)

:: --- НАСТРОЙКИ ПУТЕЙ ---
set "SOURCE_FOLDER=Apache24"
set "NEW_NAME=Apache2.4"
set "BASE_PATH=C:\Program Files\Apache Software Foundation"
set "TARGET_PATH=%BASE_PATH%\%NEW_NAME%"
set "LNK=%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\ApacheMonitor.lnk"

echo [+] Шаг 1: Очистка старых процессов и служб...
taskkill /f /im ApacheMonitor.exe >nul 2>&1
taskkill /f /im httpd.exe >nul 2>&1
net stop Apache2.4 /y >nul 2>&1
sc delete Apache2.4 >nul 2>&1

echo [+] Шаг 2: Копирование файлов в %TARGET_PATH%...
if not exist "%SOURCE_FOLDER%" (
    echo [!] ОШИБКА: Папка %SOURCE_FOLDER% не найдена рядом со скриптом!
    pause
    exit /b
)
if not exist "%BASE_PATH%" mkdir "%BASE_PATH%"
xcopy "%SOURCE_FOLDER%" "%TARGET_PATH%\" /E /I /H /Y >nul

echo [+] Шаг 3: Настройка httpd.conf (SRVROOT)...
set "CONF_FILE=%TARGET_PATH%\conf\httpd.conf"
:: Меняем путь на Unix-style (с прямыми слешами) для Apache
powershell -Command "(gc '%CONF_FILE%') -replace 'Define SRVROOT \".*\"', 'Define SRVROOT \"%TARGET_PATH:\=/%\"' | Out-File -encoding ASCII '%CONF_FILE%'"

echo [+] Шаг 4: Установка службы Apache2.4...
"%TARGET_PATH%\bin\httpd.exe" -k install -n "Apache2.4"

echo [+] Шаг 5: Разблокировка файлов и настройка автозагрузки...
:: Снимаем флаг "скачано из интернета" со всех файлов в папке
powershell -Command "Get-ChildItem -Path '%TARGET_PATH%' -Recurse | Unblock-File"

:: Создаем ярлык с предварительной очисткой процесса (чтобы не было окна "Already started")
set "MON_EXE=%TARGET_PATH%\bin\ApacheMonitor.exe"
powershell -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%LNK%'); $s.TargetPath='cmd.exe'; $s.Arguments='/c taskkill /f /im ApacheMonitor.exe 2>nul & start \"\" \"%MON_EXE%\"'; $s.WindowStyle=7; $s.Save()"

:: Запускаем монитор прямо сейчас
start "" "%MON_EXE%"

echo.
echo ======================================================
echo УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!
echo ======================================================
echo 1. Apache Monitor запущен в трее.
echo 2. В 1С выберите Apache 2.4
echo ======================================================
pause
