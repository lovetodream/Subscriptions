import Foundation
/**
 Checks that sentry-cli with the correct version is installed

 This action checks that the senty-cli is installed and meets the mimum verson requirements. You can use it at the start of your lane to ensure that sentry-cli is correctly installed.
*/
public func sentryCheckCliInstalled() {

let args: [RubyCommand.Argument] = []
let command = RubyCommand(commandID: "", methodName: "sentry_check_cli_installed", className: nil, args: args)
  _ = runner.executeCommand(command)
}

/**
 Creates a new release deployment for a project on Sentry

 - parameters:
   - url: Url for Sentry
   - authToken: Authentication token for Sentry
   - apiKey: API key for Sentry
   - orgSlug: Organization slug for Sentry project
   - projectSlug: Project slug for Sentry
   - version: Release version to associate the deploy with on Sentry
   - appIdentifier: App Bundle Identifier, prepended with the version.
For example bundle@version
   - build: Release build to associate the deploy with on Sentry
   - env: Set the environment for this release. This argument is required. Values that make sense here would be 'production' or 'staging'
   - name: Optional human readable name for this deployment
   - deployUrl: Optional URL that points to the deployment
   - started: Optional unix timestamp when the deployment started
   - finished: Optional unix timestamp when the deployment finished
   - time: Optional deployment duration in seconds. This can be specified alternatively to `started` and `finished`

 This action allows you to associate deploys to releases for a project on Sentry. See https://docs.sentry.io/product/cli/releases/#creating-deploys for more information.
*/
public func sentryCreateDeploy(url: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               authToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               apiKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               orgSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               projectSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               version: String,
                               appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               build: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               env: String,
                               name: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               deployUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                               started: Any? = nil,
                               finished: Any? = nil,
                               time: Any? = nil) {
let urlArg = url.asRubyArgument(name: "url", type: nil)
let authTokenArg = authToken.asRubyArgument(name: "auth_token", type: nil)
let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
let orgSlugArg = orgSlug.asRubyArgument(name: "org_slug", type: nil)
let projectSlugArg = projectSlug.asRubyArgument(name: "project_slug", type: nil)
let versionArg = RubyCommand.Argument(name: "version", value: version, type: nil)
let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
let buildArg = build.asRubyArgument(name: "build", type: nil)
let envArg = RubyCommand.Argument(name: "env", value: env, type: nil)
let nameArg = name.asRubyArgument(name: "name", type: nil)
let deployUrlArg = deployUrl.asRubyArgument(name: "deploy_url", type: nil)
let startedArg = RubyCommand.Argument(name: "started", value: started, type: nil)
let finishedArg = RubyCommand.Argument(name: "finished", value: finished, type: nil)
let timeArg = RubyCommand.Argument(name: "time", value: time, type: nil)
let array: [RubyCommand.Argument?] = [urlArg,
authTokenArg,
apiKeyArg,
orgSlugArg,
projectSlugArg,
versionArg,
appIdentifierArg,
buildArg,
envArg,
nameArg,
deployUrlArg,
startedArg,
finishedArg,
timeArg]
let args: [RubyCommand.Argument] = array
.filter { $0?.value != nil }
.compactMap { $0 }
let command = RubyCommand(commandID: "", methodName: "sentry_create_deploy", className: nil, args: args)
  _ = runner.executeCommand(command)
}

