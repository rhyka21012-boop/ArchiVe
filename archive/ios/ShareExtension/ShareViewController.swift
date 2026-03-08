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

        preferredContentSize = CGSize(width: 0, height: 220)

        setupUI()
        fetchSharedURL()
    }

    // MARK: UI

    func setupUI() {

        view.backgroundColor = .systemBackground

        // ドラッグバー
        handleBar.backgroundColor = .systemGray4
        handleBar.layer.cornerRadius = 2.5
        handleBar.translatesAutoresizingMaskIntoConstraints = false

        // タイトル
        titleLabel.text = "保存しますか？"
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center

        // 保存ボタン
        saveButton.setTitle("保存", for: .normal)
        saveButton.backgroundColor = UIColor(red: 0.10, green: 0.65, blue: 0.70, alpha: 1.0)
        saveButton.tintColor = .white
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        // キャンセルボタン
        cancelButton.setTitle("キャンセル", for: .normal)
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

        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else { return }

        guard let attachments = extensionItem.attachments else { return }

        for itemProvider in attachments {

            if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {

                itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in

                    DispatchQueue.main.async {

                        if let url = item as? URL {
                            self.sharedURL = url
                        }

                    }
                }

                break
            }
        }
    }

    // MARK: Save

    @objc func saveTapped() {

        guard let url = sharedURL else { return }

        saveURL(url.absoluteString)
    }

    func saveURL(_ url: String) {

        let defaults = UserDefaults(suiteName: appGroupId)

        var urls = defaults?.stringArray(forKey: "shared_url") ?? []
        urls.append(url)

        defaults?.set(urls, forKey: "shared_url")
        defaults?.synchronize()

        showSavedState()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.extensionContext?.completeRequest(returningItems: nil)
        }
    }

    func showSavedState() {

        saveButton.setTitle("Saved ✓", for: .normal)
        saveButton.backgroundColor = .systemGreen
        saveButton.isEnabled = false
    }

    // MARK: Cancel

    @objc func cancelTapped() {

        extensionContext?.completeRequest(returningItems: nil)
    }

}