// 
//  Formatter.swift
//  Subscriptions
// 
//  Created by Timo Zacherl on 11.02.22.
// 
//  Copyright © 2022 Timo Zacherl. All rights reserved.
// 
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
// 

import Foundation

let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
