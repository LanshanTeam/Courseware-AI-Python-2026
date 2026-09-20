# 第4课：深度学习理论知识与 HuggingFace 常用组件

> **授课对象**：已完成第2课（机器学习基本概念）的学员
> **前置知识**：监督学习范式、训练/验证/测试集划分、过拟合与欠拟合、梯度下降算法（BGD/SGD/MBGD）
> **课时建议**：3 课时（约 135 分钟）

---

## 一、课程目标

1. 理解多层感知机（MLP）的网络结构，掌握激活函数的作用与选择
2. 熟练推导神经网络正向传播的矩阵运算流程
3. 理解反向传播算法的核心——链式法则，能完成两层网络的梯度推导
4. 掌握深度模型训练的完整闭环，建立与课2梯度下降的联系
5. 能用 PyTorch 实现并调优一个浅层神经网络
6. 掌握 HuggingFace Transformers API 的基础调用方法

---

## 二、课前回顾：从机器学习到深度学习（5 分钟）

### 2.1 课2知识锚点

| 课2知识点 | 在本课中的作用 |
|---|---|
| 监督学习范式 | 神经网络训练本质上仍是监督学习（有标签、有损失） |
| 梯度下降（BGD/SGD/MBGD） | 反向传播算出梯度后，仍用梯度下降更新参数 |
| 过拟合与欠拟合 | 深度网络更容易过拟合，需要 Dropout、权重衰减等手段 |
| 数据集划分 | 训练流程中训练集/验证集/测试集的角色不变 |

### 2.2 为什么需要深度学习？

课2作业中大家尝试拟合 `f = x + y² + z³`，这是一个**非线性函数**。线性回归（课2内容）只能拟合线性关系，面对非线性问题时表达能力不足。

**核心矛盾**：现实数据（图像、语音、文本）的规律极其复杂，线性模型和浅层模型无法有效拟合。

**深度学习的解法**：通过堆叠多层非线性变换，让模型自动学习从原始输入到高级语义的层次化特征，理论上可以近似任意连续函数。

---

## 三、多层感知机（MLP）的网络结构与表达能力（25 分钟）

### 3.1 从单个神经元说起

一个神经元的计算：

```
z = w₁x₁ + w₂x₂ + ... + wₙxₙ + b
a = σ(z)
```

- `w`：权重（weight），决定每个输入的重要性
- `b`：偏置（bias），控制激活阈值
- `σ`：激活函数（activation function），引入非线性

### 3.2 网络结构

MLP 由三类层组成：

- **输入层**：接收原始特征，不做计算
- **隐藏层**：一层或多层，进行非线性变换
- **输出层**：产生最终预测（回归输出数值，分类输出概率）

**全连接（Fully Connected）**：相邻两层的每个神经元都两两相连。

### 3.3 激活函数——为什么必须是非线性的？

> **关键结论**：如果没有激活函数，无论堆多少层，整个网络等价于一个线性变换（矩阵乘法的组合仍是矩阵乘法），退化为线性回归。

常见激活函数对比：

| 激活函数 | 公式 | 特点 |
|---|---|---|
| Sigmoid | σ(x) = 1/(1+e⁻ˣ) | 输出 (0,1)，可做概率；但梯度消失严重 |
| Tanh | tanh(x) | 输出 (-1,1)，零中心化；仍有梯度消失问题 |
| ReLU | max(0, x) | 计算简单、缓解梯度消失；可能"神经元死亡" |

**默认选择**：隐藏层用 ReLU，输出层根据任务选（回归用线性，二分类用 Sigmoid，多分类用 Softmax）。

### 3.4 万能近似定理

> 单隐藏层、足够多神经元的前馈网络，可以在闭区间上以任意精度近似任意连续函数。

**深度 vs 宽度**：增加深度比增加宽度参数效率更高——深层网络能以指数级更少的参数表达同等复杂度的函数。

---

## 四、神经网络正向传播（20 分钟）

### 4.1 逐层计算流程

