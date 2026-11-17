@echo off
setlocal EnableExtensions

:: Request Administrator privileges if not already elevated.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator permission...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
set "BACKUP=%HOSTS%.bak"

echo.
echo Updating Windows hosts file...
echo.

if not exist "%HOSTS%" (
    echo ERROR: Hosts file not found: "%HOSTS%"
    pause
    exit /b 1
)

:: Create a backup before making changes.
copy /y "%HOSTS%" "%BACKUP%" >nul
if errorlevel 1 (
    echo ERROR: Could not back up the hosts file.
    pause
    exit /b 1
)

:: Remove existing active entries for these hostnames, then add the requested mappings.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p = $env:SystemRoot + '\System32\drivers\etc\hosts';" ^
  "$lines = [System.IO.File]::ReadAllLines($p);" ^
  "$lines = @($lines | Where-Object { $_ -notmatch '^\s*(?!#)\S+\s+(admin\.portal\.tgs\.com\.vn|api\.portal\.tgs\.com\.vn)(\s|$)' });" ^
  "$lines += '10.10.10.91 admin.portal.tgs.com.vn';" ^
  "$lines += '10.10.10.92 api.portal.tgs.com.vn';" ^
  "[System.IO.File]::WriteAllLines($p, $lines, [System.Text.Encoding]::ASCII)"

if errorlevel 1 (
    echo ERROR: Failed to update hosts file.
    echo Backup is available at: "%BACKUP%"
    pause
    exit /b 1
)

ipconfig /flushdns >nul

echo Hosts file updated successfully:
echo   10.10.10.91 admin.portal.tgs.com.vn
echo   10.10.10.92 api.portal.tgs.com.vn
echo.
echo Backup: "%BACKUP%"
echo DNS cache flushed.
echo.
pause
endlocal
