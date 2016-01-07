/*
 * [The "BSD license"]
 *  Copyright (c) 2012 Terence Parr
 *  Copyright (c) 2012 Sam Harwell
 *  Copyright (c) 2015 Janyou
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 *  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 *  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 *  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 *  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


/**
 * This class implements the {@link org.antlr.v4.runtime.misc.IntSet} backed by a sorted array of
 * non-overlapping intervals. It is particularly efficient for representing
 * large collections of numbers, where the majority of elements appear as part
 * of a sequential range of numbers that are all part of the set. For example,
 * the set { 1, 2, 3, 4, 7, 8 } may be represented as { [1, 4], [7, 8] }.
 *
 * <p>
 * This class is able to represent sets containing any combination of values in
 * the range {@link Integer#MIN_VALUE} to {@link Integer#MAX_VALUE}
 * (inclusive).</p>
 */

public class IntervalSet: IntSet, Hashable, CustomStringConvertible {
    public static let COMPLETE_CHAR_SET: IntervalSet =
    {
        let set = try! IntervalSet.of(Lexer.MIN_CHAR_VALUE, Lexer.MAX_CHAR_VALUE)
        try! set.setReadonly(true)
        return set
    }()

    public static let EMPTY_SET: IntervalSet = {
        let set = try! IntervalSet()
        try! set.setReadonly(true)
        return set
    }()


    /** The list of sorted, disjoint intervals. */
    internal var intervals: Array<Interval>

    internal var readonly: Bool = false

    public init(_ intervals: Array<Interval>) {

        self.intervals = intervals
    }

    public convenience init(_ set: IntervalSet) throws {
        try self.init()
        try addAll(set)
    }

    public init(_ els: Int...) throws {
        if els.count == 0 {
            intervals = Array<Interval>() // most sets are 1 or 2 elements
        } else {
            intervals = Array<Interval>()
            for e: Int in els {
                try add(e)
            }
        }
    }

    /** Create a set with a single element, el. */

    public class func of(a: Int) throws -> IntervalSet {
        let s: IntervalSet = try IntervalSet()
        try s.add(a)
        return s
    }

    /** Create a set with all ints within range [a..b] (inclusive) */
    public class func of(a: Int, _ b: Int) throws -> IntervalSet {
        let s: IntervalSet = try IntervalSet()
        try s.add(a, b)
        return s
    }

    public func clear() throws {
        if readonly {
            throw ANTLRError.IllegalState(msg: "can't alter readonly IntervalSet")
        }
        intervals.removeAll()
    }

    /** Add a single element to the set.  An isolated element is stored
     *  as a range el..el.
     */

    public func add(el: Int) throws {
        if readonly {
            throw ANTLRError.IllegalState(msg: "can't alter readonly IntervalSet")
        }
        try add(el, el)
    }

    /** Add interval; i.e., add all integers from a to b to set.
     *  If b&lt;a, do nothing.
     *  Keep list in sorted order (by left range value).
     *  If overlap, combine ranges.  For example,
     *  If this is {1..5, 10..20}, adding 6..7 yields
     *  {1..5, 6..7, 10..20}.  Adding 4..8 yields {1..8, 10..20}.
     */
    public func add(a: Int, _ b: Int) throws {
        try add(Interval.of(a, b))
    }

    // copy on write so we can cache a..a intervals and sets of that
    internal func add(addition: Interval) throws {
        if readonly {
            throw ANTLRError.IllegalState(msg: "can't alter readonly IntervalSet")
        }
        //System.out.println("add "+addition+" to "+intervals.toString());
        if addition.b < addition.a {
            return
        }
        // find position in list
        // Use iterators as we modify list in place

        for var i = 0; i < intervals.count; i++ {

            let r: Interval = intervals[i]
            if addition == r {
                return
            }
            if addition.adjacent(r) || !addition.disjoint(r) {
                // next to each other, make a single larger interval
                let bigger: Interval = addition.union(r)
                //iter.set(bigger);
                intervals[i] = bigger
                // make sure we didn't just create an interval that
                // should be merged with next interval in list
                //while  iter.hasNext()  {
                while i < intervals.count - 1 {
                    i++
                    let next: Interval = intervals[i]  //iter.next();
                    if !bigger.adjacent(next) && bigger.disjoint(next) {
                        break
                    }

                    // if we bump up against or overlap next, merge
                    /*iter.remove();   // remove this one
                    iter.previous(); // move backwards to what we just set
                    iter.set(bigger.union(next)); // set to 3 merged ones
                    iter.next(); // first call to next after previous duplicates the result*/
                    intervals.removeAtIndex(i)
                    i--
                    intervals[i] = bigger.union(next)

                }
                return
            }
            if addition.startsBeforeDisjoint(r) {
                // insert before r
                //iter.previous();
                //iter.add(addition);
                intervals.insert(addition, atIndex: i)
                return
            }
            // if disjoint and after r, a future iteration will handle it
        }
        // ok, must be after last interval (and disjoint from last interval)
        // just add it
        intervals.append(addition)
    }