/**
 Create new releases for a project on Sentry

 - parameters:
   - url: Url for Sentry
   - authToken: Authentication token for Sentry
   - apiKey: API key for Sentry
   - orgSlug: Organization slug for Sentry project
   - projectSlug: Project slug for Sentry
   - version: Release version to create on Sentry
   - appIdentifier: App Bundle Identifier, prepended to version
   - build: Release build to create on Sentry
   - finalize: Whether to finalize the release. If not provided or false, the release can be finalized using the finalize_release action

 This action allows you to create new releases for a project on Sentry. See https://docs.sentry.io/learn/cli/releases/#creating-releases for more information.
*/
public func sentryCreateRelease(url: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                authToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                apiKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                orgSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                projectSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                version: String,
                                appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                build: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                finalize: OptionalConfigValue<Bool> = .fastlaneDefault(false)) {
let urlArg = url.asRubyArgument(name: "url", type: nil)
let authTokenArg = authToken.asRubyArgument(name: "auth_token", type: nil)
let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
let orgSlugArg = orgSlug.asRubyArgument(name: "org_slug", type: nil)
let projectSlugArg = projectSlug.asRubyArgument(name: "project_slug", type: nil)
let versionArg = RubyCommand.Argument(name: "version", value: version, type: nil)
let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
let buildArg = build.asRubyArgument(name: "build", type: nil)
let finalizeArg = finalize.asRubyArgument(name: "finalize", type: nil)
let array: [RubyCommand.Argument?] = [urlArg,
authTokenArg,
apiKeyArg,
orgSlugArg,
projectSlugArg,
versionArg,
appIdentifierArg,
buildArg,
finalizeArg]
let args: [RubyCommand.Argument] = array
.filter { $0?.value != nil }
.compactMap { $0 }
let command = RubyCommand(commandID: "", methodName: "sentry_create_release", className: nil, args: args)
  _ = runner.executeCommand(command)
}

/**
 Finalize a release for a project on Sentry

 - parameters:
   - url: Url for Sentry
   - authToken: Authentication token for Sentry
   - apiKey: API key for Sentry
   - orgSlug: Organization slug for Sentry project
   - projectSlug: Project slug for Sentry
   - version: Release version to finalize on Sentry
   - appIdentifier: App Bundle Identifier, prepended to version
   - build: Release build to finalize on Sentry

 This action allows you to finalize releases created for a project on Sentry. See https://docs.sentry.io/learn/cli/releases/#finalizing-releases for more information.
*/
public func sentryFinalizeRelease(url: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  authToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  apiKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  orgSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  projectSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  version: String,
                                  appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  build: OptionalConfigValue<String?> = .fastlaneDefault(nil)) {
let urlArg = url.asRubyArgument(name: "url", type: nil)
let authTokenArg = authToken.asRubyArgument(name: "auth_token", type: nil)
let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
let orgSlugArg = orgSlug.asRubyArgument(name: "org_slug", type: nil)
let projectSlugArg = projectSlug.asRubyArgument(name: "project_slug", type: nil)
let versionArg = RubyCommand.Argument(name: "version", value: version, type: nil)
let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
let buildArg = build.asRubyArgument(name: "build", type: nil)
let array: [RubyCommand.Argument?] = [urlArg,
authTokenArg,
apiKeyArg,
orgSlugArg,
projectSlugArg,
versionArg,
appIdentifierArg,
buildArg]
let args: [RubyCommand.Argument] = array
.filter { $0?.value != nil }
.compactMap { $0 }
let command = RubyCommand(commandID: "", methodName: "sentry_finalize_release", className: nil, args: args)
  _ = runner.executeCommand(command)
}

/**
 Set commits of a release

 - parameters:
   - url: Url for Sentry
   - authToken: Authentication token for Sentry
   - apiKey: API key for Sentry
   - orgSlug: Organization slug for Sentry project
   - projectSlug: Project slug for Sentry
   - version: Release version on Sentry
   - appIdentifier: App Bundle Identifier, prepended to version
   - build: Release build on Sentry
   - auto: Enable completely automated commit management
   - clear: Clear all current commits from the release
   - commit: Commit spec, see `sentry-cli releases help set-commits` for more information

 This action allows you to set commits in a release for a project on Sentry. See https://docs.sentry.io/cli/releases/#sentry-cli-commit-integration for more information.
*/
public func sentrySetCommits(url: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             authToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             apiKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             orgSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             projectSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             version: String,
                             appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             build: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             auto: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             clear: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                             commit: OptionalConfigValue<String?> = .fastlaneDefault(nil)) {
let urlArg = url.asRubyArgument(name: "url", type: nil)
let authTokenArg = authToken.asRubyArgument(name: "auth_token", type: nil)
let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
let orgSlugArg = orgSlug.asRubyArgument(name: "org_slug", type: nil)
let projectSlugArg = projectSlug.asRubyArgument(name: "project_slug", type: nil)
let versionArg = RubyCommand.Argument(name: "version", value: version, type: nil)
let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
let buildArg = build.asRubyArgument(name: "build", type: nil)
let autoArg = auto.asRubyArgument(name: "auto", type: nil)
let clearArg = clear.asRubyArgument(name: "clear", type: nil)
let commitArg = commit.asRubyArgument(name: "commit", type: nil)
let array: [RubyCommand.Argument?] = [urlArg,
authTokenArg,
apiKeyArg,
orgSlugArg,
projectSlugArg,
versionArg,
appIdentifierArg,
buildArg,
autoArg,
clearArg,
commitArg]
let args: [RubyCommand.Argument] = array
.filter { $0?.value != nil }
.compactMap { $0 }
let command = RubyCommand(commandID: "", methodName: "sentry_set_commits", className: nil, args: args)
  _ = runner.executeCommand(command)
}

