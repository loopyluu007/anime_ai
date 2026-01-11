"""
WebSocket 实时通信模块
用于实时推送任务进度、消息通知等
"""
from fastapi import WebSocket, WebSocketDisconnect, status
from typing import Dict, Set, Optional
import json
from uuid import UUID
import os
from jose import JWTError, jwt

import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from shared.utils.exceptions import AuthenticationError

# JWT配置（与auth.py保持一致）
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"


class ConnectionManager:
    """WebSocket 连接管理器"""
    
    def __init__(self):
        # 存储每个用户的连接：user_id -> Set[WebSocket]
        self.active_connections: Dict[UUID, Set[WebSocket]] = {}
        # 存储每个连接的订阅：websocket -> Set[task_id]
        self.connection_subscriptions: Dict[WebSocket, Set[UUID]] = {}
        # 存储用户ID映射：websocket -> user_id
        self.connection_users: Dict[WebSocket, UUID] = {}
    
    async def connect(self, websocket: WebSocket, user_id: UUID):
        """连接 WebSocket"""
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = set()
        self.active_connections[user_id].add(websocket)
        self.connection_subscriptions[websocket] = set()
        self.connection_users[websocket] = user_id
    
    def disconnect(self, websocket: WebSocket):
        """断开 WebSocket"""
        user_id = self.connection_users.get(websocket)
        if user_id and user_id in self.active_connections:
            self.active_connections[user_id].discard(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        
        # 清理订阅信息
        if websocket in self.connection_subscriptions:
            del self.connection_subscriptions[websocket]
        if websocket in self.connection_users:
            del self.connection_users[websocket]
    
    def subscribe_task(self, websocket: WebSocket, task_id: UUID):
        """订阅任务进度"""
        if websocket in self.connection_subscriptions:
            self.connection_subscriptions[websocket].add(task_id)
    
    def unsubscribe_task(self, websocket: WebSocket, task_id: UUID):
        """取消订阅任务进度"""
        if websocket in self.connection_subscriptions:
            self.connection_subscriptions[websocket].discard(task_id)
    
    async def send_personal_message(self, message: dict, user_id: UUID):
        """发送个人消息给指定用户的所有连接"""
        if user_id not in self.active_connections:
            return
        
        disconnected = set()
        for connection in self.active_connections[user_id]:
            try:
                await connection.send_json(message)
            except Exception:
                disconnected.add(connection)
        
        # 清理断开的连接
        for conn in disconnected:
            self.disconnect(conn)
    
    async def send_task_message(self, message: dict, task_id: UUID):
        """发送任务消息给订阅了该任务的所有连接"""
        sent_count = 0
        disconnected = set()
        
        for websocket, subscriptions in self.connection_subscriptions.items():
            if task_id in subscriptions:
                try:
                    await websocket.send_json(message)
                    sent_count += 1
                except Exception:
                    disconnected.add(websocket)
        
        # 清理断开的连接
        for conn in disconnected:
            self.disconnect(conn)
        
        return sent_count
    
    async def broadcast(self, message: dict):
        """广播消息给所有连接"""
        disconnected = set()
        for user_id, connections in self.active_connections.items():
            for connection in connections:
                try:
                    await connection.send_json(message)
                except Exception:
                    disconnected.add(connection)
        
        # 清理断开的连接
        for conn in disconnected:
            self.disconnect(conn)


# 全局连接管理器实例
manager = ConnectionManager()


def verify_websocket_token(token: str) -> UUID:
    """验证WebSocket连接的JWT token"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise AuthenticationError("Token 无效")
        return UUID(user_id)
    except (JWTError, ValueError) as e:
        raise AuthenticationError(f"Token 验证失败: {str(e)}")


async def websocket_endpoint(websocket: WebSocket, token: Optional[str] = None):
    """WebSocket 端点"""
    # 从查询参数获取token
    if token is None:
        query_params = dict(websocket.query_params)
        token = query_params.get("token")
    
    if not token:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="缺少token参数")
        return
    
    try:
        # 验证token并获取用户ID
        user_id = verify_websocket_token(token)
    except AuthenticationError as e:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason=str(e))
        return
    
    # 连接WebSocket
    await manager.connect(websocket, user_id)
    
    try:
        # 发送连接成功消息
        await websocket.send_json({
            "type": "connected",
            "message": "WebSocket连接成功"
        })
        
        # 消息循环
        while True:
            try:
                # 接收消息
                data = await websocket.receive_text()
                message = json.loads(data)
                message_type = message.get("type")
                
                # 处理心跳
                if message_type == "ping":
                    await websocket.send_json({"type": "pong"})
                
                # 处理订阅
                elif message_type == "subscribe":
                    channel = message.get("channel")
                    task_id_str = message.get("taskId")
                    
                    if channel == "task.progress" and task_id_str:
                        try:
                            task_id = UUID(task_id_str)
                            manager.subscribe_task(websocket, task_id)
                            await websocket.send_json({
                                "type": "subscribed",
                                "channel": channel,
                                "taskId": task_id_str
                            })
                        except ValueError:
                            await websocket.send_json({
                                "type": "error",
                                "message": "无效的taskId格式"
                            })
                    else:
                        await websocket.send_json({
                            "type": "error",
                            "message": "无效的订阅请求"
                        })
                
                # 处理取消订阅
                elif message_type == "unsubscribe":
                    channel = message.get("channel")
                    task_id_str = message.get("taskId")
                    
                    if channel == "task.progress" and task_id_str:
                        try:
                            task_id = UUID(task_id_str)
                            manager.unsubscribe_task(websocket, task_id)
                            await websocket.send_json({
                                "type": "unsubscribed",
                                "channel": channel,
                                "taskId": task_id_str
                            })
                        except ValueError:
                            await websocket.send_json({
                                "type": "error",
                                "message": "无效的taskId格式"
                            })
                    else:
                        await websocket.send_json({
                            "type": "error",
                            "message": "无效的取消订阅请求"
                        })
                
                # 未知消息类型
                else:
                    await websocket.send_json({
                        "type": "error",
                        "message": f"未知的消息类型: {message_type}"
                    })
            
            except json.JSONDecodeError:
                await websocket.send_json({
                    "type": "error",
                    "message": "无效的JSON格式"
                })
            
            except Exception as e:
                await websocket.send_json({
                    "type": "error",
                    "message": f"处理消息时出错: {str(e)}"
                })
    
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception as e:
        # 处理其他异常
        manager.disconnect(websocket)
        raise


# 推送函数，供其他模块调用

async def send_task_progress(
    user_id: UUID,
    task_id: UUID,
    status: str,
    progress: int,
    current_step: Optional[str] = None,
    details: Optional[dict] = None
):
    """发送任务进度更新"""
    message = {
        "type": "task.progress",
        "taskId": str(task_id),
        "data": {
            "status": status,
            "progress": progress,
            "currentStep": current_step,
            "details": details or {}
        }
    }
    # 发送给订阅了该任务的所有连接
    await manager.send_task_message(message, task_id)
    # 也发送给用户的所有连接（作为备用）
    await manager.send_personal_message(message, user_id)


async def send_task_completed(user_id: UUID, task_id: UUID, result: Optional[dict] = None):
    """发送任务完成通知"""
    message = {
        "type": "task.completed",
        "taskId": str(task_id),
        "data": {
            "result": result or {}
        }
    }
    await manager.send_task_message(message, task_id)
    await manager.send_personal_message(message, user_id)


async def send_task_failed(user_id: UUID, task_id: UUID, error: str, reason: Optional[str] = None):
    """发送任务失败通知"""
    message = {
        "type": "task.failed",
        "taskId": str(task_id),
        "data": {
            "error": error,
            "reason": reason
        }
    }
    await manager.send_task_message(message, task_id)
    await manager.send_personal_message(message, user_id)


async def send_message_notification(user_id: UUID, conversation_id: UUID, message_id: UUID, content: str):
    """发送新消息通知"""
    message = {
        "type": "message.new",
        "conversationId": str(conversation_id),
        "data": {
            "messageId": str(message_id),
            "content": content
        }
    }
    await manager.send_personal_message(message, user_id)
