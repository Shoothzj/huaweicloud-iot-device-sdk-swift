import XCTest
@testable import HuaweiCloudIoTDevice

final class TimeUtilTests: XCTestCase {
    
    func testGetTimestamp() {
        let timestamp = TimeUtil.getTimestamp()
        
        let regex = #"^\d{10}$"#
        let regexTest = NSPredicate(format: "SELF MATCHES %@", regex)
        
        XCTAssertTrue(regexTest.evaluate(with: timestamp), "Timestamp format is invalid")
    }
    
    static var allTests = [
        ("testGetTimestamp", testGetTimestamp),
    ]
}
