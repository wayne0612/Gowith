import Combine
import CoreLocation
import Foundation
import UIKit

enum SessionStatus: String, Codable { case preparing, away, arrived, checking, completed }
enum SessionItemStatus: String, Codable { case unconfirmed, returned, pending, lost, stored, carried }

final class GowithPlace: Identifiable, Codable, ObservableObject {
    let id: UUID
    @Published var name: String
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var radius: Double
    let createdAt: Date

    init(name: String, latitude: Double? = nil, longitude: Double? = nil, radius: Double = 50) {
        id = UUID()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        createdAt = .now
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum CodingKeys: String, CodingKey { case id, name, latitude, longitude, radius, createdAt }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(latitude, forKey: .latitude)
        try c.encode(longitude, forKey: .longitude)
        try c.encode(radius, forKey: .radius)
        try c.encode(createdAt, forKey: .createdAt)
    }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
        radius = try c.decodeIfPresent(Double.self, forKey: .radius) ?? 50
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
    }
}

final class GowithItem: Identifiable, Codable, ObservableObject {
    let id: UUID
    @Published var name: String
    @Published var symbolName: String
    @Published var imageFileName: String?
    @Published var categoryID: UUID?
    @Published var placeID: UUID?
    let createdAt: Date
    @Published var lostCount: Int
    @Published var isArchived: Bool

    init(name: String, symbolName: String = "square.dashed", imageFileName: String? = nil, categoryID: UUID? = nil, placeID: UUID? = nil) {
        id = UUID(); self.name = name; self.symbolName = symbolName; self.imageFileName = imageFileName
        self.categoryID = categoryID
        self.placeID = placeID
        createdAt = .now; lostCount = 0; isArchived = false
    }
    enum CodingKeys: String, CodingKey { case id, name, symbolName, imageFileName, categoryID, placeID, createdAt, lostCount, isArchived }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(name, forKey: .name); try c.encode(symbolName, forKey: .symbolName)
        try c.encode(imageFileName, forKey: .imageFileName); try c.encode(categoryID, forKey: .categoryID); try c.encode(createdAt, forKey: .createdAt)
        try c.encode(placeID, forKey: .placeID)
        try c.encode(lostCount, forKey: .lostCount); try c.encode(isArchived, forKey: .isArchived)
    }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id); name = try c.decode(String.self, forKey: .name)
        symbolName = try c.decode(String.self, forKey: .symbolName); imageFileName = try c.decodeIfPresent(String.self, forKey: .imageFileName)
        categoryID = try c.decodeIfPresent(UUID.self, forKey: .categoryID)
        placeID = try c.decodeIfPresent(UUID.self, forKey: .placeID)
        createdAt = try c.decode(Date.self, forKey: .createdAt); lostCount = try c.decode(Int.self, forKey: .lostCount)
        isArchived = try c.decode(Bool.self, forKey: .isArchived)
    }
}

final class GowithCategory: Identifiable, Codable, ObservableObject {
    let id: UUID
    @Published var name: String
    @Published var symbolName: String
    @Published var sortOrder: Int
    let createdAt: Date

    init(name: String, symbolName: String = "square.grid.2x2", sortOrder: Int = 0) {
        id = UUID(); self.name = name; self.symbolName = symbolName; self.sortOrder = sortOrder; createdAt = .now
    }

    enum CodingKeys: String, CodingKey { case id, name, symbolName, sortOrder, createdAt }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(name, forKey: .name)
        try c.encode(symbolName, forKey: .symbolName); try c.encode(sortOrder, forKey: .sortOrder); try c.encode(createdAt, forKey: .createdAt)
    }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id); name = try c.decode(String.self, forKey: .name)
        symbolName = try c.decode(String.self, forKey: .symbolName); sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }
}

final class GowithBackpack: Identifiable, Codable, ObservableObject {
    let id: UUID
    @Published var name: String
    @Published var symbolName: String
    @Published var imageFileName: String?
    @Published var itemIDs: [UUID]
    @Published var placeID: UUID?
    let createdAt: Date

    init(name: String, symbolName: String = "backpack.fill", imageFileName: String? = nil, placeID: UUID? = nil) {
        id = UUID(); self.name = name; self.symbolName = symbolName; self.imageFileName = imageFileName; self.placeID = placeID; itemIDs = []; createdAt = .now
    }

