//
//  ShareViewController.swift
//  ShareExtension
//

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    let iconView = UIImageView()
    let titleLabel = UILabel()
    let domainLabel = UILabel()
    let urlLabel = UILabel()
    let saveButton = UIButton(type: .system)
    let cancelButton = UIButton(type: .system)

    let cardView = UIView()

    let appGroupId = "group.com.walkinggoblins.archive"

    var sharedURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fetchSharedURL()
    }

    // MARK: UI

    func setupUI() {

        view.backgroundColor = .systemGroupedBackground

        iconView.image = UIImage(systemName: "bookmark.circle.fill")
        iconView.tintColor = UIColor(red: 1.0, green: 0.45, blue: 0.0, alpha: 1.0)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = NSLocalizedString("save_title", comment: "")
        titleLabel.font = .boldSystemFont(ofSize: 22)
        titleLabel.textAlignment = .center

        domainLabel.font = .boldSystemFont(ofSize: 16)
        domainLabel.textColor = .label
        domainLabel.textAlignment = .center

        urlLabel.font = .systemFont(ofSize: 14)
        urlLabel.textColor = .secondaryLabel
        urlLabel.numberOfLines = 2
        urlLabel.textAlignment = .center

        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 14
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        let cardStack = UIStackView(arrangedSubviews: [
            domainLabel,
            urlLabel
        ])

        cardStack.axis = .vertical
        cardStack.spacing = 6
        cardStack.alignment = .center
        cardStack.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(cardStack)

        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            cardStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            cardStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16)
        ])

        saveButton.setTitle(
            NSLocalizedString("save_button", comment: ""),
            for: .normal
        )
        saveButton.backgroundColor = UIColor(red: 1.0, green: 0.45, blue: 0.0, alpha: 1.0)
        saveButton.tintColor = .white
        saveButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        saveButton.layer.cornerRadius = 12
        saveButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 40, bottom: 14, right: 40)

        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        cancelButton.setTitle(
            NSLocalizedString("cancel_button", comment: ""),
            for: .normal
        )
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16)

        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let mainStack = UIStackView(arrangedSubviews: [
            iconView,
            titleLabel,
            cardView,
            saveButton,
            cancelButton
        ])

        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStack)

        NSLayoutConstraint.activate([

            iconView.heightAnchor.constraint(equalToConstant: 70),
            iconView.widthAnchor.constraint(equalToConstant: 70),

            cardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),

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

        saveButton.setTitle(
            NSLocalizedString("saved", comment: ""),
            for: .normal
        )
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
