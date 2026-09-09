import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n? of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n);
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale('zh'),
  ];

  /// No description provided for @app_title.
  ///
  /// In ja, this message translates to:
  /// **'ArchiVe'**
  String get app_title;

  /// No description provided for @version.
  ///
  /// In ja, this message translates to:
  /// **'v2.0'**
  String get version;

  /// No description provided for @critical.
  ///
  /// In ja, this message translates to:
  /// **'クリティカル'**
  String get critical;

  /// No description provided for @normal.
  ///
  /// In ja, this message translates to:
  /// **'ノーマル'**
  String get normal;

  /// No description provided for @maniac.
  ///
  /// In ja, this message translates to:
  /// **'マニアック'**
  String get maniac;

  /// No description provided for @unrated.
  ///
  /// In ja, this message translates to:
  /// **'未評価'**
  String get unrated;

  /// No description provided for @ok.
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @back.
  ///
  /// In ja, this message translates to:
  /// **'戻る'**
  String get back;

  /// No description provided for @add.
  ///
  /// In ja, this message translates to:
  /// **'追加'**
  String get add;

  /// No description provided for @delete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @reload.
  ///
  /// In ja, this message translates to:
  /// **'再読み込み'**
  String get reload;

  /// No description provided for @all_item_list_name.
  ///
  /// In ja, this message translates to:
  /// **'全てのアイテム'**
  String get all_item_list_name;

  /// No description provided for @yes.
  ///
  /// In ja, this message translates to:
  /// **'はい'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ja, this message translates to:
  /// **'いいえ'**
  String get no;

  /// No description provided for @clear.
  ///
  /// In ja, this message translates to:
  /// **'クリア'**
  String get clear;

  /// No description provided for @favorite.
  ///
  /// In ja, this message translates to:
  /// **'お気に入り'**
  String get favorite;

  /// No description provided for @url.
  ///
  /// In ja, this message translates to:
  /// **'URL'**
  String get url;

  /// No description provided for @title.
  ///
  /// In ja, this message translates to:
  /// **'タイトル'**
  String get title;

  /// No description provided for @no_select.
  ///
  /// In ja, this message translates to:
  /// **'選択なし'**
  String get no_select;

  /// No description provided for @modify.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get modify;

  /// No description provided for @close.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get close;

  /// No description provided for @skip.
  ///
  /// In ja, this message translates to:
  /// **'スキップ'**
  String get skip;

  /// No description provided for @save_limit_dialog_title.
  ///
  /// In ja, this message translates to:
  /// **'保存数の上限に達しました。'**
  String get save_limit_dialog_title;

  /// No description provided for @save_limit_dialog_status_label.
  ///
  /// In ja, this message translates to:
  /// **'保存済み'**
  String get save_limit_dialog_status_label;

  /// No description provided for @save_limit_dialog_premium_detail.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムの詳細'**
  String get save_limit_dialog_premium_detail;

  /// No description provided for @save_limit_loading_ad.
  ///
  /// In ja, this message translates to:
  /// **'広告を読み込み中です…'**
  String get save_limit_loading_ad;

  /// No description provided for @main_page_lists.
  ///
  /// In ja, this message translates to:
  /// **'リスト'**
  String get main_page_lists;

  /// No description provided for @main_page_search.
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get main_page_search;

  /// No description provided for @main_page_browser.
  ///
  /// In ja, this message translates to:
  /// **'ブラウザ'**
  String get main_page_browser;

  /// No description provided for @browser_home_url_hint.
  ///
  /// In ja, this message translates to:
  /// **'URL を入力または検索'**
  String get browser_home_url_hint;

  /// No description provided for @browser_home_history.
  ///
  /// In ja, this message translates to:
  /// **'履歴'**
  String get browser_home_history;

  /// No description provided for @browser_home_history_empty.
  ///
  /// In ja, this message translates to:
  /// **'履歴はまだありません'**
  String get browser_home_history_empty;

  /// No description provided for @browser_home_history_clear.
  ///
  /// In ja, this message translates to:
  /// **'履歴をクリア'**
  String get browser_home_history_clear;

  /// No description provided for @browser_home_history_clear_confirm.
  ///
  /// In ja, this message translates to:
  /// **'履歴を全て削除しますか？'**
  String get browser_home_history_clear_confirm;

  /// No description provided for @browser_home_favorites.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りサイト'**
  String get browser_home_favorites;

  /// No description provided for @main_page_analytics.
  ///
  /// In ja, this message translates to:
  /// **'統計'**
  String get main_page_analytics;

  /// No description provided for @main_page_settings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get main_page_settings;

  /// No description provided for @main_page_update_info.
  ///
  /// In ja, this message translates to:
  /// **'アップデートのお知らせ'**
  String get main_page_update_info;

  /// No description provided for @main_page_update_later.
  ///
  /// In ja, this message translates to:
  /// **'あとで'**
  String get main_page_update_later;

  /// No description provided for @main_page_update_now.
  ///
  /// In ja, this message translates to:
  /// **'アップデート'**
  String get main_page_update_now;

  /// No description provided for @list_page_home.
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get list_page_home;

  /// No description provided for @list_page_my_list.
  ///
  /// In ja, this message translates to:
  /// **'マイリスト'**
  String get list_page_my_list;

  /// No description provided for @list_page_my_ranking.
  ///
  /// In ja, this message translates to:
  /// **'マイランキング'**
  String get list_page_my_ranking;

  /// No description provided for @list_page_make_list.
  ///
  /// In ja, this message translates to:
  /// **'リストを作成'**
  String get list_page_make_list;

  /// No description provided for @list_page_add_list.
  ///
  /// In ja, this message translates to:
  /// **'リストを追加'**
  String get list_page_add_list;

  /// No description provided for @list_page_input_list_name.
  ///
  /// In ja, this message translates to:
  /// **'リスト名を入力'**
  String get list_page_input_list_name;

  /// No description provided for @reset.
  ///
  /// In ja, this message translates to:
  /// **'リセット'**
  String get reset;

  /// No description provided for @list_page_rating_rename_title.
  ///
  /// In ja, this message translates to:
  /// **'評価名を変更'**
  String get list_page_rating_rename_title;

  /// No description provided for @list_page_reorder.
  ///
  /// In ja, this message translates to:
  /// **'並べ替え'**
  String get list_page_reorder;

  /// No description provided for @list_page_reorder_done.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get list_page_reorder_done;

  /// No description provided for @list_page_reorder_hint.
  ///
  /// In ja, this message translates to:
  /// **'ドラッグして順番を変更できます'**
  String get list_page_reorder_hint;

  /// No description provided for @list_page_all_item_fixed.
  ///
  /// In ja, this message translates to:
  /// **'「全てのアイテム」は並べ替えできません'**
  String get list_page_all_item_fixed;

  /// No description provided for @list_page_save_count.
  ///
  /// In ja, this message translates to:
  /// **'保存 {count} / {limit}'**
  String list_page_save_count(int count, int limit);

  /// No description provided for @list_page_item_unit.
  ///
  /// In ja, this message translates to:
  /// **'件'**
  String get list_page_item_unit;

  /// No description provided for @list_page_item_count.
  ///
  /// In ja, this message translates to:
  /// **'{count}件'**
  String list_page_item_count(int count);

  /// No description provided for @ranking_page_dragable.
  ///
  /// In ja, this message translates to:
  /// **'ドラッグして順番を変更できます'**
  String get ranking_page_dragable;

  /// No description provided for @ranking_page_no_title.
  ///
  /// In ja, this message translates to:
  /// **'（タイトルなし）'**
  String get ranking_page_no_title;

  /// No description provided for @ranking_page_search_title.
  ///
  /// In ja, this message translates to:
  /// **'タイトルを検索'**
  String get ranking_page_search_title;

  /// No description provided for @ranking_page_no_grid_item.
  ///
  /// In ja, this message translates to:
  /// **'保存されたアイテムがありません'**
  String get ranking_page_no_grid_item;

  /// No description provided for @ranking_page_limit_error.
  ///
  /// In ja, this message translates to:
  /// **'最大10個までしか追加できません'**
  String get ranking_page_limit_error;

  /// No description provided for @ranking_page_no_ranking_item.
  ///
  /// In ja, this message translates to:
  /// **'ランキングに作品がありません'**
  String get ranking_page_no_ranking_item;

  /// No description provided for @ranking_page_no_ranking_item_description.
  ///
  /// In ja, this message translates to:
  /// **'下の一覧から追加してください'**
  String get ranking_page_no_ranking_item_description;

  /// No description provided for @grid_page_item_count.
  ///
  /// In ja, this message translates to:
  /// **'{length}件'**
  String grid_page_item_count(Object length);

  /// No description provided for @grid_page_no_item.
  ///
  /// In ja, this message translates to:
  /// **'アイテムがありません'**
  String get grid_page_no_item;

  /// No description provided for @grid_page_add_item.
  ///
  /// In ja, this message translates to:
  /// **'追加方法を選択してください'**
  String get grid_page_add_item;

  /// No description provided for @grid_page_by_web.
  ///
  /// In ja, this message translates to:
  /// **'Web検索で追加'**
  String get grid_page_by_web;

  /// No description provided for @grid_page_by_manual.
  ///
  /// In ja, this message translates to:
  /// **'手動で追加'**
  String get grid_page_by_manual;

  /// No description provided for @grid_page_cant_load_image.
  ///
  /// In ja, this message translates to:
  /// **'画像を読み込めません'**
  String get grid_page_cant_load_image;

  /// No description provided for @grid_page_no_title.
  ///
  /// In ja, this message translates to:
  /// **'（タイトルなし）'**
  String get grid_page_no_title;

  /// No description provided for @grid_page_url_unable.
  ///
  /// In ja, this message translates to:
  /// **'有効なURLではありません'**
  String get grid_page_url_unable;

  /// No description provided for @grid_page_sort_title.
  ///
  /// In ja, this message translates to:
  /// **'タイトル順'**
  String get grid_page_sort_title;

  /// No description provided for @grid_page_sort_new.
  ///
  /// In ja, this message translates to:
  /// **'追加が新しい順'**
  String get grid_page_sort_new;

  /// No description provided for @grid_page_sort_old.
  ///
  /// In ja, this message translates to:
  /// **'追加が古い順'**
  String get grid_page_sort_old;

  /// No description provided for @grid_page_sort_count_asc.
  ///
  /// In ja, this message translates to:
  /// **'視聴回数が多い順'**
  String get grid_page_sort_count_asc;

  /// No description provided for @grid_page_sort_count_desc.
  ///
  /// In ja, this message translates to:
  /// **'視聴回数が少ない順'**
  String get grid_page_sort_count_desc;

  /// No description provided for @grid_page_sort_rating.
  ///
  /// In ja, this message translates to:
  /// **'評価順'**
  String get grid_page_sort_rating;

  /// No description provided for @grid_page_sort_offline_first.
  ///
  /// In ja, this message translates to:
  /// **'オフライン優先'**
  String get grid_page_sort_offline_first;

  /// No description provided for @grid_page_sort_list_name.
  ///
  /// In ja, this message translates to:
  /// **'リスト名順'**
  String get grid_page_sort_list_name;

  /// No description provided for @grid_page_sort_random.
  ///
  /// In ja, this message translates to:
  /// **'ランダム'**
  String get grid_page_sort_random;

  /// No description provided for @grid_page_sort_by_cast.
  ///
  /// In ja, this message translates to:
  /// **'キャスト別'**
  String get grid_page_sort_by_cast;

  /// No description provided for @grid_page_sort_by_date.
  ///
  /// In ja, this message translates to:
  /// **'追加日順'**
  String get grid_page_sort_by_date;

  /// No description provided for @grid_page_sort_current.
  ///
  /// In ja, this message translates to:
  /// **'並び: {label}'**
  String grid_page_sort_current(String label);

  /// No description provided for @grid_page_items_selected_delete.
  ///
  /// In ja, this message translates to:
  /// **'選択した{count}件を削除しますか？'**
  String grid_page_items_selected_delete(Object count);

  /// No description provided for @grid_page_rating_guidance.
  ///
  /// In ja, this message translates to:
  /// **'作品を評価するとここに表示されます'**
  String get grid_page_rating_guidance;

  /// No description provided for @detail_page_url_empty.
  ///
  /// In ja, this message translates to:
  /// **'URLが未入力です。'**
  String get detail_page_url_empty;

  /// No description provided for @detail_page_input_url.
  ///
  /// In ja, this message translates to:
  /// **'URLを入力してください。'**
  String get detail_page_input_url;

  /// No description provided for @detail_page_url_changed.
  ///
  /// In ja, this message translates to:
  /// **'URLが変更されました。'**
  String get detail_page_url_changed;

  /// No description provided for @detail_page_url_changed_note.
  ///
  /// In ja, this message translates to:
  /// **'URLを変更すると別のアイテムとして保存されます。\n続行しますか？'**
  String get detail_page_url_changed_note;

  /// No description provided for @detail_page_no_selected.
  ///
  /// In ja, this message translates to:
  /// **'選択なし'**
  String get detail_page_no_selected;

  /// No description provided for @detail_page_item_detail.
  ///
  /// In ja, this message translates to:
  /// **'作品詳細'**
  String get detail_page_item_detail;

  /// No description provided for @detail_page_delete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get detail_page_delete;

  /// No description provided for @detail_page_access.
  ///
  /// In ja, this message translates to:
  /// **'ブラウザ'**
  String get detail_page_access;

  /// No description provided for @detail_page_modify.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get detail_page_modify;

  /// No description provided for @detail_page_share.
  ///
  /// In ja, this message translates to:
  /// **'共有'**
  String get detail_page_share;

  /// No description provided for @detail_page_copied.
  ///
  /// In ja, this message translates to:
  /// **'コピーしました'**
  String get detail_page_copied;

  /// No description provided for @detail_page_saved_to.
  ///
  /// In ja, this message translates to:
  /// **'{listName} に保存'**
  String detail_page_saved_to(String listName);

  /// No description provided for @detail_page_save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get detail_page_save;

  /// No description provided for @detail_page_thumbnail_placeholder.
  ///
  /// In ja, this message translates to:
  /// **'保存するとサムネイルが表示されます'**
  String get detail_page_thumbnail_placeholder;

  /// No description provided for @detail_page_add_image.
  ///
  /// In ja, this message translates to:
  /// **'サムネイル画像を追加★'**
  String get detail_page_add_image;

  /// No description provided for @detail_page_offline.
  ///
  /// In ja, this message translates to:
  /// **'オフライン'**
  String get detail_page_offline;

  /// No description provided for @detail_page_offline_downloaded.
  ///
  /// In ja, this message translates to:
  /// **'オフライン保存済み'**
  String get detail_page_offline_downloaded;

  /// No description provided for @detail_page_offline_confirm_title.
  ///
  /// In ja, this message translates to:
  /// **'この作品をオフラインに保存しますか？'**
  String get detail_page_offline_confirm_title;

  /// No description provided for @detail_page_offline_confirm_body.
  ///
  /// In ja, this message translates to:
  /// **'動画データをこの端末にダウンロードします。\n※あなたが権利を保有するか、権利者から許諾を得た動画のみ保存してください。'**
  String get detail_page_offline_confirm_body;

  /// No description provided for @detail_page_offline_no_url.
  ///
  /// In ja, this message translates to:
  /// **'URL が入力されていません'**
  String get detail_page_offline_no_url;

  /// No description provided for @detail_page_offline_started.
  ///
  /// In ja, this message translates to:
  /// **'ダウンロードを開始しました'**
  String get detail_page_offline_started;

  /// No description provided for @detail_page_offline_probing.
  ///
  /// In ja, this message translates to:
  /// **'利用可能な解像度を確認中…'**
  String get detail_page_offline_probing;

  /// No description provided for @detail_page_delete_offline_confirm.
  ///
  /// In ja, this message translates to:
  /// **'この作品のオフラインデータを削除しますか？\n（オンライン再生には影響しません）'**
  String get detail_page_delete_offline_confirm;

  /// No description provided for @detail_page_offline_deleted.
  ///
  /// In ja, this message translates to:
  /// **'オフラインデータを削除しました'**
  String get detail_page_offline_deleted;

  /// No description provided for @consent_page_title.
  ///
  /// In ja, this message translates to:
  /// **'ご利用にあたって'**
  String get consent_page_title;

  /// No description provided for @consent_page_subtitle.
  ///
  /// In ja, this message translates to:
  /// **'本アプリのご利用前に、以下をご確認の上ご同意ください。'**
  String get consent_page_subtitle;

  /// No description provided for @consent_page_privacy_title.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get consent_page_privacy_title;

  /// No description provided for @consent_page_privacy_body.
  ///
  /// In ja, this message translates to:
  /// **'本アプリは個人情報の適切な取り扱いに努めます。詳細は下記のポリシーをご確認ください。'**
  String get consent_page_privacy_body;

  /// No description provided for @consent_page_terms_title.
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get consent_page_terms_title;

  /// No description provided for @consent_page_terms_body.
  ///
  /// In ja, this message translates to:
  /// **'本アプリの利用に関する規約を必ずお読みください。'**
  String get consent_page_terms_body;

  /// No description provided for @consent_page_ip_summary.
  ///
  /// In ja, this message translates to:
  /// **'本アプリはユーザーが入力したURLからのダウンロード・オフライン再生を提供する汎用ツールです。著作権および配信元の利用規約はユーザーの責任で遵守してください。'**
  String get consent_page_ip_summary;

  /// No description provided for @consent_page_agree_checkbox.
  ///
  /// In ja, this message translates to:
  /// **'上記の内容をすべて理解し、同意します'**
  String get consent_page_agree_checkbox;

  /// No description provided for @consent_page_agree.
  ///
  /// In ja, this message translates to:
  /// **'同意して開始'**
  String get consent_page_agree;

  /// No description provided for @consent_page_read_more.
  ///
  /// In ja, this message translates to:
  /// **'全文を読む'**
  String get consent_page_read_more;

  /// No description provided for @settings_page_ip_disclaimer.
  ///
  /// In ja, this message translates to:
  /// **'知的財産権に関する免責事項'**
  String get settings_page_ip_disclaimer;

  /// No description provided for @settings_page_ip_disclaimer_body.
  ///
  /// In ja, this message translates to:
  /// **'本アプリは、ユーザーが自身の判断で入力した動画URLからのダウンロードとオフライン再生機能を提供する汎用ツールです。特定のウェブサイトのコンテンツを取得することを目的としたものではありません。\n\nユーザーは、以下について自身の責任を負うものとします:\n・保存する動画コンテンツの著作権および配信元サイトの利用規約を遵守すること\n・保存したコンテンツを、私的使用の範囲 (著作権法第30条) を超えて複製・配布・公開・商用利用しないこと\n・第三者の著作権、肖像権、パブリシティ権、その他の権利を侵害しないこと\n・ダウンロード対象サイトの技術的保護手段を回避しないこと (著作権法第30条の2)\n\n本アプリの提供者は、ユーザーによる本アプリの利用に起因または関連して生じた著作権侵害、利用規約違反、その他一切の法的責任を負いません。\n\n疑義がある場合は、動画の著作権者または配信元にご確認の上、ご利用をお控えください。なお、本アプリはユーザーの入力に基づき動作するものであり、特定のサービスの推奨・提携を意味するものではありません。'**
  String get settings_page_ip_disclaimer_body;

  /// No description provided for @detail_page_offline_not_direct_video.
  ///
  /// In ja, this message translates to:
  /// **'このURLは動画ファイルの直リンクではないため、オフライン保存できません。\n（YouTube等のページURLは対応していません。mp4/m4v/mov/webm/mkv 形式の直リンクをお使いください）'**
  String get detail_page_offline_not_direct_video;

  /// No description provided for @detail_page_offline_failed.
  ///
  /// In ja, this message translates to:
  /// **'ダウンロードに失敗しました'**
  String get detail_page_offline_failed;

  /// No description provided for @download_failed_but_saved.
  ///
  /// In ja, this message translates to:
  /// **'URLはブックマークに保存されました（動画本体は未ダウンロード）'**
  String get download_failed_but_saved;

  /// No description provided for @download_cancel_confirm_title.
  ///
  /// In ja, this message translates to:
  /// **'ダウンロードを中断しますか？'**
  String get download_cancel_confirm_title;

  /// No description provided for @download_cancel_confirm_body.
  ///
  /// In ja, this message translates to:
  /// **'進行中のダウンロードを中断してこのタスクを削除します。よろしいですか？'**
  String get download_cancel_confirm_body;

  /// No description provided for @detail_page_offline_hls_not_supported.
  ///
  /// In ja, this message translates to:
  /// **'この動画はHLS形式(.m3u8)のためオフライン保存に対応していません。'**
  String get detail_page_offline_hls_not_supported;

  /// No description provided for @browser_video_detected_chip.
  ///
  /// In ja, this message translates to:
  /// **'動画を検出'**
  String get browser_video_detected_chip;

  /// No description provided for @browser_video_detected_sheet_title.
  ///
  /// In ja, this message translates to:
  /// **'検出された動画'**
  String get browser_video_detected_sheet_title;

  /// No description provided for @browser_video_detected_sheet_desc.
  ///
  /// In ja, this message translates to:
  /// **'ダウンロードしたい動画を選択してください。'**
  String get browser_video_detected_sheet_desc;

  /// No description provided for @browser_video_download.
  ///
  /// In ja, this message translates to:
  /// **'この動画をダウンロード'**
  String get browser_video_download;

  /// No description provided for @browser_video_download_started.
  ///
  /// In ja, this message translates to:
  /// **'ダウンロードを開始しました'**
  String get browser_video_download_started;

  /// No description provided for @browser_video_download_saved_first.
  ///
  /// In ja, this message translates to:
  /// **'先に作品として保存してからダウンロードします'**
  String get browser_video_download_saved_first;

  /// No description provided for @search_result_page_offline.
  ///
  /// In ja, this message translates to:
  /// **'オフライン保存'**
  String get search_result_page_offline;

  /// No description provided for @search_result_page_offline_desc.
  ///
  /// In ja, this message translates to:
  /// **'この作品を端末にダウンロードして、通信なしで再生できるようにします。'**
  String get search_result_page_offline_desc;

  /// No description provided for @download_queue_title.
  ///
  /// In ja, this message translates to:
  /// **'ダウンロード'**
  String get download_queue_title;

  /// No description provided for @download_clear_finished.
  ///
  /// In ja, this message translates to:
  /// **'完了分を消去'**
  String get download_clear_finished;

  /// No description provided for @download_empty.
  ///
  /// In ja, this message translates to:
  /// **'現在ダウンロードはありません'**
  String get download_empty;

  /// No description provided for @download_status_queued.
  ///
  /// In ja, this message translates to:
  /// **'待機中'**
  String get download_status_queued;

  /// No description provided for @download_status_completed.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get download_status_completed;

  /// No description provided for @download_status_failed.
  ///
  /// In ja, this message translates to:
  /// **'失敗'**
  String get download_status_failed;

  /// No description provided for @download_cancel_all_confirm.
  ///
  /// In ja, this message translates to:
  /// **'全てのダウンロードをキャンセルしますか？'**
  String get download_cancel_all_confirm;

  /// No description provided for @download_status_canceled.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get download_status_canceled;

  /// No description provided for @download_premium_required_title.
  ///
  /// In ja, this message translates to:
  /// **'Premium 限定機能'**
  String get download_premium_required_title;

  /// No description provided for @download_premium_required_body.
  ///
  /// In ja, this message translates to:
  /// **'オフラインダウンロードは Premium 以上のプランでご利用いただけます。'**
  String get download_premium_required_body;

  /// No description provided for @detail_page_rate.
  ///
  /// In ja, this message translates to:
  /// **'評価'**
  String get detail_page_rate;

  /// No description provided for @detail_page_title.
  ///
  /// In ja, this message translates to:
  /// **'タイトル'**
  String get detail_page_title;

  /// No description provided for @detail_page_title_placeholder.
  ///
  /// In ja, this message translates to:
  /// **'タイトル'**
  String get detail_page_title_placeholder;

  /// No description provided for @detail_page_cast_short.
  ///
  /// In ja, this message translates to:
  /// **'出演'**
  String get detail_page_cast_short;

  /// No description provided for @detail_page_genre_short.
  ///
  /// In ja, this message translates to:
  /// **'ジャンル'**
  String get detail_page_genre_short;

  /// No description provided for @detail_page_series_short.
  ///
  /// In ja, this message translates to:
  /// **'シリーズ'**
  String get detail_page_series_short;

  /// No description provided for @detail_page_maker_short.
  ///
  /// In ja, this message translates to:
  /// **'メーカー'**
  String get detail_page_maker_short;

  /// No description provided for @detail_page_label_short.
  ///
  /// In ja, this message translates to:
  /// **'レーベル'**
  String get detail_page_label_short;

  /// No description provided for @detail_page_cast.
  ///
  /// In ja, this message translates to:
  /// **'出演 (#で複数入力)'**
  String get detail_page_cast;

  /// No description provided for @detail_page_cast_placeholder.
  ///
  /// In ja, this message translates to:
  /// **'#出演1 #出演2 ...'**
  String get detail_page_cast_placeholder;

  /// No description provided for @detail_page_genre.
  ///
  /// In ja, this message translates to:
  /// **'ジャンル (#で複数入力)'**
  String get detail_page_genre;

  /// No description provided for @detail_page_genre_placeholder.
  ///
  /// In ja, this message translates to:
  /// **'#ジャンル1 #ジャンル2 ...'**
  String get detail_page_genre_placeholder;

  /// No description provided for @detail_page_series.
  ///
  /// In ja, this message translates to:
  /// **'シリーズ (#で複数入力)'**
  String get detail_page_series;

  /// No description provided for @detail_page_series_placeholder.
  ///
  /// In ja, this message translates to:
  /// **'#シリーズ1 #シリーズ2 ...'**
  String get detail_page_series_placeholder;

  /// No description provided for @detail_page_label.
  ///
  /// In ja, this message translates to:
  /// **'レーベル (#で複数入力)'**
  String get detail_page_label;

  /// No description provided for @detail_page_label_placeholder.
  ///
  /// In ja, this message translates to:
  /// **'#レーベル1 #レーベル2 ...'**
  String get detail_page_label_placeholder;

  /// No description provided for @detail_page_maker.
  ///
  /// In ja, this message translates to:
  /// **'メーカー (#で複数入力)'**
  String get detail_page_maker;

  /// No description provided for @detail_page_maker_placeholder.
  ///
  /// In ja, this message translates to:
  /// **'#メーカー1 #メーカー2 ...'**
  String get detail_page_maker_placeholder;

  /// No description provided for @detail_page_paste_url.
  ///
  /// In ja, this message translates to:
  /// **'URLをペースト'**
  String get detail_page_paste_url;

  /// No description provided for @detail_page_fetch_title.
  ///
  /// In ja, this message translates to:
  /// **'URLからタイトルを取得'**
  String get detail_page_fetch_title;

  /// No description provided for @detail_page_list.
  ///
  /// In ja, this message translates to:
  /// **'リスト'**
  String get detail_page_list;

  /// No description provided for @detail_page_memo.
  ///
  /// In ja, this message translates to:
  /// **'メモ'**
  String get detail_page_memo;

  /// No description provided for @detail_page_fetch_title_fail.
  ///
  /// In ja, this message translates to:
  /// **'タイトルが見つかりませんでした。'**
  String get detail_page_fetch_title_fail;

  /// No description provided for @detail_page_fetch_page_fail.
  ///
  /// In ja, this message translates to:
  /// **'ページ取得に失敗しました。'**
  String get detail_page_fetch_page_fail;

  /// No description provided for @detail_page_ex.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました。'**
  String get detail_page_ex;

  /// No description provided for @detail_page_delete_confirm01.
  ///
  /// In ja, this message translates to:
  /// **'削除しますか？'**
  String get detail_page_delete_confirm01;

  /// No description provided for @detail_page_delete_confirm02.
  ///
  /// In ja, this message translates to:
  /// **'削除後は復元できません。'**
  String get detail_page_delete_confirm02;

  /// No description provided for @detail_page_url_unable.
  ///
  /// In ja, this message translates to:
  /// **'有効なURLではありません'**
  String get detail_page_url_unable;

  /// No description provided for @detail_page_review_confirm01.
  ///
  /// In ja, this message translates to:
  /// **'ArchiVeを気に入っていただけましたか？'**
  String get detail_page_review_confirm01;

  /// No description provided for @detail_page_review_confirm02.
  ///
  /// In ja, this message translates to:
  /// **'レビューでの応援が励みになります。'**
  String get detail_page_review_confirm02;

  /// No description provided for @detail_page_review_contact_support.
  ///
  /// In ja, this message translates to:
  /// **'ご意見・不具合を報告'**
  String get detail_page_review_contact_support;

  /// No description provided for @detail_page_review_later.
  ///
  /// In ja, this message translates to:
  /// **'あとで'**
  String get detail_page_review_later;

  /// No description provided for @detail_page_review_now.
  ///
  /// In ja, this message translates to:
  /// **'レビューを書く'**
  String get detail_page_review_now;

  /// No description provided for @detail_page_mail_subject.
  ///
  /// In ja, this message translates to:
  /// **'subject=ArchiVe ご意見・ご要望'**
  String get detail_page_mail_subject;

  /// No description provided for @detail_page_fetching_thumbnail.
  ///
  /// In ja, this message translates to:
  /// **'サムネイルを取得中...'**
  String get detail_page_fetching_thumbnail;

  /// No description provided for @search_page_cast.
  ///
  /// In ja, this message translates to:
  /// **'出演'**
  String get search_page_cast;

  /// No description provided for @search_page_genre.
  ///
  /// In ja, this message translates to:
  /// **'ジャンル'**
  String get search_page_genre;

  /// No description provided for @search_page_series.
  ///
  /// In ja, this message translates to:
  /// **'シリーズ'**
  String get search_page_series;

  /// No description provided for @search_page_label.
  ///
  /// In ja, this message translates to:
  /// **'レーベル'**
  String get search_page_label;

  /// No description provided for @search_page_maker.
  ///
  /// In ja, this message translates to:
  /// **'メーカー'**
  String get search_page_maker;

  /// No description provided for @search_page_search.
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get search_page_search;

  /// No description provided for @search_page_select_category.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリを選択'**
  String get search_page_select_category;

  /// No description provided for @search_page_more.
  ///
  /// In ja, this message translates to:
  /// **'もっと見る'**
  String get search_page_more;

  /// No description provided for @search_page_fold.
  ///
  /// In ja, this message translates to:
  /// **'折りたたむ'**
  String get search_page_fold;

  /// No description provided for @search_page_search_title.
  ///
  /// In ja, this message translates to:
  /// **'タイトルを検索'**
  String get search_page_search_title;

  /// No description provided for @search_page_premium_title.
  ///
  /// In ja, this message translates to:
  /// **'複数のタグを選択★'**
  String get search_page_premium_title;

  /// No description provided for @search_page_premium_description.
  ///
  /// In ja, this message translates to:
  /// **'複数のカテゴリを組み合わせた検索は\nプレミアムプラン限定の機能です。'**
  String get search_page_premium_description;

  /// No description provided for @search_page_segment_button_app.
  ///
  /// In ja, this message translates to:
  /// **'アプリ内'**
  String get search_page_segment_button_app;

  /// No description provided for @search_page_segment_button_web.
  ///
  /// In ja, this message translates to:
  /// **'Web'**
  String get search_page_segment_button_web;

  /// No description provided for @search_page_text_empty.
  ///
  /// In ja, this message translates to:
  /// **'検索ワードを入力してください'**
  String get search_page_text_empty;

  /// No description provided for @search_page_web_title.
  ///
  /// In ja, this message translates to:
  /// **'Web検索'**
  String get search_page_web_title;

  /// No description provided for @search_page_search_word.
  ///
  /// In ja, this message translates to:
  /// **'Web検索'**
  String get search_page_search_word;

  /// No description provided for @search_page_hint_web_1.
  ///
  /// In ja, this message translates to:
  /// **'広告ブロック付きで快適に検索'**
  String get search_page_hint_web_1;

  /// No description provided for @search_page_hint_web_2.
  ///
  /// In ja, this message translates to:
  /// **'例: アニメ OP'**
  String get search_page_hint_web_2;

  /// No description provided for @search_page_hint_web_3.
  ///
  /// In ja, this message translates to:
  /// **'アプリ内ブラウザでサクサク動画収集'**
  String get search_page_hint_web_3;

  /// No description provided for @search_page_hint_web_4.
  ///
  /// In ja, this message translates to:
  /// **'例: ライブ映像 2026'**
  String get search_page_hint_web_4;

  /// No description provided for @search_page_hint_web_5.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りサイトで深掘り'**
  String get search_page_hint_web_5;

  /// No description provided for @search_page_hint_web_6.
  ///
  /// In ja, this message translates to:
  /// **'例: 料理 簡単 レシピ'**
  String get search_page_hint_web_6;

  /// No description provided for @search_page_select_site.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りサイト'**
  String get search_page_select_site;

  /// No description provided for @search_page_select_site_help_title.
  ///
  /// In ja, this message translates to:
  /// **'サイトで絞る'**
  String get search_page_select_site_help_title;

  /// No description provided for @search_page_select_site_help_description.
  ///
  /// In ja, this message translates to:
  /// **'サイトを絞って動画検索ができます。お気に入りの動画サイトを登録しておくと、そのサイト内のコンテンツだけを横断的に検索できます。下のリストからサイトを選択して検索ボタンをタップしてください。'**
  String get search_page_select_site_help_description;

  /// No description provided for @search_page_open_site.
  ///
  /// In ja, this message translates to:
  /// **'サイトを開く'**
  String get search_page_open_site;

  /// No description provided for @search_page_modify_favorite.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りを編集'**
  String get search_page_modify_favorite;

  /// No description provided for @search_page_site_name.
  ///
  /// In ja, this message translates to:
  /// **'サイト名'**
  String get search_page_site_name;

  /// No description provided for @search_page_input_all.
  ///
  /// In ja, this message translates to:
  /// **'すべて入力してください'**
  String get search_page_input_all;

  /// No description provided for @search_page_add_favorite.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りサイトを追加'**
  String get search_page_add_favorite;

  /// No description provided for @search_page_random_loading.
  ///
  /// In ja, this message translates to:
  /// **'今日のおすすめを選んでいます…'**
  String get search_page_random_loading;

  /// No description provided for @search_page_random_this.
  ///
  /// In ja, this message translates to:
  /// **'今日のおすすめはこれ！'**
  String get search_page_random_this;

  /// No description provided for @search_page_random_again.
  ///
  /// In ja, this message translates to:
  /// **'もう一度回す'**
  String get search_page_random_again;

  /// No description provided for @search_result_page_site_saved.
  ///
  /// In ja, this message translates to:
  /// **'サイトを保存しました'**
  String get search_result_page_site_saved;

  /// No description provided for @search_result_page_saving_as_item.
  ///
  /// In ja, this message translates to:
  /// **'作品を保存'**
  String get search_result_page_saving_as_item;

  /// No description provided for @search_result_page_saving_list.
  ///
  /// In ja, this message translates to:
  /// **'保存先リスト'**
  String get search_result_page_saving_list;

  /// No description provided for @search_result_page_url_already_saved.
  ///
  /// In ja, this message translates to:
  /// **'このURLはすでに保存されています'**
  String get search_result_page_url_already_saved;

  /// No description provided for @search_result_page_url_already_saved_offline_prompt.
  ///
  /// In ja, this message translates to:
  /// **'この作品をオフライン用にダウンロードしますか？'**
  String get search_result_page_url_already_saved_offline_prompt;

  /// No description provided for @search_result_page_url_already_saved_and_downloaded.
  ///
  /// In ja, this message translates to:
  /// **'この作品はすでに保存＆ダウンロード済みです'**
  String get search_result_page_url_already_saved_and_downloaded;

  /// No description provided for @download_retry.
  ///
  /// In ja, this message translates to:
  /// **'リトライ'**
  String get download_retry;

  /// No description provided for @player_minimize.
  ///
  /// In ja, this message translates to:
  /// **'ミニプレイヤーに切り替え'**
  String get player_minimize;

  /// No description provided for @player_close.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get player_close;

  /// No description provided for @player_speed.
  ///
  /// In ja, this message translates to:
  /// **'再生速度'**
  String get player_speed;

  /// No description provided for @player_speed_x.
  ///
  /// In ja, this message translates to:
  /// **'{v}倍速'**
  String player_speed_x(String v);

  /// No description provided for @player_speed_custom.
  ///
  /// In ja, this message translates to:
  /// **'カスタム'**
  String get player_speed_custom;

  /// No description provided for @player_bookmarks.
  ///
  /// In ja, this message translates to:
  /// **'ブックマーク'**
  String get player_bookmarks;

  /// No description provided for @player_bookmarks_empty.
  ///
  /// In ja, this message translates to:
  /// **'ブックマークはまだありません'**
  String get player_bookmarks_empty;

  /// No description provided for @browser_video_size.
  ///
  /// In ja, this message translates to:
  /// **'サイズ'**
  String get browser_video_size;

  /// No description provided for @browser_video_size_unknown.
  ///
  /// In ja, this message translates to:
  /// **'サイズ不明'**
  String get browser_video_size_unknown;

  /// No description provided for @browser_video_quality.
  ///
  /// In ja, this message translates to:
  /// **'画質'**
  String get browser_video_quality;

  /// No description provided for @browser_tab_max_reached.
  ///
  /// In ja, this message translates to:
  /// **'タブの上限に達しました。既存のタブを閉じてから新規タブを開いてください。'**
  String get browser_tab_max_reached;

  /// No description provided for @browser_tabs_title.
  ///
  /// In ja, this message translates to:
  /// **'タブ'**
  String get browser_tabs_title;

  /// No description provided for @browser_new_tab.
  ///
  /// In ja, this message translates to:
  /// **'新しいタブ'**
  String get browser_new_tab;

  /// No description provided for @offline_quality_title.
  ///
  /// In ja, this message translates to:
  /// **'オフライン画質'**
  String get offline_quality_title;

  /// No description provided for @offline_quality_desc.
  ///
  /// In ja, this message translates to:
  /// **'ダウンロードする動画の画質を選択してください'**
  String get offline_quality_desc;

  /// No description provided for @offline_quality_none.
  ///
  /// In ja, this message translates to:
  /// **'オフラインダウンロードなし'**
  String get offline_quality_none;

  /// No description provided for @search_result_page_has_saved.
  ///
  /// In ja, this message translates to:
  /// **'作品を保存しました'**
  String get search_result_page_has_saved;

  /// No description provided for @search_result_page_delete_site.
  ///
  /// In ja, this message translates to:
  /// **'「{siteName}」をお気に入りから削除しますか？'**
  String search_result_page_delete_site(Object siteName);

  /// No description provided for @search_result_page_new_list.
  ///
  /// In ja, this message translates to:
  /// **'新規リスト'**
  String get search_result_page_new_list;

  /// No description provided for @search_result_page_input_list_name.
  ///
  /// In ja, this message translates to:
  /// **'リスト名を入力'**
  String get search_result_page_input_list_name;

  /// No description provided for @search_result_page_list_already_exists.
  ///
  /// In ja, this message translates to:
  /// **'同じ名前のリストが既にあります'**
  String get search_result_page_list_already_exists;

  /// No description provided for @search_result_page_history.
  ///
  /// In ja, this message translates to:
  /// **'履歴'**
  String get search_result_page_history;

  /// No description provided for @search_result_page_ad_remainder01.
  ///
  /// In ja, this message translates to:
  /// **'次の保存後に広告が表示されます'**
  String get search_result_page_ad_remainder01;

  /// No description provided for @search_result_page_ad_remainder02.
  ///
  /// In ja, this message translates to:
  /// **'広告を表示します'**
  String get search_result_page_ad_remainder02;

  /// No description provided for @analytics.
  ///
  /// In ja, this message translates to:
  /// **'統計'**
  String get analytics;

  /// No description provided for @analytics_page_summary.
  ///
  /// In ja, this message translates to:
  /// **'概要'**
  String get analytics_page_summary;

  /// No description provided for @analytics_page_item_count.
  ///
  /// In ja, this message translates to:
  /// **'保存数: {totalWorks}'**
  String analytics_page_item_count(Object totalWorks);

  /// No description provided for @analytics_page_recent_additions.
  ///
  /// In ja, this message translates to:
  /// **'最近追加した作品'**
  String get analytics_page_recent_additions;

  /// No description provided for @analytics_page_piechart_others.
  ///
  /// In ja, this message translates to:
  /// **'その他\n{percent}%'**
  String analytics_page_piechart_others(Object percent);

  /// No description provided for @analytics_page_view_count_top5.
  ///
  /// In ja, this message translates to:
  /// **'視聴回数 TOP5'**
  String get analytics_page_view_count_top5;

  /// No description provided for @analytics_page_no_view_records_title.
  ///
  /// In ja, this message translates to:
  /// **'まだ視聴記録がありません'**
  String get analytics_page_no_view_records_title;

  /// No description provided for @analytics_page_no_view_records_hint.
  ///
  /// In ja, this message translates to:
  /// **'作品詳細で視聴回数を記録すると表示されます'**
  String get analytics_page_no_view_records_hint;

  /// No description provided for @analytics_page_no_data.
  ///
  /// In ja, this message translates to:
  /// **'データがありません'**
  String get analytics_page_no_data;

  /// No description provided for @analytics_page_evaluation.
  ///
  /// In ja, this message translates to:
  /// **'評価'**
  String get analytics_page_evaluation;

  /// No description provided for @analytics_page_cast.
  ///
  /// In ja, this message translates to:
  /// **'出演'**
  String get analytics_page_cast;

  /// No description provided for @analytics_page_genre.
  ///
  /// In ja, this message translates to:
  /// **'ジャンル'**
  String get analytics_page_genre;

  /// No description provided for @analytics_page_series.
  ///
  /// In ja, this message translates to:
  /// **'シリーズ'**
  String get analytics_page_series;

  /// No description provided for @analytics_page_label.
  ///
  /// In ja, this message translates to:
  /// **'レーベル'**
  String get analytics_page_label;

  /// No description provided for @analytics_page_maker.
  ///
  /// In ja, this message translates to:
  /// **'メーカー'**
  String get analytics_page_maker;

  /// No description provided for @analytics_page_premium_title.
  ///
  /// In ja, this message translates to:
  /// **'統計機能★'**
  String get analytics_page_premium_title;

  /// No description provided for @analytics_page_premium_description.
  ///
  /// In ja, this message translates to:
  /// **'ArchiVeプレミアムでは統計機能を利用できます。\n機能を使うにはアップグレードしてください。'**
  String get analytics_page_premium_description;

  /// No description provided for @analytics_page_premium_button.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムの詳細をみる'**
  String get analytics_page_premium_button;

  /// No description provided for @analytics_page_list_value.
  ///
  /// In ja, this message translates to:
  /// **'{percent}% ({entry}件)'**
  String analytics_page_list_value(Object entry, Object percent);

  /// No description provided for @analytics_page_count.
  ///
  /// In ja, this message translates to:
  /// **'(回)'**
  String get analytics_page_count;

  /// No description provided for @analytics_page_toolchip_count.
  ///
  /// In ja, this message translates to:
  /// **'{rod}回'**
  String analytics_page_toolchip_count(Object rod);

  /// No description provided for @analytics_page_no_title.
  ///
  /// In ja, this message translates to:
  /// **'タイトルなし'**
  String get analytics_page_no_title;

  /// No description provided for @analytics_page_item_count_top5.
  ///
  /// In ja, this message translates to:
  /// **'アイテム数 TOP5'**
  String get analytics_page_item_count_top5;

  /// No description provided for @analytics_page_kpi_saved_count.
  ///
  /// In ja, this message translates to:
  /// **'保存数'**
  String get analytics_page_kpi_saved_count;

  /// No description provided for @analytics_page_kpi_total_view_count.
  ///
  /// In ja, this message translates to:
  /// **'総視聴回数'**
  String get analytics_page_kpi_total_view_count;

  /// No description provided for @analytics_page_kpi_rating_rate.
  ///
  /// In ja, this message translates to:
  /// **'評価率'**
  String get analytics_page_kpi_rating_rate;

  /// No description provided for @analytics_page_most_watched.
  ///
  /// In ja, this message translates to:
  /// **'最多視聴'**
  String get analytics_page_most_watched;

  /// No description provided for @analytics_page_view_times.
  ///
  /// In ja, this message translates to:
  /// **'{count}回 視聴'**
  String analytics_page_view_times(Object count);

  /// No description provided for @analytics_page_total_view_subtitle.
  ///
  /// In ja, this message translates to:
  /// **'総視聴回数: {count}回'**
  String analytics_page_total_view_subtitle(Object count);

  /// No description provided for @analytics_page_rated_subtitle.
  ///
  /// In ja, this message translates to:
  /// **'評価済み {ratedCount} / {total}件'**
  String analytics_page_rated_subtitle(Object ratedCount, Object total);

  /// No description provided for @analytics_page_unit_items.
  ///
  /// In ja, this message translates to:
  /// **'件'**
  String get analytics_page_unit_items;

  /// No description provided for @analytics_page_ranked_row_stat.
  ///
  /// In ja, this message translates to:
  /// **'{percent}%  {count}件'**
  String analytics_page_ranked_row_stat(Object count, Object percent);

  /// No description provided for @analytics_page_times_unit.
  ///
  /// In ja, this message translates to:
  /// **'{count}回'**
  String analytics_page_times_unit(Object count);

  /// No description provided for @analytics_page_view_count_by_rating.
  ///
  /// In ja, this message translates to:
  /// **'評価別 視聴回数'**
  String get analytics_page_view_count_by_rating;

  /// No description provided for @analytics_page_saved_by_list.
  ///
  /// In ja, this message translates to:
  /// **'リスト別保存数'**
  String get analytics_page_saved_by_list;

  /// No description provided for @analytics_page_list_count_subtitle.
  ///
  /// In ja, this message translates to:
  /// **'{count}リスト'**
  String analytics_page_list_count_subtitle(Object count);

  /// No description provided for @analytics_page_type_count_subtitle.
  ///
  /// In ja, this message translates to:
  /// **'{count}種類'**
  String analytics_page_type_count_subtitle(Object count);

  /// No description provided for @settings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @settings_page_dark_mode.
  ///
  /// In ja, this message translates to:
  /// **'ダークモード'**
  String get settings_page_dark_mode;

  /// No description provided for @settings_page_theme_color.
  ///
  /// In ja, this message translates to:
  /// **'テーマカラー'**
  String get settings_page_theme_color;

  /// No description provided for @settings_page_theme_color_orange.
  ///
  /// In ja, this message translates to:
  /// **'オレンジ'**
  String get settings_page_theme_color_orange;

  /// No description provided for @settings_page_theme_color_random.
  ///
  /// In ja, this message translates to:
  /// **'ランダム'**
  String get settings_page_theme_color_random;

  /// No description provided for @settings_page_theme_color_green.
  ///
  /// In ja, this message translates to:
  /// **'グリーン'**
  String get settings_page_theme_color_green;

  /// No description provided for @settings_page_theme_color_blue.
  ///
  /// In ja, this message translates to:
  /// **'ブルー'**
  String get settings_page_theme_color_blue;

  /// No description provided for @settings_page_theme_color_white.
  ///
  /// In ja, this message translates to:
  /// **'ホワイト'**
  String get settings_page_theme_color_white;

  /// No description provided for @settings_page_theme_color_red.
  ///
  /// In ja, this message translates to:
  /// **'レッド'**
  String get settings_page_theme_color_red;

  /// No description provided for @settings_page_theme_color_yellow.
  ///
  /// In ja, this message translates to:
  /// **'イエロー'**
  String get settings_page_theme_color_yellow;

  /// No description provided for @settings_page_thumbnail_visibility.
  ///
  /// In ja, this message translates to:
  /// **'リスト画像の表示/非表示'**
  String get settings_page_thumbnail_visibility;

  /// No description provided for @settings_page_save_status.
  ///
  /// In ja, this message translates to:
  /// **'アイテム数'**
  String get settings_page_save_status;

  /// No description provided for @settings_page_offline_videos.
  ///
  /// In ja, this message translates to:
  /// **'オフライン動画'**
  String get settings_page_offline_videos;

  /// No description provided for @settings_page_offline_total_size.
  ///
  /// In ja, this message translates to:
  /// **'オフライン動画の総容量'**
  String get settings_page_offline_total_size;

  /// No description provided for @settings_page_save_count.
  ///
  /// In ja, this message translates to:
  /// **'ブックマーク'**
  String get settings_page_save_count;

  /// No description provided for @settings_page_watch_count.
  ///
  /// In ja, this message translates to:
  /// **'本日の視聴回数'**
  String get settings_page_watch_count;

  /// No description provided for @settings_page_watch_ad_today.
  ///
  /// In ja, this message translates to:
  /// **'{watchedAdsToday} / 5 回'**
  String settings_page_watch_ad_today(Object watchedAdsToday);

  /// No description provided for @settings_page_watch_ad.
  ///
  /// In ja, this message translates to:
  /// **'広告を見て +1 枠'**
  String get settings_page_watch_ad;

  /// No description provided for @settings_page_ad_limit_reached.
  ///
  /// In ja, this message translates to:
  /// **'本日の広告視聴上限に達しました'**
  String get settings_page_ad_limit_reached;

  /// No description provided for @settings_page_already_purchased.
  ///
  /// In ja, this message translates to:
  /// **'既に購入済みです。'**
  String get settings_page_already_purchased;

  /// No description provided for @settings_page_premium.
  ///
  /// In ja, this message translates to:
  /// **'ArchiVe プレミアム'**
  String get settings_page_premium;

  /// No description provided for @settings_page_app_version.
  ///
  /// In ja, this message translates to:
  /// **'アプリバージョン'**
  String get settings_page_app_version;

  /// No description provided for @settings_page_plivacy_policy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get settings_page_plivacy_policy;

  /// No description provided for @settings_page_disable_link.
  ///
  /// In ja, this message translates to:
  /// **'リンクを開けませんでした'**
  String get settings_page_disable_link;

  /// No description provided for @settings_page_terms.
  ///
  /// In ja, this message translates to:
  /// **'利用規約（Apple標準EULA）'**
  String get settings_page_terms;

  /// No description provided for @settings_page_save_count_increased.
  ///
  /// In ja, this message translates to:
  /// **'保存枠が +1 されました'**
  String get settings_page_save_count_increased;

  /// No description provided for @setting_page_unlimited.
  ///
  /// In ja, this message translates to:
  /// **'無制限'**
  String get setting_page_unlimited;

  /// No description provided for @view_counter_view_count.
  ///
  /// In ja, this message translates to:
  /// **'視聴 {viewCount}'**
  String view_counter_view_count(Object viewCount);

  /// No description provided for @random_image_no_image.
  ///
  /// In ja, this message translates to:
  /// **'画像を読み込めません'**
  String get random_image_no_image;

  /// No description provided for @random_image_change_list_name.
  ///
  /// In ja, this message translates to:
  /// **'リスト名を変更'**
  String get random_image_change_list_name;

  /// No description provided for @random_image_change_list_name_dialog.
  ///
  /// In ja, this message translates to:
  /// **'リスト名を変更'**
  String get random_image_change_list_name_dialog;

  /// No description provided for @random_image_change_list_name_hint.
  ///
  /// In ja, this message translates to:
  /// **'リスト名を入力'**
  String get random_image_change_list_name_hint;

  /// No description provided for @random_image_change_list_name_confirm.
  ///
  /// In ja, this message translates to:
  /// **'変更'**
  String get random_image_change_list_name_confirm;

  /// No description provided for @random_image_delete_list.
  ///
  /// In ja, this message translates to:
  /// **'リストを削除'**
  String get random_image_delete_list;

  /// No description provided for @random_image_delete_list_dialog.
  ///
  /// In ja, this message translates to:
  /// **'このリストを削除しますか？'**
  String get random_image_delete_list_dialog;

  /// No description provided for @random_image_delete_list_dialog_description.
  ///
  /// In ja, this message translates to:
  /// **'リスト内のアイテムも削除されます。'**
  String get random_image_delete_list_dialog_description;

  /// No description provided for @random_image_delete_list_confirm.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get random_image_delete_list_confirm;

  /// No description provided for @premium_detail_premium_title.
  ///
  /// In ja, this message translates to:
  /// **'ArchiVe Premium'**
  String get premium_detail_premium_title;

  /// No description provided for @premium_detail_premium_item01.
  ///
  /// In ja, this message translates to:
  /// **'無制限の保存数'**
  String get premium_detail_premium_item01;

  /// No description provided for @premium_detail_premium_item02.
  ///
  /// In ja, this message translates to:
  /// **'テーマカラー ゴールドを追加'**
  String get premium_detail_premium_item02;

  /// No description provided for @premium_detail_premium_item03.
  ///
  /// In ja, this message translates to:
  /// **'画像を自由に追加'**
  String get premium_detail_premium_item03;

  /// No description provided for @premium_detail_premium_item04.
  ///
  /// In ja, this message translates to:
  /// **'複数のタグで素早く検索'**
  String get premium_detail_premium_item04;

  /// No description provided for @premium_detail_premium_item05.
  ///
  /// In ja, this message translates to:
  /// **'ジャンル別・評価別にデータを可視化する統計機能'**
  String get premium_detail_premium_item05;

  /// No description provided for @premium_detail_premium_item06.
  ///
  /// In ja, this message translates to:
  /// **'広告の非表示'**
  String get premium_detail_premium_item06;

  /// No description provided for @premium_detail_note.
  ///
  /// In ja, this message translates to:
  /// **'3日間の無料トライアル後、自動的に課金されます。\nいつでもキャンセルできます。'**
  String get premium_detail_note;

  /// No description provided for @premium_detail_restore_not_found.
  ///
  /// In ja, this message translates to:
  /// **'購入履歴が見つかりませんでした'**
  String get premium_detail_restore_not_found;

  /// No description provided for @premium_detail_free_trial_badge.
  ///
  /// In ja, this message translates to:
  /// **'3日間無料'**
  String get premium_detail_free_trial_badge;

  /// No description provided for @premium_detail_start_trial.
  ///
  /// In ja, this message translates to:
  /// **'3日間無料で開始'**
  String get premium_detail_start_trial;

  /// No description provided for @premium_detail_price_after_trial.
  ///
  /// In ja, this message translates to:
  /// **'その後 {price} / 月'**
  String premium_detail_price_after_trial(Object price);

  /// No description provided for @premium_detail_restore_button.
  ///
  /// In ja, this message translates to:
  /// **'購入を復元'**
  String get premium_detail_restore_button;

  /// No description provided for @premium_detail_purchase_complete.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムを購入しました！'**
  String get premium_detail_purchase_complete;

  /// No description provided for @premium_detail_restart_message.
  ///
  /// In ja, this message translates to:
  /// **'プレミアム機能が有効になりました。\nアプリを再起動します。'**
  String get premium_detail_restart_message;

  /// No description provided for @tutorial.
  ///
  /// In ja, this message translates to:
  /// **'チュートリアル'**
  String get tutorial;

  /// No description provided for @tutorial_01.
  ///
  /// In ja, this message translates to:
  /// **'まずはリストを作成しましょう。'**
  String get tutorial_01;

  /// No description provided for @tutorial_02.
  ///
  /// In ja, this message translates to:
  /// **'作ったリストを開きましょう。'**
  String get tutorial_02;

  /// No description provided for @tutorial_03.
  ///
  /// In ja, this message translates to:
  /// **'＋ボタンから作品を追加しましょう'**
  String get tutorial_03;

  /// No description provided for @tutorial_04.
  ///
  /// In ja, this message translates to:
  /// **'まずは動画や作品のURLを入力します。'**
  String get tutorial_04;

  /// No description provided for @tutorial_05.
  ///
  /// In ja, this message translates to:
  /// **'このボタンでタイトルを自動取得できます。'**
  String get tutorial_05;

  /// No description provided for @tutorial_06.
  ///
  /// In ja, this message translates to:
  /// **'最後に保存してリストに追加しましょう。'**
  String get tutorial_06;

  /// No description provided for @start_tutorial_dialog.
  ///
  /// In ja, this message translates to:
  /// **'チュートリアルを\n再表示しますか？'**
  String get start_tutorial_dialog;

  /// No description provided for @start_tutorial_dialog_description.
  ///
  /// In ja, this message translates to:
  /// **'リスト作成からの手順をもう一度表示します。'**
  String get start_tutorial_dialog_description;

  /// No description provided for @completed_tutorial.
  ///
  /// In ja, this message translates to:
  /// **'チュートリアル完了！\nお疲れ様でした。'**
  String get completed_tutorial;

  /// No description provided for @tutorial_list_name.
  ///
  /// In ja, this message translates to:
  /// **'あとで見る'**
  String get tutorial_list_name;

  /// No description provided for @tutorial_slide_title_01.
  ///
  /// In ja, this message translates to:
  /// **'ダウンロード不要の\n動画管理アプリ'**
  String get tutorial_slide_title_01;

  /// No description provided for @tutorial_slide_dict_01.
  ///
  /// In ja, this message translates to:
  /// **'容量を使わず好きなだけ動画を収集'**
  String get tutorial_slide_dict_01;

  /// No description provided for @tutorial_slide_image_01.
  ///
  /// In ja, this message translates to:
  /// **'assets/tutorial/japanese01.png'**
  String get tutorial_slide_image_01;

  /// No description provided for @tutorial_slide_title_02.
  ///
  /// In ja, this message translates to:
  /// **'【簡単2ステップ】\n①URLをコピー'**
  String get tutorial_slide_title_02;

  /// No description provided for @tutorial_slide_dict_02.
  ///
  /// In ja, this message translates to:
  /// **'動画サイトの共有リンクやブラウザのURLをコピー'**
  String get tutorial_slide_dict_02;

  /// No description provided for @tutorial_slide_image_02.
  ///
  /// In ja, this message translates to:
  /// **'assets/tutorial/japanese02.png'**
  String get tutorial_slide_image_02;

  /// No description provided for @tutorial_slide_title_03.
  ///
  /// In ja, this message translates to:
  /// **'【簡単2ステップ】\n②コピーしたURLを保存'**
  String get tutorial_slide_title_03;

  /// No description provided for @tutorial_slide_dict_03.
  ///
  /// In ja, this message translates to:
  /// **'貼るだけで登録\n評価・タグ・メモも追加可能'**
  String get tutorial_slide_dict_03;

  /// No description provided for @tutorial_slide_image_03.
  ///
  /// In ja, this message translates to:
  /// **'assets/tutorial/japanese03.png'**
  String get tutorial_slide_image_03;

  /// No description provided for @tutorial_slide_title_04.
  ///
  /// In ja, this message translates to:
  /// **'アプリ内検索'**
  String get tutorial_slide_title_04;

  /// No description provided for @tutorial_slide_dict_04.
  ///
  /// In ja, this message translates to:
  /// **'保存した動画がタイトル・タグですぐ見つかる。'**
  String get tutorial_slide_dict_04;

  /// No description provided for @tutorial_slide_image_04.
  ///
  /// In ja, this message translates to:
  /// **'assets/tutorial/japanese04.png'**
  String get tutorial_slide_image_04;

  /// No description provided for @tutorial_slide_title_05.
  ///
  /// In ja, this message translates to:
  /// **'ウェブ検索'**
  String get tutorial_slide_title_05;

  /// No description provided for @tutorial_slide_dict_05.
  ///
  /// In ja, this message translates to:
  /// **'アプリ内ブラウザで、探してすぐに保存'**
  String get tutorial_slide_dict_05;

  /// No description provided for @tutorial_slide_image_05.
  ///
  /// In ja, this message translates to:
  /// **'assets/tutorial/japanese05.png'**
  String get tutorial_slide_image_05;

  /// No description provided for @tutorial_slide_title_06.
  ///
  /// In ja, this message translates to:
  /// **'可能性は無限大'**
  String get tutorial_slide_title_06;

  /// No description provided for @tutorial_slide_dict_06.
  ///
  /// In ja, this message translates to:
  /// **'自分だけの動画コレクションを作ろう！'**
  String get tutorial_slide_dict_06;

  /// No description provided for @tutorial_slide_image_06.
  ///
  /// In ja, this message translates to:
  /// **'assets/tutorial/japanese06.png'**
  String get tutorial_slide_image_06;

  /// No description provided for @tutorial_slide_next.
  ///
  /// In ja, this message translates to:
  /// **'次へ'**
  String get tutorial_slide_next;

  /// No description provided for @tutorial_slide_start.
  ///
  /// In ja, this message translates to:
  /// **'開始する'**
  String get tutorial_slide_start;

  /// No description provided for @share_saved.
  ///
  /// In ja, this message translates to:
  /// **'共有から保存しました'**
  String get share_saved;

  /// No description provided for @share_already_saved.
  ///
  /// In ja, this message translates to:
  /// **'このURLはすでに保存されています'**
  String get share_already_saved;

  /// No description provided for @share_dialog_title.
  ///
  /// In ja, this message translates to:
  /// **'ArchiVe に保存'**
  String get share_dialog_title;

  /// No description provided for @share_list_section.
  ///
  /// In ja, this message translates to:
  /// **'保存先リスト'**
  String get share_list_section;

  /// No description provided for @share_title_hint.
  ///
  /// In ja, this message translates to:
  /// **'タイトルを入力'**
  String get share_title_hint;

  /// No description provided for @clipboard_dialog_title.
  ///
  /// In ja, this message translates to:
  /// **'クリップボードのURLを追加しますか？'**
  String get clipboard_dialog_title;

  /// No description provided for @ranking_page_add_item.
  ///
  /// In ja, this message translates to:
  /// **'アイテムを追加'**
  String get ranking_page_add_item;

  /// No description provided for @search_page_url_cant_open.
  ///
  /// In ja, this message translates to:
  /// **'このURLは開けません'**
  String get search_page_url_cant_open;

  /// No description provided for @premium_detail_plan_monthly.
  ///
  /// In ja, this message translates to:
  /// **'月額プラン'**
  String get premium_detail_plan_monthly;

  /// No description provided for @premium_detail_plan_annual.
  ///
  /// In ja, this message translates to:
  /// **'年額プラン'**
  String get premium_detail_plan_annual;

  /// No description provided for @premium_detail_best_value.
  ///
  /// In ja, this message translates to:
  /// **'お得'**
  String get premium_detail_best_value;

  /// No description provided for @premium_detail_save_percent.
  ///
  /// In ja, this message translates to:
  /// **'{percent}% OFF'**
  String premium_detail_save_percent(String percent);

  /// No description provided for @premium_detail_per_month.
  ///
  /// In ja, this message translates to:
  /// **'/月'**
  String get premium_detail_per_month;

  /// No description provided for @premium_detail_per_year.
  ///
  /// In ja, this message translates to:
  /// **'/年'**
  String get premium_detail_per_year;

  /// No description provided for @premium_detail_price_after_trial_yearly.
  ///
  /// In ja, this message translates to:
  /// **'その後 {price} / 年'**
  String premium_detail_price_after_trial_yearly(String price);

  /// No description provided for @settings_page_free_plan.
  ///
  /// In ja, this message translates to:
  /// **'無料プラン'**
  String get settings_page_free_plan;

  /// No description provided for @settings_page_current_plan.
  ///
  /// In ja, this message translates to:
  /// **'現在のプラン'**
  String get settings_page_current_plan;

  /// No description provided for @settings_page_premium_details_link.
  ///
  /// In ja, this message translates to:
  /// **'保存数上限の解放、その他の詳細はこちら'**
  String get settings_page_premium_details_link;

  /// No description provided for @settings_page_section_appearance.
  ///
  /// In ja, this message translates to:
  /// **'外観'**
  String get settings_page_section_appearance;

  /// No description provided for @settings_page_section_about.
  ///
  /// In ja, this message translates to:
  /// **'アプリについて'**
  String get settings_page_section_about;

  /// No description provided for @settings_page_section_legal.
  ///
  /// In ja, this message translates to:
  /// **'法的情報'**
  String get settings_page_section_legal;

  /// No description provided for @settings_page_period_monthly.
  ///
  /// In ja, this message translates to:
  /// **'月額'**
  String get settings_page_period_monthly;

  /// No description provided for @settings_page_period_annual.
  ///
  /// In ja, this message translates to:
  /// **'年額'**
  String get settings_page_period_annual;

  /// No description provided for @settings_page_theme_color_pink.
  ///
  /// In ja, this message translates to:
  /// **'ピンク'**
  String get settings_page_theme_color_pink;

  /// No description provided for @settings_page_theme_color_purple.
  ///
  /// In ja, this message translates to:
  /// **'パープル'**
  String get settings_page_theme_color_purple;

  /// No description provided for @settings_page_theme_color_teal.
  ///
  /// In ja, this message translates to:
  /// **'ティール'**
  String get settings_page_theme_color_teal;

  /// No description provided for @login_page_title.
  ///
  /// In ja, this message translates to:
  /// **'サインイン'**
  String get login_page_title;

  /// No description provided for @login_page_description.
  ///
  /// In ja, this message translates to:
  /// **'ArchiVe Pro の機能を使うには、サインインしてください。'**
  String get login_page_description;

  /// No description provided for @login_with_apple.
  ///
  /// In ja, this message translates to:
  /// **'Appleでサインイン'**
  String get login_with_apple;

  /// No description provided for @login_with_google.
  ///
  /// In ja, this message translates to:
  /// **'Googleでサインイン'**
  String get login_with_google;

  /// No description provided for @login_failed.
  ///
  /// In ja, this message translates to:
  /// **'サインインに失敗しました'**
  String get login_failed;

  /// No description provided for @logout.
  ///
  /// In ja, this message translates to:
  /// **'サインアウト'**
  String get logout;

  /// No description provided for @logout_confirm.
  ///
  /// In ja, this message translates to:
  /// **'サインアウトしますか？'**
  String get logout_confirm;

  /// No description provided for @settings_page_section_account.
  ///
  /// In ja, this message translates to:
  /// **'アカウント'**
  String get settings_page_section_account;

  /// No description provided for @settings_page_not_signed_in.
  ///
  /// In ja, this message translates to:
  /// **'サインインしていません'**
  String get settings_page_not_signed_in;

  /// No description provided for @pro_detail_title.
  ///
  /// In ja, this message translates to:
  /// **'ArchiVe Pro'**
  String get pro_detail_title;

  /// No description provided for @pro_detail_subtitle.
  ///
  /// In ja, this message translates to:
  /// **'プレミアム全機能に加えて、以下が利用可能'**
  String get pro_detail_subtitle;

  /// No description provided for @pro_detail_feature_cloud_sync.
  ///
  /// In ja, this message translates to:
  /// **'クラウド同期（複数端末）'**
  String get pro_detail_feature_cloud_sync;

  /// No description provided for @pro_detail_feature_ai_tagging.
  ///
  /// In ja, this message translates to:
  /// **'AI自動タグ付け'**
  String get pro_detail_feature_ai_tagging;

  /// No description provided for @pro_detail_feature_ai_recommend.
  ///
  /// In ja, this message translates to:
  /// **'AIおすすめキーワード'**
  String get pro_detail_feature_ai_recommend;

  /// No description provided for @pro_detail_feature_monthly_report.
  ///
  /// In ja, this message translates to:
  /// **'AI月次レポート'**
  String get pro_detail_feature_monthly_report;

  /// No description provided for @pro_detail_feature_public_sharing.
  ///
  /// In ja, this message translates to:
  /// **'公開リスト共有'**
  String get pro_detail_feature_public_sharing;

  /// No description provided for @pro_detail_feature_theme_teal.
  ///
  /// In ja, this message translates to:
  /// **'テーマカラー ティールを追加'**
  String get pro_detail_feature_theme_teal;

  /// No description provided for @plans_page_title.
  ///
  /// In ja, this message translates to:
  /// **'プラン'**
  String get plans_page_title;

  /// No description provided for @plans_page_current_badge.
  ///
  /// In ja, this message translates to:
  /// **'現在'**
  String get plans_page_current_badge;

  /// No description provided for @plans_page_includes_premium.
  ///
  /// In ja, this message translates to:
  /// **'Premium全機能を含む'**
  String get plans_page_includes_premium;

  /// No description provided for @detail_page_ai_suggest.
  ///
  /// In ja, this message translates to:
  /// **'AIでタグ提案'**
  String get detail_page_ai_suggest;

  /// No description provided for @detail_page_ai_suggest_dialog_title.
  ///
  /// In ja, this message translates to:
  /// **'AIタグの提案'**
  String get detail_page_ai_suggest_dialog_title;

  /// No description provided for @detail_page_ai_suggest_dialog_hint.
  ///
  /// In ja, this message translates to:
  /// **'おすすめのタグはこちらです！適用するタグを選択してください。'**
  String get detail_page_ai_suggest_dialog_hint;

  /// No description provided for @detail_page_ai_apply.
  ///
  /// In ja, this message translates to:
  /// **'適用'**
  String get detail_page_ai_apply;

  /// No description provided for @detail_page_ai_no_suggestions.
  ///
  /// In ja, this message translates to:
  /// **'提案タグはありませんでした'**
  String get detail_page_ai_no_suggestions;

  /// No description provided for @detail_page_ai_from_library.
  ///
  /// In ja, this message translates to:
  /// **'既存のタグから'**
  String get detail_page_ai_from_library;

  /// No description provided for @detail_page_ai_daily_limit_title.
  ///
  /// In ja, this message translates to:
  /// **'本日の AI 利用上限に達しました'**
  String get detail_page_ai_daily_limit_title;

  /// No description provided for @detail_page_ai_daily_limit_body.
  ///
  /// In ja, this message translates to:
  /// **'AI タグ提案は無料版 / Premium プランで 1 日 1 回までご利用いただけます。\nPro プランなら無制限に使えます。'**
  String get detail_page_ai_daily_limit_body;

  /// No description provided for @detail_page_ai_upgrade_pro.
  ///
  /// In ja, this message translates to:
  /// **'Pro プランを見る'**
  String get detail_page_ai_upgrade_pro;

  /// No description provided for @detail_page_ai_loading.
  ///
  /// In ja, this message translates to:
  /// **'AIで分析中...'**
  String get detail_page_ai_loading;

  /// No description provided for @detail_page_ai_error.
  ///
  /// In ja, this message translates to:
  /// **'AIタグ提案エラー'**
  String get detail_page_ai_error;

  /// No description provided for @share_title.
  ///
  /// In ja, this message translates to:
  /// **'リストを共有'**
  String get share_title;

  /// No description provided for @share_loading.
  ///
  /// In ja, this message translates to:
  /// **'共有中...'**
  String get share_loading;

  /// No description provided for @share_url_label.
  ///
  /// In ja, this message translates to:
  /// **'共有URL'**
  String get share_url_label;

  /// No description provided for @share_copy.
  ///
  /// In ja, this message translates to:
  /// **'コピー'**
  String get share_copy;

  /// No description provided for @share_copied.
  ///
  /// In ja, this message translates to:
  /// **'コピーしました'**
  String get share_copied;

  /// No description provided for @share_unshare.
  ///
  /// In ja, this message translates to:
  /// **'共有を解除'**
  String get share_unshare;

  /// No description provided for @share_unshare_confirm.
  ///
  /// In ja, this message translates to:
  /// **'このリストの共有を解除しますか？'**
  String get share_unshare_confirm;

  /// No description provided for @share_create_action.
  ///
  /// In ja, this message translates to:
  /// **'このリストを共有する'**
  String get share_create_action;

  /// No description provided for @share_error.
  ///
  /// In ja, this message translates to:
  /// **'共有エラー'**
  String get share_error;

  /// No description provided for @share_open_url.
  ///
  /// In ja, this message translates to:
  /// **'共有URLを開く'**
  String get share_open_url;

  /// No description provided for @share_description.
  ///
  /// In ja, this message translates to:
  /// **'共有URLをこのリストの内容を誰でも閲覧できます（読み取り専用）'**
  String get share_description;

  /// No description provided for @share_limit_notice.
  ///
  /// In ja, this message translates to:
  /// **'最大200件まで共有されます'**
  String get share_limit_notice;

  /// No description provided for @analytics_monthly_report_title.
  ///
  /// In ja, this message translates to:
  /// **'AIサマリー'**
  String get analytics_monthly_report_title;

  /// No description provided for @analytics_monthly_report_subtitle.
  ///
  /// In ja, this message translates to:
  /// **'{month}月のまとめ'**
  String analytics_monthly_report_subtitle(int month);

  /// No description provided for @analytics_monthly_report_generate.
  ///
  /// In ja, this message translates to:
  /// **'まとめを生成'**
  String get analytics_monthly_report_generate;

  /// No description provided for @analytics_monthly_report_regenerate.
  ///
  /// In ja, this message translates to:
  /// **'再生成'**
  String get analytics_monthly_report_regenerate;

  /// No description provided for @analytics_monthly_report_loading.
  ///
  /// In ja, this message translates to:
  /// **'AIが分析しています...'**
  String get analytics_monthly_report_loading;

  /// No description provided for @analytics_monthly_report_empty.
  ///
  /// In ja, this message translates to:
  /// **'ボタンを押すと、今月のアーカイブ活動を AI が要約します。'**
  String get analytics_monthly_report_empty;

  /// No description provided for @analytics_monthly_report_error.
  ///
  /// In ja, this message translates to:
  /// **'レポート生成エラー'**
  String get analytics_monthly_report_error;

  /// No description provided for @analytics_monthly_report_cached.
  ///
  /// In ja, this message translates to:
  /// **'キャッシュから表示'**
  String get analytics_monthly_report_cached;

  /// No description provided for @search_result_loading.
  ///
  /// In ja, this message translates to:
  /// **'読み込み中'**
  String get search_result_loading;

  /// No description provided for @grid_page_move_action.
  ///
  /// In ja, this message translates to:
  /// **'移動'**
  String get grid_page_move_action;

  /// No description provided for @grid_page_move_to_list_title.
  ///
  /// In ja, this message translates to:
  /// **'移動先のリストを選択'**
  String get grid_page_move_to_list_title;

  /// No description provided for @grid_page_move_done.
  ///
  /// In ja, this message translates to:
  /// **'件を移動しました'**
  String get grid_page_move_done;

  /// No description provided for @undo.
  ///
  /// In ja, this message translates to:
  /// **'取り消し'**
  String get undo;

  /// No description provided for @settings_page_theme_color_gold.
  ///
  /// In ja, this message translates to:
  /// **'ゴールド'**
  String get settings_page_theme_color_gold;

  /// No description provided for @plans_page_premium_short.
  ///
  /// In ja, this message translates to:
  /// **'プレミアム'**
  String get plans_page_premium_short;

  /// No description provided for @plans_page_pro_short.
  ///
  /// In ja, this message translates to:
  /// **'Pro'**
  String get plans_page_pro_short;

  /// No description provided for @plans_page_free_short.
  ///
  /// In ja, this message translates to:
  /// **'無料'**
  String get plans_page_free_short;

  /// No description provided for @plans_page_free_price.
  ///
  /// In ja, this message translates to:
  /// **'¥0'**
  String get plans_page_free_price;

  /// No description provided for @plans_page_free_item01.
  ///
  /// In ja, this message translates to:
  /// **'100件まで保存可能'**
  String get plans_page_free_item01;

  /// No description provided for @plans_page_free_item02.
  ///
  /// In ja, this message translates to:
  /// **'広告視聴で15枠/日 拡張可能'**
  String get plans_page_free_item02;

  /// No description provided for @plans_page_free_item03.
  ///
  /// In ja, this message translates to:
  /// **'単一のタグで検索'**
  String get plans_page_free_item03;

  /// No description provided for @plans_page_free_item04.
  ///
  /// In ja, this message translates to:
  /// **'広告表示'**
  String get plans_page_free_item04;

  /// No description provided for @share_pro_required_title.
  ///
  /// In ja, this message translates to:
  /// **'Pro プラン限定機能'**
  String get share_pro_required_title;

  /// No description provided for @share_pro_required_description.
  ///
  /// In ja, this message translates to:
  /// **'公開リスト共有はProプランの購入が必要です。'**
  String get share_pro_required_description;

  /// No description provided for @share_pro_required_action.
  ///
  /// In ja, this message translates to:
  /// **'Proプランを見る'**
  String get share_pro_required_action;

  /// No description provided for @pro_locked_badge.
  ///
  /// In ja, this message translates to:
  /// **'Pro限定'**
  String get pro_locked_badge;

  /// No description provided for @pro_locked_unlock.
  ///
  /// In ja, this message translates to:
  /// **'Proで解除'**
  String get pro_locked_unlock;

  /// No description provided for @apple_signin_warning_title.
  ///
  /// In ja, this message translates to:
  /// **'Apple アカウントでサインインしますか？'**
  String get apple_signin_warning_title;

  /// No description provided for @apple_signin_warning_description.
  ///
  /// In ja, this message translates to:
  /// **'Apple アカウントは Android 端末ではサインインできず、データを共有できません。複数端末で共有する場合は Google アカウントをお勧めします。'**
  String get apple_signin_warning_description;

  /// No description provided for @apple_signin_warning_continue.
  ///
  /// In ja, this message translates to:
  /// **'Apple で続行'**
  String get apple_signin_warning_continue;

  /// No description provided for @settings_page_manage_subscription.
  ///
  /// In ja, this message translates to:
  /// **'サブスクリプションを管理'**
  String get settings_page_manage_subscription;

  /// No description provided for @search_page_ai_recommend_title.
  ///
  /// In ja, this message translates to:
  /// **'AIおすすめ'**
  String get search_page_ai_recommend_title;

  /// No description provided for @search_page_ai_recommend_subtitle.
  ///
  /// In ja, this message translates to:
  /// **'ライブラリ傾向から関連キーワードを提案'**
  String get search_page_ai_recommend_subtitle;

  /// No description provided for @search_page_ai_recommend_generate.
  ///
  /// In ja, this message translates to:
  /// **'おすすめを取得'**
  String get search_page_ai_recommend_generate;

  /// No description provided for @search_page_ai_recommend_refresh.
  ///
  /// In ja, this message translates to:
  /// **'再生成'**
  String get search_page_ai_recommend_refresh;

  /// No description provided for @search_page_ai_recommend_loading.
  ///
  /// In ja, this message translates to:
  /// **'AIが分析しています...'**
  String get search_page_ai_recommend_loading;

  /// No description provided for @search_page_ai_recommend_error.
  ///
  /// In ja, this message translates to:
  /// **'おすすめ取得エラー'**
  String get search_page_ai_recommend_error;

  /// No description provided for @search_page_ai_recommend_empty.
  ///
  /// In ja, this message translates to:
  /// **'保存したアイテムが少ないため提案できません。アイテムを追加してから再度お試しください。'**
  String get search_page_ai_recommend_empty;

  /// No description provided for @search_page_ai_recommend_intro.
  ///
  /// In ja, this message translates to:
  /// **'ボタンを押すと、保存ライブラリの傾向から関連キーワードをAIが提案します。'**
  String get search_page_ai_recommend_intro;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'pt',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return L10nZhHans();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return L10nDe();
    case 'en':
      return L10nEn();
    case 'es':
      return L10nEs();
    case 'fr':
      return L10nFr();
    case 'ja':
      return L10nJa();
    case 'ko':
      return L10nKo();
    case 'pt':
      return L10nPt();
    case 'zh':
      return L10nZh();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
