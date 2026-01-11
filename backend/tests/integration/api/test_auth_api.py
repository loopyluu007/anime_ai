"""认证API集成测试"""
import pytest
from fastapi import status


@pytest.mark.integration
@pytest.mark.api
class TestAuthAPI:
    """认证API测试类"""
    
    def test_register_success(self, client, test_user_data):
        """测试成功注册"""
        # 使用新的用户数据避免冲突
        user_data = {
            "username": "newuser123",
            "email": "newuser123@example.com",
            "password": "password123"
        }
        
        response = client.post("/api/v1/auth/register", json=user_data)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert "data" in data
        assert data["data"]["username"] == user_data["username"]
        assert data["data"]["email"] == user_data["email"]
        assert "id" in data["data"]
    
    def test_register_duplicate_email(self, client, test_user):
        """测试注册重复邮箱失败"""
        user_data = {
            "username": "anotheruser",
            "email": test_user.email,  # 使用已存在的邮箱
            "password": "password123"
        }
        
        response = client.post("/api/v1/auth/register", json=user_data)
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        data = response.json()
        assert data["code"] == 400
        assert "邮箱已被注册" in data["message"] or "email" in str(data).lower()
    
    def test_register_duplicate_username(self, client, test_user):
        """测试注册重复用户名失败"""
        user_data = {
            "username": test_user.username,  # 使用已存在的用户名
            "email": "another@example.com",
            "password": "password123"
        }
        
        response = client.post("/api/v1/auth/register", json=user_data)
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        data = response.json()
        assert data["code"] == 400
    
    def test_register_invalid_email(self, client):
        """测试注册无效邮箱失败"""
        user_data = {
            "username": "testuser",
            "email": "invalid-email",  # 无效邮箱格式
            "password": "password123"
        }
        
        response = client.post("/api/v1/auth/register", json=user_data)
        
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    def test_login_success(self, client, test_user_data):
        """测试成功登录"""
        # 先注册用户
        client.post("/api/v1/auth/register", json=test_user_data)
        
        # 然后登录
        response = client.post(
            "/api/v1/auth/login",
            data={
                "username": test_user_data["email"],
                "password": test_user_data["password"]
            }
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert "data" in data
        assert "access_token" in data["data"]
        assert "token_type" in data["data"]
        assert data["data"]["token_type"] == "bearer"
    
    def test_login_wrong_password(self, client, test_user_data):
        """测试错误密码登录失败"""
        # 先注册用户
        client.post("/api/v1/auth/register", json=test_user_data)
        
        # 使用错误密码登录
        response = client.post(
            "/api/v1/auth/login",
            data={
                "username": test_user_data["email"],
                "password": "wrongpassword"
            }
        )
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        data = response.json()
        assert data["code"] == 401
    
    def test_login_nonexistent_user(self, client):
        """测试不存在的用户登录失败"""
        response = client.post(
            "/api/v1/auth/login",
            data={
                "username": "nonexistent@example.com",
                "password": "password123"
            }
        )
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        data = response.json()
        assert data["code"] == 401
    
    def test_get_current_user(self, client, auth_headers):
        """测试获取当前用户信息"""
        response = client.get(
            "/api/v1/auth/me",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert "data" in data
        assert "id" in data["data"]
        assert "username" in data["data"]
        assert "email" in data["data"]
    
    def test_get_current_user_invalid_token(self, client):
        """测试使用无效token获取用户信息失败"""
        headers = {"Authorization": "Bearer invalid-token"}
        
        response = client.get(
            "/api/v1/auth/me",
            headers=headers
        )
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_get_current_user_no_token(self, client):
        """测试无token获取用户信息失败"""
        response = client.get("/api/v1/auth/me")
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
