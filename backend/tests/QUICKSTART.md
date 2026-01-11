# 测试框架快速开始指南

## ✅ 已完成的测试框架搭建

1. ✅ pytest配置文件 (`pytest.ini`)
2. ✅ 测试目录结构
3. ✅ 测试fixtures (`conftest.py`)
4. ✅ 认证服务单元测试示例
5. ✅ 认证API集成测试示例
6. ✅ 测试依赖文件 (`requirements-test.txt`)

## 🚀 快速开始

### 1. 安装测试依赖

```bash
cd backend
pip install -r requirements-test.txt
```

或者使用测试脚本（会自动安装依赖）：

**Windows:**
```bash
cd backend
tests\run_tests.bat
```

**Linux/Mac:**
```bash
cd backend
chmod +x tests/run_tests.sh
./tests/run_tests.sh
```

### 2. 运行测试

```bash
# 运行所有测试
pytest

# 运行单元测试
pytest tests/unit/ -m unit

# 运行集成测试
pytest tests/integration/ -m integration

# 运行API测试
pytest tests/integration/api/ -m api

# 查看覆盖率
pytest --cov=services --cov=shared --cov-report=html
```

### 3. 测试目录结构

```
backend/tests/
├── __init__.py
├── conftest.py              # pytest配置和共享fixtures
├── unit/                    # 单元测试
│   └── services/
│       └── test_auth_service.py
└── integration/            # 集成测试
    └── api/
        └── test_auth_api.py
```

## 📝 编写新测试

### 单元测试示例

```python
import pytest
from services.agent_service.src.services.your_service import YourService

@pytest.mark.unit
class TestYourService:
    def test_something(self, db_session):
        service = YourService(db_session)
        # 测试逻辑
        result = service.do_something()
        assert result is not None
```

### 集成测试示例

```python
import pytest
from fastapi import status

@pytest.mark.integration
@pytest.mark.api
class TestYourAPI:
    def test_endpoint(self, client, auth_headers):
        response = client.get("/api/v1/your-endpoint", headers=auth_headers)
        assert response.status_code == status.HTTP_200_OK
```

## ⚠️ 注意事项

### 数据库兼容性

当前测试使用SQLite内存数据库。如果遇到UUID类型问题，可以：

1. **方案1（推荐）**: 使用PostgreSQL测试数据库
   - 修改 `conftest.py` 中的 `DATABASE_URL`
   - 使用Docker启动PostgreSQL测试实例

2. **方案2**: 使用测试专用模型
   - 已在 `tests/utils/test_db_models.py` 中创建SQLite兼容模型
   - 需要根据实际情况调整

### 环境变量

测试会自动设置以下环境变量：
- `TESTING=true`
- `SECRET_KEY=test-secret-key-for-testing-only`
- `DATABASE_URL=sqlite:///:memory:`

## 🎯 下一步

1. **补充更多测试用例**
   - 对话服务测试
   - 任务服务测试
   - 剧本服务测试
   - 媒体服务测试

2. **提高测试覆盖率**
   - 目标：> 80%
   - 当前：~20%（仅认证服务）

3. **添加端到端测试**
   - 完整业务流程测试
   - 跨服务集成测试

## 📚 参考文档

- [pytest文档](https://docs.pytest.org/)
- [FastAPI测试文档](https://fastapi.tiangolo.com/tutorial/testing/)
- [测试README](./README.md)
