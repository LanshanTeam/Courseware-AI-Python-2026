# Lesson 2 Python 包管理、面向对象与工程基础

本次课主要内容：课前准备（命令行与多文件程序），包管理与虚拟环境，项目工程结构，面向对象编程，文件与异常处理，课后作业。



面向对象是本课后半部分的重心，篇幅也最大。包管理和工程结构是为它服务的——先把代码装进一个规范的盒子里，才有地方放类。



---



## 课前准备



开始之前先确认两件事：上一课的函数与模块会写，前面的命令行操作没问题。本部分动手做一遍即可。



### 1\. 复习上一课：能独立运行一个多文件程序



上一课学了函数与模块，本次课直接建立在它之上。最低要求是这种结构能跑起来：



```Plain Text
mytools.py      # 里面定义 add(x, y)
main.py         # 里面 import mytools，调用 mytools.add(1, 2)
```



```Bash
python main.py
```



能跑通，基础就够了。



### 2\. 检查你的环境



上一课已经建好了虚拟环境并装过包，本次课要频繁在不同项目里切换环境，先确认手头这个环境还是对的：



```Bash
python -c "import sys; print(sys.version); print(sys.executable)"
```



会输出两行：Python 版本号，以及**当前解释器的路径**。第二行很重要——后面遇到"我明明装了包却导入不了"，第一件事就是看这个路径是不是你以为的那个环境。



如果命令行不太熟，回头翻一下上一课《课前准备》第 1 节的那张表，或者记住一条：**知道自己在哪个目录下**，就能避开大多数"找不到文件""导入失败"。



---



## Python 包管理



写代码免不了要用别人写好的包。这一部分解决三个问题：包装在哪里、怎么装、怎么让同学也能跑出一模一样的结果。



### 1\. 为什么必须用虚拟环境



先看一个真实会发生的场景：



```Plain Text
你的项目要用 requests 2.32
室友的项目要用 requests 2.25
全局 Python 只有一个包目录，只能留一个版本
```



谁先装谁赢，另一个人就得改代码。虚拟环境就是为了切断这种牵连：**每个项目一个独立的包目录**，互不干扰。



工具不强制统一，能完成“创建环境、装包、运行代码”即可。Python 自带的 venv 够用；创建和激活的命令上一课已经用过，这里补齐 CMD 终端的写法和验证方法：



```Bash
python -m venv .venv            # 创建：命令和上一课一样

# 激活：按你用的终端选一条
source .venv/bin/activate       # macOS / Linux
.venv\Scripts\Activate.ps1      # Windows PowerShell
.venv\Scripts\activate.bat      # Windows CMD

python -V                       # 激活后 python 指向环境内的解释器
deactivate                      # 退出
```



激活成功的标志是提示符前多了 `(.venv)`。不放心就再敲一次课前准备里那条自检命令，路径里应该能看到 `.venv`。



### 2\. 三种工具的定位



|**工具**|**是什么**|**什么时候用**|
|---|---|---|
|pip|Python 自带的包安装器|装纯 Python 包，任何环境里都能用|
|conda|跨语言的环境管理器，能装非 Python 的库|需要 CUDA、GDAL、ffmpeg 这类带底层依赖的库|
|uv|近年流行的包与项目管理工具，用 Rust 写成，速度快|新项目，或者想要一份可复现的锁文件|



选择很简单：要装的包都在 PyPI 上，用 pip 或 uv；要装的东西里有非 Python 组件，用 conda。



#### pip



```Bash
python -m pip install requests             # 安装
python -m pip install "requests>=2.31"     # 指定版本下限
python -m pip install -r requirements.txt  # 按文件批量装
python -m pip list                         # 查看已安装的包
python -m pip show requests                # 查看某个包的详情
python -m pip uninstall requests           # 卸载
python -m pip freeze > requirements.txt    # 导出当前环境
```



建议写成 `python -m pip` 而不是直接敲 `pip`。机器上装了多个 Python 时，`pip` 这个名字可能指向另一个解释器，从而出现"装了却导不进来"。`python -m pip` 强制用当前解释器执行，和 `python main.py` 用的是同一个环境。



#### conda



```Bash
conda create -n myproj python=3.11    # 创建环境
conda activate myproj                 # 激活
conda install numpy pandas            # 安装包
conda list                            # 查看已安装的包
conda deactivate
conda env remove -n myproj            # 删除环境
```



不要把学习用的包装进 `base` 环境。`base` 是 conda 自己所在的环境，装乱了可能导致 conda 本身出问题，永远新建一个环境。



conda 的依赖求解偶尔会慢。从 conda 23\.10 起，默认求解器已经换成 libmamba（和 mamba 用的是同一个引擎），正常情况下不会像老版本那样卡住。真遇到很慢，先确认求解器：