以一个 2 层网络（输入→隐藏→输出）为例：

```
第1层（隐藏层）：Z¹ = W¹·X + b¹,  A¹ = ReLU(Z¹)
第2层（输出层）：Z² = W²·A¹ + b²,  A² = σ(Z²)
```

- 上标 `[l]` 表示第 l 层
- `Z` 是线性变换结果（预激活值）
- `A` 是激活后的值

### 4.2 矩阵运算与维度匹配

假设：
- 输入 X 维度：`(n_features, batch_size)`
- 隐藏层 3 个神经元
- 输出层 1 个神经元

则维度流转：

```
X:   (2, m)      ← 2个特征，m个样本
W¹:  (3, 2)      ← 3个神经元，每个接2个输入
b¹:  (3, 1)
Z¹:  (3, m) = W¹·X + b¹
A¹:  (3, m)
W²:  (1, 3)
b²:  (1, 1)
Z²:  (1, m) = W²·A¹ + b²
A²:  (1, m)      ← 最终预测
```

> **要点**：权重矩阵的行数 = 当前层神经元数，列数 = 上一层神经元数。

### 4.3 NumPy 实现正向传播

```python
import numpy as np

def relu(x):
    return np.maximum(0, x)

def sigmoid(x):
    return 1 / (1 + np.exp(-x))

def forward(X, W1, b1, W2, b2):
    Z1 = np.dot(W1, X) + b1
    A1 = relu(Z1)
    Z2 = np.dot(W2, A1) + b2
    A2 = sigmoid(Z2)
    return A2, (Z1, A1, Z2, A2)
```

---

## 五、反向传播算法核心（30 分钟）

### 5.1 问题引入（衔接课2）

课2中我们用梯度下降更新参数：`θ = θ - η·∂L/∂θ`。

对于线性回归，参数只有 w 和 b，梯度好算。但神经网络有**成千上万**个参数，分布在每一层——如何高效计算损失对每一个参数的梯度？

**答案**：反向传播（Backpropagation）——利用链式法则，从输出层向输入层逐层计算梯度。

### 5.2 链式法则

对于复合函数 `L = f(g(h(x)))`：

```
∂L/∂x = ∂L/∂f · ∂f/∂g · ∂g/∂h · ∂h/∂x
```

神经网络就是一个巨大的复合函数，损失 L 经过输出层→隐藏层→输入层层层复合。

### 5.3 误差项 δ 的定义

定义第 l 层的误差项：

```
δ[l] = ∂L/∂Z[l]
```

它表示"第 l 层预激活值的微小变化对损失的影响"。

### 5.4 两层网络的完整推导

**已知**：MSE 损失 `L = ½(A² - Y)²`，隐藏层 ReLU，输出层线性（回归任务）

**Step 1：输出层误差**

```
δ² = ∂L/∂Z² = (A² - Y) · σ'(Z²)
```

若输出层是线性激活（σ'(z)=1），则 `δ² = A² - Y`。

**Step 2：输出层参数梯度**

```
∂L/∂W² = δ² · (A¹)ᵀ
∂L/∂b² = δ²
```

**Step 3：隐藏层误差（梯度传递）**

```
δ¹ = (W²)ᵀ · δ² ⊙ ReLU'(Z¹)
```

其中 `⊙` 是逐元素相乘，`ReLU'(z) = 1 if z>0 else 0`。

**Step 4：隐藏层参数梯度**

```
∂L/∂W¹ = δ¹ · Xᵀ
∂L/∂b¹ = δ¹
```

### 5.5 反向传播的直觉理解

- 梯度从输出端"反向"流向输入端
- 每一层的误差 = 后一层误差经权重转置传递后，乘以本层激活函数的导数
- 算出 δ 后，参数梯度 = δ × 前一层激活值的转置

> **与课2的联系**：反向传播只是"高效计算梯度的方法"，算出梯度后，仍然用课2学的梯度下降（SGD/MBGD）来更新参数。反向传播 ≠ 优化算法，它是梯度计算算法。

