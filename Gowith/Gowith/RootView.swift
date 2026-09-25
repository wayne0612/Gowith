import CoreLocation
import MapKit
import SwiftUI

struct RootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    @AppStorage("gowith.appMode") private var mode: AppMode = .basic
    @AppStorage("gowith.hasSeenTutorial") private var hasSeenTutorial = false
    @AppStorage("gowith.didCompleteSetup") private var didCompleteSetup = false

    @State private var selectedTab: AppTab = .library
    @State private var isReviewingArrival = false
    @State private var showGoSummary = false
    @State private var showGoMessage = false
    @State private var goMessage = ""
    @State private var showPendingAlert = false
    @State private var showManualArrive = false

    // 装包飞球动画状态（规格 2.4）
    @State private var packSourceAnchors: [PackAnchor] = []
    @State private var tabAnchors: [AppTab: CGPoint] = [:]
    @State private var packFlight: PackFlightState?
    @State private var packingBadgePulse = 0

    var body: some View {
        Group {
            if !hasSeenTutorial {
                TutorialView { hasSeenTutorial = true }
            } else if !didCompleteSetup {
                GowithSetupView {
                    withAnimation(.easeInOut(duration: 0.25)) { didCompleteSetup = true }
                }
            } else {
                mainInterface
            }
        }
        .preferredColorScheme(mode == .advanced ? .dark : .light)
        .tint(GowithColor.accent)
    }

    // MARK: 全局骨架（规格 3：固定头部 / 唯一滑动区 / 悬浮主按钮 / Tab 栏）

    private var mainInterface: some View {
        navigationShell
            .confirmationDialog("准备出发？", isPresented: $showGoSummary, titleVisibility: .visible) {
                Button("开始出行") { startOuting() }
                Button("取消", role: .cancel) {}
            } message: {
                Text(goSummary)
            }
            .alert("无法开始出行", isPresented: $showGoMessage) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(goMessage)
            }
            .alert("还有物品待确认", isPresented: $showPendingAlert) {
                Button("返回核对", role: .cancel) {}
                Button("继续完成") { completeSession() }
            } message: {
                Text("还有 \(unresolvedCount) 件物品待确认。继续完成后，它们会保留 3 天，期间可以在历史记录中补充确认。")
            }
            .confirmationDialog("确认到达地点", isPresented: $showManualArrive, titleVisibility: .visible) {
                ForEach(store.places) { place in
                    Button(place.name) { markArrived(at: place) }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("选择当前位置附近的已保存地点。到达其他地点后，可选择放入哪些物品。")
            }
            .task {
                store.processExpiredPending()
                locationService.onSessionChanged = { store.save() }
                if let session = store.activeSession, session.status == .away {
                    locationService.startMonitoring(session: session, places: store.places)
                }
            }
            .onChange(of: locationService.arrivedPlaceID) { _, placeID in
                handleArrival(placeID)
            }
            .onChange(of: selectedTab) { _, _ in store.processExpiredPending() }
            .onChange(of: mode) { _, newMode in
                if newMode == .basic && selectedTab == .map { selectedTab = .profile }
            }
    }

    private var navigationShell: some View {
        ZStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(selectedTab)
                .transition(reduceMotion ? AnyTransition.opacity : AnyTransition.opacity.combined(with: .scale(scale: 0.99)))
        }
        .background(GowithColor.appBackground)
        .safeAreaInset(edge: .top, spacing: 0) {
            AppHeader(mode: $mode)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomControls
        }
        .coordinateSpace(name: "root")
        .overlay { packBallOverlay }
        .onPreferenceChange(PackSourceKey.self) { packSourceAnchors = $0 }
        .onPreferenceChange(TabAnchorKey.self) { tabAnchors = $0 }
        .animation(reduceMotion ? nil : GowithMotion.content, value: selectedTab)
    }

    private var bottomControls: some View {
        VStack(spacing: 0) {
            if let button = mainButton {
                MainButtonArea(title: button.title, isEnabled: button.isEnabled, action: button.action)
            }
            GowithTabBar(items: tabItems, selection: $selectedTab)
        }
        .background(GowithColor.appBackground)
    }

    private func handleArrival(_ placeID: UUID?) {
        guard let placeID, let session = store.activeSession, session.status == .away,
              let place = store.place(for: placeID) else { return }
        session.applyArrival(at: place)
        isReviewingArrival = false
        locationService.stopMonitoring()
        GowithHaptics.success()
        store.save()
        selectedTab = .check
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .library:
            LibraryPage(onPack: handlePack)
        case .packing:
            PackingPage(onPack: handlePack, onRequestManualArrive: { showManualArrive = true })
        case .check:
            CheckPage(isReviewingArrival: $isReviewingArrival)
        case .map:
            AdvancedMapPage()
        case .profile:
            ProfilePage()
        }
    }

    // MARK: Tab 与角标

    private var packedItems: [GowithItem] { store.packedItems(in: store.selectedBackpack) }
    private var pendingCount: Int { store.pendingItemCount }
    private var unresolvedCount: Int {
        guard let session = store.activeSession, session.status == .checking else { return 0 }
        return session.items.filter { $0.status == .unconfirmed }.count
    }

    private var tabItems: [GowithTabItem] {
        var items = [
            GowithTabItem(tab: .library, title: "物品库", icon: "square.grid.2x2.fill"),
            GowithTabItem(tab: .packing, title: "拿东西", icon: "backpack.fill", badge: packedItems.count),
            GowithTabItem(tab: .check, title: "检查", icon: "checklist", badge: pendingCount),
        ]
        if mode == .advanced {
            items.append(GowithTabItem(tab: .map, title: "地图", icon: "map.fill"))
        }
        items.append(GowithTabItem(tab: .profile, title: "我的", icon: "person.fill"))
        return items
    }

    // MARK: 悬浮主按钮状态机

    private struct MainButtonConfig {
        let title: String
        var isEnabled = true
        let action: () -> Void
    }

    private var mainButton: MainButtonConfig? {
        switch selectedTab {
        case .packing:
            if let session = store.activeSession {
                switch session.status {
                case .away:
                    // 出行中：整页只读，主按钮禁用（规格 5.2）
                    return MainButtonConfig(title: "到达后自动提醒清点", isEnabled: false, action: {})
                case .arrived, .checking:
                    return MainButtonConfig(title: "返回清点", action: { selectedTab = .check })
                default:
                    break
                }
            }
            let count = packedItems.count
            return MainButtonConfig(title: "开始出行（\(count) 件）", isEnabled: count > 0, action: requestGo)
        case .check:
            guard let session = store.activeSession else { return nil }
            switch session.status {
            case .checking:
                let returned = session.items.filter { $0.status == .returned }.count
                return MainButtonConfig(title: "完成清点（\(returned)/\(session.items.count)）", action: requestCompletion)
            case .arrived:
                return isReviewingArrival
                    ? MainButtonConfig(title: "完成放入目的地", action: completeArrival)
                    : MainButtonConfig(title: "开始检阅", action: beginArrivalReview)
            default:
                return nil
            }
        default:
            return nil
        }
    }

    // MARK: 装包飞球（规格 2.4）

    private struct PackFlightState {
        let from: CGPoint
        let to: CGPoint
        var animated = false
    }

    private var packBallOverlay: some View {
        ZStack {
            if let flight = packFlight {
                Circle()
                    .fill(GowithColor.accent)
                    .frame(width: 14, height: 14)
                    .position(flight.animated ? flight.to : flight.from)
                    .scaleEffect(flight.animated ? 0.4 : 1)
                    .opacity(flight.animated ? 0 : 1)
                    .animation(reduceMotion ? nil : GowithMotion.packBall, value: flight.animated)
            }
        }
        .allowsHitTesting(false)
    }

    private func handlePack(_ item: GowithItem) {
        guard let backpack = store.selectedBackpack else { return }
        let willPack = !backpack.itemIDs.contains(item.id)
        store.toggleItem(item, in: backpack)
        GowithHaptics.selection()
        guard willPack, !reduceMotion else { return }
        guard let from = packSourceAnchors.last(where: { $0.id == item.id })?.center,
              let to = tabAnchors[.packing] else { return }
        packFlight = PackFlightState(from: from, to: to)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 30_000_000)
            withAnimation(GowithMotion.packBall) { self.packFlight?.animated = true }
            try? await Task.sleep(nanoseconds: 560_000_000)
            self.packFlight = nil
        }
    }

    // MARK: 出行会话（沿用现有逻辑，状态机不变）

    private var goSummary: String {
        guard let backpack = store.selectedBackpack else { return "请先选择一个背包。" }
        return "本次使用「\(backpack.name)」，共携带 \(packedItems.count) 件物品。开始后会保存本次清单。"
    }

    private func requestGo() {
        guard store.activeSession == nil else { selectedTab = .check; return }
        guard let place = store.selectedPlace, locationService.isInside(place) else {
            goMessage = "到达当前地点约 50 米范围内后，才能开始出行。"
            showGoMessage = true
            return
        }
        guard let backpack = store.selectedBackpack else {
            goMessage = "还没有选择背包。先选择一个背包，再开始出行。"
            showGoMessage = true
            return
        }
        guard !packedItems.isEmpty else {
            goMessage = "「\(backpack.name)」还没有物品。先从货架装入本次要携带的物品。"
            showGoMessage = true
            return
        }
        showGoSummary = true
    }

    private func startOuting() {
        guard let backpack = store.selectedBackpack else { return }
        guard !packedItems.isEmpty else { return }
        let session = OutingSession(backpack: backpack)
        session.items = packedItems.map(SessionItem.init(item:))
        session.originPlaceID = store.selectedPlace?.id
        session.originPlaceNameSnapshot = store.selectedPlace?.name
        for item in packedItems { item.placeID = nil }
        backpack.placeID = nil
        session.status = .away
        session.wentOutAt = .now
        store.sessions.append(session)
        store.save()
        GowithHaptics.stateChange()
        locationService.startMonitoring(session: session, places: store.places)
    }

    private func markArrived(at place: GowithPlace) {
        guard let session = store.activeSession, session.status == .away else { return }
        session.applyArrival(at: place)
        isReviewingArrival = false
        locationService.stopMonitoring()
        GowithHaptics.stateChange()
        store.save()
        selectedTab = .check
    }

    private func requestCompletion() {
        if unresolvedCount > 0 || (store.activeSession?.items.filter { $0.status == .pending }.count ?? 0) > 0 {
            showPendingAlert = true
        } else {
            completeSession()
        }
    }

    private func completeSession() {
        guard let session = store.activeSession else { return }
        for item in session.items where item.status == .unconfirmed {
            item.status = .pending
            item.pendingSince = session.checkingStartedAt ?? .now
        }
        session.status = .completed
        session.completedAt = .now
        // 已带回与待确认的物品都归入出发地；待确认物品之后仍可在历史记录中改为遗失。
        let homeID = session.originPlaceID ?? store.places.first?.id
        if let homeID {
            for sessionItem in session.items where sessionItem.status == .returned || sessionItem.status == .pending {
                if let original = store.items.first(where: { $0.id == sessionItem.itemID }) { original.placeID = homeID }
            }
            if let backpack = store.backpacks.first(where: { $0.id == session.backpackID }) { backpack.placeID = homeID }
        }
        locationService.stopMonitoring()
        GowithHaptics.success()
        store.save()
        isReviewingArrival = false
        selectedTab = .library
    }

    private func beginArrivalReview() {
        guard let session = store.activeSession, session.status == .arrived else { return }
        for item in session.items { item.isSelected = true }
        withAnimation(GowithMotion.content) { isReviewingArrival = true }
        GowithHaptics.selection()
        store.save()
    }

    private func completeArrival() {
        guard let session = store.activeSession else { return }
        guard let destinationID = session.destinationPlaceID,
              let destination = store.place(for: destinationID) else { return }
        let backpack = store.backpacks.first(where: { $0.id == session.backpackID })
        for sessionItem in session.items {
            if sessionItem.isSelected {
                if let item = store.items.first(where: { $0.id == sessionItem.itemID }) { item.placeID = destinationID }
                backpack?.itemIDs.removeAll { $0 == sessionItem.itemID }
                sessionItem.status = .stored
                sessionItem.destinationPlaceID = destinationID
            } else {
                sessionItem.status = .carried
            }
        }
        backpack?.placeID = destinationID
        session.status = .completed
        session.completedAt = .now
        locationService.stopMonitoring()
        GowithHaptics.success()
        store.selectPlace(destination)
        if let backpack { store.selectBackpack(backpack) }
        store.save()
        isReviewingArrival = false
        selectedTab = .library
    }
}

