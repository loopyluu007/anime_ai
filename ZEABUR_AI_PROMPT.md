# Zeabur AI 部署提示词

## 📝 给 Zeabur AI 的指令

你是一个部署专家，需要在 Zeabur 平台上自动部署 4 个后端微服务。

### 🎯 你的任务

1. **阅读文档**: 仔细阅读 `DEPLOYMENT_GUIDE.md` 文档

2. **完成部署**:
   - 在 Zeabur 平台连接 GitHub 仓库
   - 部署 4 个服务（Agent Service、Media Service、Data Service、API Gateway）
   - 配置每个服务所需的环境变量（使用用户提供的信息）
   - 验证所有服务部署成功

### 📋 执行步骤

按照 `DEPLOYMENT_GUIDE.md` 中的 "Zeabur 后端部署" 章节，按顺序完成：

1. **连接 GitHub 仓库**
2. **部署 Agent Service**（端口 8001）
3. **部署 Media Service**（端口 8002）
4. **部署 Data Service**（端口 8003）
5. **部署 API Gateway**（端口 8000）

### ⚠️ 重要提醒

- **环境变量**: 使用文档中的环境变量清单配置每个服务
- **Dockerfile 路径**: 使用文档中指定的路径（见"环境变量配置"章节）
- **端口配置**: 严格按照文档指定的端口（8000、8001、8002、8003）
- **部署顺序**: 必须先部署 Agent、Media、Data 服务，获取 URL 后再部署 API Gateway

### ✅ 验证任务

部署完成后，验证：
- 所有服务的 `/health` 端点正常
- API Gateway 的 `/docs` 端点可访问
- 服务日志显示数据库连接正常

### 📚 参考文档

完整部署信息请查看：`DEPLOYMENT_GUIDE.md`

---

**开始执行**: 现在请阅读 `DEPLOYMENT_GUIDE.md` 文档，按照"Zeabur 后端部署"章节完成部署任务。
