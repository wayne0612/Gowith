import PhotosUI
import SwiftUI

// MARK: - 物品库页（规格 5.1）

struct LibraryPage: View {
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    let onPack: (GowithItem) -> Void

    @State private var selectedCategoryID: UUID?
    @State private var editingItem: GowithItem?
    @State private var showAddItem = false
    @State private var editingCategory: GowithCategory?
    @State private var showCategoryEditor = false
    @State private var highlightedItemID: UUID?

    /// 物品库展示全部未归档物品（含在其他地点的），行内按地点状态区分可操作性（规格 v8：充电线在「公司」也可见）。
    private var items: [GowithItem] { store.visibleItems }
    private var categories: [GowithCategory] { store.sortedCategories }
    private var packedCount: Int { store.packedItems(in: store.selectedBackpack).count }
    private var canManage: Bool {
        guard let place = store.selectedPlace else { return false }
        return locationService.isInside(place)
    }

    /// 只有「位于当前地点」或「已在背包」的物品可以在围栏内操作；出行会话进行中整库锁定（规格 5.2）。
    private func isManageable(_ item: GowithItem) -> Bool {
        guard canManage, store.activeSession == nil else { return false }
        return item.placeID == store.selectedPlaceID || store.selectedBackpack?.itemIDs.contains(item.id) == true
    }

    private var filteredItems: [GowithItem] {
        guard let selectedCategoryID else { return items }
        return items.filter { $0.categoryID == selectedCategoryID }
    }

    /// 全部 = 按分类分组；选中分类 = 单组。组名「货架 · X」。
    private var groups: [(id: String, title: String, items: [GowithItem])] {
        if let selectedCategoryID {
            let category = categories.first(where: { $0.id == selectedCategoryID })
            return [(id: selectedCategoryID.uuidString, title: category?.name ?? "未分类", items: filteredItems)]
        }
        var groups: [(id: String, title: String, items: [GowithItem])] = []
        for category in categories {
            let categoryItems = items.filter { $0.categoryID == category.id }
            if !categoryItems.isEmpty {
                groups.append((id: category.id.uuidString, title: category.name, items: categoryItems))
            }
        }
        let uncategorized = items.filter { item in
            item.categoryID == nil && !categories.contains(where: { $0.id == item.categoryID })
        }
        if !uncategorized.isEmpty {
            groups.append((id: "uncategorized", title: "未分类", items: uncategorized))
        }
        return groups
    }

