# Desktop Fishing · 桌面钓鱼

**Godot 4.6.1 + GDScript，0.4.0 Windows 场景试玩版。** 当前工程已移除 Electron、Node.js 和网页 UI 实现。

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

手动放钩 → 切换到其他工作窗口 → 每有效专注分钟下潜 4 米 → 回来手动收杆 → 按深度/本地昼夜抽取鱼获 → 图鉴登记 → 收进精选鱼缸或放生。

- 最大 200 米，14 个稳定生物 ID（其中水母/墨鱼为扩展种）。
- 游戏前台、锁屏、远程会话断开、超过所选空闲宽限（默认 10 分钟，可选 5/10/20 分钟）无键鼠输入及检测失败时暂停。
- 最多 6 条精选鱼，每条都有独立 ID 和体长。满缸时选择替换并确认；取消保留原鱼和待安置鱼获。
- 同一鱼获不能重复领取；未安置鱼获必须处理后再放钩。
- 图鉴记录发现次数和最大体长。放生不删除图鉴。
- 退出后恢复会话或待安置鱼获；退出、休眠间隔不补计。

## 第二阶段：海边日常

已接入 V2.6 参考风格的独立海洋背景、透明码头与角色图层。放钩有抛线与入水波纹，收杆后再显示已保存的鱼获；动画可跳过，动画期间阻止重复操作。暂停时冻结探索气泡与鱼线微动，轻微环境动画继续。昼夜使用柔和调色，背景随深度轻微变化。

声音默认关闭，可在主界面开启并保存。声音为程序合成的轻水声与短动作提示。设置在原 v3 存档上向后兼容，旧存档默认静音。

- [第二阶段美术与交互验收](docs/STAGE2_ART_QA.md)
- [生成素材提示词](docs/STAGE2_ART_PROMPTS.md)
- 场景动画配置：`assets/production/scene.animation.json`；本批使用独立图层补间，不是逐帧角色动作集。

## 第一阶段稳定性版本

- 检测失败、锁屏、前台和空闲分别显示暂停原因；查询进程异常退出或停止更新会自动重启，恢复时不补计。
- 主界面可选择 5 / 10 / 20 分钟空闲宽限，设置与游戏进度一起保存。
- “检测与诊断”提供最小状态、最近保存时间、复制诊断和手动重试。
- “保存退出”、窗口关闭与游戏窗口内 F8 都先保存；保存失败取消退出并提示。F8 不是全局快捷键。
- 损坏或不完整的当前存档可恢复备份，修复主存档时保留有效备份。未知版本保持保护状态。
- [Windows 实机验收清单](docs/WINDOWS_STAGE1_ACCEPTANCE.md) 随下载包提供；真实锁屏、休眠和整日使用仍待验收。

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
godot --headless --quit-after 180 -- --tests --ui-smoke
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

V2.6 主场景素材和分层动作已接入；鱼种、图鉴和鱼缸中的鱼仍是下一阶段的展示内容。主场景使用图层补间，尚未制作完整逐帧角色/猫动作集。鱼获仍使用收杆时抽取的 MVP 模型，生态范围和体长是玩法占位值。第一阶段用户已报告 Windows 实机验收通过；本轮视觉交互仍需实际试玩反馈。其他平台可打开 UI，但专注计时暂停。
