//
//  BSCentralController.swift
//  BLECentral
//
//  Created by Mikołaj Skawiński on 03/01/2019.
//  Copyright © 2019 Mikołaj Skawiński. All rights reserved.
//

import BlueSwift

final class BSCentralController: CentralController {

    private let connection = BluetoothConnection.shared
    private var echoCharacteristic: Characteristic!
    private var echoPeripheral: Peripheral<Connectable>?
    var characteristicDidUpdateValue: ((Bool, Data?) -> Void)?

    func turnOn() throws {
        echoCharacteristic = try! Characteristic(uuid: "ec00", shouldObserveNotification: true)
        echoCharacteristic.notifyHandler = { [weak self] data in
            self?.characteristicDidUpdateValue?(false, data)
        }
        let echoService = try! Service(uuid: "ec00", characteristics: [echoCharacteristic])
        let configuration = try Configuration(services: [echoService], advertisement: "ec00")
        echoPeripheral = Peripheral(configuration: configuration)
        connection.connect(echoPeripheral!) { error in
            print(error ?? "error connecting to peripheral")
        }
    }

    func turnOff() throws {
        try connection.disconnect(echoPeripheral!)
    }

    func readValue() {
        echoPeripheral?.read(echoCharacteristic) { [weak self] (data, error) in
            guard error == nil else { return }
            self?.characteristicDidUpdateValue?(true, data)
        }
    }

    func writeValue(_ value: Data) {
        echoPeripheral?.write(command: .data(value), characteristic: echoCharacteristic, type: .withoutResponse) { (error) in
            print(error)
        }
    }
}
