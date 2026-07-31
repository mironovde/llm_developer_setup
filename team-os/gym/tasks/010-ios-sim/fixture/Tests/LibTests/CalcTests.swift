import XCTest
import Lib

final class CalcTests: XCTestCase {
    func testEvenSplitAmongFour() {
        XCTAssertEqual(splitBill(total: 100.0, people: 4), 25.0, accuracy: 0.0001)
    }

    func testSinglePersonPaysFullBill() {
        XCTAssertEqual(splitBill(total: 42.5, people: 1), 42.5, accuracy: 0.0001)
    }

    func testThreeWaySplitOfNinety() {
        XCTAssertEqual(splitBill(total: 90.0, people: 3), 30.0, accuracy: 0.0001)
    }

    func testTipTwentyPercent() {
        XCTAssertEqual(addTip(total: 50.0, percent: 20.0), 60.0, accuracy: 0.0001)
    }
}
