import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

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
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @app_title.
  ///
  /// In ja, this message translates to:
  /// **'ArchiVe'**
  String get app_title;

  /// No description provided for @version.
  ///
  /// In ja, this message translates to:
  /// **'v1.7'**
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

  /// No description provided for @save_limit_dialog_title.
  ///
  /// In ja, this message translates to:
  /// **'保存数の上限に達しました。'**
  String get save_limit_dialog_title;

  /// No description provided for @save_limit_dialog_description.
  ///
  /// In ja, this message translates to:
  /// **'現在の作品の保存枠は最大{limit} 件です。\n\n現在の作品数：{count} 件\n\n{limit} 件以上保存するには、\n・既存の作品を削除いただく\n・プレミアムプランをご利用いただく\n・設定ページから広告を視聴して保存枠を増やす'**
  String save_limit_dialog_description(Object count, Object limit);

  /// No description provided for @save_limit_dialog_already_purchased.
  ///
  /// In ja, this message translates to:
  /// **'既に購入済みです。'**
  String get save_limit_dialog_already_purchased;

  /// No description provided for @save_limit_dialog_premium_detail.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムの詳細'**
  String get save_limit_dialog_premium_detail;

  /// No description provided for @main_page_lists.
  ///
  /// In ja, this message translates to:
  /// **'リスト'**
  String get main_page_lists;

  /// No description provided for @main_page_search.
  ///
  /// In ja, this message translates to:
  /// **'検索・収集'**
  String get main_page_search;

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
  /// **'画像を追加★'**
  String get detail_page_add_image;

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
  /// **'「ArchiVe - お気に入り動画記録帳」を気に入っていただけましたか？'**
  String get detail_page_review_confirm01;

  /// No description provided for @detail_page_review_confirm02.
  ///
  /// In ja, this message translates to:
  /// **'もしよろしければ、ぜひご感想をお聞かせください。'**
  String get detail_page_review_confirm02;

  /// No description provided for @detail_page_mail_subject.
  ///
  /// In ja, this message translates to:
  /// **'subject=ArchiVe ご意見・ご要望'**
  String get detail_page_mail_subject;

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
  /// **'検索ワード'**
  String get search_page_search_word;

  /// No description provided for @search_page_select_site.
  ///
  /// In ja, this message translates to:
  /// **'サイトで絞る'**
  String get search_page_select_site;

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

  /// No description provided for @search_result_page_save_as_item.
  ///
  /// In ja, this message translates to:
  /// **'作品を保存しました'**
  String get search_result_page_save_as_item;

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

  /// No description provided for @search_result_page_delete_site.
  ///
  /// In ja, this message translates to:
  /// **'「{siteName}」をお気に入りから削除しますか？'**
  String search_result_page_delete_site(Object siteName);

  /// No description provided for @analytics.
  ///
  /// In ja, this message translates to:
  /// **'統計'**
  String get analytics;

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
  /// **'テーマカラー★'**
  String get settings_page_theme_color;

  /// No description provided for @settings_page_theme_color_orange.
  ///
  /// In ja, this message translates to:
  /// **'オレンジ'**
  String get settings_page_theme_color_orange;

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
  /// **'作品保存数の状態'**
  String get settings_page_save_status;

  /// No description provided for @settings_page_save_count.
  ///
  /// In ja, this message translates to:
  /// **'保存数'**
  String get settings_page_save_count;

  /// No description provided for @settings_page_watch_count.
  ///
  /// In ja, this message translates to:
  /// **'本日の視聴回数'**
  String get settings_page_watch_count;

  /// No description provided for @settings_page_watch_ad_today.
  ///
  /// In ja, this message translates to:
  /// **'{watchedAdsToday} / 3 回'**
  String settings_page_watch_ad_today(Object watchedAdsToday);

  /// No description provided for @settings_page_watch_ad.
  ///
  /// In ja, this message translates to:
  /// **'広告を見て +5 枠'**
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
  /// **'保存枠が +5 されました'**
  String get settings_page_save_count_increased;

  /// No description provided for @view_counter_view_count.
  ///
  /// In ja, this message translates to:
  /// **'視聴回数:{viewCount}'**
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

  /// No description provided for @premium_detail_purchase_complete.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムを購入しました！'**
  String get premium_detail_purchase_complete;

  /// No description provided for @premium_detail_purchase_incomplete.
  ///
  /// In ja, this message translates to:
  /// **'購入は完了しましたが、プレミアムが有効化されませんでした'**
  String get premium_detail_purchase_incomplete;

  /// No description provided for @premium_detail_no_item.
  ///
  /// In ja, this message translates to:
  /// **'購入可能なプランが見つかりません'**
  String get premium_detail_no_item;

  /// No description provided for @premium_detail_ex.
  ///
  /// In ja, this message translates to:
  /// **'購入エラー: {ex}'**
  String premium_detail_ex(Object ex);

  /// No description provided for @premium_detail_premium_title.
  ///
  /// In ja, this message translates to:
  /// **'ArchiVe Premium'**
  String get premium_detail_premium_title;

  /// No description provided for @premium_detail_premium_item01.
  ///
  /// In ja, this message translates to:
  /// **'広告なしで快適に利用'**
  String get premium_detail_premium_item01;

  /// No description provided for @premium_detail_premium_item02.
  ///
  /// In ja, this message translates to:
  /// **'テーマカラーを自由に変更'**
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
  /// **'保存数は無制限'**
  String get premium_detail_premium_item05;

  /// No description provided for @premium_detail_premium_item06.
  ///
  /// In ja, this message translates to:
  /// **'ジャンル別・評価別にデータを可視化'**
  String get premium_detail_premium_item06;

  /// No description provided for @premium_detail_price.
  ///
  /// In ja, this message translates to:
  /// **'¥170 / 月で始める'**
  String get premium_detail_price;

  /// No description provided for @premium_detail_note.
  ///
  /// In ja, this message translates to:
  /// **'いつでもキャンセル可能'**
  String get premium_detail_note;

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
  /// **'assets/tutorial/Japanese01.png'**
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
  /// **'assets/tutorial/Japanese02.png'**
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
  /// **'assets/tutorial/Japanese03.png'**
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
  /// **'assets/tutorial/Japanese04.png'**
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
  /// **'assets/tutorial/Japanese05.png'**
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
  /// **'assets/tutorial/Japanese06.png'**
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
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'ja':
      return L10nJa();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
