// HandoffClean.swift — v1.0.0
// Menu bar app: one-click clean of the macOS Handoff shared-pasteboard cache.
// Path: ~/Library/Group Containers/group.com.apple.coreservices.useractivityd/shared-pasteboard
// This cache can balloon to tens of GB when copying large files/folders
// (Universal Clipboard stages the payloads here and never cleans up).
// Requires Full Disk Access (one-time grant in System Settings).

import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var sizeItem: NSMenuItem!
    private var didPromptForAccess = false

    private var pasteboardURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
            "Library/Group Containers/group.com.apple.coreservices.useractivityd/shared-pasteboard")
    }

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "trash",
                                   accessibilityDescription: "HandoffClean")
        }
        let menu = NSMenu()
        menu.delegate = self
        sizeItem = NSMenuItem(title: "Measuring…", action: nil, keyEquivalent: "")
        sizeItem.isEnabled = false
        menu.addItem(sizeItem)
        menu.addItem(NSMenuItem.separator())
        let clean = NSMenuItem(title: "Clean Now", action: #selector(cleanNow),
                               keyEquivalent: "")
        clean.target = self
        menu.addItem(clean)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
        checkAccessOnLaunch()
    }

    // MARK: - Full Disk Access

    private func folderExists() -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: pasteboardURL.path,
                                              isDirectory: &isDir) && isDir.boolValue
    }

    private func hasAccess() -> Bool {
        guard folderExists() else { return true } // nothing to clean
        return (try? FileManager.default.contentsOfDirectory(atPath: pasteboardURL.path)) != nil
    }

    private func checkAccessOnLaunch() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            if self.hasAccess() {
                self.refreshSize()
            } else {
                DispatchQueue.main.async { self.promptForAccess() }
            }
        }
    }

    private func promptForAccess() {
        guard !didPromptForAccess else { return }
        didPromptForAccess = true
        let alert = NSAlert()
        alert.messageText = "Full Disk Access Required"
        alert.informativeText = """
            HandoffClean needs Full Disk Access to see and clean the Handoff pasteboard cache.

            1. Open System Settings → Privacy & Security → Full Disk Access
            2. Click + and add HandoffClean.app
            3. Quit and reopen HandoffClean
            """
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Size

    private func folderSize() -> Int64 {
        var total: Int64 = 0
        guard let enumerator = FileManager.default.enumerator(
            at: pasteboardURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey]) else { return 0 }
        for case let url as URL in enumerator {
            if let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
               values.isRegularFile == true {
                total += Int64(values.fileSize ?? 0)
            }
        }
        return total
    }

    private func formatted(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func refreshSize() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let accessible = self.hasAccess()
            let size: Int64 = accessible ? self.folderSize() : -1
            DispatchQueue.main.async {
                self.sizeItem.title = size < 0
                    ? "Needs Full Disk Access"
                    : "Pasteboard cache: \(self.formatted(size))"
            }
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshSize()
    }

    // MARK: - Clean

    @objc private func cleanNow() {
        guard folderExists() else {
            sizeItem.title = "Already clean ✓"
            NSSound.beep()
            return
        }
        guard hasAccess() else {
            didPromptForAccess = false
            promptForAccess()
            return
        }
        let before = folderSize()
        do {
            let items = try FileManager.default.contentsOfDirectory(at: pasteboardURL,
                                                                    includingPropertiesForKeys: nil)
            for item in items {
                try FileManager.default.removeItem(at: item)
            }
            sizeItem.title = before > 0 ? "Cleaned \(formatted(before)) ✓" : "Already clean ✓"
            NSSound.beep()
        } catch {
            sizeItem.title = "Failed: \(error.localizedDescription)"
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
