//  Created by AustinFuller on 3/14/18.
//  Copyright © 2018 Austin Fuller. All rights reserved.
//  Created for WWDC Scholarship 2018

//  NOTE: Please ensure to run in Xcode. iPad Playground has view limitations that this
//        Playground violates. Designed and implemented in Xcode. 

/*
    Included Class in this file:
        * BoardViewController
        * SudokuBoard
        * NotificationBar
        * GridLines
    Design Explanation:
        BoardViewController {
            Main view for Playground. Originally created as a view controller, but
            converted to just a UIView that has the ability to handle user input.
            When created, it creates the top and bottom bars and adds the appropriate
            actions for each button. Also acts and the manager for the SudokuGame and
            SudokuBoard so that the model and display are always in sync.
        }
        SudokuBoard {
            Manages all subviews within the Sudoku Board. Receives  numerical inputs
            from BoardViewConroller to insert them into the appropriate cells.
            Also handles showing incorrect user input and handling user input
            within the bounds of the board.
        }
        NotificationBar {
            Handles the view that displays information to the user. Displays complete
            message, music selection, and when there are errors after completing the
            puzzle. Set up so that input is added through addMessage(str:) method and
            displays that information in order until messageQueue is empty then hides
            the bar. Main usage is explaining the controls to help with discoverability.
        }
        GridLines {
            Special view for the board. Shows example of using UIGraphicContext.
            No interaction is used with this view.
        }
        Note: this Playground is heavily UIKit depended so the included classes couldn't
            be abstracted  out to the Source folder (my understanding is that the UIKit
            module isn't accessible anywhere but in this main Playground file).
 */


import Foundation
import UIKit
import PlaygroundSupport
import AVFoundation

