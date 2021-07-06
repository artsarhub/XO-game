//
//  StartScreenViewController.swift
//  XO-game
//
//  Created by Артём on 03.07.2021.
//  Copyright © 2021 plasmon. All rights reserved.
//

import UIKit

class StartScreenViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let controller = segue.destination as? GameViewController else { return }
        switch segue.identifier {
        case "AIGameSegue":
            controller.gameVariant = .withComputer
        case "TwoPlayersGameSegue":
            controller.gameVariant = .withHuman
        case "FiveStepsGameSegue":
            controller.gameVariant = .fiveSteps
        default:
            break
        }
    }

}
