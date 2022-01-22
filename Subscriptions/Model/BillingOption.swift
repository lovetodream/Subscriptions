// 
//  BillingOption.swift
//  Subscriptions
// 
//  Created by Timo Zacherl on 22.01.22.
// 
//  Copyright © 2022 Timo Zacherl. All rights reserved.
// 
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
// 

import Foundation

enum BillingOption: Int, CaseIterable, Hashable {
    case daily = 1
    case weekly = 7
    case monthly = 30
    case quarterly = 90
    case everySixMonths = 180
    case annually = 365
    case custom = -1
    
    init(_ number: Double) {
        if number.truncatingRemainder(dividingBy: 1.0) != 0 {
            self = .custom
        } else {
            let int = Int(number)
            if int < 7 {
                self = .daily
            } else if int < 30 {
                self = .weekly
            } else if int < 90 {
                self = .monthly
            } else if int < 180 {
                self = .quarterly
            } else if int < 365 {
                self = .everySixMonths
            } else {
                self = .annually
            }
        }
    }
}

enum BillingLabel: String {
    case daily
    case weekly
    case monthly
    case quarterly
    case everySixMonths = "every six months"
    case annually
    case custom
    
    init(_ option: BillingOption) {
        switch option {
        case .daily:
            self = .daily
        case .weekly:
            self = .weekly
        case .monthly:
            self = .monthly
        case .quarterly:
            self = .quarterly
        case .everySixMonths:
            self = .everySixMonths
        case .annually:
            self = .annually
        case .custom:
            self = .custom
        }
    }
    
    func localizedString() -> String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}
