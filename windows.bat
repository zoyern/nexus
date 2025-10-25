@echo off
REM Nexus - Quick Launch Windows
SETLOCAL ENABLEEXTENSIONS

SET BASE_DIR=%CD%\nexus
SET PROJECTS=%BASE_DIR%\projects
SET IMG=nexus_dev

IF NOT EXIST "%BASE_DIR%" mkdir "%BASE_DIR%"

echo Downloading Dockerfile and startup script...
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/zoyern/nexus/main/nexus/Dockerfile' -OutFile '%BASE_DIR%\Dockerfile'"
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/zoyern/nexus/main/nexus/startup.sh' -OutFile '%BASE_DIR%\startup.sh'"

echo Building Docker environment...
docker build -t %IMG% "%BASE_DIR%"

echo === Launching Nexus Terminal ===
IF NOT EXIST "%PROJECTS%" mkdir "%PROJECTS%"
docker run -it --rm --name nexus_terminal -v "%PROJECTS%:/workspace" %IMG%

REM Cleanup
rmdir /s /q "%PROJECTS%"
echo [projects/ deleted ✅]

pause
