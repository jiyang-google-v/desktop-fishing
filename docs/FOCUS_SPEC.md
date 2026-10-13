# Godot 专注计时与 Windows 状态

## 冻结条件

手动放钩后，游戏后台、当前用户会话可用、未锁屏/休眠且最近 600 秒内有键鼠输入时累计有效专注。游戏前台（含图鉴/鱼缸/确认弹窗）暂停。4m/分钟，3000 秒封顶（200m）。锁屏、休眠和退出不补计。

## 查询实现

Godot 启动一个隐藏的 Windows PowerShell 进程，加载 Win32 查询代码；不在每帧/每秒重复启动 PowerShell。每 0.5 秒发布一份 JSON 状态：

- `GetLastInputInfo` + `GetTickCount` 获取键鼠空闲秒数（处理 32 位计时回绕）。
- `GetForegroundWindow` + `GetWindowThreadProcessId` 判断前台是否为本游戏进程，不查询其他应用名称或标题。
- `WTSQuerySessionInformation` 检查当前会话 active 状态；`OpenInputDesktop` / `GetUserObjectInformation` 检查是否处于正常输入桌面。失败、安全桌面、远程断开均保守暂停。
- 状态文件带随机运行 token、采样序号和 UTC 时间，不保存桌面名、窗口标识或按键。

Godot 每秒读取状态，超过 3 秒、token 不匹配、无效 JSON 或检测不支持时暂停。两个连续有效且序号递增的采样间才累计；首次、重复、恢复后的首个采样不回填。应用单调时钟与墙上时钟间隔都不得超过 5 秒，以排除休眠和系统挂起。前后台变化与会话操作重置累计资格。

后台正常采样有少量保守延迟；不是高精度工时统计工具。锁屏/安全桌面的判定属于保守策略，不能宣称已覆盖所有 Windows 会话环境。

## 生命周期

脚本写入当前 Godot 用户数据目录，状态以随机文件名隔离。子进程检查父游戏进程仍存活；正常退出由 Godot 终止并删除状态文件。查询进程失败最多重启 3 次，之后保持暂停。没有管理员权限要求，不修改系统 PowerShell 策略。
