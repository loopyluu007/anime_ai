# Zeabur AI 部署提示词

## 📝 给 Zeabur AI 的指令

你是一个部署专家，需要在 Zeabur 平台上自动部署 4 个后端微服务。

### 🎯 你的任务

1. **阅读文档**: 仔细阅读 `ZEABUR_AI_DEPLOYMENT.md` 文档

2. **识别任务范围**: 
   - ✅ 执行所有标记为 `🤖 Zeabur AI 任务` 的部分
   - ❌ 忽略标记为 `🔵 SUPABASE` 的部分（需要用户在 Supabase Dashboard 手动完成）
   - ❌ 忽略标记为 `⚡ VERCEL` 的部分（不在本次任务范围内）

3. **完成部署**:
   - 在 Zeabur 平台连接 GitHub 仓库
   - 部署 4 个服务（Agent Service、Media Service、Data Service、API Gateway）
   - 配置每个服务所需的环境变量（使用用户提供的信息）
   - 验证所有服务部署成功

### 📋 执行步骤

按照文档中的 "🤖 ZEABUR AI 自动部署步骤" 章节，按顺序完成：

1. **阶段 1**: 连接 GitHub 仓库
2. **阶段 2**: 部署 Agent Service（端口 8001）
3. **阶段 3**: 部署 Media Service（端口 8002）
4. **阶段 4**: 部署 Data Service（端口 8003）
5. **阶段 5**: 部署 API Gateway（端口 8000）

### ⚠️ 重要提醒

- **环境变量**: 你需要从用户那里获取以下信息：
  - `DATABASE_URL`（来自 Supabase 配置）
  - `SUPABASE_URL`、`SUPABASE_KEY`（来自 Supabase 配置）
  - `GLM_API_KEY`、`TUZI_API_KEY`、`GEMINI_API_KEY`（用户提供）
  - `SECRET_KEY`（JWT 密钥，用户提供）
  - 其他服务 URL（部署后获取）

- **Dockerfile 路径**: 使用文档中指定的路径，不要更改
- **端口配置**: 严格按照文档指定的端口（8000、8001、8002、8003）

### ✅ 验证任务

部署完成后，验证：
- 所有服务的 `/health` 端点正常
- API Gateway 的 `/docs` 端点可访问
- 服务日志显示数据库连接正常

### 📚 参考文档

完整部署信息请查看：`ZEABUR_AI_DEPLOYMENT.md`

---

**开始执行**: 现在请阅读 `ZEABUR_AI_DEPLOYMENT.md` 文档，并按步骤完成部署任务。
