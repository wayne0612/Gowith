import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    let sessions: [OutingSession]
    let items: [GowithItem]
    @State private var showHistory = false
    @AppStorage("gowith.arrivalRemindersEnabled") private var arrivalRemindersEnabled = true

    private var completedCount: Int { sessions.filter { $0.status == .completed }.count }
    private var lostCount: Int { items.reduce(0) { $0 + $1.lostCount } }
    private var activeSession: OutingSession? { store.activeSession }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    GowithTopBar(pageTitle: "我的", showsPlace: false) {
                        EmptyView()
                    }
                    Text("把地点、背包和物品放在同一个视野里。")
                        .font(.subheadline)
                        .foregroundStyle(GowithColor.secondary)
                    currentJourney
                    GowithSectionHeader(title: "你的统计")
                    HStack(spacing: 10) {
                        metric(value: "\(sessions.count)", label: "出门次数", color: GowithColor.sceneSky)
                        metric(value: "\(completedCount)", label: "完成清点", color: GowithColor.sceneMint)
                        metric(value: "\(lostCount)", label: "累计遗失", color: GowithColor.sceneCoral)
                    }
                    GowithSectionHeader(title: "地点与库存", trailing: "\(store.places.count) 个地点")
                    PlaceInventoryDashboard()
                    GowithSectionHeader(title: "设置")
                    VStack(spacing: 0) {
                        settingRow(icon: "clock", title: "待确认期限", value: "3 天")
                        Divider().padding(.leading, 56)
                        Toggle(isOn: $arrivalRemindersEnabled) {
                            HStack(spacing: 14) {
                                Image(systemName: "bell.badge.fill")
                                    .frame(width: 24)
                                    .foregroundStyle(GowithColor.primary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("到达提醒")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(GowithColor.primary)
                                    Text("进入地点约 50 米范围时提醒")
                                        .font(.caption)
                                        .foregroundStyle(GowithColor.tertiary)
                                }
                            }
                        }
                        .tint(GowithColor.success)
                        .padding(16)
                        .frame(minHeight: 56)
                        Divider().padding(.leading, 56)
                        settingRow(icon: "clock.arrow.circlepath", title: "历史记录", value: "查看") { showHistory = true }
                        Divider().padding(.leading, 56)
                        settingRow(icon: "location.fill", title: "定位范围", value: "约 50 米")
                        Divider().padding(.leading, 56)
                        settingRow(icon: "info.circle", title: "关于 Gowith", value: "MVP")
                    }
                    Text("让每次出门，都知道自己带了什么。")
                        .font(.subheadline)
                        .foregroundStyle(GowithColor.secondary)
                    Text("本地保存 · iOS MVP")
                        .font(.footnote)
                        .foregroundStyle(GowithColor.tertiary)
                }
                .padding(.horizontal, GowithMetrics.pagePadding)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(GowithColor.appBackground)
            .sheet(isPresented: $showHistory) { HistoryView() }
        }
    }

    private var currentJourney: some View {
        if let activeSession {
            GowithStatusScene(
                color: activeSession.status == .away ? GowithColor.sceneSky : GowithColor.sceneMint,
                systemImage: activeSession.status == .away ? "figure.walk" : "checkmark.circle.fill",
                title: activeSession.status == .away ? "正在出行" : "正在处理本次行程",
                message: "\(activeSession.backpackNameSnapshot ?? "当前背包") · \(activeSession.items.count) 件物品"
            )
        } else {
            GowithStatusScene(
                color: GowithColor.sceneMint,
                systemImage: "location.fill",
                title: store.selectedPlace?.name ?? "还没有选择地点",
                message: store.selectedBackpack.map { "当前背包：\($0.name)" } ?? "先选择一个地点和背包，开始建立你的出行上下文。"
            )
        }
    }

    private func metric(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(value).font(.title3.weight(.semibold))
            Text(label).font(.caption).foregroundStyle(GowithColor.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 12)
        .frame(minHeight: 68)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4, height: 46)
        }
    }

    private func settingRow(icon: String, title: String, value: String, action: (() -> Void)? = nil) -> some View {
        Button { action?() } label: {
            HStack(spacing: 14) {
                Image(systemName: icon).frame(width: 24).foregroundStyle(GowithColor.primary)
                Text(title).font(.body.weight(.medium)).foregroundStyle(GowithColor.primary)
                Spacer()
                Text(value).font(.footnote).foregroundStyle(GowithColor.secondary)
                if action != nil { Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(GowithColor.tertiary) }
            }
            .padding(16)
            .frame(minHeight: 56)
        }
        .buttonStyle(.plain)
    }
}

