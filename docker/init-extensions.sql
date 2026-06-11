-- 首次初始化数据库时安装扩展（须 superuser，应用 migrate 用户无 CREATE EXTENSION 权限）
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS vector;
