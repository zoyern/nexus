@echo off
REM Nexus - Quick setup for Windows
SETLOCAL ENABLEDELAYEDEXPANSION

SET IMG=nexus_dev
SET BASE_DIR=%CD%\nexus
SET PROJECTS=%BASE_DIR%\projects
SET MAX_WAIT=60
SET DOCKER_STARTED=0

REM ===========================
REM MAIN
REM ===========================
echo.
echo ================================
echo   NEXUS DEV ENVIRONMENT
echo ================================
echo.

call :check_docker
call :setup_files
call :build_image
call :run_container
call :cleanup
exit /b 0

REM ===========================
REM CHECKS
REM ===========================
:check_docker
echo [+] Docker
where docker >nul 2>&1
if ERRORLEVEL 1 (
    echo   [X] Docker not installed
    echo   --^> Install Docker Desktop: https://docker.com/get-started
    pause
    exit /b 1
)

REM Try starting Docker if not running
docker info >nul 2>&1
if ERRORLEVEL 1 (
    SET DOCKER_STARTED=1
    echo   [!] Docker not running, starting...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    
    REM Wait for Docker to be ready
    echo   Waiting for Docker
    SET /A count=0
    :wait_docker
    docker info >nul 2>&1
    if ERRORLEVEL 1 (
        timeout /t 2 /nobreak >nul
        SET /A count+=2
        if !count! LEQ 10 (
            echo   Still waiting...
        ) else (
            <nul set /p="."
        )
        if !count! GEQ %MAX_WAIT% (
            echo.
            echo   [X] Docker did not start within %MAX_WAIT%s
            exit /b 1
        )
        goto :wait_docker
    )
    echo.
)

echo   [V] Running on Windows
exit /b 0

REM ===========================
REM SETUP
REM ===========================
:setup_files
echo.
echo [+] Configuration
if not exist "%BASE_DIR%" mkdir "%BASE_DIR%"

if exist "%BASE_DIR%\Dockerfile" if exist "%BASE_DIR%\startup.sh" (
    echo   [V] Files ready
    exit /b 0
)

echo   [!] Downloading configuration...
powershell -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/zoyern/nexus/main/nexus/Dockerfile' -OutFile '%BASE_DIR%\Dockerfile' -ErrorAction Stop } catch { exit 1 }"
if ERRORLEVEL 1 (
    echo   [X] Failed to download Dockerfile
    exit /b 1
)

powershell -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/zoyern/nexus/main/nexus/startup.sh' -OutFile '%BASE_DIR%\startup.sh' -ErrorAction Stop } catch { exit 1 }"
if ERRORLEVEL 1 (
    echo   [X] Failed to download startup.sh
    exit /b 1
)

echo   [V] Configuration downloaded
exit /b 0

REM ===========================
REM BUILD
REM ===========================
:build_image
echo.
echo [+] Docker Image

REM Check if rebuild needed
docker image inspect %IMG% >nul 2>&1
if not ERRORLEVEL 1 (
    for /f %%i in ('powershell -Command "Get-FileHash '%BASE_DIR%\Dockerfile' -Algorithm MD5 | Select-Object -ExpandProperty Hash"') do set DOCKERFILE_HASH=%%i
    for /f "delims=" %%i in ('docker image inspect %IMG% --format="{{index .Config.Labels \"dockerfile.hash\"}}" 2^>nul') do set IMAGE_HASH=%%i
    
    if "!DOCKERFILE_HASH!"=="!IMAGE_HASH!" (
        echo   [V] Image up-to-date
        exit /b 0
    )
    echo   [!] Dockerfile changed, rebuilding...
)

REM Build image
echo   Building image...
for /f %%i in ('powershell -Command "Get-FileHash '%BASE_DIR%\Dockerfile' -Algorithm MD5 | Select-Object -ExpandProperty Hash"') do set HASH=%%i
for /f %%i in ('powershell -Command "Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'"') do set TIMESTAMP=%%i

docker build -q --label "dockerfile.hash=!HASH!" --label "build.timestamp=!TIMESTAMP!" -t %IMG% "%BASE_DIR%" >nul 2>&1
if ERRORLEVEL 1 (
    echo   [X] Build failed
    exit /b 1
)

echo   [V] Image built successfully
exit /b 0

REM ===========================
REM RUN
REM ===========================
:run_container
echo.
echo [+] Launching Nexus
if not exist "%PROJECTS%" mkdir "%PROJECTS%"
echo.

docker run -it --rm --name nexus_terminal -v "%PROJECTS%:/workspace/projects" -e "HOST_OS=Windows" %IMG%
exit /b 0

REM ===========================
REM CLEANUP
REM ===========================
:cleanup
echo.
echo [+] Cleanup

REM Always remove projects
if exist "%PROJECTS%" (
    rmdir /s /q "%PROJECTS%" 2>nul
    echo   [V] Projects removed
)

REM Always remove Docker image
docker rmi %IMG% >nul 2>&1
if not ERRORLEVEL 1 echo   [V] Image removed

REM Close Docker if we started it
if %DOCKER_STARTED%==1 (
    echo   [!] Closing Docker...
    taskkill /IM "Docker Desktop.exe" /F >nul 2>&1
    echo   [V] Docker closed
)

REM Ask for configuration cleanup
echo.
set /p CHOICE="  Remove configuration files? [y/N]: "
if /i "!CHOICE!"=="y" (
    rmdir /s /q "%BASE_DIR%" 2>nul
    echo   [V] Configuration removed
) else (
    echo   [!] Configuration kept in %BASE_DIR%
)

exit /b 0
