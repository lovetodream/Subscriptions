// 
//  DateCalculations.swift
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
import SwiftUI

extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDate = startOfDay(for: from)
        let toDate = startOfDay(for: to)
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate)
        
        return numberOfDays.day!
    }
}

extension Date {
    func startOfMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func endOfMonth() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: 1, second: -1), to: self.startOfMonth())!
    }
}

func calculateCostForRestOfCurrentMonth(for items: FetchedResults<Item>, fullMonth: Bool = false) -> Decimal {
    let today = fullMonth ? .now.startOfMonth().addingTimeInterval(TimeInterval(60 * 60 * 24)) : Calendar.current.startOfDay(for: .now)
    let startOfCurrentMonth = today.startOfMonth()
    let endOfCurrentMonth = today.endOfMonth()
    let remainingDays = Calendar.current.numberOfDaysBetween(today, and: endOfCurrentMonth) + (fullMonth ? 1 : 0)
    var fullCost: Decimal = 0
    for item in items {
        let billing = BillingOption(item.billing)
        if let firstBilling = item.lastBillDate, let cost = item.cost?.decimalValue, cost > Decimal(0.0) {
            switch billing {
            case .daily:
                fullCost += Decimal(remainingDays) * cost
            case .weekly:
                let weekdayOfFirstBill = Calendar.current.dateComponents([.weekday], from: firstBilling).weekday!
                var nextBilling = Calendar.current.date(bySetting: .weekday, value: weekdayOfFirstBill, of: today)!
                if nextBilling.compare(today) == .orderedAscending {
                    nextBilling = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: nextBilling)!
                }
                let occurrences = Calendar.current.dateComponents([.weekday], from: nextBilling, to: today.endOfMonth()).weekday! / 7
                fullCost += Decimal(occurrences) * cost
            case .monthly:
                var components = DateComponents()
                components.day = Calendar.current.dateComponents([.day], from: firstBilling).day!
                let currentMonthBilling = Calendar.current.date(bySetting: .day, value: components.day!, of: firstBilling)!
                if currentMonthBilling.compare(today) != .orderedAscending && currentMonthBilling.compare(endOfCurrentMonth) != .orderedDescending {
                    fullCost += cost
                }
            case .quarterly:
                var currentDateAtLoop = firstBilling
                var components = DateComponents()
                components.month = 3
                while currentDateAtLoop.compare(endOfCurrentMonth) != .orderedDescending {
                    if currentDateAtLoop.compare(today) != .orderedAscending {
                        fullCost += cost
                    }
                    currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
                }
            case .everySixMonths:
                var currentDateAtLoop = firstBilling
                var components = DateComponents()
                components.month = 6
                while currentDateAtLoop.compare(endOfCurrentMonth) != .orderedDescending {
                    if currentDateAtLoop.compare(today) != .orderedAscending {
                        fullCost += cost
                    }
                    currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
                }
            case .annually:
                var components = Calendar.current.dateComponents([.year, .month, .day], from: firstBilling)
                components.year = Calendar.current.component(.year, from: today)
                let currentYearBilling = Calendar.current.date(from: components)!
                if currentYearBilling.compare(today) != .orderedAscending && currentYearBilling.startOfMonth() == startOfCurrentMonth {
                    fullCost += cost
                }
            case .custom:
                let roundedBilling = Int(item.billing.rounded(.down))
                var currentDateAtLoop = firstBilling
                while currentDateAtLoop.compare(endOfCurrentMonth) != .orderedDescending {
                    if currentDateAtLoop.compare(today) != .orderedAscending {
                        fullCost += cost
                    }
                    currentDateAtLoop = Calendar.current.date(byAdding: .day, value: roundedBilling, to: currentDateAtLoop)!
                }
            }
        }
    }
    
    return fullCost
}

