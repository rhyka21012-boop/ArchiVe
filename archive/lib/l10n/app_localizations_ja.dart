// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class L10nJa extends L10n {
  L10nJa([String locale = 'ja']) : super(locale);

  @override
  String get app_title => 'ArchiVe';

  @override
  String get version => 'v1.7';

  @override
  String get critical => 'クリティカル';

  @override
  String get normal => 'ノーマル';

  @override
  String get maniac => 'マニアック';

  @override
  String get unrated => '未評価';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'キャンセル';

  @override
  String get back => '戻る';

  @override
  String get add => '追加';

  @override
  String get delete => '削除';

  @override
  String get save => '保存';

  @override
  String get reload => '再読み込み';

  @override
  String get all_item_list_name => '全てのアイテム';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get clear => 'クリア';

  @override
  String get favorite => 'お気に入り';

  @override
  String get url => 'URL';

  @override
  String get title => 'タイトル';

  @override
  String get no_select => '選択なし';

  @override
  String get modify => '編集';

  @override
  String get close => '閉じる';

  @override
  String get save_limit_dialog_title => '保存数の上限に達しました。';

  @override
  String save_limit_dialog_description(Object count, Object limit) {
    return '現在の作品の保存枠は最大$limit 件です。\n\n現在の作品数：$count 件\n\n$limit 件以上保存するには、\n・既存の作品を削除いただく\n・プレミアムプランをご利用いただく\n・設定ページから広告を視聴して保存枠を増やす';
  }

  @override
  String get save_limit_dialog_already_purchased => '既に購入済みです。';

  @override
  String get save_limit_dialog_premium_detail => 'プレミアムの詳細';

  @override
  String get main_page_lists => 'リスト';

  @override
  String get main_page_search => '検索';

  @override
  String get main_page_analytics => '統計';

  @override
  String get main_page_settings => '設定';

  @override
  String get list_page_my_list => 'マイリスト';

  @override
  String get list_page_my_ranking => 'マイランキング';

  @override
  String get list_page_make_list => 'リストを作成';

  @override
  String get list_page_add_list => 'リストを追加';

  @override
  String get list_page_input_list_name => 'リスト名を入力';

  @override
  String get ranking_page_dragable => 'ドラッグして順番を変更できます';

  @override
  String get ranking_page_no_title => '（タイトルなし）';

  @override
  String get ranking_page_search_title => 'タイトルを検索';

  @override
  String get ranking_page_no_grid_item => '保存されたアイテムがありません';

  @override
  String get ranking_page_limit_error => '最大10個までしか追加できません';

  @override
  String get ranking_page_no_ranking_item => 'ランキングに作品がありません';

  @override
  String get ranking_page_no_ranking_item_description => '下の一覧から追加してください';

  @override
  String grid_page_item_count(Object length) {
    return '$length件';
  }

  @override
  String get grid_page_no_item => 'アイテムがありません';

  @override
  String get grid_page_cant_load_image => '画像を読み込めません';

  @override
  String get grid_page_no_title => '（タイトルなし）';

  @override
  String get grid_page_url_unable => '有効なURLではありません';

  @override
  String get grid_page_sort_title => 'タイトル順';

  @override
  String get grid_page_sort_new => '追加が新しい順';

  @override
  String get grid_page_sort_old => '追加が古い順';

  @override
  String get grid_page_sort_count_asc => '視聴回数が多い順';

  @override
  String get grid_page_sort_count_desc => '視聴回数が少ない順';

  @override
  String get detail_page_url_empty => 'URLが未入力です。';

  @override
  String get detail_page_input_url => 'URLを入力してください。';

  @override
  String get detail_page_url_changed => 'URLが変更されました。';

  @override
  String get detail_page_url_changed_note =>
      'URLを変更すると別のアイテムとして保存されます。\n続行しますか？';

  @override
  String get detail_page_no_selected => '選択なし';

  @override
  String get detail_page_item_detail => '作品詳細';

  @override
  String get detail_page_delete => '削除';

  @override
  String get detail_page_access => 'サイトへ';

  @override
  String get detail_page_modify => '編集';

  @override
  String get detail_page_save => '保存';

  @override
  String get detail_page_thumbnail_placeholder => '保存するとサムネイルが表示されます';

  @override
  String get detail_page_add_image => '画像を追加★';

  @override
  String get detail_page_rate => '評価';

  @override
  String get detail_page_title => 'タイトル';

  @override
  String get detail_page_title_placeholder => 'タイトル';

  @override
  String get detail_page_cast => '出演 (#で複数入力)';

  @override
  String get detail_page_cast_placeholder => '#出演1 #出演2 ...';

  @override
  String get detail_page_genre => 'ジャンル (#で複数入力)';

  @override
  String get detail_page_genre_placeholder => '#ジャンル1 #ジャンル2 ...';

  @override
  String get detail_page_series => 'シリーズ (#で複数入力)';

  @override
  String get detail_page_series_placeholder => '#シリーズ1 #シリーズ2 ...';

  @override
  String get detail_page_label => 'レーベル (#で複数入力)';

  @override
  String get detail_page_label_placeholder => '#レーベル1 #レーベル2 ...';

  @override
  String get detail_page_maker => 'メーカー (#で複数入力)';

  @override
  String get detail_page_maker_placeholder => '#メーカー1 #メーカー2 ...';

  @override
  String get detail_page_paste_url => 'URLをペースト';

  @override
  String get detail_page_fetch_title => 'URLからタイトルを取得';

  @override
  String get detail_page_list => 'リスト';

  @override
  String get detail_page_memo => 'メモ';

  @override
  String get detail_page_fetch_title_fail => 'タイトルが見つかりませんでした。';

  @override
  String get detail_page_fetch_page_fail => 'ページ取得に失敗しました。';

  @override
  String get detail_page_ex => 'エラーが発生しました。';

  @override
  String get detail_page_delete_confirm01 => '削除しますか？';

  @override
  String get detail_page_delete_confirm02 => '削除後は復元できません。';

  @override
  String get detail_page_url_unable => '有効なURLではありません';

  @override
  String get detail_page_review_confirm01 =>
      '「ArchiVe - お気に入り動画記録帳」を気に入っていただけましたか？';

  @override
  String get detail_page_review_confirm02 => 'もしよろしければ、ぜひご感想をお聞かせください。';

  @override
  String get detail_page_mail_subject => 'subject=ArchiVe ご意見・ご要望';

  @override
  String get search_page_cast => '出演';

  @override
  String get search_page_genre => 'ジャンル';

  @override
  String get search_page_series => 'シリーズ';

  @override
  String get search_page_label => 'レーベル';

  @override
  String get search_page_maker => 'メーカー';

  @override
  String get search_page_search => '検索';

  @override
  String get search_page_select_category => 'カテゴリを選択';

  @override
  String get search_page_more => 'もっと見る';

  @override
  String get search_page_fold => '折りたたむ';

  @override
  String get search_page_search_title => 'タイトルを検索';

  @override
  String get search_page_premium_title => '複数のタグを選択★';

  @override
  String get search_page_premium_description =>
      '複数のカテゴリを組み合わせた検索は\nプレミアムプラン限定の機能です。';

  @override
  String get search_page_segment_button_app => 'アプリ内';

  @override
  String get search_page_segment_button_web => 'Web';

  @override
  String get search_page_text_empty => '検索ワードを入力してください';

  @override
  String get search_page_web_title => 'Web検索';

  @override
  String get search_page_search_word => '検索ワード';

  @override
  String get search_page_select_site => 'サイトを選択';

  @override
  String get search_page_open_site => 'サイトを開く';

  @override
  String get search_page_modify_favorite => 'お気に入りを編集';

  @override
  String get search_page_site_name => 'サイト名';

  @override
  String get search_page_input_all => 'すべて入力してください';

  @override
  String get search_page_add_favorite => 'お気に入りサイトを追加';

  @override
  String get search_result_page_save_as_item => '作品を保存しました';

  @override
  String get search_result_page_site_saved => 'サイトを保存しました';

  @override
  String get search_result_page_saving_as_item => '作品を保存';

  @override
  String get search_result_page_saving_list => '保存先リスト';

  @override
  String get search_result_page_url_already_saved => 'このURLはすでに保存されています';

  @override
  String get analytics => '統計';

  @override
  String analytics_page_piechart_others(Object percent) {
    return 'その他\n$percent%';
  }

  @override
  String get analytics_page_view_count_top5 => '視聴回数 TOP5';

  @override
  String get analytics_page_no_data => 'データがありません';

  @override
  String get analytics_page_evaluation => '評価';

  @override
  String get analytics_page_cast => '出演';

  @override
  String get analytics_page_genre => 'ジャンル';

  @override
  String get analytics_page_series => 'シリーズ';

  @override
  String get analytics_page_label => 'レーベル';

  @override
  String get analytics_page_maker => 'メーカー';

  @override
  String get analytics_page_premium_title => '統計機能★';

  @override
  String get analytics_page_premium_description =>
      'ArchiVeプレミアムでは統計機能を利用できます。\n機能を使うにはアップグレードしてください。';

  @override
  String get analytics_page_premium_button => 'プレミアムの詳細をみる';

  @override
  String analytics_page_list_value(Object entry, Object percent) {
    return '$percent% ($entry件)';
  }

  @override
  String get analytics_page_count => '(回)';

  @override
  String analytics_page_toolchip_count(Object rod) {
    return '$rod回';
  }

  @override
  String get analytics_page_no_title => 'タイトルなし';

  @override
  String get analytics_page_item_count_top5 => 'アイテム数 TOP5';

  @override
  String get settings => '設定';

  @override
  String get settings_page_dark_mode => 'ダークモード';

  @override
  String get settings_page_theme_color => 'テーマカラー★';

  @override
  String get settings_page_theme_color_orange => 'オレンジ';

  @override
  String get settings_page_theme_color_green => 'グリーン';

  @override
  String get settings_page_theme_color_blue => 'ブルー';

  @override
  String get settings_page_theme_color_white => 'ホワイト';

  @override
  String get settings_page_theme_color_red => 'レッド';

  @override
  String get settings_page_theme_color_yellow => 'イエロー';

  @override
  String get settings_page_thumbnail_visibility => 'リスト画像の表示/非表示';

  @override
  String get settings_page_save_status => '作品保存数の状態';

  @override
  String get settings_page_save_count => '保存数';

  @override
  String get settings_page_watch_count => '本日の視聴回数';

  @override
  String settings_page_watch_ad_today(Object watchedAdsToday) {
    return '$watchedAdsToday / 3 回';
  }

  @override
  String get settings_page_watch_ad => '広告を見て +5 枠';

  @override
  String get settings_page_ad_limit_reached => '本日の広告視聴上限に達しました';

  @override
  String get settings_page_already_purchased => '既に購入済みです。';

  @override
  String get settings_page_premium => 'ArchiVe プレミアム';

  @override
  String get settings_page_app_version => 'アプリバージョン';

  @override
  String get settings_page_plivacy_policy => 'プライバシーポリシー';

  @override
  String get settings_page_disable_link => 'リンクを開けませんでした';

  @override
  String get settings_page_terms => '利用規約（Apple標準EULA）';

  @override
  String get settings_page_save_count_increased => '保存枠が +5 されました';

  @override
  String view_counter_view_count(Object viewCount) {
    return '視聴回数:$viewCount';
  }

  @override
  String get random_image_no_image => '画像を読み込めません';

  @override
  String get random_image_change_list_name => 'リスト名を変更';

  @override
  String get random_image_change_list_name_dialog => 'リスト名を変更';

  @override
  String get random_image_change_list_name_hint => 'リスト名を入力';

  @override
  String get random_image_change_list_name_confirm => '変更';

  @override
  String get random_image_delete_list => 'リストを削除';

  @override
  String get random_image_delete_list_dialog => 'このリストを削除しますか？';

  @override
  String get random_image_delete_list_dialog_description => 'リスト内のアイテムも削除されます。';

  @override
  String get random_image_delete_list_confirm => '削除';

  @override
  String get premium_detail_purchase_complete => 'プレミアムを購入しました！';

  @override
  String get premium_detail_purchase_incomplete =>
      '購入は完了しましたが、プレミアムが有効化されませんでした';

  @override
  String get premium_detail_no_item => '購入可能なプランが見つかりません';

  @override
  String premium_detail_ex(Object ex) {
    return '購入エラー: $ex';
  }

  @override
  String get premium_detail_premium_title => 'ArchiVe Premium';

  @override
  String get premium_detail_premium_item01 => '広告なしで快適に利用';

  @override
  String get premium_detail_premium_item02 => 'テーマカラーを自由に変更';

  @override
  String get premium_detail_premium_item03 => '画像を自由に追加';

  @override
  String get premium_detail_premium_item04 => '複数のタグで素早く検索';

  @override
  String get premium_detail_premium_item05 => '保存数は無制限';

  @override
  String get premium_detail_premium_item06 => 'ジャンル別・評価別にデータを可視化';

  @override
  String get premium_detail_price => '¥170 / 月で始める';

  @override
  String get premium_detail_note => 'いつでもキャンセル可能';

  @override
  String get tutorial => 'チュートリアル';

  @override
  String get tutorial_01 => 'まずはリストを作成しましょう。';

  @override
  String get tutorial_02 => '作ったリストを開きましょう。';

  @override
  String get tutorial_03 => '＋ボタンから作品を追加しましょう';

  @override
  String get tutorial_04 => 'まずは動画や作品のURLを入力します。';

  @override
  String get tutorial_05 => 'このボタンでタイトルを自動取得できます。';

  @override
  String get tutorial_06 => '最後に保存してリストに追加しましょう。';

  @override
  String get start_tutorial_dialog => 'チュートリアルを再表示しますか？';

  @override
  String get start_tutorial_dialog_description => 'リスト作成からの手順をもう一度表示します。';

  @override
  String get completed_tutorial => 'チュートリアル完了！\nお疲れ様でした。';

  @override
  String get tutorial_list_name => 'あとで見る';
}
