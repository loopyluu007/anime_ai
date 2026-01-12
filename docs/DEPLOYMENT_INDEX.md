# 部署文档索引

> **最后更新**: 2026-01-16

---

## 📚 部署文档导航

### 🚀 主要部署指南

#### [完整部署指南](../DEPLOYMENT_GUIDE.md) ⭐ **推荐**

**适用场景**: 云平台部署（Supabase + Zeabur + Vercel）

**包含内容**:
- ✅ 完整架构方案
- ✅ Supabase 配置步骤
- ✅ Zeabur 后端部署
- ✅ Vercel 前端部署
- ✅ 环境变量配置
- ✅ 验证和测试
- ✅ 故障排查

**推荐**: 首次部署或云平台部署时使用

---

#### [本地部署指南](../DEPLOYMENT.md)

**适用场景**: 本地开发或私有服务器部署

**包含内容**:
- ✅ Docker Compose 部署
- ✅ 本地服务配置
- ✅ 开发环境搭建

**推荐**: 本地开发或测试时使用

---

### 📖 详细配置文档

#### [Supabase 集成指南](../SUPABASE_SETUP.md)

**内容**: Supabase 详细配置和集成说明

**包含**:
- Supabase 项目创建
- 数据库配置
- Storage 配置
- 权限设置
- 常见问题

**推荐**: 需要深入了解 Supabase 配置时查看

---

#### [Zeabur 部署指南](../ZEABUR_DEPLOYMENT.md)

**内容**: Zeabur 平台详细部署说明

**包含**:
- Zeabur 服务配置
- Dockerfile 说明
- 环境变量配置
- 服务间通信

**推荐**: 需要深入了解 Zeabur 部署时查看

---

## 🗂️ 文档结构

```
项目根目录/
├── DEPLOYMENT_GUIDE.md          # ⭐ 完整部署指南（推荐）
├── DEPLOYMENT.md                # 本地部署指南
├── SUPABASE_SETUP.md            # Supabase 详细配置
├── ZEABUR_DEPLOYMENT.md         # Zeabur 详细配置
└── docs/
    └── DEPLOYMENT_INDEX.md      # 本文档（部署文档索引）
```

---

## 🎯 快速选择指南

### 场景 1: 首次云平台部署

👉 **查看**: [完整部署指南](../DEPLOYMENT_GUIDE.md)

### 场景 2: 本地开发测试

👉 **查看**: [本地部署指南](../DEPLOYMENT.md)

### 场景 3: 只配置 Supabase

👉 **查看**: [Supabase 集成指南](../SUPABASE_SETUP.md)

### 场景 4: 只部署到 Zeabur

👉 **查看**: [Zeabur 部署指南](../ZEABUR_DEPLOYMENT.md)

---

## 📝 文档更新记录

| 日期 | 版本 | 更新内容 |
|------|------|----------|
| 2026-01-16 | v2.0 | 创建完整部署指南，整合 Supabase + Zeabur + Vercel |
| 2026-01-16 | v1.0 | 初始文档创建 |

---

## 🔗 相关资源

- [项目 README](../README.md)
- [快速开始指南](../QUICKSTART.md)
- [后端开发文档](../backend/DEVELOPMENT.md)
- [前端开发文档](../frontend/DEVELOPMENT.md)

---

**维护者**: 开发团队
