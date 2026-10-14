# 牌阵师：上线前检查记录

检查日期：2026-10-08。结论：本轮代码整改、规则回归和模拟器验收通过；尚不具备直接提交 App Store 的完整条件。未签名归档成功不能替代签名、真机验收或 App Review。

## 已处理的问题

| 问题 | 整改结果 |
| --- | --- |
| 初次进入缺乏规则引导，容易只看到展示页面 | 增加可操作的三步教学，亲自完成一条同花顺；个人页可以重看 |
| 美术和收藏品缺少一致的产品辨识度 | 新增原创山海棋盘主视觉、统一篆印收藏品；旧插画移出资源目录，保留于 generated-images/legacy-assets |
| 每日唯一机会容易误触消耗 | 先选牌和落点，再明确确认；确认前可以更换位置 |
| 结算只有分数，无法理解得失 | 增加最终棋盘、阵线归属与牌型明细；每日题比较全部五个候选落点 |
| 中途认负与正常完局奖励语义不清 | 问道认负计负、扣段位分、不发灵玉或经验、不推进完局任务；返回按钮仍保存未完成棋局 |
| 历史成绩缺少可回顾内容 | 新战绩保留最终快照供复盘，最多 100 局；旧记录继续可见 |
| 异常存档数值及伪造分数可导致状态不一致 | 增加范围修复、卡牌唯一性及阵线分数校验，保留损坏原始数据备份；兼容旧存档 |
| 首次分享出现空白系统面板 | 用带身份的分享内容驱动 sheet，保证图片与文字一起传入；修复后首次分享已实测 |
| 复盘棋子无障碍标签重复朗读 | 合并单格无障碍元素，避免子文本重复标签 |
| 隐私与支持入口不完整 | 增加应用内隐私说明、帮助、版本信息、主动诊断分享和二次确认的数据清除 |
| 缺少隐私清单 | 增加 PrivacyInfo.xcprivacy：无跟踪、无开发者数据收集，声明自有 UserDefaults 用途 CA92.1 |
| 启动时白屏与额外资源 | 启动背景统一墨色，移除不再引用的打包插画；归档应用约 5.8 MB（不是商店下载大小） |

玩法是完整的离线游戏：问道、闲庭、每日题、自动存档、真实成绩、游玩货币解锁、任务奖励和复盘。没有真人匹配、全球排行榜、广告、内购、现金兑换或开发者服务器。商店描述应保持这些边界。

## 验证证据

- `scripts/check-engine.sh` 全部通过：10 种牌型、A2345 与非法牌型；366 天残局、1,830 个候选落点；24 局完整对弈、两种难度、600 次快照恢复；独立计分对照；任务取消恢复；奖励和每日防重；认负、历史复盘、旧存档兼容、异常数值修复与隔离数据清除。
- 最终 Debug 模拟器构建通过。最终 Release 通用 iOS **未签名 archive** 通过，路径 `/private/tmp/Handcraft-release.xcarchive`。构建仅有未链接 AppIntents 的元数据跳过提示。
- 对实际归档执行 `scripts/check-release.py`：技术项通过，发布资料有 6 项 PENDING，退出码 2。已检查归档内隐私清单、图标、编译资源、启动页和 Bundle ID。
- `Info.plist`、`PrivacyInfo.xcprivacy` 的 plist 校验通过。项目配置与本轮整改前副本逐字相同；Bundle ID、签名团队和 Debug/Release 配置未改动。
- iOS 26.5 / iPhone 17 Pro Max 专用模拟器：走通三步教学、首页、图鉴解锁及装备，确认余额与解锁数量变化。
- iOS 26.5 / iPhone SE（第 3 代）专用模拟器：检查教学首页与主页面；走通每日选牌、预选落点、确认、结算和五种候选复盘；更新安装后进度保留；问道认负奖励为 0；修复后首次系统分享面板正常显示。
- 未执行分享发送或保存照片；照片授权与实际保存仍列入真机验收。未清除用户原有模拟器或应用数据。

真实模拟器截图存于 `release/screenshots/`：`01-home.png`、`02-collection.png`、`03-review-small-screen.png`、`04-share-small-screen.png`。这些是检查记录，不是已完成排版的商店宣传截图。

## 提交前必须完成

