//http://codereview.stackexchange.com/questions/85819/making-a-generic-nsmaptable-replacement-written-in-swift-thread-safe

import Foundation


public class WeakKeyDictionary<K:AnyObject, V where K:Hashable> {

    private var dict = SynchronizedValue(value: Dictionary<HashableWeakBox<K>, V>())
    public var block: (V) -> () = {
        _ in }

    public init() {
    }
    public init(dictionary: Dictionary<K, V>) {
        for (k, v) in dictionary {
            setValue(v, forKey: k)
        }
    }

    public subscript(key: K) -> V? {
        get {
            return valueForKey(key)
        }
        set {
            setValue(newValue, forKey: key)
        }
    }

    public func valueForKey(key: K) -> V? {
        return dict.get {
            $0[HashableWeakBox(key)]
        }
    }

    public func setValue(newValue: V?, forKey key: K) {
        let hashableBox = HashableWeakBox(key)

        if let value = newValue {
            let watcher = DeallocWatcher {
                [weak self] in
                if let me = self {
                    if let v = me.syncedRemoveValueForKey(hashableBox) {
                        me.block(v)
                    }
                }
            }

            objc_setAssociatedObject(key, unsafeAddressOf(self), watcher, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            dict.access {
                $0[hashableBox] = value
                return
            }
        } else {
            objc_setAssociatedObject(key, unsafeAddressOf(self), nil, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)//0
        }
    }

    public func removeValueForKey(key: K) -> V? {
        objc_setAssociatedObject(key, unsafeAddressOf(self), nil, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        return syncedRemoveValueForKey(HashableWeakBox(key))
    }

    private func syncedRemoveValueForKey(key: HashableWeakBox<K>) -> V? {
        var v: V?
        dict.access {
            v = $0.removeValueForKey(key)
            return
        }
        return v
    }

    public var count: Int {
        return dict.get {
            $0.count
        }
    }
    public var isEmpty: Bool {
        return dict.get {
            $0.isEmpty
        }
    }

    public var keyValues: [(K, V)] {
        return dict.get {
            dict in
            let v = dict.keys
            .filter {
                k in k.value != nil
            }
            .map {
                k -> (K, V) in (k.value!, dict[k]!)
            }
            return Array(v)
        }
    }
    public var keys: [K] {
        return keyValues.map {
            (k, v) in k
        }
    }
    public var values: [V] {
        return keyValues.map {
            (k, v) in v
        }
    }

    deinit {
        // Callback is not called when deallocing the helpers because in this case (inside deinit) 'self' is already nil
        dict.access {
            for box in $0.keys {
                objc_setAssociatedObject(box.value, unsafeAddressOf(self), nil, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
            }
        }
    }
}

extension WeakKeyDictionary: CustomStringConvertible {
    public var description: String {
        let contents = dict.get {
            dict -> [String] in
            let v = dict.keys
            .filter {
                $0.value != nil
            }
            .map {
                "\($0.value!) : \(dict[$0]) "
            }
            return Array(v)
        }

        return "[ " + contents.joinWithSeparator(", ") + "]"   //"[ " + ", ".join(contents) + "]"
    }
}

extension WeakKeyDictionary: SequenceType {
    public func generate() -> IndexingGenerator<Array<(K, V)>> {
        return keyValues.generate()
    }
}

private class HashableWeakBox<T:AnyObject where T:Hashable>: Hashable {
    weak var value: T?
    let hashValueWhenNil: Int

    init(_ v: T) {
        value = v
        hashValueWhenNil = v.hashValue
    }

    var hashValue: Int {
        return value?.hashValue ?? hashValueWhenNil
    }
}

private func ==<T:AnyObject where T:Hashable>(lhs: HashableWeakBox<T>, rhs: HashableWeakBox<T>) -> Bool {
    if lhs === rhs {
        return true
    }
    return lhs.hashValue == rhs.hashValue
}
//private class DeallocWatcher {
//    let callback: ()->()
//    init(_ c: ()->()) { callback = c }
//    deinit { callback() }
//}

public class SynchronizedValue<T> {
    public let serialQueue = dispatch_queue_create("SynchronizedValue serial queue", DISPATCH_QUEUE_SERIAL)
    private var value: T

    public init(value v: T) {
        value = v
    }

    /// Should only return value types or thread-safe reference types
    public func get<V>(/*@noescape*/ action: (T) -> V) -> V {
        var v: V?
        dispatch_sync(serialQueue) {
            v = action(self.value)
        }
        return v!
    }

    public func access(/*@noescape*/ action: (inout T) -> ()) {
        dispatch_sync(serialQueue) {
            action(&self.value)
        }
    }

    /// Should only be used for value types or for thread-safe reference types
    public func get() -> T {
        return get {
            $0
        }
    }

    public func set(v: T) {
        access {
            $0 = v
            return
        }
    }
}
