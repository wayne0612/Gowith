import XCTest
@testable import Gowith

/// 出行会话状态机的到达分支（回家清点 vs 异地检阅）。
final class OutingSessionTests: XCTestCase {
    private func makeSession(origin: GowithPlace, itemCount: Int) -> OutingSession {
        let backpack = GowithBackpack(name: "通勤包")
        let session = OutingSession(backpack: backpack)
        session.originPlaceID = origin.id
        session.originPlaceNameSnapshot = origin.name
        session.status = .away
        for index in 0..<itemCount {
            session.items.append(SessionItem(item: GowithItem(name: "物品\(index)")))
        }
        return session
    }

    func testArrivalAtOriginStartsCheckingAndKeepsSelection() {
        let home = GowithPlace(name: "我的家")
        let session = makeSession(origin: home, itemCount: 2)

        session.applyArrival(at: home)

        XCTAssertEqual(session.status, .checking)
        XCTAssertEqual(session.destinationPlaceID, home.id)
        XCTAssertNotNil(session.checkingStartedAt)
        // 回家清点：物品保持选中，等待逐项核对
        XCTAssertTrue(session.items.allSatisfy(\.isSelected))
    }

    func testArrivalAtOtherPlacePreparesReviewAndDeselectsAll() {
        let home = GowithPlace(name: "我的家")
        let office = GowithPlace(name: "公司")
        let session = makeSession(origin: home, itemCount: 3)

        session.applyArrival(at: office)

        XCTAssertEqual(session.status, .arrived)
        XCTAssertEqual(session.destinationPlaceID, office.id)
        XCTAssertEqual(session.destinationPlaceNameSnapshot, "公司")
        XCTAssertNil(session.checkingStartedAt)
        // 到达他地：全部取消选中，由用户在检阅中决定放入哪些
        XCTAssertTrue(session.items.allSatisfy { !$0.isSelected })
    }
}
