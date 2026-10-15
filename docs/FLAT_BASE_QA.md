# 模式二平底轮廓替换

2026-10-14 用户确认在原图基础上将底部变平、不要向下凸，并授权生成正式资产、替换与build。本轮基于番茄钟A卡片PR #12。

- 替换 assets/production/scene/reference-floating-environment.png，保持1536×1024、真实RGBA、原路径和全画布绘制方式。人物、猫、码头、鱼竿、鱼线、浮标、番茄钟继续独立绘制；完整模式和极简模式素材保留。
- 内置imagegen以原环境为编辑目标、已批准平底预览为轮廓参考、V2.7原稿为辅助参考。仅修正下方连续礁石/水草边界，避免中央向下凸的鱼缸弧度；底边保留微小自然起伏。完整提示词见 FLAT_BASE_ART_PROMPT.txt。
- reference_scene_manifest.json记录新PNG尺寸、Alpha和SHA256。Alpha范围0–254，四角全透明；无烘焙桌面、UI或棋盘格。
- 新增轮廓回归：取中央80%宽度的16个窄带，各自计算不透明下缘中位数，最大高度差需≤18源像素。旧图22，替换后9（约2.5显示像素）；测试在替换前失败、替换后通过。数据见 docs/qa/flat-base/asset-checks.json。
- Godot4.6.1实际OpenGL渲染截图before/after已并排检查：底边收平，树、云、灯塔和动态层对齐；模式二昼夜/暂停/完成截图同步刷新。
- 本地场景/透明度、番茄钟卡片、三态切换、悬停入口及番茄钟UI回归均通过，详细输出见 docs/qa/flat-base/tests.json。
- Windows导出、启动、原生透明合成与实际按钮鼠标点击继续由本PR CI执行。高DPI/多显示器与真实锁屏睡眠仍属于人工实机验收。
