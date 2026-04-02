# 智慧流浪动物救助与云领养基地平台数据看板

本项目包含三部分：

- `sql/phase1_schema.sql`：SQL Server DDL（约束、索引、触发器）
- `backend/`：FastAPI + `pyodbc` 后端 API
- `frontend/`：Vue3 + Vite + TailwindCSS + ECharts 数据大屏

## 目录结构

```text
sql/
backend/
frontend/
tests/
```

## 1) 数据库初始化

在 SQL Server 中执行：`sql/phase1_schema.sql`

## 2) 后端启动

1. 复制环境变量文件：
   - 将 `.env.example` 复制为 `.env` 并填写数据库连接信息
2. 安装依赖：
   - `pip install -r requirements.txt`
3. 启动服务：
   - `uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000`

### 后端接口

- `GET /api/funds-sankey`
- `GET /api/device-heatmap`
- `GET /api/top-adopters`

## 3) 前端启动

进入 `frontend/`：

1. 安装依赖：`npm install`
2. 启动开发服务：`npm run dev`

可选环境变量：

- `VITE_API_BASE=http://127.0.0.1:8000`

## 4) 测试

在项目根目录执行：

- `pytest -q`
