# 悬浮美术生产 QA

本轮基于用户确认的右下角海湾及极简钓具概念图，交付 6 张新增独立 PNG、65 个既有文件的复用映射、动画与锚点配置，以及 Godot 组合预览。

## 已完成检查

- 6 个文件均为真实 RGBA，存在 Alpha=0、非零主体与自然半透明边缘；非棋盘格背景。逐文件大小、透明像素比例、可见边界、SHA-256：docs/qa/floating/asset-checks.json。
- 原生生成文件直接复制，SHA-256 一致；65 个复用文件逐一校验，未重画人物/猫/钓具。
- 海面/礁石仅右下两侧允许贴画布边，其余层留透明边距；灯塔无实际外围光晕。
- 在奶白/深灰蓝两种背景上检查新图层；见 layers-light-dark.png。
- 600×400 场景、240×140 极简及真正透明背景由 Godot 4.6.1 渲染并人工查看。
- 场景检查 idle/cast/reel/happy 四种姿态与夜间调色；手柄/竿尖/浮标使用同一坐标链，鱼线竖直。
- 极简只有鱼竿、浮标与小水纹；没有人物、手、猫、码头或 UI 底板。
- 本轮发现的临时纹理生命周期问题已修复：码头使用预加载的持久纹理引用，避免渲染白块。

## 验证命令

```sh
python scripts/tools/validate_floating_assets.py
godot --headless --script res://tests/floating_art_tests.gd -- --tests
godot --audio-driver Dummy --rendering-method gl_compatibility --script res://tests/floating_art_capture.gd -- --tests --profile=scene --backdrop=light
```

截图参数：profile 为 scene/mini；backdrop 为 light/dark/transparent；pose 为 idle/cast/reel/happy；--night 打开夜间调色。

## 状态与限制

新增贴图通过上述美术/技术检查后标记 production_ready。组合模块供下一阶段悬浮窗口接入使用；主游戏界面与专注计时行为不变。Windows CI 检查导入、组合测试、渲染截图和导出资源；原生透明窗口、拖动、置顶、穿透、DPI 与多屏仍待接入后实机验收，不标记为已实现。

新图片使用内置 imagegen 生成；可复核的最终提示词及来源见 art/concepts/floating/generation.json。原始生成中未选用的岛屿变体不进入生产目录。
