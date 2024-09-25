//
//  GraphDrawer.swift
//  AudioCoreApp
//
//  Created by Danil Sokolov on 25.09.2024.
//

import QuartzCore
import CoreGraphics
import UIKit

final class GraphDrawer {
    func drawGraph(with points: [CGFloat], in context: CGContext, rect: CGRect, graphOffsetY: CGFloat) {
        let graphWidth = rect.width
        let graphHeight = rect.height
        let margin: CGFloat = 20.0

        let maxDataValue = points.max() ?? 0
        let minDataValue = points.min() ?? 0

        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2.0)

        context.move(to: CGPoint(x: margin, y: graphHeight + graphOffsetY))
        context.addLine(to: CGPoint(x: graphWidth - margin, y: graphHeight + graphOffsetY))
        context.strokePath()

        context.move(to: CGPoint(x: margin, y: graphHeight + graphOffsetY))
        context.addLine(to: CGPoint(x: margin, y: graphOffsetY))
        context.strokePath()

        guard points.count > 1 else {
            return
        }

        let path = CGMutablePath()

        let xStep = (graphWidth - 2 * margin) / CGFloat(points.count - 1)
        let yRange = maxDataValue - minDataValue
        let scale = (graphHeight - 2 * margin) / (yRange != 0 ? yRange : 1)

        let startPoint = CGPoint(
            x: margin,
            y: graphHeight + graphOffsetY - (points[0] - minDataValue) * scale
        )
        path.move(to: startPoint)

        for i in 1..<points.count {
            let nextPoint = CGPoint(
                x: margin + CGFloat(i) * xStep,
                y: graphHeight + graphOffsetY - (points[i] - minDataValue) * scale
            )
            path.addLine(to: nextPoint)
        }

        context.addPath(path)
        context.setStrokeColor(UIColor.blue.cgColor)
        context.setLineWidth(2.0)
        context.strokePath()
    }
}