/**
 Upload debugging information files.

 - parameters:
   - url: Url for Sentry
   - authToken: Authentication token for Sentry
   - apiKey: API key for Sentry
   - orgSlug: Organization slug for Sentry project
   - projectSlug: Project slug for Sentry
   - path: A path to search recursively for symbol files
   - type: Only consider debug information files of the given                                        type.  By default, all types are considered
   - noUnwind: Do not scan for stack unwinding information. Specify                                        this flag for builds with disabled FPO, or when                                        stackwalking occurs on the device. This usually                                        excludes executables and dynamic libraries. They might                                        still be uploaded, if they contain additional                                        processable information (see other flags)
   - noDebug: Do not scan for debugging information. This will                                        usually exclude debug companion files. They might                                        still be uploaded, if they contain additional                                        processable information (see other flags)
   - noSources: Do not scan for source information. This will                                        usually exclude source bundle files. They might                                        still be uploaded, if they contain additional                                        processable information (see other flags)
   - ids: Search for specific debug identifiers
   - requireAll: Errors if not all identifiers specified with --id could be found
   - symbolMaps: Optional path to BCSymbolMap files which are used to                                        resolve hidden symbols in dSYM files downloaded from                                        iTunes Connect. This requires the dsymutil tool to be                                        available
   - derivedData: Search for debug symbols in Xcode's derived data
   - noZips: Do not search in ZIP files
   - infoPlist: Optional path to the Info.plist.{n}We will try to find this                                        automatically if run from Xcode.  Providing this information                                        will associate the debug symbols with a specific ITC application                                        and build in Sentry.  Note that if you provide the plist                                        explicitly it must already be processed
   - noReprocessing: Do not trigger reprocessing after uploading
   - forceForeground: Wait for the process to finish.{n}                                       By default, the upload process will detach and continue in the                                        background when triggered from Xcode.  When an error happens,                                        a dialog is shown.  If this parameter is passed Xcode will wait                                        for the process to finish before the build finishes and output                                        will be shown in the Xcode build output
   - includeSources: Include sources from the local file system and upload                                        them as source bundles
   - wait: Wait for the server to fully process uploaded files. Errors                                        can only be displayed if --wait is specified, but this will                                        significantly slow down the upload process
   - uploadSymbolMaps: Upload any BCSymbolMap files found to allow Sentry to resolve                                        hidden symbols, e.g. when it downloads dSYMs directly from App                                        Store Connect or when you upload dSYMs without first resolving                                        the hidden symbols using --symbol-maps

 Files can be uploaded using the upload-dif command. This command will scan a given folder recursively for files and upload them to Sentry. See https://docs.sentry.io/product/cli/dif/#uploading-files for more information.
*/
public func sentryUploadDif(url: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            authToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            apiKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            orgSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            projectSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            path: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            type: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            noUnwind: Any? = nil,
                            noDebug: Any? = nil,
                            noSources: Any? = nil,
                            ids: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            requireAll: Any? = nil,
                            symbolMaps: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            derivedData: Any? = nil,
                            noZips: Any? = nil,
                            infoPlist: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                            noReprocessing: Any? = nil,
                            forceForeground: Any? = nil,
                            includeSources: Any? = nil,
                            wait: Any? = nil,
                            uploadSymbolMaps: Any? = nil) {
let urlArg = url.asRubyArgument(name: "url", type: nil)
let authTokenArg = authToken.asRubyArgument(name: "auth_token", type: nil)
let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
let orgSlugArg = orgSlug.asRubyArgument(name: "org_slug", type: nil)
let projectSlugArg = projectSlug.asRubyArgument(name: "project_slug", type: nil)
let pathArg = path.asRubyArgument(name: "path", type: nil)
let typeArg = type.asRubyArgument(name: "type", type: nil)
let noUnwindArg = RubyCommand.Argument(name: "no_unwind", value: noUnwind, type: nil)
let noDebugArg = RubyCommand.Argument(name: "no_debug", value: noDebug, type: nil)
let noSourcesArg = RubyCommand.Argument(name: "no_sources", value: noSources, type: nil)
let idsArg = ids.asRubyArgument(name: "ids", type: nil)
let requireAllArg = RubyCommand.Argument(name: "require_all", value: requireAll, type: nil)
let symbolMapsArg = symbolMaps.asRubyArgument(name: "symbol_maps", type: nil)
let derivedDataArg = RubyCommand.Argument(name: "derived_data", value: derivedData, type: nil)
let noZipsArg = RubyCommand.Argument(name: "no_zips", value: noZips, type: nil)
let infoPlistArg = infoPlist.asRubyArgument(name: "info_plist", type: nil)
let noReprocessingArg = RubyCommand.Argument(name: "no_reprocessing", value: noReprocessing, type: nil)
let forceForegroundArg = RubyCommand.Argument(name: "force_foreground", value: forceForeground, type: nil)
let includeSourcesArg = RubyCommand.Argument(name: "include_sources", value: includeSources, type: nil)
let waitArg = RubyCommand.Argument(name: "wait", value: wait, type: nil)
let uploadSymbolMapsArg = RubyCommand.Argument(name: "upload_symbol_maps", value: uploadSymbolMaps, type: nil)
let array: [RubyCommand.Argument?] = [urlArg,
authTokenArg,
apiKeyArg,
orgSlugArg,
projectSlugArg,
pathArg,
typeArg,
noUnwindArg,
noDebugArg,
noSourcesArg,
idsArg,
requireAllArg,
symbolMapsArg,
derivedDataArg,
noZipsArg,
infoPlistArg,
noReprocessingArg,
forceForegroundArg,
includeSourcesArg,
waitArg,
uploadSymbolMapsArg]
let args: [RubyCommand.Argument] = array
.filter { $0?.value != nil }
.compactMap { $0 }
let command = RubyCommand(commandID: "", methodName: "sentry_upload_dif", className: nil, args: args)
  _ = runner.executeCommand(command)
}

