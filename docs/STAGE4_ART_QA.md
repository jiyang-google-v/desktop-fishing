# V2.6 人物、猫、钓具与特效验收

基线：PR #5 / main `3bde92a`。本轮版本：0.6.0-preview。

| 类型 | 文件规格 | 动作 |
| --- | --- | --- |
| 小渔22帧 | 每帧512×512 RGBA，右向，坐姿锚点(.55,.71) | idle4、cast6、reel6、happy6 |
| 猫16帧 | 每帧512×512 RGBA，右向，脚点(.58,.82) | idle4、blink4、alert4、happy4 |
| 特效34帧 | 每帧256×256 RGBA，统一中心/水面基线 | splash8、ripple8、bubbles6、glimmer6、shadow6 |
| 钓具4件 | 每件512×512 RGBA | rod、bobber、hook、bucket |
| 码头1件 | 1774×887 RGBA | 移除烘焙猫/桶，避免双重显示 |

合计77个独立生产PNG；原始分镜图不作为运行时帧。清单见 `asset_manifest.json`；实际时长、循环、帧路径、22个握点和鱼竿角度见 `motion.animation.json`。当前为 `integration_candidate`，供用户最终目测确认。

| 门槛 | 实际证据 | 结果 |
| --- | --- | --- |
| G1 风格 | 原稿对照；猫改用柔和灰棕描边，维持粉彩纸感。奶白/青蓝底32/48/64/96px检查，无烘焙棋盘格或发光底板 | 内部通过 |
| G2 文件 | 77项RGBA、真实Alpha=0、尺寸、连续编号、留白与路径检查；72帧可见内容哈希均不同 | 通过 |
| G3 动画 | 13动作由真实JSON驱动；手部握点、尾巴/眼睛/手臂变化；循环/单次时序；鱼竿根据天空空间限制角度，长度保持固定 | 通过 |
| G4 集成 | Godot4.6.1真实OpenGL渲染：日/夜、小窗口、放钩/收杆姿态与60帧实际场景演示。重复操作、跳过、揭晓后反应、暂停恢复、入水事件只触发一次均自动断言 | 通过 |

证据：[文件检查](qa/stage4/asset-checks.json)、[帧定位](qa/stage4/frame-registration.json)、[日间](qa/stage4/day.png)、[夜间](qa/stage4/night.png)、[小窗口](qa/stage4/day-small.png)、[放钩](qa/stage4/cast.png)、[收杆](qa/stage4/reel.png)、[实际场景动画](qa/stage4/in-game.mp4)、[13动作预览](qa/stage4/motion-preview.gif)、[奶白尺寸](qa/stage4/sizes-cream.png)、[青蓝尺寸](qa/stage4/sizes-blue.png)、[握点](qa/stage4/grip-review.png)、[人物帧](qa/stage4/contact-fisher.png)、[猫帧](qa/stage4/contact-cat.png)、[特效帧](qa/stage4/contact-fx.png)。

## 回归验证

原95项模型/存档检查、第二/三阶段检查、第四阶段资源/时间边界/循环/单次/安全空结果、三种尺寸的全部姿态鱼竿边界测试通过。独立场景反应/跳过/暂停和完整UI收杆/收藏/满缸取消与替换测试通过。导出资源冒烟验证加载14种生物、72个动作帧和4件钓具。Windows导出与导出后启动由PR关联的GitHub Actions执行，以该提交实际运行结果为准。

截图/视频采用固定假数据，不累计真实专注记录。本轮不改Windows输入/锁屏/睡眠检测，不把Linux图形检查写成Windows实机使用验收。

## 生成与提取

全部插画使用内置imagegen生成，未使用CLI/API。完整提示词在 `art/concepts/motion/*.prompt.txt`。猫v2仅调整描边并移除多余提示符号；原图与选用来源保留在[sources.json](../art/concepts/motion/sources.json)。

`inspect_motion_sources.py`只分析Alpha并记录角色连通轮廓的矩形与像素区间，不改写图像。Godot的 `extract_motion_frames.gd`提取完整轮廓、排除相邻分镜残片，统一透明画布与脚点。特效按等分格导出并校准水面基线。未复制同一静态图或只改文件名凑帧数。

完整收藏卡片揭晓演出与UI收尾仍为后续任务；本轮happy只补齐人物/猫的短暂反应。
