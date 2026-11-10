# PostgreSQL 关系型数据库与 SQL 实践

## 目录

- [为什么后端离不开数据库](#为什么后端离不开数据库)
- [关系模型速览](#关系模型速览)
- [安装 PostgreSQL 并连接](#安装-postgresql-并连接)
- [建库与建表](#建库与建表)
- [增删改查（CRUD）](#增删改查crud)
- [条件查询](#条件查询)
- [聚合与分组](#聚合与分组)
- [多表连接](#多表连接)
- [事务与并发](#事务与并发)
- [用 Python 连接 PostgreSQL](#用-python-连接-postgresql)
- [SQLAlchemy 入门](#sqlalchemy-入门)
- [实战：学生成绩管理系统](#实战学生成绩管理系统)
- [常见坑与最佳实践](#常见坑与最佳实践)
- [课后练习](#课后练习)
- [参考资料](#参考资料)

---

## 为什么后端离不开数据库

### 存储方式从变量到文件再到数据库

我们在写程序时，数据的存放方式决定了它能活多久：

对于进程内内存，里面的数据在程序退出时就没了

```python
students = {"张三": 92, "李四": 85}  
```

对于文件，虽然能让数据持久化，但几乎很难进行查询

```python
with open("scores.csv", "w", encoding="utf-8") as f:
    f.write("name,score\n张三,92\n")
```

而通过数据库就可以实现‘持久化 + 结构化查询 + 并发安全 + 事务 + 权限’的“一条龙服务”，
并且可以解决文件系统存储数据时存在的数据冗余、不一致、共享性差、独立性差等问题

```python
cur.execute("SELECT name FROM students WHERE score > 90")
```

---

## 安装 PostgreSQL 并连接

两种安装方式，自选一种就行

#### 方式一：Docker Compose

配套文件 `docker-compose.yml`：

```yaml
services:
  db:
    image: postgres:18
    container_name: postgresql18
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: "123456"
      POSTGRES_DB: mydb
      TZ: Asia/Shanghai
      PGTZ: Asia/Shanghai
    ports:
      - "5432:5432"
    volumes:
      # PostgreSQL 18 起挂载父目录 
      - pgdata:/var/lib/postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U course -d lanshan_course"]
      interval: 5s
      timeout: 3s
      retries: 10

volumes:
  pgdata:
```

```bash
docker compose up -d            # 启动
docker compose ps               # 查看状态
docker exec -it mydb psql -U course -d lanshan_course   # 进库
docker compose down             # 停止（数据保留在 pgdata 卷里）
```

#### 方式二：官方安装包

- **Windows**：下载 EDB 安装包（[https://www.postgresql.org/download/windows/](https://www.postgresql.org/download/windows/)），一路下一步，**记住安装时设置的 `postgres` 超级用户密码**，安装时会自带 pgAdmin 和 `psql`。
  安装完若在终端敲 `psql` 提示找不到命令，把 `C:\Program Files\PostgreSQL\18\bin` 加进系统 `PATH`。
- **macOS**：`brew install postgresql@18 && brew services start postgresql@18`。
- **Linux**

```bash
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh   # 添加官方源
sudo apt update && sudo apt install -y postgresql-18
sudo systemctl enable --now postgresql
```

> 注：直接用发行版自带的 `apt install postgresql` 通常装到的是该发行版冻结的旧主版本，不会有新特性。

### psql 架构

```
PostgreSQL 服务器实例（一个 5432 端口上的进程）
├── 角色 / 用户  role:  postgres（超级用户）、course（我们建的）
└── 数据库       database: lanshan_course、postgres、template1
    └── 模式     schema: public（默认）、其它自定义模式
        └── 表   table: classes、students、courses、scores
```

- **角色（role）** 负责"谁能连、能干什么"，登录用的角色就叫用户。
- **数据库** 是隔离边界，跨数据库不能直接 JOIN。
- **模式（schema）** 是数据库内部的命名空间，用来分组表。默认都在 `public` 下。

创建专属用户和数据库（用超级用户执行一次）：

```sql
CREATE ROLE course WITH LOGIN PASSWORD 'course' CREATEDB;
CREATE DATABASE lanshan_course OWNER course ENCODING 'UTF8';
```

### 认识命令行客户端 psql

```bash
psql -h 127.0.0.1 -p 5432 -U course -d lanshan_course
```

注意两种输入方式，别混了：

- **SQL 语句**：一个完整的 sql 语句一定以 `;` 结尾，然后再按回车才执行。
- **元命令（meta-command）**：以 `\` 开头，自身就是一条完整指令，**不需要分号**。

```sql
SELECT version();          -- SQL：查看服务端版本，输出一行一列
SELECT * FROM students WHERE id=5;  
-- 上条sql语句与下条作用一致，用于找到student表中id为5的学生并返回他的所有信息
SELECT * FROM students
WHERE id = 5;

course=# \conninfo        -- 元命令：查看当前连接信息
```

常用元命令见[附录 A](#附录-a-psql-元命令速查)。图形客户端推荐 **DBeaver**（免费、跨平台）或 **pgAdmin**（官方的）；VS Code 也可装 SQLTools / Database Client 插件。

---

## 关系模型

### 四个基本概念

**表（Table）** 是一类实体的集合，有固定的列定义。直接想成 Excel 里的一个 sheet：`students` 就是学生表。

**行 / 记录（Row / Record）** 是表里的一条记录，代表一个具体实体。比如`(1, '2024001', '张三', ...)` 这一行，就是指张三这个人。

**列 / 字段（Column / Field）** 是实体的一个属性，有确定的类型。如`name VARCHAR(50)` 说的是"姓名，最多 50 个字符"。

**域（Domain）** 是这一列允许取值的范围。`score` 只能是 0~100——它比类型更严：`INTEGER` 允许 -5，域不允许。

顺带说一下你们看文档时可能会经常遇到的两个词：**元组**和**属性**，元组就对应的是行，而属性就是列

### 键：把表和表连起来

- **主键（Primary Key, PK）**：唯一标识一行，不允许 NULL、不允许重复。通常用自增整数 `SERIAL`，也可以用业务编号或 `UUID`。
- **外键（Foreign Key, FK）**：本表的一列指向另一张表的主键，用来表达"这两行有关系"。
- **候选键 / 唯一键（Unique Key）**：业务上应当唯一的列，比如学号、邮箱。

### 三种关系怎么落成表

```
一对一：1 个学生 ── 1 份档案
  → 档案表里加一个 student_id 外键，并加 UNIQUE 约束

一对多：1 个班级 ── N 个学生            ← 最常见的形态
  → 在"多"的一方（students）加 class_id 外键

多对多：N 个学生 ── M 门课程
  → 必须引入第三张"中间表"（scores），里面同时放两个外键
```

**多对多为什么需要中间表？** 因为关系模型里  一列只能放一个值，没法在 `students` 表里直接塞一个课程列，通过中间表把"N:M"拆成了两条"1:N"

## 建库与建表

建表属于是**一次做对、后面省事**的操作。表结构设计得不好，后面每一条查询都在替它还债；反过来，类型选对、约束加上，很多业务bug 数据库直接就帮你挡掉了

### 数据类型

PostgreSQL 的类型非常多，入门阶段掌握下面这些就够覆盖 90% 场景。挑类型的顺序是：**先想清楚这列要存什么语义，再决定用哪个类型**。


| 类别     | 类型                                                     | 说明                  | 使用建议                              |
| -------- | -------------------------------------------------------- | --------------------- | ------------------------------------- |
| 整数     | `SMALLINT` / `INTEGER` / `BIGINT`                        | 2 / 4 / 8 字节        | 主键用`BIGINT` 更保险                 |
| 自增     | `SERIAL` / `BIGSERIAL`<br>`GENERATED ALWAYS AS IDENTITY` | 自动生成递增整数      | 新项目推荐`IDENTITY` 标准写法         |
| 精确小数 | `NUMERIC(p, s)`                                          | 定点数，不丢精度      | 用于统计金额、分数                    |
| 浮点     | `REAL` / `DOUBLE PRECISION`                              | 有精度误差            | 只用于科学计算                        |
| 文本     | `VARCHAR(n)` / `CHAR(n)` / `TEXT`                        | 变长 / 定长 / 不限长  | 中文长度按**字符**算；不限长用 `TEXT` |
| 布尔     | `BOOLEAN`                                                | `true` / `false`      | —                                    |
| 日期时间 | `DATE` / `TIME` / `TIMESTAMP` / `TIMESTAMPTZ`            | —                    | **存时刻用 `TIMESTAMPTZ`**            |
| 结构化   | `JSONB`                                                  | 二进制 JSON，支持索引 | 存可变结构、接口原始报文              |
| 唯一标识 | `UUID`                                                   | 全局唯一 ID           | 分布式/对外暴露的 ID                  |
| 数组     | `INTEGER[]` / `TEXT[]`                                   | 原生数组              | 简单标签可用，复杂关联仍建议拆表      |

> **Q：为什么金额和分数不能用 `DOUBLE PRECISION`？**
> A：浮点是二进制近似。比如`SELECT 0.1::float8 + 0.2::float8 = 0.3;`的结果是 `false`。`NUMERIC` 是十进制定点数，`0.1 + 0.2 = 0.3` 严格成立。

> **Q：`TIMESTAMP` 还是 `TIMESTAMPTZ`？**
> A：`TIMESTAMP` 不带时区，存进去什么就是什么；`TIMESTAMPTZ` 存的是**绝对时刻**（内部按 UTC 存，按会话时区显示）。跨时区、跨服务器几乎总是该用 `TIMESTAMPTZ`。

### 约束：把业务规则交给数据库

六种常见约束分别管这些事：

- `PRIMARY KEY`（主键）：唯一 + 非空，一张表只能有一个。
- `NOT NULL`：该列不允许为空。
- `UNIQUE`：该列（或列组合）的值唯一，但**可以有多行 NULL**——NULL 之间不算"重复"。
- `CHECK`：表达式必须为真，比如 `score BETWEEN 0 AND 100`。
- `DEFAULT`：不写该列时自动填的值，比如 `now()`。
- `FOREIGN KEY`：引用另一张表的主键，还能配 `ON DELETE` / `ON UPDATE` 行为。

把它们写在一起长这样：

```sql
CREATE TABLE students (
    id         SERIAL PRIMARY KEY,                                      -- 主键：唯一 + 非空
    name       VARCHAR(50)  NOT NULL,                                   -- 不能为空
    email      VARCHAR(100) UNIQUE,                                     -- 唯一，但允许多个 NULL
    gender     CHAR(1)      CHECK (gender IN ('M', 'F')),               -- 只能是 M 或 F
    class_id   INTEGER      REFERENCES classes (id) ON DELETE SET NULL, -- 外键 + 删除行为
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()                      -- 不填就取当前时刻
);
```

外键的删除行为是设计时的重要决策。它要解决的其实是一个很朴素的问题：**父行要被删了，那些还指着它的子行怎么办？**

PostgreSQL 给了四种答案，写法都是在 `REFERENCES` 后面接一句话：

```sql
-- RESTRICT：存在引用就不许删父行
class_id INTEGER REFERENCES classes (id) ON DELETE RESTRICT
```

pgsql默认行为是 NO ACTION，和 RESTRICT 一样，子表还有数据引用父表就无法删除，
他们差别在于检查时机的不同：RESTRICT 立刻报错，而NO ACTION 允许把检查推迟到语句末尾（只在使用可延迟约束 DEFERRABLE INITIALLY DEFERRED 时才体现出来）。

```sql
-- CASCADE：删父行时连带删掉子行
student_id INTEGER REFERENCES students (id) ON DELETE CASCADE
-- ‘成绩’对‘学生’：学生没了，他的成绩留着也没人认领，一起删掉才干净。

-- SET NULL：把子行的外键置为 NULL（前提：该列允许 NULL）
class_id INTEGER REFERENCES classes (id) ON DELETE SET NULL
-- ‘学生’对‘班级’：班级撤销了，学生还在，只是暂时"没班"。
```

还有一种比较少见的做法是设为默认值，典型用法是存在一条"未知班级"的哨兵行，把孤儿数据都挂到它下面。

```sql
-- SET DEFAULT：设为默认值（前提：该列有 DEFAULT）
class_id INTEGER REFERENCES classes (id) ON DELETE SET DEFAULT
```

综上：如果子表有单独存在的价值，就用 `SET NULL`（或者干脆用 `RESTRICT` 拦住，逼人先处理）；没有，就用 `CASCADE`。拿不准时就用默认的 `RESTRICT`——它防护性最强，最坏的结果是"删不掉"，而不是"悄悄删多了"。

> `CASCADE` 是双刃剑：一次 `DELETE` 可能连锁删掉几十万行，而且它**会沿着外键一层层往下传**，删到第三层你都没意识到。生产环境删数据前，先用 `SELECT COUNT(*)` 数一下会被连带删掉多少行。

### 建表

完整脚本见 `sql/schema.sql`，核心片段：

（现在看不懂没关系，知道干什么就行，后面会依次讲到）

```sql
-- 班级
CREATE TABLE classes (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(50) NOT NULL UNIQUE,
    grade      SMALLINT    NOT NULL CHECK (grade BETWEEN 1 AND 4),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 学生
CREATE TABLE students (
    id         SERIAL PRIMARY KEY,
    student_no VARCHAR(20)  NOT NULL UNIQUE,
    name       VARCHAR(50)  NOT NULL,
    gender     CHAR(1)      NOT NULL CHECK (gender IN ('M', 'F')),
    birth_date DATE,
    class_id   INTEGER REFERENCES classes (id) ON DELETE SET NULL,
    email      VARCHAR(100) UNIQUE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- 课程
CREATE TABLE courses (
    id     SERIAL PRIMARY KEY,
    code   VARCHAR(20) NOT NULL UNIQUE,
    name   VARCHAR(100) NOT NULL,
    credit NUMERIC(3, 1) NOT NULL CHECK (credit > 0 AND credit <= 10)
);

-- 成绩（多对多的中间表）
CREATE TABLE scores (
    id         SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES students (id) ON DELETE CASCADE,
    course_id  INTEGER NOT NULL REFERENCES courses (id)  ON DELETE CASCADE,
    score      NUMERIC(5, 2) CHECK (score BETWEEN 0 AND 100),
    exam_date  DATE NOT NULL DEFAULT CURRENT_DATE,
    UNIQUE (student_id, course_id, exam_date)
);

-- 索引：外键列上的 JOIN 会频繁用到
CREATE INDEX idx_scores_student ON scores (student_id);
CREATE INDEX idx_scores_course  ON scores (course_id);
CREATE INDEX idx_students_class ON students (class_id);
```

### 修改表结构：ALTER TABLE

```sql
ALTER TABLE students ADD COLUMN phone VARCHAR(20);                    -- 加列
ALTER TABLE students DROP COLUMN phone;                               -- 删列
ALTER TABLE students ALTER COLUMN email TYPE VARCHAR(200);            -- 改类型
ALTER TABLE students ALTER COLUMN email SET NOT NULL;                 -- 加约束
ALTER TABLE students RENAME COLUMN email TO email_addr;               -- 改列名
ALTER TABLE students RENAME TO student;                               -- 改表名
```

> 生产环境改大表结构（加列带默认值、改类型）可能长时间锁表，需要评估影响窗口；跨环境的结构变更应当交给迁移工具（Alembic / Flyway），**不要靠人肉执行 SQL**。

### 索引入门

索引像书的目录：没有它只能整表顺序扫描（Seq Scan），有了它可以直接定位。
pgsql中的原生索引有六种（btree, hash, gist, spgist, gin, brin），
下面只以pg中最常用也是默认使用的B-Tree索引为例，剩下的可以自行学习

```sql
CREATE INDEX idx_students_name ON students (name);          -- 普通索引
CREATE UNIQUE INDEX uq_students_email ON students (email);  -- 唯一索引
CREATE INDEX idx_scores_score ON scores (score DESC);       -- 支持降序
DROP INDEX idx_students_name;                               -- 删除索引
```

注：

- **主键和 `UNIQUE` 约束会自动创建索引**，不用重复建。
- **索引不是越多越好**：每个索引都会让 `INSERT/UPDATE/DELETE` 变慢，并占用磁盘。
- **在索引列上做函数运算会让索引失效**：

  ```sql
  WHERE name = '张三'            -- 走索引
  WHERE LOWER(name) = '张三'     -- 索引失效（除非建了表达式索引）
  ```

`EXPLAIN ANALYZE` 可以查看执行计划：

```sql
EXPLAIN ANALYZE SELECT * FROM scores WHERE student_id = 1;
```

看到 `Seq Scan` 说明走了全表扫描，看到 `Index Scan` 说明命中了索引。

---

## 增删改查（CRUD）

CRUD 是 SQL 的日常：Create、Read、Update、Delete。其中读操作尤其重要——查得好不好，决定了你的数据库能不能撑住。所以这一节的篇幅，大半给了 `SELECT`

### INSERT INTO - 插入

```sql
-- 指定列插入
INSERT INTO classes (name, grade) VALUES ('计科2401', 2);

-- 一次插多行，比循环单条插入快一个数量级
INSERT INTO courses (code, name, credit) VALUES
    ('PY101',   'Python 程序设计', 4.0),
    ('DB201',   '数据库原理',       3.5),
    ('MATH101', '高等数学',         5.0);

-- 拿到刚插入的整行（PostgreSQL 特色，很实用）
INSERT INTO students (student_no, name, gender, class_id)
VALUES ('2024001', '张三', 'M', 1)
RETURNING id, student_no, name, created_at;
```

`RETURNING` 免去了"插完再查一次主键"的往返，也很适合配合 `id = currval()` 之类的老写法——现在直接用 `RETURNING` 就够了。

**冲突处理：`ON CONFLICT`（UPSERT）**

```sql
-- 学号已存在时什么都不做
INSERT INTO students (student_no, name, gender, class_id)
VALUES ('2024001', '张三', 'M', 1)
ON CONFLICT (student_no) DO NOTHING;
-- 学号已存在时就更新姓名（幂等导入 CSV 的神器）
INSERT INTO students (student_no, name, gender, class_id)
VALUES ('2024001', '张三丰', 'M', 2)
ON CONFLICT (student_no) DO UPDATE
    SET name     = EXCLUDED.name,     -- EXCLUDED 指的是"本次想插入的那一行"
        class_id = EXCLUDED.class_id;
```

### UPDATE - 更新

基础语法如下：

update 表名 SET 列名 = 要改为的值  WHERE 条件

```sql
-- 单行更新
UPDATE students SET email = 'zhangsan@lanshan.dev' WHERE student_no = '2025001';

-- 多列更新
UPDATE students
SET    class_id = 3,
       email    = 'zhangsan@lanshan.dev'
WHERE  id = 1;

-- 表达式更新 + 返回受影响的行
UPDATE scores
SET    score = score + 5
WHERE  course_id = 2 AND score < 60
RETURNING id, score;
```

> **一旦忘记写 `WHERE`，就是全表更新。** 所以习惯上先用 `SELECT` 加同样的 `WHERE` 看命中几行，确认无误再把 `SELECT` 改成 `UPDATE`。也可以在事务里操作，确认后再 `COMMIT`。

### DELETE / TRUNCATE - 删除

```sql
DELETE FROM scores WHERE score IS NULL;              -- 条件删除
DELETE FROM scores WHERE student_id = 20
RETURNING id;                                        -- 看看删掉了哪些
```

```sql
TRUNCATE TABLE scores RESTART IDENTITY CASCADE;      -- 清空整表，速度极快
```

两者的差别不止在删除的快慢上：

**粒度**：`DELETE` 可以带 `WHERE` 删一部分行；`TRUNCATE` 只能整表清空，不接受条件。

**速度**：`DELETE` 逐行删除、逐行写日志，大表能删到你怀疑人生；`TRUNCATE` 直接丢掉整块数据、重建一个空表，极快。

**日志与回滚**：`DELETE` 记录每一行，所以能精确回滚到中途；`TRUNCATE` 只记一条"这张表被清空了"，回滚粒度是整个表。

**级联**：`DELETE` 会自动触发子表上的 `ON DELETE` 级联；`TRUNCATE` 不会自动级联，必须显式写 `CASCADE`，否则一有别的表引用它就直接报错。

**自增序列**：`DELETE` 不动序列，删完再插还是接着往下编号；`TRUNCATE` 默认也不动，想重置要写 `RESTART IDENTITY`。

> **软删除** 是生产中的常见做法：加一列 `deleted_at TIMESTAMPTZ`，删除时只写时间戳，查询时统一加 `WHERE deleted_at IS NULL`。好处是数据可追溯、可恢复，代价是每条查询都得记得加条件。

---

### SELECT - 查询

基础写法：

```sql
SELECT * FROM students; 	 	-- 返回整张students表

SELECT
    id,
    student_no AS 学号,     -- AS 起别名
    name      AS 姓名
FROM students
WHERE gender = 'F'         -- WHERE 用于筛选符合条件的数据
ORDER BY id DESC            -- 用ORDER BY排序
LIMIT 10 OFFSET 0;          -- 第 1 页
```

> **Q：`SELECT *` 什么时候可以用？**
>
> **A：交互式探索时很方便**。但**写进代码的查询不要用 `SELECT *`**：表加列会让返回结构悄悄变化，也可能拖回用不到的大字段（比如 `TEXT` 正文、`BYTEA` 二进制）

注意：**SELECT 的书写顺序 ≠ 执行顺序**。
你写的顺序是给人看的，而数据库实际则按另一套顺序执行：

```
书写顺序                         逻辑执行顺序
─────────────────────────       ─────────────────────────
1. SELECT   ...                  1. FROM / JOIN    ← 先确定数据源
2. FROM     ...                  2. WHERE          ← 行级过滤
3. WHERE    ...                  3. GROUP BY       ← 分组
4. GROUP BY ...                  4. HAVING         ← 组级过滤
5. HAVING   ...                  5. SELECT         ← 计算要输出的列
6. ORDER BY ...                  6. DISTINCT
7. LIMIT    OFFSET ...           7. ORDER BY       ← 排序
                                 8. LIMIT / OFFSET ← 用于截断
```

由此可以解释几个常见疑问：

- **为什么 `WHERE` 里不能用 `SELECT` 中定义的别名？** 因为 `WHERE` 执行时 `SELECT` 还没跑
- **为什么 `WHERE` 里不能写聚合函数？** 同理，`WHERE` 阶段还没有"组"的概念；要过滤组用 `HAVING`
- **为什么 `ORDER BY` 里可以用别名？** 因为它在 `SELECT` 之后执行。`ORDER BY` 和 `LIMIT` 也能用别名

## 条件查询

由于实际项目里，`SELECT *` 几乎从不出现在代码中——真实的查询永远带着条件。这一节讲的都是 `WHERE` 和它周边的工具：运算符、范围、模糊匹配、NULL，以及把结果排好序、分好页。

其中关于NULL的介绍认真，它是 SQL 里最容易写错、最难查出来的一类 bug。

### 运算符

```sql
-- 比较
WHERE score >= 60
WHERE score <> 60          -- 不等于，也可以写 !=
-- 逻辑（注意:AND优先级高于OR，混合使用时记得加括号）
WHERE gender = 'F' AND (score >= 90 OR credit >= 4)
-- 取反
WHERE NOT (score < 60)
```

> **优先级陷阱**：`WHERE a OR b AND c` 等价于 `WHERE a OR (b AND c)`。想清楚是不是你想要的，不确定就加括号

### 范围、集合与模糊匹配

```sql
WHERE score BETWEEN 60 AND 90          -- 闭区间，等价于 >= 60 AND <= 90
WHERE class_id IN (1, 2, 3)            -- 属于集合
WHERE class_id NOT IN (1, 2)
WHERE name LIKE '张%'                  -- % 任意多字符，_ 单个字符
WHERE name ILIKE 'zhang%'              -- ILIKE 忽略大小写（PostgreSQL 扩展）
WHERE name LIKE '张_'
```

> **`NOT IN` 的 NULL 陷阱**：如果子查询结果里有 NULL，`NOT IN` 会返回空结果集，因为 `x <> NULL` 结果是 `UNKNOWN` 而不是 `true`。安全写法是 `NOT EXISTS`，或在子查询里加 `WHERE col IS NOT NULL`。

### NULL：三值逻辑

NULL 在psql中表示"未知"，而不是 0或空。它参与运算的结果是 `UNKNOWN`，而 `WHERE` 只保留结果为 `TRUE` 的行，所以如果用`=`来判断是否为NULL，查询返回的是空表，我们可以通过`IS`和`IS NOT`判段是否为NULL

```sql
SELECT * FROM students WHERE email IS NULL;
SELECT * FROM students WHERE email IS NOT NULL;
```

那如果遇到要处理NULL的情况可以用下面两个函数：

（1）`COALESCE`可有多个表达式，用于返回第一个不为 NULL的表达式，如果全部都是 NULL，最后返回 NULL

（2）`NULLIF`如果前一个参数等于后一个参数，则返回NULL，否则返回前一个参数

```sql
-- 
SELECT name, COALESCE(email, '未填写') AS email FROM students;   -- email为空则取替代值
SELECT NULLIF(score, 0) FROM scores;                              -- 等于0则变为NULL
SELECT AVG(COALESCE(score, 0)) FROM scores;                     -- 把缺考当0分算
```

**聚合函数可以会跳过 NULL**：

```sql
-- score 中有 1 行 NULL，共 10 行
SELECT COUNT(*)          FROM scores;   -- 10   统计行数，包含 NULL 行
SELECT COUNT(score)      FROM scores;   -- 9    只统计非 NULL
SELECT COUNT(DISTINCT score) FROM scores;-- 9    去重后再统计
SELECT AVG(score)        FROM scores;   -- 分母是 9，不是 10
```

### 排序与分页

```sql
-- 多列排序：先按班级升序，同班内按分数降序，（默认NULL在最后）
SELECT * FROM students ORDER BY class_id ASC NULLS LAST, name DESC;

-- 分页：LIMIT限制每页 10 条，OFFSET从第 3 页开始取（跳过前面20个数据）
SELECT * FROM students ORDER BY id LIMIT 10 OFFSET 20;
```

> **分页的一个隐藏坑**：`ORDER BY` 里如果有重复值，不同页可能出现同一行（或漏行），因为排序不稳定。稳妥做法是在 `ORDER BY` 末尾补一个唯一列：`ORDER BY score DESC, id ASC`。
>
> 深分页（`OFFSET` 很大）性能很差，因为它要先把前面所有行读出来扔掉。大表分页应当改用**游标分页（keyset pagination）**：`WHERE (score, id) < (上次的 score, 上次的 id) ORDER BY score DESC, id DESC LIMIT 20`。

### 常用函数与 CASE条件判断

一些常用函数：

```sql
-- 字符串
-- TRIM用于去除name中首尾的空白字符
SELECT UPPER(name), LOWER(name), LENGTH(name), TRIM(name) FROM students;
-- CONCAT 拼接字符串
SELECT CONCAT(name, '(', student_no, ')') FROM students;
-- SUBSTRING截取字符串
SELECT SUBSTRING(student_no FROM 1 FOR 4) FROM students;   -- 取年份 '2024'

-- 日期时间
SELECT now();                          -- 当前时刻（带时区）
SELECT CURRENT_DATE, CURRENT_TIME;     -- 当前日期和时间
SELECT exam_date, exam_date + INTERVAL '7 days' FROM scores;
SELECT EXTRACT(YEAR FROM exam_date) FROM scores;           -- 取出年份
SELECT DATE_TRUNC('month', exam_date) FROM scores;         -- 截断到月初
SELECT AGE(CURRENT_DATE, birth_date) FROM students;        -- 时间间隔

-- 数值
SELECT ROUND(AVG(score), 2) FROM scores;
SELECT CEIL(89.1), FLOOR(89.9), ABS(-5);
```

CASE 就相当于SQL里的if/else，大体语法如下：

`CASE WHEN ... THEN ... ELSE ... END`

```sql
SELECT
    name,
    score,
    CASE
        WHEN score IS NULL   THEN '缺考'
        WHEN score >= 90     THEN '优秀'
        WHEN score >= 80     THEN '良好'
        WHEN score >= 60     THEN '及格'
        ELSE                      '不及格'
    END AS level
FROM students AS s
JOIN scores AS sc ON sc.student_id = s.id
ORDER BY score DESC NULLS LAST;
```

---

## 多表连接

### 为什么需要 JOIN

数据被拆到了多张表里（这是范式的要求），但用户要看的是"张三在数据库原理课上考了 92 分"——这需要把 `students`、`courses`、`scores` 拼在一起。`JOIN` 用来就是干这个的

**没有 `ON` 条件的JOIN连接会产生笛卡尔积**：4 个班 × 20 个学生 = 80 行。这是最常见的性能事故来源

### 五种连接

```mermaid
graph TD
    A["INNER JOIN<br/>两表都有匹配<br/>（交集）"] 
    B["LEFT JOIN<br/>左表全保留<br/>右表无匹配补 NULL"]
    C["RIGHT JOIN<br/>右表全保留<br/>左表无匹配补 NULL"]
    D["FULL OUTER JOIN<br/>两表都全保留<br/>无匹配处补 NULL（并集）"]
    E["CROSS JOIN<br/>笛卡尔积<br/>无条件组合，慎用"]
```

```sql
-- (INNER) JOIN：只保留两边都匹配上的行（最常用）
SELECT s.name, sc.score
FROM students AS s
INNER JOIN scores AS sc ON sc.student_id = s.id;

-- LEFT JOIN：保留所有学生，没成绩的显示 NULL（找"零参与"数据必用）
SELECT s.name, sc.score
FROM students AS s
LEFT JOIN scores AS sc ON sc.student_id = s.id;

-- 只找没成绩的学生（反连接模式）
SELECT s.name
FROM students AS s
LEFT JOIN scores AS sc ON sc.student_id = s.id
WHERE sc.id IS NULL;

-- RIGHT JOIN：反过来，实际开发中几乎都能改写成 LEFT JOIN
SELECT s.name, c.name, sc.score
FROM scores AS sc
RIGHT JOIN courses AS c ON c.id = sc.course_id;

-- FULL OUTER JOIN：并集，两边不匹配的都保留
SELECT s.name, sc.score
FROM students AS s
FULL OUTER JOIN scores AS sc ON sc.student_id = s.id;
```

**`ON` vs `WHERE` 在 `LEFT JOIN` 中的关键区别**：

```sql
-- 1.条件在 ON 里：先连接，再保留左表所有行 → 没修的课也会出现（成绩为 NULL）
SELECT s.name, sc.score
FROM students AS s
LEFT JOIN scores AS sc
       ON sc.student_id = s.id AND sc.course_id = 2;

-- 2.条件在WHERE里：先做完整LEFT JOIN，再把sc.course_id为NULL的行（含未匹配的）筛掉
-- LEFT JOIN退化成INNER JOIN，因为NULL <> 2，为UNKNOWN
SELECT s.name, sc.score
FROM students AS s
LEFT JOIN scores AS sc ON sc.student_id = s.id
WHERE sc.course_id = 2;
```

**`LEFT JOIN` 里，作用在右表上的过滤条件写在 `ON` 里，才是真的"左表全保留"。**

### 多表连接链

```sql
SELECT
    s.student_no AS 学号,
    s.name       AS 姓名,
    cl.name      AS 班级,
    c.name       AS 课程,
    c.credit     AS 学分,
    sc.score     AS 分数
FROM students     AS s
JOIN classes      AS cl ON cl.id = s.class_id
JOIN scores       AS sc ON sc.student_id = s.id
JOIN courses      AS c  ON c.id = sc.course_id
WHERE sc.score >= 90
ORDER BY sc.score DESC, s.name;
```

**`USING` 简化写法**（两表列名相同时）：

```sql
SELECT * FROM students JOIN scores USING (student_id);   -- 等价于 ON a.id = b.id
```

### 自连接：同一张表当两张表用

```sql
-- 找出同班同名的学生（少见但经典）
SELECT a.name, a.student_no, b.student_no
FROM students AS a
JOIN students AS b
  ON a.class_id = b.class_id AND a.name = b.name AND a.id < b.id;
```

自连接必须给两张"表"起不同的别名，否则无法区分。

### 子查询

```sql
-- 标量子查询：返回单个值，可放在SELECT / WHERE里
SELECT name, score
FROM scores AS sc
JOIN students AS s ON s.id = sc.student_id
WHERE score > (SELECT AVG(score) FROM scores);

-- IN 子查询：属于某个集合
SELECT name FROM students
WHERE id IN (SELECT DISTINCT student_id FROM scores WHERE score >= 95);

-- EXISTS 子查询：存在性判断（比 IN 更安全，且遇 NULL 无陷阱）
SELECT s.name FROM students AS s
WHERE EXISTS (
    SELECT 1 FROM scores AS sc
    WHERE sc.student_id = s.id AND sc.score < 60
);

-- 相关子查询：内层用到了外层的列
SELECT s.name,
       (SELECT ROUND(AVG(sc.score), 1)
          FROM scores AS sc WHERE sc.student_id = s.id) AS 个人平均分
FROM students AS s;

-- FROM 子查询 / 派生表：把查询结果当临时表
SELECT 课程, 平均分
FROM (
    SELECT c.name AS 课程, AVG(sc.score) AS 平均分
    FROM scores AS sc JOIN courses AS c ON c.id = sc.course_id
    GROUP BY c.id, c.name
) AS t
WHERE 平均分 > 80;
```

> **性能提示**：大部分情况下，优化器能把 `IN` / `EXISTS` 重写成同一种执行计划。写的时候优先选**语义更清晰**的那个；真遇到慢查询再用 `EXPLAIN ANALYZE` 定夺。

## 聚合与分组

前面讲完怎么查找行，那如果要找到有多少学生有成绩以及每个班学生的平均成绩应该怎么做呢，这就是接下来要讲的聚会与分组。这也是 SQL 真正发挥价值的地方：几百万行数据，通过`GROUP BY` 就能给你一张报表。

### 五个聚合函数

```sql
SELECT
    COUNT(*)          AS 成绩条数,
    COUNT(score)      AS 有效成绩数,
    SUM(score)        AS 总分,
    ROUND(AVG(score), 2) AS 平均分,
    MIN(score)        AS 最低分,
    MAX(score)        AS 最高分
FROM scores;
```

不带 `GROUP BY` 的聚合会把**整个结果集压成一行**，而单行单列结果就是一个标量（scalar），完全可以放到 `AVG()`、`WHERE`、表达式、子查询等语句里当一个数值使用，所以你可以做到如下事情：

```sql
-- 查找分数大于全体学生平均分的成绩
SELECT *
FROM scores
WHERE score > (SELECT AVG(score) FROM scores WHERE score IS NOT NULL);
```

### GROUP BY：先分组，再聚合

```sql
SELECT
    c.code,
    c.name                        AS course_name,
    COUNT(*)                      AS 选课人次,
    ROUND(AVG(s.score), 2)        AS 平均分,
    STRING_AGG(s.score::text, ',' ORDER BY s.score) AS 所有分数,
    MAX(s.score)                  AS 最高分
FROM scores AS s
JOIN courses AS c ON c.id = s.course_id
GROUP BY c.id, c.code, c.name       -- 注意：非聚合列必须出现在 GROUP BY 里
ORDER BY 平均分 DESC;
```

不是很理解GROUP BY的可以看看这篇帖子[关于group by的用法 原理](https://blog.csdn.net/u014717572/article/details/80687042)

> **注**：`SELECT` 里出现的**非聚合列，必须出现在 `GROUP BY` 中**。否则数据库不知道该取哪一行的值（PostgreSQL 会直接报错，比MySQL的宽松模式更安全）

### HAVING：过滤"组"

```sql
-- 找出平均分低于 75 的课程
SELECT c.name, ROUND(AVG(s.score), 2) AS 平均分
FROM scores AS s
JOIN courses AS c ON c.id = s.course_id
GROUP BY c.id, c.name
HAVING AVG(s.score) < 75
ORDER BY 平均分;
```

两者的分工，一句话就能分清：**`WHERE` 管理"行"，`HAVING` 管理"组"**

`WHERE` 作用在原始的每一行上，执行时机在 `GROUP BY` **之前**，所以它不能写聚合函数——那时候还没有"组"这个概念。好处是**先过滤能减少要分组的数据量**，性能更好，能放在 `WHERE` 的条件就别拖到 `HAVING`。

`HAVING` 作用在分组之后的**组**上，执行时机在 `GROUP BY` **之后**，可以用 `COUNT` / `AVG` 这些聚合函数。代价是它必须在分组、算完聚合之后才能筛，数据量已经压过一轮了。

所以原则是：**行级条件尽量写进 `WHERE`，只有必须过滤聚合结果时才用 `HAVING`。**

```sql
-- 组合使用：先筛掉缺考，再算平均分，最后过滤组
SELECT c.name, ROUND(AVG(s.score), 2) AS 平均分
FROM scores AS s
JOIN courses AS c ON c.id = s.course_id
WHERE s.score IS NOT NULL          -- 1.行级过滤
GROUP BY c.id, c.name
HAVING COUNT(*) >= 3               -- 2.组级过滤
ORDER BY 平均分 DESC;
```

### 条件聚合：`FILTER` 与 `CASE`

FILTER是pgsql中一个特有的写法，把满足 WHERE 条件的行送入聚合函数中

它跟CASE的用法有点像，都是用来做条件判断，但不同的是FILTER**只能用在聚合函数后面**，无法单独进行使用，并且FILTER不支持 `HAVING`、`ORDER BY` 写在里面，里面只能是布尔条件

```sql
-- 例：想在一次查询里算出"总人数"和"及格人数"以及"及格率"：
-- 写法一：FILTER（pgsql的标准扩展，可读性好）
SELECT
    COUNT(*)                                   AS 总人次,
    COUNT(*) FILTER (WHERE score >= 60)        AS 及格人次,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE score >= 60) / COUNT(*), 1
    )                                          AS 及格率
FROM scores;

-- 写法二：CASE WHEN（不依赖聚合函数，跨数据库通用）
SELECT
    COUNT(*)                                          AS 总人次,
    SUM(CASE WHEN score >= 60 THEN 1 ELSE 0 END)      AS 及格人次
FROM scores;
```

> 注`100.0 * ...` 里的 `.0` 是必要的，因为整数除法 `1/2` 在 SQL 里等于 `0`，必须先转成小数类型

### 窗口函数：聚合而不折叠

聚合会把多行压成一行，而窗口函数则**保留每一行**，同时附上分组统计值，相当于给原结果加上一列聚合后的结果
窗口函数后面都会紧跟着`OVER`，他的核心作用是给窗口或者聚和函数划定一个**数据窗口**（Window），相当于告诉数据库：“请在前面这个函数（比如 AVG、RANK）计算时，每次基于OVER后的内容划定的这个范围去算，但算完之后，不要折叠原表的数据行”
`OVER`的语法如下：

```sql
OVER(
	 PARTITION BY 字段  -- 用于分区，把整张表切成多个独立窗口
	 ORDER BY 字段      -- 对窗口内的数据排序
	 {ROWS | RANGE} BETWEEN 起点 AND 终点  -- 划定一个滑动子集
)
```

常用'起点'与'终点'如下：

- `UNBOUNDED PRECEDING`：分区第一行
- `N PRECEDING`：当前行往前 N 行
- `CURRENT ROW`：当前行
- `N FOLLOWING`：当前行往后 N 行
- `UNBOUNDED FOLLOWING`：分区最后一行

```sql
-- 示例：每名学生每门课的成绩 + 该课程平均分 + 该课程排名
SELECT
    s.name                            AS 学生,
    c.name                            AS 课程,
    sc.score                          AS 分数,
    ROUND(AVG(sc.score) OVER (PARTITION BY sc.course_id), 2) AS 平均分,
    RANK()  OVER (PARTITION BY sc.course_id ORDER BY sc.score DESC) AS 排名
FROM scores AS sc
JOIN students AS s ON s.id = sc.student_id
JOIN courses  AS c ON c.id = sc.course_id
ORDER BY c.name, 排名;
```

几个经常使用的窗口函数：

- `ROW_NUMBER()`：组内连续编号 `1,2,3,4`，永远不重复，也不管并列。
- `RANK()`：并列后**跳号**，如`1,2,2,4`——两个第 2 名，下一个直接是第 4。
- `DENSE_RANK()`：并列后**不跳号**，如`1,2,2,3`。
- `LAG(col)` / `LEAD(col)`：取组内上一行 / 下一行的值，做同比环比、算相邻差值全靠它。
- `SUM(col) OVER (...)`：累计求和，比如按日期累加销售额。

一句话记差别：`RANK` 会空号，`DENSE_RANK` 不会空号，`ROW_NUMBER` 根本不管并列。

通过窗口函数能写出非常干净的统计报表，可以多敲几遍

---

### 集合运算与视图

```sql
SELECT name FROM students WHERE gender = 'F'
UNION                  -- 去重合并
SELECT '占位名字';

SELECT name FROM students WHERE gender = 'F'
UNION ALL              -- 不去重，性能更好（确定无重复时优先用它）
SELECT name FROM students WHERE class_id = 1;

SELECT student_id FROM scores INTERSECT SELECT student_id FROM students;  -- 交集
SELECT id FROM students EXCEPT SELECT student_id FROM scores;             -- 差集
```

**视图（VIEW）** 把复杂查询存起来当虚拟表用：

```sql
CREATE OR REPLACE VIEW v_student_report AS
SELECT
    s.student_no,
    s.name        AS student_name,
    cl.name       AS class_name,
    COUNT(sc.id)                              AS 课程数,
    ROUND(AVG(sc.score), 2)                   AS 平均分
FROM students AS s
LEFT JOIN classes AS cl ON cl.id = s.class_id
LEFT JOIN scores  AS sc ON sc.student_id = s.id
GROUP BY s.id, s.student_no, s.name, cl.name;

-- 之后就能像查表一样查它
SELECT * FROM v_student_report WHERE 平均分 > 80 ORDER BY 平均分 DESC;

DROP VIEW v_student_report;
```

视图本身不存数据，只是保存了查询定义；它很适合给上层应用或报表工具暴露一个稳定的结构。

扩展：
你可能在练习sql过程中会看到这样的语句

```sql
-- 查找每个学生的得分最高的科目及其对应成绩（如果有多个只保留一个）
WITH ranked_scores AS (
    SELECT
        s.id            AS student_id,
        s.student_no,
        s.name          AS student_name,
        c.code          AS course_code,
        c.name          AS course_name,
        sc.score,
        ROW_NUMBER() OVER (
            PARTITION BY s.id
            ORDER BY sc.score DESC, sc.exam_date DESC, sc.id ASC
        ) AS rn
    FROM students s
    JOIN scores  sc ON sc.student_id = s.id
    JOIN courses c  ON c.id = sc.course_id
    WHERE sc.score IS NOT NULL
)
SELECT
    student_id,
    student_no,
    student_name,
    course_code,
    course_name,
    score
FROM ranked_scores
WHERE rn = 1
ORDER BY student_no;
```

这里的WITH查询其实就是**CTE（公共表表达式）**，这是一种让查询结构更清晰的语法。如上面用WITH ... AS语句将括号里面查询的结果放到了名为ranked_scores的临时结果集里，让**紧接着的sql语句**可以使用这个临时结果集进行查询（pgsql中也允许执行INSERT、UPDATE、DELETE操作），这样可以使你写的sql更容易阅读、调试和修改。并且，CTE也支持递归查询来处理树形、层级结构

WITH后面也可以一次性定义多个CTE，用`，`分隔开

---

## 事务与并发

### 为什么需要事务

假设一个场景：从 A 扣 100、给 B 加 100，这两步要么都发送，要么都不发生。一旦中间过程中发生错误就会凭空少 100 块。

```sql
BEGIN;

UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;

-- 检查约束是否满足：余额不能为负
-- 满足就提交，不满足就回滚
COMMIT;     -- 提交
-- ROLLBACK;  -- 回滚，撤销本次事务内的所有改动
```

把转账这个故事套进去，下面数据库的四个特性就能懂了：

**原子性（Atomicity）**：事务内的操作要么全做，要么全不做。扣款和入账是一个整体，中间断电，谁的钱都不动——不会出现"A 少了 100，B 没收到"的半成品。

**一致性（Consistency）**：事务前后数据库都满足所有约束。钱的总数不变、余额不能为负，这些是业务规则，由数据库在提交时守住。

**隔离性（Isolation）**：并发事务之间互不干扰。别人看不到你还没提交的中间状态，就像你们各自在副本上操作，提交那一刻才合并。

**持久性（Durability）**：提交后的数据即使立刻断电也不丢，靠 WAL（预写日志）先落盘再返回。

虽然是四大特性，但另外三个最终都是为了**一致性**服务的：原子性保证"不出半成品"，隔离性保证"并发不互相污染"，持久性保证"承诺过的不会反悔"。

### 隔离级别

并发事务若不加控制，会撞出三种"读异常"。它们名字很像，但盯的是不同的东西：

**脏读（Dirty Read）**：读到了别的事务**尚未提交**的修改。对方后来回滚了，你手里这份数据就是从来没存在过的。

**不可重复读（Non-repeatable Read）**：同一个事务里两次读同一行，结果不一样——因为中间别的事务改了它并提交了。它针对的是**某一行的内容**。

**幻读（Phantom Read）**：同一个事务里两次做同样的范围查询，**行数变了**——别的事务往这个范围里插了新行，像幻觉一样多出来一条。它针对的是**结果集的行数**，不是某一行的值。

PostgreSQL 支持四个标准隔离级别（默认 **READ COMMITTED**）。逐级往上，限制越来越严、并发度越来越低：

1.**READ UNCOMMITTED-读未提交**：标准里最松的一级，会产生脏读的问题，但 由于 PostgreSQL **直接把它当作 READ COMMITTED 处理**——MVCC 的实现方式天然不会产生脏读。所以你写这一级，实际拿到的还是 READ COMMITTED 的保证。

2.**READ COMMITTED-读已提交（默认）**：不会脏读，但**不可重复读和幻读都可能发生**。每条语句看到的是"这条语句开始那一刻已提交"的快照，所以同一事务里的两条语句，完全可能看到不同版本的数据。

3.**REPEATABLE READ-可重复读**：整个事务共用一个快照，不会脏读、不会不可重复读。PostgreSQL 的实现比 SQL 标准更强——**幻读基本也能避免**（标准只要求它"可能避免"）。代价是并发更新同一行时会报 `could not serialize access due to concurrent update`，需要在应用层写重试。

4.**SERIALIZABLE-串行化**：最强的一级，效果等价于"事务一个接一个串行执行"。脏读、不可重复读、幻读全都没有，但冲突时失败率最高，同样需要重试逻辑。

> **整合起来看**：`RU`（PostgreSQL 等同 RC）→ `RC` 只挡脏读 → `RR` 连不可重复读也挡，幻读基本避免 → `SERIALIZABLE` 4 全挡。越往右越安全，也越容易因为冲突失败而需要重试。

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
-- ... 一批需要内部一致快照的查询 ...
COMMIT;
```

> PostgreSQL 用**MVCC（多版本并发控制）实现隔离**：读操作不会阻塞写、写也不会阻塞读，靠保留行的多个版本来实现。代价是会产生"死元组"，由后台 `VACUUM` 清理，这也是为什么 PostgreSQL 表会"膨胀"（bloat）

当两个事务各持有一把锁、又互相等对方释放，就会卡住，即死锁。

对此，PostgreSQL 后台有一个专门的进程，会定期扫描所有正在等待锁的事务，一旦检测到死锁后**主动中止其中一个**事务（通常是代价较小、或者执行时间较短的那个事务），然后抛出 `deadlock detected`。

预防死锁的方法：**所有事务按相同的顺序访问表/行**。

### 用事务做危险操作的"安全网"

```sql
BEGIN;
DELETE FROM students WHERE class_id = 4;   -- 先执行，别提交
SELECT COUNT(*) FROM students;             -- 确认影响行数对不对
ROLLBACK;                                  -- 不对就撤销；确认对了改成 COMMIT
```

这是每个数据库使用者都应养成的习惯，比任何备份都来得快。

---

## 用 Python 连接 PostgreSQL

到这儿为止，我们都在 `psql` 里手敲 SQL。但真实的后端服务不会那样工作：它得由程序去连库、发 SQL、拿结果，还要处理事务、参数和连接复用。

这一节就从最底层的驱动开始，一步一步往上搭：**驱动 → 连接 → 执行 → 防注入 → 事务 → 连接池 → 封装工具**。下一节的 SQLAlchemy 站在这一层之上。

### 安装驱动

```bash
pip install "psycopg[binary]"      # 带上二进制版 libpq，以免装系统依赖
pip install "psycopg[binary,pool]" # 再加连接池
```

### 连接字符串

```
postgresql://用户:密码@主机:端口/数据库名
postgresql://course:course@127.0.0.1:5432/lanshan_course
```

也可以拆成关键字参数（密码含特殊字符时更安全）：

```python
conn = psycopg.connect(
    host="127.0.0.1", port=5432,
    dbname="lanshan_course",
    user="course", password="course",
    connect_timeout=5,
)
```

> 注：**千万别把密码硬编码进代码。** 通过配置环境变量：`os.environ["DATABASE_URL"]`，配合 `.env` 文件（记得把 `.env` 写进 `.gitignore`）来进行储存。

### 基本用法

```python
import psycopg
from psycopg.rows import dict_row

DSN = "postgresql://course:course@127.0.0.1:5432/lanshan_course"

# with 块退出时：正常结束自动 COMMIT，抛异常自动 ROLLBACK
with psycopg.connect(DSN, row_factory=dict_row) as conn:
    with conn.cursor() as cur:
        # 查询
        cur.execute(
            "SELECT id, student_no, name FROM students WHERE class_id = %s ORDER BY id",
            (1,),                                   # 参数用元组传入，末尾逗号别丢
        )
        rows = cur.fetchall()                        # list[dict]
        for row in rows:
            print(row["student_no"], row["name"])

        # 单行：拿不到会返回 None，而不是抛异常
        cur.execute("SELECT * FROM students WHERE student_no = %s", ("2024001",))
        one = cur.fetchone()

        # 插入并取回主键
        cur.execute(
            """
            INSERT INTO students (student_no, name, gender, class_id)
            VALUES (%s, %s, %s, %s)
            RETURNING id
            """,
            ("2024999", "测试同学", "F", 1),
        )
        new_id = cur.fetchone()["id"]

        # 批量插入（executemany，性能远好于循环单插）
        cur.executemany(
            "INSERT INTO scores (student_id, course_id, score) VALUES (%s, %s, %s)",
            [(new_id, 1, 88), (new_id, 2, 91)],
        )
```

### 安全第一：参数化查询

**SQL注入**：当用户输入SQL语句时如果直接拼进正常SQL则会产生数据泄露等安全问题

```python
name = "'; DROP TABLE students; --"
cur.execute(f"SELECT * FROM students WHERE name = '{name}'")
# 实际执行的是：SELECT * FROM students WHERE name = ''; DROP TABLE students; --'

# 拼字符串也同样危险（即使你可能以为转义了）
cur.execute("SELECT * FROM students WHERE name = '%s'" % name)
```

因此，传参时应该通过使用占位符并通过单独传参来防止恶意注入

```python
#使用(name,)是因为execute的第二个参数必须是序列(即列表或元组等)
cur.execute("SELECT * FROM students WHERE name = %s", (name,))
```

这是因为参数化查询通过把"SQL 结构"和"数据值"分两趟发给服务器，数据永远被当作值处理，不可能改变语句结构

> 顺带一提：`%s` 是 psycopg 的占位符风格（遵循 DB-API）。它和 Python 的 `%` 格式化**没有关系**，别弄混了。所有值——包括数字和字符串——统一用 `%s`，psycopg 会按 Python 类型自动适配。想传列表用 `%s` 配合 `WHERE id = ANY(%s)`。

### 事务控制

```python
# 方式一：with 块自动管理
with psycopg.connect(DSN) as conn:
    with conn.cursor() as cur:
        cur.execute("UPDATE accounts SET balance = balance - 100 WHERE id = 1")
        cur.execute("UPDATE accounts SET balance = balance + 100 WHERE id = 2")
    # 离开 with 时自动 COMMIT；若抛异常则自动 ROLLBACK

# 方式二：手动控制（需要中间检查点或复杂逻辑时）
conn = psycopg.connect(DSN)
conn.autocommit = False
try:
    with conn.cursor() as cur:
        cur.execute("UPDATE accounts SET balance = balance - 100 WHERE id = 1")
        cur.execute("UPDATE accounts SET balance = balance + 100 WHERE id = 2")
    conn.commit()
except Exception:
    conn.rollback()
    raise
finally:
    conn.close()
```

> **一个常见困惑**：`psycopg3` 默认 `autocommit=False`，但 `with connect(...)` 会在退出时提交。所以「只读查询后自动提交」是没问题的，而「批量写操作想在中间失败就整体回滚」也正是 `with` 块给的行为。

### 连接池

Web 服务里**每个请求都新建连接**是不可接受的——建立 TCP + 认证开销很大，还会打满 `max_connections`。

```python
from psycopg_pool import ConnectionPool

# 全局建一个池，应用启动时创建，生命周期内复用
pool = ConnectionPool(
    conninfo=DSN,
    min_size=2,
    max_size=10,
    open=True,          # 立即预热
    timeout=5.0,        # 取连接最多等 5 秒
)

with pool.connection() as conn:          # 借一个连接
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM students")
        print(cur.fetchone())
      
pool.close()
```

其中，`min_size` 是常驻连接数，池子建好就先开这么多条，低峰期也有热连接可用，第一个请求不用等握手。

而`max_size` 是上限，借出的连接到这个数之后，后来的请求就在池里排队（等够 `timeout` 还拿不到就抛异常）。这个值要跟数据库的 `max_connections` 一起算，别让池子把库打满。

**泄漏**算是最常见的问题：借了连接忘了还，池子被慢慢耗干，最后整个服务卡在取连接上。所以用 `with pool.connection()` 而不是手动 `getconn()` / `putconn()`——`with` 保证异常时也会归还。

---

## SQLAlchemy 入门

### sqlalchemy介绍

SQLAlchemy 是面向python的数据库工具集与对象关系映射组件（即ORM），它里面包含了两层东西：

```
┌──────────────────────────────────────────────┐
│ ORM：把Python类映射成表                        │
│   session.add(Student(name="张三"))           │
│   session.query / select(Student).where(...) │
├──────────────────────────────────────────────┤
│ Core：用Python表达式构造SQL                    │
│   select(students.c.name)					   |
|	.where(students.c.id == 1)  			   │
├──────────────────────────────────────────────┤
│ Dialect + Driver：真正发SQL的地方              │
│   postgresql+psycopg://  →  psycopg          │
└──────────────────────────────────────────────┘
```

- **Core** 帮你用 Python 对象拼 SQL，天然防注入，还能跨数据库方言（同一段代码在不同数据库上都能用）
- **ORM** 则更进一步：你负责操作python对象，它帮你生成SQL、跟踪对象状态、和在 `commit` 时统一落库

> **绝大多数人真正要的是ORM，但它建立在 Core 之上。** 只有理解这个分层，才不会在"为什么 `session.commit()` 才生效"以及什么是直接从sqlalchemy中直接导入而什么要从.orm中导入这种问题上卡住

### 安装

```bash
pip install "sqlalchemy>=2.0" "psycopg[binary]"
```

```python
from sqlalchemy import create_engine

#数据库方言+驱动://用户:密码@主机:端口/数据库
URL = "postgresql+psycopg://course:course@127.0.0.1:5432/lanshan_course"

engine = create_engine(
    URL,
    echo=False,       # 改成 True 会打印所有生成的 SQL，不熟悉时强烈建议打开
    pool_size=5,      # 允许连接池活跃的连接数
    max_overflow=10,      # 允许额外连接池的个数
    pool_pre_ping=True,   # 取连接前先ping，避免用到已被服务端断开的连接
)
```

**`psycopg` 这个驱动名一定要写。** 不写的话 SQLAlchemy 会按默认驱动选，但默认驱动可能与你所装的不一致从而导致莫名其妙的bug

### 定义模型（表）

```python
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import String, SmallInteger, Date, DateTime, ForeignKey, Numeric, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship

class Base(DeclarativeBase):
    """所有模型的基类"""
    pass

class Class(Base):
    __tablename__ = "classes"
  
    # Mapped在py层面，作为类型注解, 而mapped_column用在数据库层面，返回一个数据库对象
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(50), unique=True)
    grade: Mapped[int] = mapped_column(SmallInteger)
    # server_default表示在数据库端设置默认值，func.now()可以让插入记录时数据库自动填入当前时间戳（带时分秒）
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # 一对多：一个班可有多个学生
    students: Mapped[list["Student"]] = relationship(back_populates="myclass")

    def __repr__(self) -> str:
        return f"<Class {self.name}>"

class Student(Base):
    __tablename__ = "students"

    id: Mapped[int] = mapped_column(primary_key=True)
    student_no: Mapped[str] = mapped_column(String(20), unique=True)
    name: Mapped[str] = mapped_column(String(50))
    gender: Mapped[str] = mapped_column(String(1))
    birth_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    class_id: Mapped[int | None] = mapped_column(
        ForeignKey("classes.id", ondelete="SET NULL"), nullable=True
    )
    email: Mapped[str | None] = mapped_column(String(100), unique=True, nullable=True)

    myclass: Mapped["Class | None"] = relationship(back_populates="students")
    scores: Mapped[list["Score"]] = relationship(
        back_populates="student", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<Student {self.student_no} {self.name}>"


class Course(Base):
    __tablename__ = "courses"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(20), unique=True)
    name: Mapped[str] = mapped_column(String(100))
    credit: Mapped[Decimal] = mapped_column(Numeric(3, 1))

    scores: Mapped[list["Score"]] = relationship(back_populates="course")


class Score(Base):
    __tablename__ = "scores"

    id: Mapped[int] = mapped_column(primary_key=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id", ondelete="CASCADE"))
    course_id: Mapped[int] = mapped_column(ForeignKey("courses.id", ondelete="CASCADE"))
    score: Mapped[Decimal | None] = mapped_column(Numeric(5, 2), nullable=True)
    # func.current_date()：数据库自动填入纯日期（没有时分秒）
    exam_date: Mapped[date] = mapped_column(Date, server_default=func.current_date())

    student: Mapped["Student"] = relationship(back_populates="scores")
    course: Mapped["Course"] = relationship(back_populates="scores")
```

关于类型注解和列的对应关系，大家看几个例子就熟了：

- `Mapped[int]` → `INTEGER NOT NULL`，非空整数
- `Mapped[int | None]` → 可空整数，`| None` 就是"这列允许 NULL"
- `Mapped[str]` → `VARCHAR`，**记得在 `mapped_column` 里给出长度**（`String(50)`）
- `Mapped[Decimal]` → `NUMERIC`，配合 `Numeric(5, 2)` 指定精度
- `Mapped[datetime]` → `TIMESTAMP`；想要带时区就写 `DateTime(timezone=True)`，对应 `TIMESTAMPTZ`

关于ORM中的外键

> SQLAlchemy 从 `Mapped[...]` 里**自动推导是否可空**，`| None` 就是可空。这也是 2.0 相比 1.x 最大的体验提升

### 建表与删表

```python
# 让 SQLAlchemy 根据模型创建表（已存在的表会跳过）
Base.metadata.create_all(engine)

# 删除所有表
Base.metadata.drop_all(engine)
```

> **生产环境不要用 `create_all` 做结构变更。** 它并不会帮你改列、加约束。真实项目可以用 **Alembic** 做版本化迁移：
>
> ```bash
> pip install alembic
> alembic init migrations      # 生成迁移目录
> alembic revision --autogenerate -m "add email to students"
> alembic upgrade head         # 应用到数据库
> ```

### Session

`Session` 相当于"内存里的一块缓存 + 一个待执行队列"。你对对象的修改先记在 Session 里，`commit()` 时才翻译成 SQL 发出去。

```python
from sqlalchemy.orm import Session

# 两种创建Session的方法
# 1.上下文管理器（推荐）
with Session(engine) as session:
    stu = Student(student_no="2024100", name="王五", gender="M", class_id=1)
    session.add(stu)
    session.commit()
    print(stu.id)         # commit 后主键才被填充

# 2.sessionmaker 工厂
from sqlalchemy.orm import sessionmaker
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False)
```

**一次完整的增删改查**：

```python
with Session(engine) as session:
    # ---------- 增 Create ----------
    s = Student(student_no="2024101", name="赵六", gender="F", class_id=1)
    session.add(s)
    session.add_all([
        Score(student=s, course_id=1, score=95),
        Score(student=s, course_id=2, score=88),
    ])
    session.commit()                    # 一次事务写入三行

    # ---------- 查 Read ----------
    from sqlalchemy import select

    stmt = (
        select(Student)
        .where(Student.class_id == 1)
        .order_by(Student.student_no)
        .limit(10)
    )
    students = session.scalars(stmt).all()    # list[Student]
    # 等价于students = session.execute(stmt).scalars().all()

    # 只取单列
    names = session.scalars(select(Student.name)).all()

    # 取单个对象：拿不到返回 None
    one = session.scalar(select(Student).where(Student.student_no == "2024101"))
  
    # 通过别名查找
    stmt = (
    	select(
    		("班级:" + Student.myclass).label("cls"), 
    		Student.name, 
    		Student.scores
    	)
    	.order_by(Student.student_no)
    	.limit(10)
    )
    for row in session.execute(engine):
    	print(row.cls, row.name)

    # 取一个必定存在的对象，否则抛异常
    from sqlalchemy import exc
    one = session.get(Student, 1)               # 按主键查，优先走缓存

    # ---------- 改 Update ----------
    one.name = "赵六_改"
    session.commit()                            # 检测到对象被修改，自动UPDATE

    # ---------- 删 Delete ----------
    session.delete(one)
    session.commit()
```

### 查询进阶

```python
from sqlalchemy import select, func, and_, or_, desc

# 聚合
stmt = (
    select(
        Course.name,
        func.count(Score.id).label("选课人次"),
        func.round(func.avg(Score.score), 2).label("平均分"),
    )
    .join(Score, Score.course_id == Course.id)
    .group_by(Course.id, Course.name)
    .having(func.avg(Score.score) < 75)
    .order_by(desc("平均分"))
)
for row in session.execute(stmt):
    print(row.name, row.选课人次, row.平均分)

# 条件组合
stmt = select(Student).where(
    and_(
        Student.gender == "F",
        or_(Student.class_id == 1, Student.class_id == 2),
    )
)

# IN / LIKE / NULL
select(Student).where(Student.class_id.in_([1, 2, 3]))
select(Student).where(Student.name.like("张%"))
select(Student).where(Student.email.is_(None))

# 关联查询：relationship 让"取关联对象"变成属性访问
s = session.scalar(select(Student).where(Student.student_no == "2024001"))
print(s.myclass.name)                       # 触发一次懒加载查询
for sc in s.scores:                       # 再触发一次
    print(sc.course.name, sc.score)

# 一次性把关联数据也捞出来，避免N+1查询
from sqlalchemy.orm import selectinload
stmt = select(Student).options(selectinload(Student.scores)).limit(20)
for s in session.scalars(stmt):
    print(s.name, len(s.scores))          # 不会额外发 SQL
```

> 什么是**N+1 查询问题**：循环 100 个学生、每个学生访问 `s.scores` 发一次SQL，就是 1 + 100 = 101 次往返。通过`selectinload`（或 `joinedload`）预加载，能压回 1~2 次
>
> `lazy="select"`（默认懒加载）容易隐藏 N+1。**在应用代码里，凡是确定要用关联数据的地方，主动写 `selectinload`**

### Core

ORM 不是万能的。复杂报表、批量操作、数据库特有语法，写原生 SQL 更直接：

```python
from sqlalchemy import text

# 执行原生 SQL（参数通过用 :name 绑定，别拼字符串，防注入）
with engine.connect() as conn:
    result = conn.execute(
        text("SELECT name, score FROM scores JOIN students s ON s.id = scores.student_id "
             "WHERE score > :min_score ORDER BY score DESC"),
        {"min_score": 90},
    )
    for row in result:
        print(row.name, row.score)

# 用 Core 表达式拼 SQL（跨方言、可组合）
from sqlalchemy import Table, Column, Integer, String, MetaData, select

metadata = MetaData()
students_t = Table(
    "students", metadata,
    Column("id", Integer, primary_key=True),
    Column("student_no", String),
    Column("name", String),
)
stmt = select(students_t.c.student_no, students_t.c.name).where(
    students_t.c.name.like("张%")
)
with engine.connect() as conn:
    for row in conn.execute(stmt):
        print(row)
```

## 课后练习

**Level 0**：
• 能看懂并自己试着敲一遍`schema.sql` 和 `seed.sql`，跑通建表与插数据后用 `psql` 相关命令试着确认表结构
• 能够通过python连接并操作数据库，可以通过sqlalchemy用py代码实现简单的CRUD

**Level 1**：
• 能自己编写sql实现你能想象到的查表操作（比如将所有班级按某个科目的平均成绩进行排名等等）
• 同上，不过通过py操作数据库的方式实现

**Level 2**：
• 试着在前面实现的学生管理系统中加入psql并实现对应操作

---

## 参考资料

- **PostgreSQL 官方文档**：[https://www.postgresql.org/docs/current/](https://www.postgresql.org/docs/current/)
- **psycopg 3 官方文档**：[https://www.psycopg.org/psycopg3/docs/](https://www.psycopg.org/psycopg3/docs/)
- **SQLAlchemy 2.0 文档**：[https://docs.sqlalchemy.org/en/20/](https://docs.sqlalchemy.org/en/20/)
- **SQLAlchemy ORM 快速入门**：[https://docs.sqlalchemy.org/en/20/orm/quickstart.html](https://docs.sqlalchemy.org/en/20/orm/quickstart.html)

---

## psql 相关元命令

**库、表、索引**

- `\l`：列出所有数据库
- `\c dbname`：切换到指定数据库
- `\dt`：列出当前库所有表
- `\dt+`：带大小、描述的表列表
- `\d tablename`：查看表结构（列、类型、约束）
- `\d+ tablename`：表结构 + 存储信息 + 描述
- `\di`：列出索引
- `\dv`：列出视图
- `\dn`：列出模式（schema）
- `\df`：列出函数
- `\du` 或`\dg`：列出角色 / 用户

**执行与调试**

- `\timing`：开关执行耗时统计（写作业时建议打开）
- `\x`：切换扩展显示模式（宽表更好读）
- `\e`：用编辑器写长 SQL
- `\i file.sql`：执行 SQL 文件
- `\copy ...`：客户端侧导入导出 CSV
- `\h SELECT`：查看 SQL 语法帮助
- `\?`：查看所有元命令帮助

**退出**：`\q`。

常用启动参数：

```bash
psql -h 127.0.0.1 -p 5432 -U course -d lanshan_course   # 完整连接
psql -U course -d lanshan_course -c "SELECT 1;"          # 执行一条命令后退出
psql -U course -d lanshan_course -f sql/01_schema.sql    # 执行文件后退出
psql -U course -d lanshan_course -At -c "SELECT version();"  # 无对齐、无表头，适合脚本
```
