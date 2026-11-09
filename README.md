# 🪓 Steel Scheme & Strict Paredit Emacs IDE

专为 **Rust Steel Scheme (0.8.2+)** 交互式 REPL 开发与 **Strict Paredit 结构化括号编程** 量身打造的专业 Emacs 配置。

彻底告别 Lisp/Scheme 中的“数括号、删错括号、缩进混乱”的括号地狱，将代码编辑提升为纯粹的语法树（AST）变形艺术。

---

## 🧠 核心心智模型（The Strict Paredit Mindset）

在传统字符编辑器中，括号只是零散的文本标点；而在 **Strict Paredit** 哲学下：

1. **括号结构是神圣不可侵犯的实体**：括号永远成对平衡，代码只能在合法树结构间变形。
2. **永远不要手工键入或删除单边括号**：
   * 想把代码套进括号？用 **`Alt + H`**（圆括号）或 **`Alt + Shift + H`**（方括号）。
   * 想把外部代码纳入现有括号？用 **`Alt + L`**（向右吞噬 Slurp）。
   * 想把括号内末尾项踢出去？用 **`Alt + J`**（向左吐出 Barf）。
   * 想去掉一层外壳括号？用 **`Alt + O`**（脱壳解包 Splice）。
3. **右手 H-J-K-L 四轴八态主键矩阵 + W/S 纵深穿梭**：
   * **`H` 轴**：Hold / Hug 包裹（`Alt + H` 圆括号 / `Alt + Shift + H` 方括号，100% 避开 Mac 系统死键）。
   * **`J` 轴**：向左收缩与切分（`Alt + J` 左吐出 Barf / `Alt + Shift + J` 列表切分 Split）。
   * **`K` 轴**：纵向呼吸扩缩（`Alt + K` 选区外扩 Expand / `Alt + Shift + K` 选区内缩 Contract）。
   * **`L` 轴**：向右吸入与对调（`Alt + L` 右吸入 Slurp / `Alt + Shift + L` 相邻对调 Transpose）。
   * **`W / S` 轴**：纵深穿梭（`Alt + W` 钻入深层 Step Into / `Alt + S` 跳出外层 Step Out）。

---

## ⌨️ 完整快捷键速查表 (The 17-Key System)

全套快捷键全面覆盖 Windows / Linux / macOS（Mac 自动将 `Option (⌥)` 映射为 `Meta (Alt)`，绝不触发系统重音死键）：

