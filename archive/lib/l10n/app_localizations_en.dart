// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'ArchiVe';

  @override
  String get version => 'v1.7';

  @override
  String get critical => 'Critical';

  @override
  String get normal => 'Normal';

  @override
  String get maniac => 'Maniac';

  @override
  String get unrated => 'Unrated';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get back => 'Back';

  @override
  String get add => 'Add';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get reload => 'Reload';

  @override
  String get all_item_list_name => 'All Items';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get clear => 'clear';

  @override
  String get favorite => 'Favorite';

  @override
  String get url => 'URL';

  @override
  String get title => 'Title';

  @override
  String get no_select => 'None';

  @override
  String get modify => 'Modify';

  @override
  String get close => 'Close';

  @override
  String get save_limit_dialog_title => 'Save limit reached';

  @override
  String save_limit_dialog_description(Object count, Object limit) {
    return 'You can save up to $limit items.\n\nCurrent items: $count\n\nTo save more than $limit items:\n• Delete existing items\n• Upgrade to the Premium plan\n• Watch ads in Settings to increase your limit';
  }

  @override
  String get save_limit_dialog_already_purchased => 'Already purchased.';

  @override
  String get save_limit_dialog_premium_detail => 'View Premium details';

  @override
  String get main_page_lists => 'Lists';

  @override
  String get main_page_search => 'Search & Collect';

  @override
  String get main_page_analytics => 'Analytics';

  @override
  String get main_page_settings => 'Settings';

  @override
  String get list_page_my_list => 'My Lists';

  @override
  String get list_page_my_ranking => 'My Rankings';

  @override
  String get list_page_make_list => 'Create List';

  @override
  String get list_page_add_list => 'Add List';

  @override
  String get list_page_input_list_name => 'Enter list name';

  @override
  String get ranking_page_dragable => 'Drag to reorder';

  @override
  String get ranking_page_no_title => '(No title)';

  @override
  String get ranking_page_search_title => 'Search title';

  @override
  String get ranking_page_no_grid_item => 'No saved items';

  @override
  String get ranking_page_limit_error => 'You can add up to 10 items only';

  @override
  String get ranking_page_no_ranking_item => 'No items in ranking';

  @override
  String get ranking_page_no_ranking_item_description =>
      'Please add items from the list below';

  @override
  String grid_page_item_count(Object length) {
    return '$length items';
  }

  @override
  String get grid_page_no_item => 'No items';

  @override
  String get grid_page_cant_load_image => 'Unable to load image';

  @override
  String get grid_page_no_title => '(No title)';

  @override
  String get grid_page_url_unable => 'Invalid URL';

  @override
  String get grid_page_sort_title => 'Title';

  @override
  String get grid_page_sort_new => 'Newest first';

  @override
  String get grid_page_sort_old => 'Oldest first';

  @override
  String get grid_page_sort_count_asc => 'Most viewed';

  @override
  String get grid_page_sort_count_desc => 'Least viewed';

  @override
  String get detail_page_url_empty => 'URL is empty.';

  @override
  String get detail_page_input_url => 'Please enter a URL.';

  @override
  String get detail_page_url_changed => 'URL has been changed.';

  @override
  String get detail_page_url_changed_note =>
      'Changing the URL will save this as a new item.\nDo you want to continue?';

  @override
  String get detail_page_no_selected => 'Not selected';

  @override
  String get detail_page_item_detail => 'Item details';

  @override
  String get detail_page_delete => 'Delete';

  @override
  String get detail_page_access => 'Browser';

  @override
  String get detail_page_modify => 'Edit';

  @override
  String get detail_page_save => 'Save';

  @override
  String get detail_page_thumbnail_placeholder =>
      'Thumbnail will appear after saving';

  @override
  String get detail_page_add_image => 'Add image ★';

  @override
  String get detail_page_rate => 'Rating';

  @override
  String get detail_page_title => 'Title';

  @override
  String get detail_page_title_placeholder => 'Title';

  @override
  String get detail_page_cast => 'Cast (# multiple)';

  @override
  String get detail_page_cast_placeholder => '#Cast1 #Cast2 ...';

  @override
  String get detail_page_genre => 'Genre (# multiple)';

  @override
  String get detail_page_genre_placeholder => '#Genre1 #Genre2 ...';

  @override
  String get detail_page_series => 'Series (# multiple)';

  @override
  String get detail_page_series_placeholder => '#Series1 #Series2 ...';

  @override
  String get detail_page_label => 'Label (# multiple)';

  @override
  String get detail_page_label_placeholder => '#Label1 #Label2 ...';

  @override
  String get detail_page_maker => 'Maker (# multiple)';

  @override
  String get detail_page_maker_placeholder => '#Maker1 #Maker2 ...';

  @override
  String get detail_page_paste_url => 'Paste URL';

  @override
  String get detail_page_fetch_title => 'Fetch title from URL';

  @override
  String get detail_page_list => 'List';

  @override
  String get detail_page_memo => 'Memo';

  @override
  String get detail_page_fetch_title_fail => 'Title not found.';

  @override
  String get detail_page_fetch_page_fail => 'Failed to load page.';

  @override
  String get detail_page_ex => 'An error occurred.';

  @override
  String get detail_page_delete_confirm01 => 'Delete this item?';

  @override
  String get detail_page_delete_confirm02 => 'This action cannot be undone.';

  @override
  String get detail_page_url_unable => 'Invalid URL';

  @override
  String get detail_page_review_confirm01 =>
      'Are you enjoying \"ArchiVe - Favorite Video Tracker\"?';

  @override
  String get detail_page_review_confirm02 =>
      'If so, we would love to hear your feedback.';

  @override
  String get detail_page_mail_subject => 'subject=ArchiVe Feedback';

  @override
  String get search_page_cast => 'Cast';

  @override
  String get search_page_genre => 'Genre';

  @override
  String get search_page_series => 'Series';

  @override
  String get search_page_label => 'Label';

  @override
  String get search_page_maker => 'Maker';

  @override
  String get search_page_search => 'Search';

  @override
  String get search_page_select_category => 'Select a category';

  @override
  String get search_page_more => 'Show more';

  @override
  String get search_page_fold => 'Show less';

  @override
  String get search_page_search_title => 'Search by title';

  @override
  String get search_page_premium_title => 'Select multiple tags ★';

  @override
  String get search_page_premium_description =>
      'Searching with multiple categories\nis available for Premium users only.';

  @override
  String get search_page_segment_button_app => 'In App';

  @override
  String get search_page_segment_button_web => 'Web';

  @override
  String get search_page_text_empty => 'Please enter a search term';

  @override
  String get search_page_web_title => 'Web Search';

  @override
  String get search_page_search_word => 'Search term';

  @override
  String get search_page_select_site => 'Filter by Site';

  @override
  String get search_page_open_site => 'Open site';

  @override
  String get search_page_modify_favorite => 'Edit favorites';

  @override
  String get search_page_site_name => 'Site name';

  @override
  String get search_page_input_all => 'Please fill in all fields';

  @override
  String get search_page_add_favorite => 'Add favorite site';

  @override
  String get search_result_page_save_as_item => 'Item has been saved';

  @override
  String get search_result_page_site_saved => 'Site has been saved';

  @override
  String get search_result_page_saving_as_item => 'Save item';

  @override
  String get search_result_page_saving_list => 'Destination list';

  @override
  String get search_result_page_url_already_saved =>
      'This URL has already been saved';

  @override
  String search_result_page_delete_site(Object siteName) {
    return 'Remove \"$siteName\" from favorites?';
  }

  @override
  String get analytics => 'Analytics';

  @override
  String analytics_page_piechart_others(Object percent) {
    return 'Others\n$percent%';
  }

  @override
  String get analytics_page_view_count_top5 => 'Top 5 View Counts';

  @override
  String get analytics_page_no_data => 'No data available';

  @override
  String get analytics_page_evaluation => 'Rating';

  @override
  String get analytics_page_cast => 'Cast';

  @override
  String get analytics_page_genre => 'Genre';

  @override
  String get analytics_page_series => 'Series';

  @override
  String get analytics_page_label => 'Label';

  @override
  String get analytics_page_maker => 'Maker';

  @override
  String get analytics_page_premium_title => 'Analytics ★';

  @override
  String get analytics_page_premium_description =>
      'Analytics features are available in ArchiVe Premium.\nPlease upgrade to use them.';

  @override
  String get analytics_page_premium_button => 'View Premium details';

  @override
  String analytics_page_list_value(Object entry, Object percent) {
    return '$percent% ($entry items)';
  }

  @override
  String get analytics_page_count => '(views)';

  @override
  String analytics_page_toolchip_count(Object rod) {
    return '$rod views';
  }

  @override
  String get analytics_page_no_title => 'No title';

  @override
  String get analytics_page_item_count_top5 => 'Top 5 Item Counts';

  @override
  String get settings => 'Settings';

  @override
  String get settings_page_dark_mode => 'Dark mode';

  @override
  String get settings_page_theme_color => 'Theme color ★';

  @override
  String get settings_page_theme_color_orange => 'Orange';

  @override
  String get settings_page_theme_color_green => 'Green';

  @override
  String get settings_page_theme_color_blue => 'Blue';

  @override
  String get settings_page_theme_color_white => 'White';

  @override
  String get settings_page_theme_color_red => 'Red';

  @override
  String get settings_page_theme_color_yellow => 'Yellow';

  @override
  String get settings_page_thumbnail_visibility => 'Show list thumbnails';

  @override
  String get settings_page_save_status => 'Save status';

  @override
  String get settings_page_save_count => 'Saved items';

  @override
  String get settings_page_watch_count => 'Today\'s views';

  @override
  String settings_page_watch_ad_today(Object watchedAdsToday) {
    return '$watchedAdsToday / 3';
  }

  @override
  String get settings_page_watch_ad => 'Watch ad (+5 slots)';

  @override
  String get settings_page_ad_limit_reached => 'Daily ad limit reached';

  @override
  String get settings_page_already_purchased => 'Already purchased.';

  @override
  String get settings_page_premium => 'ArchiVe Premium';

  @override
  String get settings_page_app_version => 'App version';

  @override
  String get settings_page_plivacy_policy => 'Privacy policy';

  @override
  String get settings_page_disable_link => 'Unable to open link';

  @override
  String get settings_page_terms => 'Terms of Service (Apple Standard EULA)';

  @override
  String get settings_page_save_count_increased => 'Save limit increased by +5';

  @override
  String view_counter_view_count(Object viewCount) {
    return 'Views: $viewCount';
  }

  @override
  String get random_image_no_image => 'Unable to load image';

  @override
  String get random_image_change_list_name => 'Change list name';

  @override
  String get random_image_change_list_name_dialog => 'Change list name';

  @override
  String get random_image_change_list_name_hint => 'Enter list name';

  @override
  String get random_image_change_list_name_confirm => 'Change';

  @override
  String get random_image_delete_list => 'Delete list';

  @override
  String get random_image_delete_list_dialog => 'Delete this list?';

  @override
  String get random_image_delete_list_dialog_description =>
      'Items in this list will also be deleted.';

  @override
  String get random_image_delete_list_confirm => 'Delete';

  @override
  String get premium_detail_purchase_complete =>
      'Premium purchased successfully!';

  @override
  String get premium_detail_purchase_incomplete =>
      'Purchase completed, but Premium was not activated';

  @override
  String get premium_detail_no_item => 'No purchasable plans found';

  @override
  String premium_detail_ex(Object ex) {
    return 'Purchase error: $ex';
  }

  @override
  String get premium_detail_premium_title => 'ArchiVe Premium';

  @override
  String get premium_detail_premium_item01 => 'Enjoy the app without ads';

  @override
  String get premium_detail_premium_item02 => 'Freely change theme colors';

  @override
  String get premium_detail_premium_item03 => 'Add images freely';

  @override
  String get premium_detail_premium_item04 => 'Quick search with multiple tags';

  @override
  String get premium_detail_premium_item05 => 'Unlimited save slots';

  @override
  String get premium_detail_premium_item06 =>
      'Visualize data by genre and rating';

  @override
  String get premium_detail_price => 'Start for ¥170 / month';

  @override
  String get premium_detail_note => 'Cancel anytime';

  @override
  String get tutorial => 'tutorial';

  @override
  String get tutorial_01 => 'First, let’s create a list.';

  @override
  String get tutorial_02 => 'Open the list you just created.';

  @override
  String get tutorial_03 => 'Tap the + button to add an item.';

  @override
  String get tutorial_04 => 'Enter the URL of the video or content.';

  @override
  String get tutorial_05 => 'Tap this button to automatically fetch the title.';

  @override
  String get tutorial_06 => 'Finally, save it to add it to the list.';

  @override
  String get start_tutorial_dialog => 'Restart the tutorial?';

  @override
  String get start_tutorial_dialog_description =>
      'This will show the steps from creating a list again.';

  @override
  String get completed_tutorial => 'Tutorial complete!\nGreat job!';

  @override
  String get tutorial_list_name => 'Watch Later';

  @override
  String get tutorial_slide_title_01 => 'A Video Manager\nNo Downloads Needed';

  @override
  String get tutorial_slide_dict_01 =>
      'Collect unlimited videos without using storage';

  @override
  String get tutorial_slide_image_01 => 'assets/tutorial/Japanese01.png';

  @override
  String get tutorial_slide_title_02 => '[2 Easy Steps]\n1. Copy the URL';

  @override
  String get tutorial_slide_dict_02 =>
      'Copy the share link or browser URL from any video site';

  @override
  String get tutorial_slide_image_02 => 'assets/tutorial/Japanese02.png';

  @override
  String get tutorial_slide_title_03 => '[2 Easy Steps]\n2. Save the URL';

  @override
  String get tutorial_slide_dict_03 =>
      'Just paste to save\nAdd ratings, tags, and notes';

  @override
  String get tutorial_slide_image_03 => 'assets/tutorial/Japanese03.png';

  @override
  String get tutorial_slide_title_04 => 'Search Inside the App';

  @override
  String get tutorial_slide_dict_04 =>
      'Find saved videos instantly by title or tags';

  @override
  String get tutorial_slide_image_04 => 'assets/tutorial/Japanese04.png';

  @override
  String get tutorial_slide_title_05 => 'Web Search';

  @override
  String get tutorial_slide_dict_05 =>
      'Browse and save videos instantly with the in-app browser';

  @override
  String get tutorial_slide_image_05 => 'assets/tutorial/Japanese05.png';

  @override
  String get tutorial_slide_title_06 => 'Unlimited Possibilities';

  @override
  String get tutorial_slide_dict_06 =>
      'Build your own personal video collection!';

  @override
  String get tutorial_slide_image_06 => 'assets/tutorial/Japanese06.png';

  @override
  String get tutorial_slide_next => 'Next';

  @override
  String get tutorial_slide_start => 'Get Started';
}
