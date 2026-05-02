import UIKit
import SwiftUI
import UniformTypeIdentifiers

private let kAppGroupID      = "group.com.walkinggoblins.archive"
private let kPendingShareKey = "archive_pending_share"
private let kAllListsKey     = "archive_all_lists"

// MARK: - SwiftUI View

struct ShareView: View {
    let url: String

    @State private var titleText: String = ""
    @State private var selectedList: String = ""
    @State private var allLists: [String] = []
    @State private var isFetchingTitle: Bool = true

    var onSave: () -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("URL")) {
                    Text(url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }

                Section(header: Text("タイトル")) {
                    HStack {
                        TextField("タイトルを入力", text: $titleText)
                        if isFetchingTitle {
                            ProgressView()
                                .padding(.leading, 4)
                        }
                    }
                }

                Section(header: Text("保存先リスト")) {
                    Picker("リスト", selection: $selectedList) {
                        Text("選択なし").tag("")
                        ForEach(allLists, id: \.self) { list in
                            Text(list).tag(list)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("ArchiVe に保存")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        writePendingShare()
                        onSave()
                    }
                }
            }
        }
        .onAppear {
            loadLists()
            fetchTitle()
        }
    }

    // App Groups からリスト一覧を読み込む
    private func loadLists() {
        guard let defaults = UserDefaults(suiteName: kAppGroupID),
              let jsonString = defaults.string(forKey: kAllListsKey),
              let data = jsonString.data(using: .utf8),
              let lists = try? JSONDecoder().decode([String].self, from: data)
        else { return }
        allLists = lists
    }

    // URL から og:title / <title> を取得
    private func fetchTitle() {
        guard let targetURL = URL(string: url) else {
            isFetchingTitle = false
            return
        }

        var request = URLRequest(url: targetURL, timeoutInterval: 8)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )

        URLSession.shared.dataTask(with: request) { data, _, _ in
            defer { DispatchQueue.main.async { isFetchingTitle = false } }
            guard let data = data else { return }

            let html = String(data: data, encoding: .utf8)
                    ?? String(data: data, encoding: .isoLatin1)
                    ?? ""

            let extracted = extractOgTitle(html: html) ?? extractTitleTag(html: html)
            if let title = extracted, !title.isEmpty {
                DispatchQueue.main.async { titleText = title }
            }
        }.resume()
    }

    // og:title を抽出（属性の順序が逆のケースも対応）
    private func extractOgTitle(html: String) -> String? {
        let patterns = [
            #"<meta[^>]+property=["']og:title["'][^>]+content=["']([^"'<>]+)["']"#,
            #"<meta[^>]+content=["']([^"'<>]+)["'][^>]+property=["']og:title["']"#,
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                  let range = Range(match.range(at: 1), in: html)
            else { continue }
            return htmlDecode(String(html[range]))
        }
        return nil
    }

    // <title> タグを抽出
    private func extractTitleTag(html: String) -> String? {
        let pattern = #"<title[^>]*>([^<]+)</title>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html)
        else { return nil }
        return htmlDecode(String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // HTML エンティティのデコード
    private func htmlDecode(_ string: String) -> String {
        var result = string
        let entities: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&nbsp;", " "),
        ]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        return result
    }

    // App Groups に pending データを書き込む
    private func writePendingShare() {
        let item: [String: String] = [
            "url": url,
            "title": titleText,
            "listName": selectedList,
        ]
        guard let data = try? JSONEncoder().encode(item),
              let jsonString = String(data: data, encoding: .utf8),
              let defaults = UserDefaults(suiteName: kAppGroupID)
        else { return }
        defaults.set(jsonString, forKey: kPendingShareKey)
        defaults.synchronize()
    }
}

// MARK: - Share Extension Principal Class

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        extractSharedURL { [weak self] urlString in
            DispatchQueue.main.async {
                guard let self else { return }
                if let url = urlString {
                    self.presentShareUI(url: url)
                } else {
                    self.cancelRequest()
                }
            }
        }
    }

    private func presentShareUI(url: String) {
        let shareView = ShareView(
            url: url,
            onSave: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            },
            onCancel: { [weak self] in
                self?.cancelRequest()
            }
        )

        let hostingVC = UIHostingController(rootView: shareView)
        addChild(hostingVC)
        hostingVC.view.frame = view.bounds
        hostingVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingVC.view)
        hostingVC.didMove(toParent: self)
    }

    // extensionContext から URL を抽出
    private func extractSharedURL(completion: @escaping (String?) -> Void) {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            completion(nil)
            return
        }

        for item in items {
            for provider in item.attachments ?? [] {
                // URL 型
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier) { data, _ in
                        if let url = data as? URL {
                            completion(url.absoluteString)
                        } else if let str = data as? String, str.hasPrefix("http") {
                            completion(str)
                        } else {
                            completion(nil)
                        }
                    }
                    return
                }
                // プレーンテキスト fallback（一部アプリはこちらで渡す）
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { data, _ in
                        if let str = data as? String, str.hasPrefix("http") {
                            completion(str)
                        } else {
                            completion(nil)
                        }
                    }
                    return
                }
            }
        }
        completion(nil)
    }

    private func cancelRequest() {
        extensionContext?.cancelRequest(withError: NSError(
            domain: Bundle.main.bundleIdentifier ?? "ShareExtension",
            code: 0,
            userInfo: nil
        ))
    }
}
