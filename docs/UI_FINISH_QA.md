# 首版 UI 收尾检查

范围：主界面、图鉴、精选鱼缸、确认框；保持既有专注与收藏规则。

## 文字和交互

- 统一鱼获水深单位；首次发现和新纪录独立展示，长纪录文字自动换行。
- 待安置状态、空图鉴、空鱼缸、满缸均有明确说明。
- 满缸显示 `6 / 6`，替换界面标明待入住鱼获；关闭按钮为“取消替换”。
- 确认按钮区分“确认放生”和“确认替换”；取消、Esc、关闭不改变鱼获。
- 放钩、收杆按钮提供不可用原因；存档受阻时收藏仍可查看，鱼获管理按钮禁用。
- 操作错误在主界面及收藏窗口同时显示，刷新后仍保留，成功操作后清除。
- 从鱼缸放生有确认与成功反馈；保存失败保留原鱼及待安置鱼获，并允许重试。

## 小窗口

- 主窗口检查默认 `1100×760` 和最小 `940×700`。
- 鱼获待安置时收起放钩/收杆区，优先展示收纳和放生按钮。
- 收藏窗口最小 `560×420`；宽度小于 720 时卡片改为两列。
- 收藏窗口高度低于 520 时收起鱼缸全景，优先展示管理卡片；其他尺寸的全景随高度缩小。列表保留滚动区域，横向不需要滚动。
- 鱼缸内鱼的尺寸与上下漂移随高度缩小，六条鱼的点击区域互不覆盖。

## 自动验证与截图

```sh
godot --headless --quit-after 180 -- --tests --ui-smoke
godot --headless --quit-after 180 -- --tests --ui-smoke --small
godot --audio-driver Dummy --rendering-method gl_compatibility --quit-after 180 -- --tests --collection-capture --ui-review --small --tank --replace
```

UI 流程断言覆盖：空缸、满缸、首次揭晓、取消替换、阻止管理、提示刷新、保存失败保留双方、重试成功、放生。

Windows CI 生成以下截图并随可执行文件放入 `ui-preview`：

| 文件 | 场景 |
| --- | --- |
| catch-small.png | 小主窗口、满缸待安置、首次发现与新纪录 |
| tank-small-replace.png | 小收藏窗口、六条鱼、替换选择 |
| tank-small-replace-error.png | 替换界面的保存失败提示 |
| tank-small-empty.png | 空鱼缸 |
| book-small-undiscovered.png | 未发现图鉴 |
| tank-small-replace-confirm.png | 小窗口替换确认框 |

本轮本地 Godot 4.6.1 使用独立临时存档运行；截图使用 Noto CJK 字体检查。Windows 的截图生成、导出和启动由 CI 执行；真实系统的锁屏、休眠与前台检测继续按 `WINDOWS_STAGE1_ACCEPTANCE.md` 实机验收。
