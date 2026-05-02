import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let appGroupID      = "group.com.walkinggoblins.archive"
    private let pendingShareKey = "archive_pending_share"
    private let allListsKey     = "archive_all_lists"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "com.walkinggoblins.archive/app_groups",
                binaryMessenger: controller.binaryMessenger
            )
            channel.setMethodCallHandler { [weak self] call, result in
                self?.handleMethodCall(call, result: result)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            result(FlutterError(code: "APP_GROUPS_UNAVAILABLE", message: "App Groups が利用できません", details: nil))
            return
        }

        switch call.method {

        // pending share データを取得
        case "getPendingShare":
            result(defaults.string(forKey: pendingShareKey))

        // pending share データを削除
        case "clearPendingShare":
            defaults.removeObject(forKey: pendingShareKey)
            defaults.synchronize()
            result(nil)

        // Extension が読み取れるようにリスト一覧を App Groups に書き込む
        case "syncAllLists":
            guard let lists = call.arguments as? [String],
                  let data = try? JSONSerialization.data(withJSONObject: lists),
                  let jsonString = String(data: data, encoding: .utf8)
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "引数が不正です", details: nil))
                return
            }
            defaults.set(jsonString, forKey: allListsKey)
            defaults.synchronize()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
