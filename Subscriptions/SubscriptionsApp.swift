//
//  SubscriptionsApp.swift
//  Subscriptions
//
//  Created by Timo Zacherl on 14.12.21.
//
//  Copyright © 2021 Timo Zacherl. All rights reserved.
//
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
//

import SwiftUI
import Sentry

@main
struct SubscriptionsApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        SentrySDK.start { options in
            options.dsn = Bundle.main.object(forInfoDictionaryKey: "sentryDSN") as? String ?? ""
            
            #if DEBUG
            options.sampleRate = 1.0
            #else
            options.sampleRate = 0.25
            #endif
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
