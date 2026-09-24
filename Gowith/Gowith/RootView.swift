import CoreLocation
import MapKit
import PhotosUI
import SwiftUI

enum AppTab: Hashable {
    case backpack
    case library
    case map
    case profile
}

struct RootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    @AppStorage("gowith.hasSeenHero") private var hasSeenHero = false
    @AppStorage("gowith.didCompleteSetup") private var didCompleteSetup = false
    @State private var selectedTab: AppTab = .backpack
    @State private var showGoSummary = false
    @State private var showGoMessage = false
    @State private var goMessage = ""

    private var items: [GowithItem] { store.visibleItems }
    private var sessions: [OutingSession] { store.sessions.sorted { $0.startedAt > $1.startedAt } }

    var body: some View {
        Group {
            if hasSeenHero {
                if didCompleteSetup {
                    mainInterface
                } else {
                    GowithSetupView {
                        withAnimation(.easeInOut(duration: 0.25)) { didCompleteSetup = true }
                    }
                }
            } else {
                GowithHeroView {
                    withAnimation(.easeInOut(duration: 0.25)) { hasSeenHero = true }
                }
            }
        }
    }

    private var mainInterface: some View {
        TabView(selection: $selectedTab) {
            BackpackView(onChooseItems: requestPickup)
                .tabItem { Image(systemName: "backpack.fill").accessibilityLabel("背包") }
                .tag(AppTab.backpack)

            ItemLibraryView(
                onOpenBackpack: { selectedTab = .backpack },
                onStartOuting: requestGo,
                onPickup: requestPickup
            )
            .tabItem { Image(systemName: "house.fill").accessibilityLabel("物品库") }
            .tag(AppTab.library)

            Group {
                if let activeSession = store.activeSession {
                    GoView(items: items, currentSession: activeSession)
                } else {
                    PlacesMapView(onTakeItems: requestPickup)
                }
            }
            .tabItem { Image(systemName: "map.fill").accessibilityLabel("地图") }
            .tag(AppTab.map)

            ProfileView(sessions: sessions, items: items)
                .tabItem { Image(systemName: "person.fill").accessibilityLabel("我的") }
                .tag(AppTab.profile)
        }
        .toolbarBackground(GowithColor.appBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .background(GowithColor.appBackground)
        .tint(GowithColor.sceneMint)
        .animation(reduceMotion ? nil : GowithMotion.content, value: selectedTab)
        .confirmationDialog("准备出发？", isPresented: $showGoSummary, titleVisibility: .visible) {
            Button("开始出行") { startOuting() }
            Button("取消", role: .cancel) {}
        } message: {
            Text(goSummary)
        }
        .alert("无法开始出行", isPresented: $showGoMessage) {
            Button("好的", role: .cancel) {}
            if store.selectedBackpack == nil {
                Button("去背包页") { selectedTab = .backpack }
            } else {
                Button("去物品库") { selectedTab = .library }
            }
        } message: {
            Text(goMessage)
        }
        .task {
            store.processExpiredPending()
            locationService.onSessionChanged = { store.save() }
            if let session = store.activeSession, session.status == .away {
                locationService.startMonitoring(session: session, places: store.places)
            }
        }
        .onChange(of: locationService.arrivedPlaceID) { _, placeID in
            guard let placeID, let session = store.activeSession, session.status == .away,
                  let place = store.place(for: placeID) else { return }
            session.applyArrival(at: place)
            store.save()
        }
        .onChange(of: selectedTab) { _, _ in store.processExpiredPending() }
    }

    private var goSummary: String {
        guard let backpack = store.selectedBackpack else { return "请先选择一个背包。" }
        let packed = store.itemsAtSelectedPlace.filter { backpack.itemIDs.contains($0.id) }
        return "本次使用「\(backpack.name)」，共携带 \(packed.count) 件物品。开始后会保存本次清单。"
    }

    private func requestGo() {
        guard store.activeSession == nil else { selectedTab = .map; return }
        guard let place = store.selectedPlace, locationService.isInside(place) else {
            goMessage = "到达当前地点约 50 米范围内后，才能开始出行。"
            showGoMessage = true
            return
        }
        guard let backpack = store.selectedBackpack else {
            goMessage = "还没有选择背包。先创建或选择一个背包，再开始出行。"
            showGoMessage = true
            return
        }
        let packed = store.itemsAtSelectedPlace.filter { backpack.itemIDs.contains($0.id) }
        guard !packed.isEmpty else {
            goMessage = "「\(backpack.name)」还没有物品。先去物品库选择本次要携带的物品。"
            showGoMessage = true
            return
        }
        showGoSummary = true
    }

    private func requestPickup() {
        guard let place = store.selectedPlace else {
            goMessage = "先在地图中添加或选择一个家。"
            showGoMessage = true
            return
        }
        guard locationService.isInside(place) else {
            goMessage = "到达「\(place.name)」约 50 米范围内后，才能拿取或调整这里的物品。"
            showGoMessage = true
            return
        }
        selectedTab = .library
    }

    private func startOuting() {
        guard let backpack = store.selectedBackpack else { return }
        let packed = store.itemsAtSelectedPlace.filter { backpack.itemIDs.contains($0.id) }
        guard !packed.isEmpty else { return }
        let session = OutingSession(backpack: backpack)
        session.items = packed.map(SessionItem.init(item:))
        session.originPlaceID = store.selectedPlace?.id
        session.originPlaceNameSnapshot = store.selectedPlace?.name
        for item in packed { item.placeID = nil }
        backpack.placeID = nil
        session.status = .away
        session.wentOutAt = .now
        store.sessions.append(session)
        store.save()
        locationService.startMonitoring(session: session, places: store.places)
        selectedTab = .map
    }
}

