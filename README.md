# Object

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
