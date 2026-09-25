import SwiftUI

// MARK: - 拿东西页（规格 5.2，含出行中 away 只读态）

struct PackingPage: View {
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    let onPack: (GowithItem) -> Void
    let onRequestManualArrive: () -> Void

    @State private var showBackpackPicker = false

    private var awaySession: OutingSession? {
        guard let session = store.activeSession, session.status == .away else { return nil }
        return session
    }

    private var packed: [GowithItem] { store.packedItems(in: store.selectedBackpack) }
    private var remaining: [GowithItem] { store.remainingShelfItems }
    private var canManage: Bool {
        guard let place = store.selectedPlace else { return false }
        return locationService.isInside(place)
    }

    /// 装包/移除需要围栏内且没有进行中的会话（checking 阶段用户在家，同样不允许改动背包）。
    private var canPack: Bool {
        canManage && store.activeSession == nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: GowithMetrics.moduleSpacing) {
                if let session = awaySession {
                    awayContent(session)
                } else {
                    preTripContent
                }
            }
            .padding(.horizontal, GowithMetrics.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(GowithColor.appBackground)
        .sheet(isPresented: $showBackpackPicker) { BackpackPickerSheet() }
    }

    // MARK: 出行前（装包）

    @ViewBuilder
    private var preTripContent: some View {
        AssetCard(
            header: "拿东西",
            headerEN: "PACKING",
            badge: store.selectedBackpack?.name ?? "选择背包",
            badgeAction: { showBackpackPicker = true },
            leftValue: "\(packed.count)",
            leftUnit: "件",
            leftLabel: "已装入",
            rightValue: "\(remaining.count)",
            rightUnit: "件",
            rightLabel: "货架剩余",
            ctaPlain: "核对完成，点底部 ",
            ctaAccent: "开始出行",
            texture: .rings
        )

        if locationService.needsPermissionRecovery {
            GowithLocationRecoveryBanner()
        } else if let place = store.selectedPlace, !canManage {
            FenceGateNote(placeName: place.name)
        }

        if store.selectedBackpack == nil {
            ContentCard {
                VStack(spacing: 8) {
                    Image(systemName: "backpack")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(GowithColor.inkTertiary)
                    Text("还没有背包")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(GowithColor.ink)
                    Text("点右上角「选择背包」创建或切换。")
                        .font(.system(size: 11))
                        .foregroundStyle(GowithColor.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            }
        } else {
            packedListCard
            remainingCard
        }

        NoteCard(
            title: "出行后",
            systemImage: "location.fill",
            lines: [
                "离开家 50 米后自动记录本次清单；",
                "回到任意已保存地点自动触发清点。",
            ]
        )
    }

    private var packedListCard: some View {
        ContentCard(padding: 10) {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(store.selectedBackpack?.name ?? "背包")清单 · \(packed.count) 件")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(GowithColor.inkSecondary)
                    Spacer()
                    Text("点行取消")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(GowithColor.inkTertiary)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)

                if packed.isEmpty {
                    Text("还没有装入物品，从下方货架点 + 补装。")
                        .font(.system(size: 11))
                        .foregroundStyle(GowithColor.inkTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                } else {
                    ForEach(Array(packed.enumerated()), id: \.element.id) { index, item in
                        PackedRow(item: item, isEditable: canPack) {
                            onPack(item)
                        }
                        if index < packed.count - 1 {
                            Divider().padding(.leading, 62)
                        }
                    }
                }
            }
        }
    }

    private var remainingCard: some View {
        ContentCard(padding: 10) {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("货架剩余 · \(remaining.count) 件")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(GowithColor.inkSecondary)
                    Spacer()
                    Text("点 + 补装")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(GowithColor.inkTertiary)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)

                if remaining.isEmpty {
                    Text("货架没有剩余物品。")
                        .font(.system(size: 11))
                        .foregroundStyle(GowithColor.inkTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                } else {
                    ForEach(Array(remaining.enumerated()), id: \.element.id) { index, item in
                        ShelfRow(
                            item: item,
                            placeName: store.place(for: item.placeID)?.name,
                            isPacked: false,
                            isEditable: canPack,
                            onTogglePack: { onPack(item) },
                            onEdit: {}
                        )
                        if index < remaining.count - 1 {
                            Divider().padding(.leading, 62)
                        }
                    }
                }
            }
        }
    }

