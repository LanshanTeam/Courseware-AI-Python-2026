-- ---------- 1. 班级表 ----------
CREATE TABLE classes (
    id         SERIAL PRIMARY KEY,                     -- 自增主键
    name       VARCHAR(50)  NOT NULL UNIQUE,           -- 班级名，唯一
    grade      SMALLINT     NOT NULL                   -- 年级 1~4
               CHECK (grade BETWEEN 1 AND 4),
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON TABLE  classes      IS '班级';
COMMENT ON COLUMN classes.name IS '班级名称，如 计科2401';
COMMENT ON COLUMN classes.grade IS '年级：1=大一 2=大二 3=大三 4=大四';


-- ---------- 2. 学生表 ----------
CREATE TABLE students (
    id         SERIAL PRIMARY KEY,
    student_no VARCHAR(20)  NOT NULL UNIQUE,           -- 学号
    name       VARCHAR(50)  NOT NULL,
    gender     CHAR(1)      NOT NULL CHECK (gender IN ('M', 'F')),
    birth_date DATE,
    -- 外键指向班级；班级被删时把该学生的 class_id 置空（关系可断开，学生不随之消失）
    class_id   INTEGER      REFERENCES classes (id) ON DELETE SET NULL,
    email      VARCHAR(100) UNIQUE,                    -- 可为空，且允许任意多个 NULL
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

COMMENT ON COLUMN students.class_id IS '所属班级，NULL 表示借读/未分班';


-- ---------- 3. 课程表 ----------
CREATE TABLE courses (
    id     SERIAL PRIMARY KEY,
    code   VARCHAR(20)  NOT NULL UNIQUE,               -- 课程代码
    name   VARCHAR(100) NOT NULL,
    credit NUMERIC(3, 1) NOT NULL                      -- 学分，精确小数，不用 float
           CHECK (credit > 0 AND credit <= 10)
);


-- ---------- 4. 成绩表（学生与课程的多对多中间表）----------
CREATE TABLE scores (
    id         SERIAL PRIMARY KEY,
    -- 学生被删则该生成绩一并删除
    student_id INTEGER      NOT NULL REFERENCES students (id) ON DELETE CASCADE,
    course_id  INTEGER      NOT NULL REFERENCES courses  (id) ON DELETE CASCADE,
    score      NUMERIC(5, 2) CHECK (score BETWEEN 0 AND 100),   -- 允许 NULL 表示缺考
    exam_date  DATE         NOT NULL DEFAULT CURRENT_DATE,
    -- 同一学生、同一课程、同一天只能有一条成绩
    UNIQUE (student_id, course_id, exam_date)
);

COMMENT ON COLUMN scores.score    IS '成绩，NULL 表示缺考';
COMMENT ON COLUMN scores.exam_date IS '考试日期';


-- ---------- 5. 索引 ----------
-- 主键已自动建索引；这里为高频外键列补索引，加速 JOIN
CREATE INDEX idx_students_class  ON students (class_id);
CREATE INDEX idx_scores_student  ON scores   (student_id);
CREATE INDEX idx_scores_course   ON scores   (course_id);
-- 支持「查某门课 90 分以上」这类按分数倒序的查询
CREATE INDEX idx_scores_score    ON scores   (score DESC);
-- 支持按姓名前缀搜索
CREATE INDEX idx_students_name   ON students (name);


-- ---------- 6. 视图：学生成绩汇总报表 ----------
CREATE OR REPLACE VIEW v_student_report AS
SELECT
    s.id                                     AS student_id,
    s.student_no                             AS 学号,
    s.name                                   AS 姓名,
    COALESCE(cl.name, '未分班')              AS 班级,
    COUNT(sc.id)                             AS 成绩条数,
    ROUND(AVG(sc.score), 2)                  AS 平均分,
    MAX(sc.score)                            AS 最高分,
    MIN(sc.score)                            AS 最低分
FROM students      AS s
LEFT JOIN classes  AS cl ON cl.id = s.class_id
LEFT JOIN scores   AS sc ON sc.student_id = s.id
GROUP BY s.id, s.student_no, s.name, cl.name;

COMMENT ON VIEW v_student_report IS '学生成绩汇总（含无成绩学生，平均分列为 NULL）';

