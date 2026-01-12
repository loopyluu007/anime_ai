@echo off
REM AI漫导统一停止脚本 (Windows)
REM 使用方法: stop.bat [all|frontend|backend]

setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

set COMPONENT=%1
if "%COMPONENT%"=="" set COMPONENT=all

echo ========================================
echo   停止服务
echo ========================================
echo.

if "%COMPONENT%"=="frontend" (
    echo [信息] 停止前端服务...
    docker-compose stop frontend
    docker-compose rm -f frontend
) else if "%COMPONENT%"=="backend" (
    echo [信息] 停止后端服务...
    docker-compose stop postgres redis minio agent_service media_service data_service api_gateway
    docker-compose rm -f agent_service media_service data_service api_gateway
) else (
    echo [信息] 停止所有服务...
    docker-compose down
)

if %ERRORLEVEL% NEQ 0 (
    echo [错误] 停止服务失败
    exit /b 1
)

echo.
echo [成功] 服务已停止
echo.

endlocal
