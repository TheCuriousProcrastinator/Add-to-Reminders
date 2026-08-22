//
//  QuickAddApp.swift
//  QuickAdd
//
//  Created by Alex on 8/22/26.
//

import AppKit
import Carbon.HIToolbox
import SwiftUI

@main
struct QuickAddApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
        .defaultLaunchBehavior(.suppressed)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: QuickAddPanelController?
    private var globalHotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let panelController = QuickAddPanelController()
        self.panelController = panelController

        globalHotKey = GlobalHotKey(
            keyCode: UInt32(kVK_ANSI_A),
            modifiers: UInt32(controlKey | cmdKey)
        ) { [weak panelController] in
            panelController?.toggle()
        }
    }
}
