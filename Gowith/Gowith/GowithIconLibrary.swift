import SwiftUI

// MARK: - 图标库目录（两套实心图标：出行装备 / 出行场景，共 109 枚）
//
// 用法：
// 1. 生成/下载图标素材时，按 `id` 命名文件（如 bag.backpack.hiking.png）。
// 2. 把素材拖进 Assets.xcassets，App 内即自动用素材替换 SF Symbol 占位。
// 3. 物品/背包编辑器的图标库支持按中文名、关键词、分类名搜索。

struct GowithIconEntry: Identifiable, Hashable {
    /// 素材命名（同时也是 Assets 里的资源名）
    let id: String
    /// 中文展示名
    let name: String
    /// 搜索关键词（空格分隔）
    let keywords: String
    let category: GowithIconCategory
    /// 未放素材时的 SF Symbol 占位
    let symbol: String
}

enum GowithIconCategory: String, CaseIterable, Identifiable {
    case bags = "包袋箱包"
    case carry = "随身数码"
    case food = "饮食容器"
    case clothing = "衣物雨具"
    case toiletries = "洗漱护理"
    case documents = "证件票据"
    case travel = "出行提醒"
    case transit = "交通住宿"
    case weather = "时间天气"
    case facility = "站点设施"
    case security = "安全功能"
    case interface = "界面通信"
    case outdoor = "户外智能"

    var id: String { rawValue }
}

