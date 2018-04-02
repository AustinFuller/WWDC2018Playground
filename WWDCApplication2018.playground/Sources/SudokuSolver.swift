//
//  SudokuSolver.swift
//  WWDCTestEnvi
//
//  Created by AustinFuller on 3/14/18.
//  Copyright © 2018 Austin Fuller. All rights reserved.
//
//  Swift implementation of this algorithm:     http://norvig.com/sudoku.html
//  With some help from this git          :     https://github.com/pbing/Sudoku-Solver

/*
 Design Explanation:
     SudokuSolver {
        Initially fills in the units and peers global variables so that when
        the board is created that those values are accessible by the board model.
        Contains the solve function that solves and returns the solved string.
     }
     Board {
        Model that represents a whole board. In charge of parsing the input string.
        Into an array of ints that is then thrown into a square. Contains the assign
        and elimination functions that refine the board down until it has only one
        value per square. At that point, we say that it is solved. We assume that all
        boards given to the solver are solvable other the code will crash. Because
        we control the starting board, this is not an issue.
     }
     Square {
        Model representation of a single square. Can hold a value like "1489"
        which represents that 1, 4, 8, or 9 are possible values for a square.
        Once this value holds only one number, do we say that square is solved.
     }
 */


import Foundation

let rows = 9, columns = 9
var units = [[[Int]]]()
var peers = [[Int]]()

public class SudokuSolver {
    public init() {
        for square in 0..<(rows*columns) {
            units.append(getAdjacentValues(for: square))
            peers.append(getPeers(for: square))
        }
    }
    func solve(with input: String) -> String {
        return Board(input).description
    }
    public func getAdjacentValues(for index: Int) -> [[Int]] {
        var row = index / columns
        var rowValues = [Int](repeatElement(0, count: columns))
        var i = 0
        for column in 0..<columns {
            rowValues[i] = columns * row + column
            i += 1
        }
        var column = index % rows
        var columnValues = [Int](repeatElement(0, count: rows))
        i = 0
        for row in 0..<rows {
            columnValues[i] = columns * row + column
            i += 1
        }
        row = 3 * (index / (3 * columns))
        column = 3 * ((index % rows) / 3)
        var unitValues = [Int](repeatElement(0, count: 9))
        for unitRow in 0..<3 {
            for unitCol in 0..<3 {
                let unitIndex = unitRow * 3 + unitCol
                unitValues[unitIndex] = (row + unitRow) * columns + (column + unitCol)
            }
        }
        return [rowValues, columnValues, unitValues]
    }
    public func getPeers(for index: Int) -> [Int] {
        var peers = Set<Int>()
        var row = index / columns
        for column in 0..<columns {
            let i = row * columns + column
            if i != index { peers.insert(i) }
        }
        var column = index % rows
        for row in 0..<rows {
            let i = row * columns + column
            if i != index { peers.insert(i) }
        }
        row = 3 * (index / (3 * columns))
        column = 3 * ((index % rows) / 3)
        for unitRow in 0..<3 {
            for unitCol in 0..<3 {
                let i = (row + unitRow) * columns + (column + unitCol)
                if i != index { peers.insert(i) }
            }
        }
        return Array(peers)
    }
}
class Board: CustomStringConvertible {
    var squares = [Square](repeatElement(Square(511), count: 81))
    var description: String {
        var result = String()
        squares.forEach({ result += $0.description })
        return result
    }
    var solved: Bool {
        for square in squares where square.count != 1 {
            return false
        }
        return true
    }
    init(_ input: String) {
        let ints = parseToInts(input)
        for i in 0..<81 where ints[i] > 0 {
            if assign(i, digit: ints[i]) == nil {
                squares = []
            }
        }
    }
    func parseToInts(_ input: String) -> [Int] {
        var result = [Int]()
        input.forEach { (char) in
            if char == "0" || char == "." {
                result.append(0)
            } else { result.append(Int(String(char))!) }
        }
        return result
    }
    func assign(_ squareIndex: Int, digit: Int) -> [Square]? {
        var otherValues = squares[squareIndex]
        otherValues.removeDigit(digit)
        for d2 in otherValues.digits where eliminate(squareIndex, digit: d2) == nil { return nil }
        return squares
    }
    func eliminate(_ index: Int, digit: Int) -> [Square]? {
        if !squares[index].hasDigit(digit) { return squares }
        squares[index].removeDigit(digit)
        let count = squares[index].count
        if count == 0 {
            return nil
        } else if count == 1 {
            let thisValue = squares[index].digits[0]
            for peer in peers[index] {
                if eliminate(peer, digit: thisValue) == nil {
                    return nil
                }
            }
        } else {
            for unit in units[index] {
                var dPlaces = 0
                var dPlacesCount = 0
                for index in unit where squares[index].hasDigit(digit) {
                    dPlaces = index
                    dPlacesCount += 1
                }
                if dPlacesCount == 0 { return nil }
                else if dPlacesCount == 1 &&
                    assign(dPlaces, digit: digit) == nil {
                    return nil
                }
            }
        }
        return squares
    }
    func search() -> [Square]? {
        if solved { return squares }
        var minCount = Int.max
        var squareWithMin = 0
        for i in 0..<81 {
            let count = squares[i].count
            if count > 1 && count < minCount {
                minCount = count
                squareWithMin = i
            }
        }
        for digit in squares[squareWithMin].digits {
            let values = self.squares
            if assign(squareWithMin, digit: digit) != nil { _ = search() }
            if !solved { self.squares = values}
        }
        return nil
    }
}
struct Square: CustomStringConvertible {
    var value = UInt16(0)
    init(_ value: UInt16 = 511) {
        self.value = value
    }
    var description: String {
        if value == 0 {
            return "-"
        } else {
            var str = String()
            for i in 1...9 where (value & (toMask(i)) != 0) {
                str += String(i)
            }
            return str
        }
    }
    var count: Int {
        var val = value
        var count = 0
        while val != 0 {
            val &= val - 1
            count += 1
        }
        return count
    }
    var digits: [Int] {
        var total = [Int]()
        for i in 1...9 where hasDigit(i) {
            total.append(i)
        }
        return total
    }
    func toMask(_ digit: Int) -> UInt16 {
        return UInt16(1 << (digit - 1))
    }
    func hasDigit(_ digit: Int) -> Bool {
        return (value & toMask(digit)) != 0
    }
    mutating func addDigit(_ digit: Int) {
        value |= toMask(digit)
    }
    mutating func removeDigit(_ digit: Int) {
        value &= ~toMask(digit)
    }
}


