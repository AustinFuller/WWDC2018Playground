//
//  SudokuGame.swift
//
//  Created by AustinFuller on 3/14/18.
//  Copyright © 2018 Austin Fuller. All rights reserved.
//

/*
    Design Explanation:
        This is the model that handles recording and checking the game's input.
        Because the function of the class is straight forward, I'll break down
        the functions instead of explaining more about the class's purpose. 
 
    Fuction Explanations:
        * generateNewBoard()        creates and reset the board
        * checkCurrentBoard()       checks to see if it solved. If not, returns the incorrect squares.
        * generateSolution()        solves the board and stores that information into the solution variable.
        * recievedInput()           makes the needed changes to the mutatedBoard variable
        * shouldeBeAbleToRemove()   ensures that provided squares aren't removed
        * getRandomUnsolvedSquare() returns a square index that
        * getValue(at:)             returns the correct value for a given square
        * translation methods       change a square index into a xy location or back
 */

import Foundation

public class SudokuGame {
    // MARK: - Variables
    public var originalBoard: String!
    public var mutatedBoard: String!
    public var solution: String?
    public var selectedCellLocation: (x: Int, y: Int)?
    public var boardSolver = SudokuSolver()
    public init() {
        originalBoard = SudokuGenerator.generateBoard()
        mutatedBoard = originalBoard
    }
    public func generateNewBoard() {
        originalBoard = SudokuGenerator.generateBoard()
        mutatedBoard = originalBoard
        solution = nil
    }
    public func checkCurrentBoard() -> [Int]? {
        if solution == nil { self.generateSolution() }
        var differentIndexs = [Int]()
        if let solution = solution {
            for i in 0..<(rows*columns) {
                let boardChar = mutatedBoard[i]
                let solutionChar = solution[i]
                if boardChar == "0" || boardChar == "." {
                    continue
                } else if boardChar != solutionChar {
                    differentIndexs.append(i)
                }
            }
        }
        // Check to see if board is solved. nil represents solved.
        if !(mutatedBoard.contains("0") || mutatedBoard.contains(".")) {
            if differentIndexs.isEmpty {
                return nil
            } else {
        // -1 represents that errors exist in the mutatedBoard 
                return [-1] + differentIndexs
            }
        }
        return differentIndexs
    }
    public func generateSolution() {
        solution = boardSolver.solve(with: originalBoard).description
    }
    public func recievedInput(_ num: Int) {
        if let selectedCell = selectedCellLocation {
            let cellIndex = self.translate(loc: selectedCell)
            let index = mutatedBoard.index(mutatedBoard.startIndex, offsetBy: cellIndex)
            if num == -1 {
                mutatedBoard.replaceSubrange(index...index, with: "0")
            } else {
                mutatedBoard.replaceSubrange(index...index, with: num.description)
            }
        }
    }
    public func shouldBeAbleToRemove(_ location: (x: Int, y: Int)) -> Bool {
        let index = self.translate(loc: location)
        let boardChar = originalBoard[index]
        return boardChar == "0" || boardChar == "."
    }
    public func getRandomUnsolvedSquare() -> Int? {
        var choiceBank = [Int]()
        for i in 0..<(rows*columns) {
            let boardChar = mutatedBoard[i]
            if boardChar == "0" || boardChar == "." {
                choiceBank.append(i)
            }
        }
        let choice = arc4random_uniform(UInt32(choiceBank.count))
        if choiceBank.isEmpty { return nil }
        return choiceBank[Int(choice)]
    }
    public func getValue(at index: Int) -> Int {
        assert(index >= 0 && index < 81, "Index out of bound")
        if solution == nil { self.generateSolution() }
        return Int(solution![index])!
    }
    public func translate(index: Int) -> (x: Int, y: Int)? {
        let x = index % rows
        let y = index / columns
        return (x, y)
    }
    public func translate(loc: (x: Int, y: Int)) -> Int {
        return (loc.y * columns) + loc.x
    }
} 
