// This file contains the fastlane.tools configuration
// You can find the documentation at https://docs.fastlane.tools
//
// For a list of all available actions, check out
//
//     https://docs.fastlane.tools/actions
//

import Foundation

class Fastfile: LaneFile {
	func screenshotsLane() {
	desc("Generate new localized screenshots")
		captureScreenshots(scheme: "SubscriptionsUITests")
        uploadToAppStore(username: Bundle.main.object(forInfoDictionaryKey: "appleID") as! String, appIdentifier: "com.timozacherl.Subscriptions", skipBinaryUpload: true, skipMetadata: true)
	}
}
