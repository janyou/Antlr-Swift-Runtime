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


import Foundation

public class PredictionContext: Hashable, CustomStringConvertible {
    /**
     * Represents {@code $} in local context prediction, which means wildcard.
     * {@code *+x = *}.
     */
    public static let EMPTY: EmptyPredictionContext = EmptyPredictionContext()

    /**
     * Represents {@code $} in an array in full context mode, when {@code $}
     * doesn't mean wildcard: {@code $ + x = [$,x]}. Here,
     * {@code $} = {@link #EMPTY_RETURN_STATE}.
     */
    public static let EMPTY_RETURN_STATE: Int = Int(Int32.max)

    private static let INITIAL_HASH: Int = 1

    public static var globalNodeCount: Int = 0
    public var id: Int = {
        return globalNodeCount++
    }()

    /**
     * Stores the computed hash code of this {@link org.antlr.v4.runtime.atn.PredictionContext}. The hash
     * code is computed in parts to match the following reference algorithm.
     *
     * <pre>
     *  private int referenceHashCode() {
     *      int hash = {@link org.antlr.v4.runtime.misc.MurmurHash#initialize MurmurHash.initialize}({@link #INITIAL_HASH});
     *
     *      for (int i = 0; i &lt; {@link #size()}; i++) {
     *          hash = {@link org.antlr.v4.runtime.misc.MurmurHash#update MurmurHash.update}(hash, {@link #getParent getParent}(i));
     *      }
     *
     *      for (int i = 0; i &lt; {@link #size()}; i++) {
     *          hash = {@link org.antlr.v4.runtime.misc.MurmurHash#update MurmurHash.update}(hash, {@link #getReturnState getReturnState}(i));
     *      }
     *
     *      hash = {@link org.antlr.v4.runtime.misc.MurmurHash#finish MurmurHash.finish}(hash, 2 * {@link #size()});
     *      return hash;
     *  }
     * </pre>
     */
    public let cachedHashCode: Int

    init(_ cachedHashCode: Int) {
        self.cachedHashCode = cachedHashCode
    }

    /** Convert a {@link org.antlr.v4.runtime.RuleContext} tree to a {@link org.antlr.v4.runtime.atn.PredictionContext} graph.
     *  Return {@link #EMPTY} if {@code outerContext} is empty or null.
     */
    public class func fromRuleContext(atn: ATN, var _ outerContext: RuleContext?) -> PredictionContext {
        if (outerContext == nil) {
            outerContext = RuleContext.EMPTY
        }

        // if we are in RuleContext of start rule, s, then PredictionContext
        // is EMPTY. Nobody called us. (if we are empty, return empty)
        if (outerContext!.parent == nil || outerContext! === RuleContext.EMPTY) {
            return PredictionContext.EMPTY
        }

        // If we have a parent, convert it to a PredictionContext graph
        var parent: PredictionContext = EMPTY
        parent = PredictionContext.fromRuleContext(atn, outerContext!.parent)

        let state: ATNState = atn.states[outerContext!.invokingState]!
        let transition: RuleTransition = state.transition(0) as! RuleTransition
        return SingletonPredictionContext.create(parent, transition.followState.stateNumber)
    }

    public func size() -> Int {
        RuntimeException(__FUNCTION__ + " must be overridden")
        return 0
    }


    public func getParent(index: Int) -> PredictionContext? {
        RuntimeException(__FUNCTION__ + " must be overridden")
        return nil
    }


    public func getReturnState(index: Int) -> Int {
        RuntimeException(__FUNCTION__ + " must be overridden")
        return 0
    }


    /** This means only the {@link #EMPTY} context is in set. */
    public func isEmpty() -> Bool {
        return self == PredictionContext.EMPTY
    }

    public func hasEmptyPath() -> Bool {
        return getReturnState(size() - 1) == PredictionContext.EMPTY_RETURN_STATE
    }

    public var hashValue: Int {
        return cachedHashCode
    }


    class func calculateEmptyHashCode() -> Int {
        var hash: Int = MurmurHash.initialize(INITIAL_HASH)
        hash = MurmurHash.finish(hash, 0)
        return hash
    }

