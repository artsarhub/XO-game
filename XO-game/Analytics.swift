//
//  Analytics.swift
//  XO-game
//
//  Created by v.prusakov on 6/22/21.
//  Copyright © 2021 plasmon. All rights reserved.
//

import Foundation

enum Event {
    case playerWin(Player)
    case playerAddMark(Player, GameboardPosition)
}

protocol EventCommand {
    var logMessage: String { get }
}

class Analytics {
    
    static let shared = Analytics()
    
    private var events: [EventCommand] = []
    
    private var maxEventsCount = 5
    
    func recordEvent(_ event: EventCommand) {
        self.events.append(event)
        self.sendEventsIfNeeded()
    }
    
    private func sendEventsIfNeeded() {
        guard self.events.count >= self.maxEventsCount else { return }
        
        self.events.forEach {
            print($0.logMessage)
        }
        
        self.events.removeAll()
    }
}

struct LogEvent: EventCommand {
    let action: Event
    
    var logMessage: String {
        switch action {
        case let .playerAddMark(player, position):
            return "\(player) set mark at position \(position)"
        case .playerWin(let player):
            return "\(player) win"
        }
    }
}

func recordEvent(_ eventAction: Event) {
    let command = LogEvent(action: eventAction)
    Analytics.shared.recordEvent(command)
}
