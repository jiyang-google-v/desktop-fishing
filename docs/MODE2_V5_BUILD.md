# 模式二：第五版接入记录

用户2026-10-15确认动画v5并授权build。基线：62a530a（feat/custom-window-titlebar），独立分支feat/mode2-v5。另一工作区尚未提交的窗口修改未带入。

## 阶段0：项目检查（完成）
- Godot 4.6.1 Standard/GDScript；入口main.tscn → main.gd → window_layouts.gd。
- 模式二已有420×280原生透明窗口、番茄钟、悬停工具条、透明度、图鉴/鱼缸和独立鱼获窗口。
- 沿用POMODORO_SPEC.md，不使用旧深度/输入专注规则。
- GameService先保存鱼获，Ocean的SceneMotion只播放动画；新表现层绝不生成或结算鱼。

## 阶段1：资源（完成，integration_candidate）
20个独立RGBA PNG、asset_manifest.json（画布/锚点/哈希）、scene.animation.json（布局/层次/运动参数）。均来自用户确认v5素材，未生成新画风。

## 阶段2：环境（完成）
mode2_scene.gd：随机间隔从左右生成，单向直线横移、轻微上下起伏、离场回收；最多12条，不在画面中转身。水域裁切；远鱼→中景水草→近鱼→前景水草/珊瑚；根部固定的叶梢形变和水面波光。

## 阶段3：钓鱼动作（完成）
以手部为竿的旋转支点，放竿才抛出浮漂，起竿直接缩短鱼线；真实鱼获沿弧线出水，水花和水滴独立。人物收竿/欢呼及猫咪蹲身/跳跃与动作进度同步。透明浮漂水纹在水面层。

## 阶段4：卡片与机制（完成）
沿用原生鱼获窗口和收进鱼缸/满缸替换/放生/稍后安置。卡背等待→翻面→固定展示；翻面后无位移、缩放回弹或旋转。卡片显示实际species_id、体长、首次发现和纪录；介绍表与鱼种稳定ID绑定。重复刷新和模式切换不增加reveal_count；点击卡背可跳过视觉等待。

## 阶段5：验证与交付
- 已通过Godot导入与15组逻辑/回归验证（含mode2_v5_tests）。
- 实际420×280透明场景、起竿和280×410原生卡片已在Godot/OpenGL软件渲染中截图检查；卡片按钮范围检测通过。
- export_presets加入新目录JSON；Windows CI加入专项逻辑测试和实际渲染捕获。
- Windows原生行为和最终exe由Actions构建/验证；本地Linux图像不替代Windows人工多屏/DPI/拖动验收。

## 复核
```
godot --headless --editor --import --quit
godot --headless --script res://tests/mode2_v5_tests.gd -- --tests
godot --headless --script res://tests/floating_interaction_tests.gd -- --tests
godot --audio-driver Dummy --script res://tests/mode2_v5_capture.gd -- --tests
```
图像：docs/qa/mode2-v5/idle.png、reel.png、card.png。透明空白区、鱼群穿越和卡片静止还应在Windows实机确认。

## 当前交付状态
本地接入与软件渲染已完成。用户已明确授权将本批模式2第五版代码、素材和文档上传至公开仓库jiyang-google-v/desktop-fishing、创建PR并启动Windows构建。Git CLI未配置凭据，改用GitHub Blob/Tree/Commit批量提交。本地Linux验证不替代Windows原生验收；最终构建状态以本批PR的Actions结果为准。
