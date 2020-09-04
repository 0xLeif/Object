import Foundation
import Later

public enum ObjectError: Error {
    case invalidParameter
}

@dynamicMemberLookup
public class Object {
    public typealias ObjectFunction = (Any?) throws -> Any?
    public typealias ObjectVariable = Any
    /// Functions of the object
    public var functions: [AnyHashable: ObjectFunction] = [:]
    /// Variables of the object
    public var variables: [AnyHashable: ObjectVariable] = [:]
    /// @dynamicMemberLookup
    public subscript(dynamicMember member: String) -> ObjectVariable {
        variables[member] ?? NSNull()
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
    public func variable(_ named: AnyHashable) -> ObjectVariable {
        return unwrap(value: variables[named] ?? NSNull())
    }
    /// Add a Value with a name to the current object
    public func addVariable(_ named: AnyHashable, value: ObjectVariable) {
        variables[named] = value
    }
    /// Add a Function with a name and a closure to the current object
    public func addFunction(named: AnyHashable, value: @escaping ObjectFunction) {
        functions[named] = value
    }
    /// Run a Function with or without a value
    @discardableResult
    public func runFunction(named: AnyHashable, value: ObjectVariable = NSNull()) -> ObjectVariable? {
        try? function(named)(value)
    }
    ///Run a Function with a internal value
    @discardableResult
    public func runFunction(named: AnyHashable, withInteralValueName iValueName: AnyHashable) -> ObjectVariable? {
        try? function(named)(variable(iValueName))
    }
    /// Run a Async Function with or without a value
    @discardableResult
    public func runAsyncFunction(named: AnyHashable, value: ObjectVariable = NSNull()) -> LaterValue<ObjectVariable?> {
        Later.promise { [weak self] promise in
            do {
                promise.succeed(try self?.function(named)(value))
            } catch {
                promise.fail(error)
            }
        }
    }
    ///Run a Async Function with a internal value
    @discardableResult
    public func runAsyncFunction(named: AnyHashable, withInteralValueName iValueName: AnyHashable) -> LaterValue<ObjectVariable?> {
        let value = variable(iValueName)
        
        return Later.promise { [weak self] promise in
            do {
                promise.succeed(try self?.function(named)(value))
            } catch {
                promise.fail(error)
            }
        }
    }
    /// Unwraps the <Optional> Any type
    private func unwrap(value: ObjectVariable) -> ObjectVariable {
        let mValue = Mirror(reflecting: value)
        let isValueOptional = mValue.displayStyle != .optional
        let isValueEmpty = mValue.children.isEmpty
        if isValueOptional { return value }
        if isValueEmpty { return NSNull() }
        guard let (_, unwrappedValue) = mValue.children.first else { return NSNull() }
        return unwrappedValue
    }
    
    public init<T>(_ value: T?) where T: Codable {
        guard let value = value else {
            return
        }
        guard let data =  try? JSONEncoder().encode(value) else {
            return
        }
        guard let json = try? JSONSerialization.jsonObject(with: data,
                                                           options: .allowFragments) as? [AnyHashable: Any] else {
                                                            variables["json"] = try? JSONSerialization.jsonObject(with: data,
                                                                                                                  options: .allowFragments) as? String
                                                            return
        }
        variables = json
        variables["json"] = try? JSONSerialization.jsonObject(with: data,
                                                              options: .allowFragments) as? String
    }
}

public extension Data {
    var object: Object {
        Object(self)
    }
}
