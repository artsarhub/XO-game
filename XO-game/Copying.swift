//
//  Copying.swift
//  XO-game
//
//  Created by v.prusakov on 6/22/21.
//  Copyright © 2021 plasmon. All rights reserved.
//

import Foundation

protocol Copying: AnyObject {
    func copy() -> Self
    
    init(prototype: Self)
}

extension Copying {
    func copy() -> Self {
        return type(of: self).init(prototype: self)
    }
}
