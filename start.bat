@echo off
REM AI漫导统一部署脚本 (Windows)
REM 使用方法: start.bat [dev|prod] [frontend|backend|all]

setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

set MODE=%1
if "%MODE%"=="" set MODE=prod

set COMPONENT=%2
if "%COMPONENT%"=="" set COMPONENT=all

echo ========================================
echo   AI漫导统一部署
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
    docker compose version >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo [错误] 未找到 docker-compose，请先安装 docker-compose
        exit /b 1
    )
)

REM 检查 Docker 是否运行
docker info >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] Docker 未运行，请启动 Docker
    exit /b 1
)

echo [信息] 环境检查通过
echo.

REM 检查 .env 文件
if not exist ".env" (
    echo [警告] 未找到 .env 文件
    if exist ".env.example" (
        echo [信息] 正在从 .env.example 创建 .env 文件...
        copy ".env.example" ".env" >nul
        echo [成功] 已创建 .env 文件，请编辑配置后重新运行
        echo [提示] 请至少配置以下环境变量:
        echo   - GLM_API_KEY
        echo   - TUZI_API_KEY
        echo   - GEMINI_API_KEY
        echo   - SECRET_KEY
        exit /b 1
    ) else (
        echo [提示] 创建 .env 文件并配置必要的环境变量
    )
)

REM 启动服务
if "%MODE%"=="dev" (
    echo [信息] 模式: 开发环境
    echo [注意] 开发环境只启动基础设施（数据库、Redis、MinIO）
    echo [注意] 服务需要本地运行
    echo.
    docker-compose up -d postgres redis minio
) else if "%MODE%"=="prod" (
    echo [信息] 模式: 生产环境
    echo.
    
    if "%COMPONENT%"=="frontend" (
        echo [信息] 启动前端服务...
        docker-compose up -d frontend
    ) else if "%COMPONENT%"=="backend" (
        echo [信息] 启动后端服务...
        docker-compose up -d postgres redis minio agent_service media_service data_service api_gateway
    ) else (
        echo [信息] 启动所有服务...
        docker-compose up -d
    )
) else (
    echo [错误] 无效的模式 '%MODE%'
    echo 使用方法: start.bat [dev|prod] [frontend|backend|all]
    exit /b 1
)

if %ERRORLEVEL% NEQ 0 (
    echo [错误] 服务启动失败
    exit /b 1
)

echo.
echo [成功] 服务启动完成
echo.

timeout /t 3 >nul

REM 显示服务状态
echo ========================================
echo   服务状态
echo ========================================
echo.
docker-compose ps

echo.
echo ========================================
echo   服务地址
echo ========================================
echo.

if "%MODE%"=="dev" (
    echo [基础设施服务]
    echo   - PostgreSQL: localhost:5432
    echo   - Redis: localhost:6379
    echo   - MinIO: http://localhost:9000
    echo   - MinIO Console: http://localhost:9001
) else (
    echo [前端服务]
    echo   - Frontend: http://localhost:8080
    echo.
    echo [后端服务]
    echo   - API Gateway: http://localhost:8000
    echo   - Agent Service: http://localhost:8001
    echo   - Media Service: http://localhost:8002
    echo   - Data Service: http://localhost:8003
    echo.
    echo [基础设施服务]
    echo   - PostgreSQL: localhost:5432
    echo   - Redis: localhost:6379
    echo   - MinIO: http://localhost:9000
    echo   - MinIO Console: http://localhost:9001
)

echo.
echo [成功] 部署完成！
echo [提示] 使用 'stop.bat' 停止服务
echo [提示] 使用 'docker-compose logs -f [service_name]' 查看日志
echo.

endlocal