/**
 Upload dSYM symbolication files to Sentry

 - parameters:
   - url: Url for Sentry
   - authToken: Authentication token for Sentry
   - apiKey: API key for Sentry
   - orgSlug: Organization slug for Sentry project
   - projectSlug: Project slug for Sentry
   - dsymPath: Path to your symbols file. For iOS and Mac provide path to app.dSYM.zip
   - dsymPaths: Path to an array of your symbols file. For iOS and Mac provide path to app.dSYM.zip
   - symbolMaps: Optional path to bcsymbolmap files which are used to resolve hidden symbols in the actual dsym files. This requires the dsymutil tool to be available
   - infoPlist: Optional path to Info.plist to add version information when uploading debug symbols

 This action allows you to upload symbolication files to Sentry. It's extra useful if you use it to download the latest dSYM files from Apple when you use Bitcode
*/
public func sentryUploadDsym(url: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             authToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             apiKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             orgSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             projectSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             dsymPath: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             dsymPaths: Any? = nil,
                             symbolMaps: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             infoPlist: OptionalConfigValue<String?> = .fastlaneDefault(nil)) {
let urlArg = url.asRubyArgument(name: "url", type: nil)
let authTokenArg = authToken.asRubyArgument(name: "auth_token", type: nil)
let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
let orgSlugArg = orgSlug.asRubyArgument(name: "org_slug", type: nil)
let projectSlugArg = projectSlug.asRubyArgument(name: "project_slug", type: nil)
let dsymPathArg = dsymPath.asRubyArgument(name: "dsym_path", type: nil)
let dsymPathsArg = RubyCommand.Argument(name: "dsym_paths", value: dsymPaths, type: nil)
let symbolMapsArg = symbolMaps.asRubyArgument(name: "symbol_maps", type: nil)
let infoPlistArg = infoPlist.asRubyArgument(name: "info_plist", type: nil)
let array: [RubyCommand.Argument?] = [urlArg,
authTokenArg,
apiKeyArg,
orgSlugArg,
projectSlugArg,
dsymPathArg,
dsymPathsArg,
symbolMapsArg,
infoPlistArg]
let args: [RubyCommand.Argument] = array
.filter { $0?.value != nil }
.compactMap { $0 }
let command = RubyCommand(commandID: "", methodName: "sentry_upload_dsym", className: nil, args: args)
  _ = runner.executeCommand(command)
}

