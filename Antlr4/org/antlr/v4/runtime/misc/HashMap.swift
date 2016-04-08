final class Entry<K: Hashable,V>: CustomStringConvertible {
    final var key: K
    final var value: V
    final var next: Entry<K,V>!
    final var hash: Int
    
    /**
     * Creates new entry.
     */
    init(_ h: Int, _ k: K, _ v: V, _ n: Entry<K,V>!) {
        value = v
        next = n
        key = k
        hash = h
    }
    
    final func getKey() -> K {
        return key
    }
    
    final func getValue() -> V {
        return value
    }
    
    final func setValue(newValue: V) -> V {
        let oldValue: V = value
        value = newValue
        return oldValue
    }
    
    final var hashValue: Int {
        return  key.hashValue
    }
    
    var description: String { return "\(getKey())=\(getValue())" }
    
}
func == <K: Hashable, V: Equatable>(lhs: Entry<K,V>, rhs: Entry<K,V>) -> Bool {
    if lhs === rhs {
        return true
    }
    if  lhs.key == rhs.key {
        if  lhs.value == rhs.value {
            return true
        }
    }
    return false
}
func == <K: Hashable, V: Equatable>(lhs: Entry<K,V?>, rhs: Entry<K,V?>) -> Bool {
    if lhs === rhs {
        return true
    }
    if  lhs.key == rhs.key {
        if lhs.value == nil && rhs.value == nil {
            return true
        } else if lhs.value != nil && rhs.value != nil && lhs.value! == rhs.value! {
            return true
        }
    }
    return false
}



public final class HashMap<K: Hashable,V>: SequenceType
{
    
    /**
     * The default initial capacity - MUST be a power of two.
     */
    let DEFAULT_INITIAL_CAPACITY: Int = 16
    
    /**
     * The maximum capacity, used if a higher value is implicitly specified
     * by either of the constructors with arguments.
     * MUST be a power of two <= 1<<30.
     */
    let MAXIMUM_CAPACITY: Int = 1 << 30
    
    /**
     * The load factor used when none specified in constructor.
     */
    let DEFAULT_LOAD_FACTOR: Float = 0.75
    
    /**
     * The table, resized as necessary. Length MUST Always be a power of two.
     */
     var table: [Entry<K,V>!]
    
    /**
     * The number of key-value mappings contained in this map.
     */
     var size: Int = 0
    
    /**
     * The next size value at which to resize (capacity * load factor).
     * @serial
     */
    var threshold: Int = 0
    
    /**
     * The load factor for the hash table.
     *
     * @serial
     */
     var loadFactor: Float = 0
    
    /**
     * The number of times this HashMap has been structurally modified
     * Structural modifications are those that change the number of mappings in
     * the HashMap or otherwise modify its internal structure (e.g.,
     * rehash).  This field is used to make iterators on Collection-views of
     * the HashMap fail-fast.  (See ConcurrentModificationException).
     */
    var modCount: Int = 0
    
    public init(count: Int) {
        var initialCapacity = count
        if (count < 0)
        {
            initialCapacity = DEFAULT_INITIAL_CAPACITY
        }
        else if (count > MAXIMUM_CAPACITY)
        {
            initialCapacity = MAXIMUM_CAPACITY
        } else {
            // Find a power of 2 >= initialCapacity
            initialCapacity = 1
            while initialCapacity < count
            {
                initialCapacity <<= 1
            }
        }
        
        self.loadFactor = DEFAULT_LOAD_FACTOR
        threshold = Int(Float(initialCapacity) * loadFactor)
        table =  [Entry<K,V>!](count: initialCapacity, repeatedValue: nil)
    }
    public init() {
        self.loadFactor = DEFAULT_LOAD_FACTOR
        threshold = Int(Float(DEFAULT_INITIAL_CAPACITY) * DEFAULT_LOAD_FACTOR)
        table =  [Entry<K,V>!](count: DEFAULT_INITIAL_CAPACITY, repeatedValue: nil)
    }
    
