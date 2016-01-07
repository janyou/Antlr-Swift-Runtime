import ObjectiveC

//http://stackoverflow.com/questions/28670796/can-i-hook-when-a-weakly-referenced-object-of-arbitrary-type-is-freed
/*
enum {
OBJC_ASSOCIATION_ASSIGN = 0,
OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1,
OBJC_ASSOCIATION_COPY_NONATOMIC = 3,
OBJC_ASSOCIATION_RETAIN = 01401,
OBJC_ASSOCIATION_COPY = 01403
};
*/
// helper class to notify deallocation

class DeallocWatcher {
    let notify: () -> Void
    init(_ notify: () -> Void) {
        self.notify = notify
    }
    deinit {
        notify()
    }
}

class WeakBox<E:AnyObject> {
    weak var raw: E!
    init(_ raw: E) {
        self.raw = raw
    }
}

class WeakHashMap<Key:Hashable, Value:AnyObject> {

    private var mapping = [Key: WeakBox < Value>]()

    subscript(key: Key) -> Value? {
        get {
            return mapping[key]?.raw
        }
        set {
            if let o = newValue {
                // Add helper to associated objects.
                // When `o` is deallocated, `watcher` is also deallocated.
                // So, `watcher.deinit()` will get called.
                let watcher = DeallocWatcher {
                    [unowned self] in self.mapping[key] = nil
                }
                objc_setAssociatedObject(o, unsafeAddressOf(self), watcher, (objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC))
                mapping[key] = WeakBox(o)
            } else {
                mapping[key] = nil
            }
        }
    }

    var count: Int {
        return mapping.count
    }

    deinit {
        // cleanup
        for e in self.mapping.values {
            objc_setAssociatedObject(e.raw, unsafeAddressOf(self), nil, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
}