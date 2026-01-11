@echo off
REM AI漫导后端服务停止脚本 (Windows)
REM 使用方法: stop.bat [dev|prod]

setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

set MODE=%1
if "%MODE%"=="" set MODE=prod

echo ========================================
echo   AI漫导后端服务停止脚本
echo ========================================
echo.

REM 停止服务
if "%MODE%"=="dev" (
    echo [信息] 停止开发环境服务...
    docker-compose -f docker-compose.dev.yml down
) else if "%MODE%"=="prod" (
    echo [信息] 停止生产环境服务...
    docker-compose down
) else (
    echo [错误] 无效的模式 '%MODE%'
    echo 使用方法: stop.bat [dev|prod]
    exit /b 1
)

if %ERRORLEVEL% NEQ 0 (
    echo [错误] 服务停止失败
    exit /b 1
)

echo.
echo [成功] 服务已停止

endlocal
