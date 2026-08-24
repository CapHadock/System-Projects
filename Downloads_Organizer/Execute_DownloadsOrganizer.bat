@echo off
REM ============================================================
REM  Downloads Organizer Launcher
REM  This batch file runs the Python script that organizes
REM  the Downloads folder automatically.
REM ============================================================

REM Change this path if Downloads_Organizer.py is in a different folder
set SCRIPT_PATH=%~dp0Downloads_Organizer.py

REM ------------------------------------------------------------
REM  Check if Python is available in this system
REM ------------------------------------------------------------
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo ============================================================
    echo  ERROR: Python was not found on this system.
    echo ============================================================
    echo.
    echo  To run this program, Python must be installed and added
    echo  to your system PATH. Follow these steps:
    echo.
    echo  1. Go to https://www.python.org/downloads/
    echo  2. Download the latest Python version for Windows.
    echo  3. Run the installer.
    echo  4. IMPORTANT: On the first installer screen, check the box
    echo     that says "Add python.exe to PATH" before clicking Install.
    echo  5. After installation finishes, restart your computer
    echo     ^(or at least close and reopen this window^).
    echo  6. Run this .bat file again.
    echo.
    echo  If Python is already installed but this message still
    echo  appears, try reinstalling it and make sure the "Add to PATH"
    echo  option is checked.
    echo ============================================================
    echo.
    pause
    exit /b 1
)

echo Python found. Running Downloads Organizer...
echo.

REM Run the script once (organizes existing files and exits)
python "%SCRIPT_PATH%"

REM If you prefer to keep it running and watching for new files,
REM comment the line above and uncomment the line below instead:
REM python "%SCRIPT_PATH%" --watch

echo.
echo Done.
pause