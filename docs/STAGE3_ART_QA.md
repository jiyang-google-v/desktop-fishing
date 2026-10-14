# 第三阶段 · 14生物与三层鱼缸素材

用户已认可A批小丑鱼/海马/灯笼鱼风格。本轮新增11种生物和3张鱼缸图层，全部独立文件，未把概念拼图用作运行时资产。

| 门槛 | 结果与证据 |
|---|---|
| G1 风格 | 内部目测通过。samples.png / samples-2.png 及各自-blue版本覆盖全部14种、32/48/64/96px双底。水母/海马32px以轮廓识别，内部细节克制；金枪鱼用长黄鳍与大眼短鳍区分。新增批次待用户反馈。 |
| G2 文件 | 14生物统一1254方形RGBA；鱼缸3层统一2172x724 RGBA。生物/水面/前景Alpha含真实0值，无伪透明、可见裁切或明显白黑边。极低Alpha散点可能延伸画布边缘，组合目测无异常。完整数据见asset-checks.json。背景源RGB仅无损补Alpha=255，RGB像素逐字节相同。 |
| G3 动画 | collection.animation.json实际驱动swim/drift/float/pulse；水母漂浮、墨鱼变速推进。图层补间，不声明逐帧动作。 |
| G4 集成 | 真实Godot OpenGL目测鱼获、图鉴、六鱼观赏区、两底缩略图；点击选鱼断言通过。A批小窗口操作验收保留，本轮界面尺寸未改。Windows新版导出检查待CI。 |

清单：collection_manifest.json、aquarium_manifest.json。首批风格认可单独记录user_style_approved，新增资源保持integration_candidate，避免将内部目测等同用户认可。

测试：模型/存档95项，第三阶段14资源/特殊运动配置/旧存档/标签持久化、UI重复操作/满缸取消及替换。真实Windows系统检测与导出由CI验证。

QA截图使用固定假数据，不是真实专注累计。tank.png展示混合生物，素材图层在assets/production/aquarium/，基础鱼图在assets/production/fish/。完整人物22帧、猫16帧、特效34帧不属于本轮完成项。