    class func calculateHashCode(parent: PredictionContext?, _ returnState: Int) -> Int {
        var hash: Int = MurmurHash.initialize(INITIAL_HASH)
        hash = MurmurHash.update(hash, parent)
        hash = MurmurHash.update(hash, returnState)
        hash = MurmurHash.finish(hash, 2)
        return hash
    }

    class func calculateHashCode(parents: [PredictionContext?], _ returnStates: [Int]) -> Int {
        var hash: Int = MurmurHash.initialize(INITIAL_HASH)

        for parent: PredictionContext? in parents {
            hash = MurmurHash.update(hash, parent)
        }

        for returnState: Int in returnStates {
            hash = MurmurHash.update(hash, returnState)
        }

        hash = MurmurHash.finish(hash, 2 * parents.count)
        return hash
    }

    // dispatch
    public class func merge(
            var a: PredictionContext,
            var _ b: PredictionContext,
            _ rootIsWildcard: Bool,
            _ mergeCache: DoubleKeyMap<PredictionContext, PredictionContext, PredictionContext>?) -> PredictionContext {
        // assert ( a != nil && b != nil,"Expected: a!=null&&b!=null");
        //assert ( a!=nil && b!=nil,"Expected: a!=null&&b!=null"); // must be empty context, never null
        // share same graph if both same


        if a == b {
            return a
        }

        if (a is SingletonPredictionContext && b is SingletonPredictionContext) {
            return mergeSingletons(a as! SingletonPredictionContext,
                    b as! SingletonPredictionContext,
                    rootIsWildcard, mergeCache)
        }

        // At least one of a or b is array
        // If one is $ and rootIsWildcard, return $ as * wildcard
        if (rootIsWildcard) {
            if (a is EmptyPredictionContext) {
                return a
            }
            if (b is EmptyPredictionContext) {
                return b
            }
        }

        // convert singleton so both are arrays to normalize
        if (a is SingletonPredictionContext) {
            a = ArrayPredictionContext(a as! SingletonPredictionContext)
        }
        if (b is SingletonPredictionContext) {
            b = ArrayPredictionContext(b as! SingletonPredictionContext)
        }
        return mergeArrays(a as! ArrayPredictionContext, b as! ArrayPredictionContext,
                rootIsWildcard, mergeCache)
    }

