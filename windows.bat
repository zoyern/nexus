@echo off
REM Nexus Quick Launch (Windows)

SET IMG=nexus_dev
SET BASE_DIR=%~dp0nexus
SET PROJECTS=%BASE_DIR%\projects

IF NOT EXIST "%BASE_DIR%" (
    mkdir "%BASE_DIR%"
)

REM Download files if not exist
IF NOT EXIST "%BASE_DIR%\Dockerfile" (
    powershell -Command "Invoke-WebRequest https://raw.githubusercontent.com/zoyern/nexus/main/assets/Dockerfile -OutFile %BASE_DIR%\Dockerfile"
)
IF NOT EXIST "%BASE_DIR%\startup.sh" (
    powershell -Command "Invoke-WebRequest https://raw.githubusercontent.com/zoyern/nexus/main/assets/startup.sh -OutFile %BASE_DIR%\startup.sh"
)

REM Check Docker
docker info >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [Docker missing or not running] Please start Docker Desktop!
    pause
    exit /b 1
)

REM Run Nexus
IF NOT EXIST "%PROJECTS%" (
    mkdir "%PROJECTS%"
)
echo Launching Nexus Terminal...
docker run -it --rm --name nexus_terminal -v "%PROJECTS%:/workspace" %IMG%

REM Cleanup
echo.
echo =================== CLEANUP ===================
IF EXIST "%PROJECTS%" (
    rmdir /s /q "%PROJECTS%"
    echo [projects\ deleted ✅]
)
SET /P RESPONSE=Delete the rest of Nexus folder and Docker image? [y/N]:
IF /I "%RESPONSE%"=="y" (
    docker save -o "%BASE_DIR%\%IMG%.tar" %IMG%
    docker rmi %IMG% >nul 2>&1
    rmdir /s /q "%BASE_DIR%"
    echo [Nexus cleaned ✅]
) ELSE (
    echo Docker image preserved at %BASE_DIR%\%IMG%.tar
)

pause
