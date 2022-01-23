import Foundation

var appIdentifier: String { return "com.timozacherl.Subscriptions" } // The bundle identifier of your app
var appleID: String {
    return environmentVariable(get: "APPLE_ID")
} // Your Apple email address

var itcTeam: String? {
    return environmentVariable(get: "CONNECT_TEAM_ID")
} // App Store Connect Team ID
var teamID: String {
    return environmentVariable(get: "DEV_PORTAL_TEAM_ID")
} // Apple Developer Portal Team ID


// For more information about the Appfile, see:
//     https://docs.fastlane.tools/advanced/#appfile
