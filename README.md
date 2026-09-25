# Gowith

**带上要带的，记住带回的。**

Gowith 是一款纯本地、零依赖的 iOS 出行物品管理 App。它记录的不是待办事项，而是一件真实物品的空间旅程：从某个家出发、跟着你移动、在另一个地点被放下、最后被确认带回。

自 v1.0.1 起，App 提供**基础 / 进阶双模式**（右上角胶囊开关随时切换）：基础模式以黑白极简视觉聚焦「添加物品 → 装包出行 → 回家清点」核心闭环，进阶模式整体转深色并解锁地图与历史统计。

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue) ![Framework](https://img.shields.io/badge/SwiftUI-iOS%2017-orange) ![Dependencies](https://img.shields.io/badge/dependencies-0-brightgreen) ![Version](https://img.shields.io/badge/version-1.0.1-blueviolet)

## 它解决什么问题

- 出门忘带关键物品（钥匙、充电器、相机卡）
- 物品放在外地（健身房、办公室）之后忘记带回
- 带出去的东西回家后，不确定是否都带回来了

## 核心概念

Gowith 的世界由一条对象关系链构成：

```
地点 → 背包 → 物品 → 出行会话 → 新地点 → 回家清点
```

- **地点（Place）**：地图上标记的物理位置（家、公司、健身房……），默认带约 50 米的地理围栏
- **背包（Backpack）**：装物品的容器，出行以背包为单位发起
- **物品（Item）**：归属于某个地点，可分类、可拍照或选图作为图标
- **出行会话（Outing Session）**：一次出门的完整记录，物品以快照形式进入会话，历史不受后续编辑影响

## 功能特性

### 🎛 基础模式（默认 · 浅色 4 Tab）

聚焦核心闭环，每个页面由黑色资产卡片给出当前数字与下一步引导：

- **物品库**：按分类分组的货架清单；109 枚命名图标库（13 类、可搜索）+ 相机/相册自定义图标；点「+」装入背包，触发飞球动画与 Tab 角标联动
- **拿东西**：当前背包清单 +「可能还想带」建议卡，悬浮按钮一键「开始出行（N 件）」
- **检查**：回家清点，整行打勾切换「已带回 / 待确认」；未确认项保留 3 天宽限期，到期自动标记遗失并在首屏提示
- **我的**：偏好设置（外观/提醒/触感）、重看教学动画、历史记录入口与数据管理

### 🌙 进阶模式（深色 5 Tab）

- 解锁**地图与地点**（围栏管理、地点库存）与**历史与统计**（清点完成率、连续零遗失天数）
- 全局切换为深色主题；历史页从「我的」进入，不占 Tab 位

### 🚶 出行会话（产品的灵魂）

```mermaid
stateDiagram-v2
    [*] --> 出门中: 在出发地 50m 内选择背包与物品，发起出行
    出门中 --> 已到达: 进入其他已保存地点（地理围栏或手动确认）
    出门中 --> 回家清点: 回到出发地（地理围栏或手动确认）
    已到达 --> 已完成: 选择放入目的地的物品，未选的继续随身携带
    回家清点 --> 已完成: 逐项标记「已带回 / 待确认」
    已完成 --> [*]
```

- 发起出行要求你真实位于出发地围栏内，清单一旦开始即固化快照
- 出门期间在后台监测离开出发地与到达其他地点，进入围栏时发送本地通知提醒确认
- 到达其他地点时，可选择哪些物品存放在那里（物品与背包会归属到新地点）
- 回家清点逐项确认「已带回 / 待确认」；未确认物品保留 **3 天**宽限期，到期自动标记为遗失，并在首屏提示
- 「我的」页提供出行统计、历史记录与每次会话的完整详情

## 技术实现

| 模块 | 方案 |
| --- | --- |
| UI | SwiftUI（iOS 17+，iPhone / iPad，竖屏） |
| 地图 | MapKit（SwiftUI `Map` / `Marker` / `MapCircle`） |
| 定位与围栏 | CoreLocation（`CLCircularRegion` 区域监测，出发地 exit + 目的地 entry） |
| 通知 | UserNotifications（到达提醒本地通知） |
| 媒体 | PhotosUI 相册选图 + 相机拍摄 |
| 持久化 | 本地 JSON（手写 Codable）+ 文件系统图片存储 + NSCache 内存缓存 |
| 架构 | 单一数据仓 `GowithStore`（ObservableObject）+ EnvironmentObject 注入 |

其他实现细节：

- **零第三方依赖**：不使用任何外部库、无后端、无网络请求
- **伪 3D 图标**：多层 SF Symbol 叠加渐变与高光，纯 SwiftUI 绘制（`Gowith3DIcon`）
- **自建设计系统**：黑白令牌组（浅 / 深两套自动适配）、间距、动效曲线、触感反馈集中在 `DesignSystem.swift`，基础 / 进阶模式经 `preferredColorScheme` 整体翻转，约 20 个通用组件复用全 App
- **可访问性**：状态永远「图标 + 文字」双通道表达，全量中文 VoiceOver 标签，触控目标 ≥ 44pt，支持动态字体与 Reduce Motion 降级

## 项目结构

```
Gowith/
├── Gowith.xcodeproj
└── Gowith/
    ├── GowithApp.swift        # App 入口与全局外观配置
    ├── RootView.swift         # 启动流程（教学动画/引导）、双模式主导航
    ├── Models.swift           # 数据模型、GowithStore 持久化、本地图片存储
    ├── LocationService.swift  # 定位授权、地理围栏监测、到达通知
    ├── GoView.swift           # 出行会话全流程界面（出门/到达/清点）
    ├── ItemViews.swift        # 物品库货架、分类与物品编辑器
    ├── PlaceViews.swift       # 地点地图与地点编辑器
    ├── ProfileViews.swift     # 我的、历史记录与会话详情
    ├── GowithIconLibrary.swift # 物品图标库：109 枚命名图标 / 13 分类（可搜索）
    ├── DesignSystem.swift     # 设计系统：黑白令牌、Tab 栏、悬浮按钮、资产卡与通用组件
    └── Gowith3DIcon.swift     # 纯 SwiftUI 伪 3D 图标
```

## 快速开始

**环境要求**：Xcode 15+（含 iOS 17 SDK），运行目标为 iOS 17.0 及以上。

```bash
git clone https://github.com/wayne0612/Gowith.git
cd Gowith
open Gowith/Gowith.xcodeproj
```

在 Xcode 中选择目标设备后 `Cmd + R` 运行即可，无需安装任何依赖。

> 💡 首次启动会播放三帧教学动画，随后进入引导流程：命名你的第一个「家」、创建第一个背包、添加第一件物品。
> 地理围栏的后台到达提醒需要授予「始终定位」权限；模拟器可通过 **Features → Location** 模拟移动来体验围栏触发。

### 真机安装（免开发者账号）

仓库 [Releases](https://github.com/wayne0612/Gowith/releases) 提供**未签名 ipa**（`dist/` 目录亦有存档），可用免费 Apple ID 经 Sideloadly / AltStore 自行签名侧载（7 天有效期，可续签），步骤见 [docs/iPhone安装教程.md](docs/iPhone安装教程.md)。

## 隐私与数据

- **全部数据只存在本机**：结构化数据保存在 `Application Support/gowith-data.json`，图片保存在 `Application Support/GowithImages/`
- 无网络请求、无账号体系、无分析 SDK，删除 App 即删除全部数据
- 出行会话记录的是物品快照（名称/图标），历史记录不随后续编辑变化

## 系统权限说明

| 权限 | 何时请求 | 用途 |
| --- | --- | --- |
| 定位（使用期间） | 引导设置 / 设置地点 | 获取当前位置、判断是否在地点围栏内 |
| 定位（始终） | 发起出行时 | 在后台监测离开出发地与到达目的地，触发提醒 |
| 通知 | 发起出行时 | 到达地点的本地提醒（可在设置中关闭） |
| 相机 / 相册 | 编辑物品或背包图标时 | 拍摄或选择图片 |

## 项目文档

- [CHANGELOG](CHANGELOG.md) —— 各版本改动日志
- [Gowith 产品原型报告](Gowith-产品原型报告.md) —— 完整 PRD：信息架构、状态机、页面与数据模型
- [Gowith 设计系统规范](Gowith-Design-System.md) —— 唯一生效的设计规范 v2.0
- [UI System](UI-system.md) / [UIUX Motion Design](uiuxmotion-design.md) —— 视觉与动效设计过程稿

## 版本

- **v1.0.1**（当前）—— 基础 / 进阶双模式 + 黑白极简视觉 + 物品图标库（109 枚 / 13 类）+ 首启教学动画，详见 [CHANGELOG](CHANGELOG.md)
- **v1.0.0** —— 纯本地 MVP：地点 / 背包 / 物品库 / 出行会话状态机 / 地理围栏提醒 / 历史记录

后续方向（详见产品原型报告）：真机围栏回归、GowithStore 单元测试、Widget 快捷入口、多背包出行、云端同步。
