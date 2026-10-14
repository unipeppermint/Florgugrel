# 牌阵师 Handcraft

面向 iPhone 的离线策略棋类游戏：在 5×5 棋盘上轮流落下扑克牌，争夺阵线并按牌型计分。保留墨黑、哑金、宣纸与山海主题的视觉设计。

## 当前功能

- **问道对弈**：策略电脑对手，随机先后手；本地段位、胜率和连胜随真实战绩更新。认负计负，不发放奖励或推进任务。
- **闲庭对弈**：可在设置中选择入门或策略难度，不影响段位。
- **每日一题**：使用固定算法和 UTC 日期生成相同残局，UTC 0 点（北京时间 8 点）更新。每台设备每天完成一次，确认落子后比较当题最佳得分，并支持阵线复盘与战绩海报。
- **自动存档**：每次落子保存双方手牌、牌堆、棋盘、回合与已计分阵线。离开或重启后可继续；对手任务随前后台切换暂停、恢复。
- **图鉴**：12 个山海印章，支持稀有度/已拥有筛选、用游玩所得灵玉解锁及装备。印章显示于头像和手牌，不影响规则。
- **旅程**：累计经验、等级和四项可领取任务，每项奖励限领一次。
- **个人页**：最近 100 局战绩、累计统计、昵称、难度、触感设置、隐私政策、帮助反馈、清除数据和可重看的交互教学。

这是离线版本。没有真人匹配、云同步、全球排名、内购或后台服务；原始产品方案中描述的这些能力属于后续规划。

## 运行

1. 使用 Xcode 26 或更新版本打开 `Florgugrel.xcodeproj`。
2. 选择 `Florgugrel` scheme 和 iPhone 模拟器，运行。
3. 工程最低部署版本保持 iOS 14.0。UIKit 管理应用生命周期，通过 `UIHostingController` 承载 SwiftUI。

没有第三方依赖。Bundle ID、签名与 Debug/Release 构建配置保持原样。真机运行需由项目所有者配置自己的签名。

## 规则

每人 5 张手牌，落子后补牌。5 行、5 列和 2 条对角线各计一次分；阵线填满时，拥有至少 3 枚棋子的一方得分。棋盘填满比较总分。

| 牌型 | 分值 |
| --- | ---: |
| 高牌 / 一对 / 两对 | 1 / 2 / 4 |
| 三条 / 顺子 / 同花 | 6 / 8 / 10 |
| 葫芦 / 四条 | 14 / 20 |
| 同花顺 / 皇家同花顺 | 30 / 50 |

每日题预置 20 张牌，每行每列留一格；每行双方各有两枚棋子，保证每个候选落点都能获得行分。预先已满的对角线作为基线排除，不会计入最终一步的成绩。最佳分通过穷举五个候选位置计算。

## 代码导航

- `GameModel.swift`：纯规则与可编码快照、确定性出题、阵线计分、对手策略和路由状态。
- `ProgressStore.swift`：UserDefaults JSON 存档、成绩、每日次数、经济与任务奖励防重。
- `BeastCatalog.swift`：印章静态定义。
- `RootView.swift`：导航和模态路由；每日弹窗完全关闭后才展示对局。
- `BattleView.swift`：对局交互、暂停恢复、结算及分享。
- `HomeView.swift` / `CollectionView.swift` / `DailyChallengeView.swift` / `MiscViews.swift`：主要页面。
- `Theme.swift` / `SupportViews.swift`：视觉组件、规则及系统分享桥接。

存档键为 `handcraft.progress.v1`。解析失败时保留原始数据到 `handcraft.progress.recovery`，并在个人页显示提示。进度仅在本机保存，卸载应用可能丢失。离线每日限制以设备日期为准，不提供服务端防作弊。

## 验证

在 macOS 终端运行：

```sh
./scripts/check-engine.sh
```

该脚本直接编译应用的规则和存档代码，使用隔离的临时 UserDefaults，不修改应用数据。覆盖全部牌型、366 天固定残局及 1,830 个落点、完整对局计分、600 次快照序列化恢复、非法落点、奖励防重、每日限次、印章解锁、任务领取、对手取消和恢复，以及认负、旧存档迁移、异常数据修复和复盘快照。无需新增测试 target 或更改工程配置。

模拟器构建：

```sh
xcodebuild -project Florgugrel.xcodeproj -scheme Florgugrel \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/HandcraftBuild CODE_SIGNING_ALLOWED=NO build
```

应用图标由 `scripts/GenerateIcon.swift` 以 CoreGraphics 绘制，可通过 `swift scripts/GenerateIcon.swift` 重新生成。

## 上架前检查

详见 `release/Readiness.md`。当前已提供应用内隐私说明、UserDefaults 必需原因声明、新手教学与复盘。商店文案、政策草案及发布字段位于 `release/`，不会进入应用包。

```sh
python3 scripts/check-release.py
# 或检查实际归档内的应用：
python3 scripts/check-release.py /path/to/App.xcarchive/Products/Applications/Florgugrel.app
```

退出码 1 表示技术缺项；退出码 2 表示技术检查通过，但缺少真实发布信息。**未签名归档成功不等于已具备提交条件**。须补齐公开隐私/支持 URL、开发者及审核联系方式、地区要求，并完成真实设备和 TestFlight 验收。

`outputs/` 保留原始产品方案与设计稿，其“过审策略”和年龄分级并非审核结论；当前实现以本 README、上线检查记录和源代码为准。
