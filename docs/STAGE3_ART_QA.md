# 第三阶段 A 批 · 三鱼收藏闭环（待验收）

本批仅小丑鱼、海马、灯笼鱼，不是14生物全部完成。

- G1：独立样本已目测；实际32/48/64/96px双底组合已目测，轮廓可辨；海马32px内部细节较弱，适合保持简化轮廓。小丑鱼轮廓留白低于15%设计目标，待后续修订。生成初稿的外部晕染已通过imagegen编辑去除。
- G2：三张真实RGBA，统一1254x1254，朝右，中心pivot；Alpha零值真实存在。全非零与Alpha>16轮廓见qa/stage3/asset-checks.json。极低Alpha散点延伸画布边缘，组合目测未见明显白边、黑边或伪透明。
- G3：collection.animation.json真实驱动水平缓游与海马漂浮；图层补间，无逐帧声明。
- G4：本地headless界面/满缸取消与替换通过；本地真实OpenGL渲染的鱼获、图鉴、六鱼观赏区、双底缩略图、小窗口已人工目测；鱼缸点击选鱼断言通过。截图位于qa/stage3/。待用户视觉反馈及Windows构建结果。

状态保持integration_candidate，无production_ready声明。其余11种插画显示“插画待制作”；鱼缸水体为Godot绘制的功能预览，正式分层场景尚未生产。

测试：95项模型/存档、第二阶段测试、第三阶段标签持久化/旧存档/重复收杆/非纪录鱼获、UI回归。本轮Windows系统检测与导出由CI验证。

生成使用内置imagegen；提示词记录STAGE3_ART_PROMPTS.md。源资源在assets/production/fish/，仅开发分支接入待验收候选。

实际截图：catch.png、catch-small.png、book.png、book-hidden.png、tank.png、samples.png。QA使用固定假数据，不是真实专注累计。截图中的鱼缸背景为功能预览。待安置鱼获隐藏计时卡，保证收藏操作可见；焦点按钮颜色已校正。