    /**
     * Merge two {@link org.antlr.v4.runtime.atn.SingletonPredictionContext} instances.
     *
     * <p>Stack tops equal, parents merge is same; return left graph.<br>
     * <embed src="images/SingletonMerge_SameRootSamePar.svg" type="image/svg+xml"/></p>
     *
     * <p>Same stack top, parents differ; merge parents giving array node, then
     * remainders of those graphs. A new root node is created to point to the
     * merged parents.<br>
     * <embed src="images/SingletonMerge_SameRootDiffPar.svg" type="image/svg+xml"/></p>
     *
     * <p>Different stack tops pointing to same parent. Make array node for the
     * root where both element in the root point to the same (original)
     * parent.<br>
     * <embed src="images/SingletonMerge_DiffRootSamePar.svg" type="image/svg+xml"/></p>
     *
     * <p>Different stack tops pointing to different parents. Make array node for
     * the root where each element points to the corresponding original
     * parent.<br>
     * <embed src="images/SingletonMerge_DiffRootDiffPar.svg" type="image/svg+xml"/></p>
     *
     * @param a the first {@link org.antlr.v4.runtime.atn.SingletonPredictionContext}
     * @param b the second {@link org.antlr.v4.runtime.atn.SingletonPredictionContext}
     * @param rootIsWildcard {@code true} if this is a local-context merge,
     * otherwise false to indicate a full-context merge
     * @param mergeCache
     */
    public class func mergeSingletons(
            a: SingletonPredictionContext,
            _ b: SingletonPredictionContext,
            _ rootIsWildcard: Bool,
            _ mergeCache: DoubleKeyMap<PredictionContext, PredictionContext, PredictionContext>?) -> PredictionContext {
        if a is EmptyPredictionContext {
            // print("parenet is null")
        }
        if (mergeCache != nil) {
            var previous: PredictionContext? = mergeCache!.get(a, b)
            if previous != nil {
                return previous!
            }
            previous = mergeCache!.get(b, a)
            if previous != nil {
                return previous!
            }
        }

        let rootMerge: PredictionContext? = mergeRoot(a, b, rootIsWildcard)
        if rootMerge != nil {
            if mergeCache != nil {
                mergeCache!.put(a, b, rootMerge!)
            }
            return rootMerge!
        }

        if (a.returnState == b.returnState) {
            // a == b
            let parent: PredictionContext = merge(a.parent!, b.parent!, rootIsWildcard, mergeCache);
            // if parent is same as existing a or b parent or reduced to a parent, return it
            if (parent == a.parent!) {
                return a
            } // ax + bx = ax, if a=b
            if (parent == b.parent!) {
                return b
            } // ax + bx = bx, if a=b
            // else: ax + ay = a'[x,y]
            // merge parents x and y, giving array node with x,y then remainders
            // of those graphs.  dup a, a' points at merged array
            // new joined parent so create new singleton pointing to it, a'
            let a_: PredictionContext = SingletonPredictionContext.create(parent, a.returnState);
            if (mergeCache != nil) {
                mergeCache!.put(a, b, a_)
            }
            return a_
        } else {
            // a != b payloads differ
            // see if we can collapse parents due to $+x parents if local ctx
            var singleParent: PredictionContext? = nil;
            //added by janyou
            if a == b || (a.parent != nil && a.parent! == b.parent) {
                // ax + bx = [a,b]x
                singleParent = a.parent
            }
            if (singleParent != nil) {
                // parents are same
                // sort payloads and use same parent
                var payloads: [Int] = [a.returnState, b.returnState];
                if (a.returnState > b.returnState) {
                    payloads[0] = b.returnState
                    payloads[1] = a.returnState
                }
                let parents: [PredictionContext?] = [singleParent, singleParent]
                let a_: PredictionContext = ArrayPredictionContext(parents, payloads)
                if (mergeCache != nil) {
                    mergeCache!.put(a, b, a_)
                }
                return a_
            }
            // parents differ and can't merge them. Just pack together
            // into array; can't merge.
            // ax + by = [ax,by]
            var payloads: [Int] = [a.returnState, b.returnState]
            var parents: [PredictionContext?] = [a.parent, b.parent];
            if (a.returnState > b.returnState) {
                // sort by payload
                payloads[0] = b.returnState
                payloads[1] = a.returnState
                parents = [b.parent, a.parent]
            }
            if a is EmptyPredictionContext {
                // print("parenet is null")
            }
            let a_: PredictionContext = ArrayPredictionContext(parents, payloads);
            if (mergeCache != nil) {
                mergeCache!.put(a, b, a_)
            }
            return a_
        }
    }

