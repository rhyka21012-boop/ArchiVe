import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

  let appGroupId = "group.com.walkinggoblins.archive"
  let channelName = "share_channel"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { (call, result) in

      if call.method == "getSharedUrl" {

        let defaults = UserDefaults(suiteName: self.appGroupId)
        let url = defaults?.string(forKey: "shared_url")

        if let sharedUrl = url {

          result(sharedUrl)

          // 取得後は削除（次回起動時に残らないように）
          defaults?.removeObject(forKey: "shared_url")

        } else {

          result(nil)

        }

      } else {

        result(FlutterMethodNotImplemented)

      }

    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
