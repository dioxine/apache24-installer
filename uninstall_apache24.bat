@echo off
:: Переключаем консоль в UTF-8 для корректного отображения кириллицы
chcp 65001 >nul
setlocal

:: Проверка прав администратора
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] ОШИБКА: Запустите скрипт от имени АДМИНИСТРАТОРА.
    pause
    exit /b
)

:: --- НАСТРОЙКИ ПУТЕЙ ---
set "LNK=%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\ApacheMonitor.lnk"
set "BASE_PATH=C:\Program Files\Apache Software Foundation"

echo [+] Шаг 1: Остановка и удаление службы Apache2.4...
:: Останавливаем службу (флаг /y подтверждает остановку зависимых служб)
net stop Apache2.4 /y >nul 2>&1
sc delete Apache2.4 >nul 2>&1

echo [+] Шаг 2: Завершение активных процессов...
:: Убиваем монитор и сам httpd, чтобы разблокировать файлы в папке
taskkill /f /im ApacheMonitor.exe >nul 2>&1
taskkill /f /im httpd.exe >nul 2>&1

echo [+] Шаг 3: Удаление ярлыка из автозагрузки...
if exist "%LNK%" (
    del /f /q "%LNK%"
    echo [OK] Ярлык автозагрузки удален.
)

echo.
echo ======================================================
echo УДАЛЕНИЕ ЗАВЕРШЕНО УСПЕШНО!
echo ======================================================
echo Теперь вы можете вручную удалить системную папку:
echo %BASE_PATH%
echo ======================================================
pause