    /**
     * Handle case where at least one of {@code a} or {@code b} is
     * {@link #EMPTY}. In the following diagrams, the symbol {@code $} is used
     * to represent {@link #EMPTY}.
     *
     * <h2>Local-Context Merges</h2>
     *
     * <p>These local-context merge operations are used when {@code rootIsWildcard}
     * is true.</p>
     *
     * <p>{@link #EMPTY} is superset of any graph; return {@link #EMPTY}.<br>
     * <embed src="images/LocalMerge_EmptyRoot.svg" type="image/svg+xml"/></p>
     *
     * <p>{@link #EMPTY} and anything is {@code #EMPTY}, so merged parent is
     * {@code #EMPTY}; return left graph.<br>
     * <embed src="images/LocalMerge_EmptyParent.svg" type="image/svg+xml"/></p>
     *
     * <p>Special case of last merge if local context.<br>
     * <embed src="images/LocalMerge_DiffRoots.svg" type="image/svg+xml"/></p>
     *
     * <h2>Full-Context Merges</h2>
     *
     * <p>These full-context merge operations are used when {@code rootIsWildcard}
     * is false.</p>
     *
     * <p><embed src="images/FullMerge_EmptyRoots.svg" type="image/svg+xml"/></p>
     *
     * <p>Must keep all contexts; {@link #EMPTY} in array is a special value (and
     * null parent).<br>
     * <embed src="images/FullMerge_EmptyRoot.svg" type="image/svg+xml"/></p>
     *
     * <p><embed src="images/FullMerge_SameRoot.svg" type="image/svg+xml"/></p>
     *
     * @param a the first {@link org.antlr.v4.runtime.atn.SingletonPredictionContext}
     * @param b the second {@link org.antlr.v4.runtime.atn.SingletonPredictionContext}
     * @param rootIsWildcard {@code true} if this is a local-context merge,
     * otherwise false to indicate a full-context merge
     */
    public class func mergeRoot(a: SingletonPredictionContext,
                                _ b: SingletonPredictionContext,
                                _ rootIsWildcard: Bool) -> PredictionContext? {
        if (rootIsWildcard) {
            if (a == PredictionContext.EMPTY) {
                return PredictionContext.EMPTY
            }  // * + b = *
            if (b == PredictionContext.EMPTY) {
                return PredictionContext.EMPTY
            }  // a + * = *
        } else {
            if (a == PredictionContext.EMPTY && b == PredictionContext.EMPTY) {
                return PredictionContext.EMPTY
            } // $ + $ = $
            if (a == PredictionContext.EMPTY) {
                // $ + x = [$,x]
                let payloads: [Int] = [b.returnState, EMPTY_RETURN_STATE]
                let parents: [PredictionContext?] = [b.parent, nil]
                let joined: PredictionContext =
                ArrayPredictionContext(parents, payloads)
                return joined;
            }
            if (b == PredictionContext.EMPTY) {
                // x + $ = [$,x] ($ is always first if present)
                let payloads: [Int] = [a.returnState, EMPTY_RETURN_STATE]
                let parents: [PredictionContext?] = [a.parent, nil]
                let joined: PredictionContext =
                ArrayPredictionContext(parents, payloads)
                return joined
            }
        }
        return nil
    }

