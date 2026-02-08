@echo off
REM Install DRAW for Windows (file association + Start Menu shortcut)
REM Usage: Right-click install-windows.cmd and "Run as administrator"
REM   Run again to update. Run with /uninstall to remove.

setlocal enabledelayedexpansion

set "DRAW_DIR=%~dp0"
REM Remove trailing backslash
if "%DRAW_DIR:~-1%"=="\" set "DRAW_DIR=%DRAW_DIR:~0,-1%"

if /i "%1"=="/uninstall" goto :uninstall

echo Installing DRAW from: %DRAW_DIR%
echo.

REM --- File association for .draw files ---
echo   Registering .draw file association...
reg add "HKCU\Software\Classes\.draw" /ve /d "DRAW.Project" /f >nul 2>&1
reg add "HKCU\Software\Classes\DRAW.Project" /ve /d "DRAW Project File" /f >nul 2>&1
reg add "HKCU\Software\Classes\DRAW.Project\DefaultIcon" /ve /d "\"%DRAW_DIR%\ASSETS\ICONS\icon.ico\"" /f >nul 2>&1
reg add "HKCU\Software\Classes\DRAW.Project\shell\open\command" /ve /d "\"%DRAW_DIR%\DRAW.exe\" \"%%1\"" /f >nul 2>&1

REM --- Create Start Menu shortcut ---
echo   Creating Start Menu shortcut...
set "SHORTCUT_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs"
set "VBS_TEMP=%TEMP%\draw_shortcut.vbs"

(
echo Set oShell = CreateObject("WScript.Shell"^)
echo Set oLink = oShell.CreateShortcut("%SHORTCUT_DIR%\DRAW.lnk"^)
echo oLink.TargetPath = "%DRAW_DIR%\DRAW.exe"
echo oLink.WorkingDirectory = "%DRAW_DIR%"
echo oLink.IconLocation = "%DRAW_DIR%\ASSETS\ICONS\icon.ico"
echo oLink.Description = "DRAW - Pixel Art Editor"
echo oLink.Save
) > "%VBS_TEMP%"
cscript //nologo "%VBS_TEMP%"
del "%VBS_TEMP%"

REM --- Notify shell of changes ---
echo   Refreshing shell...
ie4uinit.exe -show >nul 2>&1

echo.
echo Done! DRAW is now installed:
echo   - .draw files are associated with DRAW
echo   - .draw files show the DRAW icon in Explorer
echo   - DRAW shortcut added to Start Menu
echo.
echo To uninstall: %~f0 /uninstall
goto :eof

:uninstall
echo Uninstalling DRAW...
reg delete "HKCU\Software\Classes\.draw" /f >nul 2>&1
reg delete "HKCU\Software\Classes\DRAW.Project" /f >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\DRAW.lnk" >nul 2>&1
ie4uinit.exe -show >nul 2>&1
echo Done. DRAW has been uninstalled.
goto :eof
