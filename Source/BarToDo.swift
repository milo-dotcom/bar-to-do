// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Milosz Durzynski

import Cocoa
import WebKit

private let homeURL = URL(string: "https://to-do.office.com/tasks/")!

final class BrowserWindow: NSWindowController, WKNavigationDelegate, WKUIDelegate {
    let webView: WKWebView
    private let status = NSTextField(labelWithString: "Opening Microsoft To Do…")
    private let progress = NSProgressIndicator()
    private var popups: [BrowserWindow] = []
    private var loadingObservation: NSKeyValueObservation?
    private let isMain: Bool
    var onPinChanged: ((Bool) -> Void)?

    init(configuration: WKWebViewConfiguration = WKWebViewConfiguration(), popup: Bool = false) {
        isMain = !popup
        configuration.websiteDataStore = .default()
        webView = WKWebView(frame: .zero, configuration: configuration)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: popup ? 600 : 440, height: popup ? 740 : 650),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = popup ? "Microsoft sign-in" : "Bar To Do"
        window.minSize = NSSize(width: 360, height: 400)
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.center()
        if !popup { window.setFrameAutosaveName("ToDoDesk.MainWindow") }

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.setAccessibilityLabel("Microsoft To Do")
        webView.translatesAutoresizingMaskIntoConstraints = false

