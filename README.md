# Desktop Fishing · 桌面钓鱼

**Godot 4.6.1 + GDScript，0.7.0-preview 番茄钟专注钓鱼。** 当前工程已移除 Electron、Node.js 和网页 UI 实现。

## 下载直接试玩

在 GitHub 仓库 Actions 打开成功的 **Godot Windows Build**，从 Artifacts 下载 **desktop-fishing-godot-windows**。解压后双击 `DesktopFishing.exe`。该程序内嵌游戏资源，不需要安装 Godot 或 Node.js。

## 在 Godot 中运行

1. 下载 Godot **4.6.1 Standard**（普通版，不需要 .NET）。
2. 下载或克隆本仓库，在 Godot 项目管理器点击 Import，选择根目录 `project.godot`。
3. 打开项目后按 **F6/F5**（运行当前场景/项目）；测试 Windows 专注检测时，请从项目菜单关闭“嵌入游戏”选项，使用独立游戏窗口。嵌入编辑器的运行方式不作为 Windows 专注判定验收环境。

命令行运行（Godot 已加入 PATH）：

```powershell
godot --path .
```

## 玩法

设定时长 → 放竿开始番茄钟 → 可暂停/继续 → 完成后手动起竿 → 从对应时间档独立鱼池抽取 → 图鉴登记 → 收进鱼缸或放生。

- 15–29分钟仅A组，30–59分钟仅B组，60–120分钟仅C组；组内权重为普通6、少见3、稀有1。星愿鱼不进入常规抽取，留待特殊事件。
- 专注由用户自己定义：前台、查看图鉴、无键鼠输入均继续。手动暂停、锁屏/休眠/会话断开停止；恢复后手动继续。退出期间不计时，重启保持暂停；已完成仍可起竿。
- 提前起竿先询问确认，确认后本次失败且无鱼获；取消保留原状态。放竿后不能修改时长。完成后延迟起竿不改变鱼池，不自动抽鱼或启动下一轮。
- 6条精选鱼、独立ID和体长、满缸替换、放生不删图鉴及新纪录反馈保留。
- v1/v2/v3存档升级到v4：收藏、纪录、鱼缸、待安置鱼获保留；旧进行中下潜回到待设定，无自动鱼获。
- 三态均支持计时与操作；浮窗工具条提供放竿、起竿、透明度、图鉴及鱼缸，暂停/继续和剩余时间由A卡片提供，图鉴按A/B/C/特殊事件筛选。

完整规则、概率表和实机验收见 [番茄钟规则](docs/POMODORO_SPEC.md) 与 [番茄钟QA](docs/POMODORO_QA.md)。

## 模式二第五版接入

新增单向随机游鱼、水草/水面动态、前后遮挡、握竿支点、短线待机和实际鱼获翻卡。翻卡后固定展示，沿用原有番茄钟和图鉴鱼缸结算。[阶段记录与验收](docs/MODE2_V5_BUILD.md)。

## 人物、猫、钓具与特效补齐

小渔22帧、猫16帧、特效34帧和鱼竿/浮漂/鱼钩/水桶已接入。猫和桶从码头拆开，人物放钩/收杆有实际手臂姿态，揭晓后人物与猫短暂高兴，再恢复待机。待机、眨眼、尾巴、水花、水纹、气泡、钩端微光和鱼影由独立PNG与motion.animation.json驱动。手部逐帧握点与固定杆长的天空角度限制保证完整显示。探索特效暂停时停止推进。

[本轮计划](docs/STAGE4_VISUAL_PLAN.md)、[资源与集成验收](docs/STAGE4_ART_QA.md)、[实际场景动画](docs/qa/stage4/in-game.mp4)、[13动作预览](docs/qa/stage4/motion-preview.gif)。当前候选资源供用户最终视觉确认。

## 第三阶段：14生物与鱼缸分层素材

14种生物插画已全部接入鱼获、图鉴与鱼缸，未发现生物显示实际轮廓剪影。鱼缸使用独立背景、水面、前景三个图层。六鱼共同观赏区支持点击选择个体，已有替换/放生确认逻辑保留。普通鱼缓游，海马/水母漂浮，墨鱼缓慢推进，参数实际读取 `collection.animation.json`。首次发现/新纪录标记随鱼获持久化，旧存档不补造标签。

本批是最小收藏闭环，非第三阶段全部完成；素材保持 `integration_candidate`。[设计计划](docs/STAGE3_PLAN.md)、[验收记录](docs/STAGE3_ART_QA.md)、[提示词](docs/STAGE3_ART_PROMPTS.md)。

## 第二阶段：海边日常

已接入 V2.6 参考风格的独立海洋背景、透明码头与角色图层。放钩有抛线与入水波纹，收杆后再显示已保存的鱼获；动画可跳过，动画期间阻止重复操作。暂停时冻结探索气泡与鱼线微动，轻微环境动画继续。昼夜使用柔和调色，背景随深度轻微变化。

声音默认关闭，可在主界面开启并保存。声音为程序合成的轻水声与短动作提示。设置在原 v3 存档上向后兼容，旧存档默认静音。

- [第二阶段美术与交互验收](docs/STAGE2_ART_QA.md)
- [生成素材提示词](docs/STAGE2_ART_PROMPTS.md)
- 场景动画配置：`assets/production/scene.animation.json`；第二阶段原始图层补间已由本轮motion.animation.json的独立动作帧接替。

## 存档与锁屏检测

保存失败时操作回滚，保存退出失败则取消退出；未知版本存档不覆盖，损坏主存档可恢复有效备份。Windows查询进程仅提供锁屏/会话状态与连续性标记，失败保守暂停并提供重试。原键鼠/前台判定已移除，详见 docs/FOCUS_SPEC.md。

