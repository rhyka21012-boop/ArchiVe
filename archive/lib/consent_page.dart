import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/app_localizations.dart';

/// 現在の同意バージョン。免責事項を大幅に変更したらインクリメントして、
/// 既存ユーザーにも再同意を求める。
const int kConsentVersion = 1;
const String _kConsentPrefsKey = 'consent_version_accepted';

/// 保存済みの同意バージョンが現行以上か判定
Future<bool> isConsentAccepted() async {
  final prefs = await SharedPreferences.getInstance();
  final v = prefs.getInt(_kConsentPrefsKey) ?? 0;
  return v >= kConsentVersion;
}

Future<void> _markConsentAccepted() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kConsentPrefsKey, kConsentVersion);
}

/// 初回起動時 (または免責改定時) に表示する同意画面。
/// [onAccepted] は「同意する」タップ後に呼ばれる。
class ConsentPage extends StatefulWidget {
  final VoidCallback onAccepted;
  const ConsentPage({super.key, required this.onAccepted});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool _checked = false;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showFullDisclaimer() async {
    final l = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: cs.secondary,
        title: Text(
          l.settings_page_ip_disclaimer,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            l.settings_page_ip_disclaimer_body,
            style: const TextStyle(fontSize: 12, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Icon(Icons.verified_user, size: 56, color: cs.primary),
              const SizedBox(height: 16),
              Text(
                l.consent_page_title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.consent_page_subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionCard(
                        cs,
                        icon: Icons.privacy_tip_outlined,
                        title: l.consent_page_privacy_title,
                        body: l.consent_page_privacy_body,
                        trailing: TextButton(
                          onPressed: () => _openUrl(
                              'https://walkinggoblins-site.web.app/privacy.html'),
                          child: Text(l.consent_page_read_more),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        cs,
                        icon: Icons.gavel_outlined,
                        title: l.consent_page_terms_title,
                        body: l.consent_page_terms_body,
                        trailing: TextButton(
                          onPressed: () => _openUrl(
                              'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
                          child: Text(l.consent_page_read_more),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        cs,
                        icon: Icons.copyright_outlined,
                        title: l.settings_page_ip_disclaimer,
                        body: l.consent_page_ip_summary,
                        trailing: TextButton(
                          onPressed: _showFullDisclaimer,
                          child: Text(l.consent_page_read_more),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => setState(() => _checked = !_checked),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _checked,
                        onChanged: (v) =>
                            setState(() => _checked = v ?? false),
                      ),
                      Expanded(
                        child: Text(
                          l.consent_page_agree_checkbox,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checked
                      ? () async {
                          await _markConsentAccepted();
                          widget.onAccepted();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l.consent_page_agree,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String body,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 12, height: 1.5)),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing),
        ],
      ),
    );
  }
}
