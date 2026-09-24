import PhotosUI
import SwiftUI

struct ItemLibraryView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    let onOpenBackpack: () -> Void
    let onStartOuting: () -> Void
    let onPickup: () -> Void
    @State private var selectedCategoryID: UUID?
    @State private var editingItem: GowithItem?
    @State private var showCategoryEditor = false
    @State private var showItemEditor = false
    @State private var editingCategory: GowithCategory?

    private var items: [GowithItem] {
        let bagIDs = Set(selectedBackpack?.itemIDs ?? [])
        return store.visibleItems.filter { $0.placeID == store.selectedPlaceID || ($0.placeID == nil && bagIDs.contains($0.id)) }
    }
    private var categories: [GowithCategory] { store.categories.sorted { $0.sortOrder == $1.sortOrder ? $0.createdAt < $1.createdAt : $0.sortOrder < $1.sortOrder } }
    private var selectedBackpack: GowithBackpack? { store.selectedBackpack }
    private var selectedPlace: GowithPlace? { store.selectedPlace }
    private var canManageSelectedPlace: Bool {
        guard let selectedPlace else { return false }
        return locationService.isInside(selectedPlace)
    }
    private var filteredItems: [GowithItem] {
        guard let selectedCategoryID else { return items }
        return items.filter { $0.categoryID == selectedCategoryID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    GowithTopBar(pageTitle: "物品库") {
                        Menu {
                            Button("添加物品", systemImage: "plus") { showItemEditor = true }
                                .disabled(!canManageSelectedPlace)
                            Button("添加分类", systemImage: "folder.badge.plus") { showCategoryEditor = true }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(GowithColor.primary)
                                .frame(width: 44, height: 44)
                                .background(GowithColor.surface, in: Circle())
                        }
                        .accessibilityLabel("物品库操作")
                    }
                    GowithContextStrip()
                    libraryFocus
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(items.count) 件物品")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(GowithColor.secondary)
                        Spacer()
                        Text(selectedBackpack.map { "装入：\($0.name)" } ?? "请先选择背包")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(GowithColor.tertiary)
                            .lineLimit(1)
                    }
                    locationGate
                    if selectedBackpack == nil {
                        noBackpackState
                    } else {
                        categoryBar
                        itemList
                    }
                }
                .padding(.horizontal, GowithMetrics.pagePadding)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(GowithColor.appBackground)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if selectedBackpack != nil {
                    GowithBottomAction(title: "开始出行", systemImage: "figure.walk", action: onStartOuting)
                        .disabled(!canManageSelectedPlace)
                        .opacity(canManageSelectedPlace ? 1 : 0.45)
                        .padding(.horizontal, GowithMetrics.pagePadding)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .background(GowithColor.appBackground)
                }
            }
            .sheet(isPresented: $showCategoryEditor) {
                CategoryEditorView(onSave: { selectedCategoryID = $0.id })
            }
            .sheet(item: $editingCategory) { category in CategoryEditorView(category: category) }
            .sheet(isPresented: $showItemEditor) {
                ItemEditorView(initialCategoryID: selectedCategoryID, allowsUncategorized: selectedCategoryID == nil)
            }
            .sheet(item: $editingItem) { item in
                ItemEditorView(item: item)
            }
            .onChange(of: categories.count) { _, _ in
                if let selectedCategoryID, !categories.contains(where: { $0.id == selectedCategoryID }) {
                    self.selectedCategoryID = categories.first?.id
                }
            }
        }
    }

    private var categoryBar: some View {
        GowithCategoryRail(
            categories: [(id: nil, name: "全部", icon: "square.grid.2x2.fill")] + categories.map {
                (id: Optional($0.id), name: String($0.name.prefix(4)), icon: $0.symbolName)
            },
            selectedID: $selectedCategoryID
        )
        .contextMenu {
            ForEach(categories) { category in
                Button("编辑\(category.name)", systemImage: "pencil") { editingCategory = category }
            }
        }
    }

    private var libraryFocus: some View {
        GowithFocusField(color: GowithColor.sceneMint, height: 170) {
            HStack(spacing: 4) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("为这个背包准备")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GowithColor.primary.opacity(0.62))
                    Text(selectedBackpack?.name ?? "选择一个背包")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(GowithColor.primary)
                        .lineLimit(2)
                    Text("已选 \(selectedBackpack?.itemIDs.count ?? 0) 件 · 物品库 \(items.count) 件")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(GowithColor.primary.opacity(0.72))
                }
                Spacer(minLength: 0)
                if let selectedBackpack {
                    GowithBackpackPreview(backpack: selectedBackpack, size: 118)
                        .background(.white.opacity(0.22), in: Circle())
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: "backpack.fill")
                        .font(.system(size: 66, weight: .regular))
                        .foregroundStyle(GowithColor.primary.opacity(0.76))
                }
            }
            .padding(20)
        }
    }

    private var itemList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(selectedCategoryName)
                    .font(.headline)
                    .foregroundStyle(GowithColor.primary)
                Spacer()
                Text("\(filteredItems.count) 件")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(GowithColor.tertiary)
            }

            if items.isEmpty {
                VStack(spacing: 10) {
                    VStack(spacing: 10) {
                        Image(systemName: "archivebox").font(.system(size: 25, weight: .light))
                        Text("还没有物品").font(.headline)
                            Button("添加物品") { showItemEditor = true }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(GowithColor.primary)
                                .disabled(!canManageSelectedPlace)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
            } else if filteredItems.isEmpty {
                VStack(spacing: 10) {
                    VStack(spacing: 10) {
                        Image(systemName: "archivebox").font(.system(size: 25, weight: .light))
                        Text("这个分类还没有物品").font(.headline)
                        Button("添加物品") { showItemEditor = true }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(GowithColor.primary)
                            .disabled(!canManageSelectedPlace)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
            } else {
                ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                    let isPacked = selectedBackpack?.itemIDs.contains(item.id) == true
                    LibraryItemRow(item: item, isPacked: isPacked) {
                        guard let selectedBackpack else { return }
                        guard canManageSelectedPlace else { return }
                        store.toggleItem(item, in: selectedBackpack)
                    }
                    .opacity(canManageSelectedPlace ? 1 : 0.62)
                    .contextMenu {
                        if let category = categories.first(where: { $0.id == item.categoryID }) {
                            Button("编辑分类", systemImage: "folder") { editingCategory = category }
                        }
                        Button("编辑", systemImage: "pencil") { editingItem = item }
                            .disabled(!canManageSelectedPlace)
                        Button("归档", systemImage: "archivebox", role: .destructive) {
                            item.isArchived = true
                            store.save()
                        }
                        .disabled(!canManageSelectedPlace)
                    }
                    if index < filteredItems.count - 1 { Divider().padding(.leading, 66) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var selectedCategoryName: String {
        guard let selectedCategoryID else { return "全部物品" }
        return categories.first(where: { $0.id == selectedCategoryID })?.name ?? "全部物品"
    }

    private var noBackpackState: some View {
        GowithCard {
            VStack(spacing: 12) {
                Image(systemName: "backpack").font(.system(size: 32, weight: .light))
                Text("请先选择背包").font(.headline)
                Text("选择一个背包后，才能为它装入物品。")
                    .font(.body).foregroundStyle(GowithColor.secondary).multilineTextAlignment(.center)
                GowithSecondaryButton(title: "返回背包页", systemImage: "backpack.fill", action: onOpenBackpack)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }

    private var locationGate: some View {
        if let selectedPlace {
            GowithInlineStatus(
                title: canManageSelectedPlace ? "已在「\(selectedPlace.name)」范围内，可以管理物品" : "到达「\(selectedPlace.name)」约 50 米范围内可管理物品",
                systemImage: canManageSelectedPlace ? "location.fill" : "lock.fill",
                isPositive: canManageSelectedPlace
            )
        } else {
            GowithInlineStatus(title: "请先选择一个地点", systemImage: "mappin.slash")
        }
    }
}

struct LibraryItemRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let item: GowithItem
    let isPacked: Bool
    let action: () -> Void

    var body: some View {
        GowithInventoryRow(
            item: item,
            stateTitle: isPacked ? "已携带" : "未携带",
            stateIcon: isPacked ? "checkmark.circle.fill" : "circle",
            actionTitle: isPacked ? "从当前背包移除\(item.name)" : "加入当前背包\(item.name)",
            actionIcon: isPacked ? "minus" : "plus",
            action: action
        )
        .opacity(isPacked ? 0.82 : 1)
        .animation(reduceMotion ? nil : GowithMotion.row, value: isPacked)
    }
}

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

    var body: some View {
        NavigationStack {
            Form {
                Section("分类名称") {
                    TextField("最多四个字", text: $name)
                        .onChange(of: name) { _, value in
                            if value.count > 4 { name = String(value.prefix(4)) }
                        }
                }
                Section("分类图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(symbolOptions, id: \.self) { symbol in
                            Button { symbolName = symbol } label: {
                                Image(systemName: symbol)
                                    .font(.system(size: 20))
                                    .foregroundStyle(symbolName == symbol ? .white : GowithColor.primary)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(symbolName == symbol ? GowithColor.primary : GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(GowithColor.appBackground)
            .navigationTitle(category == nil ? "添加分类" : "编辑分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let category {
                    HStack {
                        Button("上移", systemImage: "arrow.up") { move(category, by: -1) }
                        Spacer()
                        Button("下移", systemImage: "arrow.down") { move(category, by: 1) }
                        Spacer()
                        Button("删除", systemImage: "trash", role: .destructive) { delete(category) }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(GowithColor.surface)
                }
            }
        }
    }

    private let symbolOptions = ["square.grid.2x2.fill", "sun.max.fill", "bolt.fill", "person.text.rectangle.fill", "briefcase.fill", "house.fill", "heart.fill", "ellipsis"]

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
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

struct ItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GowithStore
    let item: GowithItem?
    let initialCategoryID: UUID?
    let allowsUncategorized: Bool
    @State private var name: String
    @State private var symbolName: String
    @State private var categoryID: UUID?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showCamera = false

    init(item: GowithItem? = nil, initialCategoryID: UUID? = nil, allowsUncategorized: Bool = true) {
        self.item = item
        self.initialCategoryID = initialCategoryID
        self.allowsUncategorized = allowsUncategorized
        _name = State(initialValue: item?.name ?? "")
        _symbolName = State(initialValue: item?.symbolName ?? "square.dashed")
        _categoryID = State(initialValue: item?.categoryID ?? initialCategoryID)
        _imageData = State(initialValue: LocalImageStore.load(fileName: item?.imageFileName))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("物品名称", text: $name)
                    if allowsUncategorized || item != nil {
                        Picker("分类", selection: $categoryID) {
                            Text("未分类").tag(nil as UUID?)
                            ForEach(store.categories) { category in
                                Text(category.name).tag(category.id as UUID?)
                            }
                        }
                    } else if let initialCategoryID, let category = store.categories.first(where: { $0.id == initialCategoryID }) {
                        LabeledContent("分类", value: category.name)
                    }
                }
                Section("图标") {
                    HStack {
                        ItemThumbnail(data: imageData, fileName: nil, symbolName: symbolName, size: 64)
                        Spacer()
                        PhotosPicker(selection: $selectedPhoto, matching: .images) { Label("从相册选择", systemImage: "photo") }
                        Button { showCamera = true } label: { Label("拍摄", systemImage: "camera") }
                    }
                    if imageData != nil {
                        Button("使用 SF Symbol") { imageData = nil }
                    }
                    Text("3D 图标").font(.subheadline.weight(.medium))
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(Gowith3DIconOption.all) { option in
                            Button {
                                symbolName = option.id
                                imageData = nil
                            } label: {
                                VStack(spacing: 4) {
                                    Gowith3DIcon(option: option, size: 42)
                                    Text(option.title).font(.caption2).lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, minHeight: 70)
                                .background(symbolName == option.id && imageData == nil ? GowithColor.success : GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("选择3D图标：\(option.title)")
                        }
                    }
                    Text("系统图标").font(.subheadline.weight(.medium))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(symbolOptions, id: \.self) { symbol in
                                Button { symbolName = symbol; imageData = nil } label: {
                                    Image(systemName: symbol)
                                        .font(.system(size: 20))
                                        .foregroundStyle(symbolName == symbol && imageData == nil ? .white : GowithColor.primary)
                                        .frame(width: 44, height: 44)
                                        .background(symbolName == symbol && imageData == nil ? GowithColor.primary : GowithColor.softSurface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(GowithColor.appBackground)
            .navigationTitle(item == nil ? "添加物品" : "编辑物品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .task(id: selectedPhoto) {
                guard let selectedPhoto, let data = try? await selectedPhoto.loadTransferable(type: Data.self) else { return }
                imageData = data
            }
            .sheet(isPresented: $showCamera) { CameraPicker(imageData: $imageData) }
        }
    }

    private let symbolOptions = ["square.dashed", "iphone", "key.fill", "wallet.pass.fill", "airpods", "battery.100percent", "umbrella.fill", "book.fill", "pill.fill", "glasses", "laptopcomputer", "creditcard.fill"]

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
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
        } else {
            store.items.append(GowithItem(name: trimmedName, symbolName: symbolName, imageFileName: newFileName, categoryID: categoryID, placeID: store.selectedPlaceID))
        }
        store.save()
        dismiss()
    }
}

struct ItemThumbnail: View {
    var data: Data? = nil
    let fileName: String?
    let symbolName: String
    let size: CGFloat

    init(data: Data? = nil, fileName: String?, symbolName: String, size: CGFloat) {
        self.data = data
        self.fileName = fileName
        self.symbolName = symbolName
        self.size = size
    }

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let image = LocalImageStore.cachedImage(fileName: fileName) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let option = Gowith3DIconOption.option(for: symbolName) {
                Gowith3DIcon(option: option, size: size * 0.86)
            } else {
                Image(systemName: symbolName).font(.system(size: size * 0.38, weight: .medium)).foregroundStyle(GowithColor.primary)
            }
        }
        .frame(width: size, height: size)
        .background(GowithColor.softSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

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