## 工程结构

- `scenes/main.tscn`：主场景入口。
- `scripts/core/`：可独立测试的钓鱼状态、计时策略和存档。
- `scripts/services/`：游戏服务与 Windows 检测生命周期。
- `scripts/ui/`：Godot 控件、弹窗和功能示意场景。
- `data/fish-data.json`：鱼种和抽取配置。
- `platform/windows/focus-worker.ps1`：一次启动的后台原生查询进程，每 0.5 秒提供最小状态。
- `assets/`、`docs/`：美术标准、资源清单和验收。

## 验证与导出

```powershell
godot --headless --editor --import --quit
godot --headless --script res://tests/run_tests.gd -- --tests
godot --headless --script res://tests/pomodoro_tests.gd -- --tests
godot --headless --script res://tests/pomodoro_ui_tests.gd -- --tests
godot --headless --script res://tests/stage2_tests.gd -- --tests
godot --headless --script res://tests/stage3_tests.gd -- --tests
godot --headless --script res://tests/stage4_tests.gd -- --tests
godot --headless --script res://tests/stage4_ui_tests.gd -- --tests
godot --headless --script res://tests/floating_art_tests.gd -- --tests
godot --headless --quit-after 180 -- --tests --ui-smoke
godot --headless --quit-after 180 -- --tests --ui-smoke --small
godot --headless --script res://tests/run_windows_focus.gd -- --tests
powershell -NoProfile -File tests/windows_focus_smoke.ps1
```

安装匹配的 Godot 4.6.1 导出模板后，在 Project → Export 选择 Windows Desktop，或执行：

```powershell
New-Item -ItemType Directory -Force build/windows
godot --headless --export-release "Windows Desktop" build/windows/DesktopFishing.exe
```

GitHub Actions 自动执行验证、Windows 查询脚本测试和 Windows 导出。

## 存档与隐私

Godot 存档目录：`%APPDATA%/DesktopFishingGodot/`，文件为 `save.json` 和 `save.json.bak`。每 30 秒保存进度，放钩/收杆/安置/正常退出立即保存。未知版本或两份存档都无法读取时暂停，避免覆盖数据。

Windows 查询脚本使用系统自带 PowerShell 调用 Win32，只返回空闲秒数、本游戏是否在前台、锁屏/会话不可用状态、采样时间与顺序。没有键盘钩子，不记录按键、窗口标题或应用使用历史。检测进程随游戏退出终止；脚本被系统策略阻止时，界面提示检测不可用并暂停。

旧版 v1/v2 存档格式可迁移，但不会自动扫描旧目录。需要迁移时，关闭游戏，备份新旧目录，再把旧 `save.json` 复制到 Godot 目录。已有 Godot 存档时不要直接覆盖。v1 未记录个体体长，迁移使用该鱼种历史最大体长。

## 当前限制

V2.6 主场景素材和分层动作已接入；14生物与鱼缸三层插画已接入，完整收藏演出仍待完善。主场景已补齐人物22帧、猫16帧与特效34帧；UI收尾仍待完成。鱼获仍使用收杆时抽取的 MVP 模型，生态范围和体长是玩法占位值。第一阶段用户已报告 Windows 实机验收通过；本轮视觉交互仍需实际试玩反馈。其他平台可打开 UI，但专注计时暂停。

## 三态窗口

主界面底部切换场景悬浮/极简悬浮。悬浮窗口左键拖动，右键菜单可切换、放钩/收杆、安置鱼获、设置置顶及保存退出；Escape 返回完整窗口。极简状态无常驻 UI。透明区域目前仍属于窗口鼠标命中区。位置与置顶独立保存，不改变钓鱼存档。Windows 实机验收项见 docs/WINDOW_LAYOUT_QA.md。

## A 方案番茄钟卡片

模式二右上方、模式三鱼竿上方常驻奶白圆角番茄钟，展示剩余时间、专注状态和进度，可直接暂停/继续；白天太阳、夜晚月亮。模式三窗口为180×176，保留原鱼竿小场景；模式切换共用同一挑战状态。正式组件13张RGBA及验收见 [A卡片交付](docs/POMODORO_CARD_A_QA.md)。


## 浮窗操作与鱼获展示

模式二、三悬停工具条支持放竿开始当前设定时长；透明度按钮展开30%–100%不透明度滑杆，两模式独立保存。场景与计时卡一起淡化，操作工具条保持清晰。工具条已移除暂停、时间和组别，A计时卡保留。

完成后起竿播放鱼获上浮及气泡，随后在场景旁展示鱼种、稀有度、体长、专注时长和首次发现/新纪录；支持收进鱼缸、放生确认和稍后安置。满缸可选择替换；稍后安置可由“鱼获”按钮再次打开。模式切换不会丢弃鱼获或重复抽鱼。

切换原生窗口尺寸后重建操作工具条，避免复用旧鼠标输入状态。验证记录与实际尺寸截图见 [浮窗交互QA](docs/FLOATING_CONTROLS_QA.md)。


## 自定义标题栏

完整模式使用36px奶白标题栏、蓝色浮标图标及最小化/最大化/保存关闭按钮。空白标题区域可拖动、双击最大化/还原；四边和四角可调整窗口大小，缩放后内容重新布局。切到浮窗会退出最大化，返回完整模式恢复之前的最大化状态。浮窗保持透明形态。

完整窗口默认1100×796，最小940×736；旧版已保存高度只迁移一次，增加36px以保留内容空间。应用与Windows EXE替换默认引擎图标。关闭使用既有保存退出流程，保存失败取消退出。实际截图与验收见 [窗口标题栏QA](docs/WINDOW_FRAME_QA.md)。
