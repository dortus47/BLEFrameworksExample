//
//  BSCentralController.swift
//  BLECentral
//
//  Created by Mikołaj Skawiński on 03/01/2019.
//  Copyright © 2019 Mikołaj Skawiński. All rights reserved.
//

import BlueSwift

final class BSCentralController: CentralController {

    enum CentralError: Error {
        case centralAlreadyOn
        case centralAlreadyOff
    }

    private let connection = BluetoothConnection.shared
    private var echoCharacteristic: Characteristic!
    private var echoPeripheral: Peripheral<Connectable>?
    var characteristicDidUpdateValue: ((Bool, Data?) -> Void)?

    func turnOn() throws {
        guard echoPeripheral == nil else { throw CentralError.centralAlreadyOn }
        let echoIDString = "ec00"
        echoCharacteristic = try! Characteristic(uuid: echoIDString, shouldObserveNotification: true)
        echoCharacteristic.notifyHandler = { [weak self] data in
            self?.characteristicDidUpdateValue?(false, data)
        }
        let echoService = try! Service(uuid: echoIDString, characteristics: [echoCharacteristic])
        let configuration = try! Configuration(services: [echoService], advertisement: echoIDString)
        echoPeripheral = Peripheral(configuration: configuration)
        connection.connect(echoPeripheral!) { error in
            print(error ?? "error connecting to peripheral")
        }
    }

    func turnOff() throws {
        guard echoPeripheral != nil else { throw CentralError.centralAlreadyOff }
        try connection.disconnect(echoPeripheral!)
        echoPeripheral = nil
    }

    func readValue() {
        echoPeripheral?.read(echoCharacteristic) { [weak self] (data, error) in
            guard error == nil else { return }
            self?.characteristicDidUpdateValue?(true, data)
        }
    }

    func writeValue(_ value: Data) {
        echoPeripheral?.write(command: .data(value), characteristic: echoCharacteristic, type: .withoutResponse) { (error) in
            print(error ?? "error writing characteristic value")
        }
    }
}
