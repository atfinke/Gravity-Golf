//
//  CGExtensions.swift
//  Untitled Space Game
//
//  Created by Andrew Finke on 3/16/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import CoreGraphics

extension CGRect {
    func innerCircleIntersects(circleRect rect: CGRect) -> Bool {
        let radius = width / 2

        let otherRadius = rect.width / 2
        let otherCenter = rect.center

        let distance = center.distance(to: otherCenter)
        return distance <= (radius + otherRadius)
    }

    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

extension CGSize {

    func scaleComponents(by factor: CGFloat) -> CGSize {
        return CGSize(width: width * factor, height: height * factor)
    }

    static func *(lhs: CGSize, factor: Int) -> CGSize {
        return CGSize(width: lhs.width * CGFloat(factor), height: lhs.height * CGFloat(factor))
    }

    static func /(lhs: CGSize, factor: CGFloat) -> CGSize {
        return CGSize(width: lhs.width / CGFloat(factor), height: lhs.height / CGFloat(factor))
    }

}
extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }

    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    func scaleComponents(by factor: CGFloat) -> CGPoint {
        return CGPoint(x: x * factor, y: y * factor)
    }

    func vectorized() -> CGVector {
        return CGVector(dx: x, dy: y)
    }

    static func *(lhs: CGPoint, factor: Int) -> CGPoint {
        return CGPoint(x: lhs.x * CGFloat(factor), y: lhs.y * CGFloat(factor))
    }

    static func +(lhs: CGPoint, rhs: CGSize) -> CGPoint {
        return CGPoint(x: lhs.x * rhs.width, y: lhs.y * rhs.height)
    }
}

extension CGVector {
    func magnitude() -> CGFloat {
        return sqrt(pow(dx, 2) + pow(dy, 2))
    }
}
