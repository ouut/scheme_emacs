# 🪓 Steel Scheme & Strict Paredit Emacs IDE

专为 **Rust Steel Scheme (0.8.2+)** 交互式 REPL 开发与 **Strict Paredit 结构化括号编程** 量身打造的专业 Emacs 配置。

彻底告别 Lisp/Scheme 中的“数括号、删错括号、缩进混乱”的括号地狱，将代码编辑提升为纯粹的语法树（AST）变形艺术。

---

## ⚡ Linux 一键安装、启动与随时复用 (Universal Runner)

在任何 Linux 机器终端中执行以下单行命令，将全自动配置并**立即启动 Scheme Emacs**：

```bash
curl -fsSL https://raw.githubusercontent.com/ouut/scheme_emacs/main/scheme-emacs.sh | bash
```

### 🔁 幂等性与自我持久化（Run Once, Use Anywhere）
* **100% 幂等性**：
  * **首次运行**：检测系统环境，极速安装就绪（宿主无 Emacs 时自动拉取全内置单文件 AppImage，**无需 root / sudo**；已有 Emacs 时安装 6.5MB 轻量包）；
  * **后续重复运行**：毫秒级秒开，**绝不重复下载**数百兆文件！
* **自动将脚本留存在当前目录**：
  * 脚本运行后，会**自动在当前项目目录下创建一份可执行的 `./scheme-emacs.sh`**；
  * 下次在项目目录写代码时，直接运行：
    ```bash
    ./scheme-emacs.sh              # 启动并打开 sample.scm 练习
    ./scheme-emacs.sh my_code.scm  # 打开指定代码文件
    ./scheme-emacs.sh -nw          # 终端字符模式
    ./scheme-emacs.sh --update     # 强制检测并升级到最新版本
    ```
  * 当然，继续使用 `curl -fsSL ... | bash` 同样是幂等秒开！并且系统命令 `scheme-emacs` 随时全局可用。

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
make test
# 或使用原生命令:
emacs -batch -l test_config.el -f ert-run-tests-batch-and-exit
```

---

## 🛠️ 本地开发环境搭建与贡献指南 (Developer Guide)

如果你需要二次开发、调试配置或向本项目贡献代码，可以通过以下步骤极速搭建完整的本地开发环境：

### 1. 前置依赖要求
* **GNU Emacs 28+**（建议 29+）：
  * Ubuntu / Debian: `sudo apt install emacs-nox`（终端版）或 `sudo apt install emacs`（图形版）
  * macOS: `brew install emacs`
  * Arch Linux: `sudo pacman -S emacs`
  * Fedora: `sudo dnf install emacs`
* **Rust & Cargo**（1.70+）：
  * 官方安装：`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`

---

### 2. 一键自动化配置（推荐）

Clone 仓库后，只需在项目根目录执行：
```bash
make setup
# 或直接运行初始化脚本:
./scripts/setup-dev.sh
```

**该脚本全自动执行以下 5 项任务**：
1. **环境检测**：检查 Emacs 与 Rust 编译器是否完备，缺失时提示一键安装命令；
2. **构建 Steel**：自动通过 `cargo install steel-interpreter --version 0.8.2 --locked` 编译 Rust 官方解释器，并在 `bin/steel` 就绪；
3. **Vendoring 插件依赖**：以批处理隔离模式运行 Emacs，从 MELPA 镜像预下载所有需要的外部插件至本地 `elpa/` 目录；
4. **全量 AOT 预编译**：调用 `batch-byte-compile` 将所有 `.el` 源码预编译为 `.elc` 字节码；
5. **回归测试自检**：自动运行 7 项 ERT 单元测试套件，确保环境 100% 正常。

---

### 3. 日常开发常用命令速查 (`make`)

| 命令 | 对应动作 | 说明 |
| :--- | :--- | :--- |
| **`make setup`** | `./scripts/setup-dev.sh` | 首次配置或更新开发依赖环境 |
| **`make test`** | `emacs -batch -l test_config.el ...` | 运行 ERT 自动化回归测试（TDD 模式） |
| **`make run`** | `./bin/scheme-emacs sample.scm` | 以沙箱隔离模式启动 Scheme Emacs（不碰 `~/.emacs.d`） |
| **`make run-nw`**| `./bin/scheme-emacs -nw sample.scm`| 终端字符模式启动 |
| **`make compile`**| `batch-byte-compile` | 重新编译所有 `.el` 文件为 `.elc` 字节码 |
| **`make clean`** | 清理编译产物 | 删除所有 `.elc` 字节码与本地构建缓存 |
| **`make build`** | `./scripts/build.sh` | 本地打包轻量绿色 profile 分发包 |

---

### 4. 源码结构与二次开发入口

* **改动或新增快捷键、结构变换**：
  * 修改 [`lisp/strict-paredit.el`](lisp/strict-paredit.el)，并在 [`test_config.el`](test_config.el) 中追加对应的断言测试用例。
* **修改 Steel Scheme 交互与 REPL 协议**：
  * 修改 [`lisp/steel-scheme.el`](lisp/steel-scheme.el)，调试 comint 管道通信、求值高亮与输出过滤器。
* **定制配色主题、字体与补全扩展**：
  * 修改 [`lisp/ui.el`](lisp/ui.el)，可自由切换 `doom-one`、`doom-gruvbox` 或自定义注释颜色。

---

## 📦 全平台独立绿色版分发与 CI/CD 自动构建 (Standalone Multi-Platform Release)

本项目提供 **Linux、macOS、Windows 三大平台 100% 独立自包含的绿色免安装发行版**。每个分发包均内置了 **GNU Emacs 核心引擎 + Rust Steel Scheme 解释器 + 全量预编译字节码 (.elc) + Vendored 离线扩展包**，实现**零外部依赖、不污染系统、开箱即用**。

### 1. 三大平台绿色免安装产物一览

| 平台 | 产物形态 | 使用方式 | 特性说明 |
| :--- | :--- | :--- | :--- |
| **Linux** | **`scheme-emacs-*.AppImage`**<br>`scheme-emacs-*.tar.gz` | `chmod +x *.AppImage && ./*.AppImage sample.scm` | 纯单文件二进制（AppImage），全内置 Emacs 与 Steel，任何 Linux 发行版免装运行；同时提供 6.7MB 轻量配置包（tar.gz） |
| **macOS** | **`SchemeEmacs-*.dmg`**<br>`SchemeEmacs-*.zip` | 打开 DMG 拖入 Applications 或解压即用 | 原生 macOS Application Bundle（Universal 架构支持 Apple Silicon M系列与 Intel），内置 Steel 与原生 Emacs |
| **Windows** | **`scheme-emacs-*-windows-x86_64.zip`** | 解压后双击 **`run.bat`** (GUI) 或 **`run-terminal.bat`** (控制台) | 纯绿色便携包，内置 GNU Emacs 29.4、`steel.exe` 及运行时 DLL，不写注册表，随拷随用 |

---

### 2. 各平台快速启动指南

#### 🐧 Linux 用户
```bash
# 赋予执行权限并直接运行单二进制 AppImage (免装 Emacs / 免装 Rust)
chmod +x scheme-emacs-*-linux-x86_64.AppImage
./scheme-emacs-*-linux-x86_64.AppImage sample.scm
```

#### 🍎 macOS 用户
1. 下载 `SchemeEmacs-*-macos.dmg`，双击挂载后将 `SchemeEmacs.app` 拖入 `Applications` 文件夹；
2. 双击图标直接运行；如需在终端快速调起，可在 `~/.zshrc` 添加快捷别名：
   ```bash
   alias scheme-emacs="/Applications/SchemeEmacs.app/Contents/MacOS/SchemeEmacs"
   ```
> *注：首次打开若遇 macOS Gatekeeper 提示，在“系统设置 -> 隐私与安全性”中允许打开，或在终端运行 `xattr -cr /Applications/SchemeEmacs.app` 即可。*

#### 🪟 Windows 用户
1. 下载 `scheme-emacs-*-windows-x86_64.zip` 并解压到任意目录（例如 `D:\tools\scheme-emacs` 或 U 盘）；
2. **双击 `run.bat`**：启动图形界面 Emacs（自动静默后台，不弹出 DOS 黑框）；
3. **双击 `run-terminal.bat`**：在当前 Windows Terminal / CMD 窗口中以终端字符模式运行。

---

### 3. 本地全平台打包脚本 (scripts/)
* **`scripts/build.sh`**：构建 Linux 轻量 profile 归档（`.tar.gz`）。
* **`scripts/build-appimage.sh`**：组装打包 Linux 单二进制 `AppImage`。
* **`scripts/build-macos.sh`**：组装打包 macOS `SchemeEmacs.app`、`.zip` 与 `.dmg` 镜像。
* **`scripts/build-windows.ps1`**：组装打包 Windows 绿色便携包（`.zip`）。

---

### 4. GitHub Actions 自动化云端矩阵构建
仓库配置了全自动跨平台 CI/CD 工作流 [`.github/workflows/release.yml`](.github/workflows/release.yml)。当推送版本标签时：
```bash
git tag v0.2.0
git push origin v0.2.0
```
云端流水线将同时启动三台虚拟机并行构建：
* 🐧 **Ubuntu Runner**：编译 Linux 版 Steel，运行回归测试，产出 `AppImage` 与 `tar.gz`；
* 🍎 **macOS Runner**：编译 Apple Silicon 原生 Steel，产出 Universal `SchemeEmacs.dmg` 与 `.zip`；
* 🪟 **Windows Runner**：编译 Windows 原生 `steel.exe`，注入 Emacs 29.4，产出 Windows 便携版；
* 🚀 **Release Aggregator**：聚合三端所有构建产物与校验哈希，全自动同步发布至 [GitHub Releases](https://github.com/ouut/scheme_emacs/releases)。

---

## 📂 项目结构

```text
/workspace/scheme_emacs/
├── .github/
│   └── workflows/
│       └── release.yml     # 跨平台 (Linux/macOS/Windows) 自动化测试与 Release 发布流水线
├── assets/
│   ├── scheme-emacs.svg    # 专属设计矢量图标 (λ + Emacs环 + 括号美学)
│   ├── scheme-emacs.png    # 高清光栅应用图标
│   └── scheme-emacs.desktop# Linux XDG 桌面入口规范文件
├── bin/
│   └── scheme-emacs        # Linux/macOS 独立便携启动脚本 (沙箱隔离 ~/.emacs.d)
├── scheme-emacs.sh         # 🚀 Linux 一键安装、启动与自我持久化通用 Runner (curl | bash 专用)
├── Makefile                # 常用开发任务 (make setup, test, run, compile, clean)
├── scripts/
│   ├── setup-dev.sh        # 本地开发环境一键搭建脚本 (优先拉取官方预编译二进制)
│   ├── build.sh            # Linux 轻量 profile 构建脚本
│   ├── build-appimage.sh   # Linux 单文件 AppImage 打包脚本
│   ├── build-macos.sh      # macOS .app / .dmg / .zip 打包脚本
│   └── build-windows.ps1   # Windows 绿色便携包打包脚本 (PowerShell)
├── early-init.el           # 启动性能优化 (GC 阈值 / 抑制早期 UI 闪烁)
├── init.el                 # 入口配置文件 (PATH 注入 / 包自动拉取 / 平台适配)
├── lisp/
│   ├── strict-paredit.el   # Strict Paredit H-J-K-L + W/S 核心变形矩阵
│   ├── steel-scheme.el     # Steel 解释器联动 / REPL 引擎 / 求值 DWIM / 语法高亮
│   └── ui.el               # 主题 / 高对比度注释 / 彩虹括号 / Which-Key / 补全生态
├── sample.scm              # 完整的 Steel Scheme 互动演练与快捷键靶场
├── test_config.el          # 自动化回归测试套件 (7/7 全部通过)
└── README.md               # 本手册
```