    /** combine all sets in the array returned the or'd value */
    public func or(sets: [IntervalSet]) throws -> IntSet {
        let r: IntervalSet = try IntervalSet()
        for s: IntervalSet in sets {
            try r.addAll(s)
        }
        return r
    }


    public func addAll(set: IntSet?) throws -> IntSet {
        if set == nil {
            return self
        }

        if set is IntervalSet {
            let other: IntervalSet = set as! IntervalSet
            // walk set and add each interval
            let n: Int = other.intervals.count
            for var i: Int = 0; i < n; i++ {
                let I: Interval = other.intervals[i]
                try self.add(I.a, I.b)
            }
        } else {
            let setList = set!.toList()
            for value: Int in setList {
                try add(value)
            }
        }

        return self
    }

    public func complement(minElement: Int, _ maxElement: Int) throws -> IntSet? {
        return try self.complement(IntervalSet.of(minElement, maxElement))
    }

    /** {@inheritDoc} */

    public func complement(vocabulary: IntSet?) throws -> IntSet? {
        if vocabulary == nil || vocabulary!.isNil() {
            return nil // nothing in common with null set
        }

        var vocabularyIS: IntervalSet
        if vocabulary is IntervalSet {
            vocabularyIS = vocabulary as! IntervalSet
        } else {
            vocabularyIS = try! IntervalSet()
            try vocabularyIS.addAll(vocabulary)
        }

        return try vocabularyIS.subtract(self)
    }


    public func subtract(a: IntSet?) throws -> IntSet {
        if a == nil || a!.isNil() {
            return try IntervalSet(self)
        }

        if a is IntervalSet {
            return try subtract(self, a as? IntervalSet)
        }

        let other: IntervalSet = try IntervalSet()
        try other.addAll(a)
        return try subtract(self, other)
    }

    /**
     * Compute the set difference between two interval sets. The specific
     * operation is {@code left - right}. If either of the input sets is
     * {@code null}, it is treated as though it was an empty set.
     */

    public func subtract(left: IntervalSet?, _ right: IntervalSet?) throws -> IntervalSet {
        if left == nil || left!.isNil() {
            return try IntervalSet()
        }

        let result: IntervalSet = try IntervalSet(left!)
        if right == nil || right!.isNil() {
            // right set has no elements; just return the copy of the current set
            return result
        }

        var resultI: Int = 0
        var rightI: Int = 0
        while resultI < result.intervals.count && rightI < right!.intervals.count {
            let resultInterval: Interval = result.intervals[resultI]
            let rightInterval: Interval = right!.intervals[rightI]

            // operation: (resultInterval - rightInterval) and update indexes

            if rightInterval.b < resultInterval.a {
                rightI++
                continue
            }

            if rightInterval.a > resultInterval.b {
                resultI++
                continue
            }

            var beforeCurrent: Interval? = nil
            var afterCurrent: Interval? = nil
            if rightInterval.a > resultInterval.a {
                beforeCurrent = Interval(resultInterval.a, rightInterval.a - 1)
            }

            if rightInterval.b < resultInterval.b {
                afterCurrent = Interval(rightInterval.b + 1, resultInterval.b)
            }

            if beforeCurrent != nil {
                if afterCurrent != nil {
                    // split the current interval into two
                    result.intervals[resultI] = beforeCurrent!
                    //result.intervals.set(beforeCurrent,resultI);
                    result.intervals.insert(afterCurrent!, atIndex: resultI + 1)
                    //result.intervals.add(, afterCurrent);
                    resultI++
                    rightI++
                    continue
                } else {
                    // replace the current interval
                    result.intervals[resultI] = beforeCurrent!
                    resultI++
                    continue
                }
            } else {
                if afterCurrent != nil {
                    // replace the current interval
                    result.intervals[resultI] = afterCurrent!
                    rightI++
                    continue
                } else {
                    // remove the current interval (thus no need to increment resultI)
                    result.intervals.removeAtIndex(resultI)
                    //result.intervals.remove(resultI);
                    continue
                }
            }
        }

        // If rightI reached right.intervals.size(), no more intervals to subtract from result.
        // If resultI reached result.intervals.size(), we would be subtracting from an empty set.
        // Either way, we are done.
        return result
    }