1. **发布主体与联系方式**：填写 `Submission.json` 的 publisher_name、support_email、review_contact、territories。它是本地资料清单，不会随应用打包，也不会自动写入 App Store Connect。
2. **公开网页**：将 `Privacy-policy-draft.md` 补齐真实主体与联系渠道后发布；提供可访问的 HTTPS 隐私政策页及支持页。把实际地址写入应用 Info.plist 的 `HandcraftPrivacyURL`、`HandcraftSupportURL`，同时填写 App Store Connect。当前没有伪造示例网址，也未宣称完成这一项。Apple 要求可访问的隐私政策与完整可用的应用及 URL，见 [App Review Guidelines 2.1、5.1.1](https://developer.apple.com/app-store/review/guidelines/)。
3. **地区与资质**：先决定销售地区；若包含中国大陆，核实游戏审批号及 Apple 要求的支持文件，其他备案要求按实际主体和地区处理。离线或免费并不能据此推断豁免。参见 [Apple 的 App information / China mainland 要求](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)。
4. **账号、签名和上传**：由项目所有者配置有效开发者账号、签名证书及 provisioning，完成有签名归档与 App Store Connect/TestFlight 上传。版本号和构建号在提交时检查唯一性，本轮没有擅改发布配置。
5. **真机验收**：至少走通最低支持系统（当前仍为 iOS 14）及当前系统的完整对局；锁屏/切后台恢复、强退恢复、升级保留、照片保存的允许/拒绝、VoiceOver、放大文字、减少动态效果和长昵称布局。本轮只实测 iOS 26.5 模拟器，不能据此宣称覆盖所有支持系统或所有无障碍特性。
6. **商店资料**：审核 `AppStore-copy.md`，准备真实功能截图，按实际回答年龄分级、内容权利和隐私问卷。当前代码无数据上传，但应由发布者确认最终包与声明一致；后续添加 SDK 后必须重新评估。Apple 的 [App privacy 管理说明](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)。

## 复核命令

```sh
./scripts/check-engine.sh
python3 scripts/check-release.py
python3 scripts/check-release.py /private/tmp/Handcraft-release.xcarchive/Products/Applications/Florgugrel.app
```

预检脚本退出码：0 为当前脚本所覆盖项目通过，1 为技术缺项，2 为真实发布信息不完整。脚本不验证网页在线状态，不进行签名、上传或审核，也不能保证通过 Apple 的最低功能审核。

原创图片的生成工具、文件路径和完整提示词记录于 `Artwork.md`。原始方案里的过审措辞不作为审核结论。

## 图鉴展示调整（2026-10-08）

按用户反馈恢复原有 12 种图形，保留印章边框，名称与稀有度独立显示；详情、头像和手牌同步采用图形。已重新通过 Debug 模拟器构建，并在 iPhone SE 专用模拟器检查图鉴和详情页。上述 Release 归档为此调整前的版本，提交前应从最新源代码重新归档。

## 神兽实体插画调整（2026-10-14）

按用户反馈，将上述抽象图形进一步替换为 12 张独立的透明背景神兽插画。去掉印章外框，图鉴预览高度调整为 124 pt，详情图为 208 pt；首页与个人页头像、对局手牌共享 `FlorgugrelBeastArtwork.swift`。保留原有神兽 ID、名称、稀有度、解锁价格与装备逻辑。

全部 12 项资源已复制到项目 Assets，检查为正方形 RGBA PNG，逐图提示词与原图路径记录于 `generated-images/Florgugrel-beasts-prompts.json`。Debug 模拟器构建通过，iPhone SE（第 3 代）/ iOS 26.5 实测首页头像、牌库和九尾狐详情显示正常，图片透明且不受文字颜色染色。截图为 `05-beast-collection.png` 与 `06-beast-detail.png`。项目配置逐字对照未改变；未重新生成 Release 归档，发布时需从当前代码归档。

## 水墨风格统一验收（2026-10-14）

根据用户对整体协调性的反馈，12 张实体神兽进一步重绘为水墨淡彩版，以首页主视觉作为风格参考，保留透明背景及原有识别特征。卡面增加留白，稀有度边框改为淡细线并补充小色点。完整提示词、参考图和最终路径记录于 `generated-images/Florgugrel-beasts-ink-prompts.json`；上一版彩色图片保存在 `generated-images/beasts-color-v1/`，不参与打包。

全部 12 个最终文件均通过正方形 RGBA PNG 检查，最终 Debug 模拟器构建通过。iPhone SE（第 3 代）/ iOS 26.5 检查首屏卡面、九尾狐详情与鲲鹏详情，浅色身体和深墨羽翼均能在深色背景中辨识；卡面名称、稀有度与解锁状态保持可读。实拍截图为 `07-ink-collection.png` 与 `08-ink-detail.png`。无玩法与存档改动，未新增依赖；Bundle ID、签名和发布配置逐字对照未变。Release 归档仍需在提交前从最新代码重新生成。
