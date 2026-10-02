# Lesson 1 Python 核心语法与数据结构

本次课主要内容：课前准备（解释器、编辑器、虚拟环境），基础语法，核心数据结构，函数与模块，类型标注，异常处理与文件读写，课后作业。



这一课是整门课的地基。变量、容器、函数这些内容会用后面每一节课，所以这里的每个例子都建议在编辑器里敲一遍。



---



## 课前准备



开始写代码之前，先把运行环境准备好。本部分动手操作一遍即可，细节不用死记。



### 1\. 命令行基础



后面的操作大多要在终端里敲命令，先熟悉这几个：



|操作|Windows|macOS / Linux|
|---|---|---|
|查看当前目录内容|`dir`|`ls`|
|进入某个目录|`cd 目录名`|`cd 目录名`|
|返回上一级|`cd ..`|`cd ..`|
|新建文件夹|`mkdir 名字`|`mkdir 名字`|



Windows 用户在 PowerShell 里操作即可。想省掉手动 **cd** 那一步，可以在资源管理器里对着文件夹右键选“在终端中打开”（Windows 11 的写法；Windows 10 上是按住 **Shift** 右键，选“在此处打开 PowerShell 窗口”）。



命令行不需要背，用几次就熟了。真正要养成的习惯是：**知道自己在哪个目录下**。后面所有"找不到文件""导入失败"的问题，多半都是目录搞错了。



### 2\. Python 解释器安装



Python 是跨平台的，Windows、macOS、Linux 都支持官方安装包。