    enum CodingKeys: String, CodingKey { case id, name, symbolName, imageFileName, itemIDs, placeID, createdAt }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(name, forKey: .name); try c.encode(symbolName, forKey: .symbolName)
        try c.encode(imageFileName, forKey: .imageFileName)
        try c.encode(placeID, forKey: .placeID)
        try c.encode(itemIDs, forKey: .itemIDs); try c.encode(createdAt, forKey: .createdAt)
    }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id); name = try c.decode(String.self, forKey: .name)
        symbolName = try c.decode(String.self, forKey: .symbolName); imageFileName = try c.decodeIfPresent(String.self, forKey: .imageFileName)
        itemIDs = try c.decodeIfPresent([UUID].self, forKey: .itemIDs) ?? []
        placeID = try c.decodeIfPresent(UUID.self, forKey: .placeID)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }
}

final class SessionItem: Identifiable, Codable, ObservableObject {
    let id: UUID
    let itemID: UUID
    let nameSnapshot: String
    let symbolNameSnapshot: String
    let imageFileNameSnapshot: String?
    @Published var status: SessionItemStatus
    @Published var pendingSince: Date?
    @Published var checkedAt: Date?
    @Published var lostAt: Date?
    @Published var isSelected: Bool
    @Published var destinationPlaceID: UUID?

    init(item: GowithItem) {
        id = UUID(); itemID = item.id; nameSnapshot = item.name; symbolNameSnapshot = item.symbolName
        imageFileNameSnapshot = LocalImageStore.copy(fileName: item.imageFileName) ?? item.imageFileName
        status = .unconfirmed; isSelected = true; destinationPlaceID = nil
    }
    enum CodingKeys: String, CodingKey { case id, itemID, nameSnapshot, symbolNameSnapshot, imageFileNameSnapshot, status, pendingSince, checkedAt, lostAt, isSelected, destinationPlaceID }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(itemID, forKey: .itemID); try c.encode(nameSnapshot, forKey: .nameSnapshot)
        try c.encode(symbolNameSnapshot, forKey: .symbolNameSnapshot); try c.encode(imageFileNameSnapshot, forKey: .imageFileNameSnapshot)
        try c.encode(status, forKey: .status); try c.encode(pendingSince, forKey: .pendingSince); try c.encode(checkedAt, forKey: .checkedAt)
        try c.encode(lostAt, forKey: .lostAt); try c.encode(isSelected, forKey: .isSelected)
        try c.encode(destinationPlaceID, forKey: .destinationPlaceID)
    }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id); itemID = try c.decode(UUID.self, forKey: .itemID)
        nameSnapshot = try c.decode(String.self, forKey: .nameSnapshot); symbolNameSnapshot = try c.decode(String.self, forKey: .symbolNameSnapshot)
        imageFileNameSnapshot = try c.decodeIfPresent(String.self, forKey: .imageFileNameSnapshot); status = try c.decode(SessionItemStatus.self, forKey: .status)
        pendingSince = try c.decodeIfPresent(Date.self, forKey: .pendingSince); checkedAt = try c.decodeIfPresent(Date.self, forKey: .checkedAt)
        lostAt = try c.decodeIfPresent(Date.self, forKey: .lostAt); isSelected = try c.decodeIfPresent(Bool.self, forKey: .isSelected) ?? true
        destinationPlaceID = try c.decodeIfPresent(UUID.self, forKey: .destinationPlaceID)
    }
}

final class OutingSession: Identifiable, Codable, ObservableObject {
    let id: UUID
    let startedAt: Date
    var backpackID: UUID?
    var backpackNameSnapshot: String?
    var originPlaceID: UUID?
    var originPlaceNameSnapshot: String?
    var destinationPlaceID: UUID?
    var destinationPlaceNameSnapshot: String?
    var arrivedAt: Date?
    var hasExitedOrigin: Bool
    var wentOutAt: Date?
    var checkingStartedAt: Date?
    var completedAt: Date?
    var status: SessionStatus
    var items: [SessionItem]
    init(backpack: GowithBackpack? = nil) {
        id = UUID(); startedAt = .now; backpackID = backpack?.id; backpackNameSnapshot = backpack?.name
        originPlaceID = nil; originPlaceNameSnapshot = nil; destinationPlaceID = nil; destinationPlaceNameSnapshot = nil; arrivedAt = nil; hasExitedOrigin = false
        status = .preparing; items = []
    }

