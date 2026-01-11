# 测试问题排查指南

## 已知问题

### 1. metadata字段与SQLAlchemy保留字冲突

**问题描述**：
`Message`和`MediaFile`模型中的`metadata`字段与SQLAlchemy的保留字`metadata`冲突，导致无法定义模型。

**错误信息**：
```
sqlalchemy.exc.InvalidRequestError: Attribute name 'metadata' is reserved when using the Declarative API.
```

**解决方案**：

#### 方案1：修改字段名（推荐，但需要更新代码）

将`metadata`字段改为`meta_data`或`extra_data`，然后更新所有使用的地方：

1. 修改`shared/models/db_models.py`：
   ```python
   meta_data = Column("metadata", JSON)  # 数据库列名仍为metadata
   ```

2. 更新所有使用`.metadata`的地方改为`.meta_data`

3. 或者在模型中添加兼容属性：
   ```python
   @property
   def metadata(self):
       return self.meta_data
   
   @metadata.setter
   def metadata(self, value):
       self.meta_data = value
   ```

#### 方案2：使用PostgreSQL测试数据库（推荐用于集成测试）

使用真实的PostgreSQL数据库进行测试，避免SQLite的兼容性问题：

```python
# conftest.py
DATABASE_URL = "postgresql://user:password@localhost:5432/test_db"
```

#### 方案3：使用测试专用模型（临时方案）

创建测试专用的模型定义，使用不同的字段名。

## 当前状态

测试框架已搭建完成，但由于`metadata`字段冲突问题，部分测试暂时无法运行。

**可以运行的测试**：
- 认证服务单元测试（不依赖有问题的模型）
- 认证API集成测试（需要修复metadata问题后）

**待修复后才能运行的测试**：
- 消息服务测试
- 媒体服务测试
- 其他依赖Message或MediaFile模型的测试

## 下一步

1. 修复metadata字段冲突问题（使用方案1或方案2）
2. 运行测试验证修复
3. 补充其他服务的测试用例
