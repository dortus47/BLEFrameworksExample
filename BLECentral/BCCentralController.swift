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
    private var discoveryFuture: FutureStream<Void>?
    private var echoCharacteristic: Characteristic?
    var characteristicDidUpdateValue: ((Bool, Data?) -> Void)?

    func turnOn() throws {
        central = CentralManager(options: [CBCentralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.central-manager-documentation" as NSString])
        let stateChangeFuture = central.whenStateChanges()
        let scanFuture = stateChangeFuture.flatMap { [weak central] state -> FutureStream<Peripheral> in
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
        }

        let connectionFuture = scanFuture.flatMap { [weak self] discoveredPeripheral  -> FutureStream<Void> in
            self?.central.stopScanning()
            self?.peripheral = discoveredPeripheral
            return discoveredPeripheral.connect(connectionTimeout: 10.0)
        }

        discoveryFuture = connectionFuture.flatMap { [weak peripheral] () -> Future<Void> in
            guard let peripheral = peripheral else {
                throw CentralError.unlikely
            }
            return peripheral.discoverServices([CBUUID(string: "ec00")])
            }.flatMap { [weak peripheral] () -> Future<Void> in
                guard let peripheral = peripheral, let service = peripheral.services(withUUID: CBUUID(string: "ec00"))?.first else {
                    throw CentralError.serviceNotFound
                }
                return service.discoverCharacteristics([CBUUID(string: "ec00")])
        }

        let subscriptionFuture = discoveryFuture?.flatMap { [weak echoCharacteristic, weak peripheral] () -> Future<Void> in
            guard let peripheral = peripheral, let service = peripheral.services(withUUID: CBUUID(string: "ec00"))?.first else {
                throw CentralError.serviceNotFound
            }
            guard let characteristic = service.characteristics(withUUID: CBUUID(string: "ec00"))?.first else {
                throw CentralError.dataCharactertisticNotFound
            }
            echoCharacteristic = characteristic
            return characteristic.startNotifying()
            }.flatMap(mapping: { [weak echoCharacteristic]() -> FutureStream<Data?> in
                guard let characteristic = echoCharacteristic else { throw CentralError.dataCharactertisticNotFound }
                return characteristic.receiveNotificationUpdates()
            })

        subscriptionFuture?.onSuccess { [weak self] data in
            self?.characteristicDidUpdateValue?(false, data)
        }
    }

    func turnOff() throws {

    }

    func readValue() {

    }

    func writeValue(_ value: Data) {
        
    }


}
