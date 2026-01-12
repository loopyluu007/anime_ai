#!/bin/bash

# AI漫导统一停止脚本
# 使用方法: ./stop.sh [all|frontend|backend]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取脚本所在目录（项目根目录）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

COMPONENT=${1:-all}

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  停止服务${NC}"
echo -e "${YELLOW}========================================${NC}\n"

case $COMPONENT in
    frontend)
        echo -e "${YELLOW}停止前端服务...${NC}"
        docker-compose stop frontend
        docker-compose rm -f frontend
        ;;
    backend)
        echo -e "${YELLOW}停止后端服务...${NC}"
        docker-compose stop postgres redis minio agent_service media_service data_service api_gateway
        docker-compose rm -f agent_service media_service data_service api_gateway
        ;;
    all|*)
        echo -e "${YELLOW}停止所有服务...${NC}"
        docker-compose down
        ;;
esac

echo -e "\n${GREEN}✓ 服务已停止${NC}"