| 频级 / 占比 | 快捷键 (Win/Linux) | macOS (⌥ Option) | 命令动作 | 功能说明与代码变形效果 |
| :--- | :--- | :--- | :--- | :--- |
| ⭐⭐⭐⭐⭐ (45%) | **`Alt + Enter`**<br>`Ctrl + Enter` | **`⌥ + ↵`**<br>`⌘ + ↵` | **发射求值** (Eval DWIM) | 提取当前最内层表达式或选区，瞬间送入 Steel REPL 求值并带高亮闪烁 |
| ⭐⭐⭐⭐⭐ (45%) | **`Alt + K`** | **`⌥ + K`** | **向外扩选** (Expand) | 右手主键呼吸外扩：从符号 $\rightarrow$ 当前括号 $\rightarrow$ 外层函数 |
| ⭐⭐⭐⭐ (25%) | **`Alt + H`** | **`⌥ + H`** | **圆括号包裹** (Wrap Round) | `target` $\rightarrow$ `(target)`（Hold/Hug 零死键） |
| ⭐⭐⭐⭐ (25%) | **`Alt + Shift + H`** | **`⌥ + ⇧ + H`** | **方括号包裹** (Wrap Square) | `x 10` $\rightarrow$ `[x 10]`（写 `let`、`cond` 专用） |
| ⭐⭐⭐⭐ (20%) | **`Alt + L`** | **`⌥ + L`** | **向右吞噬** (Slurp) | `(a b) c` $\rightarrow$ `(a b c)`（L 偏右吸入） |
| ⭐⭐⭐⭐ (20%) | **`Alt + J`** | **`⌥ + J`** | **向左吐出** (Barf) | `(a b c)` $\rightarrow$ `(a b) c`（J 偏左收缩，踢出末尾项） |
| ⭐⭐⭐ (15%) | **`Alt + Shift + K`** | **`⌥ + ⇧ + K`** | **向内收缩** (Contract) | 选区历史回退，往回收缩一级（呼应 `Alt+K`） |
| ⭐⭐⭐ (10%) | **`Alt + O`** | **`⌥ + O`** | **脱壳解包** (Splice) | `(wrapper (+ 1 2))` $\rightarrow$ `(+ 1 2)`（打碎外壳提取内容） |
| ⭐⭐⭐ (10%) | **`Alt + 3`** | **`⌥ + 3`** | **选中顶级定义** (Defun) | 无论光标藏得多深，一键完整选中最外层 `(define ...)` |
| ⭐⭐⭐ (10%) | **`Alt + 2`** | **`⌥ + 2`** | **大步前进** (Forward Sexp) | 光标直接跨过右侧整组完整 S-expression |
| ⭐⭐⭐ (10%) | **`Alt + 1`** | **`⌥ + 1`** | **大步后退** (Backward Sexp) | 光标直接跨过左侧整组完整 S-expression |
| ⭐⭐ (5%) | **`Alt + W`** | **`⌥ + W`** | **步进深入** (Step Into) | 跳进当前/下一层括号内部第一个参数前（钻入深层） |
| ⭐⭐ (5%) | **`Alt + S`** | **`⌥ + S`** | **步退跳出** (Step Out) | 跳回当前外层括号开头（撤退跳出） |
| ⭐⭐ (5%) | **`Alt + \`** | **`⌥ + \`** | **智能排版** (Reindent) | 按 Lisp 规范一键重新对齐当前 Defun 或选区 |
| ⭐⭐ (5%) | **`Alt + Shift + X`**<br>`C-M-k` | **`⌥ + ⇧ + X`** | **向后整块删除** (Kill Sexp) | 完整删掉光标右侧整组子表达式（绝不破坏括号平衡） |
| ⭐ (2%) | **`Alt + Shift + L`** | **`⌥ + ⇧ + L`** | **相邻对调** (Transpose) | `(equal? a b)` $\rightarrow$ `(equal? b a)`，相邻两项瞬间互换 |
| ⭐ (2%) | **`Alt + Shift + J`** | **`⌥ + ⇧ + J`** | **列表切分** (Split) | `(a b \| c d)` $\rightarrow$ `(a b) (c d)`，光标处一分为二 |

---

## ⚡ Steel Scheme 交互式 REPL 工作流

本配置深度整合原生 Rust 编译的常驻 **Steel Scheme (0.8.2)** 交互式解释引擎：

### 1. REPL 快捷键速查

| 快捷键 | 命令 | 说明 |
| :--- | :--- | :--- |
| **`Alt + Enter`** / **`Ctrl + Enter`** | `steel-eval-dwim` | **单发求值**：自动识别光标所在的最内层表达式或选区，送入 REPL 并带 Pulse 视觉闪烁 |
| **`C-c C-c`** / **`C-M-x`** | `steel-send-definition` | 发送当前整个 `(define ...)` 顶级定义到 REPL |
| **`C-c C-b`** | `steel-send-buffer` | 发送当前整个文件缓冲到 REPL |
| **`C-c C-r`** | `steel-send-region` | 发送当前选中的代码区域到 REPL |
| **`C-c C-q`** | `steel-hide-repl` | **关闭/隐藏右侧 REPL 窗口**（进程仍在后台运行，定义的函数不丢失） |
| **`C-c C-z`** | `steel-toggle-repl` | **智能呼出 / 切换 / 折叠**（在 REPL 内按直接关闭 REPL 回到代码） |
| **`C-c C-d`** | `steel-kill-repl` | **彻底杀死 Steel REPL 进程**并关闭窗口 |
| **`C-x 1`** (通用) | `delete-other-windows` | 在左侧编辑区按：**左侧瞬间 100% 全屏，右侧 REPL 立即关闭收起** |
| **`C-x 0`** (通用) | `delete-window` | 光标在右侧 REPL 窗口时按：直接关闭当前 REPL 窗口 |
| **`C-c C-l`** | `steel-clear-repl` | 清空当前 REPL 输出历史 |
| **`C-c C-k`** | `steel-restart-repl` | 遇到死循环或异常时一键重启 Steel REPL |
| **`C-c C-s`** / **`M-x run-steel`** | `run-steel` | 启动或显示 Steel REPL 会话 |

### 2. 动态自适应分屏
* **宽屏（>120列）**：自动按 **60 : 40** 黄金比例左右分屏（左侧写代码，右侧常驻 Steel REPL）。
* **窄屏**：自动按 **70 : 30** 上下分屏。
* **REPL 内部同样开启 Strict Paredit 与 Rainbow Delimiters**，在 REPL 命令行键入代码同样享受 100% 括号平衡保护。

### 3. Steel 专属语法与缩进
* 支持 Steel / Racket 专属关键字：`struct`, `when`, `unless`, `fn`, `λ`, `define-syntax`, `syntax-rules`, `syntax-case`, `match`, `transduce`, `into-list`, `assert!`, `assert-equal!`。
* 自动格式化对齐 `when`、`unless`、`struct` 等高阶表单。
* 内置 `prettify-symbols-mode`，自动将 `lambda` 与 `fn` 优雅渲染为 `λ`。

---

## 🎨 现代极客 UI 与辅助生态

* **主题**：`doom-one` 暗黑极客主题。
* **彩虹括号**：`rainbow-delimiters`，括号随嵌套深度自动色彩区分，一目了然。
* **快捷键提示**：`which-key`，按下前缀键（如 `C-c`）悬停 0.4 秒自动浮动提示可用按键。
* **轻量级搜索补全**：`vertico` + `orderless` + `marginalia`，Minibuffer 模糊空格任意匹配。
* **代码自动补全**：`corfu`，极速浮窗代码补全提示。

---

## 🚀 极速上手与运行

### 1. 尝试演练文件
在终端运行：
```bash
emacs /workspace/scheme_emacs/sample.scm
```
或终端无图形界面模式：
```bash
emacs -nw /workspace/scheme_emacs/sample.scm
```

打开后：
1. 按下 **`C-c C-s`**（或 `M-x run-steel`）启动 Steel REPL。
2. 光标停留在 `(fib 10)` 上，按 **`Alt + Enter`**（Mac: `⌥ + ↵`），右侧立刻返回 `=> 55`！
3. 跟随 `sample.scm` 中的演练注释体验 17 个 Strict Paredit 快捷键。

### 2. 运行自动化单元测试套件
本项目包含完整的 ERT (Emacs Regression Testing) 测试矩阵，覆盖 17 个按键映射、结构变形与真实 Steel REPL 通信：
```bash
emacs -batch -l /workspace/scheme_emacs/test_config.el -f ert-run-tests-batch-and-exit
```

---

## 📂 项目结构

```text
/workspace/scheme_emacs/
├── early-init.el         # 启动性能优化 (GC 阈值 / 抑制早期 UI 闪烁)
├── init.el               # 入口配置文件 (PATH 注入 / 包自动拉取 / 平台适配)
├── lisp/
│   ├── strict-paredit.el # Strict Paredit H-J-K-L + W/S 核心变形矩阵
│   ├── steel-scheme.el   # Steel 解释器联动 / REPL 引擎 / 求值 DWIM / 语法高亮
│   └── ui.el             # 主题 / 彩虹括号 / Which-Key / 补全生态
├── sample.scm            # 完整的 Steel Scheme 互动演练与快捷键靶场
├── test_config.el        # 自动化回归测试套件 (7/7 全部通过)
└── README.md             # 本手册
```
