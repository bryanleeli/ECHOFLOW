//
//  Item.swift
//  Echo
//
//  Created by 李毅 on 10/19/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
