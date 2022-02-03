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
    var cost: Decimal = 0.0

    items.forEach { item in
        if inCurrentMonth(item, circle: BillingOption(item.billing), fullMonth: fullMonth) {
            cost += item.cost?.decimalValue ?? 0.0
        }
    }

    return cost
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
            if previousBilling.compare(today) != .orderedAscending {
                previousBilling = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: previousBilling)!
            }
            return previousBilling
        case .monthly:
            var components = DateComponents()
            components.day = Calendar.current.dateComponents([.day], from: firstBilling).day!
            var previousBilling = Calendar.current.date(bySetting: .day, value: components.day!, of: today)!
            if previousBilling.compare(today) != .orderedAscending {
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
    let previousBill = getPreviousBill(item, circle: circle)
    let nextBill = getNextBill(item, circle: circle)
    let today = Calendar.current.startOfDay(for: .now)
    let firstDay = fullMonth ? today.startOfMonth() : today
    let endOfMonth = today.endOfMonth()
    
    if let nextBill = nextBill, nextBill >= firstDay, nextBill <= endOfMonth {
        return true
    }
    
    if let previousBill = previousBill, fullMonth, previousBill >= firstDay, previousBill <= endOfMonth {
        return true
    }
    
    return false
}
