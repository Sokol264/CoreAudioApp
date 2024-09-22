//
//  GraphDrawerView.swift
//  AudioCoreApp
//
//  Created by Данил Соколов on 18.09.2024.
//

import UIKit
import CoreGraphics

class GraphDrawerView: UIView {
    var dataPoints: [CGFloat] = [] {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .white
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Заливка фона
        context.setFillColor(UIColor.white.cgColor)
        context.fill(rect)
        
        // Определяем параметры осей графика
        let graphWidth = rect.width
        let graphHeight = rect.height
        let margin: CGFloat = 20.0
        
        let maxDataValue = dataPoints.max() ?? 0
        let minDataValue = dataPoints.min() ?? 0
        
        // Нарисуем оси
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2.0)
        
        // Горизонтальная ось
        context.move(to: CGPoint(x: margin, y: graphHeight - margin))
        context.addLine(to: CGPoint(x: graphWidth - margin, y: graphHeight - margin))
        context.strokePath()
        
        // Вертикальная ось
        context.move(to: CGPoint(x: margin, y: graphHeight - margin))
        context.addLine(to: CGPoint(x: margin, y: margin))
        context.strokePath()
        
        // Нарисуем график
        if dataPoints.count > 1 {
            let path = CGMutablePath()
            
            let xStep = (graphWidth - 2 * margin) / CGFloat(dataPoints.count - 1)
            let yRange = maxDataValue - minDataValue
            let scale = (graphHeight - 2 * margin) / (yRange != 0 ? yRange : 1)
            
            // Начальная точка
            let startPoint = CGPoint(
                x: margin,
                y: graphHeight - margin - (dataPoints[0] - minDataValue) * scale
            )
            path.move(to: startPoint)
            
            // Остальные точки
            for i in 1..<dataPoints.count {
                let nextPoint = CGPoint(
                    x: margin + CGFloat(i) * xStep,
                    y: graphHeight - margin - (dataPoints[i] - minDataValue) * scale
                )
                path.addLine(to: nextPoint)
            }
            
            context.addPath(path)
            context.setStrokeColor(UIColor.blue.cgColor)
            context.setLineWidth(2.0)
            context.strokePath()
        }
    }
}
