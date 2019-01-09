/**
 * Copyright (c) 2019 Mikołaj Skawiński
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import CoreBluetooth

public class PeripheralController: NSObject {

    enum PeripheralError: Error {
        case peripheralAlreadyOn
        case peripheralAlreadyOff
    }

    private let echoID = CBUUID(string: "ec00")
    private let peripheralName: String
    private var peripheral: CBPeripheralManager!
    private var data: Data?
    private lazy var characteristic = CBMutableCharacteristic(type: echoID, properties: [.writeWithoutResponse, .write, .read, .notify], value: nil, permissions: [.writeable, .readable])

    public init(peripheralName: String) {
        self.peripheralName = peripheralName
        super.init()
    }

    public func turnOn() throws {
        guard peripheral == nil else { throw PeripheralError.peripheralAlreadyOn }
        peripheral = CBPeripheralManager(delegate: self, queue: .main)
    }

    public func turnOff() throws {
        guard peripheral != nil, peripheral.state == .poweredOn else { throw PeripheralError.peripheralAlreadyOff }
        peripheral.stopAdvertising()
        peripheral = nil
    }
}

extension PeripheralController: CBPeripheralManagerDelegate {

    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else { return }
        let advertisementData: [String: Any] = [CBAdvertisementDataLocalNameKey: peripheralName,
                                                CBAdvertisementDataServiceUUIDsKey: [echoID]]
        let echoService = CBMutableService(type: echoID, primary: true)
        echoService.characteristics = [characteristic]
        peripheral.add(echoService)
        peripheral.startAdvertising(advertisementData)
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        request.value = data
        peripheral.respond(to: request, withResult: .success)
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        requests.forEach {
            guard let value = $0.value else { return }
            peripheral.updateValue(value, for: characteristic, onSubscribedCentrals: nil)
            peripheral.respond(to: $0, withResult: .success)
            data = value
        }
    }
}
