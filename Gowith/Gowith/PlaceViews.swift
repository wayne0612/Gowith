import CoreLocation
import MapKit
import SwiftUI

struct PlacePickerMenu: View {
    @EnvironmentObject private var store: GowithStore

    var body: some View {
        Menu {
            ForEach(store.places) { place in
                Button {
                    store.selectPlace(place)
                } label: {
                    if place.id == store.selectedPlaceID {
                        Label(place.name, systemImage: "checkmark")
                    } else {
                        Text(place.name)
                    }
                }
            }
        } label: {
            Label(store.selectedPlace?.name ?? "地点", systemImage: "mappin.and.ellipse")
                .font(.caption.weight(.semibold))
                .foregroundStyle(GowithColor.primary)
                .padding(.horizontal, 10)
                .frame(minHeight: 36)
                .background(GowithColor.softSurface.opacity(0.86), in: Capsule())
                .overlay { Capsule().stroke(GowithColor.border, lineWidth: 1) }
                .lineLimit(1)
                .frame(maxWidth: 150, alignment: .leading)
        }
        .accessibilityLabel("当前地点：\(store.selectedPlace?.name ?? "未选择")")
    }
}

struct PlacesMapView: View {
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    let onTakeItems: () -> Void
    @State private var editingPlace: GowithPlace?
    @State private var showPlaceEditor = false
    @State private var showHistory = false
    @State private var selectedPlace: GowithPlace?
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var mapPlaces: [GowithPlace] { store.places.sorted { $0.createdAt < $1.createdAt } }
    private var latestCompletedSession: OutingSession? {
        store.sessions.filter { $0.status == .completed }.max {
            ($0.completedAt ?? $0.startedAt) < ($1.completedAt ?? $1.startedAt)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                if mapPlaces.contains(where: { $0.coordinate != nil }) {
                    Map(position: $cameraPosition) {
                        ForEach(mapPlaces) { place in
                            if let coordinate = place.coordinate {
                                if shouldShowRadius(for: place) {
                                    MapCircle(center: coordinate, radius: place.radius)
                                        .foregroundStyle(GowithColor.success.opacity(0.16))
                                        .stroke(GowithColor.success, lineWidth: 1.5)
                                }
                                Annotation(place.name, coordinate: coordinate) {
                                    Button { select(place) } label: {
                                        Image(systemName: "house.fill")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundStyle(place.id == selectedPlace?.id ? .black : .white)
                                            .frame(width: 44, height: 44)
                                            .background(place.id == selectedPlace?.id ? GowithColor.success : GowithColor.primary, in: Circle())
                                            .overlay { Circle().stroke(.white, lineWidth: 3) }
                                            .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("打开地点：\(place.name)")
                                }
                            }
                        }
                        if locationService.isAuthorized { UserAnnotation() }
                    }
                    .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                    .mapControls { MapUserLocationButton(); MapCompass() }
                    .ignoresSafeArea(edges: .bottom)
                    .overlay(alignment: .bottomTrailing) {
                        Button { locationService.requestCurrentLocation() } label: {
                            Image(systemName: "location.fill")
                                .foregroundStyle(GowithColor.onPrimary)
                                .frame(width: 44, height: 44)
                                .background(GowithColor.primary, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(16)
                        .accessibilityLabel("定位到当前位置")
                    }
                } else {
                    mapEmptyState
                }

                VStack(spacing: 0) {
                    brandBar
                    if let latestCompletedSession {
                        completionBanner(for: latestCompletedSession)
                            .padding(.top, 12)
                    }
                    Spacer()
                    if !locationService.statusMessage.isEmpty {
                        Text(locationService.statusMessage)
                            .font(.caption)
                            .foregroundStyle(GowithColor.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(GowithColor.surface.opacity(0.92), in: Capsule())
                            .overlay { Capsule().stroke(GowithColor.border, lineWidth: 1) }
                            .padding(.bottom, 12)
                    }
                }
                .padding(.horizontal, GowithMetrics.pagePadding)
                .padding(.top, 12)
                .allowsHitTesting(true)
            }
            .background(GowithColor.appBackground)
            .sheet(isPresented: $showPlaceEditor) { PlaceEditorView() }
            .sheet(item: $editingPlace) { place in PlaceEditorView(place: place) }
            .sheet(item: $selectedPlace) { place in
                PlaceInventorySheet(place: place, onTakeItems: onTakeItems) {
                    editingPlace = place
                }
                .presentationDetents([.height(230), .medium, .large])
                .presentationDragIndicator(.visible)
            }
            .onAppear {
                locationService.requestCurrentLocationIfNeeded()
                setOverviewCamera()
            }
            .onChange(of: mapPlaces.count) { _, _ in setOverviewCamera() }
            .sheet(isPresented: $showHistory) { HistoryView() }
        }
    }

    private func completionBanner(for session: OutingSession) -> some View {
        let pending = session.items.filter { $0.status == .pending }.count
        let lost = session.items.filter { $0.status == .lost }.count
        let summary: String = if lost > 0 {
            "\(lost) 件物品标记为遗失"
        } else if pending > 0 {
            "\(pending) 件物品仍待确认"
        } else {
            "全部物品已完成清点"
        }

        return GowithStatusScene(
            color: lost > 0 ? GowithColor.sceneCoral : pending > 0 ? GowithColor.sceneAmber : GowithColor.sceneMint,
            systemImage: lost > 0 ? "exclamationmark.circle.fill" : pending > 0 ? "clock.fill" : "checkmark.circle.fill",
            title: "最近一次出行已完成",
            message: summary,
            actionTitle: "查看",
            action: { showHistory = true }
        )
    }

    private var brandBar: some View {
        GowithTopBar(pageTitle: "地图") {
            Button { showPlaceEditor = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .medium))
                    .frame(width: 44, height: 44)
                    .background(GowithColor.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("添加地点")
        }
    }

    private var mapEmptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "map").font(.system(size: 40, weight: .light)).foregroundStyle(GowithColor.secondary)
            Text("还没有保存地点").font(.title3.weight(.semibold))
            Text("添加一个家，开始管理你的物品").font(.subheadline).foregroundStyle(GowithColor.secondary)
            GowithPrimaryButton(title: "添加地点", systemImage: "plus") { showPlaceEditor = true }
                .frame(maxWidth: 240)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func select(_ place: GowithPlace) {
        store.selectPlace(place)
        selectedPlace = place
        guard let coordinate = place.coordinate else { return }
        cameraPosition = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)))
    }

    private func shouldShowRadius(for place: GowithPlace) -> Bool {
        place.id == selectedPlace?.id || locationService.isInside(place)
    }

    private func setOverviewCamera() {
        let coordinates = mapPlaces.compactMap(\.coordinate)
        guard let first = coordinates.first else { return }
        guard coordinates.count > 1 else {
            cameraPosition = .region(MKCoordinateRegion(center: first, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)))
            return
        }
        let minLatitude = coordinates.map(\.latitude).min() ?? first.latitude
        let maxLatitude = coordinates.map(\.latitude).max() ?? first.latitude
        let minLongitude = coordinates.map(\.longitude).min() ?? first.longitude
        let maxLongitude = coordinates.map(\.longitude).max() ?? first.longitude
        let center = CLLocationCoordinate2D(latitude: (minLatitude + maxLatitude) / 2, longitude: (minLongitude + maxLongitude) / 2)
        let span = MKCoordinateSpan(latitudeDelta: max((maxLatitude - minLatitude) * 1.7, 0.02), longitudeDelta: max((maxLongitude - minLongitude) * 1.7, 0.02))
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

