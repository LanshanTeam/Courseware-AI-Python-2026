"""
models.py —— SQLAlchemy ORM 模型
"""

from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    Date,
    DateTime,
    ForeignKey,
    Numeric,
    SmallInteger,
    String,
    func,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    """所有 ORM 模型的基类"""


# -------------------------------------------------- 班级
class Class(Base):
    __tablename__ = "classes"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(50), unique=True)
    grade: Mapped[int] = mapped_column(SmallInteger)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # 一对多（反向）：一个班级对应多个学生
    students: Mapped[list["Student"]] = relationship(back_populates="klass")

    def __repr__(self) -> str:
        return f"<Class id={self.id} name={self.name!r} grade={self.grade}>"


# --------------------------------------------------- 学生
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
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # 多对一（正向）：多名学生属于同一个班级
    klass: Mapped["Class | None"] = relationship(back_populates="students")
    # 一对多：一名学生有多条成绩；cascade 让「删学生」自动删掉他的成绩
    scores: Mapped[list["Score"]] = relationship(
        back_populates="student",
        cascade="all, delete-orphan",
        passive_deletes=True,   # 交给数据库的 ON DELETE CASCADE 处理，减少往返
    )

    def __repr__(self) -> str:
        return f"<Student id={self.id} no={self.student_no!r} name={self.name!r}>"


# -------------------------------------------- 课程
class Course(Base):
    __tablename__ = "courses"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(20), unique=True)
    name: Mapped[str] = mapped_column(String(100))
    credit: Mapped[Decimal] = mapped_column(Numeric(3, 1))

    scores: Mapped[list["Score"]] = relationship(back_populates="course")

    def __repr__(self) -> str:
        return f"<Course id={self.id} code={self.code!r} name={self.name!r}>"


# --------------------------------------------- 成绩
class Score(Base):
    """学生与课程之间的多对多中间表"""

    __tablename__ = "scores"

    id: Mapped[int] = mapped_column(primary_key=True)
    student_id: Mapped[int] = mapped_column(
        ForeignKey("students.id", ondelete="CASCADE")
    )
    course_id: Mapped[int] = mapped_column(
        ForeignKey("courses.id", ondelete="CASCADE")
    )
    # 可为空 → 表示缺考
    score: Mapped[Decimal | None] = mapped_column(Numeric(5, 2), nullable=True)
    exam_date: Mapped[date] = mapped_column(Date, server_default=func.current_date())

    student: Mapped["Student"] = relationship(back_populates="scores")
    course: Mapped["Course"] = relationship(back_populates="scores")

    def __repr__(self) -> str:
        return (
            f"<Score student_id={self.student_id} "
            f"course_id={self.course_id} score={self.score}>"
        )