    /**
     * Merge two {@link org.antlr.v4.runtime.atn.ArrayPredictionContext} instances.
     *
     * <p>Different tops, different parents.<br>
     * <embed src="images/ArrayMerge_DiffTopDiffPar.svg" type="image/svg+xml"/></p>
     *
     * <p>Shared top, same parents.<br>
     * <embed src="images/ArrayMerge_ShareTopSamePar.svg" type="image/svg+xml"/></p>
     *
     * <p>Shared top, different parents.<br>
     * <embed src="images/ArrayMerge_ShareTopDiffPar.svg" type="image/svg+xml"/></p>
     *
     * <p>Shared top, all shared parents.<br>
     * <embed src="images/ArrayMerge_ShareTopSharePar.svg" type="image/svg+xml"/></p>
     *
     * <p>Equal tops, merge parents and reduce top to
     * {@link org.antlr.v4.runtime.atn.SingletonPredictionContext}.<br>
     * <embed src="images/ArrayMerge_EqualTop.svg" type="image/svg+xml"/></p>
     */
    public class func mergeArrays(
            a: ArrayPredictionContext,
            _ b: ArrayPredictionContext,
            _ rootIsWildcard: Bool,
            _ mergeCache: DoubleKeyMap<PredictionContext, PredictionContext, PredictionContext>?) -> PredictionContext {

        if (mergeCache != nil) {
            var previous: PredictionContext? = mergeCache!.get(a, b)
            if (previous != nil) {
                return previous!
            }
            previous = mergeCache!.get(b, a)
            if (previous != nil) {
                return previous!
            }
        }

        // merge sorted payloads a + b => M
        var i: Int = 0 // walks a
        var j: Int = 0 // walks b
        var k: Int = 0// walks target M array

        var mergedReturnStates: [Int] = [Int](count: a.returnStates.count + b.returnStates.count, repeatedValue: 0)

        var mergedParents: [PredictionContext?] = [PredictionContext?](count: a.returnStates.count + b.returnStates.count, repeatedValue: nil)
        //new PredictionContext[a.returnStates.length + b.returnStates.length];
        // walk and merge to yield mergedParents, mergedReturnStates
        while i < a.returnStates.count && j < b.returnStates.count {
            let a_parent: PredictionContext? = a.parents[i]
            let b_parent: PredictionContext? = b.parents[j]
            if (a.returnStates[i] == b.returnStates[j]) {
                // same payload (stack tops are equal), must yield merged singleton
                let payload: Int = a.returnStates[i]
                // $+$ = $
                let both$: Bool = ((payload == EMPTY_RETURN_STATE) &&
                        a_parent == nil && b_parent == nil)
                let ax_ax: Bool = (a_parent != nil && b_parent != nil) && a_parent! == b_parent!  // ax+ax -> ax
                if (both$ || ax_ax) {
                    mergedParents[k] = a_parent // choose left
                    mergedReturnStates[k] = payload
                } else {
                    // ax+ay -> a'[x,y]
                    let mergedParent: PredictionContext =
                    merge(a_parent!, b_parent!, rootIsWildcard, mergeCache)
                    mergedParents[k] = mergedParent
                    mergedReturnStates[k] = payload
                }
                i++ // hop over left one as usual
                j++ // but also skip one in right side since we merge
            } else if (a.returnStates[i] < b.returnStates[j]) {
                // copy a[i] to M
                mergedParents[k] = a_parent
                mergedReturnStates[k] = a.returnStates[i]
                i++
            } else {
                // b > a, copy b[j] to M
                mergedParents[k] = b_parent
                mergedReturnStates[k] = b.returnStates[j]
                j++
            }
            k++
        }

        // copy over any payloads remaining in either array
        if (i < a.returnStates.count) {
            for var p: Int = i; p < a.returnStates.count; p++ {
                mergedParents[k] = a.parents[p]
                mergedReturnStates[k] = a.returnStates[p]
                k++
            }
        } else {
            for var p: Int = j; p < b.returnStates.count; p++ {
                mergedParents[k] = b.parents[p]
                mergedReturnStates[k] = b.returnStates[p]
                k++
            }
        }

        // trim merged if we combined a few that had same stack tops
        if (k < mergedParents.count) {
            // write index < last position; trim
            if (k == 1) {
                // for just one merged element, return singleton top
                let a_: PredictionContext =
                SingletonPredictionContext.create(mergedParents[0],
                        mergedReturnStates[0])
                if (mergeCache != nil) {
                    mergeCache!.put(a, b, a_)
                }
                //print("merge array 1 \(a_)")
                return a_
            }
            mergedParents = Array(mergedParents[0 ..< k])
            mergedReturnStates = Array(mergedReturnStates[0 ..< k])
        }

        let M: PredictionContext =
        ArrayPredictionContext(mergedParents, mergedReturnStates)

        // if we created same array as a or b, return that instead
        // TODO: track whether this is possible above during merge sort for speed
        if M == a {
            if mergeCache != nil {
                mergeCache!.put(a, b, a)
            }
            //print("merge array 2 \(a)")
            return a
        }
        if M == b {
            if mergeCache != nil {
                mergeCache!.put(a, b, b)
            }
            // print("merge array 3 \(b)")
            return b
        }

        combineCommonParents(&mergedParents)

        if mergeCache != nil {
            mergeCache!.put(a, b, M)
        }
        // print("merge array 4 \(M)")
        return M
    }

    /**
     * Make pass over all <em>M</em> {@code parents}; merge any {@code equals()}
     * ones.
     */
    internal class func combineCommonParents(inout parents: [PredictionContext?]) {
        var uniqueParents: Dictionary<PredictionContext, PredictionContext> =
        Dictionary<PredictionContext, PredictionContext>()

        for var p: Int = 0; p < parents.count; p++ {
            let parent: PredictionContext? = parents[p]
            if parent != nil && !uniqueParents.keys.contains(parent!) {
                // don't replace
                uniqueParents[parent!] = parent
            }
        }

        for var p: Int = 0; p < parents.count; p++ {
            parents[p] = (parents[p] == nil) ? nil : uniqueParents[parents[p]!]
        }

    }

    public class func toDOTString(context: PredictionContext?) -> String {
        if (context == nil) {
            return ""
        }
        let buf: StringBuilder = StringBuilder()
        buf.append("digraph G {\n")
        buf.append("rankdir=LR;\n")

        var nodes: Array<PredictionContext> = getAllContextNodes(context!)

        nodes.sortInPlace({ $0.id > $1.id })


