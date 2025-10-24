@echo off
REM Configuration
set IMG=nexus_dev
set DIR=%USERPROFILE%\.nexus

echo === Nexus Installation ===
echo.

REM Verifie Docker
if not exist "%DIR%" mkdir "%DIR%"
docker --version >nul 2>&1
if %errorlevel% equ 0 (
    echo true > "%DIR%\.state"
    echo [OK] Docker detecte
) else (
    echo false > "%DIR%\.state"
    echo [!] Docker requis
    echo.
    echo Installer via Chocolatey ? (choco install docker-desktop)
    set /p "INST=Oui (O/n): "
    if /i not "%INST%"=="n" (
        where choco >nul 2>&1
        if %errorlevel% equ 0 (
            choco install docker-desktop -y
            echo Redemarrez puis lancez Docker Desktop
            pause
            exit /b 0
        )
    )
    echo Installez Docker: https://docker.com/products/docker-desktop
    start https://docker.com/products/docker-desktop
    pause
    exit /b 1
)

REM Verifie que Docker tourne
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERREUR] Lancez Docker Desktop
    pause
    exit /b 1
)

REM Telecharge
echo.
echo Telechargement...
curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/Dockerfile -o "%DIR%\Dockerfile"
curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/startup.sh -o "%DIR%\startup.sh"

REM Build et run
echo Construction...
docker build -t %IMG% "%DIR%"
if %errorlevel% neq 0 (
    echo [ERREUR] Build echoue
    pause
    exit /b 1
)

echo Lancement...
echo.
set "PROJ=%USERPROFILE%\projects"
set "PROJ=%PROJ:\=/%"
docker run -it --rm -v "%PROJ%:/workspace" %IMG%

REM Nettoyage
echo.
echo Nettoyage ?
set /p "CLEAN=Supprimer l'environnement ? (o/N): "
if /i "%CLEAN%"=="o" (
    docker rmi %IMG% 2>nul
    set /p STATE=<"%DIR%\.state"
    if "%STATE%"=="false" echo Docker installe par ce script. Pour supprimer: choco uninstall docker-desktop
    rmdir /s /q "%DIR%"
    echo [OK] Nettoye
)
pause