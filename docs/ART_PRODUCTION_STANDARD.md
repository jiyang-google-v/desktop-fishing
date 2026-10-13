# V2.6 正式美术生产验收标准

视觉基准：`assets/references/PRIMARY_REFERENCE_V2.6.png`。柔和粉彩、低到中饱和、轻微水彩/蜡笔纸感、简洁可辨的生物轮廓、自适应描边、奶白 UI。避免高饱和蓝、塑料高光、厚描边、复杂贴纸感。

## 强制验收
- 每物体/每动画帧独立 PNG，必须真实 RGBA Alpha；背景透明像素确实为 alpha=0，不可把棋盘格画进 RGB。
- 同一动画画布尺寸、pivot、朝向一致；文件连续编号；动画 JSON 可解析且引用文件存在。
- 32/48/64/96 px 在白色与海蓝底均需目测；无白边/黑边/伪透明。
- `assets/production/asset_manifest.json` 每项路径、尺寸、pivot、style_version、状态可追溯。
- 通过视觉 G1、文件 G2、动画 G3、游戏集成 G4 四关，才可 `production_ready`。
- 仅概念图不得出现在 `assets/production/`，概念图/图集放 `art/concepts/`。

## 8 批次
01 14 生物；02 小渔 22 帧；03 猫 16 帧；04 钓具；05 分层场景；06 UI；07 特效 34 帧；08 集成 QA。
