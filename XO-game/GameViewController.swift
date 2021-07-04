//
//  GameViewController.swift
//  XO-game
//
//  Created by Evgeny Kireev on 25/02/2019.
//  Copyright © 2019 plasmon. All rights reserved.
//

import UIKit
import GameplayKit

enum GameVariant {
    case withHuman, withComputer, fiveSteps
}

class GameViewController: UIViewController {

    @IBOutlet private var gameboardView: GameboardView!
    @IBOutlet private(set) var firstPlayerTurnLabel: UILabel!
    @IBOutlet private(set) var secondPlayerTurnLabel: UILabel!
    @IBOutlet private(set) var winnerLabel: UILabel!
    @IBOutlet private var restartButton: UIButton!
    
    private let gameboard = Gameboard()
    private lazy var referee = Referee(gameboard: self.gameboard)
    private var stateMachine: GKStateMachine!
    private var firstState: GKState.Type = FirstPlayerInputState.self
    
    var gameVariant: GameVariant = .withHuman
//    var currentState: GameState! {
//        didSet {
//            self.currentState.begin()
//        }
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var states: [GKState] = [GameEndedState(gameViewController: self)]
        
        switch gameVariant {
        case .withHuman:
            states.append(contentsOf: [
                FirstPlayerInputState(gameViewController: self, gameboard: self.gameboard, view: self.gameboardView, referee: self.referee),
                SecondPlayerInputState(gameViewController: self, gameboard: self.gameboard, view: self.gameboardView, referee: self.referee)
            ])
        case .withComputer:
            states.append(contentsOf: [
                FirstPlayerInputState(gameViewController: self, gameboard: self.gameboard, view: self.gameboardView, referee: self.referee),
                ComputerPlayerInputState(gameViewController: self, gameboard: self.gameboard, view: self.gameboardView, referee: self.referee)
            ])
        case .fiveSteps:
            firstState = FirstPlayerFiveStepsInputState.self
            states.append(contentsOf: [
                FirstPlayerFiveStepsInputState(gameViewController: self, gameboard: self.gameboard, view: self.gameboardView, referee: self.referee),
                SecondPlayerFiveStepsInputState(gameViewController: self, gameboard: self.gameboard, view: self.gameboardView, referee: self.referee),
                PlayersInputsExecutionState()
            ])
        }
        
        self.stateMachine = GKStateMachine(states: states)
        
        self.goToFirstState()
        
        gameboardView.onSelectPosition = { [weak self] position in
            guard let self = self else { return }
            
            (self.stateMachine.currentState as? PlayerInputState)?.addMark(at: position)
            
//            self.currentState.addMark(at: position)
//
//            if self.currentState.isCompleted {
//                self.gotoNextState()
//            }
        }
    }
    
//    func gotoFirstState() {
//        self.currentState = PlayerInputGameState(
//            player: .first,
//            gameboad: self.gameboard,
//            gameView: self.gameboardView,
//            gameViewController: self
//        )
//    }
//
//    func gotoNextState() {
//
//        if let player = self.referee.determineWinner() {
//            self.currentState = WinnerGameState(winner: player, gameViewController: self)
//            return
//        }
//
//        guard let playerInputState = self.currentState as? PlayerInputGameState else {
//            return
//        }
//
//        let player = playerInputState.player
//
//        self.currentState = PlayerInputGameState(
//            player: player.next,
//            gameboad: self.gameboard,
//            gameView: self.gameboardView,
//            gameViewController: self
//        )
//    }
    
    private func goToFirstState() {
        self.stateMachine.enter(firstState)
    }
    
    @IBAction func restartButtonTapped(_ sender: UIButton) {
        self.gameboard.clear()
        self.gameboardView.clear()
        self.goToFirstState()
    }
    
}
