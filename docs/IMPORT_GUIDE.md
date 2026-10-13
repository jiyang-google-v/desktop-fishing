# Godot 工程导入

使用 Godot 4.6.1 Standard，Import 仓库根目录 `project.godot`。按 F5 运行；Windows 专注检测请使用独立运行窗口。

代码只维护 Godot 实现。当前实现及构建不再依赖 Electron、npm、HTML 或 CSS。鱼种路径改为 `data/fish-data.json`，已有 14 个 ID 不变。

原 V2.6 参考文件内容实际为 JPEG，已将扩展名从 `.png` 更正为 `.jpg`，图片字节内容保持一致。

旧 v1/v2 存档可手动迁移：先退出两版程序并备份目录，之后复制旧存档到 `%APPDATA%/DesktopFishingGodot/save.json`。不要覆盖已有 Godot 收藏；未知版本保守暂停。项目不自动扫描旧版本目录。