```Bash
conda config --show solver            # 应当显示 solver: libmamba
conda config --set solver libmamba    # 如果不是，手动切过来

# 也可以改用 mamba：命令和 conda 几乎一样，下载安装更快
conda install -n base -c conda-forge mamba
mamba install numpy
```

（把 `mamba` 装进 `base` 是官方推荐的做法：它本身是环境管理工具，不是某个项目的依赖。除此之外的包仍应装在新建的环境里。）



#### uv



```Bash
uv init myproj          # 初始化项目，生成 pyproject.toml 等文件
cd myproj
uv add requests         # 添加依赖
uv run python main.py   # 在环境中运行脚本，无需手动激活
```



uv 的特点是省事：下载解释器、建环境、装包合并成一条命令，并且不需要 activate。



### 3\. 依赖声明：requirements\.txt 与 pyproject\.toml



装完包，怎么让同学也装出一样的环境？有两种写法。



**requirements\.txt**：一行一个包，简单直白。



```Plain Text
requests>=2.31
flask==3.0.0
```



```Bash
python -m pip install -r requirements.txt
```



**pyproject\.toml**：现代项目标准，能同时记录项目信息和依赖，还能把"运行依赖"和"开发依赖"分开：



```TOML
[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[project]
name = "student-manager"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "requests>=2.31",
]

[dependency-groups]
dev = [
    "pytest>=8.0",
]
```



两种文件都可以用，小脚本用 requirements\.txt 就行。不过要把项目本身装进环境（**pip install \-e \.**），打包信息只能写在 pyproject\.toml 里，那就必须用它。



有个坑要注意：`pip freeze` 导出的是**整个环境**的包，包括你没直接用的间接依赖（比如 `certifi`、`charset-normalizer`）。这不算错，但文件会比较长。想要干净，就自己手写只含直接依赖的 requirements\.txt。



### 4\. 依赖版本与镜像源



版本约束的几种写法：



|写法|含义|
|---|---|
|`requests`|任意版本，不可复现|
|`requests>=2.31`|不低于 2\.31|
|`requests==2.32.3`|精确锁定某个版本|
|`requests>=2.31,<3.0`|区间，防止大版本破坏性更新|



日常用 `>=` 加下限就行；要给别人复现你的环境时，用 `==` 锁定。



如果用的是 uv，它会自动生成一个 `uv.lock` 文件，里面记录了每个包的精确版本。这个文件要提交到 Git，不要手改——它的作用就是保证你和同学跑出完全相同的结果。



#### 配置国内镜像源



默认的 PyPI 在国外，下载慢，换成国内镜像会快很多。



```Bash
# 一次性配置（推荐）
python -m pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/
python -m pip config list          # 验证

# 或者临时指定，只影响这一条命令
python -m pip install requests -i https://pypi.tuna.tsinghua.edu.cn/simple
```



常用的几个镜像站：



|**镜像站**|**地址**|
|---|---|
|阿里云|**https://mirrors\.aliyun\.com/pypi/simple/**|
|腾讯云|**https://mirrors\.cloud\.tencent\.com/pypi/simple/**|
|中科大|**https://pypi\.mirrors\.ustc\.edu\.cn/simple/**|
|上海交大|**https://mirror\.sjtu\.edu\.cn/pypi/web/simple**|
|南京大学|**https://mirror\.nju\.edu\.cn/pypi/web/simple**|
|清华 TUNA|**https://pypi\.tuna\.tsinghua\.edu\.cn/simple**|



需要提醒一点：**镜像站的状态是会变的**。网上很多老教程推荐的豆瓣源、网易源，现在已经连不上了，照抄反而会卡住。所以上面这几个地址也不是永久有效的，遇到超时可以换一个试试。配两个备用比较稳妥。



---



## 项目工程结构



上一课结尾提过项目的目录组织。这一部分把它讲清楚：代码该放哪，模块之间怎么互相引用。



### 1\. 从"一坨文件"到"一个项目"



上一课的作业大概是这样的：



```Plain Text
学生管理系统/
├── main.py
├── student.py
├── utils.py
├── students.json
└── test.py
```



能用，但有三个问题：数据文件和代码混在一起；没有依赖声明，换台电脑跑不起来；文件一多就分不清谁是谁。



整理之后（作业就按这个结构做）：



