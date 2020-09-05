# Object

## Basic Example
```swift
let obj = Object()
obj.variables["qwerty"] = 12456
obj.functions["printy"] = { input in
    "{ \(Object(input).value() ?? -1) }"
}

obj.runFunction(named: "printy", value: obj.qwerty)
obj.runFunction(named: "printy", value: obj.variable("qwerty"))
obj.runFunction(named: "printy", withInteralValueName: "qwerty")
```

## [Data](https://jsonplaceholder.typicode.com/posts) Example

```swift
Later.fetch(url: URL(string: "https://jsonplaceholder.typicode.com/posts")!)
    .whenSuccess { (data, response, error) in
        let obj = Object(data)
        
        XCTAssertEqual(obj.array.count, 100)
        
        let first: Object? = obj.array.first
        
        XCTAssertEqual(first?.userId.value(), 1)
        XCTAssertEqual(first?.id.value(), 1)
        XCTAssertEqual(first?.title.value(), "sunt aut facere repellat provident occaecati excepturi optio reprehenderit")
        XCTAssertEqual(first?.body.value(), "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto")
}
```