/**
 Upload files to a release of a project on Sentry

 - parameters:
   - url: Url for Sentry
   - authToken: Authentication token for Sentry
   - apiKey: API key for Sentry
   - orgSlug: Organization slug for Sentry project
   - projectSlug: Project slug for Sentry
   - version: Release version on Sentry
   - appIdentifier: App Bundle Identifier, prepended to version
   - build: Release build on Sentry
   - dist: Distribution in release
   - file: Path to the file to upload
   - fileUrl: Optional URL we should associate with the file

 This action allows you to upload files to a release of a project on Sentry. See https://docs.sentry.io/learn/cli/releases/#upload-files for more information.
*/
public func sentryUploadFile(url: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             authToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             apiKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             orgSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             projectSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             version: String,
                             appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             build: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             dist: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                             file: String,
                             fileUrl: OptionalConfigValue<String?> = .fastlaneDefault(nil)) {
let urlArg = url.asRubyArgument(name: "url", type: nil)
let authTokenArg = authToken.asRubyArgument(name: "auth_token", type: nil)
let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
let orgSlugArg = orgSlug.asRubyArgument(name: "org_slug", type: nil)
let projectSlugArg = projectSlug.asRubyArgument(name: "project_slug", type: nil)
let versionArg = RubyCommand.Argument(name: "version", value: version, type: nil)
let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
let buildArg = build.asRubyArgument(name: "build", type: nil)
let distArg = dist.asRubyArgument(name: "dist", type: nil)
let fileArg = RubyCommand.Argument(name: "file", value: file, type: nil)
let fileUrlArg = fileUrl.asRubyArgument(name: "file_url", type: nil)
let array: [RubyCommand.Argument?] = [urlArg,
authTokenArg,
apiKeyArg,
orgSlugArg,
projectSlugArg,
versionArg,
appIdentifierArg,
buildArg,
distArg,
fileArg,
fileUrlArg]
let args: [RubyCommand.Argument] = array
.filter { $0?.value != nil }
.compactMap { $0 }
let command = RubyCommand(commandID: "", methodName: "sentry_upload_file", className: nil, args: args)
  _ = runner.executeCommand(command)
}

/**
 Upload mapping to a project on Sentry

 - parameters:
   - url: Url for Sentry
   - authToken: Authentication token for Sentry
   - apiKey: API key for Sentry
   - orgSlug: Organization slug for Sentry project
   - projectSlug: Project slug for Sentry
   - mappingPath: Path to your proguard mapping.txt file
   - androidManifestPath: Path to your merged AndroidManifest file. This is usually found under `app/build/intermediates/manifests/full`

 This action allows you to upload the proguard mapping file to Sentry. See https://docs.sentry.io/product/cli/dif/#proguard-mapping-upload for more information.
*/
public func sentryUploadProguard(url: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                 authToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                 apiKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                 orgSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                 projectSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                 mappingPath: String,
                                 androidManifestPath: String) {
let urlArg = url.asRubyArgument(name: "url", type: nil)
let authTokenArg = authToken.asRubyArgument(name: "auth_token", type: nil)
let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
let orgSlugArg = orgSlug.asRubyArgument(name: "org_slug", type: nil)
let projectSlugArg = projectSlug.asRubyArgument(name: "project_slug", type: nil)
let mappingPathArg = RubyCommand.Argument(name: "mapping_path", value: mappingPath, type: nil)
let androidManifestPathArg = RubyCommand.Argument(name: "android_manifest_path", value: androidManifestPath, type: nil)
let array: [RubyCommand.Argument?] = [urlArg,
authTokenArg,
apiKeyArg,
orgSlugArg,
projectSlugArg,
mappingPathArg,
androidManifestPathArg]
let args: [RubyCommand.Argument] = array
.filter { $0?.value != nil }
.compactMap { $0 }
let command = RubyCommand(commandID: "", methodName: "sentry_upload_proguard", className: nil, args: args)
  _ = runner.executeCommand(command)
}

