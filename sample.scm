;;; sample.scm --- Steel Scheme & Strict Paredit Playground
;;;
;;; 💡 使用提示：
;;; 1. 按 M-x run-steel 或 C-c C-s 打开右侧/下方 Steel REPL。
;;; 2. 光标停留在任意 S-expression 或函数内，按【Alt + Enter】（Mac: ⌥ ↵）即可发射求值！
;;; 3. 选中代码区域按【Alt + Enter】求值选中部分。
;;; 4. 按【C-c C-c】一键求值当前顶级定义 (define ...)。
;;; 5. 按【C-c C-z】在代码编辑区与 REPL 之间智能呼出 / 切换 / 折叠关闭！
;;; 6. 按【C-c C-q】或在左侧代码区按【C-x 1】一键关闭右侧 REPL 窗口（后台保持运行）。
;;; 7. 按【C-c C-d】彻底终止 Steel REPL 进程。

;; =============================================================================
;; 1. 递归与基础函数 (Alt + Enter 求值体验)
;; =============================================================================

;; 斐波那契数列
(define (fib n)
  (if (<= n 1)
      n
      (+ (fib (- n 1))
         (fib (- n 2)))))

;; 阶乘
(define (factorial n)
  (if (<= n 1)
      1
      (* n (factorial (- n 1)))))

;; 试着光标放在下面任意一行，按 Alt + Enter 求值：
(fib 10)         ; => 55
(factorial 6)    ; => 720

;; =============================================================================
;; 2. Strict Paredit 快捷键演练靶场 (请跟随注释动手测试)
;; =============================================================================

;; 练习 1: 【Alt + H】圆括号包裹 (Wrap Parens)
;; 将光标放在下面的 "target" 上，按下 Alt + H：
;; 结果应变为：(target)
target

;; 练习 2: 【Alt + Shift + H】方括号包裹 (Wrap Square)
;; 适合 let 绑定。将光标放在 "x 10" 上选定或光标停在 x 上，按 Alt + Shift + H：
;; 结果应变为：[x 10]
x 10

;; 练习 3: 【Alt + L】向右吞噬 (Slurp) 与 【Alt + J】向左吐出 (Barf)
;; 将光标放在下面的 (apple banana) 内部：
;; - 按 Alt + L：右括号向右吞噬 orange，变成 (apple banana orange) pear
;; - 按 Alt + J：右括号向左收缩，把 orange 踢出去，恢复 (apple banana) orange pear
(apple banana) orange pear

;; 练习 4: 【Alt + O】脱壳解包 (Splice)
;; 将光标放在内部的 (+ 1 2) 括号内，按下 Alt + O：
;; 结果应打碎外壳变成 (+ 1 2)，剥去无用的 wrapper：
(wrapper (+ 1 2))

;; 练习 5: 【Alt + Shift + J】切分 (Split)
;; 将光标放在 2 和 3 之间的空格处，按 Alt + Shift + J：
;; 结果应从中间切分成两个独立的表：(1 2) (3 4)
(1 2  3 4)

;; 练习 6: 【Alt + Shift + L】相邻对调 (Transpose)
;; 将光标停在 alpha 上，按下 Alt + Shift + L：
;; 结果应交换位置变成 (equal? beta alpha)
(equal? alpha beta)

;; 练习 7: 【Alt + K】外扩 与 【Alt + Shift + K】内缩 (纵向呼吸)
;; 将光标停在下面的 "inner-value" 处：
;; - 连按 Alt + K：从 inner-value 扩到整个表，再扩到上一层
;; - 连按 Alt + Shift + K：收缩选区回溯历史
(outer-form (middle-form inner-value extra-arg))

;; 练习 8: 【Alt + W】钻入 与 【Alt + S】跳出 (纵深穿梭)
;; 将光标停在下面的外层括号处：
;; - 按 Alt + W：光标步进跳入第一层参数
;; - 按 Alt + S：光标步退跳出外层括号开头
(root (child (grandchild "treasure")))

;; =============================================================================
;; 3. Rust Steel 专属特性 (Structs, Higher-Order, Transducers)
;; =============================================================================

;; Steel 原生结构体
(struct Point (x y))

(define p (Point 10 20))
(Point-x p) ; => 10
(Point-y p) ; => 20

;; 高阶变换 (transduce / mapping / filtering)
(define numbers '(1 2 3 4 5 6 7 8 9 10))

(define even-squares
  (transduce numbers
             (compose
              (filtering even?)
              (mapping (fn (x) (* x x))))
             (into-list)))

;; 求值这行查看结果：
even-squares ; => (4 16 36 64 100)

;; =============================================================================
;; 4. Steel 宏系统 (syntax-rules)
;; =============================================================================

(define-syntax-rule (when-debug condition body ...)
  (when condition
    (displayln "DEBUG: ")
    body ...))

;; 模块断言测试
(assert-equal! (fib 5) 5)
(assert-equal! (factorial 5) 120)