        for current: PredictionContext in nodes {
            if (current is SingletonPredictionContext) {
                let s: String = String(current.id)
                buf.append("  s").append(s)
                var returnState: String = String(current.getReturnState(0))
                if (current is EmptyPredictionContext) {
                    returnState = "$"
                }
                buf.append(" [label=\"").append(returnState).append("\"];\n")
                continue
            }
            let arr: ArrayPredictionContext = current as! ArrayPredictionContext
            buf.append("  s").append(arr.id)
            buf.append(" [shape=box, label=\"")
            buf.append("[")
            var first: Bool = true
            for inv: Int in arr.returnStates {
                if (!first) {
                    buf.append(", ")
                }
                if (inv == EMPTY_RETURN_STATE) {
                    buf.append("$")
                } else {
                    buf.append(inv)
                }
                first = false
            }
            buf.append("]")
            buf.append("\"];\n")
        }

        for current: PredictionContext in nodes {
            if (current == EMPTY) {
                continue
            }
            for var i: Int = 0; i < current.size(); i++ {
                if (current.getParent(i) == nil) {
                    continue
                }
                let s: String = String(current.id)
                buf.append("  s").append(s)
                buf.append("->")
                buf.append("s")
                buf.append(current.getParent(i)!.id)
                if (current.size() > 1) {
                    buf.append(" [label=\"parent[" + String(i) + "]\"];\n"); } else {
                    buf.append(";\n")
                }
            }
        }

        buf.append("}\n")
        return buf.toString()
    }

    // From Sam
    public class func getCachedContext(
            context: PredictionContext,
            _ contextCache: PredictionContextCache,
            inout _ visited: Dictionary<PredictionContext, PredictionContext>) -> PredictionContext {
        if (context.isEmpty()) {
            return context
        }

        var existing: PredictionContext? = visited[context]
        if (existing != nil) {
            return existing!
        }

        existing = contextCache.get(context)
        if (existing != nil) {
            visited[context] = existing!
            return existing!
        }

        var changed: Bool = false
        var parents: [PredictionContext?] = [PredictionContext?](count: context.size(), repeatedValue: nil)
        for var i: Int = 0; i < parents.count; i++ {
            //added by janyou
            if context.getParent(i) == nil {
                return context
            }

            let parent: PredictionContext = getCachedContext(context.getParent(i)!, contextCache, &visited)
            if (changed || parent != context.getParent(i)) {
                if (!changed) {
                    parents = [PredictionContext?](count: context.size(), repeatedValue: nil)
                    for var j: Int = 0; j < context.size(); j++ {
                        parents[j] = context.getParent(j)
                    }

                    changed = true
                }

                parents[i] = parent
            }
        }

        if (!changed) {
            contextCache.add(context)
            visited[context] = context
            return context
        }

        var updated: PredictionContext
        if (parents.count == 0) {
            updated = EMPTY
        } else {
            if (parents.count == 1) {
                updated = SingletonPredictionContext.create(parents[0], context.getReturnState(0))
            } else {
                let arrayPredictionContext: ArrayPredictionContext = context as! ArrayPredictionContext
                updated = ArrayPredictionContext(parents, arrayPredictionContext.returnStates)
            }
        }

        contextCache.add(updated)
        visited[updated] = updated
        visited[context] = updated

        return updated
    }



    // ter's recursive version of Sam's getAllNodes()
    public class func getAllContextNodes(context: PredictionContext) -> Array<PredictionContext> {
        var nodes: Array<PredictionContext> = Array<PredictionContext>()
        var visited: Dictionary<PredictionContext, PredictionContext> =
        Dictionary<PredictionContext, PredictionContext>()
        getAllContextNodes_(context, &nodes, &visited)
        return nodes
    }

    public class func getAllContextNodes_(context: PredictionContext?,
                                          inout _ nodes: Array<PredictionContext>,
                                          inout _ visited: Dictionary<PredictionContext, PredictionContext>) {
        if (context == nil || visited.keys.contains(context!)) {
            return
        }
        visited[context!] = context!
        nodes.append(context!)
        for var i: Int = 0; i < context!.size(); i++ {
            getAllContextNodes_(context!.getParent(i), &nodes, &visited)
        }
    }

    public func toString<T:ATNSimulator>(recog: Recognizer<T>) -> String {
        return NSStringFromClass(PredictionContext.self)
//		return toString(recog, ParserRuleContext.EMPTY);
    }