    /// 统一的到达处理：回到出发地进入清点，到达其他地点进入检阅准备。
    func applyArrival(at place: GowithPlace) {
        destinationPlaceID = place.id
        destinationPlaceNameSnapshot = place.name
        arrivedAt = .now
        if place.id == originPlaceID {
            status = .checking
            checkingStartedAt = .now
        } else {
            status = .arrived
            for item in items { item.isSelected = false }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, startedAt, backpackID, backpackNameSnapshot, originPlaceID, originPlaceNameSnapshot, destinationPlaceID, destinationPlaceNameSnapshot, arrivedAt, hasExitedOrigin, wentOutAt, checkingStartedAt, completedAt, status, items
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(startedAt, forKey: .startedAt)
        try c.encode(backpackID, forKey: .backpackID); try c.encode(backpackNameSnapshot, forKey: .backpackNameSnapshot)
        try c.encode(originPlaceID, forKey: .originPlaceID); try c.encode(originPlaceNameSnapshot, forKey: .originPlaceNameSnapshot)
        try c.encode(destinationPlaceID, forKey: .destinationPlaceID); try c.encode(destinationPlaceNameSnapshot, forKey: .destinationPlaceNameSnapshot)
        try c.encode(arrivedAt, forKey: .arrivedAt); try c.encode(hasExitedOrigin, forKey: .hasExitedOrigin)
        try c.encode(wentOutAt, forKey: .wentOutAt); try c.encode(checkingStartedAt, forKey: .checkingStartedAt)
        try c.encode(completedAt, forKey: .completedAt); try c.encode(status, forKey: .status); try c.encode(items, forKey: .items)
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id); startedAt = try c.decode(Date.self, forKey: .startedAt)
        backpackID = try c.decodeIfPresent(UUID.self, forKey: .backpackID)
        backpackNameSnapshot = try c.decodeIfPresent(String.self, forKey: .backpackNameSnapshot)
        originPlaceID = try c.decodeIfPresent(UUID.self, forKey: .originPlaceID)
        originPlaceNameSnapshot = try c.decodeIfPresent(String.self, forKey: .originPlaceNameSnapshot)
        destinationPlaceID = try c.decodeIfPresent(UUID.self, forKey: .destinationPlaceID)
        destinationPlaceNameSnapshot = try c.decodeIfPresent(String.self, forKey: .destinationPlaceNameSnapshot)
        arrivedAt = try c.decodeIfPresent(Date.self, forKey: .arrivedAt)
        hasExitedOrigin = try c.decodeIfPresent(Bool.self, forKey: .hasExitedOrigin) ?? false
        wentOutAt = try c.decodeIfPresent(Date.self, forKey: .wentOutAt)
        checkingStartedAt = try c.decodeIfPresent(Date.self, forKey: .checkingStartedAt)
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
        status = try c.decode(SessionStatus.self, forKey: .status)
        items = try c.decode([SessionItem].self, forKey: .items)
    }
}

final class GowithStore: ObservableObject {
    @Published var items: [GowithItem] = []
    @Published var sessions: [OutingSession] = []
    @Published var backpacks: [GowithBackpack] = []
    @Published var categories: [GowithCategory] = []
    @Published var places: [GowithPlace] = []
    @Published var selectedPlaceID: UUID?
    @Published var selectedBackpackID: UUID?
    private let fileURL: URL

