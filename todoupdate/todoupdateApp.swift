//
//  todoupdateApp.swift
//  todoupdate
//
//  Created by Tiến Đoàn on 04/05/2024.
//

import SwiftUI
import UIKit
import BackgroundTasks

@main
struct todoupdateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var model = ViewModel()

    @Environment(\.scenePhase) var scenePhase: ScenePhase

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(viewModel: model)
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                model.save()
            }
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.tien0246.todoupdate.refreshApp", using: nil) { task in
            self.handleBackgroundProcessing(task: task as! BGAppRefreshTask)
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Permission to notify has been granted.")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }

        scheduleBackgroundProcessing()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        self.scheduleBackgroundProcessing()
    }

    private func handleBackgroundProcessing(task: BGAppRefreshTask) {
        scheduleBackgroundProcessing()

        let viewModel = ViewModel()
        
        viewModel.refreshApp { updatedApps in
            updatedApps.forEach { appInfo in
                self.scheduleLocalNotification(for: appInfo)
            }
            task.setTaskCompleted(success: true)
        }
    }

    private func scheduleBackgroundProcessing() {
        let request = BGAppRefreshTaskRequest(identifier: "com.tien0246.todoupdate.refreshApp")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3 * 3600)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    private func scheduleLocalNotification(for appInfo: AppInfo) {
        let content = UNMutableNotificationContent()
        content.title = "\(appInfo.name)"
        content.body = "\(appInfo.name) has a new version \(appInfo.currentVersion)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification for \(appInfo.name): \(error)")
            }
        }
    }
}