    public func toStrings<T:ATNSimulator>(recognizer: Recognizer<T>, _ currentState: Int) -> [String] {
        return toStrings(recognizer, PredictionContext.EMPTY, currentState)
    }

    // FROM SAM
    public func toStrings<T:ATNSimulator>(recognizer: Recognizer<T>?, _ stop: PredictionContext, _ currentState: Int) -> [String] {
        var result: Array<String> = Array<String>()

        outer:
        for var perm: Int = 0;; perm++ {
            var offset: Int = 0
            var last: Bool = true
            var p: PredictionContext = self
            var stateNumber: Int = currentState
            let localBuffer: StringBuilder = StringBuilder()
            localBuffer.append("[")
            while !p.isEmpty() && p != stop {
                var index: Int = 0
                if (p.size() > 0) {
                    var bits: Int = 1
                    while (1 << bits) < p.size() {
                        bits++
                    }

                    let mask: Int = (1 << bits) - 1
                    index = (perm >> offset) & mask

                    //last &= index >= p.size() - 1;
                    //last = Bool(Int(last) & (index >= p.size() - 1));
                    last = last && (index >= p.size() - 1)

                    if (index >= p.size()) {
                        continue outer
                    }
                    offset += bits
                }

                if (recognizer != nil) {
                    if (localBuffer.length > 1) {
                        // first char is '[', if more than that this isn't the first rule
                        localBuffer.append(" ")
                    }

                    let atn: ATN = recognizer!.getATN()
                    let s: ATNState = atn.states[stateNumber]!
                    let ruleName: String = recognizer!.getRuleNames()[s.ruleIndex!]
                    localBuffer.append(ruleName)
                } else {
                    if (p.getReturnState(index) != PredictionContext.EMPTY_RETURN_STATE) {
                        if (!p.isEmpty()) {
                            if (localBuffer.length > 1) {
                                // first char is '[', if more than that this isn't the first rule
                                localBuffer.append(" ")
                            }

                            localBuffer.append(p.getReturnState(index))
                        }
                    }
                }
                stateNumber = p.getReturnState(index)
                p = p.getParent(index)!
            }
            localBuffer.append("]")
            result.append(localBuffer.toString())

            if (last) {
                break
            }
        }

        return result
    }

    public var description: String {
        return String(PredictionContext.self) + "@" + String(unsafeAddressOf(self).hashValue)
    }
}


public func ==(lhs: RuleContext, rhs: ParserRuleContext) -> Bool {
    if !(lhs is ParserRuleContext) {
        return false
    }
    return (lhs as! ParserRuleContext) === rhs
}

public func ==(lhs: PredictionContext, rhs: PredictionContext) -> Bool {

    if lhs === rhs {
        return true
    }
    if (lhs is EmptyPredictionContext) {
        return lhs === rhs
    }
    if (lhs is SingletonPredictionContext) && !(rhs is SingletonPredictionContext) {
        return false
    }
    if (lhs is SingletonPredictionContext) && (rhs is SingletonPredictionContext) {
        return (lhs as! SingletonPredictionContext) == (rhs as! SingletonPredictionContext)
    }

    if (lhs is ArrayPredictionContext) && !(rhs is ArrayPredictionContext) {
        return false
    }
    if (lhs is ArrayPredictionContext) && (rhs is ArrayPredictionContext) {
        return (lhs as! ArrayPredictionContext) == (rhs as! ArrayPredictionContext)
    }

    return false
}

public func ==(lhs: ArrayPredictionContext, rhs: SingletonPredictionContext) -> Bool {
    return false
}

public func ==(lhs: SingletonPredictionContext, rhs: ArrayPredictionContext) -> Bool {
    return false
}

public func ==(lhs: SingletonPredictionContext, rhs: EmptyPredictionContext) -> Bool {
    return lhs == (rhs as SingletonPredictionContext)
}

public func ==(lhs: EmptyPredictionContext, rhs: ArrayPredictionContext) -> Bool {
    return lhs === rhs
}

public func ==(lhs: EmptyPredictionContext, rhs: SingletonPredictionContext) -> Bool {
    return lhs === rhs
}
