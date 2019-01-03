//
//  CBCentralController.swift
//  CBCentral
//
//  Created by Mikołaj Skawiński on 02/01/2019.
//  Copyright © 2019 Mikołaj Skawiński. All rights reserved.
//

import CoreBluetooth

final class CBCentralController: NSObject, CentralController {

    enum CentralError: Swift.Error {
        case centralAlreadyOn
        case centralAlreadyOff
    }

    let echoID = CBUUID(string: "ec00")
    var central: CBCentralManager!
    var echoPeripheral: CBPeripheral?
    var echoCharacteristic: CBCharacteristic?
    var characteristicDidUpdateValue: ((Bool, Data?) -> Void)?
    private var isReadingCharacteristicValue = false

    func turnOn() throws {
        guard central == nil else { throw CentralError.centralAlreadyOn }
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func turnOff() throws {
        guard central != nil, central.state == .poweredOn else { throw CentralError.centralAlreadyOff }
        central.stopScan()
        central = nil
    }

    func readValue() {
        guard let characteristic = echoCharacteristic else { return }
        echoPeripheral?.readValue(for: characteristic)
        isReadingCharacteristicValue = true
    }

    func writeValue(_ value: Data) {
        guard let characteristic = echoCharacteristic else { return }
        echoPeripheral?.writeValue(value, for: characteristic, type: .withoutResponse)
    }
}

extension CBCentralController: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        central.scanForPeripherals(withServices: [echoID])
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        central.stopScan()
        central.connect(peripheral)
        echoPeripheral = peripheral
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([echoID])
    }
}

extension CBCentralController: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where:  { $0.uuid == echoID }) else { return }
        peripheral.discoverCharacteristics([echoID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == echoID}) else { return }
        echoPeripheral?.setNotifyValue(true, for: characteristic)
        echoCharacteristic = characteristic
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        characteristicDidUpdateValue?(isReadingCharacteristicValue, characteristic.value)
        isReadingCharacteristicValue = false
    }
}
