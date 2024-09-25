//
//  ViewController.swift
//  AudioCoreApp
//
//  Created by Данил Соколов on 08.09.2024.
//

import UIKit
import Combine
import PDFKit

final class ViewController: UIViewController {
    // MARK: Private properties
    private let viewModel = ViewModel()
    private var subscriptions = Set<AnyCancellable>()

    private lazy var buttons: [UIButton] = {
        [recordButton, playButton, higherPitchButton, lowerPitchButton, showPDFButton]
    }()

    // MARK: Views
    private let recordButton = UIButton()
    private let playButton = UIButton()
    private let higherPitchButton = UIButton()
    private let lowerPitchButton = UIButton()
    private let showPDFButton = UIButton()

    // MARK: View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        baseInit()
    }
}

// MARK: - ViewController configuration methods
private extension ViewController {
    func baseInit() {
        addSubviews()
        configuringViews()
        constraintsSettings()
        observeRecord()
        observePlaying()
    }

    func addSubviews() {
        view.addSubview(recordButton)
        view.addSubview(playButton)
        view.addSubview(showPDFButton)
        view.addSubview(lowerPitchButton)
        view.addSubview(higherPitchButton)
    }

    func configuringViews() {
        configureRecordButton()
        configurePlayButton()
        configureLowerPitchButton()
        configureHigherPitchButton()
        configurePDFButton()
    }

    func constraintsSettings() {
        setRecordButtonConstraints()
        setPlayButtonConstraints()
        setPDFButtonConstraints()
        setLowerPitchButtonConstraints()
        setHigherPitchButtonConstraints()
    }
}

// MARK: ViewController observing methods
private extension ViewController {
    func observeRecord() {
        viewModel.$isRecording
            .sink { [weak self] isRecording in
                self?.recordStateChangeHandler(isRecording: isRecording)
            }
            .store(in: &subscriptions)
    }

    func observePlaying() {
        viewModel.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                self?.playingStateChangeHandler(isPlaying: isPlaying)
            }
            .store(in: &subscriptions)

        viewModel.$isHighPitchPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                self?.playingHighPitchStateChangeHandler(isPlaying: isPlaying)
            }
            .store(in: &subscriptions)

        viewModel.$isLowPitchPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                self?.playingLowPitchStateChangeHandler(isPlaying: isPlaying)
            }
            .store(in: &subscriptions)
    }
}

// MARK: ViewController helper methods
private extension ViewController {
    func recordStateChangeHandler(isRecording: Bool) {
        recordButtonImage(for: isRecording)
        enableButtonsExept(buttons: [recordButton], !isRecording)
    }

    func playingStateChangeHandler(isPlaying: Bool) {
        playButtonImage(for: isPlaying)
        enableButtonsExept(buttons: [playButton], !isPlaying)
    }

    func playingHighPitchStateChangeHandler(isPlaying: Bool) {
        higherPitchButtonImage(for: isPlaying)
        enableButtonsExept(buttons: [higherPitchButton], !isPlaying)
    }

    func playingLowPitchStateChangeHandler(isPlaying: Bool) {
        lowerPitchButtonImage(for: isPlaying)
        enableButtonsExept(buttons: [lowerPitchButton], !isPlaying)
    }

    func enableButtonsExept(buttons: [UIButton], _ state: Bool) {
        let mutable = self.buttons.filter { !buttons.contains($0) }

        for button in mutable {
            button.isEnabled = state
        }
    }
}

// MARK: - Views settings

// MARK: - Record button
private extension ViewController {
    func configureRecordButton() {
        recordButtonImage(for: false)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
    }

    func setRecordButtonConstraints() {
        recordButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            recordButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 50),
            recordButton.heightAnchor.constraint(equalTo: recordButton.widthAnchor),
        ])
    }

    func recordButtonImage(for isRecord: Bool) {
        let imageName = isRecord ? "pause.circle.fill" : "record.circle"
        recordButton.setBackgroundImage(UIImage(systemName: imageName), for: .normal)
    }

    @objc func recordTapped() {
        viewModel.recordButtonTapped()
    }
}

// MARK: - Play button
private extension ViewController {
    func configurePlayButton() {
        playButtonImage(for: false)
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
    }

    func setPlayButtonConstraints() {
        playButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 60),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 50),
            playButton.heightAnchor.constraint(equalTo: playButton.widthAnchor),
        ])
    }

    func playButtonImage(for isPlay: Bool) {
        let imageName = isPlay ? "pause.circle.fill" : "play.circle.fill"
        playButton.setBackgroundImage(UIImage(systemName: imageName), for: .normal)
    }

    @objc func playTapped() {
        viewModel.playButtonTapped()
    }
}

// MARK: - Higher pitch button
private extension ViewController {
    func configureHigherPitchButton() {
        higherPitchButtonImage(for: false)
        higherPitchButton.addTarget(self, action: #selector(playHigherTapped), for: .touchUpInside)
    }

    func setHigherPitchButtonConstraints() {
        higherPitchButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            higherPitchButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 60),
            higherPitchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 60),
            higherPitchButton.widthAnchor.constraint(equalToConstant: 50),
            higherPitchButton.heightAnchor.constraint(equalTo: higherPitchButton.widthAnchor),
        ])
    }

    func higherPitchButtonImage(for isPlay: Bool) {
        let imageName = isPlay ? "pause.circle.fill" : "arrow.up"
        higherPitchButton.setBackgroundImage(UIImage(systemName: imageName), for: .normal)
    }

    @objc func playHigherTapped() {
        viewModel.playButtonTapped(with: .high)
    }
}

// MARK: - Lower pitch button
private extension ViewController {
    func configureLowerPitchButton() {
        lowerPitchButtonImage(for: false)
        lowerPitchButton.addTarget(self, action: #selector(playLowerTapped), for: .touchUpInside)
    }

    func setLowerPitchButtonConstraints() {
        lowerPitchButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            lowerPitchButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 60),
            lowerPitchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -60),
            lowerPitchButton.widthAnchor.constraint(equalToConstant: 50),
            lowerPitchButton.heightAnchor.constraint(equalTo: lowerPitchButton.widthAnchor),
        ])
    }

    func lowerPitchButtonImage(for isPlay: Bool) {
        let imageName = isPlay ? "pause.circle.fill" : "arrow.down"
        lowerPitchButton.setBackgroundImage(UIImage(systemName: imageName), for: .normal)
    }
    
    @objc func playLowerTapped() {
        viewModel.playButtonTapped(with: .low)
    }
}


// MARK: - PDF button
private extension ViewController {
    func configurePDFButton() {
        showPDFButton.setBackgroundImage(
            UIImage(systemName: "chart.line.uptrend.xyaxis.circle.fill"),
            for: .normal
        )

        showPDFButton.addTarget(self, action: #selector(PDFTapped), for: .touchUpInside)
    }

    func setPDFButtonConstraints() {
        showPDFButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            showPDFButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 120),
            showPDFButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            showPDFButton.widthAnchor.constraint(equalToConstant: 50),
            showPDFButton.heightAnchor.constraint(equalTo: showPDFButton.widthAnchor),
        ])
    }

    @objc func PDFTapped() {
        let data = viewModel.pdfPreviewTapped()
        guard let data, let doc = PDFDocument(data: data) else {
            return
        }

        let preview = PDFPreviewController(document: doc)
        present(preview, animated: true)
    }
}
