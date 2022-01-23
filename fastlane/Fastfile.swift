// This file contains the fastlane.tools configuration
// You can find the documentation at https://docs.fastlane.tools
//
// For a list of all available actions, check out
//
//     https://docs.fastlane.tools/actions
//

import Foundation

class Fastfile: LaneFile {
    let xcodeproj = OptionalConfigValue(stringLiteral: "Subscriptions.xcodeproj")
    let appleID = OptionalConfigValue(stringLiteral: environmentVariable(get: "APPLE_ID"))
    
	func screenshotsLane() {
        desc("Generate new localized screenshots")
		captureScreenshots(scheme: "SubscriptionsUITests")
        uploadToAppStore(username: "appleID", appIdentifier: "com.timozacherl.Subscriptions", skipBinaryUpload: true, skipMetadata: true)
	}
    
    func releaseLane() {
        desc("Upload a new build to TestFlight")
        
        incrementBuildNumber(xcodeproj: xcodeproj)
        
        let buildNumber = getBuildNumber()
        
        commitVersionBump(message: "build: version bump to \(buildNumber)", xcodeproj: xcodeproj)
        
        addGitTag()
        
        pushToGitRemote()
        
        buildIosApp(scheme: "Subscriptions")
        
        uploadToTestflight(appleId: "appleID")
    }
}
