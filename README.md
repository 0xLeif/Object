# Object

## Basic Example
```swift
let obj = Object()
obj.variables["qwerty"] = 12456
obj.functions["printy"] = { input in
    "{ \(Object(input).value() ?? -1) }"
}

XCTAssertEqual(obj.run(function: "printy", value: obj.qwerty).value(), "{ 12456 }")
XCTAssertEqual(obj.run(function: "printy", value: obj.variable("qwerty")).value(), "{ 12456 }")
XCTAssertEqual(obj.run(function: "printy", withInteralValueName: "qwerty").value(), "{ 12456 }" )
```

## [Data](https://jsonplaceholder.typicode.com/posts) Example

```swift
var mockDataView = UIView.later { later in
    // Fetch Data
    later.fetch(url: URL(string: "https://jsonplaceholder.typicode.com/todos/3")!)
        // Store Values in an Object
        .map { (data, response, error) in
            Object(data).configure {
                $0.add(variable: "response", value: response as Any)
                $0.add(variable: "error", value: error as Any)
            }
    }
        // Save Data
        .flatMap { object in
            object.value(decodedAs: MockData.self)
                .save(withKey: "mock_03")
    }
        // Load Data
        .flatMap { _ in
            MockData.load(withKey: "mock_03")
    }
        // Present UI
        .flatMap { data in
            later.main {
                Label("Data: \(data.title)").number(ofLines: 100)
            }
    }
}
```
