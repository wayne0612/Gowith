import MapKit
import SwiftUI

struct GoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    let items: [GowithItem]
    let currentSession: OutingSession?
    @State private var showPendingAlert = false
    @State private var showHistory = false
    @State private var showPlaceChoice = false
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var initializedSelection = false
    @State private var isReviewingArrival = false

    private var displayItems: [SessionItem] {
        guard let currentSession else { return [] }
        if currentSession.status == .arrived && !isReviewingArrival { return [] }
        let items = currentSession.status == .preparing || currentSession.status == .arrived ? currentSession.items : currentSession.items.filter(\.isSelected)
        return items.sorted(by: { $0.nameSnapshot < $1.nameSnapshot })
    }

    private var pendingItems: [SessionItem] {
        displayItems.filter { $0.status == .pending }
    }

    private var unresolvedItems: [SessionItem] {
        displayItems.filter { $0.status == .unconfirmed }
    }

    /// 统计行使用的数据源：已到达但未开始检阅时，列表隐藏但统计应仍基于全部物品。
    private var statItems: [SessionItem] {
        guard let currentSession else { return [] }
        if currentSession.status == .arrived && !isReviewingArrival { return currentSession.items }
        return displayItems
    }

    private var visibleItemCount: Int {
        guard let currentSession else { return selectedItemIDs.count }
        if currentSession.status == .arrived && !isReviewingArrival {
            return currentSession.items.count
        }
        return displayItems.count
    }

    var body: some View {
        NavigationStack {
          ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if currentSession?.status == .away {
                    tripMap
                }
                taskCard
                if currentSession?.status == .arrived {
                    tripMap
                }
                if currentSession == nil, !items.isEmpty {
                    GowithSectionHeader(title: "出门清单", trailing: "\(selectedItemIDs.count) 件已选")
                    selectionList
                } else if displayItems.isEmpty {
                    if currentSession?.status == .arrived && !isReviewingArrival {
                        arrivalReadyState
                    } else {
                        emptyState
                    }
                } else {
                    GowithSectionHeader(title: sectionTitle, trailing: "\(displayItems.count) 件")
                    itemList
                }
            }
            .padding(.horizontal, GowithMetrics.pagePadding)
            .padding(.top, 20)
            .padding(.bottom, 24)
          }
          .scrollIndicators(.hidden)
          .background(GowithColor.appBackground)
          .safeAreaInset(edge: .top, spacing: 0) {
              GowithTopBar(pageTitle: currentSession?.status == .checking ? "回家清点" : "本次出行") {
                  Button("历史记录", systemImage: "clock.arrow.circlepath") { showHistory = true }
                      .labelStyle(.iconOnly)
                      .foregroundStyle(GowithColor.primary)
                      .frame(width: 44, height: 44)
                      .background(GowithColor.surface, in: Circle())
                      .accessibilityLabel("历史记录")
              }
              .padding(.horizontal, GowithMetrics.pagePadding)
              .padding(.top, 12)
              .background(GowithColor.appBackground)
          }
          .safeAreaInset(edge: .bottom, spacing: 0) {
              if let currentSession, currentSession.status == .arrived || currentSession.status == .checking {
                  bottomAction
                      .padding(.horizontal, GowithMetrics.pagePadding)
                      .padding(.top, 10)
                      .padding(.bottom, 8)
                      .background(GowithColor.appBackground)
                      .transition(.move(edge: .bottom).combined(with: .opacity))
              }
          }
          .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: currentSession?.status)
          .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: isReviewingArrival)
          .onAppear {
              guard !initializedSelection else { return }
              selectedItemIDs = Set(items.map(\.id))
              initializedSelection = true
          }
          .sheet(isPresented: $showHistory) { HistoryView() }
          .alert("还有物品待确认", isPresented: $showPendingAlert) {
              Button("返回核对", role: .cancel) {}
              Button("继续完成") { completeSession() }
          } message: {
              Text("还有 \(pendingItems.count + unresolvedItems.count) 件物品待确认。继续完成后，它们会保留 3 天，期间可以在历史记录中补充确认。")
          }
          .confirmationDialog("确认到达地点", isPresented: $showPlaceChoice, titleVisibility: .visible) {
              ForEach(store.places) { place in
                  Button(place.name) { markArrived(at: place) }
              }
              Button("取消", role: .cancel) {}
          } message: {
              Text("选择当前位置附近的已保存地点。确认后仍需手动选择放入哪些物品。")
          }
        }
    }

    private var taskCard: some View {
        GowithFocusField(color: taskSceneColor, height: 278) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(stateTitle)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(GowithColor.primary)
                        Text(stateSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(GowithColor.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Image(systemName: stateIcon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(GowithColor.primary)
                        .frame(width: 52, height: 52)
                        .background(.white.opacity(0.42))
                        .clipShape(Circle())
                }

                if let currentSession,
                   let backpack = store.backpacks.first(where: { $0.id == currentSession.backpackID }) {
                    HStack(spacing: 12) {
                        GowithBackpackPreview(backpack: backpack, size: 48)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(backpack.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(GowithColor.primary)
                            Text("来自「\(currentSession.originPlaceNameSnapshot ?? "当前地点")」 · \(currentSession.items.count) 件物品")
                                .font(.caption)
                                .foregroundStyle(GowithColor.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background(.white.opacity(0.34), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                if currentSession != nil {
                    HStack(spacing: 16) {
                        stat(value: "\(visibleItemCount)", label: "件物品")
                        Divider().frame(height: 30)
                        stat(value: "\(statItems.filter { $0.status == .pending || $0.status == .unconfirmed }.count)", label: "待确认")
                        Divider().frame(height: 30)
                        stat(value: "\(statItems.filter { $0.status == .lost }.count)", label: "已遗失")
                    }
                } else {
                    HStack(spacing: 16) {
                        stat(value: "\(selectedItemIDs.count)", label: "件物品已选")
                        Divider().frame(height: 30)
                        stat(value: "\(items.count)", label: "物品库")
                    }
                }

                if currentSession?.status != .arrived && currentSession?.status != .checking {
                    primaryAction
                }
                if currentSession?.status == .away {
                    GowithSecondaryButton(title: "手动确认到家或地点", systemImage: "mappin.and.ellipse") {
                        showPlaceChoice = true
                    }
                }
                if currentSession?.status == .arrived {
                    Text(isReviewingArrival
                         ? "选择要放在「\(currentSession?.destinationPlaceNameSnapshot ?? "该地点")」的物品；未选择的物品会继续随身携带。"
                         : "已到达「\(currentSession?.destinationPlaceNameSnapshot ?? "该地点")」。准备好后，再开始检阅本次物品。")
                        .font(.footnote)
                        .foregroundStyle(GowithColor.secondary)
                }
            }
            .padding(20)
        }
    }

    private var tripMap: some View {
        Map(initialPosition: .userLocation(followsHeading: false, fallback: .automatic)) {
            ForEach(store.places) { place in
                if let coordinate = place.coordinate {
                    Marker(place.name, systemImage: "house.fill", coordinate: coordinate)
                }
            }
            if locationService.authorizationStatus == .authorizedAlways || locationService.authorizationStatus == .authorizedWhenInUse {
                UserAnnotation()
            }
        }
        .mapControls { MapUserLocationButton(); MapCompass() }
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(GowithColor.border.opacity(0.7), lineWidth: 1)
        }
        .overlay(alignment: .topLeading) {
            Label("当前位置与已保存地点", systemImage: "location.fill")
                .font(.caption.weight(.medium))
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(GowithColor.surface.opacity(0.94), in: Capsule())
                .padding(12)
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("本次行程地图")
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title3.weight(.semibold))
            Text(label).font(.caption).foregroundStyle(GowithColor.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var primaryAction: some View {
        switch currentSession?.status {
        case nil, .completed:
            GowithBottomAction(title: "开始一次出门", systemImage: "arrow.up.right") { startSession() }
        case .preparing:
            GowithBottomAction(title: "确认带上这些物品", systemImage: "checkmark") { confirmLeaving() }
        case .away:
            GowithBottomAction(title: "我回来了，开始清点", systemImage: "house") { startChecking() }
        case .arrived, .checking:
            EmptyView()
        }
    }

    @ViewBuilder
    private var bottomAction: some View {
        if currentSession?.status == .arrived {
            GowithBottomAction(
                title: isReviewingArrival ? "完成放入目的地" : "开始检阅",
                systemImage: isReviewingArrival ? "shippingbox.fill" : "checklist"
            ) {
                if isReviewingArrival { completeArrival() }
                else { beginArrivalReview() }
            }
        } else {
            GowithBottomAction(title: "完成清点", systemImage: "checkmark.circle") { requestCompletion() }
        }
    }

    private var itemList: some View {
        VStack(spacing: 0) {
            ForEach(Array(displayItems.enumerated()), id: \.element.id) { index, item in
                SessionItemRow(
                    item: item,
                    isPreparing: currentSession?.status == .preparing || (currentSession?.status == .arrived && isReviewingArrival),
                    isChecking: currentSession?.status == .checking
                ) {
                    update(item, to: .returned)
                } onPending: {
                    update(item, to: .pending)
                } onToggleSelection: {
                    item.isSelected.toggle()
                    store.save()
                }
                if index < displayItems.count - 1 { Divider().padding(.leading, 62) }
            }
        }
    }

    private var selectionList: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                Button {
                    if selectedItemIDs.contains(item.id) { selectedItemIDs.remove(item.id) }
                    else { selectedItemIDs.insert(item.id) }
                } label: {
                    HStack(spacing: 14) {
                        ItemThumbnail(fileName: item.imageFileName, symbolName: item.symbolName, size: 48)
                        Text(item.name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(GowithColor.primary)
                        Spacer()
                        Image(systemName: selectedItemIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 25, weight: .medium))
                            .foregroundStyle(selectedItemIDs.contains(item.id) ? GowithColor.primary : GowithColor.tertiary)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .frame(minHeight: 74)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if index < items.count - 1 { Divider().padding(.leading, 62) }
            }
        }
    }

    private var emptyState: some View {
        GowithStatusScene(
            color: GowithColor.sceneMint,
            systemImage: "bag",
            title: "还没有本次出门清单",
            message: "开始一次出门后，从物品库选择要带上的东西。"
        )
    }

    private var arrivalReadyState: some View {
        GowithStatusScene(
            color: GowithColor.sceneMint,
            systemImage: "checkmark.circle.fill",
            title: "已到达，可以开始检阅",
            message: "先处理眼前的事情，准备好后点击底部按钮，再决定哪些物品放在这里。"
        )
    }

    private var stateTitle: String {
        switch currentSession?.status {
        case .preparing: return "准备出门"
        case .away: return "出门中"
        case .arrived: return "已到达地点"
        case .checking: return "回家清点"
        case .completed, nil: return "准备出发"
        }
    }

    private var stateSubtitle: String {
        switch currentSession?.status {
        case .preparing: return "选好今天要带的物品"
        case .away: return "\(currentSession?.items.count ?? 0) 件物品已记录，回来后逐项清点"
        case .arrived: return isReviewingArrival ? "选择要放下的物品" : "已到达，准备开始检阅"
        case .checking: return "确认每件物品是否带回"
        case .completed, nil: return "用一分钟确认随身物品"
        }
    }

    private var stateIcon: String {
        switch currentSession?.status {
        case .preparing: return "checklist"
        case .away: return "figure.walk"
        case .arrived: return "mappin.and.ellipse"
        case .checking: return "house"
        case .completed, nil: return "sparkles"
        }
    }

    private var taskSceneColor: Color {
        switch currentSession?.status {
        case .away: return GowithColor.sceneSky
        case .arrived: return GowithColor.sceneMint
        case .checking: return GowithColor.sceneAmber
        case .preparing: return GowithColor.sceneViolet
        case .completed, nil: return GowithColor.sceneMint
        }
    }

    private func startSession() {
        guard !selectedItemIDs.isEmpty else { return }
        let session = OutingSession()
        items.filter { selectedItemIDs.contains($0.id) }.forEach { item in
            let sessionItem = SessionItem(item: item)
            session.items.append(sessionItem)
        }
        session.status = .away
        session.wentOutAt = .now
        store.sessions.append(session)
        store.save()
    }

    private func confirmLeaving() {
        guard let session = currentSession else { return }
        session.items.removeAll(where: { !$0.isSelected })
        guard !session.items.isEmpty else { return }
        session.status = .away
        session.wentOutAt = .now
        store.save()
    }

    private func startChecking() {
        guard let session = currentSession else { return }
        locationService.stopMonitoring()
        session.status = .checking
        session.checkingStartedAt = .now
        store.save()
    }

    private func update(_ item: SessionItem, to status: SessionItemStatus) {
        item.status = status
        item.checkedAt = .now
        if status == .pending { item.pendingSince = item.pendingSince ?? currentSession?.checkingStartedAt ?? .now }
        if status == .returned { item.pendingSince = nil }
        store.save()
    }

    private func requestCompletion() {
        if !pendingItems.isEmpty || !unresolvedItems.isEmpty { showPendingAlert = true }
        else { completeSession() }
    }

    private func completeSession() {
        guard let session = currentSession else { return }
        for item in unresolvedItems {
            item.status = .pending
            item.pendingSince = session.checkingStartedAt ?? .now
        }
        session.status = .completed
        session.completedAt = .now
        // 已带回与待确认的物品都归入出发地；待确认物品之后仍可在历史记录中改为遗失，
        // 避免物品 placeID 悬空为 nil、在所有界面不可见。
        let homeID = session.originPlaceID ?? store.places.first?.id
        if let homeID {
            for sessionItem in session.items where sessionItem.status == .returned || sessionItem.status == .pending {
                if let original = store.items.first(where: { $0.id == sessionItem.itemID }) { original.placeID = homeID }
            }
            if let backpack = store.backpacks.first(where: { $0.id == session.backpackID }) { backpack.placeID = homeID }
        }
        locationService.stopMonitoring()
        store.save()
    }

    private var sectionTitle: String {
        switch currentSession?.status {
        case .checking: return "回家清点"
        case .arrived: return "选择放入的物品"
        default: return "本次物品"
        }
    }

    private func markArrived(at place: GowithPlace) {
        guard let session = currentSession, session.status == .away else { return }
        session.applyArrival(at: place)
        isReviewingArrival = false
        locationService.stopMonitoring()
        store.save()
    }

    private func beginArrivalReview() {
        guard let session = currentSession, session.status == .arrived else { return }
        for item in session.items { item.isSelected = true }
        isReviewingArrival = true
    }

    private func completeArrival() {
        guard let session = currentSession, let destinationID = session.destinationPlaceID,
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
        store.selectPlace(destination)
        if let backpack { store.selectBackpack(backpack) }
        store.save()
    }
}

struct SessionItemRow: View {
    let item: SessionItem
    let isPreparing: Bool
    let isChecking: Bool
    let onReturned: () -> Void
    let onPending: () -> Void
    let onToggleSelection: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ItemThumbnail(fileName: item.imageFileNameSnapshot, symbolName: item.symbolNameSnapshot, size: 48)
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.nameSnapshot)
                        .font(.body.weight(.medium))
                        .foregroundStyle(GowithColor.primary)
                    if item.status == .pending, let date = item.pendingSince {
                        Text("请在 \(date.addingTimeInterval(3 * 24 * 60 * 60), format: .dateTime.month().day()) 前确认")
                            .font(.caption)
                            .foregroundStyle(GowithColor.secondary)
                    } else if !isChecking {
                        Text("出门清单")
                            .font(.caption)
                            .foregroundStyle(GowithColor.tertiary)
                    }
                }
                Spacer()
                if isPreparing {
                    Button(action: onToggleSelection) {
                        Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 25, weight: .medium))
                            .foregroundStyle(item.isSelected ? GowithColor.primary : GowithColor.tertiary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                } else if isChecking {
                    Button {
                        if item.status == .returned { onPending() } else { onReturned() }
                    } label: {
                        HStack(spacing: 8) {
                            Text(item.status == .returned ? "已带回" : "待确认")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(item.status == .returned ? GowithColor.primary : GowithColor.secondary)
                            Image(systemName: item.status == .returned ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 25, weight: .medium))
                                .foregroundStyle(item.status == .returned ? GowithColor.success : GowithColor.tertiary)
                        }
                        .frame(minWidth: 92, minHeight: 44, alignment: .trailing)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.status == .returned ? "已带回，点击改为待确认" : "待确认，点击标记为已带回")
                } else {
                    GowithStatusBadge(status: item.status)
                }
            }
            .frame(minHeight: 58)
        }
        .padding(.horizontal, 4)
        .frame(minHeight: 72)
        .contentShape(Rectangle())
    }
}