struct GowithSetupView: View {
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    let onComplete: () -> Void
    @State private var placeName = ""
    @State private var backpackName = ""
    @State private var itemName = ""
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var setupCamera: MapCameraPosition = .automatic
    @State private var showValidation = false

    private var canComplete: Bool {
        !placeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !backpackName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        coordinate != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Gowith")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .tracking(-1)
                    Text("先建立你的第一个出发点")
                        .font(.title2.weight(.semibold))
                    Text("这些基础信息会帮助 Gowith 之后判断你在哪里，以及哪些物品属于这个家。")
                        .font(.body)
                        .foregroundStyle(GowithColor.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                GowithCard {
                    VStack(alignment: .leading, spacing: 18) {
                        setupField(title: "第一个家", hint: "例如：广西玉林", text: $placeName, icon: "house.fill")
                        setupField(title: "常用背包", hint: "例如：通勤包", text: $backpackName, icon: "backpack.fill")
                        setupField(title: "一件常用物品", hint: "例如：钥匙", text: $itemName, icon: "key.fill")
                    }
                }

                GowithCard(padding: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: coordinate == nil ? "location.slash" : "location.fill")
                                .foregroundStyle(coordinate == nil ? .white : GowithColor.primary)
                                .frame(width: 38, height: 38)
                                .background(coordinate == nil ? GowithColor.primary : GowithColor.success, in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text("设置这个家的位置")
                                    .font(.subheadline.weight(.semibold))
                                Text(coordinate == nil ? "使用当前位置，或在下方地图点选位置" : "位置已准备好，之后会用于到达提醒")
                                    .font(.caption)
                                    .foregroundStyle(GowithColor.secondary)
                            }
                        }
                        GowithSecondaryButton(title: coordinate == nil ? "使用当前位置" : "重新获取当前位置", systemImage: "location.fill") {
                            locationService.requestCurrentLocation()
                        }
                        MapReader { proxy in
                            Map(position: $setupCamera) {
                                if let coordinate {
                                    MapCircle(center: coordinate, radius: 50)
                                        .foregroundStyle(GowithColor.success.opacity(0.3))
                                        .stroke(GowithColor.success, lineWidth: 1.5)
                                    Marker("家的位置", systemImage: "house.fill", coordinate: coordinate)
                                }
                            }
                            .mapControls { MapUserLocationButton(); MapCompass() }
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .simultaneousGesture(SpatialTapGesture().onEnded { value in
                                guard let picked = proxy.convert(value.location, from: .local) else { return }
                                coordinate = picked
                            })
                        }
                        if !locationService.statusMessage.isEmpty {
                            Text(locationService.statusMessage)
                                .font(.caption)
                                .foregroundStyle(GowithColor.secondary)
                        }
                    }
                }

                GowithPrimaryButton(title: "进入 Gowith", systemImage: "arrow.right") {
                    completeSetup()
                }
                .disabled(!canComplete)
                .opacity(canComplete ? 1 : 0.45)

                if showValidation {
                    Text("请填写地点、背包和一件常用物品，并设置当前位置。")
                        .font(.caption)
                        .foregroundStyle(GowithColor.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, GowithMetrics.pagePadding)
            .padding(.top, 36)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(GowithColor.appBackground)
        .onAppear {
            locationService.requestCurrentLocationIfNeeded()
            if let existing = store.selectedPlace {
                placeName = existing.name == "我的家" ? "" : existing.name
                coordinate = existing.coordinate
            }
        }
        .onChange(of: locationService.currentCoordinate?.latitude) { _, _ in
            if coordinate == nil { coordinate = locationService.currentCoordinate }
        }
    }

    private func setupField(title: String, hint: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
            TextField(hint, text: text)
                .textFieldStyle(.plain)
                .font(.body)
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
                .background(GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
    }

    private func completeSetup() {
        guard canComplete, let coordinate else {
            showValidation = true
            return
        }
        let trimmedPlace = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBackpack = backpackName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedItem = itemName.trimmingCharacters(in: .whitespacesAndNewlines)

        let place: GowithPlace
        if let existing = store.selectedPlace {
            place = existing
            existing.name = trimmedPlace
            existing.latitude = coordinate.latitude
            existing.longitude = coordinate.longitude
        } else {
            place = GowithPlace(name: trimmedPlace, latitude: coordinate.latitude, longitude: coordinate.longitude, radius: 50)
            store.places.append(place)
        }

        let backpack = GowithBackpack(name: trimmedBackpack, symbolName: "gowith3d.backpack", placeID: place.id)
        let item = GowithItem(name: trimmedItem, symbolName: "gowith3d.keys", placeID: place.id)
        backpack.itemIDs = [item.id]
        store.items.append(item)
        store.backpacks.append(backpack)
        store.selectPlace(place)
        store.selectBackpack(backpack)
        store.save()
        onComplete()
    }
}

