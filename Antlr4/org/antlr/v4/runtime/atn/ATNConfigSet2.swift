///*
//* [The "BSD license"]
//*  Copyright (c) 2012 Terence Parr
//*  Copyright (c) 2012 Sam Harwell
//*  All rights reserved.
//*
//*  Redistribution and use in source and binary forms, with or without
//*  modification, are permitted provided that the following conditions
//*  are met:
//*
//*  1. Redistributions of source code must retain the above copyright
//*     notice, this list of conditions and the following disclaimer.
//*  2. Redistributions in binary form must reproduce the above copyright
//*     notice, this list of conditions and the following disclaimer in the
//*     documentation and/or other materials provided with the distribution.
//*  3. The name of the author may not be used to endorse or promote products
//*     derived from this software without specific prior written permission.
//*
//*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
//*  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//*  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//*  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
//*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//*  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//*  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//*  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
//*  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//*/
//
//// package org.antlr.v4.runtime.atn;
//
//// import org.antlr.v4.runtime.misc.AbstractEqualityComparator;
//// import org.antlr.v4.runtime.misc.Array2DHashSet;
//// import org.antlr.v4.runtime.misc.DoubleKeyMap;
//
//// import java.util.ArrayList;
//// import java.util.BitSet;
//// import java.util.Collection;
//// import java.util.HashSet;
//// import java.util.Iterator;
//// import java.util.List;
//// import java.util.Set;
//
///**
//* Specialized {@link java.util.Set}{@code <}{@link org.antlr.v4.runtime.atn.ATNConfig}{@code >} that can track
//* info about the set, with support for combining similar configurations using a
//* graph-structured stack.
//*/
////:  Set<ATNConfig>
//public class ATNConfigSet:Hashable,CustomStringConvertible{
//    /**
//    * The reason that we need this is because we don't want the hash map to use
//    * the standard hash code and equals. We need all configurations with the same
//    * {@code (s,i,_,semctx)} to be equal. Unfortunately, this key effectively doubles
//    * the number of objects associated with ATNConfigs. The other solution is to
//    * use a hash table that lets us specify the equals/hashcode operation.
//    */
//    /*public class ConfigHashSet  :  AbstractConfigHashSet {
//    public   init() {
//    super.init(ConfigEqualityComparator.INSTANCE);
//    }
//    }
//    
//    public final class ConfigEqualityComparator  :  AbstractEqualityComparator<ATNConfig> {
//    public let INSTANCE : ConfigEqualityComparator = ConfigEqualityComparator();
//    
//    private override init() {
//    }
//    
//    override
//    public func hashCode(o : ATNConfig) -> Int {
//    var hashCode : Int = 7;
//    hashCode = 31 * hashCode + o.state.stateNumber;
//    hashCode = 31 * hashCode + o.alt;
//    hashCode = 31 * hashCode + o.semanticContext.hashCode();
//    return hashCode;
//    }
//    
//    override
//    public func equals(a : ATNConfig, _ b : ATNConfig) -> Bool {
//    if ( a==b ) { return true; }
//    if ( a==nil || b==nil ) { return false; }
//    return a.state.stateNumber==b.state.stateNumber
//				&& a.alt==b.alt
//				&& a.semanticContext.equals(b.semanticContext);
//    }
//    }*/
//    
//    /** Indicates that the set of configurations is read-only. Do not
//    *  allow any code to manipulate the set; DFA states will point at
//    *  the sets and they must not change. This does not protect the other
//    *  fields; in particular, conflictingAlts is set after
//    *  we've made this readonly.
//    */
//    internal var readonly : Bool = false;
//    
//    /**
//    * All configs but hashed by (s, i, _, pi) not including context. Wiped out
//    * when we go readonly as this set becomes a DFA state.
//    */
//    public var configLookup : Set<LookupATNConfig> //AbstractConfigHashSet;
//    
//    /** Track the elements as they are added to the set; supports get(i) */
//    public var configs : Array<ATNConfig> = Array<ATNConfig>();
//    
//    // TODO: these fields make me pretty uncomfortable but nice to pack up info together, saves recomputation
//    // TODO: can we track conflicts as they are added to save scanning configs later?
//    public var uniqueAlt : Int  = 0;   //TODO no default
//    /** Currently this is only used when we detect SLL conflict; this does
//    *  not necessarily represent the ambiguous alternatives. In fact,
//    *  I should also point out that this seems to include predicated alternatives
//    *  that have predicates that evaluate to false. Computed in computeTargetState().
//    */
//    internal var conflictingAlts : BitSet?;
//    
//    // Used in parser and lexer. In lexer, it indicates we hit a pred
//    // while computing a closure operation.  Don't make a DFA state from this.
//    public var hasSemanticContext : Bool = false ;  //TODO no default
//    public var dipsIntoOuterContext : Bool = false  ;  //TODO no default
//    
//    /** Indicates that this configuration set is part of a full context
//    *  LL prediction. It will be used to determine how to merge $. With SLL
//    *  it's a wildcard whereas it is not for LL context merge.
//    */
//    public final var fullCtx : Bool;
//    
//    private var cachedHashCode : Int = -1;
//    
//    public init(_ fullCtx : Bool) {
//        configLookup =  Set<LookupATNConfig>()  //ConfigHashSet();
//        self.fullCtx = fullCtx;
//    }
//    public convenience init() {
//        self.init(true);
//    }
//    
//    public convenience init(_ old : ATNConfigSet) {
//        self.init(old.fullCtx);
//        addAll(old);
//        self.uniqueAlt = old.uniqueAlt;
//        self.conflictingAlts = old.conflictingAlts;
//        self.hasSemanticContext = old.hasSemanticContext;
//        self.dipsIntoOuterContext = old.dipsIntoOuterContext;
//    }
//    
//    //override
//    public func add(config : ATNConfig) -> Bool {
//        return add(config, nil);
//    }
//    
//    /**
//    * Adding a new config means merging contexts with existing configs for
//    * {@code (s, i, pi, _)}, where {@code s} is the
//    * {@link org.antlr.v4.runtime.atn.ATNConfig#state}, {@code i} is the {@link org.antlr.v4.runtime.atn.ATNConfig#alt}, and
//    * {@code pi} is the {@link org.antlr.v4.runtime.atn.ATNConfig#semanticContext}. We use
//    * {@code (s,i,pi)} as key.
//    *
//    * <p>This method updates {@link #dipsIntoOuterContext} and
//    * {@link #hasSemanticContext} when necessary.</p>
//    */
//    public func add(
//        config : ATNConfig,
//        _ mergeCache : DoubleKeyMap<PredictionContext,PredictionContext,PredictionContext>?) -> Bool
//    {
//        if ( readonly ) {
//            RuntimeException("This set is readonly")
//        }
//        // throwException() /* throw IllegalStateException("This set is readonly"); } */
//        if ( config.semanticContext != SemanticContext.NONE ) {
//            hasSemanticContext = true;
//        }
//        if (config.getOuterContextDepth() > 0) {
//            dipsIntoOuterContext = true;
//        }
//        let existing : ATNConfig =  getOrAdd(config);   //configLookup.getOrAdd(config);
//        if ( existing === config ) { // we added this new one
//            cachedHashCode = -1;
//            configs.append(config);  // track order here
//            return true;
//        }
//        // a previous (s,i,pi,_), merge with it and save result
//        let rootIsWildcard : Bool = !fullCtx;
//        let merged : PredictionContext =
//        PredictionContext.merge(existing.context!, config.context!, rootIsWildcard, mergeCache);
//        // no need to check for existing.context, config.context in cache
//        // since only way to create new graphs is "call rule" and here. We
//        // cache at both places.
//        existing.reachesIntoOuterContext =
//            max(existing.reachesIntoOuterContext, config.reachesIntoOuterContext);
//        
//        // make sure to preserve the precedence filter suppression during the merge
//        if (config.isPrecedenceFilterSuppressed()) {
//            existing.setPrecedenceFilterSuppressed(true);
//        }
//        
//        existing.context = merged; // replace context; no need to alt mapping
//        return true;
//    }
//    
//    public func getOrAdd(config : ATNConfig) ->ATNConfig{
//        //        for c:ATNConfig in self.configLookup {
//        //            if c==config {
//        //                return c
//        //            }
//        //        }
//        //modify by janyou
//        if configLookup is Set<OrderedATNConfig> {
//            let oConfig = OrderedATNConfig(config)
//            
//            //
//            //            if self.configLookup.contains(oConfig) {
//            //              for configInside in (self.configLookup as! Set<OrderedATNConfig>){
//            //
//            //                    if configInside == oConfig {
//            //                        return configInside.config
//            //                    }
//            //                }
//            //                //return config
//            //            }
//            
//            if let index = self.configLookup.indexOf(oConfig) {
//                return  self.configLookup[index].config
//            }
//            else {
//                self.configLookup.insert(oConfig)
//            }
//        }else {
//            let lConfig = LookupATNConfig(config)
//            //             if self.configLookup.contains(lConfig) {
//            //
//            //                //return config
//            //                for configInside in (self.configLookup ){
//            //                    if configInside == lConfig {
//            //                        return configInside.config
//            //                    }
//            //                }
//            //            }
//            if let index = self.configLookup.indexOf(lConfig) {
//                return  self.configLookup[index].config
//            }
//            else {
//                self.configLookup.insert(lConfig)
//            }
//        }
//        
//        return config
//        
//        
//        //        if self.configLookup.contains(config){
//        //            return config
//        //        }
//        //
//        //        self.configLookup.insert(config)
//        //        return config
//    }
//    
//    
//    /** Return a List holding list of configs */
//    public func elements() -> Array<ATNConfig> {
//        return configs;
//    }
//    
//    public func getStates() -> Set<ATNState> {
//        var states : Set<ATNState> = Set<ATNState>();
//        for c : ATNConfig in configs {
//            states.insert(c.state);
//        }
//        return states;
//    }
//    
//    /**
//    * Gets the complete set of represented alternatives for the configuration
//    * set.
//    *
//    * @return the set of represented alternatives in this configuration set
//    *
//    * @since 4.3
//    */
//    
//    public func getAlts() -> BitSet {
//        let alts : BitSet = BitSet();
//        for config : ATNConfig in configs {
//            alts.set(config.alt);
//        }
//        return alts;
//    }
//    
//    public func getPredicates() -> Array<SemanticContext> {
//        var preds : Array<SemanticContext> = Array<SemanticContext>();
//        for c : ATNConfig in configs {
//            if   c.semanticContext != SemanticContext.NONE  {
//                preds.append(c.semanticContext);
//            }
//        }
//        return preds;
//    }
//    
//    public func get(i : Int) -> ATNConfig { return configs[i]; }
//    
//    public func optimizeConfigs(interpreter : ATNSimulator) {
//        if ( readonly ) {
//            RuntimeException("This set is readonly")
//            // throwException() /* throw IllegalStateException("This set is readonly"); } */
//        }
//        if ( configLookup.isEmpty  ) { return; }
//        
//        for config : ATNConfig in configs {
//            //			int before = PredictionContext.getAllContextNodes(config.context).size();
//            config.context = interpreter.getCachedContext(config.context!);
//            //			int after = PredictionContext.getAllContextNodes(config.context).size();
//            //			System.out.println("configs "+before+"->"+after);
//        }
//    }
//    
//    
//    public func addAll(coll : ATNConfigSet) -> Bool {
//        for c : ATNConfig in coll.configs {
//            add(c);
//        }
//        return false;
//    }
//    
//    
//    /*public func equals(o : AnyObject) -> Bool {
//    if (o as! String == self) {
//    return true;
//    }
//    else { if (!(o is ATNConfigSet)) {
//    return false;
//    } }
//    
//    //		System.out.print("equals " + this + ", " + o+" = ");
//    var other : ATNConfigSet = o as! ATNConfigSet;
//    var same : Bool = configs=nil &&
//    configs.equals(other.configs) &&  // includes stack context
//    self.fullCtx == other.fullCtx &&
//    self.uniqueAlt == other.uniqueAlt &&
//    self.conflictingAlts == other.conflictingAlts &&
//    self.hasSemanticContext == other.hasSemanticContext &&
//    self.dipsIntoOuterContext == other.dipsIntoOuterContext;
//    
//    //		System.out.println(same);
//    return same;
//    }*/
//    
//    public var hashValue:Int {
//        if  isReadonly()  {
//            if (cachedHashCode == -1) {
//                cachedHashCode = configsHashValue//configs.hashValue ;
//            }
//            
//            return cachedHashCode;
//        }
//        
//        return configsHashValue // configs.hashValue;
//    }
//    
//    private var configsHashValue:Int {
//        var hashCode = 1;
//        for  item in   configs {
//            hashCode =  Int.multiplyWithOverflow(3, hashCode).0
//            hashCode =  Int.addWithOverflow(hashCode, item.hashValue).0
//            
//        }
//        return hashCode;
//        
//    }
//    
//    
//    public func size() -> Int {
//        return configs.count;
//    }
//    
//    
//    public func isEmpty() -> Bool {
//        return configs.isEmpty;
//    }
//    
//    
//    public func contains(o : ATNConfig) -> Bool {
//        //if (configLookup == nil) {
//        //  RuntimeException("This method is not implemented for readonly sets.")
//        //throwException() /* throw UnsupportedOperationException("This method is not implemented for readonly sets."); */
//        //}
//        if configLookup is Set<OrderedATNConfig> {
//            return self.configLookup.contains(OrderedATNConfig(o))
//        }else {
//            return self.configLookup.contains(LookupATNConfig(o))
//        }
//        //return configLookup.contains(o);
//    }
//    
//    /*public func containsFast(obj : ATNConfig) -> Bool {
//    if (configLookup == nil) {
//    RuntimeException("This method is not implemented for readonly sets.")
//    //throwException() /* throw UnsupportedOperationException("This method is not implemented for readonly sets."); */
//    }
//    
//    return configLookup!.containsFast(obj);
//    }*/
//    
//    
//    //public func iterator() -> Iterator<ATNConfig> {
//    //return configs.iterator();
//    //}
//    
//    
//    public func clear() {
//        if ( readonly ) {
//            RuntimeException("This set is readonly")
//            // throwException() /* throw IllegalStateException("This set is readonly"); } */
//        }
//        configs.removeAll()
//        cachedHashCode = -1;
//        configLookup.removeAll()
//    }
//    
//    public func isReadonly() -> Bool {
//        return readonly;
//    }
//    
//    public func setReadonly(readonly : Bool) {
//        self.readonly = readonly;
//        configLookup.removeAll()
//        //configLookup = nil; // can't mod, no need for lookup cache
//    }
//    
//    public var description:String {
//        let buf : StringBuilder = StringBuilder();
//        buf.append(elements().map({$0.description}) );
//        if ( hasSemanticContext ) {
//            buf.append(",hasSemanticContext=").append(hasSemanticContext);
//        }
//        if ( uniqueAlt != ATN.INVALID_ALT_NUMBER ) {
//            buf.append(",uniqueAlt=").append(uniqueAlt);
//        }
//        if ( conflictingAlts != nil ) {
//            buf.append(",conflictingAlts=").append(conflictingAlts!.description);
//        }
//        if ( dipsIntoOuterContext ) {
//            buf.append(",dipsIntoOuterContext");
//        }
//        return buf.toString();
//    }
//    public func toString() -> String {
//        
//        return description;
//    }
//    
//    // satisfy interface
//    
//    
//    public func toArray() -> [ATNConfig] {
//        return  Array( configLookup.map{$0.config}) ;
//    }
//    
//    /*override
//    public <T> func toArray(a : [T]) -> [T] {
//    return configLookup.toArray(a);
//    }*/
//    
//    /*
//    public func remove(o : AnyObject)   -> Bool {
//    throw ANTLRError.UnsupportedOperation /* throw UnsupportedOperationException(); */
//    }
//    
//    
//    public func containsAll(c : Collection<AnyObject>) -> Bool {
//    throwException() /* throw UnsupportedOperationException(); */
//    }
//    
//    
//    public func retainAll(c : Collection<AnyObject>) -> Bool {
//    throwException() /* throw UnsupportedOperationException(); */
//    }
//    
//    
//    public func removeAll(c : Collection<AnyObject>) -> Bool {
//    throwException() /* throw UnsupportedOperationException(); */
//    }
//    */
//    /*public   class AbstractConfigHashSet  :  Array2DHashSet<ATNConfig> {
//    
//    public convenience init(_ comparator : AbstractEqualityComparator<super ATNConfig>) {
//    self.init(comparator, 16, 2);
//    }
//    
//    public   init(_ comparator : AbstractEqualityComparator<super ATNConfig>, _ initialCapacity : Int, _ initialBucketCapacity : Int) {
//    super.init(comparator, initialCapacity, initialBucketCapacity);
//    }
//    
//    //override
//    internal   func asElementType(o : AnyObject) -> ATNConfig? {
//    if (!(o is ATNConfig)) {
//				return nil;
//    }
//    
//    return o as! ATNConfig;
//    }
//    
//    override
//    internal final func createBuckets(capacity : Int) -> [ATNConfig] {
//    return [ATNConfig]()    //new ATNConfig[capacity][];
//    }
//    
//    override
//    internal final func createBucket(capacity : Int) -> [ATNConfig] {
//    return  [ATNConfig]()  //new ATNConfig[capacity];
//    }
//    
//    }*/
//}
//
//
//public func  == (lhs:ATNConfigSet,rhs:ATNConfigSet) ->Bool{
//    
//    if (lhs === rhs) {
//        return true;
//    }
//    
//    
//    
//    
//    let same : Bool =
//    lhs.configs == rhs.configs  &&  // includes stack context
//        lhs.fullCtx == rhs.fullCtx &&
//        lhs.uniqueAlt == rhs.uniqueAlt &&
//        lhs.conflictingAlts == rhs.conflictingAlts &&
//        lhs.hasSemanticContext == rhs.hasSemanticContext &&
//        lhs.dipsIntoOuterContext == rhs.dipsIntoOuterContext;
//    
//    //		System.out.println(same);
//    return same;
//    
//}