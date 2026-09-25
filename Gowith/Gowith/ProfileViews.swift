import SwiftUI

// MARK: - 我的面板（规格 5.4）

struct ProfilePage: View {
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    @AppStorage("gowith.appMode") private var mode: AppMode = .basic
    @AppStorage("gowith.arrivalRemindersEnabled") private var arrivalRemindersEnabled = true
    @AppStorage("gowith.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("gowith.hasSeenTutorial") private var hasSeenTutorial = false
    @AppStorage("gowith.didCompleteSetup") private var didCompleteSetup = false
    @State private var showHistory = false
    @State private var showResetConfirm = false

    private var itemCount: Int { store.visibleItems.count }
    private var completedCount: Int { store.sessions.filter { $0.status == .completed }.count }
    private var pendingCount: Int { store.pendingItemCount }
    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return "v\(version)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: GowithMetrics.moduleSpacing) {
                ContentCard {
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(GowithColor.onPrimary)
                            .frame(width: 44, height: 44)
                            .background(GowithColor.ink, in: Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text("我的面板")
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundStyle(GowithColor.ink)
                            Text("\(itemCount) 件物品 · 完成 \(completedCount) 次清点")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(GowithColor.inkSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                }

                // 待确认物品的显眼入口（不打扰式提醒）：仅在有待确认项时出现，点击进入历史补登。
                if pendingCount > 0 {
                    Button {
                        showHistory = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.badge.exclamationmark.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.92))
                                .frame(width: 38, height: 38)
                                .background(.white.opacity(0.18), in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(pendingCount) 件物品待确认")
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("3 天内未确认将自动标记为遗失")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 66)
                        .background(GowithColor.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(pendingCount) 件物品待确认，打开历史记录补登")
                }

                if locationService.needsPermissionRecovery {
                    GowithLocationRecoveryBanner()
                }

                settingGroup(title: "偏好") {
                    settingRow(icon: "circle.lefthalf.filled", title: "外观", value: mode == .basic ? "基础" : "进阶")
                        .accessibilityHint("在页面右上角切换基础与进阶模式")
                    Divider().padding(.leading, 46)
                    toggleRow(icon: "bell.badge.fill", title: "出门 / 回家提醒", subtitle: "进入地点约 50 米范围时提醒", isOn: $arrivalRemindersEnabled)
                    Divider().padding(.leading, 46)
                    toggleRow(icon: "iphone.radiowaves.left.and.right", title: "触感反馈", subtitle: "勾选与切换时的振动反馈", isOn: $hapticsEnabled)
                }

                settingGroup(title: "功能") {
                    settingRow(icon: "play.rectangle", title: "重新观看引导动画", value: "") { hasSeenTutorial = false }
                    Divider().padding(.leading, 46)
                    settingRow(icon: "clock.arrow.circlepath", title: "历史记录", value: "\(completedCount) 次") { showHistory = true }
                    Divider().padding(.leading, 46)
                    settingRow(icon: "location.fill", title: "定位与围栏", value: locationService.isAuthorized ? "已开启" : "未开启")
                }

                settingGroup(title: "支持") {
                    settingRow(icon: "message", title: "意见反馈", value: "") {
                        if let url = URL(string: "mailto:feedback@gowith.app?subject=Gowith%20反馈") {
                            UIApplication.shared.open(url)
                        }
                    }
                    Divider().padding(.leading, 46)
                    settingRow(icon: "info.circle", title: "关于 Gowith", value: appVersion)
                }

                settingGroup(title: "账号") {
                    Button {
                        showResetConfirm = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "trash")
                                .font(.system(size: 15))
                                .foregroundStyle(GowithColor.accent)
                                .frame(width: 24)
                            Text("清空全部数据")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(GowithColor.accent)
                            Spacer()
                            Text("谨慎")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(GowithColor.onPrimary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(GowithColor.accent, in: Capsule())
                        }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, GowithMetrics.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(GowithColor.appBackground)
        .sheet(isPresented: $showHistory) { HistoryPage() }
        .confirmationDialog("清空全部数据？", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("清空全部数据", role: .destructive) {
                store.resetAll()
                didCompleteSetup = false
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("所有物品、背包、地点与出行记录都会被删除，且无法恢复。")
        }
    }

    private func settingGroup<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(GowithColor.inkSecondary)
                .padding(.horizontal, 6)
            ContentCard(padding: 6) {
                VStack(spacing: 0) { content() }
            }
        }
    }

    private func settingRow(icon: String, title: String, value: String, action: (() -> Void)? = nil) -> some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(GowithColor.ink)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(GowithColor.ink)
                Spacer(minLength: 8)
                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(GowithColor.inkTertiary)
                }
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(GowithColor.inkTertiary)
                }
            }
            .padding(.horizontal, 8)
            .frame(minHeight: 46)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(GowithColor.ink)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(GowithColor.ink)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(GowithColor.inkTertiary)
                }
            }
        }
        .tint(GowithColor.accent)
        .padding(.horizontal, 8)
        .frame(minHeight: 50)
        .onChange(of: isOn.wrappedValue) { _, _ in
            GowithHaptics.selection()
        }
    }
}

