# Kid Profiles (personal iPad app)

One iPad, a parent PIN, and a rule set per child: allowed apps, a daily time
limit, and content filters. Built on Apple's Screen Time API
(FamilyControls, ManagedSettings, DeviceActivity). Requires iPadOS 17.4+.

**Status: starter code, written without access to Xcode, so it has not been
compiled or run. Expect to fix a few small build errors on first open.**

## What you need
- A Mac with Xcode 15.3 or later
- A paid Apple Developer account (the Family Controls capability is not offered to free accounts)
- Your iPad connected to the Mac (the Screen Time API does not work in the simulator)

## Setup
1. Replace `com.example` with your own identifier (e.g. `com.yourname`) in
   `project.yml`, and `appGroupID` in `Shared/Storage.swift` to match.
2. In Terminal, in this folder: `brew install xcodegen && xcodegen`
3. Open `KidProfiles.xcodeproj`. For BOTH targets (KidProfiles and KidMonitor):
   Signing & Capabilities → choose your Team. Xcode registers the
   Family Controls (Development) capability and the App Group for you.
4. Select your iPad as the run destination and press Run.
5. On the iPad: create the parent PIN, allow Screen Time access, add a profile
   per child, tap **Start** to hand the iPad over.

No XcodeGen? Create an iOS App project named KidProfiles, add a
"Device Activity Monitor Extension" target named KidMonitor, add the
Family Controls and App Groups capabilities to both, then drag `App/` + `Shared/`
into the app target and `Monitor/` + `Shared/` into the extension target
(replace the extension's generated Swift file).

## How it works
- **Parent mode**: all restrictions cleared.
- **Start a kid profile**: every app is shielded except that child's allowed
  list; content filters are applied; a background monitor counts time spent in
  the allowed apps and shields everything when the daily limit is reached.
- **Switching** needs the parent PIN. The parent area locks whenever the app
  leaves the screen. Used minutes are kept per child per day and reset at midnight.

## Do these too, or kids can get around it
- Set an Apple **Screen Time passcode** (Settings → Screen Time → Lock Screen
  Time Settings), different from the iPad passcode. Otherwise a child can
  switch off this app's access in Settings → Screen Time.
- Don't share the parent PIN or Screen Time passcode.

## Things to check on first run
- **Is Kid Profiles itself blocked while a kid profile is active?** If so, edit
  each profile and add Kid Profiles to its allowed apps. If you ever get locked
  out: Settings → Screen Time → Apps with Screen Time Access → turn Kid Profiles off.
- Keep each child's allowed list under about 50 apps (an Apple limit on shields).
- The midnight reset relies on the extension restarting its own monitoring;
  test it once by leaving a profile active overnight.

## Limits you can't code around
Apps stay signed in to the same accounts for everyone, so history, game saves
and photos are shared between children. iPadOS has no true separate users.
