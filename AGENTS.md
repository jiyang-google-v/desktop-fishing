# Desktop Fishing 项目开发约束

1. **视觉最高权威**：`assets/references/PRIMARY_REFERENCE_V2.6.jpg`，其次 `docs/ART_STYLE_GUIDE_V2.6.md`。V2.6 低饱和柔和粉彩、轻水彩、简洁 Icon、柔和自适应描边。禁止回退高饱和塑料手游风。
2. **冻结玩法**：仅游戏在后台且电脑醒着未锁屏、最近 10 分钟有键鼠输入时积累有效专注；4m/分钟，200m 封顶；手动放钩收杆；深度/本地昼夜影响鱼池；图鉴和 6 鱼鱼缸。
3. **禁止擅自加功能**：商店、货币、等级、背包、天气、老板来了、桌面悬浮窗均不属于首版。
4. **鱼种稳定 ID**：保持 `data/fish-data.json` 中前 12 种 ID 不变；水母墨鱼仅扩展。
5. **美术严格门槛**：独立真实 RGBA PNG（不能烘焙棋盘格）、统一尺寸/锚点/朝向、实际游戏尺寸检查、真实 JSON 动画配置和 manifest；每批提供可复核 QA。未过关不能标 `production_ready`。
6. 先写测试、运行 README 中的 Godot headless 验证命令，Windows 打包交给 GitHub Actions；Windows 前台/锁屏/睡眠/输入检测必须实机验收。
7. 保护隐私：绝不记录键盘按键内容、窗口标题或应用使用历史。
8. 变更优先创建分支/PR，不擅自修改玩法与美术标准。

9. 引擎固定 Godot 4.6.1 Standard + GDScript；不再引入 Electron/Node 网页 UI。Windows 查询进程只提供最小状态，失败时暂停。
