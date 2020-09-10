import XCTest
import Later
@testable import Object

final class ObjectTests: XCTestCase {
    func testBasic() {
        XCTAssertNil(Object(0).value(as: Double.self))
    }
    
    func testBasicInit() {
        let obj = Object("init_value") { o in
            o.add(variable: "SomeValue", value: "qwerty")
        }
        
        XCTAssertEqual(obj.value(), "init_value")
        XCTAssertEqual(obj.SomeValue.value(), "qwerty")
    }
    
    func testObjectInit() {
        let obj = Object("init_value") { o in
            o.add(variable: "SomeObject", value: Object("qwerty"))
        }
        
        XCTAssertEqual(obj.value(), "init_value")
        XCTAssertEqual(obj.SomeObject.value(), "qwerty")
    }
    
    func testObjectConsumeInit() {
        let obj = Object(Object("init_value") { o in
            o.add(variable: 3.14, value: "pi")
            o.add(function: 3.15) { input in
                guard let value = input as? Double else {
                    return input
                }
                
                return value * 3.15
            }
            
        }) { o in
            o.add(variable: "SomeValue", value: "qwerty")
        }
        
        XCTAssertEqual(obj.value(), "init_value")
        XCTAssertEqual(obj.SomeValue.value(), "qwerty")
    }
    
    func testComplexInit() {
        let innerObject = Object("init_value") { o in
            o.add(variable: "SomeValue", value: "qwerty")
            o.add(variable: 3.14, value: "pi")
            o.add(function: 3.15) { (Object($0).value(as: Double.self) ?? 0.0) * 3.15 }
        }
        
        let otherObject = Object("other_value") { o in
            o.add(variable: "SomeOtherValue", value: "otherqwerty")
            o.add(variable: 3.14, value: 3.14)
            o.add(function: false) { (Object($0).value(as: Double.self) ?? 0.0) * 3.15 }
        }
        
        let obj = Object { p in
            p.add(childObject: innerObject)
        }
        
        innerObject.add(childObject: otherObject)
        
        XCTAssertEqual(obj.value(as: Object.self)?.description, Object().description)
        XCTAssertEqual(obj.object.value(), "init_value")
        XCTAssertEqual(obj.object.SomeValue.value(), "qwerty")
    }
    
    func testExample() {
        let obj = Object()
        obj.variables["qwerty"] = 12456
        obj.functions["printy"] = { input in
            "{ \(Object(input).value() ?? -1) }"
        }
        
        XCTAssertEqual(obj.run(function: "printy", value: obj.qwerty).value(), "{ 12456 }")
        XCTAssertEqual(obj.run(function: "printy", value: obj.variable("qwerty")).value(), "{ 12456 }")
        XCTAssertEqual(obj.run(function: "printy", withInteralValueName: "qwerty").value(), "{ 12456 }" )
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
        XCTAssertEqual(newObj.run(function: "printy", value: 654321).value(), "{ 654321 }")
        XCTAssertEqual(newObj.run(function: "toString", value: true).value(), "true")
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
        
        print(obj.value)
        
        let smObj = obj.value(decodedAs: SMObj.self)
        
        XCTAssertEqual(smObj?.id, 1)
        XCTAssertEqual(smObj?.string, "Object")
    }
    
    func testConsume() {
        struct SMObj: Codable {
            let id = 1
            let string = "Object"
        }
        
        let smObj = SMObj().object
        
        let dictObj = Object([
            "some": 3.14,
            3.14: "some"
        ])
        
        let arrayObj = Object((1 ... 100).map { $0 })
        
        let obj = Object(
            ["id": 10]
        )
        XCTAssertEqual(obj.id.value(), 10)
        XCTAssertEqual(obj.array.count, 0)
        
        XCTAssertNil(obj.some.value(as: Double.self))
        XCTAssertNil(obj.variable(3.14).value(as: String.self))
        XCTAssertNil(obj.string.value(as: String.self))
        
        [smObj, dictObj, arrayObj]
            .forEach {
                obj.consume($0)
        }
        
        XCTAssertNotEqual(obj.id.value(), 10)
        
        XCTAssertNotNil(obj.some.value(as: Double.self))
        XCTAssertNotNil(obj.variable(3.14).value(as: String.self))
        XCTAssertNotNil(obj.string.value(as: String.self))
        
        XCTAssertEqual(obj.id.value(), smObj.id.value() ?? -1)
        XCTAssertEqual(obj.string.value(), "Object")
        XCTAssertEqual(obj.array.count, arrayObj.array.count)
        XCTAssertEqual(obj.some.value(), 3.14)
        XCTAssertEqual(obj.variable(3.14).value(), "some")
    }
    
    func testAdd() {
        struct SMObj: Codable {
            let id = 1
            let string = "Object"
        }
        
        let smObj = SMObj().object
        
        let dictObj = Object([
            "some": 3.14,
            3.14: "some"
        ])
        
        let arrayObj = Object((1 ... 100).map { $0 })
        
        let empty = Object()
        let obj = Object(
            ["id": 10]
        )
        XCTAssertEqual(obj.id.value(), 10)
        XCTAssertEqual(obj.array.count, 0)
        
        XCTAssertNil(obj.some.value(as: Double.self))
        XCTAssertNil(obj.variable(3.14).value(as: String.self))
        XCTAssertNil(obj.string.value(as: String.self))
        
        [smObj, dictObj]
            .forEach {
                empty.consume($0)
        }
        obj.add(childObject: empty)
        obj.add(array: arrayObj.array)
        
        XCTAssertEqual(obj.id.value(), 10)
        XCTAssertNotEqual(obj.id.value(), smObj.id.value() ?? -1)
        
        XCTAssertNotNil(obj.object.some.value(as: Double.self))
        XCTAssertNotNil(obj.object.variable(3.14).value(as: String.self))
        XCTAssertNotNil(obj.object.string.value(as: String.self))
        
        XCTAssertEqual(obj.object.id.value(), smObj.id.value() ?? -1)
        XCTAssertEqual(obj.object.string.value(), "Object")
        XCTAssertEqual(obj.array.count, arrayObj.array.count)
        XCTAssertEqual(obj.object.some.value(), 3.14)
        XCTAssertEqual(obj.object.variable(3.14).value(), "some")
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
    
    func testDive() {
        let sema = DispatchSemaphore(value: 0)
        
        Later.fetch(url: URL(string: "https://jsonplaceholder.typicode.com/users/7")!)
            .whenSuccess { (data, response, error) in
                let obj = Object(data)
                
                XCTAssertEqual(obj.address.street.value(), "Rex Trail")
                XCTAssertEqual(obj.address.geo.lng.value(), "21.8984")
                XCTAssertEqual(obj.address.geo.lat.value(), "24.8918")
                
                sema.signal()
        }
        
        sema.wait()
    }
    
    static var allTests = [
        ("testBasic", testBasic),
        ("testBasicInit", testBasicInit),
        ("testObjectInit", testObjectInit),
        ("testObjectConsumeInit", testObjectConsumeInit),
        ("testComplexInit", testComplexInit),
        ("testExample", testExample),
        ("testObject", testObject),
        ("testArray", testArray),
        ("testDictionary", testDictionary),
        ("testCodableObject", testCodableObject),
        ("testConsume", testConsume),
        ("testAdd", testAdd),
        ("testFetchObject", testFetchObject),
        ("testFetch100Objects", testFetch100Objects),
        ("testDive", testDive)
    ]
}