        let root = NSView()
        window.contentView = root
        let back = button("chevron.left", "Back", #selector(goBack))
        let refresh = button("arrow.clockwise", "Refresh", #selector(reload))
        let home = button("checklist", "Open task list", #selector(goHome))
        let browser = button("safari", "Open Microsoft To Do in your browser", #selector(openBrowser))
        let pin = button("pin", "Keep this panel open", #selector(togglePin))
        pin.setButtonType(.toggle)
        pin.state = UserDefaults.standard.bool(forKey: "keepOnTop") && !popup ? .on : .off

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let title = NSTextField(labelWithString: popup ? "Microsoft sign-in" : "MICROSOFT TO DO")
        title.font = .systemFont(ofSize: 10, weight: .semibold)
        title.textColor = .secondaryLabelColor
        let bar = NSStackView(views: popup ? [back, refresh, title, spacer, browser] : [home, back, refresh, title, spacer, pin, browser])
        bar.orientation = .horizontal
        bar.spacing = 7
        bar.translatesAutoresizingMaskIntoConstraints = false
        progress.style = .spinning
        progress.controlSize = .small
        progress.isDisplayedWhenStopped = false
        status.font = .systemFont(ofSize: 11)
        status.textColor = .secondaryLabelColor
        status.lineBreakMode = .byTruncatingTail
        status.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let footer = NSStackView(views: [progress, status])
        footer.orientation = .horizontal
        footer.spacing = 6
        footer.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(bar)
        root.addSubview(webView)
        root.addSubview(footer)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: root.topAnchor, constant: 5),
            bar.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10),
            bar.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -10),
            bar.heightAnchor.constraint(equalToConstant: 30),
            webView.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 5),
            webView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -5),
            footer.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            footer.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
            footer.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -5),
            footer.heightAnchor.constraint(equalToConstant: 17),
            progress.widthAnchor.constraint(equalToConstant: 14)
        ])
        loadingObservation = webView.observe(\.isLoading, options: [.new]) { [weak self] view, _ in
            guard let self else { return }
            if view.isLoading { self.progress.startAnimation(nil) }
            else { self.progress.stopAnimation(nil) }
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    private func button(_ symbol: String, _ label: String, _ action: Selector) -> NSButton {
        let button = NSButton(image: NSImage(systemSymbolName: symbol, accessibilityDescription: label)!, target: self, action: action)
        button.bezelStyle = .accessoryBarAction
        button.toolTip = label
        button.setAccessibilityLabel(label)
        return button
    }
    func start() { webView.load(URLRequest(url: homeURL)) }
    @objc private func goBack() { if webView.canGoBack { webView.goBack() } }
    @objc private func reload() { webView.reload() }
    @objc private func goHome() { start() }
    @objc private func openBrowser() { NSWorkspace.shared.open(homeURL) }
    @objc private func togglePin(_ sender: NSButton) {
        if let onPinChanged { onPinChanged(sender.state == .on) }
        else { applyPin(sender.state == .on) }
        UserDefaults.standard.set(sender.state == .on, forKey: "keepOnTop")
    }
    private func applyPin(_ enabled: Bool) {
        window?.level = enabled ? .floating : .normal
        window?.collectionBehavior = enabled ? [.canJoinAllSpaces, .fullScreenAuxiliary] : []
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        status.stringValue = "Loading…"
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        status.stringValue = webView.url?.host ?? "Microsoft To Do"
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { show(error) }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { show(error) }
    private func show(_ error: Error) {
        if (error as NSError).code == NSURLErrorCancelled { return }
        status.stringValue = "Couldn’t load. Refresh or use Open in Browser."
        status.toolTip = error.localizedDescription
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        status.stringValue = "Page stopped. Click Refresh to reopen it."
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        // No injected scripts, credential handling, or native bridge. Microsoft owns the sign-in flow.
        if url.scheme == "https" || url.absoluteString == "about:blank" { decisionHandler(.allow) }
        else { decisionHandler(.cancel) }
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let child = BrowserWindow(configuration: configuration, popup: true)
        popups.append(child)
        child.showWindow(nil)
        return child.webView
    }
    func webViewDidClose(_ webView: WKWebView) { if !isMain { close() } }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        guard let window = webView.window else { completionHandler(); return }
        let alert = NSAlert()
        alert.messageText = frame.request.url?.host ?? "Microsoft To Do"
        alert.informativeText = message
        alert.beginSheetModal(for: window) { _ in completionHandler() }
    }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        guard let window = webView.window else { completionHandler(false); return }
        let alert = NSAlert()
        alert.messageText = frame.request.url?.host ?? "Microsoft To Do"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: window) { completionHandler($0 == .alertFirstButtonReturn) }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindow: BrowserWindow?
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let statusMenu = NSMenu()
    private var hasOpened = false
    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        let appMenuItem = NSMenuItem()
        menu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Bar To Do", action: #selector(about), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Bar To Do", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Quit Bar To Do", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let edit = NSMenu(title: "Edit")
        for (title, action, key) in [("Undo", "undo:", "z"), ("Cut", "cut:", "x"), ("Copy", "copy:", "c"), ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
            edit.addItem(withTitle: title, action: Selector(action), keyEquivalent: key)
        }
        editItem.submenu = edit
        menu.addItem(editItem)
        let windowItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowItem.submenu = windowMenu
        menu.addItem(windowItem)
        NSApp.mainMenu = menu
        NSApp.windowsMenu = windowMenu
        mainWindow = BrowserWindow()
        let content = NSViewController()
        content.view = mainWindow!.window!.contentView!
        mainWindow!.window!.contentView = NSView()
        let availableHeight = NSScreen.main?.visibleFrame.height ?? 800
        popover.contentSize = NSSize(width: 440, height: min(650, availableHeight - 50))
        popover.contentViewController = content
        popover.behavior = UserDefaults.standard.bool(forKey: "keepOnTop") ? .applicationDefined : .transient
        mainWindow?.onPinChanged = { [weak self] pinned in
            self?.popover.behavior = pinned ? .applicationDefined : .transient
        }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.autosaveName = "ToDoDesk.StatusItem"
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "To Do")!
            image.isTemplate = true
            button.image = image
            button.toolTip = "Microsoft To Do — click to open, right-click for options"
            button.setAccessibilityLabel("To Do menu bar")
            button.target = self
            button.action = #selector(statusClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        for (title, selector) in [("Open To Do", #selector(showPanel)),
                                  ("Open in Browser", #selector(openBrowser)),
                                  ("About Bar To Do", #selector(about))] {
            let item = statusMenu.addItem(withTitle: title, action: selector, keyEquivalent: "")
            item.target = self
        }
        statusMenu.addItem(.separator())
        statusMenu.addItem(withTitle: "Quit Bar To Do", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        showPanel()
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPanel()
        return true
    }
    @objc private func statusClicked(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            popover.performClose(nil)
            statusItem.menu = statusMenu
            sender.performClick(nil)
            statusItem.menu = nil
        } else if popover.isShown {
            popover.performClose(nil)
        } else { showPanel() }
    }
    @objc private func showPanel() {
        guard let button = statusItem?.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        if !hasOpened {
            hasOpened = true
            mainWindow?.start()
        }
    }
    @objc private func openBrowser() { NSWorkspace.shared.open(homeURL) }
    @objc private func about() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Bar To Do", .applicationVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.2.0",
            .credits: NSAttributedString(string: "A menu bar panel for Microsoft’s official To Do website.\nIndependent local companion; not a Microsoft product.\nClick the checkmark in the menu bar to open your tasks.\nUse the pin button to keep the panel open while switching apps.")
        ])
    }
}
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
