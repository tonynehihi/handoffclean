# HandoffClean 1.0.0

Menu bar app: one-click clean of the macOS Handoff shared-pasteboard cache.

**What it cleans:** `~/Library/Group Containers/group.com.apple.coreservices.useractivityd/shared-pasteboard`
— where macOS stages Universal Clipboard payloads. Copying large files/folders can balloon this
folder to tens of GB (seen at 33.5 GB) and macOS never cleans it up. Deleting it is safe:
only staged clipboard data, the system rebuilds what it needs.

## Build (on a Mac, Xcode Command Line Tools required)

```bash
bash build.sh
```

Produces `HandoffClean.app`.

## First run

1. The app is unsigned (no paid Apple Developer account). If macOS blocks it with
   "damaged" after downloading, remove the quarantine flag:
   ```bash
   xattr -dr com.apple.quarantine HandoffClean.app
   ```
2. Optional: move `HandoffClean.app` to `/Applications`.
3. Open it — a trash icon appears in the menu bar.
4. On first launch it asks for **Full Disk Access** (required to see the pasteboard cache):
   System Settings → Privacy & Security → Full Disk Access → `+` → add `HandoffClean.app`
   → quit and reopen the app.

## Use

Click the menu bar icon → it shows the current cache size → **Clean Now**.
Tick sound confirms; the menu then shows how much was cleaned.

## Notes

- Apple Silicon only.
- English UI.
- v1.0.0 — tonynehihi.