struct PlaceInventorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    let place: GowithPlace
    let onTakeItems: () -> Void
    let onEdit: () -> Void

    private var items: [GowithItem] { store.visibleItems.filter { $0.placeID == place.id } }
    private var backpacks: [GowithBackpack] { store.visibleBackpacks.filter { $0.placeID == place.id } }
    private var distanceText: String {
        guard let distance = locationService.distance(to: place) else { return "正在确认当前位置" }
        return distance <= place.radius ? "已在地点范围内" : "距离当前位置约 \(Int(distance)) 米"
    }
    private var canManage: Bool { locationService.isInside(place) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 14) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(GowithColor.primary)
                            .frame(width: 56, height: 56)
                            .background(canManage ? GowithColor.sceneMint : GowithColor.softSurface, in: Circle())
                        VStack(alignment: .leading, spacing: 5) {
                            Text(place.name)
                                .font(.title2.weight(.semibold))
                            Text(distanceText)
                                .font(.footnote)
                                .foregroundStyle(GowithColor.secondary)
                        }
                        Spacer(minLength: 4)
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .frame(width: 44, height: 44)
                                .foregroundStyle(GowithColor.primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("编辑\(place.name)")
                    }

                    if canManage {
                        Button {
                            dismiss()
                            onTakeItems()
                        } label: {
                            Label("去家里拿物品", systemImage: "arrow.down.to.line.compact")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(GowithColor.primary)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(GowithColor.sceneMint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    } else {
                        GowithStatusScene(
                            color: GowithColor.sceneAmber,
                            systemImage: "lock.fill",
                            title: "到达后才能管理",
                            message: "进入该地点约 50 米范围内，才可以拿取或调整这里的物品。"
                        )
                    }

                    inventorySection(title: "背包库", count: backpacks.count) {
                        if backpacks.isEmpty {
                            emptyInventoryText("这里还没有背包")
                        } else {
                            ForEach(backpacks) { backpack in
                                HStack(spacing: 12) {
                                    GowithBackpackPreview(backpack: backpack, size: 42)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(backpack.name)
                                            .font(.body.weight(.medium))
                                        Text("\(backpack.itemIDs.count) 件物品")
                                            .font(.caption)
                                            .foregroundStyle(GowithColor.secondary)
                                    }
                                    Spacer()
                                }
                                .frame(minHeight: GowithMetrics.rowHeight)
                            }
                        }
                    }

                    inventorySection(title: "物品库", count: items.count) {
                        if items.isEmpty {
                            emptyInventoryText("这里还没有物品")
                        } else {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                HStack(spacing: 14) {
                                    ItemThumbnail(fileName: item.imageFileName, symbolName: item.symbolName, size: 48)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .font(.body.weight(.medium))
                                        Text(item.lostCount > 0 ? "累计遗失 \(item.lostCount) 次" : "在这个地点保存")
                                            .font(.caption)
                                            .foregroundStyle(GowithColor.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: canManage ? "checkmark.circle.fill" : "lock.fill")
                                        .foregroundStyle(canManage ? GowithColor.primary : GowithColor.tertiary)
                                        .frame(width: 44, height: 44)
                                }
                                .frame(minHeight: GowithMetrics.rowHeight)
                                if index < items.count - 1 {
                                    Divider().padding(.leading, 62)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, GowithMetrics.pagePadding)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(GowithColor.appBackground)
            .navigationTitle("地点详情")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func inventorySection<Content: View>(title: String, count: Int, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline.weight(.semibold))
                Spacer()
                Text("\(count)")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(GowithColor.tertiary)
            }
            content()
        }
    }

    private func emptyInventoryText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(GowithColor.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
    }
}