    static func hash(h: Int) -> Int {
        var h = h
        // This function ensures that hashCodes that differ only by
        // constant multiples at each bit position have a bounded
        // number of collisions (approximately 8 at default load factor).
        h ^= (h >>> 20) ^ (h >>> 12)
        return h ^ (h >>> 7) ^ (h >>> 4)
    }
    
    /**
     * Returns index for hash code h.
     */
    static func indexFor(h: Int, _ length: Int) -> Int {
        return h & (length-1)
    }
    
    /**
     * Returns <tt>true</tt> if this map contains no key-value mappings.
     *
     * @return <tt>true</tt> if this map contains no key-value mappings
     */
    public final var isEmpty: Bool {
        return size == 0
    }
    public final subscript(key: K) -> V? {
        get {
            return get(key)
        }
        set {
            if newValue == nil {
                remove(key)
            }else{
                put(key,newValue!)
            }
        }
    }
    
    public final var count: Int {
        return size
    }
    /**
     * Returns the value to which the specified key is mapped,
     * or {@code null} if this map contains no mapping for the key.
     *
     * <p>More formally, if this map contains a mapping from a key
     * {@code k} to a value {@code v} such that {@code (key==null ? k==null :
     * key.equals(k))}, then this method returns {@code v}; otherwise
     * it returns {@code null}.  (There can be at most one such mapping.)
     *
     * <p>A return value of {@code null} does not <i>necessarily</i>
     * indicate that the map contains no mapping for the key; it's also
     * possible that the map explicitly maps the key to {@code null}.
     * The {@link #containsKey containsKey} operation may be used to
     * distinguish these two cases.
     *
     * @see #put(Object, Object)
     */
    public final func get(key: K) -> V? {
        let hash: Int = HashMap.hash(key.hashValue)
        var e = table[HashMap.indexFor(hash, table.count)]
        while e != nil {
            if  e.hash == hash &&  e.key == key
            {
                return e.value
            }
            e = e!.next
        }

        return nil
    }
    /**
     * Returns <tt>true</tt> if this map contains a mapping for the
     * specified key.
     *
     * @param   key   The key whose presence in this map is to be tested
     * @return <tt>true</tt> if this map contains a mapping for the specified
     * key.
     */
    public final func containsKey(key: K) -> Bool {
        return getEntry(key) != nil
    }
    
    /**
     * Returns the entry associated with the specified key in the
     * HashMap.  Returns null if the HashMap contains no mapping
     * for the key.
     */
    final func getEntry(key: K) -> Entry<K,V>! {
        let hash: Int =  HashMap.hash(key.hashValue)
        var e = table[HashMap.indexFor(hash, table.count)]
        while e != nil {
            if  e.hash == hash &&  e.key == key
            {
                return e
            }
            e = e!.next
        }

        return nil
    }
    
    
    /**
     * Associates the specified value with the specified key in this map.
     * If the map previously contained a mapping for the key, the old
     * value is replaced.
     *
     * @param key key with which the specified value is to be associated
     * @param value value to be associated with the specified key
     * @return the previous value associated with <tt>key</tt>, or
     *         <tt>null</tt> if there was no mapping for <tt>key</tt>.
     *         (A <tt>null</tt> return can also indicate that the map
     *         previously associated <tt>null</tt> with <tt>key</tt>.)
     */
    public final func put(key: K, _ value: V) -> V? {
        
        let hash: Int = HashMap.hash(key.hashValue)
        let i: Int = HashMap.indexFor(hash, table.count)
        var e = table[i]
        while e != nil {
            if  e.hash == hash &&  e.key == key {
                let oldValue = e.value
                e.value = value
                return oldValue
            }
            e = e.next
        }
        
        
        modCount += 1
        addEntry(hash, key, value, i)
        return nil
    }
    
