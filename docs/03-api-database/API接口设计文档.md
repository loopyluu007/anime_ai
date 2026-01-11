# API 接口设计文档

> **版本**: v1.0  
> **基础路径**: `https://api.directorai.com/api/v1`  
> **协议**: HTTPS  
> **格式**: JSON

---

## 📋 目录

1. [通用说明](#通用说明)
2. [认证授权](#认证授权)
3. [对话管理](#对话管理)
4. [任务管理](#任务管理)
5. [剧本管理](#剧本管理)
6. [媒体服务](#媒体服务)
7. [WebSocket 实时通信](#websocket-实时通信)

---

## 🔧 通用说明

### 请求头

```http
Content-Type: application/json
Authorization: Bearer {token}
X-Request-ID: {uuid}  # 可选，用于追踪请求
```

### 响应格式

**成功响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "timestamp": "2025-01-XX 12:00:00"
}
```

**错误响应**:
```json
{
  "code": 400,
  "message": "参数错误",
  "error": {
    "field": "prompt",
    "reason": "不能为空"
  },
  "timestamp": "2025-01-XX 12:00:00"
}
```

### 状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未授权（Token 无效或过期） |
| 403 | 无权限 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

### 分页参数

```json
{
  "page": 1,        // 页码，从 1 开始
  "pageSize": 20,   // 每页数量
  "total": 100,     // 总数量
  "items": []       // 数据列表
}
```

---

## 🔐 认证授权

### 1. 用户注册

**接口**: `POST /auth/register`

**请求体**:
```json
{
  "username": "user123",
  "email": "user@example.com",
  "password": "password123"
}
```

**响应**:
```json
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "userId": "uuid",
    "token": "jwt_token",
    "refreshToken": "refresh_token"
  }
}
```

### 2. 用户登录

**接口**: `POST /auth/login`

**请求体**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**响应**:
```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "userId": "uuid",
    "token": "jwt_token",
    "refreshToken": "refresh_token",
    "expiresIn": 3600
  }
}
```

### 3. 刷新 Token

**接口**: `POST /auth/refresh`

**请求体**:
```json
{
  "refreshToken": "refresh_token"
}
```

**响应**: 同登录接口

### 4. 获取用户信息

**接口**: `GET /auth/me`

**响应**:
```json
{
  "code": 200,
  "data": {
    "id": "uuid",
    "username": "user123",
    "email": "user@example.com",
    "avatar": "https://...",
    "createdAt": "2025-01-XX 12:00:00"
  }
}
```

---

## 💬 对话管理

### 1. 创建对话

**接口**: `POST /conversations`

**请求体**:
```json
{
  "title": "新对话"
}
```

**响应**:
```json
{
  "code": 200,
  "data": {
    "id": "conversation_id",
    "title": "新对话",
    "messageCount": 0,
    "isPinned": false,
    "createdAt": "2025-01-XX 12:00:00"
  }
}
```

### 2. 获取对话列表

**接口**: `GET /conversations`

**查询参数**:
- `page`: 页码（默认 1）
- `pageSize`: 每页数量（默认 20）
- `pinned`: 是否只获取置顶（可选）

**响应**:
```json
{
  "code": 200,
  "data": {
    "page": 1,
    "pageSize": 20,
    "total": 50,
    "items": [
      {
        "id": "conversation_id",
        "title": "对话标题",
        "previewText": "最后一条消息预览...",
        "messageCount": 10,
        "isPinned": true,
        "lastAccessedAt": "2025-01-XX 12:00:00",
        "createdAt": "2025-01-XX 10:00:00"
      }
    ]
  }
}
```

### 3. 获取对话详情

**接口**: `GET /conversations/{id}`

**响应**:
```json
{
  "code": 200,
  "data": {
    "id": "conversation_id",
    "title": "对话标题",
    "messageCount": 10,
    "isPinned": false,
    "createdAt": "2025-01-XX 10:00:00",
    "updatedAt": "2025-01-XX 12:00:00"
  }
}
```

### 4. 更新对话

**接口**: `PUT /conversations/{id}`

**请求体**:
```json
{
  "title": "新标题",
  "isPinned": true
}
```

### 5. 删除对话

**接口**: `DELETE /conversations/{id}`

### 6. 获取消息列表

**接口**: `GET /conversations/{id}/messages`

**查询参数**:
- `page`: 页码
- `pageSize`: 每页数量
- `before`: 获取指定时间之前的消息（可选）

**响应**:
```json
{
  "code": 200,
  "data": {
    "page": 1,
    "pageSize": 50,
    "total": 100,
    "items": [
      {
        "id": "message_id",
        "role": "user",
        "content": "用户消息内容",
        "type": "text",
        "createdAt": "2025-01-XX 12:00:00"
      },
      {
        "id": "message_id",
        "role": "assistant",
        "content": "AI 回复内容（Markdown）",
        "type": "screenplay",
        "metadata": {
          "screenplayId": "screenplay_id"
        },
        "createdAt": "2025-01-XX 12:01:00"
      }
    ]
  }
}
```

---

## 📋 任务管理

### 1. 创建任务

**接口**: `POST /tasks`

**请求体**:
```json
{
  "type": "screenplay",
  "conversationId": "conversation_id",
  "params": {
    "prompt": "生成一个雪地里的冒险故事",
    "userImages": ["base64_image1", "base64_image2"],
    "sceneCount": 7,
    "characterCount": 2
  }
}
```

**响应**:
```json
{
  "code": 200,
  "data": {
    "id": "task_id",
    "type": "screenplay",
    "status": "pending",
    "progress": 0,
    "createdAt": "2025-01-XX 12:00:00"
  }
}
```

### 2. 获取任务列表

**接口**: `GET /tasks`

**查询参数**:
- `page`: 页码
- `pageSize`: 每页数量
- `type`: 任务类型（可选）
- `status`: 任务状态（可选）

**响应**:
```json
{
  "code": 200,
  "data": {
    "page": 1,
    "pageSize": 20,
    "total": 50,
    "items": [
      {
        "id": "task_id",
        "type": "screenplay",
        "status": "completed",
        "progress": 100,
        "createdAt": "2025-01-XX 12:00:00"
      }
    ]
  }
}
```

### 3. 获取任务详情

**接口**: `GET /tasks/{id}`

**响应**:
```json
{
  "code": 200,
  "data": {
    "id": "task_id",
    "type": "screenplay",
    "status": "processing",
    "progress": 50,
    "result": {
      "screenplayId": "screenplay_id"
    },
    "createdAt": "2025-01-XX 12:00:00",
    "updatedAt": "2025-01-XX 12:05:00"
  }
}
```

### 4. 获取任务进度

**接口**: `GET /tasks/{id}/progress`

**响应**:
```json
{
  "code": 200,
  "data": {
    "status": "processing",
    "progress": 50,
    "currentStep": "生成场景图片",
    "details": {
      "completedScenes": 3,
      "totalScenes": 7,
      "currentScene": 4
    }
  }
}
```

### 5. 取消任务

**接口**: `POST /tasks/{id}/cancel`

### 6. 删除任务

**接口**: `DELETE /tasks/{id}`

---

## 📝 剧本管理

### 1. 生成剧本草稿

**接口**: `POST /screenplays/draft`

**请求体**:
```json
{
  "taskId": "task_id",
  "prompt": "生成一个雪地里的冒险故事",
  "userImages": ["base64_image1"],
  "sceneCount": 7,
  "characterCount": 2
}
```

**响应**:
```json
{
  "code": 200,
  "data": {
    "id": "screenplay_id",
    "taskId": "task_id",
    "title": "雪地冒险",
    "status": "draft",
    "scenes": [
      {
        "sceneId": 1,
        "narration": "在一个寒冷的冬日...",
        "imagePrompt": "A snowy landscape...",
        "videoPrompt": "The snow is falling...",
        "status": "pending"
      }
    ],
    "characterSheets": [
      {
        "id": "character_id",
        "name": "主角",
        "description": "一个勇敢的冒险者",
        "combinedViewUrl": "https://..."
      }
    ]
  }
}
```

### 2. 确认剧本

**接口**: `POST /screenplays/{id}/confirm`

**请求体**:
```json
{
  "feedback": "请增加一些动作场景"  // 可选
}
```

**响应**:
```json
{
  "code": 200,
  "data": {
    "id": "screenplay_id",
    "status": "generating",
    "taskId": "task_id"
  }
}
```

### 3. 获取剧本详情

**接口**: `GET /screenplays/{id}`

**响应**:
```json
{
  "code": 200,
  "data": {
    "id": "screenplay_id",
    "title": "雪地冒险",
    "status": "completed",
    "scenes": [
      {
        "sceneId": 1,
        "narration": "在一个寒冷的冬日...",
        "imagePrompt": "A snowy landscape...",
        "videoPrompt": "The snow is falling...",
        "imageUrl": "https://...",
        "videoUrl": "https://...",
        "status": "completed"
      }
    ],
    "characterSheets": [],
    "createdAt": "2025-01-XX 12:00:00",
    "updatedAt": "2025-01-XX 12:30:00"
  }
}
```

### 4. 更新剧本

**接口**: `PUT /screenplays/{id}`

**请求体**:
```json
{
  "title": "新标题"
}
```

---

## 🎨 媒体服务

### 1. 上传图片

**接口**: `POST /media/images/upload`

**请求格式**: `multipart/form-data`

**参数**:
- `file`: 图片文件
- `type`: 图片类型（`reference` | `character`）

**响应**:
```json
{
  "code": 200,
  "data": {
    "id": "image_id",
    "url": "https://...",
    "size": 1024000,
    "width": 1920,
    "height": 1080
  }
}
```

### 2. 生成图片（异步）

**接口**: `POST /media/images/generate`

**请求体**:
```json
{
  "prompt": "A beautiful landscape",
  "model": "gemini-3-pro-image-preview-hd",
  "size": "1024x1024",
  "referenceImages": ["image_id1", "image_id2"]
}
```

**响应**:
```json
{
  "code": 200,
  "data": {
    "taskId": "task_id",
    "status": "pending"
  }
}
```

### 3. 获取生成的图片

**接口**: `GET /media/images/{id}`

**响应**:
```json
{
  "code": 200,
  "data": {
    "id": "image_id",
    "url": "https://...",
    "status": "completed",
    "createdAt": "2025-01-XX 12:00:00"
  }
}
```

### 4. 生成视频（异步）

**接口**: `POST /media/videos/generate`

**请求体**:
```json
{
  "imageId": "image_id",
  "prompt": "The scene is animated...",
  "model": "sora-1",
  "seconds": "10",
  "referenceImages": ["image_id1", "image_id2"]
}
```

**响应**:
```json
{
  "code": 200,
  "data": {
    "taskId": "task_id",
    "status": "pending"
  }
}
```

### 5. 获取生成的视频

**接口**: `GET /media/videos/{id}`

**响应**:
```json
{
  "code": 200,
  "data": {
    "id": "video_id",
    "url": "https://...",
    "status": "completed",
    "duration": 10,
    "size": 5242880,
    "createdAt": "2025-01-XX 12:00:00"
  }
}
```

---

## 🔌 WebSocket 实时通信

### 连接

**URL**: `wss://api.directorai.com/ws`

**连接参数**:
```
?token={jwt_token}
```

### 消息格式

**客户端 → 服务端**:
```json
{
  "type": "subscribe",
  "channel": "task.progress",
  "taskId": "task_id"
}
```

**服务端 → 客户端**:
```json
{
  "type": "task.progress",
  "taskId": "task_id",
  "data": {
    "status": "processing",
    "progress": 50,
    "currentStep": "生成场景图片"
  }
}
```

### 事件类型

#### 1. 任务进度更新

```json
{
  "type": "task.progress",
  "taskId": "task_id",
  "data": {
    "status": "processing",
    "progress": 50,
    "currentStep": "生成场景图片",
    "details": {
      "completedScenes": 3,
      "totalScenes": 7
    }
  }
}
```

#### 2. 任务完成

```json
{
  "type": "task.completed",
  "taskId": "task_id",
  "data": {
    "result": {
      "screenplayId": "screenplay_id"
    }
  }
}
```

#### 3. 任务失败

```json
{
  "type": "task.failed",
  "taskId": "task_id",
  "data": {
    "error": "生成失败",
    "reason": "API 调用超时"
  }
}
```

#### 4. 新消息通知

```json
{
  "type": "message.new",
  "conversationId": "conversation_id",
  "data": {
    "messageId": "message_id",
    "content": "消息内容"
  }
}
```

### 心跳

客户端每 30 秒发送一次心跳:
```json
{
  "type": "ping"
}
```

服务端响应:
```json
{
  "type": "pong"
}
```

---

## 📊 错误码定义

| 错误码 | 说明 |
|--------|------|
| 1000 | 参数错误 |
| 1001 | 缺少必需参数 |
| 1002 | 参数格式错误 |
| 2000 | 认证失败 |
| 2001 | Token 无效 |
| 2002 | Token 过期 |
| 2003 | 无权限 |
| 3000 | 资源不存在 |
| 3001 | 对话不存在 |
| 3002 | 任务不存在 |
| 4000 | 业务错误 |
| 4001 | 任务已取消 |
| 4002 | 任务处理中，无法取消 |
| 5000 | 服务器错误 |
| 5001 | 第三方 API 调用失败 |
| 5002 | 文件上传失败 |

---

## 🔒 安全说明

1. **HTTPS**: 所有接口必须使用 HTTPS
2. **Token 过期**: Access Token 有效期 1 小时，Refresh Token 有效期 7 天
3. **限流**: 每个用户每分钟最多 60 次请求
4. **文件大小**: 单文件最大 50MB
5. **CORS**: 仅允许指定域名访问

---

**文档版本**: v1.0  
**最后更新**: 2026-01-12
