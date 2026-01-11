# 测试文档

## 测试框架

本项目使用 `pytest` 作为测试框架，支持单元测试和集成测试。

## 安装测试依赖

```bash
pip install -r requirements-test.txt
```

或者安装所有依赖（包括测试依赖）：

```bash
pip install -r requirements.txt
pip install -r requirements-test.txt
```

## 运行测试

### 运行所有测试

```bash
pytest
```

### 运行单元测试

```bash
pytest tests/unit/ -m unit
```

### 运行集成测试

```bash
pytest tests/integration/ -m integration
```

### 运行API测试

```bash
pytest tests/integration/api/ -m api
```

### 运行特定测试文件

```bash
pytest tests/unit/services/test_auth_service.py
```

### 运行特定测试用例

```bash
pytest tests/unit/services/test_auth_service.py::TestAuthService::test_create_user_success
```

### 生成覆盖率报告

```bash
pytest --cov=services --cov=shared --cov-report=html
```

覆盖率报告会生成在 `htmlcov/index.html`

## 测试目录结构

```
tests/
├── __init__.py
├── conftest.py              # pytest配置和共享fixtures
├── unit/                    # 单元测试
│   └── services/            # 服务层单元测试
│       └── test_auth_service.py
└── integration/             # 集成测试
    └── api/                 # API集成测试
        └── test_auth_api.py
```

## 测试标记

使用pytest标记来分类测试：

- `@pytest.mark.unit` - 单元测试
- `@pytest.mark.integration` - 集成测试
- `@pytest.mark.api` - API测试
- `@pytest.mark.slow` - 慢速测试

## 测试Fixtures

### db_session

提供测试数据库会话，使用SQLite内存数据库。

```python
def test_example(db_session):
    # 使用db_session进行测试
    pass
```

### client

提供FastAPI测试客户端。

```python
def test_api(client):
    response = client.get("/api/v1/auth/me")
    assert response.status_code == 200
```

### test_user_data

提供测试用户数据字典。

```python
def test_example(test_user_data):
    username = test_user_data["username"]
    # ...
```

### test_user

创建并返回一个测试用户对象。

```python
def test_example(test_user):
    assert test_user.username == "testuser"
```

### auth_headers

提供已认证的请求头。

```python
def test_protected_endpoint(client, auth_headers):
    response = client.get("/api/v1/auth/me", headers=auth_headers)
    assert response.status_code == 200
```

## 编写测试

### 单元测试示例

```python
import pytest
from services.agent_service.src.services.auth_service import AuthService

@pytest.mark.unit
class TestAuthService:
    def test_create_user_success(self, db_session):
        service = AuthService(db_session)
        # 测试逻辑
        pass
```

### 集成测试示例

```python
import pytest
from fastapi import status

@pytest.mark.integration
@pytest.mark.api
class TestAuthAPI:
    def test_register_success(self, client):
        response = client.post("/api/v1/auth/register", json={...})
        assert response.status_code == status.HTTP_200_OK
```

## 测试覆盖率目标

- 当前目标：> 80%
- 检查覆盖率：`pytest --cov-report=term-missing`

## 注意事项

1. 测试使用SQLite内存数据库，不会影响开发/生产数据库
2. 每个测试函数都会获得一个全新的数据库会话
3. 测试结束后会自动清理数据库
4. 使用环境变量 `TESTING=true` 来区分测试和生产环境
