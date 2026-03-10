import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

  let appGroupId = "group.com.walkinggoblins.archive"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController

    /// Debug Log Channel
    let debugChannel = FlutterMethodChannel(
      name: "debug_log_channel",
      binaryMessenger: controller.binaryMessenger
    )

    debugChannel.setMethodCallHandler { (call, result) in

      let defaults = UserDefaults(suiteName: self.appGroupId)

      if call.method == "getLogs" {

        let logs = defaults?.stringArray(forKey: "debug_logs") ?? []
        result(logs)

      } else if call.method == "clearLogs" {

        defaults?.removeObject(forKey: "debug_logs")
        result(true)

      } else if call.method == "addLog" {

        if let args = call.arguments as? [String: Any],
           let message = args["message"] as? String {

          var logs = defaults?.stringArray(forKey: "debug_logs") ?? []
          logs.append(message)
          defaults?.set(logs, forKey: "debug_logs")
        }

        result(true)

      } else {

        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}