struct BackpackView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    let onChooseItems: () -> Void
    @State private var selectedIndex = 0
    @State private var editingBackpack: GowithBackpack?
    @State private var showAddBackpack = false
    @State private var showAddItem = false
    @State private var showDeleteConfirmation = false
    @State private var backpackToDelete: GowithBackpack?

    private var backpacks: [GowithBackpack] { store.backpacksAtSelectedPlace }
    private var canManageSelectedPlace: Bool {
        guard let place = store.selectedPlace else { return false }
        return locationService.isInside(place)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    GowithTopBar(pageTitle: "背包") {
                        Menu {
                            Button("添加背包", systemImage: "backpack.badge.plus") { showAddBackpack = true }
                            Button("添加物品", systemImage: "plus.square") { showAddItem = true }
                                .disabled(!canManageSelectedPlace)
                            Button("去家里拿物品", systemImage: "arrow.down.to.line.compact", action: onChooseItems)
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(GowithColor.primary)
                                .frame(width: 44, height: 44)
                                .background(GowithColor.surface, in: Circle())
                        }
                        .accessibilityLabel("添加和取物品")
                    }
                    GowithContextStrip()
                    HStack(alignment: .firstTextBaseline) {
                        Text("选择一个背包")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(GowithColor.primary)
                        Spacer()
                        Text("\(backpacks.count) 个")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(GowithColor.tertiary)
                    }
                    if backpacks.isEmpty {
                        emptyState
                    } else {
                        backpackCarousel
                        positionDots
                        packedItemsList
                    GowithBottomAction(title: "选择物品", systemImage: "arrow.right", action: onChooseItems)
                    }
                }
                .padding(.horizontal, GowithMetrics.pagePadding)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(GowithColor.appBackground)
            .sheet(isPresented: $showAddBackpack) { BackpackEditorView() }
            .sheet(isPresented: $showAddItem) { ItemEditorView() }
            .sheet(item: $editingBackpack) { backpack in BackpackEditorView(backpack: backpack) }
            .confirmationDialog("删除这个背包？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("删除背包", role: .destructive) {
                    if let backpackToDelete { delete(backpackToDelete) }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("只会删除背包及其装包清单，不会删除物品库中的物品。")
            }
            .onAppear { syncSelection() }
            .onChange(of: store.selectedPlaceID) { _, _ in
                selectedIndex = 0
                syncSelection()
            }
            .onChange(of: selectedIndex) { _, _ in selectCurrentBackpack() }
            .onChange(of: backpacks.count) { _, _ in syncSelection() }
        }
    }

    private var backpackCarousel: some View {
        GowithObjectRail(itemCount: backpacks.count, selectedIndex: $selectedIndex) { index, _ in
            if backpacks.indices.contains(index) {
                backpackCard(backpacks[index], width: 280)
            }
        }
        .onAppear {
            let index = backpacks.indices.contains(selectedIndex) ? selectedIndex : 0
            selectedIndex = index
            selectCurrentBackpack()
        }
    }

    @ViewBuilder
    private func backpackCard(_ backpack: GowithBackpack, width: CGFloat) -> some View {
        let index = backpacks.firstIndex(where: { $0.id == backpack.id }) ?? 0
        VStack(alignment: .leading, spacing: 12) {
            GowithFocusField(color: sceneColor(for: index), height: 270) {
                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("当前背包")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(GowithColor.primary.opacity(0.66))
                        Text(backpack.name)
                            .font(.title.weight(.bold))
                            .foregroundStyle(GowithColor.primary)
                            .lineLimit(1)
                            .padding(.top, 4)
                        Spacer()
                        HStack {
                            Label("\(backpack.itemIDs.count) 件物品", systemImage: "archivebox.fill")
                                .font(.footnote.weight(.semibold))
                            Spacer()
                            Text("可出行")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.36), in: Capsule())
                        }
                        .foregroundStyle(GowithColor.primary.opacity(0.78))
                    }
                    .padding(22)

                    VStack(spacing: -14) {
                        backpackArtwork(backpack)
                            .frame(width: 176, height: 176)
                        backpackArtwork(backpack)
                            .scaleEffect(y: -1)
                            .blur(radius: 1.8)
                            .opacity(0.16)
                            .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                            .frame(width: 176, height: 70)
                    }
                    .offset(x: 16, y: 54)

                    Button { editingBackpack = backpack } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(GowithColor.primary)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.42), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(14)
                    .accessibilityLabel("编辑\(backpack.name)")
                }
            }
        }
        .frame(width: width)
        .contextMenu {
            Button("删除背包", systemImage: "trash", role: .destructive) {
                backpackToDelete = backpack
                showDeleteConfirmation = true
            }
            .disabled(store.activeSession?.backpackID == backpack.id)
        }
    }

    @ViewBuilder
    private func backpackArtwork(_ backpack: GowithBackpack) -> some View {
        if let image = LocalImageStore.cachedImage(fileName: backpack.imageFileName) {
            Image(uiImage: image).resizable().scaledToFit()
        } else if let option = Gowith3DIconOption.option(for: backpack.symbolName) {
            Gowith3DIcon(option: option, size: 170)
        } else {
            Image(systemName: backpack.symbolName)
                .font(.system(size: 88, weight: .light))
                .foregroundStyle(GowithColor.primary)
        }
    }

    private var positionDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<dotCount, id: \.self) { dot in
                Circle()
                    .fill(dot == activeDot ? GowithColor.primary : GowithColor.tertiary.opacity(0.35))
                    .frame(width: dot == activeDot ? 8 : 6, height: dot == activeDot ? 8 : 6)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: activeDot)
            }
        }
        .frame(height: 18)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("背包位置")
        .accessibilityValue("第\(selectedIndex + 1)个，共\(backpacks.count)个")
    }

    /// 背包不超过 3 个时，每个背包一个圆点；超过 3 个时收敛为「开头/中间/结尾」三个位置点。
    private var dotCount: Int { min(backpacks.count, 3) }

    private var activeDot: Int {
        if backpacks.count <= 3 { return selectedIndex }
        if selectedIndex == 0 { return 0 }
        if selectedIndex == backpacks.count - 1 { return 2 }
        return 1
    }

    private var emptyState: some View {
        GowithCard {
            VStack(spacing: 14) {
                Image(systemName: "backpack").font(.system(size: 38, weight: .light))
                Text("还没有背包").font(.title3.weight(.semibold))
                Text("创建一个背包，开始准备本次出行。")
                    .font(.body).foregroundStyle(GowithColor.secondary).multilineTextAlignment(.center)
                GowithPrimaryButton(title: "创建背包", systemImage: "plus") { showAddBackpack = true }.padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }

    private var packedItemsList: some View {
        let itemIDs = Set(store.selectedBackpack?.itemIDs ?? [])
        let packedItems = store.visibleItems.filter { itemIDs.contains($0.id) }
        return VStack(alignment: .leading, spacing: 10) {
            GowithSectionHeader(title: "已装入物品", trailing: "\(packedItems.count) 件")
            if packedItems.isEmpty {
                Text("这个背包还没有物品")
                    .font(.subheadline)
                    .foregroundStyle(GowithColor.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(packedItems.enumerated()), id: \.element.id) { index, item in
                        GowithInventoryRow(
                            item: item,
                            stateTitle: "已携带",
                            stateIcon: "checkmark.circle.fill",
                            actionTitle: "从当前背包移除",
                            actionIcon: "minus"
                        ) {
                            guard let backpack = store.selectedBackpack, canManageSelectedPlace else { return }
                            store.toggleItem(item, in: backpack)
                        }
                        if index < packedItems.count - 1 { Divider().padding(.leading, 66) }
                    }
                }
                .background(GowithColor.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func sceneColor(for index: Int) -> Color {
        switch index % 4 {
        case 1: return GowithColor.sceneViolet
        case 2: return GowithColor.sceneSky
        case 3: return GowithColor.sceneOrange
        default: return GowithColor.sceneMint
        }
    }

    private func syncSelection() {
        guard !backpacks.isEmpty else { selectedIndex = 0; return }
        if let id = store.selectedBackpackID, let index = backpacks.firstIndex(where: { $0.id == id }) {
            selectedIndex = index
        } else {
            selectedIndex = min(selectedIndex, backpacks.count - 1)
            store.selectBackpack(backpacks[selectedIndex])
        }
    }

    private func selectCurrentBackpack() {
        guard backpacks.indices.contains(selectedIndex) else { return }
        store.selectBackpack(backpacks[selectedIndex])
    }

    private func delete(_ backpack: GowithBackpack) {
        // 进行中的出行会话引用该背包时禁止删除，避免会话数据悬空。
        guard store.activeSession?.backpackID != backpack.id else { return }
        store.backpacks.removeAll { $0.id == backpack.id }
        if store.selectedBackpackID == backpack.id { store.selectedBackpackID = store.visibleBackpacks.first?.id }
        store.save()
    }
}

struct BackpackEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GowithStore
    let backpack: GowithBackpack?
    @State private var name: String
    @State private var symbolName: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?

    init(backpack: GowithBackpack? = nil) {
        self.backpack = backpack
        _name = State(initialValue: backpack?.name ?? "")
        _symbolName = State(initialValue: backpack?.symbolName ?? "backpack.fill")
        _imageData = State(initialValue: LocalImageStore.load(fileName: backpack?.imageFileName))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("背包名称") { TextField("例如：通勤包", text: $name) }
                Section("背包图标") {
                    HStack {
                        if let imageData, let image = UIImage(data: imageData) {
                            Image(uiImage: image).resizable().scaledToFill().frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else if let option = Gowith3DIconOption.option(for: symbolName) {
                            Gowith3DIcon(option: option, size: 64)
                        } else {
                            Image(systemName: symbolName).font(.system(size: 28)).frame(width: 64, height: 64).background(GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        Spacer()
                        PhotosPicker(selection: $selectedPhoto, matching: .images) { Label("选择照片", systemImage: "photo") }
                    }
                    if imageData != nil { Button("使用系统图标") { imageData = nil } }
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
                        }
                    }
                    Text("系统图标").font(.subheadline.weight(.medium))
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(symbolOptions, id: \.self) { symbol in
                            Button { symbolName = symbol; imageData = nil } label: {
                                Image(systemName: symbol)
                                    .font(.system(size: 21))
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
            .navigationTitle(backpack == nil ? "添加背包" : "编辑背包")
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
        }
    }

    private let symbolOptions = ["backpack.fill", "briefcase.fill", "suitcase.fill", "bag.fill", "basket.fill", "cart.fill", "shippingbox.fill", "duffel.bag.fill"]

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
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