enum GowithIconLibrary {
    static let all: [GowithIconEntry] = [
        // 包袋箱包（15）
        E("bag.backpack.classic", "双肩背包", "背包 书包 通勤 上学", .bags, "backpack.fill"),
        E("bag.backpack.hiking", "登山背包", "背包 户外 登山 徒步 旅行", .bags, "backpack.fill"),
        E("bag.backpack.mini", "迷你背包", "背包 轻便 小包 潮流", .bags, "backpack.fill"),
        E("bag.luggage.stripe", "竖纹行李箱", "行李箱 拉杆箱 旅行 托运", .bags, "suitcase.rolling.fill"),
        E("bag.luggage.large", "大行李箱", "行李箱 拉杆箱 大容量 长途", .bags, "suitcase.rolling.fill"),
        E("bag.luggage.compact", "轻便行李箱", "行李箱 拉杆箱 短途 登机", .bags, "suitcase.fill"),
        E("bag.duffle", "旅行手提袋", "旅行袋 圆筒包 健身包 短途", .bags, "bag.fill"),
        E("bag.handbag", "女士手提包", "手提包 包 包袋 通勤", .bags, "handbag.fill"),
        E("bag.satchel", "翻盖斜挎包", "斜挎包 单肩包 日常 包袋", .bags, "handbag.fill"),
        E("bag.chest", "胸包腰包", "胸包 腰包 挎包 运动 骑行", .bags, "bag.fill"),
        E("bag.pouch", "圆筒收纳包", "收纳包 化妆包 洗漱包 相机包", .bags, "bag.fill"),
        E("bag.drawstring", "束口袋", "抽绳袋 鞋袋 收纳 束口", .bags, "bag.fill"),
        E("bag.shopping", "购物袋", "购物 手提袋 采购", .bags, "cart.fill"),
        E("bag.briefcase", "公文包", "公文 商务 电脑包 上班", .bags, "briefcase.fill"),
        E("bag.storageBox", "收纳箱", "收纳 整理 储物 箱子", .bags, "archivebox.fill"),

        // 随身数码（9）
        E("key.single", "钥匙", "钥匙 开门 家门 门禁", .carry, "key.fill"),
        E("key.bunch", "钥匙串", "钥匙 挂件 一串 钥匙扣", .carry, "key.fill"),
        E("key.carKey", "遥控钥匙", "车钥匙 汽车 遥控 解锁", .carry, "key.radiowaves.forward.fill"),
        E("key.fob", "挂牌钥匙", "钥匙圈 挂牌 门禁卡 钥匙扣", .carry, "key.horizontal.fill"),
        E("gear.powerbank", "充电宝", "充电 移动电源 电池 补电", .carry, "battery.100.bolt"),
        E("gear.cable", "数据线", "充电线 数据 typec usb", .carry, "cable.connector"),
        E("wallet.long", "钱包卡包", "钱包 卡包 皮夹 卡片 票据", .carry, "wallet.pass.fill"),
        E("tech.headphones", "头戴式耳机", "耳机 音乐 头戴 降噪", .carry, "headphones"),
        E("tech.earbuds", "无线耳机", "耳机 蓝牙 airpods 无线", .carry, "airpodspro"),

        // 饮食容器（4）
        E("bottle.sport", "运动水壶", "水壶 水瓶 喝水 运动", .food, "waterbottle"),
        E("bottle.thermos", "保温杯", "保温 水杯 咖啡 热水", .food, "cup.and.saucer.fill"),
        E("bottle.mug", "马克杯", "杯子 咖啡杯 水杯", .food, "cup.and.saucer.fill"),
        E("bottle.spray", "喷雾罐", "喷雾 防晒 补水 花露水", .food, "drop.fill"),

        // 衣物雨具（8）
        E("cloth.tshirt", "T恤", "衣服 上衣 打底 短袖", .clothing, "tshirt.fill"),
        E("cloth.shirt", "衬衫", "衬衣 正装 上衣 商务", .clothing, "jacket.fill"),
        E("cloth.pants", "长裤", "裤子 休闲裤 牛仔裤 换洗", .clothing, "tshirt.fill"),
        E("cloth.shorts", "短裤", "裤子 运动短裤 夏季", .clothing, "tshirt.fill"),
        E("cloth.socks", "袜子", "袜 船袜 换洗", .clothing, "shoe.2.fill"),
        E("cloth.sneakers", "运动鞋", "鞋 跑鞋 球鞋 慢跑", .clothing, "shoe.2.fill"),
        E("cloth.slippers", "人字拖", "拖鞋 凉鞋 海滩", .clothing, "shoe.2.fill"),
        E("cloth.umbrella", "雨伞", "雨具 伞 防雨 天气", .clothing, "umbrella.fill"),

        // 洗漱护理（8）
        E("wash.towelStack", "叠放毛巾", "毛巾 浴巾 擦脸巾 换洗", .toiletries, "square.stack.3d.up.fill"),
        E("wash.towelHanging", "挂式毛巾", "毛巾 浴巾 洗浴", .toiletries, "shower.fill"),
        E("wash.pouch", "洗漱包", "洗漱 化妆包 盥洗 收纳包", .toiletries, "bag.fill"),
        E("wash.toothbrush", "牙刷", "牙具 刷牙 口腔", .toiletries, "paintbrush.pointed.fill"),
        E("wash.toothpaste", "牙膏", "牙具 挤牙膏 口腔", .toiletries, "testtube.2"),
        E("wash.pumpBottle", "按压瓶", "洗手液 洗发水 沐浴露", .toiletries, "drop.fill"),
        E("wash.lotion", "护肤乳", "乳液 面霜 防晒 护肤", .toiletries, "sparkles"),
        E("wash.medicineBox", "医药箱", "药品 急救 创可贴 健康", .toiletries, "cross.case.fill"),

        // 证件票据（7）
        E("doc.passport", "护照", "护照 证件 出境 签证", .documents, "person.text.rectangle.fill"),
        E("doc.idcard", "证件卡", "身份证 卡片 证件 银行卡", .documents, "creditcard.fill"),
        E("doc.boardingPass", "登机牌", "机票 登机 飞机 航班", .documents, "airplane.ticket"),
        E("doc.ticket", "车票门票", "票 交通票 演出票 入场", .documents, "ticket.fill"),
        E("doc.clipboard", "清单板", "清单 记录 待办 备忘", .documents, "list.clipboard.fill"),
        E("doc.checklist", "勾选清单", "清单 勾选 待办 打勾", .documents, "checklist"),
        E("doc.folder", "文件夹", "文件 资料 合同 归档", .documents, "folder.fill"),

        // 出行提醒（7）
        E("travel.luggageTag", "行李牌", "行李 吊牌 挂牌 托运", .travel, "tag.fill"),
        E("travel.boardingCase", "手提登机箱", "登机箱 手提箱 短途 出差", .travel, "suitcase.fill"),
        E("travel.pin", "定位针", "定位 位置 地点 标记", .travel, "mappin.circle.fill"),
        E("travel.map", "折叠地图", "地图 导航 路线", .travel, "map.fill"),
        E("travel.compass", "指南针", "方向 户外 导航 探索", .travel, "safari.fill"),
        E("travel.alarm", "闹钟", "闹铃 起床 提醒 睡前", .travel, "alarm.fill"),
        E("travel.bell", "通知铃", "铃铛 提醒 通知 消息", .travel, "bell.fill"),

        // 交通住宿（12）
        E("trans.plane", "飞机", "航班 机票 出差 旅行", .transit, "airplane"),
        E("trans.train", "火车", "高铁 地铁 列车 车站", .transit, "tram.fill"),
        E("trans.car", "汽车", "轿车 自驾 开车", .transit, "car.fill"),
        E("trans.taxi", "出租车", "打车 网约车 的士", .transit, "car.fill"),
        E("trans.bus", "公交车", "公交 巴士 车站", .transit, "bus.fill"),
        E("trans.ferry", "轮船", "渡轮 邮轮 海上", .transit, "ferry.fill"),
        E("trans.cityLandmark", "城市建筑", "大楼 写字楼 地标 商圈", .transit, "building.2.fill"),
        E("place.home", "房子", "家 住宅 住处 到家", .transit, "house.fill"),
        E("place.hotel", "酒店", "住宿 床 入住 睡觉", .transit, "bed.double.fill"),
        E("place.storage", "行李寄存", "寄存 储物 储物柜 存包", .transit, "archivebox.fill"),
        E("trans.route", "路线", "路径 途经 规划 导航", .transit, "arrow.triangle.turn.up.right.circle.fill"),
        E("place.navigate", "导航箭头", "导航 前往 方向 到达", .transit, "location.north.fill"),

        // 时间天气（6）
        E("time.calendar", "日历", "日期 行程 安排 出发", .weather, "calendar"),
        E("weather.sunny", "晴天", "太阳 晴 热天", .weather, "sun.max.fill"),
        E("weather.cloudy", "多云", "阴天 云 天气", .weather, "cloud.fill"),
        E("weather.rain", "下雨", "雨天 降雨 带伞", .weather, "cloud.rain.fill"),
        E("weather.snow", "下雪", "雪天 降雪 保暖", .weather, "snowflake"),
        E("weather.thunder", "雷暴", "雷电 雷雨 天气", .weather, "cloud.bolt.fill"),

        // 站点设施（7）
        E("fac.thermometer", "温度计", "温度 体温 天气", .facility, "thermometer"),
        E("fac.securityGate", "安检门", "安检 检票 闸机 通道", .facility, "door.left.hand.open"),
        E("fac.badge", "工作证", "挂牌 证件 门禁 胸卡", .facility, "person.crop.rectangle.fill"),
        E("fac.scale", "体重秤", "秤 体重 健康", .facility, "scalemass.fill"),
        E("fac.luggageScale", "行李秤", "称重 行李 超重", .facility, "scalemass.fill"),
        E("fac.up", "上行", "上楼 电梯 扶梯 上行箭头", .facility, "arrow.up.square.fill"),
        E("fac.down", "下行", "下楼 电梯 扶梯 下行箭头", .facility, "arrow.down.square.fill"),

        // 安全功能（6）
        E("func.search", "搜索", "查找 放大镜 找东西", .security, "magnifyingglass"),
        E("func.gauge", "仪表盘", "码表 速度 进度", .security, "speedometer"),
        E("func.target", "目标", "准星 聚焦 计划", .security, "target"),
        E("func.unlock", "解锁", "开锁 已打开 访问", .security, "lock.open.fill"),
        E("func.lock", "上锁", "锁定 安全 保管", .security, "lock.fill"),
        E("func.biometric", "指纹", "安全 验证 解锁", .security, "touchid"),

        // 界面通信（14）
        E("comm.chatDots", "留言", "聊天 消息 输入中", .interface, "ellipsis.bubble.fill"),
        E("comm.chatText", "消息", "聊天 对话 留言", .interface, "text.bubble.fill"),
        E("comm.signal", "信号", "网络 强度 联网", .interface, "wifi"),
        E("func.pie", "统计占比", "饼图 分析 数据", .interface, "chart.pie.fill"),
        E("func.bars", "统计对比", "柱状图 报表 数据", .interface, "chart.bar.fill"),
        E("ui.grid", "应用宫格", "九宫格 模块 分类", .interface, "square.grid.2x2.fill"),
        E("ui.layers", "图层", "层级 堆叠 叠放", .interface, "square.stack.3d.up.fill"),
        E("ui.add", "添加", "新增 加号 加入", .interface, "plus.square.fill"),
        E("ui.check", "勾选", "完成 确认 打勾", .interface, "checkmark.square.fill"),
        E("ui.star", "星标", "收藏 喜欢 重要", .interface, "star.fill"),
        E("ui.share", "分享", "发送 导出 分享给", .interface, "square.and.arrow.up.fill"),
        E("ui.gear", "设置", "配置 偏好 参数", .interface, "gearshape.fill"),
        E("func.camera", "相机", "拍照 照相 拍摄", .interface, "camera.fill"),
        E("func.scan", "扫描", "识别 取景 扫码", .interface, "viewfinder"),

        // 户外智能（6）
        E("outdoor.tent", "帐篷", "露营 户外 扎营", .outdoor, "flag.2.crossed.fill"),
        E("tech.watch", "智能手表", "手表 穿戴 计步", .outdoor, "applewatch"),
        E("tech.bluetooth", "蓝牙", "连接 配对 无线", .outdoor, "antenna.radiowaves.left.and.right"),
        E("tech.link", "链接", "网址 关联 跳转", .outdoor, "link"),
        E("tech.phoneCharging", "手机充电", "充电 手机 补电", .outdoor, "phone.circle.fill"),
        E("tech.battery", "电池", "电量 充电 耗电", .outdoor, "battery.100.bolt"),
    ]

