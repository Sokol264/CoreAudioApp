//
//  PDFPreviewController.swift
//  AudioCoreApp
//
//  Created by Данил Соколов on 15.09.2024.
//

import UIKit
import PDFKit

class PDFPreviewController: UIViewController {
//    private var pdfPreview = PDFView()
    private var pdfPreview = GraphDrawerView()
    
    init(document: PDFDocument) {
        super.init(nibName: nil, bundle: nil)
        pdfPreview.dataPoints = [10, 30, 20, 40, 25, 60, 35]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(pdfPreview)
        setPdfPreviewConstraints()
    }
}

private extension PDFPreviewController {
    func setPdfPreviewConstraints() {
        pdfPreview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfPreview.topAnchor.constraint(equalTo: view.topAnchor),
//            pdfPreview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pdfPreview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfPreview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfPreview.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2)
        ])
    }
}
