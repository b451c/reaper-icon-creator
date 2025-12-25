import SwiftUI

@main
struct ReaperIconCreatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) { }

            CommandGroup(after: .appInfo) {
                Button("Check for REAPER Installation") {
                    checkReaperInstallation()
                }
            }
        }
    }

    private func checkReaperInstallation() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let reaperPath = home.appendingPathComponent("Library/Application Support/REAPER")

        let alert = NSAlert()
        alert.alertStyle = .informational

        if FileManager.default.fileExists(atPath: reaperPath.path) {
            alert.messageText = "REAPER Found"
            alert.informativeText = "REAPER installation detected at:\n\(reaperPath.path)"
        } else {
            alert.messageText = "REAPER Not Found"
            alert.informativeText = "No REAPER installation found at the expected location.\n\nExpected: \(reaperPath.path)"
        }

        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
