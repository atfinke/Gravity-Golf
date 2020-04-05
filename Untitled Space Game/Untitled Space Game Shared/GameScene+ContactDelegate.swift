//
//  GameScene+ContactDelegate.swift
//  Untitled Space Game
//
//  Created by Andrew Finke on 4/4/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SpriteKit

extension GameScene: SKPhysicsContactDelegate {

    // MARK: - SKPhysicsContactDelegate -

    private func type<T: Any>(type: T.Type, in contact: SKPhysicsContact) -> T? {
        if let a = contact.bodyA.node as? T {
            return a
        } else if let b = contact.bodyB.node as? T {
            return b
        } else {
            return nil
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        if let goal = type(type: Goal.self, in: contact) {
            contactGoal = goal
        } else if let planet = type(type: Planet.self, in: contact) {
            contactPlanet = planet
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        if let _ = type(type: Goal.self, in: contact) {
            contactGoal = nil
        } else if let _ = type(type: Planet.self, in: contact) {
            contactPlanet = nil
        }
    }

}
