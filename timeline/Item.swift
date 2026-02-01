//
//  Item.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
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
