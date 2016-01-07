import Foundation

//https://github.com/pNre/ExSwift/blob/master/ExSwift/Array.swift
extension Array {

    mutating func concat(addArray: [Element]) -> [Element] {
        return self + addArray
    }

    mutating func removeObject<T:Equatable>(object: T) {
        var index: Int?
        for (idx, objectToCompare) in self.enumerate() {

            if let to = objectToCompare as? T {
                if object == to {
                    index = idx
                }
            }
        }

        if index != nil {

            self.removeAtIndex(index!)
        }

    }

    /**
    Removes the last element from self and returns it.
    
    :returns: The removed element
    */
    mutating func pop() -> Element {
        return removeLast()
    }
    /**
    Same as append.
    
    :param: newElement Element to append
    */
    mutating func push(newElement: Element) {
        return append(newElement)
    }

    func all(test: (Element) -> Bool) -> Bool {
        for item in self {
            if !test(item) {
                return false
            }
        }

        return true
    }


    /**
    Checks if test returns true for all the elements in self
    
    :param: test Function to call for each element
    :returns: True if test returns true for all the elements in self
    */
    func every(test: (Element) -> Bool) -> Bool {
        for item in self {
            if !test(item) {
                return false
            }
        }

        return true
    }

    /**
    Checks if test returns true for any element of self.
    
    :param: test Function to call for each element
    :returns: true if test returns true for any element of self
    */
    func any(test: (Element) -> Bool) -> Bool {
        for item in self {
            if test(item) {
                return true
            }
        }

        return false
    }



    /* slice array
    :param: index slice index
    :param: isClose is close array
    :param: first First array
    :param: second Second array
    */
    //func slice(startIndex startIndex:Int, endIndex:Int) -> Slice<Element> {
    func slice(startIndex startIndex: Int, endIndex: Int) -> ArraySlice<Element> {


        return self[startIndex ... endIndex]

    }
    // func slice(index:Int,isClose:Bool = false) ->(first:Slice<Element> ,second:Slice<Element>){
    func slice(index: Int, isClose: Bool = false) -> (first:ArraySlice<Element>, second:ArraySlice<Element>) {
        var first = self[0 ... index]
        var second = self[index ..< count]

        if isClose {
            first = second + first
            second = []
        }

        return (first, second)

    }


}

 