    // MARK: 出行中（away 只读态，规格 5.2）

    private func awayContent(_ session: OutingSession) -> some View {
        VStack(spacing: GowithMetrics.moduleSpacing) {
            AssetCard(
                header: "出行中",
                headerEN: "AWAY",
                badge: "从「\(session.originPlaceNameSnapshot ?? "出发地")」出发",
                leftValue: "\(session.items.count)",
                leftUnit: "件",
                leftLabel: "携带中",
                rightValue: awayDurationValue(session).value,
                rightUnit: awayDurationValue(session).unit,
                rightLabel: "已出门",
                texture: .rings
            )

            ContentCard(padding: 10) {
                VStack(spacing: 0) {
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(GowithColor.accent)
                                .frame(width: 6, height: 6)
                            Text("出行中 · 清单已锁定")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(GowithColor.ink)
                        }
                        Spacer()
                        Text("\(session.backpackNameSnapshot ?? "背包") · 只读")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(GowithColor.inkTertiary)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)

                    ForEach(Array(session.items.enumerated()), id: \.element.id) { index, item in
                        CarriedRow(item: item)
                        if index < session.items.count - 1 {
                            Divider().padding(.leading, 62)
                        }
                    }
                }
            }

            Button {
                onRequestManualArrive()
            } label: {
                Label("手动确认到家或地点…", systemImage: "mappin.and.ellipse")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(GowithColor.inkSecondary)
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .background(GowithColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(GowithColor.surfaceBorder, lineWidth: 1).allowsHitTesting(false)
                    }
            }
            .buttonStyle(.plain)

            NoteCard(
                title: "到达后",
                systemImage: "location.fill",
                lines: [
                    "进入任意已保存地点 50 米范围，",
                    "自动切换到「检查」开始清点。",
                ]
            )
        }
    }

    private func awayDurationValue(_ session: OutingSession) -> (value: String, unit: String) {
        let reference = session.wentOutAt ?? session.startedAt
        let minutes = max(0, Int(Date().timeIntervalSince(reference) / 60))
        if minutes < 60 { return ("\(minutes)", "分钟") }
        if minutes < 60 * 24 { return ("\(minutes / 60)", "小时") }
        return ("\(minutes / (60 * 24))", "天")
    }
}

/// 出行中只读行（清单锁定）。
private struct CarriedRow: View {
    let item: SessionItem

    var body: some View {
        HStack(spacing: 12) {
            ItemThumbnail(fileName: item.imageFileNameSnapshot, symbolName: item.symbolNameSnapshot, size: GowithMetrics.rowIconSize)
                .background(GowithColor.softSurface, in: RoundedRectangle(cornerRadius: GowithMetrics.rowIconRadius, style: .continuous))
            Text(item.nameSnapshot)
                .font(GowithFont.rowTitle)
                .foregroundStyle(GowithColor.ink)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text("携带中")
                .font(GowithFont.rowSubtitle)
                .foregroundStyle(GowithColor.accent)
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(GowithColor.ink)
                .frame(width: 29, height: 29)
                .background(GowithColor.softSurface, in: Circle())
        }
        .padding(.horizontal, 4)
        .frame(minHeight: GowithMetrics.rowHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.nameSnapshot)，携带中")
    }
}

/// 已装入行（点整行取消装包）。
private struct PackedRow: View {
    let item: GowithItem
    let isEditable: Bool
    let onRemove: () -> Void