struct PlaceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    let place: GowithPlace?
    @State private var name: String
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition
    @State private var showDeleteConfirmation = false

    private var itemCount: Int { store.visibleItems.filter { $0.placeID == place?.id }.count }
    private var backpackCount: Int { store.visibleBackpacks.filter { $0.placeID == place?.id }.count }
    private var canDelete: Bool {
        guard place != nil else { return false }
        return store.places.count > 1 && itemCount == 0 && backpackCount == 0
    }

    init(place: GowithPlace? = nil) {
        self.place = place
        _name = State(initialValue: place?.name ?? "")
        let coordinate = place?.coordinate
        _coordinate = State(initialValue: coordinate)
        if let coordinate {
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008))
            _cameraPosition = State(initialValue: .region(region))
        } else {
            _cameraPosition = State(initialValue: .automatic)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("地点信息") {
                    TextField("地点名称，例如：家", text: $name)
                    LabeledContent("提醒范围", value: "约 50 米")
                }
                Section("地图位置") {
                    MapReader { proxy in
                        Map(position: $cameraPosition) {
                            if let coordinate {
                                MapCircle(center: coordinate, radius: 50)
                                    .foregroundStyle(GowithColor.success.opacity(0.35))
                                    .stroke(GowithColor.primary.opacity(0.3), lineWidth: 1)
                                Marker(name.isEmpty ? "地点" : name, systemImage: "house.fill", coordinate: coordinate)
                            }
                        }
                        .mapControls { MapUserLocationButton(); MapCompass() }
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .simultaneousGesture(SpatialTapGesture().onEnded { value in
                            guard let picked = proxy.convert(value.location, from: .local) else { return }
                            coordinate = picked
                        })
                    }
                    Button("使用当前位置", systemImage: "location.fill") {
                        if let current = locationService.currentCoordinate {
                            setCoordinate(current)
                        } else {
                            locationService.requestCurrentLocation()
                        }
                    }
                    if coordinate == nil {
                        Text("点击地图选择地点，或使用当前位置。")
                            .font(.footnote).foregroundStyle(GowithColor.secondary)
                    }
                    if !locationService.statusMessage.isEmpty {
                        Text(locationService.statusMessage).font(.footnote).foregroundStyle(GowithColor.secondary)
                    }
                }
                if place != nil {
                    Section {
                        Button("删除地点", systemImage: "trash", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                        .disabled(!canDelete)
                        if !canDelete {
                            Text(store.places.count <= 1 ? "需要保留至少一个地点。" : "该地点还有物品或背包时无法删除。")
                                .font(.footnote)
                                .foregroundStyle(GowithColor.secondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(GowithColor.appBackground)
            .navigationTitle(place == nil ? "添加地点" : "编辑地点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || coordinate == nil)
                }
            }
            .onChange(of: locationService.currentCoordinate?.latitude) { _, _ in
                guard coordinate == nil, let current = locationService.currentCoordinate else { return }
                setCoordinate(current)
            }
            .confirmationDialog("删除「\(place?.name ?? "")」？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("删除地点", role: .destructive) { deletePlace() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("删除后无法恢复。")
            }
        }
    }

    private func setCoordinate(_ value: CLLocationCoordinate2D) {
        coordinate = value
        cameraPosition = .region(MKCoordinateRegion(center: value, span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)))
    }

    private func save() {
        guard let coordinate else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let place {
            place.name = trimmed
            place.latitude = coordinate.latitude
            place.longitude = coordinate.longitude
        } else {
            let newPlace = GowithPlace(name: trimmed, latitude: coordinate.latitude, longitude: coordinate.longitude, radius: 50)
            store.places.append(newPlace)
            store.selectPlace(newPlace)
        }
        store.save()
        dismiss()
    }

    private func deletePlace() {
        guard let place, canDelete else { return }
        store.places.removeAll { $0.id == place.id }
        if store.selectedPlaceID == place.id, let first = store.places.first {
            store.selectPlace(first)
        }
        store.save()
        dismiss()
    }
}
