// 
//  SubscriptionItems.swift
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
import CoreData

func deleteItem(_ item: Item, in context: NSManagedObjectContext) {
    withAnimation {
        context.delete(item)
        try? context.save()
    }
}

func deleteAtOffset(_ offsets: IndexSet,
                                on items: FetchedResults<Item>,
                                with context: NSManagedObjectContext) {
    
    offsets.map { items[$0] }.forEach(context.delete)

    do {
        try context.save()
    } catch {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        let nsError = error as NSError
        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
}
