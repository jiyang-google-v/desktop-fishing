# GitHub 导入
1. 下载 `desktop-fishing-github-starter.zip` 并解压。
2. 打开 https://github.com/jiyang-google-v/desktop-fishing ，选择 Add file → Upload files。
3. 把解压后 `desktop-fishing-starter` 目录**里面的全部文件和文件夹**拖入上传页面（不要只上传 ZIP）。
4. 提交到 `main` 后，进入 Actions 查看 `Windows Build`；若 Actions 尚未启用，按 GitHub 提示启用。
5. Actions 成功后在运行详情的 Artifacts 下载 `desktop-fishing-windows`。
6. 当前工程使用占位图，非正式 V2.6 生产美术；Windows 实机测试焦点、锁屏、睡眠、空闲时间是后续必须项。

提示：GitHub 网页上传对包含隐藏目录（如 `.github`）的拖拽行为可能因浏览器而异，提交后请确认 `.github/workflows/windows-build.yml` 确实存在；缺失时可在 GitHub 网页单独创建此文件。
