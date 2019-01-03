//
//  ViewController.swift
//  BLECentral
//
//  Created by Mikołaj Skawiński on 02/01/2019.
//  Copyright © 2019 Mikołaj Skawiński. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private let centralController = CBCentralController()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Echo characteristic"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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

    private let notifyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Turn on", for: .normal)
        button.setTitle("Turn off", for: .selected)
        button.addTarget(self, action: #selector(notifyButtonTapped), for: .touchUpInside)
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

    lazy var notifiedStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [notifiedLabel, notifyButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        writeTextField.delegate = self
        centralController.characteristicDidUpdateValue = { [unowned self] value in
            guard let value = value else { return }
            let stringValue = String(data: value, encoding: .utf8)
            self.readLabel.text = "Read value: \(stringValue ?? "")"
            self.notifiedLabel.text = "Notified value: \(stringValue ?? "")"
        }
        try! centralController.turnOn()
    }

    private func setupLayout() {
        [titleLabel, readStackView, notifiedStackView, writeStackView].forEach { view.addSubview($0) }
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            readStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            readStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            readStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            notifiedStackView.topAnchor.constraint(equalTo: readStackView.bottomAnchor, constant: 8),
            notifiedStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            notifiedStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            writeStackView.topAnchor.constraint(equalTo: notifiedStackView.bottomAnchor, constant: 8),
            writeStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            writeStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    @objc
    private func readButtonTapped() {
        centralController.readValue()
    }

    @objc
    private func notifyButtonTapped() {
        notifyButton.isSelected = !notifyButton.isSelected
        centralController.setNotifyValue(notifyButton.isSelected)
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