var globalBoardManager = SudokuGame()
let colorLiterals = [#colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1), #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1), #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1), #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), #colorLiteral(red: 0.6741188169, green: 0.5459612608, blue: 0.75508672, alpha: 1), #colorLiteral(red: 0.8755858541, green: 0.5732600093, blue: 0.7454114556, alpha: 1), #colorLiteral(red: 0.953907907, green: 0.5350736976, blue: 0.6515971422, alpha: 1), #colorLiteral(red: 0.9638058543, green: 0.5192728639, blue: 0.4036269188, alpha: 1), #colorLiteral(red: 0.9957414269, green: 0.777808547, blue: 0.4629557133, alpha: 1), #colorLiteral(red: 0.9768560529, green: 0.9465773702, blue: 0.5484383106, alpha: 1), #colorLiteral(red: 0.7569081187, green: 0.8642141819, blue: 0.5401860476, alpha: 1), #colorLiteral(red: 0.670507133, green: 0.8569833636, blue: 0.7756617069, alpha: 1), #colorLiteral(red: 0.5860881209, green: 0.8168383241, blue: 0.9508643746, alpha: 1), #colorLiteral(red: 0.5321525931, green: 0.6081470251, blue: 0.8082398772, alpha: 1)]

class BoardViewController: UIView {
    var boardDisplay: SudokuBoard!
    var player: AVAudioPlayer?
    var applausePlayer: AVAudioPlayer?
    private var notificationBar: NotificationBar!
    // MARK: - View Functions
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.addNotificationBar()
        self.addResetHintCheckButtons()
        self.addBottomButtonSelection()
        self.generateBoardView()
        self.showStartingNotifications()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func addNotificationBar() {
        let noteBarSize = CGRect(x: 0, y: 40, width: self.frame.width, height: 40)
        notificationBar = NotificationBar(frame: noteBarSize)
        notificationBar.alpha = 0.0
        self.addSubview(notificationBar)
    }
    private func addResetHintCheckButtons() {
        //TOP BAR
        // Reset Button
        let width = self.frame.width / 3, height: CGFloat = 40.0
        let distanceFromTop: CGFloat = 0
        let resetButtonSize = CGRect(x: 0, y: distanceFromTop, width: width, height: height)
        _ = buttonGenerator(title: "Reset", frame: resetButtonSize, view: self, action: #selector(BoardViewController.resetBoard), backgroundColor: colorLiterals[0])
        // MUSIC RELATED BUTTONS
        // next play button
        let playButtonSize = CGRect(x: resetButtonSize.maxX, y: distanceFromTop, width: width, height: height)
        _ = buttonGenerator(title: "Play", frame: playButtonSize, view: self, action: #selector(BoardViewController.playSong(_:)), backgroundColor: colorLiterals[1])
        // Stop Button
        let pauseButtonSize = CGRect(x: playButtonSize.maxX, y: distanceFromTop, width: width, height: height)
        _ = buttonGenerator(title: "Pause", frame: pauseButtonSize, view: self, action: #selector(BoardViewController.pauseOrResumeSong(_:)), backgroundColor: colorLiterals[2])
        // BOTTOM BAR
        // Hint Button
        let bottomInsertY = self.frame.maxY - 40
        let hintButtonSize = CGRect(x: 0, y: bottomInsertY, width: self.frame.width/2, height: height)
        _ = buttonGenerator(title: "Hint", frame: hintButtonSize, view: self, action: #selector(BoardViewController.showHint), backgroundColor: colorLiterals[3])
        // Check Button
        let checkButtonSize = CGRect(x: self.frame.width/2, y: bottomInsertY, width: self.frame.width/2, height: height)
        _ = buttonGenerator(title: "Check", frame: checkButtonSize, view: self, action: #selector(BoardViewController.checkBoard), backgroundColor: colorLiterals[4])
    }
    private func addBottomButtonSelection() {
        // MARK: Adjust Size
        let bottomInsertY = self.frame.maxY - 80
        let horStackSize = CGRect(x: 0, y: bottomInsertY, width: self.frame.width, height: 40)
        let HorizontalStack = UIStackView(frame: horStackSize)
        let width = horStackSize.width / 10
        let buttonSize = CGRect(x: 0, y: 0, width: width, height: horStackSize.height)
        for i in 1...9 {
            let button = buttonGenerator(title: i.description, frame: buttonSize, view: nil, action: #selector(BoardViewController.bottomButtonNumberPressed(_:)), backgroundColor: colorLiterals[i + 4])
            button.tag = i
            HorizontalStack.addArrangedSubview(button)
        }
        //remove button
        let removeButton = buttonGenerator(title: "X", frame: buttonSize, view: nil, action: #selector(BoardViewController.bottomButtonNumberPressed(_:)), backgroundColor: colorLiterals[14])
        removeButton.tag = -1
        HorizontalStack.addArrangedSubview(removeButton)
        //final horizontal stack settings
        HorizontalStack.distribution = .fillEqually
        self.addSubview(HorizontalStack)
    }
    private func generateBoardView() {
        let sideLength = self.frame.width - 20
        // Center calculation = total + top bar - two bottom bars
        let boardTop: CGFloat = frame.midY - (sideLength / 2) + (40 - 80) / 2
        let boardSize = CGRect(x: 10, y: boardTop,
                               width: sideLength, height: sideLength)
        boardDisplay = SudokuBoard(frame: boardSize)
        boardDisplay.setBoardManager(globalBoardManager)
        boardDisplay.setUpSubviews(with: globalBoardManager.originalBoard)
        self.addSubview(boardDisplay)
    }
    private func showStartingNotifications() {
        notificationBar.addMessage("")
        notificationBar.addMessage("Welcome to Tex's Sudoku!")
        notificationBar.addMessage("The \"Reset\" button shows a new board.")
        notificationBar.addMessage("Music controls are above.")
        notificationBar.addMessage("The \"Hint\' button reveals a square.")
        notificationBar.addMessage("The \"Check\" button shows current errors")
        notificationBar.addMessage("Have fun!")
    }
    // MARK: - Button Action Functions
    var currentSongSelection = 0
    @objc private func playSong(_ sender: UIButton) {
        if let player = player {
            if let url = player.url {
                let currentSongIndex = url.lastPathComponent.first!
                var nextSongIndex = Int(currentSongIndex.description)! + 1
                if nextSongIndex == 4 { nextSongIndex = 1 }
                var songMessage = "Playing "
                switch nextSongIndex {
                case 1:
                    songMessage += "Springish by Gillicuddy"
                    break
                case 2:
                    songMessage += "Night Owl by Directionless"
                    break
                case 3:
                    songMessage += "Veloma by Fabrizio Paterlini"
                    break
                default:
                    break
                }
                notificationBar.addMessage(songMessage)
                let url = Bundle.main.url(forResource: String(nextSongIndex), withExtension: ".m4a")
                self.playSongWith(url)
            }
        } else {
            notificationBar.addMessage("Playing Springish by Gillicuddy")
            let url = Bundle.main.url(forResource: "1", withExtension: "m4a")
            self.playSongWith(url)
            sender.setTitle("Next", for: .normal)
        }
    }
    @objc private func pauseOrResumeSong(_ sender: UIButton) {
        if let player = player {
            if player.isPlaying {
                sender.setTitle("Resume", for: .normal)
                player.pause()
            } else {
                sender.setTitle("Pause", for: .normal)
                player.play()
            }
        }
    }
    @objc private func resetBoard() {
        globalBoardManager.generateNewBoard()
        notificationBar.messageQueue.removeAll()
        boardDisplay.setUpSubviews(with: globalBoardManager.originalBoard)
        applausePlayer?.stop()
    }
    @objc private func checkBoard() {
        let differentIndex = globalBoardManager.checkCurrentBoard()
        if let differentIndex = differentIndex {
            boardDisplay.showDifference(for: differentIndex)
        } else {
            self.checkForCompleteSolution()
        }
    }
    @objc private func bottomButtonNumberPressed(_ sender: UIButton) {
        globalBoardManager.recievedInput(sender.tag)
        if let selectedCell = globalBoardManager.selectedCellLocation {
            boardDisplay.updateBoard(with: sender.tag, for: selectedCell)
            globalBoardManager.selectedCellLocation = nil
            self.checkForCompleteSolution()
        }
    }
    @objc private func showHint() {
        let squareToReveal = globalBoardManager.getRandomUnsolvedSquare()
        if let square = squareToReveal {
            let number = globalBoardManager.getValue(at: square)
            let location = globalBoardManager.translate(index: square)
            if let location = location {
                globalBoardManager.selectedCellLocation = location
                globalBoardManager.recievedInput(number)
                boardDisplay.updateBoard(with: number, for: location)
                boardDisplay.flashSquare(at: location, color: UIColor.yellow)
                self.checkForCompleteSolution()
            }
        }
    }
    //MARK: - Support Functions
    private func buttonGenerator(title: String, frame: CGRect, view: UIView?, action: Selector,
                                 weight: UIFont.Weight = .light, titleColor: UIColor = .white, backgroundColor: UIColor = .white) -> UIButton {
        let generatedButton = UIButton(type: .system)
        generatedButton.frame = frame
        generatedButton.setTitle(title, for: .normal)
        generatedButton.titleLabel?.font = UIFont.systemFont(ofSize:
            generatedButton.frame.height - 15, weight: weight)
        generatedButton.setTitleColor(titleColor, for: .normal)
        generatedButton.backgroundColor = backgroundColor
        generatedButton.addTarget(self, action: action, for: .touchUpInside)
        if let view = view {
            view.addSubview(generatedButton)
        }
        return generatedButton
    }
    private func playSongWith(_ url: URL?) {
        if let url = url {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                guard let player = player else { return }
                player.prepareToPlay()
                player.play()
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    private func checkForCompleteSolution() {
        let currentSolveState = globalBoardManager.checkCurrentBoard()
        if currentSolveState == nil {
            // MARK: Show Solved
            notificationBar.addFirstMessage("Board Solved!")
            self.playApplause()
        } else if currentSolveState?.first == -1 {
            notificationBar.addMessage("Still a few errors!")
            currentSolveState?.dropFirst()
            boardDisplay.showDifference(for: currentSolveState!)
        }
    }
    private func playApplause() {
        let applauseURL = Bundle.main.url(forResource: "applause", withExtension: "mp3")
        if let applauseURL = applauseURL {
            do {
                applausePlayer = try AVAudioPlayer(contentsOf: applauseURL)
                guard let player = applausePlayer else { return }
                player.prepareToPlay()
                player.play()
            } catch let error {
                print(error.localizedDescription)
            }
            
        }
    }
}

class SudokuBoard: UIView {
    var manager: SudokuGame!
    public func setBoardManager(_ manager: SudokuGame) {
        self.manager = manager
    }
    public func setUpSubviews(with input: String) {
        self.subviews.forEach({ $0.removeFromSuperview() })
        var mutableInput = input
        let GridViewSideLength = self.frame.width / 9
        for i in 0..<9 {
            for j in 0..<9 {
                let xPoint = CGFloat(j) * GridViewSideLength
                let yPoint = CGFloat(i) * GridViewSideLength
                let subviewSize = CGRect(x: xPoint, y: yPoint, width: GridViewSideLength, height: GridViewSideLength)
                let subview = UIView(frame: subviewSize)
                subview.backgroundColor = UIColor.white
                let char = mutableInput.removeFirst()
                if !(char == "." || char == "0") {
                    let label = UILabel(frame: CGRect(x: 0, y: 0, width: GridViewSideLength,
                                                      height: GridViewSideLength))
                    label.text = String(describing: char)
                    label.textAlignment = .center
                    label.font = UIFont.systemFont(ofSize: label.frame.width - 7, weight: .light)
                    subview.addSubview(label)
                }
                self.addSubview(subview)
            }
        }
        let gridLines = GridLines(frame: self.bounds)
        gridLines.backgroundColor = UIColor.clear
        gridLines.tag = -1
        self.addSubview(gridLines)
    }
    public func flashSquare(at loc: (x: Int, y: Int), color: UIColor) {
        let view = getSubview(at: loc)
        if let view = view {
            let initialColor = view.backgroundColor
            UIView.animate(withDuration: 0.5, animations: {
                view.backgroundColor = color
            }, completion: { (_) in
                UIView.animate(withDuration: 0.5, animations: {
                    view.backgroundColor = initialColor
                })
            })
        }
    }
    public func showDifference(for diff: [Int]) {
        for squareIndex in diff {
            let location = globalBoardManager.translate(index: squareIndex)
            if let location = location {
                flashSquare(at: location, color: UIColor.red)
            }
        }
    }
    public func getSubview(at loc: (x: Int, y: Int)) -> UIView? {
        let xComp = ((self.frame.width / 9) * CGFloat(loc.x) + CGFloat(10))
        let yComp = ((self.frame.height / 9) * CGFloat(loc.y) + CGFloat(10))
        let point = CGPoint(x: xComp, y: yComp)
        let view = subviews.filter({$0.frame.contains(point)})
        //Note: the Gridline subview is also included in this array
        //but is always included last.
        return view.first
    }
    public func updateBoard(with num: Int, for location: (x: Int, y: Int)) {
        if let view = getSubview(at: location) {
            if globalBoardManager.shouldBeAbleToRemove(location) {
                view.subviews.forEach { $0.removeFromSuperview() }
                view.backgroundColor = UIColor.white
                let label = UILabel(frame: view.bounds)
                label.textAlignment = .center
                if num == -1 {
                    label.text = " "
                } else {
                    label.text = String(num)
                }
                label.font = UIFont.systemFont(ofSize: label.frame.width - 7, weight: .light)
                view.addSubview(label)
            }
        }
    }
    private func adjustHighlightedCell(at point: CGPoint) {
        for view in subviews {
            if view.tag == -1 {
                continue
            } else if view.frame.contains(point) {
                view.backgroundColor = UIColor.yellow
            } else {
                view.backgroundColor = UIColor.clear
            }
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touchPoint = touches.first?.preciseLocation(in: self) {
            self.adjustHighlightedCell(at: touchPoint)
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touchPoint = touches.first?.preciseLocation(in: self) {
            self.adjustHighlightedCell(at: touchPoint)
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touchPoint = touches.first?.preciseLocation(in: self) {
            if !self.bounds.contains(touchPoint) { return }
            self.adjustHighlightedCell(at: touchPoint)
            let touchedRow = Int(9 * touchPoint.x / self.bounds.width)
            let touchedCol = Int(9 * touchPoint.y / self.bounds.width)
            manager?.selectedCellLocation = (touchedRow, touchedCol)
        }
    }
}

class NotificationBar: UIView {
    public var messageQueue = [String]()
    private var label: UILabel!
    private var displayTimer: Timer!
    private var messageTimer: Timer!
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = colorLiterals[5]
        self.configureLabel()
        self.addTimers()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func addTimers() {
        //Display Timer
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true, block: { (timer) in
            if !self.messageQueue.isEmpty {
                self.displayNextMessage()
            }
        })
        //Message Update Timer
        messageTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { (timer) in
            if self.messageQueue.first == "Board Solved!" { return }
            if !self.messageQueue.isEmpty {
                _ = self.messageQueue.removeFirst()
            } else {
                self.hideBar()
            }
        })
    }
    public func addFirstMessage(_ str: String) {
        messageQueue.insert(str, at: 0)
        self.displayNextMessage()
    }
    public func addMessage(_ str: String) {
        messageQueue.append(str)
    }
    private func configureLabel() {
        label = UILabel(frame: self.bounds)
        self.label.font = UIFont.systemFont(ofSize: self.frame.height - 15, weight: .light)
        label.textAlignment = .center
        label.textColor = UIColor.white
        self.addSubview(label)
        self.bringSubview(toFront: label)
    }
    @objc private func displayNextMessage() {
        if !messageQueue.isEmpty {
            self.showBar()
            self.label.text = self.messageQueue.first
        }
    }
    private func showBar() {
        UIView.animate(withDuration: 0.5) {
            self.alpha = 1.0
        }
    }
    private func hideBar() {
        if messageQueue.first == "Board Solved!" { return }
        UIView.animate(withDuration: 0.5) {
            self.alpha = 0.0
        }
    }
}

class GridLines: UIView {
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        context.setLineWidth(5)
        context.stroke(rect)
        context.setLineWidth(1)
        for i in 1..<9 {
            let i = CGFloat(i)
            context.move(to: CGPoint(x: rect.origin.x, y: i * rect.size.height/9))
            context.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: i * rect.size.height/9))
            context.move(to: CGPoint(x: i * rect.size.width/9, y: rect.origin.y))
            context.addLine(to: CGPoint(x: i * rect.size.width/9, y: rect.origin.y + rect.size.height))
        }
        context.strokePath()
        context.setLineWidth(2)
        for i in 0...2 {
            let i = CGFloat(i)
            context.move(to: CGPoint(x: rect.origin.x, y: i * rect.size.height/3))
            context.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: i * rect.size.height/3))
            context.move(to: CGPoint(x: i * rect.size.width/3, y: rect.origin.y))
            context.addLine(to: CGPoint(x: i * rect.size.width/3, y: rect.origin.y + rect.size.height))
        }
        context.strokePath()
    }
}

let boardView = BoardViewController(frame: CGRect(x: 0, y: 0, width: 500, height: 700))
PlaygroundPage.current.liveView = boardView
