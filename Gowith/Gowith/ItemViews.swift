import PhotosUI
import SwiftUI

// MARK: - 物品页 · 家（用户方向 3：以「家」为中心的渐进展开信息架构）

struct LibraryPage: View {
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    let onPack: (GowithItem) -> Void

    @State private var editingItem: GowithItem?
    @State private var showAddItem = false
    @State private var editingCategory: GowithCategory?
    @State private var showCategoryEditor = false
    @State private var showAddPlace = false
    @State private var showBackpackPicker = false
    @State private var detailHome: GowithPlace?
    @State private var detailBackpack: GowithBackpack?
    @State private var highlightedItemID: UUID?

    private var places: [GowithPlace] { store.places.sorted { $0.createdAt < $1.createdAt } }
    private var packedItems: [GowithItem] { store.packedItems(in: store.selectedBackpack) }
    private var homeItemCount: Int { store.shelfItems.count }

    var body: some View {
        ScrollView {
            VStack(spacing: GowithMetrics.moduleSpacing) {
                AssetCard(
                    header: store.selectedPlace?.name ?? "我的家",
                    headerEN: "HOME",
                    badge: "共 \(places.count) 个家",
                    leftValue: "\(homeItemCount)",
                    leftUnit: "件",
                    leftLabel: "当前家物品",
                    rightValue: "\(packedItems.count)",
                    rightUnit: "件",
                    rightLabel: store.activeSession == nil ? "已装入背包" : "携带中",
                    ctaPlain: "点 ",
                    ctaAccent: "+ 添加物品 · 装包",
                    texture: .home
                )

                locationStatus

                homeSwitcher

                currentBackpackCard

                homesSection

                addNewItemEntry
            }
            .padding(.horizontal, GowithMetrics.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(GowithColor.appBackground)
        .sheet(isPresented: $showAddItem) {
            ItemEditorView { savedItem, isNew in
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
        .sheet(isPresented: $showAddPlace) { PlaceEditorView(place: nil) }
        .sheet(isPresented: $showBackpackPicker) { BackpackPickerSheet() }
        .sheet(item: $detailHome) { place in
            HomeDetailSheet(place: place)
        }
        .sheet(item: $detailBackpack) { backpack in
            BackpackDetailSheet(backpack: backpack)
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
        } else if let place = store.selectedPlace, !locationService.isInside(place) {
            FenceGateNote(placeName: place.name)
        }
    }

    // MARK: (a) 家切换条：直观看到并切换当前所在的家

    private var homeSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(places) { place in
                    let isSelected = place.id == store.selectedPlaceID
                    Button {
                        store.selectPlace(place)
                        GowithHaptics.selection()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: isSelected ? "house.fill" : "house")
                                .font(.system(size: 10, weight: .semibold))
                            Text(place.name)
                        }
                        .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? GowithColor.onPrimary : GowithColor.inkSecondary)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 30)
                        .background(isSelected ? GowithColor.ink : GowithColor.surface, in: Capsule())
                        .overlay { Capsule().stroke(isSelected ? .clear : GowithColor.surfaceBorder, lineWidth: 1).allowsHitTesting(false) }
                    }
                    .buttonStyle(.plain)
                    .disabled(store.activeSession != nil)
                    .accessibilityLabel(isSelected ? "当前家：\(place.name)" : "切换到家：\(place.name)")
                }
                Button {
                    showAddPlace = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(GowithColor.inkSecondary)
                        .frame(width: 30, height: 30)
                        .background(GowithColor.surface, in: Capsule())
                        .overlay { Capsule().stroke(GowithColor.surfaceBorder, lineWidth: 1).allowsHitTesting(false) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("添加新家")
            }
            .padding(.horizontal, 1)
            .padding(.vertical, 1)
            .opacity(store.activeSession == nil ? 1 : 0.4)
            .animation(GowithMotion.content, value: store.activeSession == nil)
        }
    }

    // MARK: (b) 当前背包卡：正在使用的背包与内容透视

    private var currentBackpackCard: some View {
        ContentCard(padding: 12) {
            if let backpack = store.selectedBackpack {
                Button {
                    detailBackpack = backpack
                } label: {
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            GowithBackpackPreview(backpack: backpack, size: 46)
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(backpack.name)
                                        .font(GowithFont.rowTitle)
                                        .foregroundStyle(GowithColor.ink)
                                    Text("正在使用")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(GowithColor.onPrimary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(GowithColor.ink, in: Capsule())
                                }
                                Text(originText(for: backpack))
                                    .font(GowithFont.rowSubtitle)
                                    .foregroundStyle(GowithColor.inkTertiary)
                            }
                            Spacer(minLength: 8)
                            Button {
                                showBackpackPicker = true
                            } label: {
                                Text("换背包")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(GowithColor.ink)
                                    .padding(.horizontal, 11)
                                    .frame(minHeight: 30)
                                    .background(GowithColor.softSurface, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(store.activeSession != nil)
                            .accessibilityLabel("更换背包")
                        }

                        if !packedItems.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(Array(packedItems.prefix(6)), id: \.id) { item in
                                        HStack(spacing: 5) {
                                            ItemThumbnail(fileName: item.imageFileName, symbolName: item.symbolName, size: 20)
                                            Text(item.name)
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundStyle(GowithColor.inkSecondary)
                                                .lineLimit(1)
                                        }
                                        .padding(.leading, 4)
                                        .padding(.trailing, 9)
                                        .frame(minHeight: 28)
                                        .background(GowithColor.softSurface, in: Capsule())
                                    }
                                    if packedItems.count > 6 {
                                        Text("+\(packedItems.count - 6)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(GowithColor.inkTertiary)
                                            .padding(.horizontal, 6)
                                    }
                                }
                                .padding(.vertical, 1)
                            }
                        }

                        HStack {
                            Text("查看背包内容")
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundStyle(GowithColor.accent)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(GowithColor.accent)
                            Spacer()
                            Text("点卡片看每件的归属与属性")
                                .font(.system(size: 9.5))
                                .foregroundStyle(GowithColor.inkTertiary)
                        }
                    }
                    .padding(2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("当前背包：\(backpack.name)，已装 \(packedItems.count) 件，\(originText(for: backpack))。双击查看背包内容")
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "backpack")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(GowithColor.inkTertiary)
                    Text("还没有正在使用的背包")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(GowithColor.ink)
                    Button {
                        showBackpackPicker = true
                    } label: {
                        Text("选择或新建背包")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(GowithColor.onPrimary)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 32)
                            .background(GowithColor.ink, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
        }
    }

    private func originText(for backpack: GowithBackpack) -> String {
        if store.activeSession?.backpackID == backpack.id { return "随身携带中" }
        guard let place = store.place(for: backpack.placeID) else { return "未设置地点" }
        return "从「\(place.name)」拿出"
    }

    // MARK: (c) 全部家：只有计数，点开才看到里面的背包与物品

    private var homesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("全部家 · \(places.count) 个")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(GowithColor.inkSecondary)
                .padding(.horizontal, 6)
            ContentCard(padding: 8) {
                VStack(spacing: 0) {
                    ForEach(Array(places.enumerated()), id: \.element.id) { index, place in
                        homeRow(place)
                        if index < places.count - 1 {
                            Divider().padding(.leading, 58)
                        }
                    }
                }
            }
        }
    }

    private func homeRow(_ place: GowithPlace) -> some View {
        let itemCount = store.visibleItems.filter { $0.placeID == place.id }.count
        let backpackCount = store.visibleBackpacks.filter { $0.placeID == place.id }.count
        let isCurrent = place.id == store.selectedPlaceID
        return Button {
            detailHome = place
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isCurrent ? GowithColor.onPrimary : GowithColor.ink)
                    .frame(width: 34, height: 34)
                    .background(isCurrent ? GowithColor.ink : GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(place.name)
                            .font(GowithFont.rowTitle)
                            .foregroundStyle(GowithColor.ink)
                            .lineLimit(1)
                        if isCurrent {
                            Text("当前")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(GowithColor.onPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(GowithColor.ink, in: Capsule())
                        }
                    }
                    Text("物品 \(itemCount) · 背包 \(backpackCount)")
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
            .frame(minHeight: GowithMetrics.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(isCurrent ? "当前家" : "家")：\(place.name)，物品 \(itemCount) 件，背包 \(backpackCount) 个。双击查看家内物品")
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
            imageData = LocalImageStore.normalizedJPEGData(from: data)
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
    /// 从某个家的详情页进入时预置新建物品的归属家；缺省为当前家。
    let initialPlaceID: UUID?
    var onSaved: ((GowithItem, Bool) -> Void)? = nil

    @State private var name: String
    @State private var symbolName: String
    @State private var imageData: Data?
    @State private var categoryID: UUID?
    @State private var editingCategory: GowithCategory?
    @State private var showNewCategory = false
    @State private var showArchiveConfirm = false
    @FocusState private var nameFocused: Bool

    init(item: GowithItem? = nil, initialCategoryID: UUID? = nil, initialPlaceID: UUID? = nil, onSaved: ((GowithItem, Bool) -> Void)? = nil) {
        self.item = item
        self.initialCategoryID = initialCategoryID
        self.initialPlaceID = initialPlaceID
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
            let newItem = GowithItem(name: trimmedName, symbolName: symbolName, imageFileName: newFileName, categoryID: categoryID, placeID: initialPlaceID ?? store.selectedPlaceID)
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
    /// 从某个家的详情页进入时预置新建背包的归属家；缺省为当前家。
    let initialPlaceID: UUID?

    @State private var name: String
    @State private var symbolName: String
    @State private var imageData: Data?

    init(backpack: GowithBackpack? = nil, initialPlaceID: UUID? = nil) {
        self.backpack = backpack
        self.initialPlaceID = initialPlaceID
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
            let newBackpack = GowithBackpack(name: trimmedName, symbolName: symbolName, imageFileName: newFileName, placeID: initialPlaceID ?? store.selectedPlaceID)
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
            if let image = info[.originalImage] as? UIImage,
               let raw = image.jpegData(compressionQuality: 0.82) {
                parent.imageData = LocalImageStore.normalizedJPEGData(from: raw)
            }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