// MARK: - 进阶 · 历史与统计页（规格 5.6）

struct HistoryPage: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GowithStore
    @State private var detailSession: OutingSession?

    private var sessions: [OutingSession] { store.sessions.sorted { $0.startedAt > $1.startedAt } }

    private var thisMonthSessions: [OutingSession] {
        let calendar = Calendar.current
        return sessions.filter { session in
            guard session.status == .completed else { return false }
            return calendar.isDate(session.completedAt ?? session.startedAt, equalTo: .now, toGranularity: .month)
        }
    }
    private var monthLostCount: Int {
        thisMonthSessions.reduce(0) { $0 + $1.items.filter { $0.status == .lost }.count }
    }

    /// 近 30 天清点完成率：无待确认且无遗失的会话占比。
    private var completionRate: Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        let recent = sessions.filter { ($0.completedAt ?? $0.startedAt) >= cutoff && $0.status == .completed }
        guard !recent.isEmpty else { return nil }
        let clean = recent.filter { session in
            session.items.allSatisfy { $0.status == .returned || $0.status == .stored || $0.status == .carried }
        }
        return Double(clean.count) / Double(recent.count)
    }

    /// 连续零遗失天数：距最近一次遗失标记的时间；从未遗失则从首次出行算起。
    private var zeroLostDays: Int {
        let lostDates = sessions.flatMap { $0.items.compactMap(\.lostAt) }
        let reference: Date
        if let latestLost = lostDates.max() {
            reference = latestLost
        } else if let first = sessions.map(\.startedAt).min() {
            reference = first
        } else {
            return 0
        }
        return max(0, Int(Date().timeIntervalSince(reference) / 86400))
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetNavBar(
                title: "历史",
                saveTitle: "完成",
                saveEnabled: true,
                showsCancel: false,
                onCancel: { dismiss() },
                onSave: { dismiss() }
            )
            ScrollView {
                VStack(spacing: GowithMetrics.moduleSpacing) {
                    AssetCard(
                        header: "历史",
                        headerEN: "HISTORY",
                        badge: "本月",
                        leftValue: "\(thisMonthSessions.count)",
                        leftUnit: "次",
                        leftLabel: "完成清点",
                        rightValue: "\(monthLostCount)",
                        rightUnit: "件",
                        rightLabel: "遗失物品",
                        isDarkVariant: true
                    )

                    recentList

                    ContentCard(padding: 12) {
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 15))
                                    .foregroundStyle(GowithColor.ink)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("清点完成率")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(GowithColor.ink)
                                    Text("近 30 天")
                                        .font(.system(size: 10))
                                        .foregroundStyle(GowithColor.inkTertiary)
                                }
                                Spacer()
                                Text(completionRate.map { "\(Int(($0 * 100).rounded()))%" } ?? "—")
                                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                                    .foregroundStyle(GowithColor.ink)
                            }
                            .frame(minHeight: 52)
                            Divider().padding(.leading, 44)
                            HStack(spacing: 12) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(GowithColor.accent)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("连续零遗失")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(GowithColor.ink)
                                    Text("天数")
                                        .font(.system(size: 10))
                                        .foregroundStyle(GowithColor.inkTertiary)
                                }
                                Spacer()
                                Text("\(zeroLostDays) 天")
                                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                                    .foregroundStyle(GowithColor.ink)
                            }
                            .frame(minHeight: 52)
                        }
                    }
                }
                .padding(.horizontal, GowithMetrics.pagePadding)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .background(GowithColor.appBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .sheet(item: $detailSession) { session in
            SessionDetailView(session: session)
        }
    }

    @ViewBuilder
    private var recentList: some View {
        ContentCard(padding: 10) {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("最近清点")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(GowithColor.inkSecondary)
                    Spacer()
                    Text("\(sessions.count) 次")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(GowithColor.inkTertiary)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)

                if sessions.isEmpty {
                    Text("还没有历史记录。开始出行后，这里会显示每次清点。")
                        .font(.system(size: 11))
                        .foregroundStyle(GowithColor.inkTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 14)
                } else {
                    ForEach(Array(sessions.prefix(12).enumerated()), id: \.element.id) { index, session in
                        HistoryRow(session: session) { detailSession = session }
                        if index < min(sessions.count, 12) - 1 {
                            Divider().padding(.leading, 58)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 历史行（状态圆点：绿=完成，橙=待确认，规格 5.6）

struct HistoryRow: View {
    let session: OutingSession
    let onOpen: () -> Void

    private var hasPending: Bool { session.items.contains { $0.status == .pending } }
    private var hasLost: Bool { session.items.contains { $0.status == .lost } }

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                Circle()
                    .fill(hasLost ? GowithColor.accent : hasPending ? GowithColor.accent : Color.green)
                    .frame(width: 7, height: 7)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(session.backpackNameSnapshot ?? "出行")
                            .font(GowithFont.rowTitle)
                            .foregroundStyle(GowithColor.ink)
                            .lineLimit(1)
                        Text("· \(session.items.count) 件")
                            .font(GowithFont.rowSubtitle)
                            .foregroundStyle(GowithColor.inkTertiary)
                    }
                    Text(session.startedAt, format: .dateTime.month().day().hour().minute())
                        .font(GowithFont.rowSubtitle)
                        .foregroundStyle(GowithColor.inkTertiary)
                }
                Spacer(minLength: 8)
                Text(session.status == .completed ? (hasLost ? "有遗失" : hasPending ? "待确认" : "完成") : "进行中")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(session.status == .completed && !hasPending && !hasLost ? Color.green : GowithColor.accent)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(GowithColor.inkTertiary)
            }
            .padding(.horizontal, 4)
            .frame(minHeight: GowithMetrics.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(session.backpackNameSnapshot ?? "出行")，\(session.items.count) 件，\(session.status == .completed ? "已完成" : "进行中")")
    }
}

// MARK: - 清点详情（保留待确认补登逻辑）

struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GowithStore
    let session: OutingSession

    var body: some View {
        VStack(spacing: 0) {
            SheetNavBar(
                title: "清点详情",
                saveTitle: "完成",
                saveEnabled: true,
                showsCancel: false,
                onCancel: { dismiss() },
                onSave: { dismiss() }
            )
            ScrollView {
                VStack(spacing: GowithMetrics.moduleSpacing) {
                    ContentCard(padding: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.startedAt, format: .dateTime.year().month().day().hour().minute())
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(GowithColor.ink)
                            HStack(spacing: 10) {
                                if let backpackName = session.backpackNameSnapshot {
                                    Text(backpackName)
                                }
                                if let origin = session.originPlaceNameSnapshot {
                                    Text("从「\(origin)」出发")
                                }
                            }
                            .font(.system(size: 11))
                            .foregroundStyle(GowithColor.inkSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ContentCard(padding: 8) {
                        VStack(spacing: 0) {
                            ForEach(Array(session.items.enumerated()), id: \.element.id) { index, item in
                                HStack(spacing: 12) {
                                    ItemThumbnail(fileName: item.imageFileNameSnapshot, symbolName: item.symbolNameSnapshot, size: 34)
                                    Text(item.nameSnapshot)
                                        .font(GowithFont.rowTitle)
                                        .foregroundStyle(GowithColor.ink)
                                        .lineLimit(1)
                                    Spacer(minLength: 8)
                                    if item.status == .pending {
                                        Menu {
                                            Button("已带回", systemImage: "checkmark.circle") { resolve(item, as: .returned) }
                                            Button("遗失", systemImage: "exclamationmark.circle") { resolve(item, as: .lost) }
                                        } label: {
                                            GowithStatusBadge(status: item.status)
                                        }
                                    } else {
                                        GowithStatusBadge(status: item.status)
                                    }
                                }
                                .padding(.horizontal, 6)
                                .frame(minHeight: 48)
                                .contentShape(Rectangle())
                                if index < session.items.count - 1 {
                                    Divider().padding(.leading, 52)
                                }
                            }
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private func resolve(_ item: SessionItem, as status: SessionItemStatus) {
        guard item.status == .pending else { return }
        GowithHaptics.selection()
        item.status = status
        item.pendingSince = nil
        item.checkedAt = .now
        if status == .lost {
            item.lostAt = .now
        }
        // 物品确认后归入出发地，避免 placeID 悬空导致物品在所有界面不可见。
        if let index = store.items.firstIndex(where: { $0.id == item.itemID }) {
            if status == .lost { store.items[index].lostCount += 1 }
            if store.items[index].placeID == nil {
                store.items[index].placeID = session.originPlaceID ?? store.places.first?.id
            }
        }
        store.save()
    }
}
