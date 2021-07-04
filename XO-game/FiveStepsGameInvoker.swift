//
//  FiveStepsGameInvoker.swift
//  XO-game
//
//  Created by Артём on 03.07.2021.
//  Copyright © 2021 plasmon. All rights reserved.
//

import Foundation
import GameKit

protocol Command {
    func execute()
}

struct PlayerStepCommand: Command {
    let player: Player
    let position: GameboardPosition
    unowned let gameboard: Gameboard
    unowned let view: GameboardView
    unowned let referee: Referee
    let stateMachine: GKStateMachine?
    
    func execute() {
        guard let executionState = stateMachine?.currentState as? PlayersInputsExecutionState else { return }
        
        self.view.removeMarkView(at: position)
        self.gameboard.setPlayer(player, at: position)
        self.view.placeMarkView(player.markViewPrototype.copy(), at: position)
        recordEvent(.playerAddMark(player, position))
        
        if FiveStepsGameInvoker.shared.executedCommandsCount == FiveStepsGameInvoker.shared.firstPlayerCommands.count + FiveStepsGameInvoker.shared.secondPlayerCommands.count {
            executionState.winner = self.referee.determineWinner()
            self.stateMachine?.enter(GameEndedState.self)
        }
    }
}

class FiveStepsGameInvoker {
    // MARK: - Instance
    
    static let shared = FiveStepsGameInvoker()
    
    // MARK: - Private
    
    private(set) var firstPlayerCommands: [PlayerStepCommand] = []
    private(set) var secondPlayerCommands: [PlayerStepCommand] = []
    private(set) var executedCommandsCount = 0
    
    private init() {}
    
    // MARK: - Public
    
    public func addCommand(_ command: PlayerStepCommand) {
        switch command.player {
        case .first:
            firstPlayerCommands.append(command)
        case .second:
            secondPlayerCommands.append(command)
        }
    }
    
    public func executeCommands() {
        executedCommandsCount = 0
        guard firstPlayerCommands.count == secondPlayerCommands.count else { return }
        for i in 0..<firstPlayerCommands.count {
            firstPlayerCommands[i].execute()
            executedCommandsCount += 2
            secondPlayerCommands[i].execute()
        }
        firstPlayerCommands.removeAll()
        secondPlayerCommands.removeAll()
    }
}