### 5.6 NumPy 实现反向传播

```python
def backward(X, Y, cache, W1, W2):
    Z1, A1, Z2, A2 = cache
    m = X.shape[1]

    dZ2 = A2 - Y                           # δ²
    dW2 = np.dot(dZ2, A1.T) / m
    db2 = np.sum(dZ2, axis=1, keepdims=True) / m

    dZ1 = np.dot(W2.T, dZ2) * (Z1 > 0)     # δ¹，ReLU导数
    dW1 = np.dot(dZ1, X.T) / m
    db1 = np.sum(dZ1, axis=1, keepdims=True) / m

    return dW1, db1, dW2, db2
```

---

## 六、深度模型典型训练全流程（15 分钟）

### 6.1 完整闭环

```
┌─────────────────────────────────────────────┐
│  1. 数据加载（课2：训练集/验证集/测试集）      │
│  2. 前向计算 → 得到预测 A²                     │
│  3. 计算损失 L                                │
│  4. 反向传播 → 得到所有参数梯度                │
│  5. 参数更新（课2：梯度下降）                  │
│  6. 重复 2-5，直到收敛                        │
│  7. 验证集评估 → 早停/调参（课2：过拟合监控）   │
└─────────────────────────────────────────────┘
```

### 6.2 损失函数选择

| 任务类型 | 损失函数 |
|---|---|
| 回归 | MSE（均方误差） |
| 二分类 | Binary Cross-Entropy |
| 多分类 | Cross-Entropy |

### 6.3 优化器演进

- **SGD**（课2已学）：基础梯度下降
- **SGD + Momentum**：加入惯性，加速收敛、抑制震荡
- **Adam**：自适应学习率，目前最常用的默认选择

### 6.4 深度学习中的过拟合（衔接课2）

课2讲了过拟合的概念。深度网络参数极多，更容易过拟合。常用正则化手段：

- **Dropout**：训练时随机"丢弃"部分神经元，强迫网络不依赖任何单一特征
- **权重衰减（L2 正则化）**：在损失中加入权重的 L2 范数
- **早停（Early Stopping）**：验证集损失不再下降时停止训练
- **数据增强**：扩充训练数据多样性

---

## 七、浅层神经网络的代码实现与调优（25 分钟）

### 7.1 PyTorch 基础概念

- `Tensor`：类似 NumPy ndarray，但支持 GPU 和自动求导
- `autograd`：自动计算梯度，无需手写反向传播
- `nn.Module`：模型基类，`nn.Linear` 是全连接层

### 7.2 完整训练代码

```python
import torch
import torch.nn as nn
import numpy as np
import matplotlib.pyplot as plt

torch.manual_seed(42)

# 1. 生成非线性数据：y = sin(x) + 噪声
X = np.linspace(-np.pi, np.pi, 200).reshape(-1, 1)
Y = np.sin(X) + 0.1 * np.random.randn(*X.shape)
X_tensor = torch.tensor(X, dtype=torch.float32)
Y_tensor = torch.tensor(Y, dtype=torch.float32)

# 2. 定义模型
class MLP(nn.Module):
    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(1, 32),
            nn.ReLU(),
            nn.Linear(32, 32),
            nn.ReLU(),
            nn.Linear(32, 1)
        )
    def forward(self, x):
        return self.net(x)

model = MLP()
criterion = nn.MSELoss()
optimizer = torch.optim.Adam(model.parameters(), lr=0.01)

# 3. 训练循环
losses = []
for epoch in range(1000):
    pred = model(X_tensor)
    loss = criterion(pred, Y_tensor)

    optimizer.zero_grad()   # 清零梯度
    loss.backward()         # 反向传播
    optimizer.step()        # 参数更新

    losses.append(loss.item())
    if epoch % 200 == 0:
        print(f"Epoch {epoch}, Loss: {loss.item():.6f}")

# 4. 可视化
with torch.no_grad():
    Y_pred = model(X_tensor).numpy()

plt.figure(figsize=(10, 4))
plt.subplot(1, 2, 1)
plt.plot(losses)
plt.title("Training Loss")
plt.subplot(1, 2, 2)
plt.scatter(X, Y, s=10, label="data")
plt.plot(X, Y_pred, 'r', label="prediction")
plt.legend()
plt.show()
```

