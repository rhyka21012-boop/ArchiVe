//
//  ShareViewController.swift
//  ShareExtension
//

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    let titleLabel = UILabel()
    let saveButton = UIButton(type: .system)
    let cancelButton = UIButton(type: .system)
    let handleBar = UIView()

    let appGroupId = "group.com.walkinggoblins.archive"

    var sharedURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        debugLog("ShareExtension opened") // DEBUG

        preferredContentSize = CGSize(width: 0, height: 220)

        if let sheet = self.presentationController as? UISheetPresentationController {
            sheet.detents = [.custom(resolver: { _ in 220 })]
        }

        setupUI()
        fetchSharedURL()
    }

    // MARK: DEBUG LOG

    func debugLog(_ message: String) {

        let defaults = UserDefaults(suiteName: appGroupId)

        var logs = defaults?.stringArray(forKey: "debug_logs") ?? []

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"

        let time = formatter.string(from: Date())

        logs.append("[\(time)] \(message)")

        defaults?.set(logs, forKey: "debug_logs")
    }

    // MARK: UI

    func setupUI() {

        view.backgroundColor = .systemBackground

        // ドラッグバー
        handleBar.backgroundColor = .systemGray4
        handleBar.layer.cornerRadius = 2.5
        handleBar.translatesAutoresizingMaskIntoConstraints = false

        // タイトル
        titleLabel.text = NSLocalizedString("save_title", comment: "")
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center

        // 保存ボタン
        saveButton.setTitle(NSLocalizedString("save_button", comment: ""), for: .normal)
        saveButton.backgroundColor = UIColor(red: 0.984, green: 0.549, blue: 0.0, alpha: 1.0)
        saveButton.tintColor = .white
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        // キャンセルボタン
        cancelButton.setTitle(NSLocalizedString("cancel_button", comment: ""), for: .normal)
        cancelButton.backgroundColor = .systemGray5
        cancelButton.tintColor = .label
        cancelButton.layer.cornerRadius = 12
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        // ボタンStack
        let buttonStack = UIStackView(arrangedSubviews: [
            cancelButton,
            saveButton
        ])

        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually

        // メインStack
        let mainStack = UIStackView(arrangedSubviews: [
            titleLabel,
            buttonStack
        ])

        mainStack.axis = .vertical
        mainStack.spacing = 28
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(handleBar)
        view.addSubview(mainStack)

        handleBar.widthAnchor.constraint(equalToConstant: 40).isActive = true
        handleBar.heightAnchor.constraint(equalToConstant: 5).isActive = true
        handleBar.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        handleBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 8).isActive = true

        NSLayoutConstraint.activate([

            mainStack.topAnchor.constraint(equalTo: handleBar.bottomAnchor, constant: 30),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)

        ])

        saveButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    // MARK: Fetch URL

    func fetchSharedURL() {

        debugLog("fetchSharedURL called") // DEBUG

        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            debugLog("No extension item") // DEBUG
            return
        }

        guard let attachments = extensionItem.attachments else { 
            debugLog("No attachments") // DEBUG
            return 
        }

        for itemProvider in attachments {

            if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {

                debugLog("URL type detected") // DEBUG

                itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in

                    DispatchQueue.main.async {

                        if let url = item as? URL {
                            self.sharedURL = url
                            self.debugLog("URL received: \(url.absoluteString)") // DEBUG
                        } else {
                            self.debugLog("URL cast failed") // DEBUG
                        }

                    }
                }

                break
            }
        }
    }

    // MARK: Save

    @objc func saveTapped() {

        debugLog("Save button tapped") // DEBUG

        guard let url = sharedURL else { 
            debugLog("sharedURL is nil") // DEBUG
            return 
        }

        saveURL(url.absoluteString)
    }

    func saveURL(_ url: String) {

    debugLog("saveURL called: \(url)")

    let defaults = UserDefaults(suiteName: appGroupId)

    var urls = defaults?.stringArray(forKey: "shared_url") ?? []
    urls.append(url)

    defaults?.set(urls, forKey: "shared_url")

    debugLog("saved urls count: \(urls.count)")
    debugLog("AppGroup write complete")

    showSavedState()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        self.debugLog("Extension closing")
        self.extensionContext?.completeRequest(returningItems: nil)
    }
}

    func showSavedState() {

        saveButton.setTitle(NSLocalizedString("saved", comment: ""), for: .normal)
        saveButton.backgroundColor = .systemGreen
        saveButton.isEnabled = false
    }

    // MARK: Cancel

    @objc func cancelTapped() {

        debugLog("Cancel tapped") // DEBUG

        extensionContext?.completeRequest(returningItems: nil)
    }

}