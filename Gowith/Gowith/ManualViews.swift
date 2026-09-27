import SwiftUI

// MARK: - 应用内操作手册（进阶 · 深入查询）：基础篇 + 进阶篇

/// 「我的 → 操作手册」：把 docs/使用手册.md 的核心内容做成应用内可折叠手册。
/// 基础篇 = 日常使用必读；进阶篇 = 深入了解全部操作。默认收起，点开即读。
struct ManualView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expanded: Set<String> = ["basic-intro"]

    var body: some View {
        VStack(spacing: 0) {
            SheetNavBar(
                title: "操作手册",
                saveTitle: "完成",
                saveEnabled: true,
                onCancel: { dismiss() },
                onSave: { dismiss() }
            )
            ScrollView {
                VStack(spacing: GowithMetrics.moduleSpacing) {
                    manualIntro

                    manualGroup(title: "基础篇 · 日常必读", icon: "house.fill") {
                        manualSection(id: "basic-intro", icon: "lightbulb.fill", title: "认识 Gowith") {
                            manualParagraph("Gowith = Go + with，带着走。它管住「家 → 背包 → 出行 → 清点」整条链路：家里有什么、包里装了什么、出门带没带、回家丢了没，一件都看得见。")
                            manualWords()
                        }
                        manualSection(id: "basic-start", icon: "flag.checkered", title: "三步上手") {
                            manualStep(number: 1, text: "建家：按引导输入家的名字，用地图选好位置——它用来判断你是否「到家」。")
                            manualStep(number: 2, text: "建背包、上货架：点右下角 ＋ 随时添加物品 / 背包 / 地点。")
                            manualStep(number: 3, text: "装包出发：在家页点物品行的 ＋ 装包 → 「拿东西」核对 → 点底部按钮开始出行。")
                        }
                        manualSection(id: "basic-home", icon: "house.fill", title: "「家」页 · 物品都在这") {
                            manualLine("资产卡显示当前家的名字与物品数；家切换条一点切换视角。")
                            manualLine("当前背包卡：正在使用的背包、里面装了什么、从哪个家拿出。")
                            manualLine("全部家：每个家只显示计数，点开才看到里面的背包与货架（货架按分类分组）。")
                            manualLine("背包详情：包里每件物品的归属家、分类、收录天数、遗失次数。")
                            manualLine("物品行 ＋ = 装包，再点变 ✕ = 移出；点行本体 = 编辑。")
                        }
                        manualSection(id: "basic-packing", icon: "backpack.fill", title: "拿东西 · 出发前核对") {
                            manualLine("上半是已装入清单，点行可移除；下半是货架剩余，点 ＋ 补装。")
                            manualLine("核对完点底部「开始出行」，清单自动锁定防止误改。")
                        }
                        manualSection(id: "basic-check", icon: "checklist", title: "检查 · 回家清点") {
                            manualLine("到家自动进入清点，逐行打勾确认「已带回」。")
                            manualLine("没勾的进入「待确认」，保留 3 天；期间可在「我的 → 历史记录」补登，超时自动记遗失。")
                            manualLine("到达公司等其他地点时，会请你勾选哪些物品放入此地，没勾的继续随身。")
                        }
                    }

                    manualGroup(title: "进阶篇 · 深入了解", icon: "map.fill") {
                        manualSection(id: "adv-fence", icon: "location.fill", title: "围栏与提醒") {
                            manualLine("每个地点有约 50 米的隐形围栏：离开开始记录行程，进入自动触发清点 / 检阅。")
                            manualLine("没触发可在拿东西页点「手动确认到家或地点…」。")
                            manualLine("需要定位权限（使用 App 期间 + 后台）；误关时「我的」页会出现一键恢复条。")
                        }
                        manualSection(id: "adv-lost", icon: "exclamationmark.triangle.fill", title: "待确认与遗失") {
                            manualLine("清点没勾的物品 → 待确认（检查页与我的页角标提示数量）。")
                            manualLine("3 天内补登：历史记录打开那次会议改为「已带回」。")
                            manualLine("3 天后自动转遗失，该物品遗失次数 +1——经常丢的东西一眼可见。")
                        }
                        manualSection(id: "adv-map", icon: "map.fill", title: "地图（进阶模式）") {
                            manualLine("右上角切到「进阶」解锁地图页与深色外观。")
                            manualLine("地图显示所有家的位置与 50 米围栏；点大头针可切换当前家。")
                        }
                        manualSection(id: "adv-data", icon: "lock.shield.fill", title: "数据与隐私") {
                            manualLine("所有数据只存在手机本地的应用目录，不上传任何服务器，无需注册。")
                            manualLine("物品照片自动压缩存储；删除物品 / 背包时照片一并删除。")
                            manualLine("暂无云同步；换机数据不自动迁移。")
                        }
                        manualSection(id: "adv-faq", icon: "questionmark.circle.fill", title: "常见问题") {
                            manualLine("装包按钮是灰的？——出行中清单锁定，或不在地点 50 米围栏内。")
                            manualLine("删不掉地点？——先移走里面的物品和背包，且至少保留一个地点。")
                            manualLine("删背包丢东西吗？——不丢，物品还在物品库，只是不再装在任何背包里。")
                            manualLine("误点开始出行？——拿东西页「手动确认到家或地点…」选出发地即可进入清点。")
                        }
                        manualSection(id: "adv-gestures", icon: "hand.tap.fill", title: "手势速查") {
                            manualGesture(action: "添加物品 / 背包 / 家", how: "右下角 ＋")
                            manualGesture(action: "装包 / 移出背包", how: "物品行右侧 ＋ / ✕")
                            manualGesture(action: "编辑物品", how: "点物品行")
                            manualGesture(action: "切换当前家", how: "家页胶囊 / 地图大头针")
                            manualGesture(action: "看一个家里有什么", how: "点开该家的卡片")
                            manualGesture(action: "看背包明细与归属", how: "点当前背包卡")
                            manualGesture(action: "手动触发到家", how: "拿东西页 → 手动确认")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .background(GowithColor.appBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private var manualIntro: some View {
        ContentCard {
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(GowithColor.onPrimary)
                    .frame(width: 40, height: 40)
                    .background(GowithColor.ink, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("想深入了解每个操作？都在这里。")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(GowithColor.ink)
                    Text("基础篇教你日常怎么用，进阶篇查全部规则。")
                        .font(.system(size: 10.5))
                        .foregroundStyle(GowithColor.inkSecondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func manualGroup<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(GowithColor.inkSecondary)
                .padding(.horizontal, 6)
                .padding(.top, 4)
            content()
        }
    }

    private func manualSection<Content: View>(id: String, icon: String, title: String, @ViewBuilder lines: @escaping () -> Content) -> some View {
        DisclosureGroup(isExpanded: Binding(
            get: { expanded.contains(id) },
            set: { isOpen in
                withAnimation(GowithMotion.content) {
                    if isOpen { expanded.insert(id) } else { expanded.remove(id) }
                }
            }
        )) {
            VStack(alignment: .leading, spacing: 9) { lines() }
                .padding(.top, 10)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GowithColor.accent)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(GowithColor.ink)
                Spacer(minLength: 0)
            }
        }
        .tint(GowithColor.inkTertiary)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GowithColor.surface, in: RoundedRectangle(cornerRadius: GowithMetrics.contentCardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: GowithMetrics.contentCardRadius, style: .continuous)
                .stroke(GowithColor.surfaceBorder.opacity(0.7), lineWidth: 1).allowsHitTesting(false)
        }
    }

    private func manualParagraph(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(GowithColor.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// 核心概念四词表（认识 Gowith 内）。
    private func manualWords() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            manualWord(word: "家", meaning: "你保存的地点（家、公司…），物品和背包都放在某个家里")
            manualWord(word: "背包", meaning: "装物品出门的容器")
            manualWord(word: "出行", meaning: "带着背包从当前家出门的一段行程")
            manualWord(word: "清点", meaning: "到家后逐件确认带出的东西有没有带回来")
        }
        .padding(.top, 4)
    }

    private func manualWord(word: String, meaning: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(word)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(GowithColor.accent)
                .frame(width: 34, alignment: .leading)
            Text(meaning)
                .font(.system(size: 11.5))
                .foregroundStyle(GowithColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func manualLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Circle()
                .fill(GowithColor.accent.opacity(0.85))
                .frame(width: 4.5, height: 4.5)
                .padding(.top, 5)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(GowithColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func manualStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Text("\(number)")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(GowithColor.ink, in: Circle())
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(GowithColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func manualGesture(action: String, how: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(action)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(GowithColor.ink)
            Spacer(minLength: 12)
            Text(how)
                .font(.system(size: 11))
                .foregroundStyle(GowithColor.inkSecondary)
        }
        .padding(.vertical, 2)
    }
}