```Plain Text
student-manager/
    ├── .venv/                 # 虚拟环境，不进 Git
    ├── .gitignore
    ├── README.md
    ├── pyproject.toml         # 依赖声明与打包配置（也可只用 requirements.txt）
    ├── data/
    │   └── students.json      # 数据与代码分开放
    ├── src/
    │   └── student_manager/   # 真正的包
    │       ├── __init__.py
    │       ├── models.py      # 类定义
    │       ├── repository.py  # 数据存取
    │       ├── exceptions.py  # 自定义异常
    │       └── cli.py         # 命令行入口
    └── tests/
        └── test_models.py
```



`.gitignore` 至少写这几行：



```Plain Text
.venv/
__pycache__/
*.pyc
```



### 2\. **\_\_init\_\_**\.py 的作用



`__init__.py` 的作用是标记这个文件夹是一个 **Python 包**。Python 3\.3 之后严格来说不是必需的，但建议还是加上——它能让目录成为常规包，导入行为更可预期，也能在里面统一暴露对外的接口。



```Python
# src/student_manager/__init__.py
"""学生信息管理系统。"""

from .models import Person, Student

__version__ = "0.1.0"
```



这样别人可以写 `from student_manager import Student`，而不用关心内部文件是怎么拆的。



不要在 `__init__.py` 里写业务逻辑或者 `print`。那会导致"仅仅导入一下，程序就开始跑"，是很难排查的问题。



### 3\. 绝对导入与相对导入



导入有两种写法：



```Python
from student_manager.models import Student   # 绝对导入：从顶层包写起
from .models import Student                  # 相对导入：. 代表当前包
```



相对导入里，一个点 `.` 表示当前包，两个点 `..` 表示上一级包。



**什么时候用哪个**，记住两条就够：



- **包内部**的模块互相引用，用相对导入 `from .models import Student`；

- **包外部**（根目录的脚本、tests 里的测试），用绝对导入 `from student_manager.models import Student`。

    

如果用错了，会碰到这个报错：



```Plain Text
ImportError: attempted relative import with no known parent package
```



原因是直接运行了一个含有相对导入的文件，比如 `python src/student_manager/cli.py`。这时它被当成一个孤立的脚本，没有"父包"可言，相对导入自然无从谈起。



实际项目里不会去手动改搜索路径，而是先把项目装进当前环境，再以模块方式运行：



```Bash
pip install -e .                  # 在项目根目录装上，之后 src/ 里的包就能被找到
python -m student_manager.cli     # 以模块方式运行，不带 .py 后缀
```



注意这里点的用法：`-m` 后面写的是"包\.模块"，不带 `.py` 后缀。



