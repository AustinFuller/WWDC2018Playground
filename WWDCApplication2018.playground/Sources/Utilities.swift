//
//  Utilities.swift
//  WWDCTestEnvi
//
//  Created by AustinFuller on 3/19/18.
//  Copyright © 2018 Austin Fuller. All rights reserved.
//

/*
    Design Explanation:
        Included extension Necessary to access the n-th element for the SudokuSolver’s design.
        Code taken from StackOverflow where any uploaded code is open source.
        Code snippet from:
            https://stackoverflow.com/questions/24092884/get-nth-character-of-a-string-in-swift-programming-language
        Open source statement:
            https://meta.stackexchange.com/questions/271080/the-mit-license-clarity-on-using-code-on-stack-overflow-and-stack-exchange
 */

import Foundation

extension String {
    var length: Int {
        return self.count
    }
    subscript (index: Int) -> String {
        return self[index ..< index + 1]
    }
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
    subscript (inputRange: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, inputRange.lowerBound)),
                                            upper: min(length, max(0, inputRange.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}
