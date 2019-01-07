//
//  RBCentralController.swift
//  BLECentral
//
//  Created by Mikołaj Skawiński on 05/01/2019.
//  Copyright © 2019 Mikołaj Skawiński. All rights reserved.
//

import RxSwift
import CoreBluetooth
import RxBluetoothKit

final class RBCentralController: CentralController {

    enum CentralError: Error {
        case centralAlreadyOn
        case centralAlreadyOff
    }

    var subscriptionToCharacteristic: Disposable!
    var central: CentralManager!
    private var echoCharacteristic: Characteristic?
    var characteristicDidUpdateValue: ((Bool, Data?) -> Void)?
    private let disposeBag = DisposeBag()

    func turnOn() throws {
        let echoID = CBUUID(string: "ec00")
        central = CentralManager()
        central
            .observeState()
            .startWith(central.state)
            .filter { $0 == .poweredOn }
            .flatMap { _ in self.central.scanForPeripherals(withServices: [echoID]) }
            .take(1)
            .flatMap { $0.peripheral.establishConnection() }
            .flatMap { $0.discoverServices([echoID]) }
            .flatMap { Observable.from($0) }
            .flatMap { $0.discoverCharacteristics([echoID]) }
            .subscribe { [weak self] characteristics in
                self?.echoCharacteristic = characteristics.element?.first
                self?.subscriptionToCharacteristic = self?.echoCharacteristic?.observeValueUpdateAndSetNotification()
                    .subscribe {
                        self?.characteristicDidUpdateValue?(false, $0.element?.value)
                        return
                }
        }.disposed(by: disposeBag)
    }

    func turnOff() throws {
        guard central != nil else { throw CentralError.centralAlreadyOff }
        subscriptionToCharacteristic.dispose()
        central = nil
    }

    func readValue() {
        _ = echoCharacteristic?
            .readValue()
            .asObservable()
            .take(1)
            .timeout(0.5, scheduler: MainScheduler.instance)
            .subscribe {
                self.characteristicDidUpdateValue?(true, $0.element?.value)
        }
    }

    func writeValue(_ value: Data) {
        echoCharacteristic?.writeValue(value, type: .withoutResponse).subscribe().dispose()
    }
}
