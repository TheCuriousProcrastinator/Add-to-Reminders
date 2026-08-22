//
//  QuickAddPanelController.swift
//  QuickAdd
//

import AppKit
import SwiftUI

final class QuickAddPanelController {
    private let panel: NSPanel
    private var didBecomeKeyObserver: NSObjectProtocol?

    init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 180),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "QuickAdd"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: makeContentView())
    }

    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            panel.contentView = NSHostingView(rootView: makeContentView())
            centerOnCurrentScreen()
            observePanelBecomingKey()
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
        }
    }

    private func makeContentView() -> ContentView {
        ContentView(
            onSubmit: { [weak self] in self?.hide() },
            onEscape: { [weak self] in self?.hide() }
        )
    }

    private func hide() {
        panel.orderOut(nil)
    }

    private func observePanelBecomingKey() {
        if let didBecomeKeyObserver {
            NotificationCenter.default.removeObserver(didBecomeKeyObserver)
        }

        didBecomeKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                NotificationCenter.default.post(
                    name: .quickAddTitleFocusRequested,
                    object: self.panel
                )
            }
        }
    }

    private func centerOnCurrentScreen() {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main

        guard let visibleFrame = screen?.visibleFrame else { return }
        let origin = NSPoint(
            x: visibleFrame.midX - panel.frame.width / 2,
            y: visibleFrame.midY - panel.frame.height / 2
        )
        panel.setFrameOrigin(origin)
    }
}
