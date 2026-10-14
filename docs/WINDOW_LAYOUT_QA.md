# 三态原生窗口实现与验收

2026-10-14：三态已接入主场景，Windows build 由 PR 的 GitHub Actions 生成。

- 完整窗口：保留主界面、图鉴与鱼缸，底部按钮切换悬浮状态。
- 场景悬浮：420×280，原生无边框透明窗口，右下角初始定位；保留人物、猫、码头、岛屿云层、水面及浅层海水。悬停显示切换按钮。
- 极简悬浮：160×100，仅鱼竿、鱼线、浮标及极小水面，无常驻工具条。
- 左键拖动，右键菜单切换布局、手动放钩/收杆、返回完整窗口安置鱼获、置顶及保存退出；Escape 返回完整窗口，原有 F8 保存退出保留。
- 每种布局位置、完整窗口尺寸及置顶设置保存到独立 window-layouts.cfg，不改变钓鱼存档。
- 布局切换保留专注、鱼钩与待安置鱼获；前台仍暂停，后台专注判定继续使用现有 Windows worker。

本地 Godot 4.6.1 验证：95 项模型存储检查、stage2/3/4、收藏反馈、浮窗素材、默认与最小窗口 UI smoke 全部通过。新增 window_layout_tests 在 headless 和真实 X11 窗口运行通过。主场景三态截图由 window_layout_capture 生成，人工检查完整布局、透明背景、场景与极简主体显示。

截图：docs/qa/layouts/full.png、scene.png、mini.png。

Windows 实机待验：DWM 透明合成、多显示器/高 DPI 拖动与屏幕边界、置顶开关、锁屏/休眠暂停、退出重启位置恢复。X11/headless 检查不替代 Windows 验收。当前拖动命中区为整个矩形窗口（透明部分未做鼠标穿透）。

## Windows 黑底修复

用户实机反馈显示黑色背景；之前的 viewport Alpha 截图不能证明桌面合成成功。现改为启动时同时允许并启用原生窗口透明、viewport 透明与透明清屏；所有布局保持 alpha 合成表面，完整模式用独立不透明 ColorRect 作背景，避免重复重建合成状态。Windows Compatibility 使用 ANGLE / Direct3D 11，官方 Godot 4.6.1 模板内置 ANGLE；导出测试检查实际驱动为 opengl3_angle，不允许静默回退到原生 OpenGL。使用动态 ANGLE 模板时由导出器包含 DLL。

导出程序新增 --tests --transparency-smoke：创建独立原生双色测试底窗，在完整/悬浮/极简之间往返，直接读取屏幕合成像素，要求悬浮空白角落透出底窗两种颜色且完整模式保持不透明。同时检查 viewport Alpha。此测试仅在 CI/显式测试参数下执行，不在正常游戏中读取屏幕。Windows CI 结果以对应运行记录为准，不将 Linux Alpha 测试当作 DWM 验收。
