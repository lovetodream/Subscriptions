import Foundation

var appIdentifier: String { return "com.timozacherl.Subscriptions" } // The bundle identifier of your app
var appleID: String {
    return Bundle.main.object(forInfoDictionaryKey: "appleID") as! String
} // Your Apple email address

var itcTeam: String? {
    return Bundle.main.object(forInfoDictionaryKey: "connectTeamID") as! String
} // App Store Connect Team ID
var teamID: String {
    return Bundle.main.object(forInfoDictionaryKey: "developerTeamID") as! String
} // Apple Developer Portal Team ID


// For more information about the Appfile, see:
//     https://docs.fastlane.tools/advanced/#appfile
