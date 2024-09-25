//
//  PDFManager.swift
//  AudioCoreApp
//
//  Created by Данил Соколов on 15.09.2024.
//

import PDFKit

final class PDFManager {
    private enum Constants {
        static let pageWidth: CGFloat = 595.0
        static let pageHeight: CGFloat = 842.0

        static let titleHeight: CGFloat = 35.0
        static let spacing: CGFloat = 10.0

        static let maxGraphCountOnPage: Int = 4

        static let graphHeight: CGFloat = (pageHeight - titleHeight - spacing * CGFloat(maxGraphCountOnPage + 1)) / CGFloat(maxGraphCountOnPage)
        static let pageRect = CGRect(x: 0.0, y: 0.0, width: pageWidth, height: pageHeight)
        static let graphRect = CGRect(x: 0.0, y: 0.0, width: pageWidth, height: graphHeight)
    }

    private let graphDrawer = GraphDrawer()

    func createGraphDocumentData(with points: [[Float]]) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Audio Recorder / Player",
            kCGPDFContextAuthor: "sokol264.com"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let graphOffset = Constants.titleHeight + Constants.spacing

        let renderer = UIGraphicsPDFRenderer(bounds: Constants.pageRect, format: format)

        let data = renderer.pdfData { (context) in
            context.beginPage()

            let attributes = getTitleAttribute()

            let text = "Модальная амплитуда аудио:"
            let textRect = CGRect(
                x: 0.0,
                y: Constants.spacing,
                width: Constants.pageWidth,
                height: Constants.titleHeight
            )

            text.draw(in: textRect, withAttributes: attributes)

            drawGraphics(
                with: points,
                in: context,
                offset: graphOffset
            )
        }
        
        return data
    }
}

private extension PDFManager {
    func getTitleAttribute() -> [NSAttributedString.Key : NSObject] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes = [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 30),
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]

        return attributes
    }

    func drawGraphics(
        with graphs: [[Float]],
        in context: UIGraphicsPDFRendererContext,
        offset: CGFloat
    ) {
        var graphOffset = offset
        for (index, points) in graphs.enumerated() {
            if index % Constants.maxGraphCountOnPage == 0 && index != 0 {
                context.beginPage()
                graphOffset = Constants.spacing
            }

            graphDrawer.drawGraph(
                with: points.map { .init($0) },
                in: context.cgContext,
                rect: Constants.graphRect,
                graphOffsetY: graphOffset
            )

            graphOffset += Constants.spacing + Constants.graphHeight
        }
    }
}