    public func or(a: IntSet) throws -> IntSet {
        let o: IntervalSet = try IntervalSet()
        try o.addAll(self)
        try o.addAll(a)
        return o
    }

    /** {@inheritDoc} */

    public func and(other: IntSet?) throws -> IntSet? {
        if other == nil {
            //|| !(other instanceof IntervalSet) ) {
            return nil // nothing in common with null set
        }

        var myIntervals: Array<Interval> = self.intervals
        var theirIntervals: Array<Interval> = (other as! IntervalSet).intervals
        var intersection: IntervalSet? = nil
        let mySize: Int = myIntervals.count
        let theirSize: Int = theirIntervals.count
        var i: Int = 0
        var j: Int = 0
        // iterate down both interval lists looking for nondisjoint intervals
        while i < mySize && j < theirSize {
            let mine: Interval = myIntervals[i]
            let theirs: Interval = theirIntervals[j]
            //System.out.println("mine="+mine+" and theirs="+theirs);
            if mine.startsBeforeDisjoint(theirs) {
                // move this iterator looking for interval that might overlap
                i++
            } else {
                if theirs.startsBeforeDisjoint(mine) {
                    // move other iterator looking for interval that might overlap
                    j++
                } else {
                    if mine.properlyContains(theirs) {
                        // overlap, add intersection, get next theirs
                        if intersection == nil {
                            intersection = try IntervalSet()
                        }
                        try intersection!.add(mine.intersection(theirs))
                        j++
                    } else {
                        if theirs.properlyContains(mine) {
                            // overlap, add intersection, get next mine
                            if intersection == nil {
                                intersection = try IntervalSet()
                            }
                            try intersection!.add(mine.intersection(theirs))
                            i++
                        } else {
                            if !mine.disjoint(theirs) {
                                // overlap, add intersection
                                if intersection == nil {
                                    intersection = try IntervalSet()
                                }
                                try intersection!.add(mine.intersection(theirs))
                                // Move the iterator of lower range [a..b], but not
                                // the upper range as it may contain elements that will collide
                                // with the next iterator. So, if mine=[0..115] and
                                // theirs=[115..200], then intersection is 115 and move mine
                                // but not theirs as theirs may collide with the next range
                                // in thisIter.
                                // move both iterators to next ranges
                                if mine.startsAfterNonDisjoint(theirs) {
                                    j++
                                } else {
                                    if theirs.startsAfterNonDisjoint(mine) {
                                        i++
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if intersection == nil {
            return try IntervalSet()
        }
        return intersection
    }

    /** {@inheritDoc} */

    public func contains(el: Int) -> Bool {
        let n: Int = intervals.count
        for var i: Int = 0; i < n; i++ {
            let I: Interval = intervals[i]
            let a: Int = I.a
            let b: Int = I.b
            if el < a {
                break // list is sorted and el is before this interval; not here
            }
            if el >= a && el <= b {
                return true // found in this interval
            }
        }
        return false
/*
		for (ListIterator iter = intervals.listIterator(); iter.hasNext();) {
            Interval I = (Interval) iter.next();
            if ( el<I.a ) {
                break; // list is sorted and el is before this interval; not here
            }
            if ( el>=I.a && el<=I.b ) {
                return true; // found in this interval
            }
        }
        return false;
        */
    }

    /** {@inheritDoc} */

    public func isNil() -> Bool {
        return intervals.isEmpty
    }

    /** {@inheritDoc} */

    public func getSingleElement() -> Int {
        //intervals=nil && intervals.count==1 )
        if intervals.count == 1 {
            let I: Interval = intervals[0]
            if I.a == I.b {
                return I.a
            }
        }
        return CommonToken.INVALID_TYPE
    }

    /**
     * Returns the maximum value contained in the set.
     *
     * @return the maximum value contained in the set. If the set is empty, this
     * method returns {@link org.antlr.v4.runtime.Token#INVALID_TYPE}.
     */
    public func getMaxElement() -> Int {
        if isNil() {
            return CommonToken.INVALID_TYPE
        }
        let last: Interval = intervals[intervals.count - 1]
        return last.b
    }

    /**
     * Returns the minimum value contained in the set.
     *
     * @return the minimum value contained in the set. If the set is empty, this
     * method returns {@link org.antlr.v4.runtime.Token#INVALID_TYPE}.
     */
    public func getMinElement() -> Int {
        if isNil() {
            return CommonToken.INVALID_TYPE
        }

        return intervals[0].a
    }

    /** Return a list of Interval objects. */
    public func getIntervals() -> Array<Interval> {
        return intervals
    }


    public func hashCode() -> Int {
        var hash: Int = MurmurHash.initialize()
        for I: Interval in intervals {
            hash = MurmurHash.update(hash, I.a)
            hash = MurmurHash.update(hash, I.b)
        }

        hash = MurmurHash.finish(hash, intervals.count * 2)
        return hash
    }
    public var hashValue: Int {
        var hash: Int = MurmurHash.initialize()
        for I: Interval in intervals {
            hash = MurmurHash.update(hash, I.a)
            hash = MurmurHash.update(hash, I.b)
        }

        hash = MurmurHash.finish(hash, intervals.count * 2)
        return hash
    }
    /** Are two IntervalSets equal?  Because all intervals are sorted
     *  and disjoint, equals is a simple linear walk over both lists
     *  to make sure they are the same.  Interval.equals() is used
     *  by the List.equals() method to check the ranges.
     */

    /* public func equals(obj : AnyObject) -> Bool {
         if ( obj==nil || !(obj is IntervalSet) ) {
             return false;
         }
         var other : IntervalSet = obj as! IntervalSet;
         return self.intervals.equals(other.intervals);
     }*/

    public var description: String {
        return toString(false)
    }
    public func toString() -> String {
        return description
    }

    public func toString(elemAreChar: Bool) -> String {
        let buf: StringBuilder = StringBuilder()
        //if ( self.intervals==nil || self.intervals.isEmpty() ) {
        if self.intervals.isEmpty {
            return "{}"
        }
        if self.size() > 1 {
            buf.append("{")
        }
        //var iter : Iterator<Interval> = self.intervals.iterator();
        //while iter.hasNext() {
        var first = true
        for I: Interval in intervals {
            if !first {
                buf.append(", ")
            }
            first = false
            //var I : Interval = iter.next();
            let a: Int = I.a
            let b: Int = I.b
            if a == b {
                if a == CommonToken.EOF {
                    buf.append("<EOF>")
                } else {
                    if elemAreChar {
                        buf.append("'").append(String(a)).append("'")
                    } else {
                        buf.append(a)
                    }
                }
            } else {
                if elemAreChar {
                    buf.append("'").append(String(a)).append("'..'").append(String(b)).append("'")
                } else {
                    buf.append(a).append("..").append(b)
                }
            }
            //if ( iter.hasNext() ) {
            //	buf.append(", ");
            //}
        }
        if self.size() > 1 {
            buf.append("}")
        }
        return buf.toString()
    }

    /**
     * @deprecated Use {@link #toString(org.antlr.v4.runtime.Vocabulary)} instead.
     */
    ////@Deprecated
    public func toString(tokenNames: [String?]?) -> String {
        return toString(Vocabulary.fromTokenNames(tokenNames))
    }

    public func toString(vocabulary: Vocabulary) -> String {
        let buf: StringBuilder = StringBuilder()

        if self.intervals.isEmpty {
            return "{}"
        }
        if self.size() > 1 {
            buf.append("{")
        }

        var first = true
        for I: Interval in intervals {
            if !first {
                buf.append(", ")
            }
            first = false
            //var I : Interval = iter.next();
            let a: Int = I.a
            let b: Int = I.b
            if a == b {
                buf.append(elementName(vocabulary, a))
            } else {
                for var i: Int = a; i <= b; i++ {
                    if i > a {
                        buf.append(", ")
                    }
                    buf.append(elementName(vocabulary, i))
                }
            }

        }
        if self.size() > 1 {
            buf.append("}")
        }
        return buf.toString()
    }

    /**
     * @deprecated Use {@link #elementName(org.antlr.v4.runtime.Vocabulary, int)} instead.
     */
    ////@Deprecated
    internal func elementName(tokenNames: [String?]?, _ a: Int) -> String {
        return elementName(Vocabulary.fromTokenNames(tokenNames), a)
    }


    internal func elementName(vocabulary: Vocabulary, _ a: Int) -> String {
        if a == CommonToken.EOF {
            return "<EOF>"
        } else {
            if a == CommonToken.EPSILON {
                return "<EPSILON>"
            } else {
                return vocabulary.getDisplayName(a)
            }
        }
    }


    public func size() -> Int {
        var n: Int = 0
        let numIntervals: Int = intervals.count
        if numIntervals == 1 {
            let firstInterval: Interval = self.intervals[0]
            return firstInterval.b - firstInterval.a + 1
        }
        for var i: Int = 0; i < numIntervals; i++ {
            let I: Interval = intervals[i]
            n += (I.b - I.a + 1)
        }
        return n
    }


    public func toIntegerList() -> Array<Int> {
        var values: Array<Int> = Array<Int>()
        let n: Int = intervals.count
        for var i: Int = 0; i < n; i++ {
            let I: Interval = intervals[i]
            let a: Int = I.a
            let b: Int = I.b
            for var v: Int = a; v <= b; v++ {
                values.append(v)
            }
        }
        return values
    }


    public func toList() -> Array<Int> {
        var values: Array<Int> = Array<Int>()
        let n: Int = intervals.count
        for var i: Int = 0; i < n; i++ {
            let I: Interval = intervals[i]
            let a: Int = I.a
            let b: Int = I.b
            for var v: Int = a; v <= b; v++ {
                values.append(v)
            }
        }
        return values
    }

    public func toSet() -> Set<Int> {
        var s: Set<Int> = Set<Int>()
        for I: Interval in intervals {
            let a: Int = I.a
            let b: Int = I.b
            for var v: Int = a; v <= b; v++ {
                s.insert(v)
                //s.add(v);
            }
        }
        return s
    }

    /** Get the ith element of ordered set.  Used only by RandomPhrase so
     *  don't bother to implement if you're not doing that for a new
     *  ANTLR code gen target.
     */
    public func get(i: Int) -> Int {
        let n: Int = intervals.count
        var index: Int = 0
        for var j: Int = 0; j < n; j++ {
            let I: Interval = intervals[j]
            let a: Int = I.a
            let b: Int = I.b
            for var v: Int = a; v <= b; v++ {
                if index == i {
                    return v
                }
                index++
            }
        }
        return -1
    }

    public func toArray() -> [Int] {
        return toIntegerList()
    }


    public func remove(el: Int) throws {
        if readonly {
            throw ANTLRError.IllegalState(msg: "can't alter readonly IntervalSet")
        }
        let n: Int = intervals.count
        for var i: Int = 0; i < n; i++ {
            let I: Interval = intervals[i]
            let a: Int = I.a
            let b: Int = I.b
            if el < a {
                break // list is sorted and el is before this interval; not here
            }
            // if whole interval x..x, rm
            if el == a && el == b {
                intervals.removeAtIndex(i)
                //intervals.remove(i);
                break
            }
            // if on left edge x..b, adjust left
            if el == a {
                I.a++
                break
            }
            // if on right edge a..x, adjust right
            if el == b {
                I.b--
                break
            }
            // if in middle a..x..b, split interval
            if el > a && el < b {
                // found in this interval
                let oldb: Int = I.b
                I.b = el - 1      // [a..x-1]
                try add(el + 1, oldb) // add [x+1..b]
            }
        }
    }

    public func isReadonly() -> Bool {
        return readonly
    }

    public func setReadonly(readonly: Bool) throws {
        if self.readonly && !readonly {
            throw ANTLRError.IllegalState(msg: "can't alter readonly IntervalSet")

        }
        self.readonly = readonly
    }
}

public func ==(lhs: IntervalSet, rhs: IntervalSet) -> Bool {
    return lhs.intervals == rhs.intervals
}