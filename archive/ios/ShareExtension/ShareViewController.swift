//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by 001 on 2026/03/03.
//

import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    let titleLabel = UILabel()
    let urlLabel = UILabel()
    let saveButton = UIButton(type: .system)

    let appGroupId = "group.com.walkinggoblins.archive"

    var sharedURL: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fetchSharedURL()
    }

    func setupUI() {

        view.backgroundColor = .systemBackground

        titleLabel.text = "Shared URL"
        titleLabel.font = .boldSystemFont(ofSize: 18)

        urlLabel.text = "Loading..."
        urlLabel.numberOfLines = 0
        urlLabel.textAlignment = .center

        saveButton.setTitle("Save", for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            urlLabel,
            saveButton
        ])

        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center

        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }

    func fetchSharedURL() {

        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else { return }

        guard let itemProvider = extensionItem.attachments?.first else { return }

        if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {

            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in

                DispatchQueue.main.async {

                    if let url = item as? URL {
                        self.sharedURL = url.absoluteString
                        self.urlLabel.text = url.absoluteString
                    }

                }

            }

        }

    }

    @objc func saveTapped() {

        guard let url = sharedURL else { return }

        saveURL(url)

    }

    func saveURL(_ url: String) {

        let defaults = UserDefaults(suiteName: appGroupId)

        defaults?.set(url, forKey: "shared_url")

        openMainApp()

    }

    func openMainApp() {

        let url = URL(string: "archive://share")!

        var responder = self as UIResponder?

        while responder != nil {

            if let application = responder as? UIApplication {

                application.performSelector(
                    onMainThread: Selector(("openURL:")),
                    with: url,
                    waitUntilDone: false
                )

                break

            }

            responder = responder?.next

        }

        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

}
