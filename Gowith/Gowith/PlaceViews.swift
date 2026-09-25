import CoreLocation
import MapKit
import SwiftUI

// MARK: - 进阶 · 地图与地点页（规格 5.5，深色）

struct AdvancedMapPage: View {
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    @State private var editingPlace: GowithPlace?
    @State private var showAddPlace = false
    @AppStorage("gowith.arrivalRemindersEnabled") private var arrivalRemindersEnabled = true
    @AppStorage("gowith.exitRecordingEnabled") private var exitRecordingEnabled = true

    private var places: [GowithPlace] { store.places.sorted { $0.createdAt < $1.createdAt } }
    private var hasMappedPlaces: Bool { places.contains(where: { $0.coordinate != nil }) }

    var body: some View {
        ScrollView {
            VStack(spacing: GowithMetrics.moduleSpacing) {
                if hasMappedPlaces {
                    mapCard
                } else {
                    ContentCard {
                        VStack(spacing: 8) {
                            Image(systemName: "map")
                                .font(.system(size: 26, weight: .light))
                                .foregroundStyle(GowithColor.inkTertiary)
                            Text("还没有保存地点的位置")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(GowithColor.ink)
                            Text("添加地点并设置位置后，这里显示地图。")
                                .font(.system(size: 11))
                                .foregroundStyle(GowithColor.inkSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                    }
                }

                if locationService.needsPermissionRecovery {
                    GowithLocationRecoveryBanner()
                }

                placeListCard

                fenceSettingsCard
            }
            .padding(.horizontal, GowithMetrics.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(GowithColor.appBackground)
        .sheet(isPresented: $showAddPlace) { PlaceEditorView() }
        .sheet(item: $editingPlace) { place in PlaceEditorView(place: place) }
        .onAppear {
            locationService.requestCurrentLocationIfNeeded()
        }
    }

    private var mapCard: some View {
        Map(initialPosition: .userLocation(followsHeading: false, fallback: .automatic)) {
            ForEach(places) { place in
                if let coordinate = place.coordinate {
                    if place.id == store.selectedPlaceID || locationService.isInside(place) {
                        MapCircle(center: coordinate, radius: place.radius)
                            .foregroundStyle(GowithColor.accent.opacity(0.18))
                            .stroke(GowithColor.accent, lineWidth: 1.5)
                    }
                    Annotation(place.name, coordinate: coordinate) {
                        Button { store.selectPlace(place) } label: {
                            Image(systemName: place.id == store.selectedPlaceID ? "house.fill" : "mappin.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(place.id == store.selectedPlaceID ? GowithColor.accent : Color.white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("选择地点：\(place.name)")
                    }
                }
            }
            if locationService.isAuthorized {
                UserAnnotation()
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControls { MapUserLocationButton(); MapCompass() }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: GowithMetrics.contentCardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: GowithMetrics.contentCardRadius, style: .continuous)
                .stroke(GowithColor.surfaceBorder, lineWidth: 1).allowsHitTesting(false)
        }
        .overlay(alignment: .topLeading) {
            Label("当前位置 · 50m 围栏已启用", systemImage: "location.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(GowithColor.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(10)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("地图：已保存地点与当前位置")
    }

    private var placeListCard: some View {
        ContentCard(padding: 10) {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("已保存地点 · \(places.count) 个")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(GowithColor.inkSecondary)
                    Spacer()
                    Button {
                        showAddPlace = true
                    } label: {
                        Label("添加新地点", systemImage: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(GowithColor.ink)
                            .frame(minHeight: 32)
                            .padding(.horizontal, 8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)

                ForEach(Array(places.enumerated()), id: \.element.id) { index, place in
                    placeRow(place)
                    if index < places.count - 1 {
                        Divider().padding(.leading, 50)
                    }
                }
            }
        }
    }

    private func placeRow(_ place: GowithPlace) -> some View {
        let itemCount = store.visibleItems.filter { $0.placeID == place.id }.count
        let backpackCount = store.visibleBackpacks.filter { $0.placeID == place.id }.count
        let isSelected = store.selectedPlaceID == place.id
        return Button {
            store.selectPlace(place)
            editingPlace = place
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? GowithColor.onPrimary : GowithColor.ink)
                    .frame(width: 30, height: 30)
                    .background(isSelected ? GowithColor.ink : GowithColor.softSurface, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(place.name)
                        .font(GowithFont.rowTitle)
                        .foregroundStyle(GowithColor.ink)
                        .lineLimit(1)
                    Text("物品 \(itemCount) · 背包 \(backpackCount) · 围栏 \(Int(place.radius))m")
                        .font(GowithFont.rowSubtitle)
                        .foregroundStyle(GowithColor.inkTertiary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(GowithColor.inkTertiary)
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 4)
            .frame(minHeight: GowithMetrics.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("编辑地点：\(place.name)")
    }

    private var fenceSettingsCard: some View {
        ContentCard {
            VStack(alignment: .leading, spacing: 2) {
                Text("围栏提醒")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(GowithColor.inkSecondary)
                    .padding(.bottom, 6)
                fenceToggle(
                    title: "进入地点时提醒",
                    subtitle: "进入地点约 50 米范围时发送本地通知",
                    isOn: $arrivalRemindersEnabled
                )
                Divider().padding(.leading, 40)
                fenceToggle(
                    title: "离开地点时记录",
                    subtitle: "离开出发地围栏后开始监测其他地点",
                    isOn: $exitRecordingEnabled
                )
            }
        }
    }

    private func fenceToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 18))
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
        .padding(.vertical, 8)
        .onChange(of: isOn.wrappedValue) { _, _ in
            GowithHaptics.selection()
        }
    }
}

// MARK: - S4 添加/编辑地点（规格 5.7，对应现有 PlaceEditorView 改版）

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
    private var deleteDisabledReason: String? {
        guard place != nil, !canDelete else { return nil }
        if store.places.count <= 1 { return "至少保留一个地点。" }
        return "该地点还有 \(itemCount) 件物品、\(backpackCount) 个背包，无法删除。"
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
        VStack(spacing: 0) {
            SheetNavBar(
                title: place == nil ? "添加地点" : "编辑地点",
                saveEnabled: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && coordinate != nil,
                onCancel: { dismiss() },
                onSave: { save() }
            )
            ScrollView {
                VStack(spacing: GowithMetrics.moduleSpacing) {
                    ContentCard(padding: 10) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("点按地图选点 · 虚线 = 50m 围栏")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(GowithColor.inkSecondary)
                                Spacer()
                                Button {
                                    if let current = locationService.currentCoordinate {
                                        setCoordinate(current)
                                    } else {
                                        locationService.requestCurrentLocation()
                                    }
                                } label: {
                                    Label("使用当前位置", systemImage: "location.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(GowithColor.ink)
                                        .padding(.horizontal, 10)
                                        .frame(minHeight: 28)
                                        .background(GowithColor.softSurface, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            MapReader { proxy in
                                Map(position: $cameraPosition) {
                                    if let coordinate {
                                        MapCircle(center: coordinate, radius: 50)
                                            .foregroundStyle(GowithColor.accent.opacity(0.2))
                                            .stroke(GowithColor.accent, lineWidth: 1.5)
                                        Marker(name.isEmpty ? "地点" : name, systemImage: "house.fill", coordinate: coordinate)
                                    }
                                }
                                .mapControls { MapUserLocationButton(); MapCompass() }
                                .frame(height: 260)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .simultaneousGesture(SpatialTapGesture().onEnded { value in
                                    guard let picked = proxy.convert(value.location, from: .local) else { return }
                                    coordinate = picked
                                })
                            }
                            if coordinate == nil {
                                Text("点击地图选择地点，或使用当前位置。")
                                    .font(.system(size: 11))
                                    .foregroundStyle(GowithColor.inkSecondary)
                            }
                            if !locationService.statusMessage.isEmpty {
                                Text(locationService.statusMessage)
                                    .font(.system(size: 11))
                                    .foregroundStyle(GowithColor.inkSecondary)
                            }
                        }
                    }

                    ContentCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("地点名称")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(GowithColor.inkSecondary)
                            TextField("例如：家", text: $name)
                                .font(.system(size: 15, weight: .medium))
                            Divider()
                            HStack {
                                Text("提醒范围")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(GowithColor.ink)
                                Spacer()
                                Text("约 50 米（固定）")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(GowithColor.inkTertiary)
                            }
                        }
                    }

                    if place != nil {
                        VStack(spacing: 6) {
                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                Label("删除地点", systemImage: "trash")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(canDelete ? GowithColor.accent : GowithColor.inkTertiary)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                            }
                            .buttonStyle(.plain)
                            .disabled(!canDelete)
                            if let reason = deleteDisabledReason {
                                Text(reason)
                                    .font(.system(size: 10))
                                    .foregroundStyle(GowithColor.inkTertiary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .background(GowithColor.appBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
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

    private func setCoordinate(_ value: CLLocationCoordinate2D) {
        coordinate = value
        cameraPosition = .region(MKCoordinateRegion(center: value, span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)))
    }

    private func save() {
        guard let coordinate else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
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
