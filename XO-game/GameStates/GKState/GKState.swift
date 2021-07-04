//
//  GKState.swift
//  XO-game
//
//  Created by v.prusakov on 6/22/21.
//  Copyright © 2021 plasmon. All rights reserved.
//

import Foundation
import GameplayKit

class GameEndedState: GKState {

    var winner: Player?

    unowned let gameViewController: GameViewController

    init(gameViewController: GameViewController) {
        self.gameViewController = gameViewController
    }

    override func didEnter(from previousState: GKState?) {
        self.gameViewController.winnerLabel.isHidden = false

        if let playerInput = previousState as? PlayerInputState, playerInput.isWinner {
            recordEvent(.playerWin(playerInput.player))
            self.gameViewController.winnerLabel.text = self.winnerName(from: playerInput.player) + " win"
        } else if let executionState = previousState as? PlayersInputsExecutionState,
                  let winner = executionState.winner {
            recordEvent(.playerWin(winner))
            self.gameViewController.winnerLabel.text = self.winnerName(from: winner) + " win"
        } else {
            self.gameViewController.winnerLabel.text = "No winner"
        }
        self.gameViewController.firstPlayerTurnLabel.isHidden = true
        self.gameViewController.secondPlayerTurnLabel.isHidden = true
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == FirstPlayerInputState.self
            || stateClass == FirstPlayerFiveStepsInputState.self
    }

    private func winnerName(from winner: Player) -> String {
        switch winner {
        case .first: return "1st player"
        case .second: return "2nd player"
        }
    }
}

class PlayerInputState: GKState {
    let player: Player
    unowned let gameViewController: GameViewController
    unowned let gameboard: Gameboard
    unowned let view: GameboardView
    unowned let referee: Referee
    let markView: MarkView

    var isWinner: Bool = false

    init(player: Player, gameViewController: GameViewController, gameboard: Gameboard, view: GameboardView, referee: Referee) {
        self.player = player
        self.gameboard = gameboard
        self.view = view
        self.gameViewController = gameViewController
        self.referee = referee
        self.markView = player.markViewPrototype
    }

    // Begin
    override func didEnter(from previousState: GKState?) {
        switch self.player {
        case .first:
            self.gameViewController.firstPlayerTurnLabel.isHidden = false
            self.gameViewController.secondPlayerTurnLabel.isHidden = true
        case .second:
            self.gameViewController.firstPlayerTurnLabel.isHidden = true
            self.gameViewController.secondPlayerTurnLabel.isHidden = false
        }
        self.gameViewController.winnerLabel.isHidden = true
    }

    func addMark(at position: GameboardPosition) {
        guard self.view.canPlaceMarkView(at: position) else { return }

        self.gameboard.setPlayer(self.player, at: position)
        self.view.placeMarkView(self.markView.copy(), at: position)
        recordEvent(.playerAddMark(self.player, position))

        if let winner = self.referee.determineWinner() {
            self.isWinner = winner == self.player
            self.stateMachine?.enter(GameEndedState.self)
        } else {
            let stateClass = player.next == .first
                ? FirstPlayerInputState.self
                : (gameViewController.gameVariant == .withHuman ? SecondPlayerInputState.self : ComputerPlayerInputState.self)
            self.stateMachine?.enter(stateClass)
        }
    }
}

class SecondPlayerInputState: PlayerInputState {
    init(gameViewController: GameViewController, gameboard: Gameboard, view: GameboardView, referee: Referee) {
        super.init(player: .second, gameViewController: gameViewController, gameboard: gameboard, view: view, referee: referee)
    }
}

class FirstPlayerInputState: PlayerInputState {
    init(gameViewController: GameViewController, gameboard: Gameboard, view: GameboardView, referee: Referee) {
        super.init(player: .first, gameViewController: gameViewController, gameboard: gameboard, view: view, referee: referee)
    }
}

// MARK: - With computer

class ComputerPlayerInputState: SecondPlayerInputState {
    override init(gameViewController: GameViewController, gameboard: Gameboard, view: GameboardView, referee: Referee) {
        super.init(gameViewController: gameViewController, gameboard: gameboard, view: view, referee: referee)
    }
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        let emptyPositions = getEmptyPositions(view: view)
        guard emptyPositions.count != 0 else { return }
        let randomPositionIdx = Int.random(in: 0..<emptyPositions.count)
        let randomPosition = emptyPositions[randomPositionIdx]
        
        view.onSelectPosition?(randomPosition)
    }
    
    private func getEmptyPositions(view: GameboardView) -> [GameboardPosition] {
        var positions: [GameboardPosition] = []
        for i in 0..<3 {
            for j in 0..<3 {
                let position = GameboardPosition(column: i, row: j)
                if view.canPlaceMarkView(at: position) {
                    positions.append(position)
                }
            }
        }
        return positions
    }
}

// MARK: - FiveSteps

class FiveStepsPlayerInputState: PlayerInputState {
    private var commandsCount = 0
    private let maxCommandsCount = 5
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        if FiveStepsGameInvoker.shared.firstPlayerCommands.count == maxCommandsCount,
           FiveStepsGameInvoker.shared.secondPlayerCommands.count == maxCommandsCount {
            self.stateMachine?.enter(PlayersInputsExecutionState.self)
        }
        commandsCount = 0
    }
    
    override func addMark(at position: GameboardPosition) {
        let command = PlayerStepCommand(player: player, position: position, gameboard: gameboard, view: view, referee: referee, stateMachine: self.stateMachine)
        FiveStepsGameInvoker.shared.addCommand(command)
        commandsCount += 1
        
        if commandsCount == maxCommandsCount {
            let stateClass = player.next == .first
                ? FirstPlayerFiveStepsInputState.self
                : SecondPlayerFiveStepsInputState.self
            self.stateMachine?.enter(stateClass)
        }
    }
}

class FirstPlayerFiveStepsInputState: FiveStepsPlayerInputState {
    init(gameViewController: GameViewController, gameboard: Gameboard, view: GameboardView, referee: Referee) {
        super.init(player: .first, gameViewController: gameViewController, gameboard: gameboard, view: view, referee: referee)
    }
}

class SecondPlayerFiveStepsInputState: FiveStepsPlayerInputState {
    init(gameViewController: GameViewController, gameboard: Gameboard, view: GameboardView, referee: Referee) {
        super.init(player: .second, gameViewController: gameViewController, gameboard: gameboard, view: view, referee: referee)
    }
}

class PlayersInputsExecutionState: GKState {
    var winner: Player?
    
    override func didEnter(from previousState: GKState?) {
        FiveStepsGameInvoker.shared.executeCommands()
    }
}