|系统|安装方式|验证命令|
|---|---|---|
|Windows|前往 [python\.org](https://www.python.org/downloads/) 下载安装包，安装时**勾选 "Add Python to PATH"**|`python --version`|
|macOS|官网安装包，或终端执行 `brew install python`|`python3 --version`|
|Linux|包管理器安装，如 `sudo apt install python3` 或 `sudo dnf install python3`|`python3 --version`|



安装完成后，在终端输入验证命令，能输出版本号就说明装好了。



Windows 用户如果在终端里找不到 `python`，通常是安装时漏勾了 "Add Python to PATH"，重新装一次，把这个选项勾上即可。



本课要求 Python **3\.11 及以上**。Python 3\.10 已于 2026 年 10 月停止支持，所以门槛提到了 3\.11；版本偏低的话，先升级再上课。



### 3\. 编辑器与插件



编辑器没有强制要求，按自己的习惯选一款即可。课堂上讲的代码在任意一款主流编辑器里都能运行。



- **VS Code**：轻量、免费。装上 Python 扩展后就有语法高亮、智能提示、单文件运行和调试功能。

- **PyCharm**：功能完整，Community 免费版够用。新建项目时要注意选对解释器路径。

- **Cursor、Trae 等 AI 辅助编辑器**：基于 VS Code 生态，自带 AI 补全和问答，同样能写能跑 Python。

    

装好编辑器后做一个验证：新建一个 `hello.py`，写入 `print("hello")`，运行它。能打印出结果，说明编辑器配好了。



### 4\. 虚拟环境



这一节的唯一目标：**建好一个虚拟环境，能激活，能在里面装包**。原理下一课专门讲，现在先把动作做出来。



```Bash
python -m venv .venv                  # 在项目目录下创建 .venv 文件夹

source .venv/bin/activate             # macOS / Linux 激活
.venv\Scripts\Activate.ps1            # Windows PowerShell 激活

pip install requests                  # 安装第一个第三方包
deactivate                            # 退出
```



激活成功的标志是提示符前多了 `(.venv)`。装完之后用下面这个脚本确认环境和包都对得上：



```Python
import sys
import requests

print("Python :", sys.version.split()[0])
print("解释器 :", sys.executable)
print("requests:", requests.__version__)
```



把这段存成 `check_env.py` 运行。如果 `requests` 那行报 `ModuleNotFoundError`，多半是**装包的环境和运行代码的环境不是同一个**——这是新手最常遇到的问题，后面还会碰到。



`.venv` 文件夹不要提交到 Git，也不要手动改里面的东西，它随时能重建。



---



## 基础语法



基础语法是后续一切内容的地基。先掌握变量、数据类型、运算符和流程控制，再进入数据结构。



### 1\. 变量与数据类型



**变量**是用来存放数据的名字。Python 变量的命名规则：



- 由字母、数字、下划线组成，不能以数字开头；

- 不能与 Python 关键字重名（如 `if`、`for`、`class`）；

- 区分大小写，建议使用 `小写字母_下划线` 风格，如 `user_name`。

    

```Python
a = 1            # 整数
b = 1.5          # 浮点数
name = "Alice"   # 字符串
```



Python 是动态类型语言，变量无需声明类型，赋值时自动确定，也可以用 `type()` 查看类型：



```Python
print(type(a))      # <class 'int'>
print(type(b))      # <class 'float'>
print(type(name))   # <class 'str'>
```



#### 数字与四则运算



```Python
a = 1
b = 1.5
c = a * b + a - b / a
print(c)
```



#### 布尔型



布尔型只有两个值 `True` 和 `False`，常用于条件判断：



```Python
a = True
b = False
print(3 > 2)    # True
print(3 == 2)   # False
```



#### 字符串



字符串用单引号或双引号包裹，支持多种常用操作：



```Python
s = 'hello world'
print(s + '!')                        # 字符串连接
print(len(s))                         # 字符串长度
print(s[0], s[-1])                    # 索引访问
print(s[0:5])                         # 切片
print(s.find('world'))                # 查找子串
print(s.replace('world', 'python'))   # 替换
print(s.split(' '))                   # 分割
print(s.upper(), s.lower())           # 大小写转换
print(s.strip())                      # 去除首尾空白
print(s.startswith('hello'))          # 判断开头
```



字符串格式化常用 f\-string（Python 3\.6\+）：



```Python
name = "Alice"
age = 25
print(f"{name} is {age} years old")
```



### 2\. 输入与输出



`input()` 接收键盘输入，**返回的一定是字符串**；`print()` 输出到屏幕。



```Python
x = input("x: ")
print(x, type(x))          # 输入 123，输出 123 <class 'str'>

num = int(input("Enter a number: "))   # 需要数值时用 int() 转换
print(num + 10)
```



这个细节很容易踩坑：`input()` 拿到的是字符串，`"123" + 10` 会直接报 `TypeError`，必须先用 `int()` 或 `float()` 转换。



### 3\. 运算符



#### 算术运算符



|运算符|说明|示例|
|---|---|---|
|`+ - * /`|加、减、乘、除|`7 / 2` 结果是 `3.5`|
|`//`|整除（向下取整）|`7 // 2` 结果是 `3`|
|`%`|取余|`7 % 2` 结果是 `1`|
|`**`|幂运算|`2 ** 3` 结果是 `8`|



#### 比较运算符



比较运算的结果是布尔值：



|表达式|描述|
|---|---|
|`x == y`|x 等于 y|
|`x != y`|x 不等于 y|
|`x < y`|x 小于 y|
|`x > y`|x 大于 y|
|`x <= y`|x 小于或等于 y|
|`x >= y`|x 大于或等于 y|
|`x in y`|x 是容器 y 的成员|
|`x is y`|x 和 y 是同一个对象|



#### 逻辑运算符



- `and`：两边都为真才为真；

- `or`：一边为真即为真；

- `not`：取反。

    

```Python
age = 20
print(age > 18 and age < 60)   # True
print(not (age > 18))          # False
```



#### 赋值运算符



除 `=` 外，还常用复合赋值：`+=`、`-=`、`*=`、`/=` 等。



```Python
x = 1
x += 1      # 等价于 x = x + 1
print(x)    # 2
```



（`+=` 用在列表上时有个容易踩的坑，等讲完列表再补。）



### 4\. 分支流程控制



程序根据条件选择不同的执行路径，使用 `if` / `elif` / `else`：



```Python
num = int(input('Enter a number: '))
if num > 0:
    print('The number is positive')
elif num < 0:
    print('The number is negative')
else:
    print('The number is zero')
```



书写要点：条件后面有冒号 `:`，属于该分支的代码必须缩进（约定 4 个空格）。



### 5\. 循环流程控制



循环用于重复执行某段代码。



**while 循环**：条件为真时反复执行，适合"次数不确定"的场景。



```Python
x = 1
while x <= 100:
    print(x)
    x += 1
```



**for 循环**：遍历可迭代对象（如 `range`、字符串、列表），适合"次数确定"或"遍历容器"的场景。



```Python
for x in range(1, 101):
    print(x)

words = ['this', 'is', 'an', 'ex', 'parrot']
for word in words:
    print(word)
```



`range(1, 101)` 生成 1 到 100 的整数序列；`range(start, stop, step)` 可以指定步长。



循环控制语句：



- `break`：立即结束整个循环；

- `continue`：跳过本次循环，进入下一次。

    

```Python
for i in range(1, 10):
    if i == 3:
        continue   # 跳过 3
    if i == 6:
        break      # 到 6 结束
    print(i)
```



---



## 核心数据结构



Python 内置了四种常用的容器类型：列表、元组、字典、集合。它们都能存放多个数据，但特点和使用场景各不相同。**重点是列表和字典**，这两个在日常代码里出现频率最高。



先区分两个概念：



- **序列（Sequence）**：元素按顺序排列，支持下标索引和切片，如字符串、列表、元组、range；

- **非序列**：不支持按位置下标访问——字典按键取值、集合本身无序，如字典、集合。

    

列表、元组属于序列，字典、集合属于非序列。



### 1\. 列表



列表是有序、可变的序列，用方括号 `[]` 表示，可以存放任意类型的数据。



```Python
l = [1, 2, 3, 4, 5]

print(l[0])        # 索引访问，从 0 开始
l[0] = 100         # 修改元素
print(len(l))      # 长度
print(l[1:3])      # 切片

l.append(6)        # 追加元素
l.extend([7, 8])   # 合并另一个列表
l.insert(0, 0)     # 在指定位置插入
l.remove(100)      # 删除指定值
l.pop()            # 弹出末尾元素
l.sort()           # 排序
```



列表拷贝需要注意：直接赋值 `b = l` 只是让 `b` 指向同一个列表，修改 `b` 会同时影响 `l`；需要独立副本时用 `copy()` 或切片：



```Python
l = [1, 2, 3]
b = l.copy()      # 独立副本
b.append(4)
print(l, b)       # [1, 2, 3] [1, 2, 3, 4]
```



遍历列表用 for 循环：



```Python
for item in l:
    print(item)
```



#### 列表推导式



把一个列表加工成另一个列表，用推导式比写循环更简洁：



```Python
nums = [1, 2, 3, 4, 5, 6]

squares = [n * n for n in nums]              # 每个元素求平方
evens = [n for n in nums if n % 2 == 0]      # 只要偶数

print(squares)   # [1, 4, 9, 16, 25, 36]
print(evens)     # [2, 4, 6]
```



#### 常用内置函数



列表常配合 `len()`、`sum()`、`max()`、`min()`、`sorted()` 一起用：



```Python
scores = [88, 92, 79, 95]

print(len(scores))            # 4
print(sum(scores))            # 354
print(max(scores), min(scores))   # 95 79
print(sum(scores) / len(scores))  # 88.5  平均分
print(sorted(scores, reverse=True))   # [95, 92, 88, 79]
```



#### \+= 用在列表上的坑



前面讲运算符时留了个问题：`l += [4]` 和 `l = l + [4]` 看起来一样，其实有区别。



对数字这类**不可变**对象，两种写法完全等价，都是产生一个新的数字。但列表是**可变**对象，`+=` 会在原列表上**原地追加**，`l` 还是原来那个列表；而 `l = l + [4]` 是创建一个**新列表**，再绑定给 `l`：



```Python
l1 = [1, 2]
l2 = [1, 2]
i1 = id(l1)
i2 = id(l2)

l1 += [3]         # 原地修改，仍是原来的列表对象
l2 = l2 + [3]     # 生成新列表，绑定到新对象

print(l1, l2)             # [1, 2, 3] [1, 2, 3]
print(id(l1) == i1)       # True，l1 还是原对象
print(id(l2) == i2)       # False，l2 已是新对象
```



原因：`+=` 调用对象的 `__iadd__` 方法，可变对象通常原地修改；不可变对象没有这个方法，会自动退化为 `x = x + ...`，产生新对象。



这个区别平时不用刻意记，但当你有两个变量指向同一个列表时就要小心了——改一个会连带影响另一个。类似的还有 `list.append()`、`list.sort()` 这些方法，它们都是原地修改，不返回新列表。



### 2\. 元组



元组用圆括号 `()` 表示，**创建后不可修改**（不可变）。可以索引、切片、求长度，但没有 `append`、`remove` 这些方法。



```Python
t = (1, 2, 3, 4, 5)
print(t[0], t[1:3], len(t))
```



元组支持**解包**，一次把多个值赋给多个变量：



```Python
a, b, c = (1, 2, 3)
print(a, b, c)   # 1 2 3
```



适用场景：表示“不应该被修改”的数据，如坐标、配置项；函数返回多个值时，返回的其实就是一个元组（后面讲函数返回值时会用到）。



### 3\. 字典



字典以键值对（key\-value）存储数据，用花括号 `{}` 表示，通过键快速查找值。



```Python
my_dict = {"name": "Alice", "age": 25, "city": "New York"}

print(my_dict["name"])        # 访问：键不存在会报 KeyError
print(my_dict.get("age"))     # 访问：键不存在返回 None，更安全
my_dict["age"] = 26           # 修改
my_dict["job"] = "engineer"   # 添加新键值对
del my_dict["city"]           # 删除键值对
print(len(my_dict))           # 大小
print(my_dict.keys())         # 所有键
print(my_dict.values())       # 所有值
```



遍历字典最常用的是同时取出键和值：



```Python
for key, value in my_dict.items():
    print(key, value)
```



字典合并可以用 `|` 运算符（Python 3\.9\+）或 `update()`：



```Python
d1 = {"a": 1}
d2 = {"b": 2}

print(d1 | d2)    # {'a': 1, 'b': 2}  —— 用 | 合并，两边都不变

d1.update(d2)     # 用 update 合并，就地修改 d1
print(d1)         # {'a': 1, 'b': 2}
```



遍历字典时修改字典会报错，需要遍历副本：



```Python
d = {"a": 1, "b": 2}
for k in list(d.keys()):      # list() 复制一份键
    if d[k] == 1:
        del d[k]
print(d)     # {'b': 2}
```



#### 用字典统计



字典最常见的用法之一是计数，这在后面的作业里会用到：



```Python
words = ["apple", "banana", "apple", "cherry", "banana", "apple"]

count = {}
for w in words:
    count[w] = count.get(w, 0) + 1    # get 给不存在的键返回 0

print(count)     # {'apple': 3, 'banana': 2, 'cherry': 1}
```



适用场景：需要"按名字查值"的数据，如学生成绩表、配置信息、统计词频。



### 4\. 集合



集合与数学中的集合概念一致：**无序、元素不重复**，用花括号或 `set()` 创建。



```Python
s = {1, 2, 3, 3, 4}
print(s)          # {1, 2, 3, 4}，自动去重
s.add(5)          # 添加元素
s.remove(1)       # 删除元素，不存在会报错
s.discard(99)     # 删除元素，不存在也不报错
print(len(s))
```



集合最常用的三个场景：



- **去重**：把列表转成集合再转回列表，重复元素自动消失；

- **成员判断**：`x in s` 的速度远快于列表；

- **集合运算**：并集 `|`、交集 `&`、差集 `-`。

    

```Python
a = {1, 2, 3}
b = {2, 3, 4}
print(a | b)   # {1, 2, 3, 4}  并集
print(a & b)   # {2, 3}        交集
print(a - b)   # {1}           差集

nums = [1, 2, 2, 3, 3, 3]
unique = list(set(nums))
print(unique)  # [1, 2, 3] 去重
```



### 5\. 四种数据结构对比



|类型|是否有序|是否可变|是否允许重复|典型用途|
|---|---|---|---|---|
|列表 list|是|是|是|有序、需要增删改的数据集合|
|元组 tuple|是|否|是|不应被修改的数据、函数多返回值|
|字典 dict|插入有序（3\.7\+）|是|键不重复|按键快速查找|
|集合 set|否|是|否|去重、成员判断、集合运算|



### 6\. 容器类型的标注



四种容器都能标注里面装的是什么类型，写法是在方括号里写元素类型：



```Python
scores: list[int] = [88, 92, 79]
names: list[str] = ["Alice", "Bob"]
student: dict[str, int] = {"age": 18}
tags: set[str] = {"python", "basics"}
point: tuple[int, int] = (3, 4)
```



如果某个值可能是 `None`，用 `| None` 标注：



```Python
def find_student(sid: str) -> dict | None:
    ...
    return None
```



这种写法是 Python 3\.10 引入的。更早的版本要写 **Optional\[dict\]**，还得 **from typing import Optional**。本课要求 3\.11 及以上，直接用 **\|** 就行。



---



## 函数与模块



### 1\. 函数的概念与定义



**函数**是一个被命名的、独立的、完成特定功能的代码段，可能给调用它的程序一个返回值。简单说，函数把一段实现某种功能的代码封装起来，需要使用该功能时直接调用即可。



函数的主要作用：



- **模块化编程**：把大问题拆成小功能；

- **代码重用**：同一段逻辑只需写一次。

    

函数语法：



```Plain Text
def 函数名(参数1, 参数2, ...):
    代码1
    代码2
    ...
    [return 返回值]
```



使用要点：



- 先定义，后调用；

- 不调用，不执行；

- 调用一次，执行一次。

    

```Python
# 1. 定义
def show():
    print("Hello World!")

# 2. 调用
show()
```



### 2\. 函数的参数



定义函数时的参数叫**形参**，调用时传入的参数叫**实参**。



```Python
def printme(text, num):          # 参数名别用 str、list 这类内置名字，会把内置类型遮住
    print(text, num)

printme("蓝山", 666)            # 位置参数：按顺序传
printme(num=666, text="蓝山")   # 关键字参数：按名字传，可不按顺序
```



常用参数形式：



- **位置参数（必备参数）**：调用时的数量必须与定义一致；

- **关键字参数**：用 `参数名=值` 传参，顺序可打乱；

- **默认参数**：定义时给参数设默认值，调用时不传则使用默认值；

- **不定长参数**：`*args` 把任意多个参数收集成元组，用 `**kwargs` 收集成字典。

    

```Python
def printinfo(name, age=35):      # age 是默认参数
    print("Name:", name, "Age:", age)

printinfo(name="miki")            # Age: 35
printinfo(name="miki", age=50)    # Age: 50


def total(*nums):                 # 调用时能传任意多个参数
    return sum(nums)


print(total(1, 2, 3))             # 6
```



匿名函数 `lambda` 适合写只有一行的简单函数，最常出现在 `sorted` 的排序规则里：



```Python
add = lambda a, b: a + b
print(add(3, 4))   # 7

words = ["banana", "kiwi", "apple"]
print(sorted(words, key=lambda w: len(w)))   # ['kiwi', 'apple', 'banana']
```



两个都别用过头：函数体超过一行就正常用 `def`，匿名函数多了反而难读。



### 3\. 函数的返回值



`return` 把结果返回给调用处，并结束函数；没有 `return`（或 `return` 不带值）时，函数返回 `None`。



```Python
def get_multiply(a, b):
    return a * b

print(get_multiply(10, 20))   # 200
```



函数可以一次返回多个值，实际返回的是一个元组：



```Python
def get_sub_sum(a, b):
    return a - b, a + b

result = get_sub_sum(30, 14)
print(result)          # (16, 44)
x, y = result          # 解包
print(x, y)            # 16 44
```



补充两点：



- **局部变量与全局变量**：函数内定义的变量是局部变量，只在函数内生效；函数外定义的变量是全局变量。同名时函数内优先使用局部变量。

- **说明文档**：在函数第一行写多行字符串作为文档，调用 `help(函数名)` 可以查看。

    

### 4\. 类型标注



既然函数已经会写了，顺手给参数和返回值标上类型，代码会好读很多：



```Python
def add(x: int, y: int) -> int:
    return x + y

def greet(name: str) -> str:
    return f"Hello, {name}"

print(add(3, 5))         # 8
print(greet("Alice"))    # Hello, Alice
```



变量也可以标：



```Python
name: str = "Alice"
age: int = 25
is_active: bool = True
```



**重点是搞清楚一点：Python 不会在运行时检查这些标注。**



```Python
def add(x: int, y: int) -> int:
    return x + y

print(add("3", "5"))     # 35  —— 不报错，标注被忽略了
```



标注是**给人看、给编辑器看**的，不是给解释器看的。配上 VS Code 或 PyCharm 的提示，它能在你传错类型时标出警告：



```Python
add(3, "5")     # 编辑器会标黄：Argument of type "str" cannot be assigned to "int"
```



但程序照样能跑，要等运行到 **int \+ str** 那一步才真的报 **TypeError**。所以标注是一种**约定和提示**，不是强制约束。



后面几节课会用到真正做校验的工具，到时候你会发现：类型标注是那类工具的基础。现在先把习惯养起来——**写函数时顺手标上参数和返回值的类型**。



### 5\. 模块



**模块**是组织 Python 代码的文件（`.py` 文件），模块里可以包含函数、类和变量。当需要使用的功能在某个模块中时，先导入再使用。



导入语法：



```Plain Text
import 模块名
from 模块名 import 功能名
from 模块名 import 功能名 as 别名
import 模块名 as 别名
```



不要写 `from 模块名 import *`。它看起来省事，但导入进来的名字你并不知道有哪些，一旦和本地变量重名就会互相覆盖，排查起来很麻烦。要什么就明确导入什么。



#### 标准库调用



Python 自带丰富的标准库，安装解释器后即可使用：



```Python
import math
print(math.floor(32.9))   # 向下取整，32

import time
time.sleep(1)             # 暂停 1 秒

from datetime import datetime
print(datetime.now())     # 当前时间
```



标准库完整索引见 [Python 标准库](https://docs.python.org/zh-cn/3/library/index.html)；`len`、`int`、`type`、`print` 等常用内置函数的说明见 [Python 内置函数](https://docs.python.org/zh-cn/3/library/functions.html)。



#### 自定义模块



自定义模块就是创建一个以 `.py` 结尾的文件（文件名要符合标识符命名规则），把功能写进去，再在另一个文件里导入使用。



例如创建 `mytools.py`：



```Python
def add(x, y):
    return x + y

def print1():
    print("Hello from mytools")
```



在同目录下创建 `main.py` 导入并使用：



```Python
import mytools
print(mytools.add(3, 5))    # 8
mytools.print1()

from mytools import add     # 只导入某个功能
print(add(4, 5))            # 9
```



一个小约定：写在 `if __name__ == "__main__":` 里的代码只在直接运行该文件时执行，被导入时不会执行，常用于测试模块自身：



```Python
def add(x, y):
    return x + y

if __name__ == "__main__":
    print(add(1, 2))
```



模块化之后，项目通常按职责分目录组织：



```Plain Text
project_root/
    ├── src/             # 核心代码
    ├── data/            # 数据文件
    ├── logs/            # 运行日志
    └── tests/           # 测试代码
```



现在只要知道"代码和数据通常分开放在不同目录"就够了，下一课会把目录规范讲清楚。



---



## 异常处理与文件读写



写程序时总会遇到出错的情况：文件不存在、用户输入的不是数字、列表下标越界。这些都会抛出**异常**。如果异常没被处理，程序会直接中断并打印一堆 traceback。



作业要把学生数据存进文件、下次启动再读回来，而程序第一次运行时这个文件还不存在；用户输入也可能不是数字。这一章先过一遍文件读写，再讲这类出错情况怎么处理。



### 1\. try / except



用 `try...except` 捕获异常，让程序有机会补救：



```Python
try:
    age = int(input("请输入年龄: "))
    print(f"年龄是 {age}")
except ValueError:
    print("输入的不是整数！")
```



`try` 块里放**可能出错**的代码；一旦抛出异常，就跳去执行对应的 `except` 块，而不是直接崩溃。



一个 `try` 可以带多个 `except`，按**从上到下**的顺序匹配：



```Python
try:
    num = int(input("请输入一个整数: "))
    result = 10 / num
    print(result)
except ValueError:
    print("输入的不是整数！")
except ZeroDivisionError:
    print("除数不能为 0！")
```



也可以用 `as e` 把异常对象取出来，打印详细信息：



```Python
try:
    num = int(input("请输入一个整数: "))
except ValueError as e:
    print(f"输入有误：{e}")     # 输入有误：invalid literal for int() with base 10: 'abc'
```



### 2\. 常见异常



|异常|说明|
|---|---|
|`SyntaxError`|语法错误，代码书写不规范|
|`NameError`|使用未定义的变量或函数|
|`TypeError`|对不兼容的类型进行操作|
|`ValueError`|传入的值类型正确但不合法（如把 `"abc"` 转 `int`）|
|`ZeroDivisionError`|除数为 0|
|`IndexError`|索引超出序列范围|
|`KeyError`|字典的键不存在|
|`AttributeError`|属性不存在|
|`FileNotFoundError`|打开不存在的文件|



不用背。实际写代码时遇到报错，看 traceback 最后一行写的异常名，就知道该捕获什么了。



### 3\. 文件读写基础



程序运行时的数据都在内存里，一关就没了。要把数据留下来，就得写进文件。这一节先把最基本的读写动作过一遍。



#### open 与打开模式



```Python
file_object = open(file_name, mode, encoding="utf-8")
```



常用模式：



|**模式**|**说明**|
|---|---|
|**'r'**|只读（默认）。文件不存在会报错|
|**'w'**|只写。文件存在则覆盖，不存在则创建|
|**'a'**|追加。写入内容追加到文件末尾|
|**'x'**|独占写。文件已存在时报错|
|**'b'**|二进制模式，如 **'rb'**、**'wb'**，处理图片等|



读写文本文件时建议指定 **encoding="utf\-8"**，避免中文乱码。在 Python 3\.14 及更早的版本上，Windows 中文版的默认编码是 GBK（cp936），Linux 和 macOS 是 UTF\-8，不写清楚的话同一份文件在两台机器上读出来可能不一样；从 Python 3\.15 起默认编码统一为 UTF\-8（PEP 686），但显式写 **encoding="utf\-8"** 仍然是推荐做法。



#### 读取文件



```Python
# 读取整个文件
with open('students.txt', 'r', encoding='utf-8') as file:
    content = file.read()
    print(content)
```



```Python
# 逐行读取：文件对象本身可迭代，最简洁
with open('students.txt', 'r', encoding='utf-8') as file:
    for line in file:
        print(line, end='')
```



#### 写入文件



```Python
# 写入单行
with open('students.txt', 'w', encoding='utf-8') as file:
    file.write("张三,18\n")

# 写入多行
lines = ["张三,18\n", "李四,19\n"]
with open('students.txt', 'w', encoding='utf-8') as file:
    file.writelines(lines)
```



#### with 与文件关闭



**with open\(\.\.\.\) as file:** 是推荐写法：无论操作是否成功，文件都会自动关闭。靠的就是对象的 **\_\_enter\_\_** 和 **\_\_exit\_\_** 方法——即使块里抛了异常，**\_\_exit\_\_** 也一定会执行（自己写这两个方法下一课会讲）。手动打开的话必须自己 **close\(\)**，一旦中途出错就执行不到了：



```Python
file = open('students.txt', 'r', encoding='utf-8')
# 进行文件操作
file.close()
```



#### 读写 JSON



学生信息用字典存最方便，存文件时用标准库的 **json** 模块：



```Python
import json

data = [{"sid": "20250001", "name": "张三", "age": 18}]

with open("students.json", "w", encoding="utf-8") as file:
    json.dump(data, file, ensure_ascii=False, indent=2)

with open("students.json", "r", encoding="utf-8") as file:
    loaded = json.load(file)

print(loaded[0]["name"])     # 张三
```



**ensure\_ascii=False** 让中文原样写入，**indent=2** 让文件带缩进便于阅读。



### 4\. 在文件读写里用



最典型的场景就是读文件——文件可能不存在：



```Python
import json


def load_students(path: str) -> list[dict]:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return []        # 第一次运行，还没有数据文件，返回空列表
```



这样程序第一次运行时不会因为"文件不存在"而崩溃，用户也不用先手动创建一个空文件。



### 5\. else 与 finally



**try** 语句还可以带 **else** 和 **finally** 两个子句。**else** 在 **try** 没有出错时执行，**finally** 无论有没有出错都执行：



```Python
def parse_age(raw):
    try:
        age = int(raw)                       # 可能出错的部分
    except ValueError:
        print("年龄必须是整数")
        return None
    else:
        if not 0 < age < 150:                # 只有 try 成功才走到这里
            print("年龄超出合理范围")
            return None
        return age
    finally:
        print("parse_age 结束")               # 无论如何都执行
```



**else** 的价值是把“可能出错的代码”和“成功之后的代码”分开。上面如果省掉 **else**，把范围判断也塞进 **try**，那么它抛出的异常就可能被同一个 **except ValueError** 误捕获——本来想抓的是“输入不是整数”，结果连“范围判断写错了”也一并吞掉。**try 里只放真正可能出错的那几行。**



**finally** 常用于释放资源。不过文件这类资源用 **with** 更省事，所以 **finally** 在业务代码里出现得不多，见到能认出来就行。



### 6\. 两个容易写错的地方



**一是 `try` 的范围要尽量小。** 只把真正可能出错的那几行放进 `try`：



```Python
# 不好：范围太大，后面的逻辑出错也会被当成"输入有问题"
try:
    age = int(input("年龄: "))
    save_to_file(age)
    send_email(age)
except ValueError:
    print("输入的不是整数")

# 好：只包住可能抛异常的那一句
try:
    age = int(input("年龄: "))
except ValueError:
    print("输入的不是整数")
else:
    save_to_file(age)
```



**二是不要用裸 `except`。**



```Python
try:
    do_something()
except:              # 什么都抓，连 Ctrl+C 都拦
    pass             # 而且什么都不做，错误被彻底隐藏
```



这样写程序不会报错，但出了问题你完全不知道发生了什么。**只捕获你预期的那种异常**，抓不到的正常报出来就好。



---



## 课后作业：学生信息管理系统



实现一个学生信息管理系统，把本课的知识串起来。这个系统在后面几节课里会继续升级。



**题目要求：**



- 用字典存一个学生的信息（学号、姓名、年龄），用列表存所有学生；

- 实现增、删、改、查四个功能；

- 用函数组织代码，每个功能一个函数；

- 数据保存到文件，程序下次启动能读回来；

- 给函数标上类型标注。

    

**建议的项目结构：**



```Plain Text
学生管理系统/
├── main.py         # 程序入口，负责命令行交互
├── student.py      # 学生的增删改查
├── utils.py        # 文件读写等工具函数
├── students.json   # 数据文件
└── test.py         # 自己写的简单测试
```



后面几节课会在这个结构上继续补充依赖声明和目录规范，所以文件拆清楚一点，别全塞进一个文件。



**分步思路：**



1. 先想清楚数据长什么样：一个学生是一个字典 `{"sid": "20250001", "name": "张三", "age": 18}`，所有学生放在一个列表里；

2. 在 `student.py` 里写 `add_student(students, sid, name, age)`，把新学生追加进列表；

3. 写 `find_student(students, sid)`，遍历列表找到学号匹配的那个，找不到返回 `None`；

4. 写 `delete_student(students, sid)` 和 `update_student(students, sid, **kwargs)`；

5. 在 `utils.py` 里写 `save_students(students, path)` 和 `load_students(path)`，用 `with open(...)` 读写文件；

6. 在 `main.py` 里写一个 `main()`，用 `while True` 加 `input()` 做简单菜单，让用户选择要做什么；

7. 用 `if __name__ == "__main__":` 作为程序入口；

8. 在 `test.py` 里写几行调用，验证增删改查和存读都能正确工作。

    

**一个起步框架**（`student.py`、`utils.py` 已给出完整实现，`main.py` 只接通了“增”“查”两条链路，其余照着上面的思路自己补）：



`student.py`：



```Python
def add_student(students: list[dict], sid: str, name: str, age: int) -> None:
    students.append({"sid": sid, "name": name, "age": age})


def find_student(students: list[dict], sid: str) -> dict | None:
    for s in students:
        if s["sid"] == sid:
            return s
    return None


def delete_student(students: list[dict], sid: str) -> bool:
    s = find_student(students, sid)
    if s is None:
        return False
    students.remove(s)
    return True


def update_student(students: list[dict], sid: str, **kwargs) -> bool:
    s = find_student(students, sid)
    if s is None:
        return False
    s.update(kwargs)          # 只改传进来的字段
    return True
```



`utils.py`：



```Python
import json


def save_students(students: list[dict], path: str) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(students, f, ensure_ascii=False, indent=2)


def load_students(path: str) -> list[dict]:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return []
```



`main.py`：



```Python
from student import add_student, find_student
from utils import load_students, save_students

DATA_FILE = "students.json"


def main() -> None:
    students = load_students(DATA_FILE)

    while True:
        choice = input("1.添加 2.查找 3.退出 > ").strip()
        if choice == "1":
            sid = input("学号: ").strip()
            name = input("姓名: ").strip()
            age = int(input("年龄: "))          # 别忘了转成整数
            add_student(students, sid, name, age)
            save_students(students, DATA_FILE)
            print(f"已添加 {name}")
        elif choice == "2":
            sid = input("学号: ").strip()
            s = find_student(students, sid)
            print(s if s else "未找到")
        else:
            break


if __name__ == "__main__":
    main()
```



`test.py`：



```Python
from student import add_student, find_student, delete_student
from utils import load_students, save_students


def test_basic() -> None:
    students: list[dict] = []
    add_student(students, "20250001", "张三", 18)
    assert find_student(students, "20250001")["name"] == "张三"
    assert find_student(students, "99999999") is None
    assert delete_student(students, "20250001") is True
    assert len(students) == 0
    print("全部通过")


if __name__ == "__main__":
    test_basic()
```



这里用到了前面讲的模块导入：**main\.py** 和 **test\.py** 都通过 **import** 使用 **student\.py**、**utils\.py** 里定义的函数。注意这几个文件要放在同一个目录下，否则会报 **ModuleNotFoundError**。



**可选扩展（进阶）：**



- 学号重复时拒绝添加，并给出提示；

- 加一个"统计"功能，比如输出平均年龄、年龄分布（可以练一下字典统计）；

- 用列表推导式筛选出年龄大于 18 的学生；

- 数据改用 CSV 存，用标准库 **csv** 模块读写；

    

**提交前自查：**



- 所有 `open()` 都写了 `encoding="utf-8"`；

- `input()` 拿到的数字用 `int()` 转换过了；

- 函数都标上了类型标注；

- 各个 `.py` 文件都在同一个目录下，`import` 能正常工作。