struct PlaceInventoryDashboard: View {
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    @State private var expandedPlaceIDs: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            if store.places.isEmpty {
                Text("还没有地点")
                    .font(.subheadline)
                    .foregroundStyle(GowithColor.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            } else {
                ForEach(Array(store.places.sorted { $0.createdAt < $1.createdAt }.enumerated()), id: \.element.id) { index, place in
                    placeSection(place)
                    if index < store.places.count - 1 {
                        Divider().padding(.leading, 58)
                    }
                }
            }
        }
        .background(GowithColor.surface)
    }

    private func placeSection(_ place: GowithPlace) -> some View {
        let itemCount = store.visibleItems.filter { $0.placeID == place.id }.count
        let backpackCount = store.visibleBackpacks.filter { $0.placeID == place.id }.count
        let isCurrent = store.selectedPlaceID == place.id
        let isNearby = locationService.isInside(place)

        return DisclosureGroup(
            isExpanded: Binding(
                get: { expandedPlaceIDs.contains(place.id) },
                set: { expanded in
                    if expanded { expandedPlaceIDs.insert(place.id) }
                    else { expandedPlaceIDs.remove(place.id) }
                }
            )
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Divider()
                inventoryGroup(title: "背包库", icon: "backpack.fill") {
                    let backpacks = store.visibleBackpacks.filter { $0.placeID == place.id }
                    if backpacks.isEmpty {
                        Text("还没有背包")
                            .font(.caption)
                            .foregroundStyle(GowithColor.tertiary)
                    } else {
                        ForEach(backpacks) { backpack in
                            HStack(spacing: 8) {
                                Image(systemName: backpack.symbolName == "gowith3d.backpack" ? "backpack.fill" : backpack.symbolName)
                                    .frame(width: 22)
                                Text(backpack.name)
                                Spacer()
                                Text("\(backpack.itemIDs.count) 件")
                                    .font(.caption)
                                    .foregroundStyle(GowithColor.tertiary)
                            }
                            .font(.subheadline)
                        }
                    }
                }
                inventoryGroup(title: "物品库", icon: "archivebox.fill") {
                    let items = store.visibleItems.filter { $0.placeID == place.id }
                    if items.isEmpty {
                        Text("还没有物品")
                            .font(.caption)
                            .foregroundStyle(GowithColor.tertiary)
                    } else {
                        ForEach(items) { item in
                            HStack(spacing: 8) {
                                ItemThumbnail(fileName: item.imageFileName, symbolName: item.symbolName, size: 28)
                                Text(item.name)
                                Spacer()
                                if item.lostCount > 0 {
                                    Text("遗失 \(item.lostCount) 次")
                                        .font(.caption)
                                        .foregroundStyle(GowithColor.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.leading, 42)
            .padding(.bottom, 14)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isNearby ? GowithColor.primary : .white)
                    .frame(width: 36, height: 36)
                    .background(isNearby ? GowithColor.success : GowithColor.primary, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(place.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(GowithColor.primary)
                        if isCurrent {
                            Text("当前")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(GowithColor.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(GowithColor.success, in: Capsule())
                        }
                    }
                    Text("\(backpackCount) 个背包 · \(itemCount) 件物品")
                        .font(.caption)
                        .foregroundStyle(GowithColor.secondary)
                }
                Spacer(minLength: 8)
                Text(isNearby ? "在范围内" : "未到达")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isNearby ? GowithColor.primary : GowithColor.tertiary)
            }
            .frame(minHeight: 68)
            .contentShape(Rectangle())
        }
        .tint(GowithColor.secondary)
        .padding(.horizontal, 14)
    }

    private func inventoryGroup<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(GowithColor.secondary)
            content()
        }
    }
}

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GowithStore
    private var sessions: [OutingSession] { store.sessions.sorted { $0.startedAt > $1.startedAt } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if sessions.isEmpty {
                        Text("还没有历史记录").foregroundStyle(GowithColor.secondary).padding(.top, 80)
                    } else {
                        ForEach(sessions) { session in
                            HistoryRow(session: session)
                        }
                    }
                }
                .padding(20)
            }
            .background(GowithColor.appBackground)
            .navigationTitle("历史记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("完成") { dismiss() } } }
        }
    }
}

struct HistoryRow: View {
    let session: OutingSession
    @State private var showDetail = false

    private var lost: Int { session.items.filter { $0.status == .lost }.count }
    private var pending: Int { session.items.filter { $0.status == .pending }.count }

    var body: some View {
        Button { showDetail = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.startedAt, format: .dateTime.month().day().hour().minute())
                        .font(.body.weight(.semibold))
                        .foregroundStyle(GowithColor.primary)
                    Text(session.status == .completed ? "已完成 · \(session.items.count) 件物品" : "进行中")
                        .font(.caption).foregroundStyle(GowithColor.secondary)
                    if let backpackName = session.backpackNameSnapshot {
                        Text(backpackName).font(.caption.weight(.medium)).foregroundStyle(GowithColor.tertiary)
                    }
                }
                Spacer()
                if lost > 0 { Text("遗失 \(lost)").font(.caption.weight(.medium)) }
                else if pending > 0 { Text("待确认 \(pending)").font(.caption.weight(.medium)) }
                Image(systemName: "chevron.right").foregroundStyle(GowithColor.tertiary)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) { SessionDetailView(session: session) }
    }
}

struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GowithStore
    let session: OutingSession

    var body: some View {
        NavigationStack {
            List {
                ForEach(session.items) { item in
                    HStack {
                        ItemThumbnail(fileName: item.imageFileNameSnapshot, symbolName: item.symbolNameSnapshot, size: 42)
                        Text(item.nameSnapshot)
                        Spacer()
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
                }
            }
            .scrollContentBackground(.hidden)
            .background(GowithColor.appBackground)
            .navigationTitle("清点详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("完成") { dismiss() } } }
        }
    }

    private func resolve(_ item: SessionItem, as status: SessionItemStatus) {
        guard item.status == .pending else { return }
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
