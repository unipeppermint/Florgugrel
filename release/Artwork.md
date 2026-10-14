# 原创主视觉

生成方式：内置 imagegen 工具，2026-10-08。未使用第三方参考图。

项目资源：`Florgugrel/Assets.xcassets/BoardHero.imageset/BoardHero.png`。

提示词：

Use case: stylized-concept. Asset type: premium iOS Chinese strategy board game hero background, landscape 3:2. Create an original refined Chinese shan-hai fantasy illustration: a small ivory white deer with four graceful antlers on the upper right overlooks a five-by-five dark stone square game board etched with very thin muted gold lines, a few small ivory tiles resting in its cells. Mountains and sea mist dissolve into charcoal ink. Very sophisticated brushwork with subtle antique gold, ink black #0F0E0E, ivory #EFE7D8, deep moss teal. Oblique overhead view of the board at center-right, deer in upper right, dim unobtrusive space on left and bottom for app's separately rendered typography. Calm contemplative strategy, not casino, no chips. Editorial gouache and ink engraving with subtle paper texture, polished restrained art direction, striking clear silhouette at small mobile sizes, no text, no lettering, no logo, no border, no watermarks. Do not render an app mockup or UI.

## 神兽实体插画（2026-10-14）

使用内置 imagegen 工具分别生成 12 张透明背景的神兽插画：夫诸、狰、当康、乘黄、精卫、白泽、毕方、麒麟、文鳐鱼、九尾狐、鲲鹏和烛龙。采用一致的柔和国风配色、简化动物轮廓和完整身体构图，替换原来的抽象 SF Symbols 与文字印章，不叠加外框。

最终文件：`Florgugrel/Assets.xcassets/FlorgugrelBeast-<id>.imageset/Florgugrel-<id>.png`。图鉴、详情、装备头像和手牌通过 `FlorgugrelBeastArtwork.swift` 使用同一素材；图片保留原始颜色与透明度，不受卡牌红黑花色染色。

完整的逐图提示词、名称和生成原图路径见 `generated-images/Florgugrel-beasts-prompts.json`。所有应用引用素材均复制至项目 Assets，不依赖生成工具的缓存目录。未使用第三方参考图，也未新增依赖。

旧版两张主视觉插画仍保留为源材料，新界面不再引用。

## 水墨淡彩风格统一（2026-10-14）

基于用户反馈，以首页 `BoardHero.png` 为风格参考，使用内置 imagegen 逐张重绘神兽素材。保留神兽实体轮廓、识别特征和透明背景，改用灰墨、米白与少量低饱和淡彩；减少毛发、鳞片细节和金色装饰，使其更接近首页山海水墨与宣纸卡面。

新一轮完整提示词及生成文件路径记录于 `generated-images/Florgugrel-beasts-ink-prompts.json`。应用继续引用相同的 `FlorgugrelBeast-<id>` 资源名称。前一版彩色插画与提示词已完整保存在 `generated-images/beasts-color-v1/`，不会随应用打包。

卡面配套增加插画留白，采用淡细边框；稀有度保留文字与小色点，解锁和装备状态保持可辨。
