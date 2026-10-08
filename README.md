# To Do Desk

Microsoft To Do in your Mac menu bar. Click the checkmark icon to capture a task, check something off, or switch lists without keeping a browser window open.

To Do Desk is a small independent AppKit + WebKit app that displays [Microsoft's official To Do website](https://to-do.office.com/tasks/). It uses the website's normal Microsoft sign-in. No custom Microsoft app registration, API key, or separate task database is needed.

## Features

- A checkmark icon in the menu bar, with a compact dropdown panel.
- Microsoft's own task lists, task entry, and completion controls.
- A pin button to keep the panel open when switching apps.
- Back, refresh, and open-in-browser controls.
- Right-click the menu bar icon for options and Quit.
- A persistent WebKit session, separate from your regular browser.

## Requirements

macOS 14 or later, internet access, and a Microsoft account with access to To Do. Existing Microsoft account and organization policies still apply.

The downloadable build targets Apple silicon. The app has been checked on macOS 26.5.1 with Xcode 26.5. macOS 14–26.4 and Intel Macs have not been runtime-tested.

## Install

Download and unzip the Apple silicon release, then move **To Do Desk.app** to your Applications folder and open it. Click the checkmark in the menu bar and sign in to Microsoft.

**The first release is ad-hoc signed and is not Apple-notarized.** A downloaded build may be blocked by Gatekeeper. Building from source is the supported alternative; this project does not ask you to disable macOS security protections.

To launch it automatically, add To Do Desk in **System Settings → General → Login Items → Open at Login**. Installing the app does not change login items or replace Microsoft's native app.

## Build from source

Install Xcode or the Xcode Command Line Tools. No package manager or third-party library is needed.

```sh
./build.sh
```

The app is written to `dist/To Do Desk.app`. To create a ZIP with a SHA-256 checksum:

```sh
./package.sh
```

Optional build settings:

```sh
# Compile for Intel; this is not a runtime-tested release target.
ARCH=x86_64 ./build.sh

# Use your own bundle identifier and Developer ID signing identity.
BUNDLE_ID=com.example.tododesk \
SIGNING_IDENTITY='Developer ID Application: Your Name (TEAMID)' \
./package.sh
```

A Developer ID signature alone does not notarize the app. Public notarized distribution also requires Apple's notarization and stapling steps, performed with the publisher's own credentials.

## Privacy

The wrapper contains no analytics, custom credential collection, task export, injected JavaScript, or native JavaScript bridge. Microsoft provides the web interface and handles its sign-in and service requests. WebKit stores the website's cookies and local web data on the Mac. See [PRIVACY.md](PRIVACY.md).

## Limitations

This is a menu bar web panel, not a WidgetKit desktop widget or a native task client. Its task features, availability, and layout depend on Microsoft's website. Organization policies may restrict embedded-browser sign-in. No guaranteed offline workflow or native notifications are implemented.

The panel is fixed at 440 points wide and up to 650 points high. The pin keeps it open; it does not make it a desktop widget. Microsoft may change its website in ways that affect the panel.

## Validation

The local menu bar version was checked for launch, popover layout, pin toggling, persisted sign-in across restart, and loading real task lists with add/completion controls. Existing tasks were not modified during testing. The public build is compiled and its code signature is verified; broad compatibility and end-to-end task mutation tests remain outstanding.

## License and attribution

Copyright © 2026 Milosz Durzynski. The wrapper's source code and project documentation are released under the [MIT License](LICENSE).

Microsoft To Do, Microsoft services, web content, and Microsoft trademarks are not included in this license. This project is not affiliated with, endorsed by, or sponsored by Microsoft. System icons are rendered using Apple's SF Symbols APIs.