/**
 Upload a sourcemap to a release of a project on Sentry

 - parameters:
   - url: Url for Sentry
   - authToken: Authentication token for Sentry
   - apiKey: API key for Sentry
   - orgSlug: Organization slug for Sentry project
   - projectSlug: Project slug for Sentry
   - version: Release version on Sentry
   - appIdentifier: App Bundle Identifier, prepended to version
   - build: Release build on Sentry
   - dist: Distribution in release
   - sourcemap: Path to the sourcemap to upload
   - rewrite: Rewrite the sourcemaps before upload
   - stripPrefix: Chop-off a prefix from uploaded files
   - stripCommonPrefix: Automatically guess what the common prefix is and chop that one off
   - urlPrefix: Sets a URL prefix in front of all files
   - ignore: Ignores all files and folders matching the given glob or array of globs
   - ignoreFile: Ignore all files and folders specified in the given ignore file, e.g. .gitignore

 This action allows you to upload a sourcemap to a release of a project on Sentry. See https://docs.sentry.io/learn/cli/releases/#upload-sourcemaps for more information.
*/
public func sentryUploadSourcemap(url: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  authToken: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  apiKey: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  orgSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  projectSlug: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  version: String,
                                  appIdentifier: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  build: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  dist: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  sourcemap: String,
                                  rewrite: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  stripPrefix: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  stripCommonPrefix: OptionalConfigValue<Bool> = .fastlaneDefault(false),
                                  urlPrefix: OptionalConfigValue<String?> = .fastlaneDefault(nil),
                                  ignore: Any? = nil,
                                  ignoreFile: OptionalConfigValue<String?> = .fastlaneDefault(nil)) {
let urlArg = url.asRubyArgument(name: "url", type: nil)
let authTokenArg = authToken.asRubyArgument(name: "auth_token", type: nil)
let apiKeyArg = apiKey.asRubyArgument(name: "api_key", type: nil)
let orgSlugArg = orgSlug.asRubyArgument(name: "org_slug", type: nil)
let projectSlugArg = projectSlug.asRubyArgument(name: "project_slug", type: nil)
let versionArg = RubyCommand.Argument(name: "version", value: version, type: nil)
let appIdentifierArg = appIdentifier.asRubyArgument(name: "app_identifier", type: nil)
let buildArg = build.asRubyArgument(name: "build", type: nil)
let distArg = dist.asRubyArgument(name: "dist", type: nil)
let sourcemapArg = RubyCommand.Argument(name: "sourcemap", value: sourcemap, type: nil)
let rewriteArg = rewrite.asRubyArgument(name: "rewrite", type: nil)
let stripPrefixArg = stripPrefix.asRubyArgument(name: "strip_prefix", type: nil)
let stripCommonPrefixArg = stripCommonPrefix.asRubyArgument(name: "strip_common_prefix", type: nil)
let urlPrefixArg = urlPrefix.asRubyArgument(name: "url_prefix", type: nil)
let ignoreArg = RubyCommand.Argument(name: "ignore", value: ignore, type: nil)
let ignoreFileArg = ignoreFile.asRubyArgument(name: "ignore_file", type: nil)
let array: [RubyCommand.Argument?] = [urlArg,
authTokenArg,
apiKeyArg,
orgSlugArg,
projectSlugArg,
versionArg,
appIdentifierArg,
buildArg,
distArg,
sourcemapArg,
rewriteArg,
stripPrefixArg,
stripCommonPrefixArg,
urlPrefixArg,
ignoreArg,
ignoreFileArg]
let args: [RubyCommand.Argument] = array
.filter { $0?.value != nil }
.compactMap { $0 }
let command = RubyCommand(commandID: "", methodName: "sentry_upload_sourcemap", className: nil, args: args)
  _ = runner.executeCommand(command)
}
