// 
//  NotificationScheduler.swift
//  NotificationScheduler
// 
//  Created by Timo Zacherl on 03.02.22.
// 
//  Copyright © 2022 Timo Zacherl. All rights reserved.
// 
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
// 

import Foundation
import UserNotifications
import CoreData
import SwiftUI

class NotificationScheduler: ObservableObject {
    
    static var shared = NotificationScheduler()
    
    private let center = UNUserNotificationCenter.current()

    func scheduleNotifications(for items: FetchedResults<Item>, at time: Date, with priceTag: Bool, and formatter: NumberFormatter) async {
        revokeNotifications()
        
        let calendar = Calendar.current
        
        // TODO: schedule all the notifications
        let itemsWithNextBill: [ItemWithNextBill] = items.compactMap {
            if let nextBill = getNextBill($0, circle: BillingOption($0.billing)) {
                return ItemWithNextBill(item: $0, nextBill: nextBill)
            }
            return nil
        }
        
        // This additional layer of abstraction is not really needed now,
        // but might be in the future. Therefor it stays here for now.
        let itemsOnSameDay = Dictionary(grouping: itemsWithNextBill) { $0.nextBill }
                
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        itemsOnSameDay.forEach { (date, items) in
            items.forEach { itemWithNextBill in
                itemWithNextBill.item.reminders?.forEach { reminder in
                    if let reminder = reminder as? Reminder {
                        var notificationDate = calendar.date(byAdding: .day, value: Int(reminder.daysBefore) * -1, to: itemWithNextBill.nextBill)!
                        notificationDate = calendar.date(bySetting: .hour, value: timeComponents.hour!, of: notificationDate)!
                        notificationDate = calendar.date(bySetting: .minute, value: timeComponents.minute!, of: notificationDate)!
                        
                        var inDaysString: String
                        if reminder.daysBefore == 1 {
                            inDaysString = "tomorrow"
                        } else if reminder.daysBefore == 2 {
                            inDaysString = "the day after tomorrow"
                        } else {
                            inDaysString = "in \(Int(reminder.daysBefore).written ?? "\(reminder.daysBefore)") Days"
                        }
                        
                        let content = UNMutableNotificationContent()
                        content.title = "Abonementi - Subscription"
                        if priceTag, let cost = itemWithNextBill.item.cost, let formattedCost = formatter.string(from: cost), let title = itemWithNextBill.item.title {
                            content.body = "Your \(title) subscription for \(formattedCost) will be charged \(inDaysString)."
                        } else if let title = itemWithNextBill.item.title {
                            content.body = "Your \(title) subscription will be charged \(inDaysString)."
                        } else {
                            content.body = "One of your subscriptions will be charged \(inDaysString)"
                        }
                        content.threadIdentifier = "next-bill"
                        content.categoryIdentifier = "next-bill"
                        content.userInfo = ["item": "\(itemWithNextBill.item.id)"]
                        
                        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
                        
                        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                        
                        let uuidString = UUID().uuidString
                        let request = UNNotificationRequest(identifier: uuidString,
                                                            content: content,
                                                            trigger: trigger)

                        center.add(request) { error in
                           if error != nil {
                               print(error as Any)
                           }
                            
                            self.center.getPendingNotificationRequests { requests in
                                print(requests)
                            }
                        }
                    }
                }
                
                itemWithNextBill.item.cancellationReminders?.forEach { reminder in
                    if let reminder = reminder as? CancellationReminder, let onDate = reminder.onDate {
                        let dateFormatter = DateFormatter()
                        dateFormatter.timeStyle = .none
                        dateFormatter.dateStyle = .medium
                        
                        let content = UNMutableNotificationContent()
                        content.title = "Abonementi - Cancel Subscription"
                        if let deactivationDate = itemWithNextBill.item.deactivationDate, let title = itemWithNextBill.item.title {
                            content.body = "You should cancel your \(title) subscription before \(dateFormatter.string(from: deactivationDate))."
                        } else if let title = itemWithNextBill.item.title {
                            content.body = "You should cancel your \(title) soon. Your next charge will be at \(dateFormatter.string(from: itemWithNextBill.nextBill))."
                        } else {
                            content.body = "You should cancel one of your subscriptions soon. Your next charge will be at \(dateFormatter.string(from: itemWithNextBill.nextBill))"
                        }
                        content.threadIdentifier = "cancellation"
                        content.categoryIdentifier = "cancellation"
                        content.userInfo = ["item": "\(itemWithNextBill.item.id)"]
                        
                        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: onDate)
                        
                        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                                                
                        let uuidString = UUID().uuidString
                        let request = UNNotificationRequest(identifier: uuidString,
                                                            content: content,
                                                            trigger: trigger)
                        
                        center.add(request) { error in
                           if error != nil {
                               print(error as Any)
                           }
                        }
                    }
                }
            }
        }
    }

    func revokeNotifications() {
        return center.removeAllPendingNotificationRequests()
    }
    
    func removeDeliveredNotifications() {
        return center.removeAllDeliveredNotifications()
    }
    
    func requestPermissions() async -> Bool {
        do {
            let settings = await getNotificationSettings()
            
            if settings.authorizationStatus == .notDetermined {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge, .providesAppNotificationSettings])
                
                return granted
            }
        } catch {
            print(error.localizedDescription)
        }
        
        return false
    }
    
    private func getNotificationSettings() async -> UNNotificationSettings {
        return await withCheckedContinuation { checkedContinuation in
            center.getNotificationSettings { settings in
                checkedContinuation.resume(returning: settings)
            }
        }
    }
        
}

struct ItemWithNextBill {
    var item: Item
    var nextBill: Date
}