    /**
     * Adds a new entry with the specified key, value and hash code to
     * the specified bucket.  It is the responsibility of this
     * method to resize the table if appropriate.
     *
     * Subclass overrides this to alter the behavior of put method.
     */
    final func addEntry(hash: Int, _ key: K, _ value: V, _ bucketIndex: Int) {
        let e = table[bucketIndex]
        table[bucketIndex] = Entry<K,V>(hash, key, value, e)
        let oldSize = size
        size += 1
        if oldSize >= threshold {
            resize(2 * table.count)
        }
    }
    /**
     * Rehashes the contents of this map into a new array with a
     * larger capacity.  This method is called automatically when the
     * number of keys in this map reaches its threshold.
     *
     * If current capacity is MAXIMUM_CAPACITY, this method does not
     * resize the map, but sets threshold to Integer.MAX_VALUE.
     * This has the effect of preventing future calls.
     *
     * @param newCapacity the new capacity, MUST be a power of two;
     *        must be greater than current capacity unless current
     *        capacity is MAXIMUM_CAPACITY (in which case value
     *        is irrelevant).
     */
    final func resize(newCapacity: Int) {
        let oldCapacity: Int = table.count
        if oldCapacity == MAXIMUM_CAPACITY {
            threshold = Int.max
            return
        }
        
        var newTable  = [Entry<K,V>!](count: newCapacity, repeatedValue: nil)
        transfer(&newTable)
        table = newTable
        threshold = Int(Float(newCapacity) * loadFactor)
    }
    
    /**
     * Transfers all entries from current table to newTable.
     */
    final func transfer(inout newTable: [Entry<K,V>!]) {
        
        let newCapacity: Int = newTable.count
        let length = table.count
        for  j in 0..<length {
            var e = table[j]
            if e != nil {
                table[j] = nil
                repeat {
                    let next = e.next
                    let i: Int = HashMap.indexFor(e.hash, newCapacity)
                    e.next = newTable[i]
                    newTable[i] = e
                    e = next
                } while e != nil
            }
        }
    }
    /**
     * Removes all of the mappings from this map.
     * The map will be empty after this call returns.
     */
    public final func clear() {
        modCount += 1
        let length = table.count
        for  i in 0..<length {
            table[i] = nil
        }
        size = 0
    }
    
    public func remove(key: K) -> V? {
        let e  = removeEntryForKey(key)
        return (e == nil ? nil : e!.value)
    }
    
 
    final func removeEntryForKey(key: K) -> Entry<K,V>? {
        let hash: Int = HashMap.hash(Int(key.hashValue))
        let i = Int(HashMap.indexFor(hash, Int(table.count)))
        var prev  = table[i]
        var e  = prev
        
        while e != nil{
            let next  = e.next
            var _: AnyObject
            if e.hash == hash &&  e.key == key{
                modCount += 1
                size -= 1
                if prev === e
                {table[i] = next}
                else
                {prev.next = next}
                return e
            }
            prev = e
            e = next
        }
        
        return e
    }
    
    public final var values: [V]{
        var valueList: [V] = [V]()
        let length = table.count
        for  j in 0..<length {
            var e = table[j]
            if e != nil {
                valueList.append(e.value)
                repeat {
                    let next = e.next
                    e = next
                    if e != nil {
                        valueList.append(e.value)
                    }
                    
                } while e != nil
            }
        }
        return valueList
    }
    
    public final var keys: [K]{
        var keyList: [K] = [K]()
        let length = table.count
        for  j in 0..<length {
            var e = table[j]
            if e != nil {
                keyList.append(e.key)
                repeat {
                    let next = e.next
                    e = next
                    if e != nil {
                        keyList.append(e.key)
                    }
                    
                } while e != nil
            }
        }
        return keyList
    }
    
 
    public func generate() ->  AnyGenerator<(K,V)> {
        var _next: Entry<K,V>? // next entry to return
        let expectedModCount: Int = modCount // For fast-fail
        var index: Int = 0 // current slot
        //var current: HashMapEntry<K,V> // current entry
        if size > 0{ // advance to first entry
            
            while index < table.count &&  _next == nil
            {
                _next = table[index]
                index += 1
            }
        }
        
        return AnyGenerator {
            if self.modCount != expectedModCount
            {
                fatalError("\(#function) ConcurrentModificationException")
            }
            let e  = _next
            if e == nil
            {
                return nil
            }
            _next = e!.next
            if _next == nil{
                while index < self.table.count &&  _next == nil
                {
                    _next = self.table[index]
                    index += 1
                }
            }
            //current = e
            return (e!.getKey(),e!.getValue())
        }
        
    }
    
}