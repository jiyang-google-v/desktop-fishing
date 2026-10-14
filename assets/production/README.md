# V2.6 生产资产

asset_manifest.json登记主场景与本轮77项独立RGBA PNG；生物及鱼缸另见collection_manifest.json和aquarium_manifest.json。背景按用途不透明，所有叠加层均含真实Alpha=0。

主场景读取motion.animation.json的人物22帧、猫16帧、特效34帧及4件钓具。人物/猫/钓具画布512方形、特效256方形，每帧独立PNG。scene.animation.json控制放钩/收杆输入锁时长、入水事件和环境时序。鱼线、云层、精确深度刻度由Godot绘制。

scene/fisher.png与scene/pier-cat.png保留为历史来源；当前使用拆分码头、独立猫与水桶，避免重复。原始分镜与完整提示词保留在art/concepts/motion/，不打进游戏包。

本轮保持integration_candidate，内部G1–G4证据见docs/STAGE4_ART_QA.md，供最终视觉反馈。production_ready不等于所有八批任务或首版全部完成。

悬浮形态增量：floating/ 下 6 张新 RGBA PNG；floating_manifest.json 登记源文件校验值、锚点、透明边界及 65 个既有文件的复用关系；floating.animation.json 定义场景/极简组合和环境时序。新增组件 scripts/ui/floating_art_view.gd 供组合验收及后续窗口接入，当前不替换主界面。美术范围、技术验收与限制见 docs/FLOATING_ART_SPEC.md、docs/FLOATING_ART_QA.md。