    var body: some View {
        Button(action: onRemove) {
            HStack(spacing: 12) {
                ItemThumbnail(fileName: item.imageFileName, symbolName: item.symbolName, size: GowithMetrics.rowIconSize, isSymbolLight: true)
                    .background(GowithColor.ink, in: RoundedRectangle(cornerRadius: GowithMetrics.rowIconRadius, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(GowithFont.rowTitle)
                        .foregroundStyle(GowithColor.ink)
                        .lineLimit(1)
                    Text("已装入")
                        .font(GowithFont.rowSubtitle)
                        .foregroundStyle(GowithColor.accent)
                }
                Spacer(minLength: 8)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(GowithColor.onPrimary)
                    .frame(width: 29, height: 29)
                    .background(GowithColor.ink, in: Circle())
            }
            .padding(.horizontal, 4)
            .frame(minHeight: GowithMetrics.rowHeight)
            .contentShape(Rectangle())
            .opacity(isEditable ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isEditable)
        .accessibilityLabel("\(item.name)，已装入")
        .accessibilityHint("双击从背包移除")
    }
}

// MARK: - 检查页（规格 5.3，覆盖 checking 清点与 arrived 检阅）

struct CheckPage: View {
    @EnvironmentObject private var store: GowithStore
    @Binding var isReviewingArrival: Bool

    private var session: OutingSession? {
        guard let session = store.activeSession else { return nil }
        guard session.status == .checking || session.status == .arrived else { return nil }
        return session
    }

    var body: some View {
        ScrollView {
            VStack(spacing: GowithMetrics.moduleSpacing) {
                if let session {
                    switch session.status {
                    case .checking:
                        checkingContent(session)
                    case .arrived:
                        arrivedContent(session)
                    default:
                        emptyState
                    }
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, GowithMetrics.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(GowithColor.appBackground)
        .animation(GowithMotion.content, value: isReviewingArrival)
    }

    private var emptyState: some View {
        VStack(spacing: GowithMetrics.moduleSpacing) {
            AssetCard(
                header: "检查",
                headerEN: "CHECK-IN",
                leftValue: "0",
                leftUnit: "件",
                leftLabel: "已带回",
                rightValue: "0",
                rightUnit: "件",
                rightLabel: "待确认",
                texture: .crossCircle
            )
            ContentCard {
                VStack(spacing: 8) {
                    Image(systemName: "checklist")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(GowithColor.inkTertiary)
                    Text("还没有进行中的清点")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(GowithColor.ink)
                    Text("开始出行并到达地点后，会自动进入清点。")
                        .font(.system(size: 11))
                        .foregroundStyle(GowithColor.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
    }

    // MARK: 回家清点（checking）

    private func checkingContent(_ session: OutingSession) -> some View {
        let returned = session.items.filter { $0.status == .returned }.count
        let unconfirmed = session.items.filter { $0.status == .unconfirmed || $0.status == .pending }.count
        return VStack(spacing: GowithMetrics.moduleSpacing) {
            AssetCard(
                header: "检查",
                headerEN: "CHECK-IN",
                badge: "回家清点",
                leftValue: "\(returned)",
                leftUnit: "件",
                leftLabel: "已带回",
                rightValue: "\(unconfirmed)",
                rightUnit: "件",
                rightLabel: "待确认",
                ctaPlain: "勾完点底部 ",
                ctaAccent: "完成清点",
                texture: .crossCircle
            )

            ContentCard(padding: 10) {
                VStack(spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("本次带出 \(session.items.count) 件")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(GowithColor.inkSecondary)
                        Spacer()
                        Text("点整行核对")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(GowithColor.inkTertiary)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)

                    ForEach(Array(session.items.enumerated()), id: \.element.id) { index, item in
                        CheckRow(
                            name: item.nameSnapshot,
                            fileName: item.imageFileNameSnapshot,
                            symbolName: item.symbolNameSnapshot,
                            isReturned: item.status == .returned
                        ) {
                            toggle(item)
                        }
                        if index < session.items.count - 1 {
                            Divider().padding(.leading, 62)
                        }
                    }

                    Divider().padding(.top, 4)
                    Text("找不到可标「待确认」，3 天内补登。")
                        .font(.system(size: 10))
                        .foregroundStyle(GowithColor.inkTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }
            }

            checkinTipsCard(session)
        }
    }

    /// 清点小贴士：只引用现有数据（历史会话中物品的存放地点 + 出发地快照），无待确认项时隐藏（规格 5.3）。
    private func checkinTipsCard(_ session: OutingSession) -> some View {
        let unresolved = session.items.filter { $0.status == .unconfirmed || $0.status == .pending }
        let lines = unresolved.prefix(3).map { item -> String in
            "「\(item.nameSnapshot)」最后记录在「\(lastKnownPlaceName(for: item, in: session))」。"
        }
        return Group {
            if !unresolved.isEmpty {
                NoteCard(
                    title: "清点小贴士",
                    systemImage: "lightbulb.fill",
                    lines: lines + ["3 天内未确认将自动标记为遗失。"]
                )
            }
        }
    }

    /// 物品最近一次被存放的地点：查历史已完成会话的 stored 记录；没有则回退出发地快照。
    private func lastKnownPlaceName(for item: SessionItem, in current: OutingSession) -> String {
        let pastSessions = store.sessions
            .filter { $0.id != current.id && $0.status == .completed }
            .sorted { ($0.completedAt ?? $0.startedAt) > ($1.completedAt ?? $1.startedAt) }
        for past in pastSessions {
            if let record = past.items.first(where: { $0.itemID == item.itemID && $0.status == .stored }),
               let placeID = record.destinationPlaceID,
               let place = store.place(for: placeID) {
                return place.name
            }
        }
        return current.originPlaceNameSnapshot ?? "出发地"
    }

    // MARK: 到达检阅（arrived：选择放入目的地的物品）

    private func arrivedContent(_ session: OutingSession) -> some View {
        let destinationName = session.destinationPlaceNameSnapshot ?? "该地点"
        return VStack(spacing: GowithMetrics.moduleSpacing) {
            if isReviewingArrival {
                let selectedCount = session.items.filter(\.isSelected).count
                let carriedCount = session.items.count - selectedCount
                AssetCard(
                    header: "选择放入",
                    headerEN: "ARRIVED",
                    badge: "在「\(destinationName)」",
                    leftValue: "\(selectedCount)",
                    leftUnit: "件",
                    leftLabel: "放入该地点",
                    rightValue: "\(carriedCount)",
                    rightUnit: "件",
                    rightLabel: "继续携带",
                    ctaPlain: "未选择的物品",
                    ctaAccent: "继续随身携带",
                    texture: .crossCircle
                )
                ContentCard(padding: 10) {
                    VStack(spacing: 0) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("本次带出 \(session.items.count) 件")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(GowithColor.inkSecondary)
                            Spacer()
                            Text("点行选择")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(GowithColor.inkTertiary)
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)

                        ForEach(Array(session.items.enumerated()), id: \.element.id) { index, item in
                            CheckRow(
                                name: item.nameSnapshot,
                                fileName: item.imageFileNameSnapshot,
                                symbolName: item.symbolNameSnapshot,
                                isReturned: item.isSelected,
                                selectedTitle: "放入此地",
                                unselectedTitle: "随身携带"
                            ) {
                                item.isSelected.toggle()
                                GowithHaptics.selection()
                                store.save()
                            }
                            if index < session.items.count - 1 {
                                Divider().padding(.leading, 62)
                            }
                        }
                    }
                }
            } else {
                AssetCard(
                    header: "已到达",
                    headerEN: "ARRIVED",
                    badge: "在「\(destinationName)」",
                    leftValue: "\(session.items.count)",
                    leftUnit: "件",
                    leftLabel: "本次带出",
                    rightValue: "\(session.items.count)",
                    rightUnit: "件",
                    rightLabel: "待处理",
                    ctaPlain: "准备好后，点底部 ",
                    ctaAccent: "开始检阅",
                    texture: .crossCircle
                )
                ContentCard(padding: 10) {
                    VStack(spacing: 0) {
                        ForEach(Array(session.items.enumerated()), id: \.element.id) { index, item in
                            CarriedRow(item: item)
                            if index < session.items.count - 1 {
                                Divider().padding(.leading, 62)
                            }
                        }
                    }
                }
                NoteCard(
                    title: "接下来",
                    systemImage: "checklist",
                    lines: [
                        "点底部「开始检阅」选择放入此地的物品；",
                        "未选择的物品会继续随身携带。",
                    ]
                )
            }
        }
    }

    private func toggle(_ item: SessionItem) {
        GowithHaptics.selection()
        if item.status == .returned {
            item.status = .unconfirmed
        } else {
            item.status = .returned
            item.pendingSince = nil
        }
        item.checkedAt = .now
        store.save()
    }
}
