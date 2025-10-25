@echo off
REM Nexus Quick Setup for Windows
SETLOCAL ENABLEDELAYEDEXPANSION

SET IMG=nexus_dev
SET BASE_DIR=%CD%\nexus
SET PROJECTS=%BASE_DIR%\projects

echo === Nexus Quick Install (Windows) ===

REM Check Docker
where docker >nul 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Docker CLI not found.
    echo Install Docker Desktop: https://docs.docker.com/desktop/
    pause
    exit /b 1
)

REM Prepare Nexus folder
if not exist "%BASE_DIR%" mkdir "%BASE_DIR%"
if not exist "%BASE_DIR%\Dockerfile" (
    powershell -Command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/zoyern/nexus/main/assets/Dockerfile -OutFile '%BASE_DIR%\Dockerfile'"
)
if not exist "%BASE_DIR%\startup.sh" (
    powershell -Command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/zoyern/nexus/main/assets/startup.sh -OutFile '%BASE_DIR%\startup.sh'"
)

REM Build image
docker build -q -t "%IMG%" "%BASE_DIR%"

REM Run terminal
if not exist "%PROJECTS%" mkdir "%PROJECTS%"
docker run -it --rm -v "%PROJECTS%:/workspace" "%IMG%"

REM Cleanup prompt
set /p DELCHOICE=Delete Nexus folder and image? [y/N]:
if /i "!DELCHOICE!"=="y" (
    docker save -o "%BASE_DIR%\%IMG%.tar" "%IMG%"
    docker rmi "%IMG%"
    rmdir /s /q "%BASE_DIR%"
)