func getPreviousBill(_ item: Item, circle: BillingOption) -> Date? {
    let today = Calendar.current.startOfDay(for: .now)
    if let firstBilling = item.lastBillDate, let cost = item.cost?.decimalValue, cost > Decimal(0.0) {
        switch circle {
        case .daily:
            return Calendar.current.date(byAdding: .day, value: -1, to: today)
        case .weekly:
            let weekdayOfFirstBill = Calendar.current.dateComponents([.weekday], from: firstBilling).weekday!
            var previousBilling = Calendar.current.date(bySetting: .weekday, value: weekdayOfFirstBill, of: today)!
            if previousBilling.compare(today) == .orderedDescending {
                previousBilling = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: previousBilling)!
            }
            return previousBilling
        case .monthly:
            var components = DateComponents()
            components.day = Calendar.current.dateComponents([.day], from: firstBilling).day!
            var previousBilling = Calendar.current.date(bySetting: .day, value: components.day!, of: today)!
            if previousBilling.compare(today) == .orderedDescending {
                previousBilling = Calendar.current.date(byAdding: .month, value: -1, to: previousBilling)!
            }
            return previousBilling
        case .quarterly:
            var currentDateAtLoop = firstBilling
            var components = DateComponents()
            components.month = 3
            while currentDateAtLoop.compare(today) != .orderedDescending {
                currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
            }
            components.month = -3
            currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
            return currentDateAtLoop
        case .everySixMonths:
            var currentDateAtLoop = firstBilling
            var components = DateComponents()
            components.month = 6
            while currentDateAtLoop.compare(today) != .orderedDescending {
                currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
            }
            components.month = -6
            currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
            return currentDateAtLoop
        case .annually:
            var components = Calendar.current.dateComponents([.year, .month, .day], from: firstBilling)
            components.year = Calendar.current.component(.year, from: today)
            let currentYearBilling = Calendar.current.date(from: components)!
            if currentYearBilling.compare(today) == .orderedAscending {
                return currentYearBilling
            } else {
                return Calendar.current.date(byAdding: .year, value: -1, to: currentYearBilling)!
            }
        case .custom:
            let roundedBilling = Int(item.billing.rounded(.down))
            var currentDateAtLoop = firstBilling
            while currentDateAtLoop.compare(today) != .orderedDescending {
                currentDateAtLoop = Calendar.current.date(byAdding: .day, value: roundedBilling, to: currentDateAtLoop)!
            }
            currentDateAtLoop = Calendar.current.date(byAdding: .day, value: roundedBilling * -1, to: currentDateAtLoop)!
            return currentDateAtLoop
        }
    }
    
    return nil
}

func getNextBill(_ item: Item, circle: BillingOption) -> Date? {
    let today = Calendar.current.startOfDay(for: .now)
    if let firstBilling = item.lastBillDate, let cost = item.cost?.decimalValue, cost > Decimal(0.0) {
        switch circle {
        case .daily:
            return today
        case .weekly:
            let weekdayOfFirstBill = Calendar.current.dateComponents([.weekday], from: firstBilling).weekday!
            var nextBilling = Calendar.current.date(bySetting: .weekday, value: weekdayOfFirstBill, of: today)!
            if nextBilling.compare(today) == .orderedAscending {
                nextBilling = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: nextBilling)!
            }
            return nextBilling
        case .monthly:
            var components = DateComponents()
            components.day = Calendar.current.dateComponents([.day], from: firstBilling).day!
            var nextBilling = Calendar.current.date(bySetting: .day, value: components.day!, of: firstBilling)!
            if nextBilling.compare(today) == .orderedAscending {
                nextBilling = Calendar.current.date(byAdding: .month, value: 1, to: nextBilling)!
            }
            return nextBilling
        case .quarterly:
            var currentDateAtLoop = firstBilling
            var components = DateComponents()
            components.month = 3
            while currentDateAtLoop.compare(today) != .orderedDescending {
                currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
            }
            return currentDateAtLoop
        case .everySixMonths:
            var currentDateAtLoop = firstBilling
            var components = DateComponents()
            components.month = 6
            while currentDateAtLoop.compare(today) != .orderedDescending {
                currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
            }
            return currentDateAtLoop
        case .annually:
            var components = Calendar.current.dateComponents([.year, .month, .day], from: firstBilling)
            components.year = Calendar.current.component(.year, from: today)
            let currentYearBilling = Calendar.current.date(from: components)!
            if currentYearBilling.compare(today) != .orderedAscending {
                return currentYearBilling
            } else {
                return Calendar.current.date(byAdding: .year, value: 1, to: currentYearBilling)!
            }
        case .custom:
            let roundedBilling = Int(item.billing.rounded(.down))
            var currentDateAtLoop = firstBilling
            while currentDateAtLoop.compare(today) != .orderedDescending {
                currentDateAtLoop = Calendar.current.date(byAdding: .day, value: roundedBilling, to: currentDateAtLoop)!
            }
            return currentDateAtLoop
        }
    }
    
    return nil
}