    init() {
        let support = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)) ?? URL(fileURLWithPath: NSTemporaryDirectory())
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        fileURL = support.appendingPathComponent("gowith-data.json")
        load()
        processExpiredPending()
    }

    var activeSession: OutingSession? { sessions.first(where: { $0.status != .completed }) }
    var visibleItems: [GowithItem] { items.filter { !$0.isArchived }.sorted { $0.createdAt < $1.createdAt } }
    var visibleBackpacks: [GowithBackpack] { backpacks.sorted { $0.createdAt < $1.createdAt } }
    var itemsAtSelectedPlace: [GowithItem] { visibleItems.filter { $0.placeID == selectedPlaceID } }
    var backpacksAtSelectedPlace: [GowithBackpack] { visibleBackpacks.filter { $0.placeID == selectedPlaceID } }
    var selectedPlace: GowithPlace? { places.first(where: { $0.id == selectedPlaceID }) }
    var selectedBackpack: GowithBackpack? { backpacks.first(where: { $0.id == selectedBackpackID }) }

    func selectPlace(_ place: GowithPlace) {
        selectedPlaceID = place.id
        if !backpacksAtSelectedPlace.contains(where: { $0.id == selectedBackpackID }) {
            selectedBackpackID = backpacksAtSelectedPlace.first?.id
        }
        save()
    }

    func place(for id: UUID?) -> GowithPlace? {
        guard let id else { return nil }
        return places.first(where: { $0.id == id })
    }

    func selectBackpack(_ backpack: GowithBackpack) {
        selectedBackpackID = backpack.id
        save()
    }

    func toggleItem(_ item: GowithItem, in backpack: GowithBackpack) {
        if let index = backpack.itemIDs.firstIndex(of: item.id) {
            backpack.itemIDs.remove(at: index)
        } else {
            backpack.itemIDs.append(item.id)
        }
        save()
    }

    func save() {
        struct Payload: Codable {
            var items: [GowithItem]
            var sessions: [OutingSession]
            var backpacks: [GowithBackpack]
            var categories: [GowithCategory]
            var places: [GowithPlace]
            var selectedPlaceID: UUID?
            var selectedBackpackID: UUID?
        }
        if let data = try? JSONEncoder().encode(Payload(items: items, sessions: sessions, backpacks: backpacks, categories: categories, places: places, selectedPlaceID: selectedPlaceID, selectedBackpackID: selectedBackpackID)) {
            try? data.write(to: fileURL, options: .atomic)
        }
        objectWillChange.send()
    }

    func processExpiredPending() {
        let homeFallback = places.first?.id
        var changed = false
        for session in sessions { for item in session.items where item.status == .pending {
            guard let since = item.pendingSince, Date().timeIntervalSince(since) >= 3 * 24 * 60 * 60 else { continue }
            item.status = .lost; item.lostAt = .now
            if let index = items.firstIndex(where: { $0.id == item.itemID }) {
                items[index].lostCount += 1
                if items[index].placeID == nil { items[index].placeID = session.originPlaceID ?? homeFallback }
            }
            changed = true
        }}
        if changed { save() }
    }

    private func load() {
        struct Payload: Codable {
            var items: [GowithItem]
            var sessions: [OutingSession]
            var backpacks: [GowithBackpack]?
            var categories: [GowithCategory]?
            var places: [GowithPlace]?
            var selectedPlaceID: UUID?
            var selectedBackpackID: UUID?
        }
        guard let data = try? Data(contentsOf: fileURL), let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            let home = GowithPlace(name: "我的家")
            places = [home]
            selectedPlaceID = home.id
            return
        }
        items = payload.items; sessions = payload.sessions
        backpacks = payload.backpacks ?? []
        categories = payload.categories ?? []
        if let storedPlaces = payload.places, !storedPlaces.isEmpty {
            places = storedPlaces
            selectedPlaceID = payload.selectedPlaceID ?? storedPlaces.first?.id
        } else {
            let home = GowithPlace(name: "我的家")
            places = [home]
            selectedPlaceID = home.id
            let activeJourney = sessions.first(where: { $0.status != .completed })
            let travellingItemIDs = Set(activeJourney?.status == .away ? activeJourney?.items.map(\.itemID) ?? [] : [])
            for item in items where !item.isArchived {
                item.placeID = travellingItemIDs.contains(item.id) ? nil : home.id
            }
            for backpack in backpacks {
                backpack.placeID = activeJourney?.status == .away && backpack.id == activeJourney?.backpackID ? nil : home.id
            }
            if let activeJourney, activeJourney.originPlaceID == nil {
                activeJourney.originPlaceID = home.id
                activeJourney.originPlaceNameSnapshot = home.name
            }
        }
        selectedBackpackID = payload.selectedBackpackID
        if !backpacksAtSelectedPlace.contains(where: { $0.id == selectedBackpackID }) {
            selectedBackpackID = backpacksAtSelectedPlace.first?.id
        }
        save()
    }
}

enum LocalImageStore {
    private static let cache = NSCache<NSString, UIImage>()

    static func save(data: Data) -> String? {
        let name = "\(UUID().uuidString).jpg"
        do {
            let dir = try directoryURL()
            try data.write(to: dir.appendingPathComponent(name), options: .atomic)
            if let image = UIImage(data: data) { cache.setObject(image, forKey: name as NSString) }
            return name
        } catch { return nil }
    }
    static func load(fileName: String?) -> Data? {
        guard let fileName, let dir = try? directoryURL() else { return nil }
        return try? Data(contentsOf: dir.appendingPathComponent(fileName))
    }
    /// 读取并缓存解码后的图片，避免列表滚动时反复磁盘 I/O 与解码。
    static func cachedImage(fileName: String?) -> UIImage? {
        guard let fileName else { return nil }
        if let image = cache.object(forKey: fileName as NSString) { return image }
        guard let data = load(fileName: fileName), let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: fileName as NSString)
        return image
    }
    static func delete(fileName: String?) {
        guard let fileName, let dir = try? directoryURL() else { return }
        cache.removeObject(forKey: fileName as NSString)
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(fileName))
    }
    static func copy(fileName: String?) -> String? {
        guard let data = load(fileName: fileName) else { return nil }
        return save(data: data)
    }
    private static func directoryURL() throws -> URL {
        let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = base.appendingPathComponent("GowithImages", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
