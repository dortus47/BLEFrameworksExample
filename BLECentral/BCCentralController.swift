//
//  BCCentralController.swift
//  BLECentral
//
//  Created by Mikołaj Skawiński on 03/01/2019.
//  Copyright © 2019 Mikołaj Skawiński. All rights reserved.
//

import CoreBluetooth
import BlueCapKit

final class BCCentralController: CentralController {

    public enum CentralError : Error {
        case dataCharactertisticNotFound
        case enabledCharactertisticNotFound
        case updateCharactertisticNotFound
        case serviceNotFound
        case invalidState
        case resetting
        case poweredOff
        case unknown
        case unlikely
    }
    
    private var central: CentralManager!
    private var peripheral: Peripheral?
    private var echoCharacteristic: Characteristic?
    private var subscriptionFuture: FutureStream<Data?>? {
        didSet {
            subscriptionFuture?.onSuccess { data in
                self.characteristicDidUpdateValue?(false, data)
            }
        }
    }
    var characteristicDidUpdateValue: ((Bool, Data?) -> Void)?

    func turnOn() throws {
        central = CentralManager()
        let discoveryFuture = central.whenStateChanges()
        .flatMap { [weak central] state -> FutureStream<Peripheral> in
            guard let central = central else { throw CentralError.unlikely }
            switch state {
            case .poweredOn:
                return central.startScanning(forServiceUUIDs: [CBUUID(string: "ec00")])
            case .poweredOff:
                throw CentralError.poweredOff
            case .unauthorized, .unsupported:
                throw CentralError.invalidState
            case .resetting:
                throw CentralError.resetting
            case .unknown:
                throw CentralError.unknown
            }
        }.flatMap { [weak self] discoveredPeripheral  -> FutureStream<Void> in
                self?.central.stopScanning()
                self?.peripheral = discoveredPeripheral
                return discoveredPeripheral.connect(connectionTimeout: 10.0)
        }.flatMap { [weak self] () -> Future<Void> in
                guard let peripheral = self?.peripheral else {
                    throw CentralError.unlikely
                }
                return peripheral.discoverServices([CBUUID(string: "ec00")])
        }.flatMap { [weak self] () -> Future<Void> in
            guard
                let peripheral = self?.peripheral,
                let service = peripheral.services(withUUID: CBUUID(string: "ec00"))?.first
            else {
                throw CentralError.serviceNotFound
            }
            return service.discoverCharacteristics([CBUUID(string: "ec00")])
        }

        subscriptionFuture = discoveryFuture
            .flatMap { [weak self] () -> Future<Void> in
                guard
                    let self = self,
                    let peripheral = self.peripheral,
                    let service = peripheral.services(withUUID: CBUUID(string: "ec00"))?.first
                else {
                    throw CentralError.serviceNotFound
                }
                guard let characteristic = service
                    .characteristics(withUUID: CBUUID(string: "ec00"))?
                    .first
                else {
                        throw CentralError.dataCharactertisticNotFound
                }
                self.echoCharacteristic = characteristic
                return self.echoCharacteristic!.startNotifying()
            }.flatMap { [weak self] () -> FutureStream<Data?> in
                guard let characteristic = self?.echoCharacteristic else {
                    throw CentralError.dataCharactertisticNotFound
                }
                return characteristic.receiveNotificationUpdates()
            }
    }

    func turnOff() throws {

    }

    func readValue() {
        echoCharacteristic?.read().onSuccess { [weak self] in
            guard let data = self?.echoCharacteristic?.dataValue else { return }
            self?.characteristicDidUpdateValue?(true, data)
        }
    }

    func writeValue(_ value: Data) {
        _ = echoCharacteristic?.write(data: value, timeout: .infinity, type: .withoutResponse)
    }
}