// MARK: - 首启教学动画（规格 5.8：三帧横滑，可跳过）

private struct TutorialView: View {
    let onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Frame {
        let kicker: String
        let emoji: String
        let title: String
        let lines: [String]
    }

    private let frames: [Frame] = [
        Frame(kicker: "01 / 添加", emoji: "📦", title: "把物品放进货架",
              lines: ["记下你常带的每一样东西，", "它们都会出现在物品库里。"]),
        Frame(kicker: "02 / 装包", emoji: "🎒", title: "点 + 装入背包",
              lines: ["装入后「拿东西」角标实时计数，", "点底部按钮开始出行。"]),
        Frame(kicker: "03 / 清点", emoji: "✅", title: "回家逐项打勾",
              lines: ["到家后逐项确认，", "找不到的 3 天内可补登。"]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(frames.indices, id: \.self) { index in
                    tutorialFrame(frames[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: page)

            HStack {
                Spacer()
                if page < frames.count - 1 {
                    Button("跳过 ›") { onFinish() }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GowithColor.inkTertiary)
                        .frame(minWidth: 44, minHeight: 44)
                } else {
                    Button {
                        onFinish()
                    } label: {
                        Text("开始体验 →")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(GowithColor.onPrimary)
                            .padding(.horizontal, 22)
                            .frame(minHeight: 44)
                            .background(GowithColor.ink, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, GowithMetrics.pagePadding + 8)
            .padding(.bottom, 18)

            HStack(spacing: 6) {
                ForEach(frames.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? GowithColor.ink : GowithColor.inkTertiary.opacity(0.3))
                        .frame(width: index == page ? 20 : 4, height: 4)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: page)
                }
            }
            .frame(height: 20)
            .padding(.bottom, 12)
        }
        .background(GowithColor.appBackground)
    }

    private func tutorialFrame(_ frame: Frame) -> some View {
        VStack(spacing: 0) {
            Spacer()
            Text(frame.kicker)
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
                .foregroundStyle(GowithColor.accent)
            Text(frame.emoji)
                .font(.system(size: 96))
                .padding(.vertical, 30)
            Text(frame.title)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(GowithColor.ink)
            VStack(spacing: 3) {
                ForEach(frame.lines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 13))
                        .foregroundStyle(GowithColor.inkSecondary)
                }
            }
            .padding(.top, 10)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 首启设置（规格 6.2：教学动画播完后进入，负责首个地点/背包/物品创建）

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
                    (Text("Gowith").font(.system(size: 34, weight: .heavy, design: .rounded)).tracking(-1).foregroundStyle(GowithColor.ink)
                     + Text(".").font(.system(size: 34, weight: .heavy, design: .rounded)).tracking(-1).foregroundStyle(GowithColor.accent))
                    Text("先建立你的第一个出发点")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(GowithColor.ink)
                    Text("这些信息会用于判断你在哪里，以及哪些物品属于这个家。")
                        .font(.system(size: 13))
                        .foregroundStyle(GowithColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                GowithCard {
                    VStack(alignment: .leading, spacing: 18) {
                        setupField(title: "第一个家", hint: "例如：广西玉林", text: $placeName, icon: "house.fill")
                        setupField(title: "常用背包", hint: "例如：通勤包", text: $backpackName, icon: "backpack.fill")
                        setupField(title: "一件常用物品", hint: "例如：钥匙", text: $itemName, icon: "key.fill")
                    }
                }

                GowithCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: coordinate == nil ? "location.slash" : "location.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(GowithColor.onPrimary)
                                .frame(width: 36, height: 36)
                                .background(coordinate == nil ? GowithColor.inkTertiary : GowithColor.accent, in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text("设置这个家的位置")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(GowithColor.ink)
                                Text(coordinate == nil ? "使用当前位置，或在下方地图点选位置" : "位置已准备好，之后会用于到达提醒")
                                    .font(.system(size: 11))
                                    .foregroundStyle(GowithColor.inkSecondary)
                            }
                        }
                        GowithSecondaryButton(title: coordinate == nil ? "使用当前位置" : "重新获取当前位置", systemImage: "location.fill") {
                            locationService.requestCurrentLocation()
                        }
                        if locationService.needsPermissionRecovery {
                            GowithLocationRecoveryBanner()
                        }
                        MapReader { proxy in
                            Map(position: $setupCamera) {
                                if let coordinate {
                                    MapCircle(center: coordinate, radius: 50)
                                        .foregroundStyle(GowithColor.accent.opacity(0.22))
                                        .stroke(GowithColor.accent, lineWidth: 1.5)
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
                                .font(.system(size: 11))
                                .foregroundStyle(GowithColor.inkSecondary)
                        }
                    }
                }

                GowithPrimaryButton(title: "进入 Gowith", systemImage: "arrow.right") {
                    completeSetup()
                }
                .disabled(!canComplete)
                .opacity(canComplete ? 1 : 0.45)

                if showValidation {
                    Text("请填写地点、背包和一件常用物品，并设置位置。")
                        .font(.system(size: 11))
                        .foregroundStyle(GowithColor.inkSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, 20)
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
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(GowithColor.ink)
            TextField(hint, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
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
