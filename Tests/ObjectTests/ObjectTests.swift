import XCTest
import Later
@testable import Object

final class ObjectTests: XCTestCase {
    func testBasic() {
        XCTAssertNil(Object(0).value(as: Double.self))
    }
    
    func testExample() {
        let obj = Object()
        obj.variables["qwerty"] = 12456
        obj.functions["printy"] = { input in
            "{ \(Object(input).value() ?? -1) }"
        }
        
        XCTAssertEqual(obj.runFunction(named: "printy", value: obj.qwerty).value(), "{ 12456 }")
        XCTAssertEqual(obj.runFunction(named: "printy", value: obj.variable("qwerty")).value(), "{ 12456 }")
        XCTAssertEqual(obj.runFunction(named: "printy", withInteralValueName: "qwerty").value(), "{ 12456 }" )
    }
    
    func testObject() {
        let obj = Object()
        obj.variables["qwerty"] = 123456
        obj.functions["toString"] = { "\($0 ?? "-1")" }
        obj.functions["printy"] = { input in
            guard let input = input as? Int else {
                throw ObjectError.invalidParameter
            }
            return "{ \(input) }"
        }
        
        let newObj = Object(obj)
        
        XCTAssertEqual(newObj.qwerty.value(), 123456)
        XCTAssertEqual(newObj.runFunction(named: "printy", value: 654321).value(), "{ 654321 }")
        XCTAssertEqual(newObj.runFunction(named: "toString", value: true).value(), "true")
    }
    
    func testArray() {
        let obj = Object((1 ... 100).map { $0 })
        
        XCTAssertEqual(obj.array.count, 100)
    }
    
    func testDictionary() {
        let obj = Object([
            "some": 3.14,
            3.14: "some"
        ])
        
        XCTAssertEqual(obj.some.value(), 3.14)
        XCTAssertEqual(obj.variable(3.14).value(), "some")
    }
    
    func testCodableObject() {
        struct SMObj: Codable {
            let id = 1
            let string = "Object"
        }
        
        let obj = SMObj().object
        
        XCTAssertEqual(obj.id.value(), 1)
        XCTAssertEqual(obj.string.value(), "Object")
    }
    
    func testFetchObject() {
        let sema = DispatchSemaphore(value: 0)
        
        Later.fetch(url: URL(string: "https://jsonplaceholder.typicode.com/posts/1")!)
            .whenSuccess { (data, response, error) in
                let obj = Object(data)
                
                XCTAssertEqual(obj.userId.value(), 1)
                XCTAssertEqual(obj.id.value(), 1)
                XCTAssertEqual(obj.title.value(), "sunt aut facere repellat provident occaecati excepturi optio reprehenderit")
                XCTAssertEqual(obj.body.value(), "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto")
                
                sema.signal()
        }
        
        sema.wait()
    }
    
    func testFetch100Objects() {
        let sema = DispatchSemaphore(value: 0)
        
        Later.fetch(url: URL(string: "https://jsonplaceholder.typicode.com/posts")!)
            .whenSuccess { (data, response, error) in
                let obj = Object(data)
                
                XCTAssertEqual(obj.array.count, 100)
                
                let first: Object? = obj.array.first
                
                XCTAssertEqual(first?.userId.value(), 1)
                XCTAssertEqual(first?.id.value(), 1)
                XCTAssertEqual(first?.title.value(), "sunt aut facere repellat provident occaecati excepturi optio reprehenderit")
                XCTAssertEqual(first?.body.value(), "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto")
                
                sema.signal()
        }
        
        sema.wait()
    }
    
    static var allTests = [
        ("testBasic", testBasic),
        ("testExample", testExample),
        ("testObject", testObject),
        ("testArray", testArray),
        ("testDictionary", testDictionary),
        ("testCodableObject", testCodableObject),
        ("testFetchObject", testFetchObject),
        ("testFetch100Objects", testFetch100Objects)
    ]
}
