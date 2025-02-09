//
//  StarTextureCreator.swift
//  Gravity Putt
//
//  Created by Andrew Finke on 3/21/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SpriteKit

#if os(macOS)
typealias ContextRenderer = AppKitContextRenderer
#else
typealias ContextRenderer = UIGraphicsImageRenderer
#endif

struct StarTextureCreator {

    func create(size: CGSize, countRange: Range<Int>, radiusRange: Range<CGFloat>) -> SKTexture {

        #if os(macOS)
        guard let scale = NSScreen.main?.backingScaleFactor else { fatalError() }
        #else
        let scale = UIScreen.main.scale
        #endif

        let scaledSize = size / scale

        let renderer = ContextRenderer(size: scaledSize)
        let image = renderer.image { ctx in
            let context = ctx.cgContext
            for _ in countRange {
                let position = CGPoint(x: CGFloat.random(in: 0...size.width),
                                        y: CGFloat.random(in: 0...size.height))
                context.move(to: position)
                context.addArc(center: position,
                           radius: CGFloat.random(in: radiusRange),
                           startAngle: 0,
                           endAngle: CGFloat.pi * 2,
                           clockwise: false)
            }

            SKColor.white.setFill()
            context.fillPath()
        }
        #if os(macOS)
        guard let cgImage = image.cgImage(forProposedRect: nil,
                                          context: nil,
                                          hints: nil) else {
                                            fatalError()
        }
        #else
        guard let cgImage = image.cgImage else {
            fatalError()
        }
        #endif

        return SKTexture(cgImage: cgImage)
    }
}
