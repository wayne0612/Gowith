import XCTest
@testable import Gowith

/// GowithStore 纯逻辑：货架归属与 3 天 pending 过期结算。
/// 通过注入临时文件 URL 保证每个用例独立，不污染真实数据。
final class GowithStoreLogicTests: XCTestCase {
    private func makeStore() -> GowithStore {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("gowith-tests-\(UUID().uuidString).json")
        return GowithStore(fileURL: url)
    }

    // MARK: - shelfItems / remainingShelfItems

    func testShelfContainsHomeItemsAndPackedCarryItems() {
        let store = makeStore()
        let home = store.places[0]
        store.selectedPlaceID = home.id
        let backpack = GowithBackpack(name: "通勤包", placeID: home.id)
        store.backpacks.append(backpack)
        store.selectedBackpackID = backpack.id

        let shelfItem = GowithItem(name: "备用充电器", placeID: home.id)
        let carriedItem = GowithItem(name: "钥匙", placeID: home.id)
        let homelessItem = GowithItem(name: "无主物品", placeID: nil)
        store.items.append(contentsOf: [shelfItem, carriedItem, homelessItem])

        // 装入钥匙并模拟出门（placeID 置空 = 随身携带中）
        store.toggleItem(carriedItem, in: backpack)
        carriedItem.placeID = nil

        let shelfIDs = Set(store.shelfItems.map(\.id))
        XCTAssertTrue(shelfIDs.contains(shelfItem.id), "当前地点的物品应在货架上")
        XCTAssertTrue(shelfIDs.contains(carriedItem.id), "placeID 为 nil 的随身已装物品应计入货架")
        XCTAssertFalse(shelfIDs.contains(homelessItem.id), "无地点且未装入的物品不应出现在货架")

        let remainingIDs = Set(store.remainingShelfItems.map(\.id))
        XCTAssertTrue(remainingIDs.contains(shelfItem.id), "未装入的地点物品应在「货架剩余」")
        XCTAssertFalse(remainingIDs.contains(carriedItem.id), "已装入物品不应再出现在「货架剩余」")
        XCTAssertFalse(remainingIDs.contains(homelessItem.id))
    }

    // MARK: - processExpiredPending

    private func makePendingSession(in store: GowithStore, origin: GowithPlace, item: GowithItem, since: Date) -> OutingSession {
        let session = OutingSession()
        session.originPlaceID = origin.id
        session.originPlaceNameSnapshot = origin.name
        session.status = .completed
        let sessionItem = SessionItem(item: item)
        sessionItem.status = .pending
        sessionItem.pendingSince = since
        session.items = [sessionItem]
        store.sessions.append(session)
        return session
    }

    func testPendingUnderThreeDaysStaysPending() {
        let store = makeStore()
        let home = store.places[0]
        let item = GowithItem(name: "雨伞", placeID: nil)
        store.items.append(item)
        let session = makePendingSession(in: store, origin: home, item: item,
                                         since: Date().addingTimeInterval(-(3 * 24 * 3600 - 60)))

        store.processExpiredPending()

        XCTAssertEqual(session.items[0].status, .pending, "未满 3 天不应转为遗失")
        XCTAssertNil(session.items[0].lostAt)
        XCTAssertEqual(item.lostCount, 0)
    }

    func testExpiredPendingBecomesLostAndOrphanReassignsToOrigin() {
        let store = makeStore()
        let home = store.places[0]
        let item = GowithItem(name: "雨伞", placeID: nil)
        store.items.append(item)
        let session = makePendingSession(in: store, origin: home, item: item,
                                         since: Date().addingTimeInterval(-(3 * 24 * 3600 + 60)))

        store.processExpiredPending()

        XCTAssertEqual(session.items[0].status, .lost)
        XCTAssertNotNil(session.items[0].lostAt)
        XCTAssertEqual(item.lostCount, 1)
        XCTAssertEqual(item.placeID, home.id, "孤儿物品应归位到会话出发地，避免在所有界面不可见")
    }

    func testExpiredPendingKeepsExistingPlaceAndAccumulatesLostCount() {
        let store = makeStore()
        let home = store.places[0]
        let office = GowithPlace(name: "公司")
        store.places.append(office)
        let item = GowithItem(name: "充电器", placeID: office.id)
        store.items.append(item)
        makePendingSession(in: store, origin: home, item: item,
                           since: Date().addingTimeInterval(-(4 * 24 * 3600)))
        makePendingSession(in: store, origin: home, item: item,
                           since: Date().addingTimeInterval(-(5 * 24 * 3600)))

        store.processExpiredPending()

        XCTAssertEqual(item.lostCount, 2, "两次过期应各自累加遗失计数")
        XCTAssertEqual(item.placeID, office.id, "已有地点的物品不应被出发地覆盖")
    }
}
