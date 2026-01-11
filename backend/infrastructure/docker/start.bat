@echo off
REM AI漫导后端服务启动脚本 (Windows)
REM 使用方法: start.bat [dev|prod]

setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

set MODE=%1
if "%MODE%"=="" set MODE=prod

echo ========================================
echo   AI漫导后端服务启动脚本
echo ========================================
echo.

REM 检查 Docker
where docker >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 未找到 Docker，请先安装 Docker
    exit /b 1
)

REM 检查 docker-compose
where docker-compose >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 未找到 docker-compose，请先安装 docker-compose
    exit /b 1
)

echo [信息] 环境检查通过
echo.

REM 检查 .env 文件
if not exist "..\..\.env" (
    echo [警告] 未找到 .env 文件
    if exist "..\..\.env.example" (
        echo [信息] 正在从 .env.example 创建 .env 文件...
        copy "..\..\.env.example" "..\..\.env" >nul
        echo [成功] 已创建 .env 文件，请编辑配置后重新运行
        echo [提示] 请至少配置以下环境变量:
        echo   - GLM_API_KEY
        echo   - TUZI_API_KEY
        echo   - GEMINI_API_KEY
        echo   - SECRET_KEY
        exit /b 1
    ) else (
        echo [错误] 未找到 .env.example 文件
        exit /b 1
    )
)

REM 启动服务
if "%MODE%"=="dev" (
    echo [信息] 启动开发环境...
    echo [注意] 开发环境只启动基础设施（数据库、Redis、MinIO）
    echo [注意] 服务需要本地运行
    docker-compose -f docker-compose.dev.yml up -d
) else if "%MODE%"=="prod" (
    echo [信息] 启动生产环境...
    docker-compose up -d
) else (
    echo [错误] 无效的模式 '%MODE%'
    echo 使用方法: start.bat [dev|prod]
    exit /b 1
)

if %ERRORLEVEL% NEQ 0 (
    echo [错误] 服务启动失败
    exit /b 1
)

echo.
echo [成功] 服务启动完成
echo.
echo 服务地址:
echo   - API Gateway: http://localhost:8000
echo   - Agent Service: http://localhost:8001
echo   - Media Service: http://localhost:8002
echo   - Data Service: http://localhost:8003
echo   - MinIO Console: http://localhost:9001
echo   - PostgreSQL: localhost:5432
echo   - Redis: localhost:6379
echo.

timeout /t 3 >nul

REM 显示服务状态
echo [信息] 服务状态:
if "%MODE%"=="dev" (
    docker-compose -f docker-compose.dev.yml ps
) else (
    docker-compose ps
)

endlocal