func inCurrentMonth(_ item: Item, circle: BillingOption, fullMonth: Bool = false) -> Bool {
    let today = fullMonth ? .now.startOfMonth().addingTimeInterval(TimeInterval(60 * 60 * 24)) : Calendar.current.startOfDay(for: .now)
    let startOfCurrentMonth = today.startOfMonth()
    let endOfCurrentMonth = today.endOfMonth()
    let remainingDays = Calendar.current.numberOfDaysBetween(today, and: endOfCurrentMonth) + (fullMonth ? 1 : 0)
    if let firstBilling = item.lastBillDate, let cost = item.cost?.decimalValue, cost > Decimal(0.0) {
        switch circle {
        case .daily:
            return remainingDays > 0
        case .weekly:
            let weekdayOfFirstBill = Calendar.current.dateComponents([.weekday], from: firstBilling).weekday!
            var nextBilling = Calendar.current.date(bySetting: .weekday, value: weekdayOfFirstBill, of: today)!
            if nextBilling.compare(today) == .orderedAscending {
                nextBilling = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: nextBilling)!
            }
            let occurrences = Calendar.current.dateComponents([.weekday], from: nextBilling, to: today.endOfMonth()).weekday! / 7
            return occurrences > 0
        case .monthly:
            var components = DateComponents()
            components.day = Calendar.current.dateComponents([.day], from: firstBilling).day!
            let currentMonthBilling = Calendar.current.date(bySetting: .day, value: components.day!, of: firstBilling)!
            if currentMonthBilling.compare(today) != .orderedAscending && currentMonthBilling.compare(endOfCurrentMonth) != .orderedDescending {
                return true
            }
        case .quarterly:
            let components = Calendar.current.dateComponents([.year, .quarter], from: today)
            var nextBilling = Calendar.current.date(bySetting: .year, value: components.year!, of: firstBilling)!
            nextBilling = Calendar.current.date(bySetting: .quarter, value: components.quarter!, of: nextBilling)!
            if nextBilling.compare(today) != .orderedAscending && nextBilling.startOfMonth() == startOfCurrentMonth {
                return true
            }
        case .everySixMonths:
            let components = Calendar.current.dateComponents([.year, .weekOfYear], from: today)
            var nextBillingOpt1 = Calendar.current.date(bySetting: .year, value: components.year!, of: firstBilling)!
            nextBillingOpt1 = Calendar.current.date(bySetting: .weekOfYear, value: components.weekOfYear!, of: nextBillingOpt1)!
            let nextBillingOpt2 = Calendar.current.date(byAdding: .weekOfYear, value: 52 / 2, to: nextBillingOpt1)!
            let nextBillingOpt3 = Calendar.current.date(byAdding: .weekOfYear, value: 52 / 2 * -1, to: nextBillingOpt1)!
            if (nextBillingOpt1.compare(today) != .orderedAscending && nextBillingOpt1.startOfMonth() == startOfCurrentMonth) ||
                (nextBillingOpt2.compare(today) != .orderedAscending && nextBillingOpt2.startOfMonth() == startOfCurrentMonth) ||
                (nextBillingOpt3.compare(today) != .orderedAscending && nextBillingOpt3.startOfMonth() == startOfCurrentMonth) {
                return true
            }
        case .annually:
            let components = Calendar.current.dateComponents([.year], from: today)
            let currentYearBilling = Calendar.current.date(bySetting: .year, value: components.year!, of: firstBilling)!
            if currentYearBilling.compare(today) != .orderedAscending && currentYearBilling.startOfMonth() == startOfCurrentMonth {
                return true
            }
        case .custom:
            let roundedBilling = Int(item.billing.rounded(.down))
            var currentDateAtLoop = firstBilling
            while currentDateAtLoop.compare(endOfCurrentMonth) != .orderedDescending {
                if currentDateAtLoop.compare(today) != .orderedAscending {
                    return true
                }
                currentDateAtLoop = Calendar.current.date(byAdding: .day, value: roundedBilling, to: currentDateAtLoop)!
            }
        }
    }
    
    return false
}
