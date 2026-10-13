# Desktop Fishing · 桌面钓鱼

Windows 桌面专注钓鱼小游戏（可运行的 **MVP 工程骨架**，非美术完成版）。

## 当前可用
- Electron 桌面窗口、手动放钩/收杆、后台有效专注累计、深度（4 米/分钟，最多 200 米）
- 前台暂停、锁屏/休眠暂停、10 分钟键鼠空闲宽限（Windows 原生查询）
- 深度/昼夜鱼池、图鉴纪录、最多 6 条鱼的鱼缸、本地 JSON 存档
- 自动化逻辑测试、美术文件验证、Windows GitHub Actions 打包配置

**暂未实现**：最终 V2.6 美术 PNG、完整角色动画、场景分层、鱼获动效、鱼缸满位的完整替换交互；当前 UI 为功能验证用的 CSS 占位视觉。14 种生物数据已定义，其中水母/墨鱼为扩展种；不将未经检验的拼贴图当作正式素材。

## 本地运行（Windows）
安装 Node.js 20 或 22：
```bash
npm install
npm start
```
检查：`npm run verify`。打包：`npm run dist`。

## 上传 GitHub
GitHub 网页上传可以直接拖入**解压后的文件和文件夹**，不要上传 ZIP 作为唯一仓库文件。建议先将全部内容上传到 `main`，随后通过分支/PR 开发。上传 `package.json` 后 GitHub Actions 将自动尝试 `npm install`、测试和 Windows portable 打包。首次运行依赖下载需要网络。

## 安全与隐私
只调用 Windows 的最后输入时间和前台窗口标识，不采集键盘内容、窗口标题、其他应用数据。Linux/macOS 上的焦点采集尚未支持，专注计时默认不会启动。详见 `docs/FOCUS_SPEC.md`。