至于为什么要把源码放在 **src/** 目录下：这样源码默认不在 Python 的搜索路径里，只有显式装进环境（上面那条 **pip install \-e \.**）之后才能被导入，你就不会“不小心”用到还没装好的代码。测试能过，装到别人机器上就也能过。



顺带一提，不要用 `sys.path.append()` 去解决导入问题。它只是把路径临时塞进去，掩盖了结构上的毛病，换个运行目录就又坏了。



---



## 面向对象编程



前面的内容都在给代码"找地方放"。现在开始讲放进去的是什么。



### 1\. 从"字典堆"到"类"



先回顾一下上一课的写法：



```Python
def add_student(students: list[dict], sid: str, name: str, age: int) -> None:
    students.append({"sid": sid, "name": name, "age": age})


def find_student(students: list[dict], sid: str) -> dict | None:
    for s in students:
        if s["sid"] == sid:
            return s
    return None
```



能跑。但假设需求变了：



1. 现在学生分本科生和研究生，研究生多一个"导师"字段；

2. 现在年龄必须是 0–150 的整数，非法数据要拒绝；

3. 现在数据要存成 JSON，将来可能存数据库。

    

用字典的写法，这三个改动会散落到每一个函数里，每处都得改。



问题的根源是：`{"sid": ..., "name": ..., "age": ...}` 是**裸数据**，任何代码都能往里塞 `age = "abc"`，没人管得住。类则是在这份数据外面装了一道门：



```Python
class Student:
    def __init__(self, sid, name, age):
        self.sid = sid
        self.name = name
        self.set_age(age)      # 走校验入口

    def set_age(self, age):
        if not isinstance(age, int) or not 0 < age < 150:
            raise ValueError("年龄必须是 0-150 的整数")
        self.age = age
```



这就是面向对象最核心的动机——**把数据和操作数据的方法绑在一起，并且只留下一个受控的入口**。



### 2\. 类与对象



**类**是对象的模板，定义了对象有哪些属性和方法；**对象**是类的具体实例。类与对象的关系，就像模具与产品。



定义类的语法：



```Python
class Student:
    def __init__(self, sid, name, age):
        self.sid = sid        # 实例属性
        self.name = name
        self.age = age

    def describe(self):
        return f"{self.name}（{self.sid}），{self.age} 岁"

s1 = Student("20250001", "张三", 18)
s2 = Student("20250002", "李四", 19)
print(s1.describe())     # 张三（20250001），18 岁
print(s2.describe())     # 李四（20250002），19 岁
```



要点：



- `__init__` 是构造方法，创建对象时自动调用，用于初始化属性；

- `self` 代表对象本身，通过 `self.xxx` 定义和访问实例属性；

- 实例方法第一个参数必须是 `self`。

    

`self` **不是关键字**，只是第一个参数的约定俗成名。它代表"调用这个方法的那个对象"：



```Python
s1.describe()
# 等价于
Student.describe(s1)
```



理解这一点，后面 `@classmethod` 里的 `cls` 就顺理成章了。



### 3\. 实例属性与类属性



属性分两类：



- **实例属性**：属于具体对象，在 `__init__` 里通过 `self.xxx` 定义，每个对象可以有不同的值；

- **类属性**：属于类本身，被所有实例共享，直接写在类内。

    

```Python
class Student:
    school = "重庆邮电大学"    # 类属性，所有实例共享

    def __init__(self, name):
        self.name = name      # 实例属性，每个对象各自拥有

s1 = Student("张三")
s2 = Student("李四")
print(s1.school, s2.school)   # 重庆邮电大学 重庆邮电大学
print(Student.school)         # 通过类名访问更清晰
print(s1.name, s2.name)       # 张三 李四
```



#### 一个常见的错误



如果你想让类属性计数：



```Python
class Student:
    count = 0

    def __init__(self, name):
        self.name = name
        Student.count += 1     # 注意：写 Student.count，不要写 self.count
```



如果写成 `self.count += 1`，结果会一直是 0。因为这行等价于 `self.count = self.count + 1`，它会**新建一个实例属性** `count`，把同名的类属性遮住。之后 `Student.count` 永远不变。



规则就一句：**读类属性 `self.x` 和 `类名.x` 都行，写类属性一律用 `类名.x`。**



### 4\. 封装



**封装**指把属性和操作属性的方法捆绑在类内部，并隐藏内部细节。Python 没有 `private` 关键字，靠命名约定来区分：



|写法|名称|含义|
|---|---|---|
|`self.name`|公有|谁都可以访问|
|`self._sid`|受保护|内部使用，约定上不该从外面碰|
|`self.__score`|私有|外部不能直接访问，只能通过类提供的公有方法操作|



外部要读写私有属性，就通过类提供的公有方法。这样做的好处是可以在读写时做校验：



```Python
class Student:
    def __init__(self, sid, name):
        self._sid = sid          # 受保护
        self.name = name
        self.__score = 0         # 私有

    def get_score(self):         # 公有方法：读取私有属性
        return self.__score

    def set_score(self, value):  # 公有方法：修改私有属性，可做校验
        if not 0 <= value <= 100:
            raise ValueError(f"成绩必须在 0-100，收到 {value}")
        self.__score = value

s = Student("20250001", "张三")
s.set_score(95)
print(s.get_score())      # 95
s.set_score(150)          # ValueError: 成绩必须在 0-100，收到 150
```



不过 `get_score` / `set_score` 这种写法和 Java 类似，Python 里更常用 `@property` 装饰器，让调用方直接用属性语法，背后仍然走校验：



```Python
class Student:
    def __init__(self, sid, name):
        self._sid = sid
        self.name = name
        self.__score = 0

    @property
    def score(self):
        return self.__score

    @score.setter
    def score(self, value):
        if not 0 <= value <= 100:
            raise ValueError(f"成绩必须在 0-100，收到 {value}")
        self.__score = value

s = Student("20250001", "张三")
s.score = 95
print(s.score)          # 95
s.score = 150           # ValueError
```



好处是**外部接口更自然**：调用方写 `s.score = 95`，而不是 `s.set_score(95)`。



还有个小用法：只写 `@property` 不写 `@score.setter`，这个属性就是只读的，外部赋值会报 `AttributeError`。



不建议一上来就给每个属性都套上 getter/setter。先用普通的公有属性，等到真的需要校验了再改成 `@property` 就行——这样调用方的代码一行都不用改。



### 5\. 继承



**继承**允许子类复用父类的属性和方法，并在此基础上添加自己的新特性，避免重复代码。



```Python
class Person:
    def __init__(self, sid, name, age):
        self._sid = sid
        self.name = name
        self.age = age

    def describe(self):
        return f"{self.name}（{self.age}岁）"


class Student(Person):                       # Student 继承 Person
    def __init__(self, sid, name, age, major="未定"):
        super().__init__(sid, name, age)     # 调用父类构造方法
        self.major = major                   # 子类新增属性

    def describe(self):                      # 重写（override）父类方法
        return f"学生 {self.name}，专业 {self.major}"


class Teacher(Person):
    def __init__(self, sid, name, age, title="讲师"):
        super().__init__(sid, name, age)
        self.title = title

    def describe(self):
        return f"教师 {self.name}，职称 {self.title}"
```



要点：



- 子类自动拥有父类的属性和方法，可以直接使用；

- 子类可以添加自己的属性和方法；

- 子类可以重写（override）父类的同名方法；

- 子类必须在 `__init__` 里调用 `super().__init__(...)`，下面单独说为什么。

    

#### super\(\) 不能省



上面例子里 `Student.__init__` 的第一行就是 `super().__init__(sid, name, age)`，这不是可选的：



```Python
class Bad(Person):
    def __init__(self, sid, name, age, major="未定"):
        self.major = major           # 漏了 super().__init__
```



这样写，`self.name`、`self.age` 全都不存在，后面一用就报 `AttributeError`。



继承的本质是"父类的初始化工作你也要做一遍"，`super().__init__(...)` 就是这个动作。子类只负责自己新增的那部分属性（上面的 `major`），父类负责的那部分（`name`、`age`）要交给父类去做。



#### 多继承



Python 允许一个子类继承多个父类：



```Python
class A:
    def greet(self): return "A"

class B(A):
    def greet(self): return "B"

class C(A):
    def greet(self): return "C"

class D(B, C):
    pass

print(D().greet())    # B
```



同名方法按 `D.__mro__` 的顺序查找。多继承容易产生歧义，实际开发中很少用。需要复用好几个类的能力时，优先考虑把其中一个作为属性持有（组合），或者用只提供方法、不定义 `__init__` 的混入类。



### 6\. 多态



**多态**指同一个方法调用，针对不同类型的对象表现出不同的行为。上面 `Student` 和 `Teacher` 都重写了 `describe()`，于是：



```Python
people = [
    Student("20250001", "张三", 18, "计算机"),
    Teacher("T001", "李老师", 40, "教授"),
]

for p in people:
    print(p.describe())
```



输出：



```Plain Text
学生 张三，专业 计算机
教师 李老师，职称 教授
```



多态的关键在于：调用方（这个 for 循环）只依赖父类定义的统一接口 `describe()`，不关心传入的究竟是哪个子类。以后新增 `Staff`、`Alumni` 等子类，这个循环一行都不用改。



#### 用抽象基类把接口钉死



上面的写法有个隐患：如果某个子类忘了写 `describe()`，代码会悄悄走父类的实现，不报错。可以用抽象基类强制子类必须实现：



```Python
from abc import ABC, abstractmethod

class Person(ABC):
    def __init__(self, sid, name, age):
        self._sid = sid
        self.name = name
        self.age = age

    @abstractmethod
    def describe(self):
        """子类必须实现。"""
        ...
```



这样 `Person` 本身不能被实例化，子类漏实现方法也会立刻报错，问题暴露得更早。



```Python
Person("x", "y", 18)
# TypeError: Can't instantiate abstract class Person
#            without an implementation for abstract method 'describe'
```

（Python 3.11 的措辞略有不同，末尾是 `with abstract method describe`；3.12 起改成了上面这种写法。）



#### 什么时候还是得判断类型



多态的初衷就是**让调用方不用判断类型**。但有时候确实需要知道手头这个对象是哪一类，用 `isinstance`：



```Python
s = Student("20250001", "张三", 18, "计算机")
print(isinstance(s, Student))      # True
print(isinstance(s, Person))       # True，子类实例也是父类实例
```



注意第二行：`Student` 的实例同时也是 `Person` 的实例，`isinstance` 会考虑继承关系。所以判断"是不是某类"时优先用它，别用 `type(s) is Person`——后者对子类会返回 `False`。



不过还是那句话：**如果代码里出现了大段 `isinstance` 判断，多半说明该用多态了**。比如下面两种写法：



```Python
# 不好：每加一个子类都要改这里
def describe_all(people):
    for p in people:
        if isinstance(p, Student):
            print(f"学生 {p.name}")
        elif isinstance(p, Teacher):
            print(f"教师 {p.name}")

# 好：交给对象自己决定，新增子类不用改
def describe_all(people):
    for p in people:
        print(p.describe())
```



### 7\. 类方法



方法按操作对象的不同分两类：



- **实例方法**：第一个参数是 `self`，操作实例属性，日常最常用；

- **类方法**：用 `@classmethod` 装饰，第一个参数是 `cls`，操作类属性。

    

```Python
class Student:
    count = 0

    def __init__(self, sid, name, age):
        self.sid = sid
        self.name = name
        self.age = age
        Student.count += 1

    def describe(self):                        # 实例方法
        return f"{self.name}，{self.age} 岁"

    @classmethod
    def from_csv_line(cls, line):              # 类方法
        sid, name, age = line.strip().split(",")
        return cls(sid, name, int(age))


s = Student.from_csv_line("20250001,张三,18")
print(s.describe())        # 张三，18 岁
print(Student.count)       # 1
```



类方法最典型的用途是**替代构造器**。上面的 `from_csv_line` 就是"从 CSV 的一行构造一个学生对象"，相比在外面写一个 `parse_student()` 函数，放进类里语义更清楚，也能跟着类一起被找到。



注意类方法里要用 `cls(...)` 而不是写死类名 `Student(...)`。原因是：如果以后有人继承了这个类，用 `cls` 才能返回正确的子类实例，写死类名就永远返回父类。



```Python
class GradStudent(Student):
    pass

g = GradStudent.from_csv_line("20250003,王五,24")
print(type(g).__name__)    # GradStudent（用了 cls）；写死 Student 的话这里会是 Student
```



### 8\. 常用魔术方法



魔术方法（dunder methods，前后各两个下划线）是"让自定义对象表现得像内置类型"的钩子。



#### **\_\_str\_\_** 与 **\_\_repr\_\_**



```Python
class Student:
    def __init__(self, sid, name):
        self.sid = sid
        self.name = name

    def __str__(self):                    # 给用户看：print() 时调用
        return f"{self.name}（{self.sid}）"

    def __repr__(self):                   # 给开发者看：调试、容器里显示时调用
        return f"Student(sid={self.sid!r}, name={self.name!r})"

s = Student("20250001", "张三")
print(s)           # 张三（20250001）
print(repr(s))     # Student(sid='20250001', name='张三')
print([s])         # [Student(sid='20250001', name='张三')]  列表里用 __repr__
```



两个方法的分工：`__str__` 面向使用者，写得好看就行；`__repr__` 面向开发者，应当尽量写清楚每个字段的值，调试时一眼能看出对象的状态。



写 `__repr__` 时字段用 `!r` 格式化（也就是 `repr()`），这样字符串会带上引号，`Student(sid='20250001')` 比 `Student(sid=20250001)` 更明确。



如果只愿意写一个，写 `__repr__`——没有 `__str__` 时，`print` 会退回去用 `__repr__`。



#### **\_\_eq\_\_**



默认情况下，两个对象比较的是"是不是同一个对象"。想要按内容比较，就定义 `__eq__`：



```Python
class Student:
    def __init__(self, sid, name):
        self.sid = sid
        self.name = name

    def __eq__(self, other):
        if not isinstance(other, Student):
            return NotImplemented
        return self.sid == other.sid     # 学号相同就算同一个人

print(Student("20250001", "张三") == Student("20250001", "张三三"))   # True
```



有个细节要注意：类型不对时返回 `NotImplemented`（不是 `False`），让 Python 去尝试对方的比较逻辑。



还有一个副作用要记住：**定义了 `__eq__` 之后，对象就不能放进集合或当字典的键了**，会报 `unhashable type`。如果确实需要，可以补一个 `__hash__`：



```Python
def __hash__(self):
    return hash(self.sid)
```



#### 更多魔术方法



魔术方法能让你的对象直接用 `len()`、`in`、`for` 这类内置语法：



```Python
class StudentBox:
    def __init__(self):
        self._data = {}

    def add(self, sid, name):             # 对外提供的入口，不直接碰内部字典
        self._data[sid] = {"name": name}

    def __len__(self):                    # len(box)
        return len(self._data)

    def __contains__(self, sid):          # "20250001" in box
        return sid in self._data

    def __iter__(self):                   # for s in box
        return iter(self._data.values())


box = StudentBox()
box.add("20250001", "张三")
print(len(box))                 # 1
print("20250001" in box)        # True
for s in box:                   # 可迭代
    print(s)
```



用到的几个：



|魔术方法|触发的语法|
|---|---|
|`__init__`|`Student(...)`|
|`__str__`|`print(obj)`、`str(obj)`|
|`__repr__`|`repr(obj)`、容器内显示|
|`__eq__`|`a == b`|
|`__hash__`|`hash(obj)`、放进 set 或当字典键|
|`__len__`|`len(obj)`|
|`__contains__`|`x in obj`|
|`__iter__`|`for x in obj`|
|`__enter__` / `__exit__`|`with obj:`|



不要滥用。`Vector.__add__` 表示向量相加很自然，`Student.__add__` 表示"两个学生相加"就很奇怪了。只有当运算符的含义对读者是显而易见的，才去重载它。



#### @dataclass



如果一个类主要是存数据，手写 `__init__` 和 `__repr__` 挺啰嗦的。`@dataclass` 装饰器能自动生成这些方法：



```Python
from dataclasses import dataclass, field

@dataclass
class Course:
    code: str
    name: str
    teacher: str = "待定"
    tags: list = field(default_factory=list)

c = Course("CS101", "程序设计")
print(c)     # Course(code='CS101', name='程序设计', teacher='待定', tags=[])
```



它会自动生成 `__init__`、`__repr__`、`__eq__`。



有个坑必须记住：**可变类型的默认值要用 `field(default_factory=...)`**。



```Python
@dataclass
class Bad:
    tags: list = []      # 报错：mutable default ... is not allowed

@dataclass
class Good:
    tags: list = field(default_factory=list)   # 正确
```



原因是类的定义体只执行一次，直接写 `[]` 的话，所有实例会共享同一个列表对象，`a.tags.append(1)` 会连带影响 `b.tags`。



这个规则和函数的默认参数完全一样：不要用可变对象做默认值。



---



## 文件与异常的进阶用法



类讲完了，回到工程层面。文件的读写和异常的基本处理上一课已经讲过，这一章把这两件事往前推一步：让文件写入更安全，让异常带上更多信息。



### 1\. 自己写上下文管理器



上一课讲的 **with open\(\.\.\.\)** 用的是文件对象自带的上下文管理能力。我们自己写的类也可以支持 **with**，只要实现 **\_\_enter\_\_** 和 **\_\_exit\_\_**：



```Python
import json
from pathlib import Path


class StudentRepo:
    def __init__(self, path):
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)   # 目录不存在就建好
        self._data = {}

    def add(self, record):
        self._data[record["sid"]] = record

    def __enter__(self):
        if self.path.exists():                    # 打开时载入
            self._data = {r["sid"]: r for r in json.loads(self.path.read_text("utf-8"))}
        return self

    def __exit__(self, exc_type, exc, tb):
        if exc_type is None:                      # 没出错才写回
            self.path.write_text(
                json.dumps(list(self._data.values()), ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
        return False                              # 不吞异常


with StudentRepo("data/students.json") as repo:
    repo.add({"sid": "20250001", "name": "张三", "age": 18})
# 离开 with 时自动保存
```



这样写有两个好处：打开和保存成对出现，使用者不会忘记；`__exit__` 里判断 `exc_type is None`，出错时就不写回，避免把损坏的数据存进文件。



`__exit__` 返回 `True` 会吞掉异常，返回 `False`（或不返回）则让异常继续往外传。不清楚在做什么的话，就返回 `False`。



### 2\. raise 与异常链



`raise` 可以主动抛出异常：



```Python
def set_age(age):
    if not 0 < age < 150:
        raise ValueError(f"年龄超出范围：{age}")
```



在 `except` 里重新抛出时，用裸 `raise` 能保留原始堆栈；写 `raise e` 会把"重新抛出"这一行也算进堆栈，反而干扰排查。



更常见的是把底层异常**包装成更清楚的异常**，这时用 `raise ... from e` 保留原始原因：



```Python
import json


def load_config(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        raise ValueError(f"配置文件不是合法 JSON：{path}") from e
```



不加 `from e`，报错只显示最后抛出的那句，看不到"文件里第几行 JSON 坏了"这个根因；加上之后，traceback 里会同时呈现两层——表层是你抛出的 `ValueError`，下面接着原始异常，排查快很多。



### 3\. 自定义异常



内置异常表达的是"语言层面的错误"。业务上的错误应该有自己的一类名字，而且这里的写法正好用上了刚学的继承和 `super()`：



```Python
class AppError(Exception):
    """本项目所有异常的基类。"""


class ValidationError(AppError):
    """数据校验失败。"""

    def __init__(self, field, message):
        self.field = field
        super().__init__(f"{field}: {message}")


class NotFoundError(AppError):
    """记录不存在。"""
```



定义一个基类 `AppError` 的价值在于，调用方可以只捕获它，把本项目的业务错误和 Python 的意外错误区分开：



```Python
try:
    run_app()
except AppError as e:
    print(f"业务失败：{e}")
except Exception:
    raise          # 其余都是意料之外的 bug，让它暴露出来
```



`ValidationError` 里把 `field` 存成属性，上层就能定位到具体是哪个字段出了问题，而不用去解析错误消息的字符串。



命名上以 `Error` 结尾，继承 `Exception` 就行。不要继承 `BaseException`，那个是给 `KeyboardInterrupt`、`SystemExit` 这类用的。



### 4\. 日志记录



调程序时习惯用 `print` 输出信息，但正式项目里一般用 `logging`。区别在于：



||print|logging|
|---|---|---|
|级别|无|DEBUG / INFO / WARNING / ERROR / CRITICAL|
|关闭|要删代码|调一下级别即可|
|输出目标|只能到终端|终端、文件都可以|
|时间与位置|无|自动附带|



原则很简单：**给用户看的输出用 `print`，给自己排查问题用的记录用 `logging`。**



```Python
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)

logger = logging.getLogger(__name__)

logger.debug("调试细节，默认不显示")
logger.info("载入 %d 条记录", 42)
logger.warning("文件不存在，将创建新文件")
logger.error("保存失败")
```



级别从低到高是 `DEBUG` \< `INFO` \< `WARNING` \< `ERROR` \< `CRITICAL`。设置 `level=logging.INFO` 表示只输出 INFO 及以上，DEBUG 被过滤掉。



三个要注意的地方：



**一是用 `logging.getLogger(__name__)`，不要用 `logging.info()`。**



```Python
logging.info("msg")        # 不推荐

logger = logging.getLogger(__name__)
logger.info("msg")         # 推荐
```



`__name__` 是模块的路径名（比如 `student_manager.repository`），日志格式里的 `%(name)s` 会输出它。文件一多，这是定位问题的第一条线索。



**二是用 `%s` 占位符，不要用 f\-string。**



```Python
logger.debug(f"处理第 {i} 条")         # 不推荐
logger.debug("处理第 %s 条", i)        # 推荐
```



区别在于，f\-string 无论这条日志会不会输出，都会先把字符串拼好；`%s` 的拼接会推迟到确定要输出的时候。日志量大时这个差别不小。



**三是输出到文件时记得写编码。**



```Python
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.StreamHandler(),                            # 输出到终端
        logging.FileHandler("app.log", encoding="utf-8"),   # 输出到文件
    ],
)
```



另外，`basicConfig` 只在第一次调用时生效。如果发现格式设置没起作用，可以 `print(logging.getLogger().handlers)` 看看里面挂了什么——多半是某个库已经先配置过了。



在 `except` 块里，`logger.exception("...")` 会自动附上完整的报错堆栈，比 `logger.error` 更适合记录异常。



---



## 课后作业：面向对象版学生信息管理系统



把上一课的学生信息管理系统升级为面向对象版本，并整理成带依赖声明的规范项目结构。



**题目要求：**



- 用类重写学生信息管理系统，至少包含 `Student` 类和一个管理学生的类；

- 学生信息要能校验，非法数据（如年龄为负）要抛出异常，不要静默接受；

- 数据保存到文件，程序下次启动能读回来；

- 项目里有依赖声明文件，助教按 README 一条命令能跑起来。

    

**分步思路：**



1. 先定目录结构：`src/包名/` 放代码，`data/` 放数据文件，`tests/` 放测试；

2. 在 `models.py` 里写 `Person` 基类和 `Student` 子类，`__init__` 里调用 `super().__init__(...)`；

3. 用 `@property` 给 `age` 或 `score` 加校验，非法值抛 `ValueError`；

4. 给 `Student` 写 `__str__` 和 `__repr__`，方便打印和调试；

5. 写一个 `StudentRepo` 类负责读写 JSON 文件，实现 `__enter__` / `__exit__`，用 `with` 语句使用；

6. 在 `exceptions.py` 里定义 `AppError` 基类和至少两个具体异常，校验失败和文件读取失败分别用不同的异常；

7. 用 `logging` 记录关键操作，入口处配置一次，各模块用 `logging.getLogger(__name__)`；

8. 在 **cli\.py** 里写命令行入口，装好项目后用 **python \-m 包名\.cli** 运行；

9. 写 `requirements.txt` 或 `pyproject.toml`，并在 README 里写清安装和运行步骤。

    

**可选扩展（进阶）：**



- 让 `StudentRepo` 支持 `len()`、`in` 和 `for` 遍历（实现 `__len__`、`__contains__`、`__iter__`）；

- 给 `Student` 加一个 `@classmethod from_dict(cls, data)` 作为替代构造器；

- 用 `@dataclass` 重写一个辅助类（如 `Course`），注意可变默认值要用 `field(default_factory=list)`；

- 用 `pytest` 给 `models.py` 写几个测试。

    

**提交前自查：**



- **pip install \-e \.** 装好之后，**python \-m 包名\.cli** 能正常跑起来；

- `.venv/` 没有提交到 Git；

- 所有 `open()` 都写了 `encoding="utf-8"`；

- 没有写 `except: pass` 这种把错误吞掉的地方。

