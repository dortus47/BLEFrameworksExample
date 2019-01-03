//
//  ViewController.swift
//  BLECentral
//
//  Created by Mikołaj Skawiński on 02/01/2019.
//  Copyright © 2019 Mikołaj Skawiński. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {

    private let centralController = BSCentralController()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Echo characteristic"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let centralSwitch: UISwitch = {
        let sw = UISwitch()
        sw.addTarget(self, action: #selector(centralSwitchChanged), for: .valueChanged)
        sw.translatesAutoresizingMaskIntoConstraints = false
        return sw
    }()

    private let readLabel: UILabel = {
        let label = UILabel()
        label.text = "Read value: "
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let notifiedLabel: UILabel = {
        let label = UILabel()
        label.text = "Notified value: "
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let writeLabel: UILabel = {
        let label = UILabel()
        label.text = "Write value"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let writeTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Value to write"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let readButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Read", for: .normal)
        button.addTarget(self, action: #selector(readButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var readStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [readLabel, readButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    lazy var writeStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [writeLabel, writeTextField])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        writeTextField.delegate = self
        centralController.characteristicDidUpdateValue = { [unowned self] isReading, value in
            guard let value = value else { return }
            let stringValue = String(data: value, encoding: .utf8)
            if isReading {
                self.readLabel.text = "Read value: \(stringValue ?? "")"
            } else {
                self.notifiedLabel.text = "Notified value: \(stringValue ?? "")"
            }
        }
    }

    private func setupLayout() {
        [titleLabel, centralSwitch,readStackView, notifiedLabel, writeStackView].forEach { view.addSubview($0) }
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centralSwitch.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            readStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            readStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            readStackView.topAnchor.constraint(equalTo: centralSwitch.bottomAnchor, constant: 10),
            notifiedLabel.topAnchor.constraint(equalTo: readStackView.bottomAnchor, constant: 8),
            notifiedLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            notifiedLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            writeStackView.topAnchor.constraint(equalTo: notifiedLabel.bottomAnchor, constant: 8),
            writeStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            writeStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    @objc
    private func readButtonTapped() {
        centralController.readValue()
    }

    @objc
    private func centralSwitchChanged() {
        try! centralSwitch.isOn ? centralController.turnOn() : centralController.turnOff()
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        guard let text = textField.text, let data = text.data(using: .utf8) else { return false }
        centralController.writeValue(data)
        return true
    }
}
