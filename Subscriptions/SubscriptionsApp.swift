//
//  SubscriptionsApp.swift
//  Subscriptions
//
//  Created by Timo Zacherl on 14.12.21.
//

import SwiftUI

@main
struct SubscriptionsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
