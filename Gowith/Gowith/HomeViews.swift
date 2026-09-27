import SwiftUI

// MARK: - 家详情（用户方向 3c：点开某个家，才看到这个家的背包与物品）

struct HomeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    let place: GowithPlace

    @State private var editingItem: GowithItem?
    @State private var showAddItem = false
    @State private var showNewBackpack = false
    @State private var editingBackpack: GowithBackpack?
    @State private var detailBackpack: GowithBackpack?
    @State private var editingCategory: GowithCategory?
    @State private var showCategoryEditor = false
    @State private var highlightedItemID: UUID?

    private var isCurrent: Bool { store.selectedPlaceID == place.id }
    private var items: [GowithItem] { store.visibleItems.filter { $0.placeID == place.id } }
    private var backpacks: [GowithBackpack] { store.visibleBackpacks.filter { $0.placeID == place.id } }
    /// 该家的物品可操作 = 当前家 + 围栏内 + 无进行中出行（沿用规格 5.2 锁定语义）。
    private var canManage: Bool {
        isCurrent && locationService.isInside(place) && store.activeSession == nil
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetNavBar(
                title: place.name,
                saveTitle: "完成",
                saveEnabled: true,
                onCancel: { dismiss() },
                onSave: { dismiss() }
            )
            ScrollView {
                VStack(spacing: GowithMetrics.moduleSpacing) {
                    summaryCard
                    if isCurrent && store.activeSession == nil && !locationService.isInside(place) {
                        FenceGateNote(placeName: place.name)
                    }
                    backpacksCard
                    itemsSection
                    addNewItemEntry
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
        .sheet(item: $detailBackpack) { backpack in
            BackpackDetailSheet(backpack: backpack)
        }
        .sheet(isPresented: $showAddItem) {
            ItemEditorView(initialPlaceID: place.id) { savedItem, isNew in
                guard isNew else { return }
                highlightedItemID = savedItem.id
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 700_000_000)
                    highlightedItemID = nil
                }
            }
        }
        .sheet(item: $editingItem) { item in
            ItemEditorView(item: item)
        }
        .sheet(isPresented: $showNewBackpack) { BackpackEditorView(initialPlaceID: place.id) }
        .sheet(item: $editingBackpack) { backpack in BackpackEditorView(backpack: backpack) }
        .sheet(isPresented: $showCategoryEditor) {
            CategoryEditorView(category: editingCategory)
        }
    }

    private var summaryCard: some View {
        ContentCard {
            HStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(GowithColor.onPrimary)
                    .frame(width: 44, height: 44)
                    .background(GowithColor.ink, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(place.name)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(GowithColor.ink)
                            .lineLimit(1)
                        if isCurrent {
                            Text("当前所在")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(GowithColor.onPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(GowithColor.ink, in: Capsule())
                        }
                    }
                    Text("物品 \(items.count) 件 · 背包 \(backpacks.count) 个")
                        .font(GowithFont.rowSubtitle)
                        .foregroundStyle(GowithColor.inkSecondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var backpacksCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("这个家的背包 · \(backpacks.count) 个")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(GowithColor.inkSecondary)
                .padding(.horizontal, 6)
            ContentCard(padding: 8) {
                VStack(spacing: 0) {
                    if backpacks.isEmpty {
                        Text("这个家还没有背包。")
                            .font(.system(size: 11))
                            .foregroundStyle(GowithColor.inkTertiary)
                            .frame(maxWidth: .infinity, minHeight: 40)
                    } else {
                        ForEach(Array(backpacks.enumerated()), id: \.element.id) { index, backpack in
                            backpackRow(backpack)
                            if index < backpacks.count - 1 {
                                Divider().padding(.leading, 58)
                            }
                        }
                    }
                    Button {
                        showNewBackpack = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("新建背包")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(GowithColor.inkSecondary)
                        .frame(maxWidth: .infinity, minHeight: 40)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func backpackRow(_ backpack: GowithBackpack) -> some View {
        let inUse = store.selectedBackpackID == backpack.id
        return Button {
            detailBackpack = backpack
        } label: {
            HStack(spacing: 12) {
                GowithBackpackPreview(backpack: backpack, size: 36)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(backpack.name)
                            .font(GowithFont.rowTitle)
                            .foregroundStyle(GowithColor.ink)
                            .lineLimit(1)
                        if inUse {
                            Text("正在使用")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(GowithColor.onPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(GowithColor.ink, in: Capsule())
                        }
                    }
                    Text("已装 \(backpack.itemIDs.count) 件")
                        .font(GowithFont.rowSubtitle)
                        .foregroundStyle(GowithColor.inkTertiary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(GowithColor.inkTertiary)
                    .frame(width: 30, height: 44)
            }
            .padding(.horizontal, 6)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("编辑背包", systemImage: "pencil") { editingBackpack = backpack }
                .disabled(store.activeSession != nil)
        }
        .accessibilityLabel("背包：\(backpack.name)，已装 \(backpack.itemIDs.count) 件。双击查看背包内容")
    }

    @ViewBuilder
    private var itemsSection: some View {
        if items.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("这个家的物品 · 0 件")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(GowithColor.inkSecondary)
                    .padding(.horizontal, 6)
                ContentCard {
                    VStack(spacing: 8) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 26, weight: .light))
                            .foregroundStyle(GowithColor.inkTertiary)
                        Text("货架还是空的")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(GowithColor.ink)
                        Text("点下方「添加新物品」，把常用物品放进这个家。")
                            .font(.system(size: 11))
                            .foregroundStyle(GowithColor.inkSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
        } else {
            ForEach(ShelfGrouping.groups(for: items, categories: store.sortedCategories), id: \.id) { group in
                shelfCard(group.title, items: group.items)
            }
        }
    }

    private func shelfCard(_ title: String, items: [GowithItem]) -> some View {
        ContentCard(padding: 10) {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("货架 · \(title)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(GowithColor.inkSecondary)
                    Spacer()
                    Text("\(items.count) 件")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(GowithColor.inkTertiary)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)

                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let packed = store.selectedBackpack?.itemIDs.contains(item.id) == true
                    ShelfRow(
                        item: item,
                        placeName: packed ? nil : store.place(for: item.placeID)?.name,
                        isPacked: packed,
                        isEditable: canManage,
                        highlight: highlightedItemID == item.id,
                        onTogglePack: { togglePack(item) },
                        onEdit: { editingItem = item }
                    )
                    .contextMenu {
                        // 规格 5.2：出行中 / 围栏外清单锁定，编辑入口同步禁用
                        Button("编辑物品", systemImage: "pencil") { editingItem = item }
                            .disabled(!canManage)
                        if let category = store.sortedCategories.first(where: { $0.id == item.categoryID }) {
                            Button("编辑分类「\(category.name)」", systemImage: "folder") {
                                editingCategory = category
                                showCategoryEditor = true
                            }
                        }
                    }
                    if index < items.count - 1 {
                        Divider().padding(.leading, 62)
                    }
                }
            }
        }
    }

    /// 家详情里的装包动作：在 sheet 内直接切换，不触发热球飞行动画（锚点坐标系在主界面）。
    private func togglePack(_ item: GowithItem) {
        guard canManage, let backpack = store.selectedBackpack else { return }
        store.toggleItem(item, in: backpack)
        GowithHaptics.selection()
    }

    private var addNewItemEntry: some View {
        Button {
            showAddItem = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                Text("添加新物品…")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(GowithColor.inkSecondary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: GowithMetrics.contentCardRadius, style: .continuous)
                    .strokeBorder(GowithColor.inkTertiary.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("添加物品到「\(place.name)」")
    }
}

// MARK: - 背包详情（用户方向 3d：包里有什么、归属哪个家、从哪拿出、什么属性）

struct BackpackDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GowithStore
    let backpack: GowithBackpack

    @State private var editingItem: GowithItem?

    private var items: [GowithItem] { store.packedItems(in: backpack) }
    private var isCurrent: Bool { store.selectedBackpackID == backpack.id }
    private var originText: String {
        if store.activeSession?.backpackID == backpack.id { return "随身携带中" }
        guard let place = store.place(for: backpack.placeID) else { return "未设置地点" }
        return "从「\(place.name)」拿出"
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetNavBar(
                title: "背包详情",
                saveTitle: "完成",
                saveEnabled: true,
                onCancel: { dismiss() },
                onSave: { dismiss() }
            )
            ScrollView {
                VStack(spacing: GowithMetrics.moduleSpacing) {
                    headerCard

                    VStack(alignment: .leading, spacing: 6) {
                        Text("包内物品 · \(items.count) 件")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(GowithColor.inkSecondary)
                            .padding(.horizontal, 6)
                        if items.isEmpty {
                            ContentCard {
                                Text("背包是空的。从「家」页的货架点 + 装入物品。")
                                    .font(.system(size: 11))
                                    .foregroundStyle(GowithColor.inkTertiary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 18)
                            }
                        } else {
                            ContentCard(padding: 10) {
                                VStack(spacing: 0) {
                                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                        itemRow(item)
                                        if index < items.count - 1 {
                                            Divider().padding(.leading, 62)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    NoteCard(
                        title: "怎么读这页",
                        systemImage: "info.circle",
                        lines: [
                            "「归属」= 物品当前所在的家；「随身」表示正跟着背包出行。",
                            "点击物品行可编辑名称、图标与分类。",
                        ]
                    )
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
        .sheet(item: $editingItem) { item in
            ItemEditorView(item: item)
        }
    }

    private var headerCard: some View {
        ContentCard {
            HStack(spacing: 12) {
                GowithBackpackPreview(backpack: backpack, size: 52)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(backpack.name)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(GowithColor.ink)
                            .lineLimit(1)
                        if isCurrent {
                            Text("正在使用")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(GowithColor.onPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(GowithColor.ink, in: Capsule())
                        }
                    }
                    Text("已装 \(items.count) 件 · \(originText)")
                        .font(GowithFont.rowSubtitle)
                        .foregroundStyle(GowithColor.inkSecondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func itemRow(_ item: GowithItem) -> some View {
        Button {
            editingItem = item
        } label: {
            HStack(spacing: 12) {
                ItemThumbnail(fileName: item.imageFileName, symbolName: item.symbolName, size: GowithMetrics.rowIconSize, isSymbolLight: true)
                    .background(GowithColor.ink, in: RoundedRectangle(cornerRadius: GowithMetrics.rowIconRadius, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(GowithFont.rowTitle)
                        .foregroundStyle(GowithColor.ink)
                        .lineLimit(1)
                    Text(attributeText(for: item))
                        .font(GowithFont.rowSubtitle)
                        .foregroundStyle(GowithColor.inkTertiary)
                        .lineLimit(1)
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
        }
        .buttonStyle(.plain)
        .accessibilityLabel("包内物品：\(item.name)，\(attributeText(for: item))。双击编辑")
    }

    /// (d) 属性行：分类 · 归属家 · 持有天数（有遗失记录时追加）。
    private func attributeText(for item: GowithItem) -> String {
        let category = item.categoryID.flatMap { id in store.sortedCategories.first(where: { $0.id == id }) }
        let categoryText = category?.name ?? "未分类"
        let homeText = item.placeID == nil ? "随身" : "归属「\(store.place(for: item.placeID)?.name ?? "未知地点")」"
        let days = max(0, Calendar.current.dateComponents([.day], from: item.createdAt, to: .now).day ?? 0)
        var parts = [categoryText, homeText, "收录 \(days) 天"]
        if item.lostCount > 0 { parts.append("遗失 \(item.lostCount) 次") }
        return parts.joined(separator: " · ")
    }
}

// MARK: - 货架分组（家详情复用）

enum ShelfGrouping {
    /// 按分类分组；分类名最多 4 字的既定规则不变。
    static func groups(for items: [GowithItem], categories: [GowithCategory]) -> [(id: String, title: String, items: [GowithItem])] {
        var groups: [(id: String, title: String, items: [GowithItem])] = []
        for category in categories {
            let categoryItems = items.filter { $0.categoryID == category.id }
            if !categoryItems.isEmpty {
                groups.append((id: category.id.uuidString, title: category.name, items: categoryItems))
            }
        }
        let uncategorized = items.filter { item in
            !categories.contains(where: { $0.id == item.categoryID })
        }
        if !uncategorized.isEmpty {
            groups.append((id: "uncategorized", title: "未分类", items: uncategorized))
        }
        return groups
    }
}
