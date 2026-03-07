//
//  ShareViewController.swift
//  ShareExtension
//

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    let titleLabel = UILabel()
    let domainLabel = UILabel()
    let saveButton = UIButton(type: .system)
    let cancelButton = UIButton(type: .system)

    let appGroupId = "group.com.walkinggoblins.archive"

    var sharedURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        preferredContentSize = CGSize(width: 0, height: 180)

        setupUI()
        fetchSharedURL()
    }

    // MARK: UI

    func setupUI() {

        view.backgroundColor = .systemGroupedBackground

        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center

        domainLabel.font = .systemFont(ofSize: 15)
        domainLabel.textColor = .secondaryLabel
        domainLabel.textAlignment = .center

        saveButton.backgroundColor = UIColor(red: 1.0, green: 0.45, blue: 0.0, alpha: 1.0)
        saveButton.tintColor = .white
        saveButton.layer.cornerRadius = 12
        saveButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 40, bottom: 12, right: 40)

        cancelButton.setTitleColor(.secondaryLabel, for: .normal)

        let mainStack = UIStackView(arrangedSubviews: [
            domainLabel,
            titleLabel,
            saveButton,
            cancelButton
        ])

        mainStack.axis = .vertical
        mainStack.spacing = 14
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
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

                            self.domainLabel.text = url.host ?? "Link"

                            self.urlLabel.text = url.absoluteString
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

        UIView.animate(withDuration: 0.2) {
            self.saveButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    // MARK: Cancel

    @objc func cancelTapped() {

        extensionContext?.completeRequest(returningItems: nil)
    }

}