    var body: some View {
        ScrollView {
            VStack(spacing: GowithMetrics.moduleSpacing) {
                AssetCard(
                    header: "物品库",
                    headerEN: "INVENTORY",
                    badge: "全部 \(categories.count) 类",
                    leftValue: "\(items.count)",
                    leftUnit: "件",
                    leftLabel: "物品库总数",
                    rightValue: "\(packedCount)",
                    rightUnit: "件",
                    rightLabel: "已装入背包",
                    ctaPlain: "点 ",
                    ctaAccent: "+ 装包",
                    texture: .flow
                )

                locationStatus

                CategoryChips(
                    chips: [CategoryChips.Chip(id: nil, name: "全部", systemImage: "square.grid.2x2")]
                        + categories.map { CategoryChips.Chip(id: $0.id, name: String($0.name.prefix(4)), systemImage: $0.symbolName) },
                    selection: $selectedCategoryID,
                    trailingNew: { editingCategory = nil; showCategoryEditor = true },
                    onEditChip: { id in
                        guard let category = categories.first(where: { $0.id == id }) else { return }
                        editingCategory = category
                        showCategoryEditor = true
                    }
                )

                if items.isEmpty {
                    emptyState
                } else if filteredItems.isEmpty {
                    ContentCard {
                        Text("这个分类还没有物品，点 + 添加。")
                            .font(.system(size: 11))
                            .foregroundStyle(GowithColor.inkTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 14)
                    }
                } else {
                    ForEach(groups, id: \.id) { group in
                        shelfCard(group.title, items: group.items)
                    }
                }

                addNewItemEntry
            }
            .padding(.horizontal, GowithMetrics.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(GowithColor.appBackground)
        .sheet(isPresented: $showAddItem) {
            ItemEditorView(initialCategoryID: selectedCategoryID) { savedItem, isNew in
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
        .sheet(isPresented: $showCategoryEditor) {
            CategoryEditorView(category: editingCategory)
        }
    }

    @ViewBuilder
    private var locationStatus: some View {
        if locationService.needsPermissionRecovery {
            GowithLocationRecoveryBanner()
        } else if store.activeSession != nil {
            NoteCard(
                title: "出行进行中",
                systemImage: "lock.fill",
                lines: ["本次清单已锁定，装包与编辑将在出行完成后恢复。"]
            )
        } else if let place = store.selectedPlace, !canManage {
            FenceGateNote(placeName: place.name)
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
                        isEditable: isManageable(item),
                        highlight: highlightedItemID == item.id,
                        onTogglePack: { onPack(item) },
                        onEdit: { editingItem = item }
                    )
                    .contextMenu {
                        Button("编辑物品", systemImage: "pencil") { editingItem = item }
                            .disabled(!isManageable(item))
                        if let category = categories.first(where: { $0.id == item.categoryID }) {
                            Button("编辑分类「\(category.name)」", systemImage: "folder") { editingCategory = category }
                        }
                    }
                    if index < items.count - 1 {
                        Divider().padding(.leading, 62)
                    }
                }
            }
        }
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
        .accessibilityHint("打开添加物品页")
    }

    private var emptyState: some View {
        ContentCard {
            VStack(spacing: 8) {
                Image(systemName: "archivebox")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(GowithColor.inkTertiary)
                Text("还没有物品")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(GowithColor.ink)
                Text("点下方「添加新物品」，把常用物品放进货架。")
                    .font(.system(size: 11))
                    .foregroundStyle(GowithColor.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
        }
    }
}

// MARK: - 共享图标选择卡（S1 物品 / S3 背包复用，规格 5.7）

struct IconPickerSection: View {
    @Binding var imageData: Data?
    @Binding var symbolName: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCamera = false
    @State private var iconQuery = ""
    @State private var iconCategory: GowithIconCategory?

    /// 背包编辑器默认落在「包袋箱包」分类
    init(imageData: Binding<Data?>, symbolName: Binding<String>, preferredCategory: GowithIconCategory? = nil) {
        _imageData = imageData
        _symbolName = symbolName
        _iconCategory = State(initialValue: preferredCategory)
    }

    private var libraryEntries: [GowithIconEntry] {
        GowithIconLibrary.search(iconQuery, category: iconCategory)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ItemThumbnail(data: imageData, fileName: nil, symbolName: symbolName, size: 52)
                    .background(GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 6) {
                    Text("照片")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(GowithColor.inkSecondary)
                    HStack(spacing: 8) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("从相册选择", systemImage: "photo")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(GowithColor.ink)
                                .padding(.horizontal, 10)
                                .frame(minHeight: 30)
                                .background(GowithColor.softSurface, in: Capsule())
                        }
                        Button {
                            showCamera = true
                        } label: {
                            Label("拍摄", systemImage: "camera")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(GowithColor.ink)
                                .padding(.horizontal, 10)
                                .frame(minHeight: 30)
                                .background(GowithColor.softSurface, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        if imageData != nil {
                            Button("移除照片") { imageData = nil }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(GowithColor.accent)
                        }
                    }
                }
                Spacer(minLength: 0)
            }

            Divider().padding(.vertical, 2)

            Text("图标库 · \(libraryEntries.count) 枚")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(GowithColor.inkSecondary)

            TextField("搜索：背包、钥匙、充电、雨伞…", text: $iconQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(.horizontal, 10)
                .frame(minHeight: 32)
                .background(GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    categoryChip(nil, "全部")
                    ForEach(GowithIconCategory.allCases) { cat in
                        categoryChip(cat, cat.rawValue)
                    }
                }
                .padding(.vertical, 2)
            }

            if libraryEntries.isEmpty {
                Text("没有匹配的图标，换个词试试")
                    .font(.system(size: 11))
                    .foregroundStyle(GowithColor.inkTertiary)
                    .frame(maxWidth: .infinity, minHeight: 44)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                    ForEach(libraryEntries) { entry in
                        Button {
                            symbolName = entry.id
                            imageData = nil
                        } label: {
                            VStack(spacing: 3) {
                                GowithLibraryIcon(entry: entry, size: 34)
                                Text(entry.name)
                                    .font(.system(size: 8.5, weight: .medium))
                                    .foregroundStyle(GowithColor.inkSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                symbolName == entry.id && imageData == nil
                                    ? RoundedRectangle(cornerRadius: 12, style: .continuous).fill(GowithColor.softSurface)
                                    : RoundedRectangle(cornerRadius: 12, style: .continuous).fill(GowithColor.softSurface.opacity(0.5))
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(symbolName == entry.id && imageData == nil ? GowithColor.ink : .clear, lineWidth: 1.5).allowsHitTesting(false)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("选择图标：\(entry.name)")
                    }
                }
            }

            Divider().padding(.vertical, 2)

            Text("系统图标")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(GowithColor.inkSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(symbolOptions, id: \.self) { symbol in
                        Button {
                            symbolName = symbol
                            imageData = nil
                        } label: {
                            Image(systemName: symbol)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(symbolName == symbol && imageData == nil ? GowithColor.onPrimary : GowithColor.ink)
                                .frame(width: 40, height: 40)
                                .background(symbolName == symbol && imageData == nil ? GowithColor.ink : GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .task(id: selectedPhoto) {
            guard let selectedPhoto, let data = try? await selectedPhoto.loadTransferable(type: Data.self) else { return }
            imageData = data
        }
        .sheet(isPresented: $showCamera) { CameraPicker(imageData: $imageData) }
    }

    private func categoryChip(_ category: GowithIconCategory?, _ title: String) -> some View {
        let isSelected = iconCategory == category
        return Button {
            withAnimation(GowithMotion.row) { iconCategory = category }
        } label: {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? GowithColor.onPrimary : GowithColor.inkSecondary)
                .padding(.horizontal, 11)
                .frame(minHeight: 26)
                .background(isSelected ? GowithColor.ink : GowithColor.softSurface, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private let symbolOptions = ["square.dashed", "iphone", "key.fill", "wallet.pass.fill", "airpods", "battery.100percent", "umbrella.fill", "book.fill", "pill.fill", "eyeglasses", "laptopcomputer", "creditcard.fill"]
}

// MARK: - S1 添加/编辑物品（规格 5.7，对应现有 ItemEditorView 重写）

struct ItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GowithStore
    let item: GowithItem?
    let initialCategoryID: UUID?
    var onSaved: ((GowithItem, Bool) -> Void)? = nil

    @State private var name: String
    @State private var symbolName: String
    @State private var imageData: Data?
    @State private var categoryID: UUID?
    @State private var editingCategory: GowithCategory?
    @State private var showNewCategory = false
    @State private var showArchiveConfirm = false
    @FocusState private var nameFocused: Bool

    init(item: GowithItem? = nil, initialCategoryID: UUID? = nil, onSaved: ((GowithItem, Bool) -> Void)? = nil) {
        self.item = item
        self.initialCategoryID = initialCategoryID
        self.onSaved = onSaved
        _name = State(initialValue: item?.name ?? "")
        _symbolName = State(initialValue: item?.symbolName ?? "square.dashed")
        _imageData = State(initialValue: LocalImageStore.load(fileName: item?.imageFileName))
        _categoryID = State(initialValue: item?.categoryID ?? initialCategoryID)
    }

    private var saveEnabled: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            SheetNavBar(
                title: item == nil ? "添加物品" : "编辑物品",
                saveEnabled: saveEnabled,
                onCancel: { dismiss() },
                onSave: { save() }
            )
            ScrollView {
                VStack(spacing: GowithMetrics.moduleSpacing) {
                    ContentCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("名称")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(GowithColor.inkSecondary)
                            TextField("例如：钥匙、工卡…", text: $name)
                                .font(.system(size: 15, weight: .medium))
                                .focused($nameFocused)
                                .submitLabel(.done)
                        }
                    }

                    ContentCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("分类")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(GowithColor.inkSecondary)
                            CategoryChips(
                                chips: [CategoryChips.Chip(id: nil, name: "未分类")]
                                    + store.sortedCategories.map { CategoryChips.Chip(id: $0.id, name: String($0.name.prefix(4))) },
                                selection: $categoryID,
                                trailingNew: { showNewCategory = true }
                            )
                        }
                    }

                    ContentCard {
                        IconPickerSection(imageData: $imageData, symbolName: $symbolName)
                    }

                    if item != nil {
                        Button {
                            showArchiveConfirm = true
                        } label: {
                            Text("归档物品")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GowithColor.accent)
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .background(GowithColor.appBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .onAppear {
            if item == nil { nameFocused = true }
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorView(category: category)
        }
        .sheet(isPresented: $showNewCategory) {
            CategoryEditorView()
        }
        .confirmationDialog("归档这件物品？", isPresented: $showArchiveConfirm, titleVisibility: .visible) {
            Button("归档", role: .destructive) {
                item?.isArchived = true
                store.save()
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("归档后物品不再出现在货架。")
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let newFileName = imageData.flatMap(LocalImageStore.save(data:))
        if let item {
            if let newFileName {
                LocalImageStore.delete(fileName: item.imageFileName)
                item.imageFileName = newFileName
            } else if imageData == nil {
                LocalImageStore.delete(fileName: item.imageFileName)
                item.imageFileName = nil
            }
            item.name = trimmedName
            item.symbolName = symbolName
            item.categoryID = categoryID
            onSaved?(item, false)
        } else {
            let newItem = GowithItem(name: trimmedName, symbolName: symbolName, imageFileName: newFileName, categoryID: categoryID, placeID: store.selectedPlaceID)
            store.items.append(newItem)
            onSaved?(newItem, true)
        }
        store.save()
        dismiss()
    }
}

// MARK: - S2 新建/编辑分类（规格 5.7，行内小弹层）

struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GowithStore
    let category: GowithCategory?
    var onSave: ((GowithCategory) -> Void)? = nil

    @State private var name: String
    @State private var symbolName: String

    init(category: GowithCategory? = nil, onSave: ((GowithCategory) -> Void)? = nil) {
        self.category = category
        self.onSave = onSave
        _name = State(initialValue: category?.name ?? "")
        _symbolName = State(initialValue: category?.symbolName ?? "square.grid.2x2.fill")
    }

    private var saveEnabled: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            SheetNavBar(
                title: category == nil ? "新建分类" : "编辑分类",
                saveEnabled: saveEnabled,
                onCancel: { dismiss() },
                onSave: { save() }
            )
            ScrollView {
                VStack(spacing: GowithMetrics.moduleSpacing) {
                    ContentCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("分类名称（最多 4 字）")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(GowithColor.inkSecondary)
                            TextField("例如：洗护", text: $name)
                                .font(.system(size: 15, weight: .medium))
                                .onChange(of: name) { _, value in
                                    if value.count > 4 { name = String(value.prefix(4)) }
                                }
                        }
                    }

                    ContentCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("分类图标")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(GowithColor.inkSecondary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                                ForEach(symbolOptions, id: \.self) { symbol in
                                    Button { symbolName = symbol } label: {
                                        Image(systemName: symbol)
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundStyle(symbolName == symbol ? GowithColor.onPrimary : GowithColor.ink)
                                            .frame(maxWidth: .infinity, minHeight: 44)
                                            .background(symbolName == symbol ? GowithColor.ink : GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    if category != nil {
                        HStack(spacing: 10) {
                            Button {
                                move(category!, by: -1)
                            } label: {
                                Label("上移", systemImage: "arrow.up")
                                    .font(.system(size: 11, weight: .semibold))
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                    .background(GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            Button {
                                move(category!, by: 1)
                            } label: {
                                Label("下移", systemImage: "arrow.down")
                                    .font(.system(size: 11, weight: .semibold))
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                    .background(GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            Button {
                                delete(category!)
                            } label: {
                                Label("删除", systemImage: "trash")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(GowithColor.accent)
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                    .background(GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        Text("删除分类后，其物品归为「未分类」。")
                            .font(.system(size: 10))
                            .foregroundStyle(GowithColor.inkTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .background(GowithColor.appBackground)
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.hidden)
    }

    private let symbolOptions = ["square.grid.2x2.fill", "sun.max.fill", "bolt.fill", "person.text.rectangle.fill", "briefcase.fill", "house.fill", "heart.fill", "book.fill"]

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        if let category {
            category.name = trimmedName
            category.symbolName = symbolName
        } else {
            let order = (store.categories.map(\.sortOrder).max() ?? -1) + 1
            let newCategory = GowithCategory(name: trimmedName, symbolName: symbolName, sortOrder: order)
            store.categories.append(newCategory)
            onSave?(newCategory)
        }
        store.save()
        dismiss()
    }

    private func move(_ category: GowithCategory, by offset: Int) {
        let sorted = store.categories.sorted { $0.sortOrder < $1.sortOrder }
        guard let index = sorted.firstIndex(where: { $0.id == category.id }) else { return }
        let target = index + offset
        guard sorted.indices.contains(target) else { return }
        let other = sorted[target]
        let previousOrder = category.sortOrder
        category.sortOrder = other.sortOrder
        other.sortOrder = previousOrder
        store.save()
    }

    private func delete(_ category: GowithCategory) {
        for item in store.items where item.categoryID == category.id { item.categoryID = nil }
        store.categories.removeAll { $0.id == category.id }
        store.save()
        dismiss()
    }
}

// MARK: - S3 背包选择（规格 5.7）

struct BackpackPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GowithStore
    @State private var showNewBackpack = false
    @State private var editingBackpack: GowithBackpack?
    @State private var backpackToDelete: GowithBackpack?
    @State private var showDeleteConfirm = false

    private var backpacks: [GowithBackpack] { store.visibleBackpacks }
    private var current: GowithBackpack? { store.selectedBackpack }

    var body: some View {
        VStack(spacing: 0) {
            SheetNavBar(
                title: "选择背包",
                saveTitle: "完成",
                saveEnabled: true,
                onCancel: { dismiss() },
                onSave: { dismiss() }
            )
            ScrollView {
                VStack(spacing: GowithMetrics.moduleSpacing) {
                    if let current {
                        ContentCard {
                            HStack(spacing: 12) {
                                GowithBackpackPreview(backpack: current, size: 52)
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(current.name)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(GowithColor.ink)
                                        Text("当前")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(GowithColor.onPrimary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(GowithColor.ink, in: Capsule())
                                    }
                                    Text("已装 \(current.itemIDs.count) 件 · 在「\(store.place(for: current.placeID)?.name ?? "未设置地点")」")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(GowithColor.inkTertiary)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }

                    sectionTitle("全部背包 · \(backpacks.count) 个")

                    ContentCard(padding: 8) {
                        VStack(spacing: 0) {
                            ForEach(Array(backpacks.enumerated()), id: \.element.id) { index, backpack in
                                backpackRow(backpack)
                                    .contextMenu {
                                        Button("编辑", systemImage: "pencil") { editingBackpack = backpack }
                                        Button("删除", systemImage: "trash", role: .destructive) {
                                            backpackToDelete = backpack
                                            showDeleteConfirm = true
                                        }
                                        .disabled(store.activeSession?.backpackID == backpack.id)
                                    }
                                if index < backpacks.count - 1 {
                                    Divider().padding(.leading, 58)
                                }
                            }
                        }
                    }

                    Button {
                        showNewBackpack = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("新建背包")
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

                    NoteCard(lines: ["点背包行切换；长按可改名 / 删除。", "出行中的背包不可删除。"])
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
        .sheet(isPresented: $showNewBackpack) { BackpackEditorView() }
        .sheet(item: $editingBackpack) { backpack in BackpackEditorView(backpack: backpack) }
        .confirmationDialog("删除这个背包？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("删除背包", role: .destructive) {
                if let backpackToDelete { delete(backpackToDelete) }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("只会删除背包及其装包清单，不会删除物品库中的物品。")
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(GowithColor.inkSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

    private func backpackRow(_ backpack: GowithBackpack) -> some View {
        let isSelected = backpack.id == current?.id
        return Button {
            store.selectBackpack(backpack)
            GowithHaptics.selection()
        } label: {
            HStack(spacing: 12) {
                GowithBackpackPreview(backpack: backpack, size: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text(backpack.name)
                        .font(GowithFont.rowTitle)
                        .foregroundStyle(GowithColor.ink)
                    Text("\(backpack.itemIDs.count) 件 · 在「\(store.place(for: backpack.placeID)?.name ?? "未设置地点")」")
                        .font(GowithFont.rowSubtitle)
                        .foregroundStyle(GowithColor.inkTertiary)
                }
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(GowithColor.ink)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 6)
            .frame(minHeight: GowithMetrics.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("选择背包：\(backpack.name)")
    }

    private func delete(_ backpack: GowithBackpack) {
        // 进行中的出行会话引用该背包时禁止删除，避免会话数据悬空。
        guard store.activeSession?.backpackID != backpack.id else { return }
        LocalImageStore.delete(fileName: backpack.imageFileName)
        store.backpacks.removeAll { $0.id == backpack.id }
        if store.selectedBackpackID == backpack.id { store.selectedBackpackID = store.visibleBackpacks.first?.id }
        store.save()
    }
}

// MARK: - 新建/编辑背包（S3 底部入口，复用 S1 图标卡）

struct BackpackEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GowithStore
    let backpack: GowithBackpack?

    @State private var name: String
    @State private var symbolName: String
    @State private var imageData: Data?

    init(backpack: GowithBackpack? = nil) {
        self.backpack = backpack
        _name = State(initialValue: backpack?.name ?? "")
        _symbolName = State(initialValue: backpack?.symbolName ?? "bag.backpack.classic")
        _imageData = State(initialValue: LocalImageStore.load(fileName: backpack?.imageFileName))
    }

    private var saveEnabled: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            SheetNavBar(
                title: backpack == nil ? "新建背包" : "编辑背包",
                saveEnabled: saveEnabled,
                onCancel: { dismiss() },
                onSave: { save() }
            )
            ScrollView {
                VStack(spacing: GowithMetrics.moduleSpacing) {
                    ContentCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("背包名称")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(GowithColor.inkSecondary)
                            TextField("例如：通勤包", text: $name)
                                .font(.system(size: 15, weight: .medium))
                        }
                    }
                    ContentCard {
                        IconPickerSection(imageData: $imageData, symbolName: $symbolName, preferredCategory: .bags)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .background(GowithColor.appBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let newFileName = imageData.flatMap(LocalImageStore.save(data:))
        if let backpack {
            backpack.name = trimmedName
            backpack.symbolName = symbolName
            if let newFileName {
                LocalImageStore.delete(fileName: backpack.imageFileName)
                backpack.imageFileName = newFileName
            } else if imageData == nil {
                LocalImageStore.delete(fileName: backpack.imageFileName)
                backpack.imageFileName = nil
            }
        } else {
            let newBackpack = GowithBackpack(name: trimmedName, symbolName: symbolName, imageFileName: newFileName, placeID: store.selectedPlaceID)
            store.backpacks.append(newBackpack)
            if store.selectedBackpackID == nil || store.selectedPlaceID == newBackpack.placeID { store.selectedBackpackID = newBackpack.id }
        }
        store.save()
        dismiss()
    }
}

// MARK: - 相机拍摄（保留）

struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var imageData: Data?

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.imageData = image.jpegData(compressionQuality: 0.82) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
