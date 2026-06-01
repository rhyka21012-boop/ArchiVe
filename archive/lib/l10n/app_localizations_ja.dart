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
  String get version => 'v2.0';

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
  String get skip => 'スキップ';

  @override
  String get save_limit_dialog_title => '保存数の上限に達しました。';

  @override
  String get save_limit_dialog_status_label => '保存済み';

  @override
  String get save_limit_dialog_premium_detail => 'プレミアムの詳細';

  @override
  String get save_limit_loading_ad => '広告を読み込み中です…';

  @override
  String get main_page_lists => 'リスト';

  @override
  String get main_page_search => '検索・収集';

  @override
  String get main_page_analytics => '統計';

  @override
  String get main_page_settings => '設定';

  @override
  String get main_page_update_info => 'アップデートのお知らせ';

  @override
  String get main_page_update_later => 'あとで';

  @override
  String get main_page_update_now => 'アップデート';

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
  String get grid_page_add_item => '追加方法を選択してください';

  @override
  String get grid_page_by_web => 'Web検索で追加';

  @override
  String get grid_page_by_manual => '手動で追加';

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
  String grid_page_items_selected_delete(Object count) {
    return '選択した$count件を削除しますか？';
  }

  @override
  String get grid_page_rating_guidance => '作品を評価するとここに表示されます';

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
  String get detail_page_access => 'ブラウザ';

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
  String get detail_page_review_confirm01 => 'ArchiVeを気に入っていただけましたか？';

  @override
  String get detail_page_review_confirm02 => 'レビューでの応援が励みになります。';

  @override
  String get detail_page_review_contact_support => 'ご意見・不具合を報告';

  @override
  String get detail_page_review_later => 'あとで';

  @override
  String get detail_page_review_now => 'レビューを書く';

  @override
  String get detail_page_mail_subject => 'subject=ArchiVe ご意見・ご要望';

  @override
  String get detail_page_fetching_thumbnail => 'サムネイルを取得中...';

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
  String get search_page_search_word => 'Web検索';

  @override
  String get search_page_hint_web_1 => '広告ブロック付きで快適に検索';

  @override
  String get search_page_hint_web_2 => '例: アニメ OP';

  @override
  String get search_page_hint_web_3 => 'アプリ内ブラウザでサクサク動画収集';

  @override
  String get search_page_hint_web_4 => '例: ライブ映像 2026';

  @override
  String get search_page_hint_web_5 => 'お気に入りサイトで深掘り';

  @override
  String get search_page_hint_web_6 => '例: 料理 簡単 レシピ';

  @override
  String get search_page_select_site => 'サイトで絞る';

  @override
  String get search_page_select_site_help_title => 'サイトで絞る';

  @override
  String get search_page_select_site_help_description =>
      'サイトを絞って動画検索ができます。お気に入りの動画サイトを登録しておくと、そのサイト内のコンテンツだけを横断的に検索できます。下のリストからサイトを選択して検索ボタンをタップしてください。';

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
  String get search_page_random_loading => '今日のおすすめを選んでいます…';

  @override
  String get search_page_random_this => '今日のおすすめはこれ！';

  @override
  String get search_page_random_again => 'もう一度回す';

  @override
  String get search_result_page_site_saved => 'サイトを保存しました';

  @override
  String get search_result_page_saving_as_item => '作品を保存';

  @override
  String get search_result_page_saving_list => '保存先リスト';

  @override
  String get search_result_page_url_already_saved => 'このURLはすでに保存されています';

  @override
  String get search_result_page_has_saved => '作品を保存しました';

  @override
  String search_result_page_delete_site(Object siteName) {
    return '「$siteName」をお気に入りから削除しますか？';
  }

  @override
  String get search_result_page_new_list => '新規リスト';

  @override
  String get search_result_page_input_list_name => 'リスト名を入力';

  @override
  String get search_result_page_list_already_exists => '同じ名前のリストが既にあります';

  @override
  String get search_result_page_history => '履歴';

  @override
  String get search_result_page_ad_remainder01 => '次の保存後に広告が表示されます';

  @override
  String get search_result_page_ad_remainder02 => '広告を表示します';

  @override
  String get analytics => '統計';

  @override
  String get analytics_page_summary => '概要';

  @override
  String analytics_page_item_count(Object totalWorks) {
    return '保存数: $totalWorks';
  }

  @override
  String get analytics_page_recent_additions => '最近追加した作品';

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
  String get analytics_page_kpi_saved_count => '保存数';

  @override
  String get analytics_page_kpi_total_view_count => '総視聴回数';

  @override
  String get analytics_page_kpi_rating_rate => '評価率';

  @override
  String get analytics_page_most_watched => '最多視聴';

  @override
  String analytics_page_view_times(Object count) {
    return '$count回 視聴';
  }

  @override
  String analytics_page_total_view_subtitle(Object count) {
    return '総視聴回数: $count回';
  }

  @override
  String analytics_page_rated_subtitle(Object ratedCount, Object total) {
    return '評価済み $ratedCount / $total件';
  }

  @override
  String get analytics_page_unit_items => '件';

  @override
  String analytics_page_ranked_row_stat(Object count, Object percent) {
    return '$percent%  $count件';
  }

  @override
  String analytics_page_times_unit(Object count) {
    return '$count回';
  }

  @override
  String get analytics_page_view_count_by_rating => '評価別 視聴回数';

  @override
  String get analytics_page_saved_by_list => 'リスト別保存数';

  @override
  String analytics_page_list_count_subtitle(Object count) {
    return '$countリスト';
  }

  @override
  String analytics_page_type_count_subtitle(Object count) {
    return '$count種類';
  }

  @override
  String get settings => '設定';

  @override
  String get settings_page_dark_mode => 'ダークモード';

  @override
  String get settings_page_theme_color => 'テーマカラー';

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
  String get setting_page_unlimited => '無制限';

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
  String get premium_detail_premium_title => 'ArchiVe Premium';

  @override
  String get premium_detail_premium_item01 => '無制限の保存数';

  @override
  String get premium_detail_premium_item02 => 'テーマカラー ゴールドを追加';

  @override
  String get premium_detail_premium_item03 => '画像を自由に追加';

  @override
  String get premium_detail_premium_item04 => '複数のタグで素早く検索';

  @override
  String get premium_detail_premium_item05 => 'ジャンル別・評価別にデータを可視化する統計機能';

  @override
  String get premium_detail_premium_item06 => '広告の非表示';

  @override
  String get premium_detail_note => '3日間の無料トライアル後、自動的に課金されます。\nいつでもキャンセルできます。';

  @override
  String get premium_detail_restore_not_found => '購入履歴が見つかりませんでした';

  @override
  String get premium_detail_free_trial_badge => '3日間無料';

  @override
  String get premium_detail_start_trial => '3日間無料で開始';

  @override
  String premium_detail_price_after_trial(Object price) {
    return 'その後 $price / 月';
  }

  @override
  String get premium_detail_restore_button => '購入を復元';

  @override
  String get premium_detail_purchase_complete => 'プレミアムを購入しました！';

  @override
  String get premium_detail_restart_message => 'プレミアム機能が有効になりました。\nアプリを再起動します。';

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
  String get start_tutorial_dialog => 'チュートリアルを\n再表示しますか？';

  @override
  String get start_tutorial_dialog_description => 'リスト作成からの手順をもう一度表示します。';

  @override
  String get completed_tutorial => 'チュートリアル完了！\nお疲れ様でした。';

  @override
  String get tutorial_list_name => 'あとで見る';

  @override
  String get tutorial_slide_title_01 => 'ダウンロード不要の\n動画管理アプリ';

  @override
  String get tutorial_slide_dict_01 => '容量を使わず好きなだけ動画を収集';

  @override
  String get tutorial_slide_image_01 => 'assets/tutorial/japanese01.png';

  @override
  String get tutorial_slide_title_02 => '【簡単2ステップ】\n①URLをコピー';

  @override
  String get tutorial_slide_dict_02 => '動画サイトの共有リンクやブラウザのURLをコピー';

  @override
  String get tutorial_slide_image_02 => 'assets/tutorial/japanese02.png';

  @override
  String get tutorial_slide_title_03 => '【簡単2ステップ】\n②コピーしたURLを保存';

  @override
  String get tutorial_slide_dict_03 => '貼るだけで登録\n評価・タグ・メモも追加可能';

  @override
  String get tutorial_slide_image_03 => 'assets/tutorial/japanese03.png';

  @override
  String get tutorial_slide_title_04 => 'アプリ内検索';

  @override
  String get tutorial_slide_dict_04 => '保存した動画がタイトル・タグですぐ見つかる。';

  @override
  String get tutorial_slide_image_04 => 'assets/tutorial/japanese04.png';

  @override
  String get tutorial_slide_title_05 => 'ウェブ検索';

  @override
  String get tutorial_slide_dict_05 => 'アプリ内ブラウザで、探してすぐに保存';

  @override
  String get tutorial_slide_image_05 => 'assets/tutorial/japanese05.png';

  @override
  String get tutorial_slide_title_06 => '可能性は無限大';

  @override
  String get tutorial_slide_dict_06 => '自分だけの動画コレクションを作ろう！';

  @override
  String get tutorial_slide_image_06 => 'assets/tutorial/japanese06.png';

  @override
  String get tutorial_slide_next => '次へ';

  @override
  String get tutorial_slide_start => '開始する';

  @override
  String get share_saved => '共有から保存しました';

  @override
  String get share_already_saved => 'このURLはすでに保存されています';

  @override
  String get share_dialog_title => 'ArchiVe に保存';

  @override
  String get share_list_section => '保存先リスト';

  @override
  String get share_title_hint => 'タイトルを入力';

  @override
  String get clipboard_dialog_title => 'クリップボードのURLを追加しますか？';

  @override
  String get ranking_page_add_item => 'アイテムを追加';

  @override
  String get search_page_url_cant_open => 'このURLは開けません';

  @override
  String get premium_detail_plan_monthly => '月額プラン';

  @override
  String get premium_detail_plan_annual => '年額プラン';

  @override
  String get premium_detail_best_value => 'お得';

  @override
  String premium_detail_save_percent(String percent) {
    return '$percent% OFF';
  }

  @override
  String get premium_detail_per_month => '/月';

  @override
  String get premium_detail_per_year => '/年';

  @override
  String premium_detail_price_after_trial_yearly(String price) {
    return 'その後 $price / 年';
  }

  @override
  String get settings_page_free_plan => '無料プラン';

  @override
  String get settings_page_current_plan => '現在のプラン';

  @override
  String get settings_page_premium_details_link => '保存数上限の解放、その他の詳細はこちら';

  @override
  String get settings_page_section_appearance => '外観';

  @override
  String get settings_page_section_about => 'アプリについて';

  @override
  String get settings_page_section_legal => '法的情報';

  @override
  String get settings_page_period_monthly => '月額';

  @override
  String get settings_page_period_annual => '年額';

  @override
  String get settings_page_theme_color_pink => 'ピンク';

  @override
  String get settings_page_theme_color_purple => 'パープル';

  @override
  String get settings_page_theme_color_teal => 'ティール';

  @override
  String get login_page_title => 'サインイン';

  @override
  String get login_page_description => 'ArchiVe Pro の機能を使うには、サインインしてください。';

  @override
  String get login_with_apple => 'Appleでサインイン';

  @override
  String get login_with_google => 'Googleでサインイン';

  @override
  String get login_failed => 'サインインに失敗しました';

  @override
  String get logout => 'サインアウト';

  @override
  String get logout_confirm => 'サインアウトしますか？';

  @override
  String get settings_page_section_account => 'アカウント';

  @override
  String get settings_page_not_signed_in => 'サインインしていません';

  @override
  String get pro_detail_title => 'ArchiVe Pro';

  @override
  String get pro_detail_subtitle => 'プレミアム全機能に加えて、以下が利用可能';

  @override
  String get pro_detail_feature_cloud_sync => 'クラウド同期（複数端末）';

  @override
  String get pro_detail_feature_ai_tagging => 'AI自動タグ付け';

  @override
  String get pro_detail_feature_ai_recommend => 'AIおすすめキーワード';

  @override
  String get pro_detail_feature_monthly_report => 'AI月次レポート';

  @override
  String get pro_detail_feature_public_sharing => '公開リスト共有';

  @override
  String get pro_detail_feature_theme_teal => 'テーマカラー ティールを追加';

  @override
  String get plans_page_title => 'プラン';

  @override
  String get plans_page_current_badge => '現在';

  @override
  String get plans_page_includes_premium => 'Premium全機能を含む';

  @override
  String get detail_page_ai_suggest => 'AIでタグ提案';

  @override
  String get detail_page_ai_loading => 'AIで分析中...';

  @override
  String get detail_page_ai_error => 'AIタグ提案エラー';

  @override
  String get share_title => 'リストを共有';

  @override
  String get share_loading => '共有中...';

  @override
  String get share_url_label => '共有URL';

  @override
  String get share_copy => 'コピー';

  @override
  String get share_copied => 'コピーしました';

  @override
  String get share_unshare => '共有を解除';

  @override
  String get share_unshare_confirm => 'このリストの共有を解除しますか？';

  @override
  String get share_create_action => 'このリストを共有する';

  @override
  String get share_error => '共有エラー';

  @override
  String get share_open_url => '共有URLを開く';

  @override
  String get share_description => '共有URLをこのリストの内容を誰でも閲覧できます（読み取り専用）';

  @override
  String get share_limit_notice => '最大200件まで共有されます';

  @override
  String get analytics_monthly_report_title => 'AIサマリー';

  @override
  String analytics_monthly_report_subtitle(int month) {
    return '$month月のまとめ';
  }

  @override
  String get analytics_monthly_report_generate => 'まとめを生成';

  @override
  String get analytics_monthly_report_regenerate => '再生成';

  @override
  String get analytics_monthly_report_loading => 'AIが分析しています...';

  @override
  String get analytics_monthly_report_empty => 'ボタンを押すと、今月のアーカイブ活動を AI が要約します。';

  @override
  String get analytics_monthly_report_error => 'レポート生成エラー';

  @override
  String get analytics_monthly_report_cached => 'キャッシュから表示';

  @override
  String get search_result_loading => '読み込み中';

  @override
  String get grid_page_move_action => '移動';

  @override
  String get grid_page_move_to_list_title => '移動先のリストを選択';

  @override
  String get grid_page_move_done => '件を移動しました';

  @override
  String get undo => '取り消し';

  @override
  String get settings_page_theme_color_gold => 'ゴールド';

  @override
  String get plans_page_premium_short => 'プレミアム';

  @override
  String get plans_page_pro_short => 'Pro';

  @override
  String get plans_page_free_short => '無料';

  @override
  String get plans_page_free_price => '¥0';

  @override
  String get plans_page_free_item01 => '100件まで保存可能';

  @override
  String get plans_page_free_item02 => '広告視聴で15枠/日 拡張可能';

  @override
  String get plans_page_free_item03 => '単一のタグで検索';

  @override
  String get plans_page_free_item04 => '広告表示';

  @override
  String get share_pro_required_title => 'Pro プラン限定機能';

  @override
  String get share_pro_required_description => '公開リスト共有はProプランの購入が必要です。';

  @override
  String get share_pro_required_action => 'Proプランを見る';

  @override
  String get pro_locked_badge => 'Pro限定';

  @override
  String get pro_locked_unlock => 'Proで解除';

  @override
  String get apple_signin_warning_title => 'Apple アカウントでサインインしますか？';

  @override
  String get apple_signin_warning_description =>
      'Apple アカウントは Android 端末ではサインインできず、データを共有できません。複数端末で共有する場合は Google アカウントをお勧めします。';

  @override
  String get apple_signin_warning_continue => 'Apple で続行';

  @override
  String get settings_page_manage_subscription => 'サブスクリプションを管理';

  @override
  String get search_page_ai_recommend_title => 'AIおすすめ';

  @override
  String get search_page_ai_recommend_subtitle => 'ライブラリ傾向から関連キーワードを提案';

  @override
  String get search_page_ai_recommend_generate => 'おすすめを取得';

  @override
  String get search_page_ai_recommend_refresh => '再生成';

  @override
  String get search_page_ai_recommend_loading => 'AIが分析しています...';

  @override
  String get search_page_ai_recommend_error => 'おすすめ取得エラー';

  @override
  String get search_page_ai_recommend_empty =>
      '保存したアイテムが少ないため提案できません。アイテムを追加してから再度お試しください。';

  @override
  String get search_page_ai_recommend_intro =>
      'ボタンを押すと、保存ライブラリの傾向から関連キーワードをAIが提案します。';
}
