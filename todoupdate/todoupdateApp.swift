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
            .onAppear() {
                appDelegate.scheduleBackgroundProcessing()
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                model.save()
                
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let isRegister = BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.tien0246.todoupdate.refresh", using: nil) { task in
            guard let task = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleBackgroundProcessing(task: task)
        }
        
        print(isRegister)

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
        BGTaskScheduler.shared.cancelAllTaskRequests()
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

    func scheduleBackgroundProcessing() {
        let request = BGAppRefreshTaskRequest(identifier: "com.tien0246.todoupdate.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60)

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