    /// 按分类 + 查询词过滤；查询词命中中文名、关键词、分类名或素材 id。
    static func search(_ rawQuery: String, category: GowithIconCategory?) -> [GowithIconEntry] {
        let pool = category.map { c in all.filter { $0.category == c } } ?? all
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return pool }
        return pool.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.keywords.localizedCaseInsensitiveContains(query)
                || $0.category.rawValue.localizedCaseInsensitiveContains(query)
                || $0.id.localizedCaseInsensitiveContains(query)
        }
    }

    static func entry(for id: String) -> GowithIconEntry? {
        all.first { $0.id == id }
    }

    private static func E(_ id: String, _ name: String, _ keywords: String, _ category: GowithIconCategory, _ symbol: String) -> GowithIconEntry {
        GowithIconEntry(id: id, name: name, keywords: keywords, category: category, symbol: symbol)
    }
}

/// 图标库渲染：Assets 里有同名素材就用素材，否则回退到 SF Symbol 占位。
struct GowithLibraryIcon: View {
    let entry: GowithIconEntry
    var size: CGFloat = 38
    /// 深色底上转浅色，与 ItemThumbnail 的 isSymbolLight 对齐
    var lightSymbol: Bool = false

    var body: some View {
        Group {
            if UIImage(named: entry.id) != nil {
                Image(entry.id)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.08)
            } else {
                Image(systemName: entry.symbol)
                    .font(.system(size: size * 0.46, weight: .medium))
                    .foregroundStyle(lightSymbol ? GowithColor.onPrimary : GowithColor.ink)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
