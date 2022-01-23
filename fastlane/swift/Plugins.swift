import Foundation
/**
 Finds a tag of last release and determinates version of next release

 - parameters:
   - match: Match parameter of git describe. See man page of git describe for more info
   - commitFormat: The commit format to apply. Presets are 'default' or 'angular', or you can provide your own Regexp. Note: the supplied regex _must_ have 4 capture groups, in order: type, scope, has_exclamation_mark, and subject
   - releases: Map types of commit to release (major, minor, patch)
   - codepushFriendly: These types are consider as codepush friendly automatically
   - tagVersionMatch: To parse version number from tag name
   - ignoreScopes: To ignore certain scopes when calculating releases
   - showVersionPath: True if you want to print out the version calculated for each commit
   - debug: True if you want to log out a debug info

 - returns: Returns true if the next version is higher then the last version

 This action will find a last release tag and analyze all commits since the tag. It uses conventional commits. Every time when commit is marked as fix or feat it will increase patch or minor number (you can setup this default behaviour). After all it will suggest if the version should be released or not.
*/
public func analyzeCommits(match: String,
                           commitFormat: Any = "default",
                           releases: [String : Any] = [:],
                           codepushFriendly: [String] = ["chore", "test", "docs"],
                           tagVersionMatch: String = "\\d+\\.\\d+\\.\\d+",
                           ignoreScopes: [String] = [],
                           showVersionPath: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                           debug: OptionalConfigValue<Bool> = .fastlaneDefault(false)) {
let matchArg = RubyCommand.Argument(name: "match", value: match, type: nil)
let commitFormatArg = RubyCommand.Argument(name: "commit_format", value: commitFormat, type: nil)
let releasesArg = RubyCommand.Argument(name: "releases", value: releases, type: nil)
let codepushFriendlyArg = RubyCommand.Argument(name: "codepush_friendly", value: codepushFriendly, type: nil)
let tagVersionMatchArg = RubyCommand.Argument(name: "tag_version_match", value: tagVersionMatch, type: nil)
let ignoreScopesArg = RubyCommand.Argument(name: "ignore_scopes", value: ignoreScopes, type: nil)
let showVersionPathArg = showVersionPath.asRubyArgument(name: "show_version_path", type: nil)
let debugArg = debug.asRubyArgument(name: "debug", type: nil)
let array: [RubyCommand.Argument?] = [matchArg,
commitFormatArg,
releasesArg,
codepushFriendlyArg,
tagVersionMatchArg,
ignoreScopesArg,
showVersionPathArg,
debugArg]
let args: [RubyCommand.Argument] = array
.filter { $0?.value != nil }
.compactMap { $0 }
let command = RubyCommand(commandID: "", methodName: "analyze_commits", className: nil, args: args)
  _ = runner.executeCommand(command)
}

/**
 Get commits since last version and generates release notes

 - parameters:
   - format: You can use either markdown, slack or plain
   - title: Title for release notes
   - commitUrl: Uses as a link to the commit
   - order: You can change the order of groups in release notes
   - sections: Map type to section title
   - displayAuthor: Whether you want to show the author of the commit
   - displayTitle: Whether you want to hide the title/header with the version details at the top of the changelog
   - displayLinks: Whether you want to display the links to commit IDs
   - ignoreScopes: To ignore certain scopes when calculating releases
   - debug: True if you want to log out a debug info

 - returns: Returns generated release notes as a string

 Uses conventional commits. It groups commits by their types and generates release notes in markdown or slack format.
*/
public func conventionalChangelog(format: String = "markdown",
                                  title: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  commitUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  order: [String] = ["feat", "fix", "refactor", "perf", "chore", "test", "docs", "no_type"],
                                  sections: [String : Any] = [:],
                                  displayAuthor: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  displayTitle: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                                  displayLinks: OptionalConfigValue<Bool> = .fastlaneDefault(true),
                                  ignoreScopes: [String] = [],
                                  debug: OptionalConfigValue<Bool> = .fastlaneDefault(false)) {
let formatArg = RubyCommand.Argument(name: "format", value: format, type: nil)
let titleArg = title.asRubyArgument(name: "title", type: nil)
let commitUrlArg = commitUrl.asRubyArgument(name: "commit_url", type: nil)
let orderArg = RubyCommand.Argument(name: "order", value: order, type: nil)
let sectionsArg = RubyCommand.Argument(name: "sections", value: sections, type: nil)
let displayAuthorArg = displayAuthor.asRubyArgument(name: "display_author", type: nil)
let displayTitleArg = displayTitle.asRubyArgument(name: "display_title", type: nil)
let displayLinksArg = displayLinks.asRubyArgument(name: "display_links", type: nil)
let ignoreScopesArg = RubyCommand.Argument(name: "ignore_scopes", value: ignoreScopes, type: nil)
let debugArg = debug.asRubyArgument(name: "debug", type: nil)
let array: [RubyCommand.Argument?] = [formatArg,
titleArg,
commitUrlArg,
orderArg,
sectionsArg,
displayAuthorArg,
displayTitleArg,
displayLinksArg,
ignoreScopesArg,
debugArg]
let args: [RubyCommand.Argument] = array
.filter { $0?.value != nil }
.compactMap { $0 }
let command = RubyCommand(commandID: "", methodName: "conventional_changelog", className: nil, args: args)
  _ = runner.executeCommand(command)
}
