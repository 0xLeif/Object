import XCTest
@testable import Object

final class ObjectTests: XCTestCase {
    func testExample() {
        let obj = Object()
        obj.variables["qwerty"] = 12456
        obj.functions["printy"] = { input in
            guard let input = input as? Int else {
                throw ObjectError.invalidParameter
            }
            print("[[{ \(input) }]]")
            return "{ \(input) }"
        }
    
        obj.runFunction(named: "printy", value: obj.qwerty)
        obj.runFunction(named: "printy", value: obj.variable("qwerty"))
        obj.runFunction(named: "printy", withInteralValueName: "qwerty")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