### 7.3 调优要点

| 超参数 | 作用 | 调整建议 |
|---|---|---|
| 学习率 lr | 步长大小 | 太大震荡不收敛，太小收敛慢；Adam 默认 1e-3 |
| 隐藏层宽度 | 表达能力 | 从 32/64 开始，欠拟合则增大 |
| 隐藏层深度 | 特征抽象层次 | 简单任务 1-2 层即可 |
| 激活函数 | 非线性类型 | ReLU 默认，尝试 LeakyReLU |
| 批次大小 | 梯度估计稳定性 | 小批量（32/64）通常效果好 |
| 训练轮数 | 拟合程度 | 监控验证损失，早停防过拟合 |

---

## 八、HuggingFace Transformers API 基础（15 分钟）

### 8.1 平台简介

HuggingFace 是 AI 领域的"GitHub"，核心组件：

- **Model Hub**：预训练模型仓库（数十万模型）
- **Datasets**：数据集共享平台
- **Transformers**：统一的模型调用库
- **Spaces**：在线 Demo 部署

### 8.2 最简单的调用：pipeline

```python
from transformers import pipeline

# 情感分析
classifier = pipeline("sentiment-analysis", model="distilbert-base-uncased-finetuned-sst-2-english")
result = classifier("I love this course!")
print(result)
# [{'label': 'POSITIVE', 'score': 0.9998}]
```

`pipeline` 封装了：分词→模型推理→后处理，一行代码完成任务。

### 8.3 灵活调用：AutoTokenizer + AutoModel

```python
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch

model_name = "distilbert-base-uncased-finetuned-sst-2-english"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSequenceClassification.from_pretrained(model_name)

text = "Deep learning is amazing."
inputs = tokenizer(text, return_tensors="pt")

with torch.no_grad():
    outputs = model(**inputs)
    probs = torch.softmax(outputs.logits, dim=-1)

print(probs)
```

### 8.4 常见 pipeline 任务

| 任务标识 | 功能 |
|---|---|
| `sentiment-analysis` | 情感分析 |
| `text-generation` | 文本生成 |
| `summarization` | 文本摘要 |
| `translation_en_to_zh` | 英中翻译 |
| `question-answering` | 问答 |
| `image-classification` | 图像分类 |

---

## 九、课后作业

1. **必做**：运行课件中全部代码（NumPy 正向/反向传播、PyTorch MLP 训练、HuggingFace pipeline），理解每一步的作用
2. **必做**：用 PyTorch 实现一个 MLP，拟合课2作业中的函数 `f = x + y² + z³`，对比线性回归的效果，写一段分析
3. **选做**：使用 HuggingFace pipeline 完成一个文本分类任务，尝试更换至少 2 个不同模型，对比结果差异

---

## 十、下节课预告

- 卷积神经网络（CNN）：图像特征提取
- 循环神经网络（RNN/LSTM）：序列数据建模
- Transformer 架构详解：Attention 机制

---

## 附录：课2→课4 知识映射总表

| 课2概念 | 课4中的延伸 |
|---|---|
| 线性回归 | MLP 是线性层 + 激活函数的堆叠，输出层可视为线性回归 |
| 梯度下降 | 反向传播负责算梯度，梯度下降负责用梯度更新参数 |
| 批量/随机/小批量 GD | PyTorch DataLoader 实现 mini-batch 训练 |
| 过拟合 | 深度网络过拟合更严重，引入 Dropout/权重衰减/早停 |
| 训练集/验证集/测试集 | 训练流程不变，验证集用于早停和超参选择 |
| 损失函数 | 从 MSE 扩展到交叉熵等多种任务相关损失 |
