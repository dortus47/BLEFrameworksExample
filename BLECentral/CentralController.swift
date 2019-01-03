//
//  CentralController.swift
//  BLECentral
//
//  Created by Mikołaj Skawiński on 02/01/2019.
//  Copyright © 2019 Mikołaj Skawiński. All rights reserved.
//

import Foundation

protocol CentralController {
    func turnOn() throws
    func turnOff() throws
    func readValue()
    func writeValue(_ value: Data)
    func setNotifyValue(_ enabled: Bool)
}
