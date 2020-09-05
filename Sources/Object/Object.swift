import Foundation
import Later

public enum ObjectError: Error {
    case invalidParameter
}

@dynamicMemberLookup
public class Object {
    public typealias ObjectFunction = (Any?) throws -> Any?
    /// Functions of the object
    public var functions: [AnyHashable: ObjectFunction] = [:]
    /// Variables of the object
    public var variables: [AnyHashable: Any] = [:]
    /// @dynamicMemberLookup
    public subscript(dynamicMember member: String) -> Object {
        guard let value = variables[member] else {
            return Object()
        }
        if let array = value as? [Any] {
            return Object(array: array)
        }
        guard let object = value as? Object else {
            return Object(value)
        }
        return object
    }
    /// Retrieve a Function from the current object
    @discardableResult
    public func function(_ named: AnyHashable) -> ObjectFunction {
        guard let function = functions[named] else {
            return { _ in NSNull() }
        }
        return function
    }
    /// Retrieve a Value from the current object
    @discardableResult
    public func variable(_ named: AnyHashable) -> Object {
        guard let value = variables[named] else {
            return Object()
        }
        if let array = value as? [Any] {
            return Object(array: array)
        }
        guard let object = value as? Object else {
            return Object {
                $0.addVariable("_value", value: unwrap(value))
            }
        }
        return object
    }
    /// Add a Value with a name to the current object
    public func addVariable(_ named: AnyHashable, value: Any) {
        variables[named] = value
    }
    /// Add a Function with a name and a closure to the current object
    public func addFunction(named: AnyHashable, value: @escaping ObjectFunction) {
        functions[named] = value
    }
    /// Run a Function with or without a value
    @discardableResult
    public func runFunction(named: AnyHashable, value: Any = NSNull()) -> Object {
        Object(try? function(named)(value))
    }
    ///Run a Function with a internal value
    @discardableResult
    public func runFunction(named: AnyHashable, withInteralValueName iValueName: AnyHashable) -> Object {
        Object(try? function(named)(variable(iValueName)))
    }
    /// Run a Async Function with or without a value
    @discardableResult
    public func runAsyncFunction(named: AnyHashable, value: Any = NSNull()) -> LaterValue<Object> {
        Later.promise { [weak self] promise in
            do {
                promise.succeed(Object(try self?.function(named)(value)))
            } catch {
                promise.fail(error)
            }
        }
    }
    ///Run a Async Function with a internal value
    @discardableResult
    public func runAsyncFunction(named: AnyHashable, withInteralValueName iValueName: AnyHashable) -> LaterValue<Object> {
        let value = variable(iValueName)
        
        return Later.promise { [weak self] promise in
            do {
                promise.succeed(Object(try self?.function(named)(value)))
            } catch {
                promise.fail(error)
            }
        }
    }
    /// Unwraps the <Optional> Any type
    private func unwrap(_ value: Any) -> Any {
        let mValue = Mirror(reflecting: value)
        let isValueOptional = mValue.displayStyle != .optional
        let isValueEmpty = mValue.children.isEmpty
        if isValueOptional { return value }
        if isValueEmpty { return NSNull() }
        guard let (_, unwrappedValue) = mValue.children.first else { return NSNull() }
        return unwrappedValue
    }
    
    // MARK: public init
    
    public init() { }
    public convenience init(_ closure: (Object) -> Void) {
        self.init()
        
        closure(self)
    }
    public init(_ value: Any?) {
        guard let value = value else {
            return
        }
        let unwrappedValue = unwrap(value)
        if let _ = unwrappedValue as? NSNull {
            return
        }
        if let object = unwrappedValue as? Object {
            consume(object)
        } else if let array = unwrappedValue as? [Any] {
            consume(Object(array: array))
        } else if let dictionary = unwrappedValue as? [AnyHashable: Any] {
            consume(Object(dictionary: dictionary))
        } else if let data = unwrappedValue as? Data {
            consume(Object(data: data))
        } else {
            consume(Object {
                $0.addVariable("_value", value: unwrappedValue)
            })
        }
    }
    
    // MARK: private init
    
    private init(array: [Any]) {
        addVariable("_array", value: array.map(Object.init))
    }
    private init(dictionary: [AnyHashable: Any]) {
        variables = dictionary
    }
    private init(data: Data) {
        defer {
            variables["_json"] = String(data: data, encoding: .utf8)
        }
        if let json = try? JSONSerialization.jsonObject(with: data,
                                                        options: .allowFragments) as? [Any] {
            addVariable("_array", value: json)
            return
        }
        guard let json = try? JSONSerialization.jsonObject(with: data,
                                                           options: .allowFragments) as? [AnyHashable: Any] else {
                                                            return
        }
        variables = json
    }
}

public extension Object {
    
    @discardableResult
    func configure(_ closure: (Object) -> Void) -> Object {
        closure(self)
        
        return self
    }
    
    @discardableResult
    func consume(_ object: Object) -> Object {
        object.variables.forEach { (key, value) in
            self.addVariable(key, value: value)
        }
        object.functions.forEach { (key, closure) in
            self.addFunction(named: key, value: closure)
        }
        
        return self
    }
}

extension Object: CustomStringConvertible {
    public var description: String {
        variables
            .map { (key, value) in
                guard let object = value as? Object else {
                    return "\t\(key): \(value)"
                }
                
                return object.description
        }
        .joined(separator: "\n")
    }
}

public extension Object {
    var all: [AnyHashable: Object] {
        var allVariables = [AnyHashable: Object]()
        
        variables.forEach { key, value in
            print("Key: \(key) = \(value)")
            let uKey = ((key as? String) == "") ? UUID().uuidString : key
            if let objects = value as? [Object] {
                allVariables[uKey] = Object(array: objects)
                return
            }
            guard let object = value as? Object else {
                allVariables[uKey] = Object()
                allVariables[uKey]?.addVariable("_value", value: value)
                return
            }
            allVariables[uKey] = Object(dictionary: object.all)
        }
        
        return allVariables
    }
    
    var array: [Object] {
        if let array = variables["_array"] as? [Data] {
            return array.map { Object($0) }
        } else if let array = variables["_array"] as? [Any] {
            return array.map { value in
                guard let json = value as? [AnyHashable: Any] else {
                    return Object {
                        $0.addVariable("_value", value: value)
                    }
                }
                return Object(dictionary: json)
            }
        }
        return []
    }
    
    var object: Object {
        (variables["_object"] as? Object) ?? Object()
    }
    
    var value: Any {
        variables["_value"] ?? Object()
    }
    
    func value<T>(as type: T.Type? = nil) -> T? {
        value as? T
    }
}

public extension Data {
    var object: Object {
        Object(self)
    }
}

public extension Encodable {
    
    var object: Object {
        guard let data =  try? JSONEncoder().encode(self) else {
            return Object(self)
        }
        return Object(data)
    }
}
