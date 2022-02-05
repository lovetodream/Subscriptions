//
//  Icons.swift
//  Subscriptions
//
//  Created by Timo Zacherl on 09.01.22.
//
//  Copyright © 2022 Timo Zacherl. All rights reserved.
//
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
//

import Foundation

// TODO: This needs some work
struct Icon: Identifiable, Codable {
    init(_ symbolName: String, label: String) {
        self.symbolName = symbolName
        self.label = label
    }
    
    var id: String { symbolName }
    var symbolName: String
    var label: String
    
    static var list: [Icon] = Bundle.main.decode([Icon].self, from: "Icons.json")
}
