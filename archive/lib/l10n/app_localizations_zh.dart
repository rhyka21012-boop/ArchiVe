// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class L10nZh extends L10n {
  L10nZh([String locale = 'zh']) : super(locale);

  @override
  String get app_title => 'ArchiVe';

  @override
  String get version => 'v1.8';

  @override
  String get critical => '强烈推荐';

  @override
  String get normal => '普通';

  @override
  String get maniac => '狂热';

  @override
  String get unrated => '未评分';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get back => '返回';

  @override
  String get add => '添加';

  @override
  String get delete => '删除';

  @override
  String get save => '保存';

  @override
  String get reload => '刷新';

  @override
  String get all_item_list_name => '全部项目';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get clear => '清除';

  @override
  String get favorite => '收藏';

  @override
  String get url => 'URL';

  @override
  String get title => '标题';

  @override
  String get no_select => '未选择';

  @override
  String get modify => '修改';

  @override
  String get close => '关闭';

  @override
  String get skip => '跳过';

  @override
  String get save_limit_dialog_title => '已达到保存上限';

  @override
  String get save_limit_dialog_status_label => '已保存';

  @override
  String get save_limit_dialog_premium_detail => '查看高级版详情';

  @override
  String get save_limit_loading_ad => '广告加载中...';

  @override
  String get main_page_lists => '列表';

  @override
  String get main_page_search => '搜索与收集';

  @override
  String get main_page_analytics => '统计';

  @override
  String get main_page_settings => '设置';

  @override
  String get main_page_update_info => '更新通知';

  @override
  String get main_page_update_later => '稍后';

  @override
  String get main_page_update_now => '立即更新';

  @override
  String get list_page_my_list => '我的列表';

  @override
  String get list_page_my_ranking => '我的排行';

  @override
  String get list_page_make_list => '创建列表';

  @override
  String get list_page_add_list => '添加列表';

  @override
  String get list_page_input_list_name => '输入列表名称';

  @override
  String get ranking_page_dragable => '拖动排序';

  @override
  String get ranking_page_no_title => '(无标题)';

  @override
  String get ranking_page_search_title => '搜索标题';

  @override
  String get ranking_page_no_grid_item => '暂无保存项目';

  @override
  String get ranking_page_limit_error => '最多只能添加10个项目';

  @override
  String get ranking_page_no_ranking_item => '排行中暂无项目';

  @override
  String get ranking_page_no_ranking_item_description => '请从下方列表添加项目';

  @override
  String grid_page_item_count(Object length) {
    return '$length 个项目';
  }

  @override
  String get grid_page_no_item => '暂无项目';

  @override
  String get grid_page_add_item => '选择添加方式';

  @override
  String get grid_page_by_web => '通过网页搜索添加';

  @override
  String get grid_page_by_manual => '手动添加';

  @override
  String get grid_page_cant_load_image => '无法加载图片';

  @override
  String get grid_page_no_title => '(无标题)';

  @override
  String get grid_page_url_unable => '无效的URL';

  @override
  String get grid_page_sort_title => '按标题';

  @override
  String get grid_page_sort_new => '最新优先';

  @override
  String get grid_page_sort_old => '最早优先';

  @override
  String get grid_page_sort_count_asc => '浏览量从高到低';

  @override
  String get grid_page_sort_count_desc => '浏览量从低到高';

  @override
  String grid_page_items_selected_delete(Object count) {
    return '删除选中的 $count 个项目？';
  }

  @override
  String get grid_page_rating_guidance => '已评分的项目将显示在这里';

  @override
  String get detail_page_url_empty => 'URL为空。';

  @override
  String get detail_page_input_url => '请输入URL。';

  @override
  String get detail_page_url_changed => 'URL已更改。';

  @override
  String get detail_page_url_changed_note => '更改URL将作为新项目保存。\n是否继续？';

  @override
  String get detail_page_no_selected => '未选择';

  @override
  String get detail_page_item_detail => '项目详情';

  @override
  String get detail_page_delete => '删除';

  @override
  String get detail_page_access => '浏览器';

  @override
  String get detail_page_modify => '编辑';

  @override
  String get detail_page_save => '保存';

  @override
  String get detail_page_thumbnail_placeholder => '保存后将显示缩略图';

  @override
  String get detail_page_add_image => '添加图片 ★';

  @override
  String get detail_page_rate => '评分';

  @override
  String get detail_page_title => '标题';

  @override
  String get detail_page_title_placeholder => '标题';

  @override
  String get detail_page_cast => '演员 (# 多个)';

  @override
  String get detail_page_cast_placeholder => '#演员1 #演员2 ...';

  @override
  String get detail_page_genre => '类型 (# 多个)';

  @override
  String get detail_page_genre_placeholder => '#类型1 #类型2 ...';

  @override
  String get detail_page_series => '系列 (# 多个)';

  @override
  String get detail_page_series_placeholder => '#系列1 #系列2 ...';

  @override
  String get detail_page_label => '标签 (# 多个)';

  @override
  String get detail_page_label_placeholder => '#标签1 #标签2 ...';

  @override
  String get detail_page_maker => '制作方 (# 多个)';

  @override
  String get detail_page_maker_placeholder => '#制作方1 #制作方2 ...';

  @override
  String get detail_page_paste_url => '粘贴URL';

  @override
  String get detail_page_fetch_title => '从URL获取标题';

  @override
  String get detail_page_list => '列表';

  @override
  String get detail_page_memo => '备注';

  @override
  String get detail_page_fetch_title_fail => '未找到标题。';

  @override
  String get detail_page_fetch_page_fail => '页面加载失败。';

  @override
  String get detail_page_ex => '发生错误。';

  @override
  String get detail_page_delete_confirm01 => '确定删除此项目？';

  @override
  String get detail_page_delete_confirm02 => '此操作无法撤销。';

  @override
  String get detail_page_url_unable => '无效的URL';

  @override
  String get detail_page_review_confirm01 =>
      '您喜欢“ArchiVe - Favorite Video Tracker”吗？';

  @override
  String get detail_page_review_confirm02 =>
      '感谢您的使用。\n\n您的反馈将由开发者认真查看，并用于后续改进。\n\n如果您喜欢本应用，欢迎留下评价支持我们。';

  @override
  String get detail_page_review_contact_support => '反馈或报告问题';

  @override
  String get detail_page_review_later => '稍后';

  @override
  String get detail_page_review_now => '去评价';

  @override
  String get detail_page_mail_subject => 'subject=ArchiVe Feedback';

  @override
  String get detail_page_fetching_thumbnail => '正在获取缩略图...';

  @override
  String get search_page_cast => '演员';

  @override
  String get search_page_genre => '类型';

  @override
  String get search_page_series => '系列';

  @override
  String get search_page_label => '标签';

  @override
  String get search_page_maker => '制作方';

  @override
  String get search_page_search => '搜索';

  @override
  String get search_page_select_category => '选择分类';

  @override
  String get search_page_more => '查看更多';

  @override
  String get search_page_fold => '收起';

  @override
  String get search_page_search_title => '按标题搜索';

  @override
  String get search_page_premium_title => '选择多个标签 ★';

  @override
  String get search_page_premium_description => '多分类搜索功能\n仅限高级版用户使用。';

  @override
  String get search_page_segment_button_app => '应用内';

  @override
  String get search_page_segment_button_web => '网页';

  @override
  String get search_page_text_empty => '请输入搜索内容';

  @override
  String get search_page_web_title => '网页搜索';

  @override
  String get search_page_search_word => '搜索词';

  @override
  String get search_page_select_site => '按网站筛选';

  @override
  String get search_page_open_site => '打开网站';

  @override
  String get search_page_modify_favorite => '编辑收藏';

  @override
  String get search_page_site_name => '网站名称';

  @override
  String get search_page_input_all => '请填写所有字段';

  @override
  String get search_page_add_favorite => '添加收藏网站';

  @override
  String get search_page_random_loading => '正在选择今日推荐…';

  @override
  String get search_page_random_this => '今日推荐！';

  @override
  String get search_result_page_site_saved => '网站已保存';

  @override
  String get search_result_page_saving_as_item => '保存项目';

  @override
  String get search_result_page_saving_list => '保存到列表';

  @override
  String get search_result_page_url_already_saved => '该URL已保存';

  @override
  String get search_result_page_has_saved => '物品已保存';

  @override
  String search_result_page_delete_site(Object siteName) {
    return '是否将“$siteName”从收藏中删除？';
  }

  @override
  String get search_result_page_new_list => '新建列表';

  @override
  String get search_result_page_input_list_name => '输入列表名称';

  @override
  String get search_result_page_list_already_exists => '已存在同名列表';

  @override
  String get search_result_page_history => '历史记录';

  @override
  String get search_result_page_ad_remainder01 => '下次保存后将显示广告';

  @override
  String get search_result_page_ad_remainder02 => '显示广告';

  @override
  String get analytics => '统计';

  @override
  String get analytics_page_summary => '概览';

  @override
  String analytics_page_item_count(Object totalWorks) {
    return '已保存项目：$totalWorks';
  }

  @override
  String get analytics_page_recent_additions => '最近添加的项目';

  @override
  String analytics_page_piechart_others(Object percent) {
    return '其他\n$percent%';
  }

  @override
  String get analytics_page_view_count_top5 => '浏览量前5名';

  @override
  String get analytics_page_no_data => '暂无数据';

  @override
  String get analytics_page_evaluation => '评分';

  @override
  String get analytics_page_cast => '演员';

  @override
  String get analytics_page_genre => '类型';

  @override
  String get analytics_page_series => '系列';

  @override
  String get analytics_page_label => '标签';

  @override
  String get analytics_page_maker => '制作方';

  @override
  String get analytics_page_premium_title => '统计功能 ★';

  @override
  String get analytics_page_premium_description =>
      '统计功能仅在 ArchiVe Premium 中提供。\n请升级后使用。';

  @override
  String get analytics_page_premium_button => '查看高级版详情';

  @override
  String analytics_page_list_value(Object entry, Object percent) {
    return '$percent%（$entry个）';
  }

  @override
  String get analytics_page_count => '（浏览）';

  @override
  String analytics_page_toolchip_count(Object rod) {
    return '$rod 次浏览';
  }

  @override
  String get analytics_page_no_title => '无标题';

  @override
  String get analytics_page_item_count_top5 => '项目数量前5名';

  @override
  String get analytics_page_kpi_saved_count => '收藏數';

  @override
  String get analytics_page_kpi_total_view_count => '總觀看次數';

  @override
  String get analytics_page_kpi_rating_rate => '評價率';

  @override
  String get analytics_page_most_watched => '最多播放';

  @override
  String analytics_page_view_times(Object count) {
    return '觀看 $count 次';
  }

  @override
  String analytics_page_total_view_subtitle(Object count) {
    return '總觀看次數: $count';
  }

  @override
  String analytics_page_rated_subtitle(Object ratedCount, Object total) {
    return '已評價 $ratedCount / $total 件';
  }

  @override
  String get analytics_page_unit_items => '件';

  @override
  String analytics_page_ranked_row_stat(Object count, Object percent) {
    return '$percent%  $count件';
  }

  @override
  String analytics_page_times_unit(Object count) {
    return '$count次';
  }

  @override
  String get analytics_page_view_count_by_rating => '按評價的觀看次數';

  @override
  String get analytics_page_saved_by_list => '依列表保存數';

  @override
  String analytics_page_list_count_subtitle(Object count) {
    return '$count個列表';
  }

  @override
  String analytics_page_type_count_subtitle(Object count) {
    return '$count種類';
  }

  @override
  String get settings => '设置';

  @override
  String get settings_page_dark_mode => '深色模式';

  @override
  String get settings_page_theme_color => '主题颜色 ★';

  @override
  String get settings_page_theme_color_orange => '橙色';

  @override
  String get settings_page_theme_color_green => '绿色';

  @override
  String get settings_page_theme_color_blue => '蓝色';

  @override
  String get settings_page_theme_color_white => '白色';

  @override
  String get settings_page_theme_color_red => '红色';

  @override
  String get settings_page_theme_color_yellow => '黄色';

  @override
  String get settings_page_thumbnail_visibility => '显示列表缩略图';

  @override
  String get settings_page_save_status => '保存状态';

  @override
  String get settings_page_save_count => '已保存项目数';

  @override
  String get settings_page_watch_count => '今日浏览数';

  @override
  String settings_page_watch_ad_today(Object watchedAdsToday) {
    return '$watchedAdsToday / 3';
  }

  @override
  String get settings_page_watch_ad => '观看广告（+5个名额）';

  @override
  String get settings_page_ad_limit_reached => '今日广告次数已达上限';

  @override
  String get settings_page_already_purchased => '已购买。';

  @override
  String get settings_page_premium => 'ArchiVe Premium';

  @override
  String get settings_page_app_version => '应用版本';

  @override
  String get settings_page_plivacy_policy => '隐私政策';

  @override
  String get settings_page_disable_link => '无法打开链接';

  @override
  String get settings_page_terms => '服务条款（Apple 标准 EULA）';

  @override
  String get settings_page_save_count_increased => '保存上限增加 +5';

  @override
  String get setting_page_unlimited => '无限制';

  @override
  String view_counter_view_count(Object viewCount) {
    return '浏览次数：$viewCount';
  }

  @override
  String get random_image_no_image => '无法加载图片';

  @override
  String get random_image_change_list_name => '更改列表名称';

  @override
  String get random_image_change_list_name_dialog => '更改列表名称';

  @override
  String get random_image_change_list_name_hint => '输入列表名称';

  @override
  String get random_image_change_list_name_confirm => '更改';

  @override
  String get random_image_delete_list => '删除列表';

  @override
  String get random_image_delete_list_dialog => '确定删除此列表？';

  @override
  String get random_image_delete_list_dialog_description => '该列表中的项目也将被删除。';

  @override
  String get random_image_delete_list_confirm => '删除';

  @override
  String get premium_detail_premium_title => 'ArchiVe Premium';

  @override
  String get premium_detail_premium_item01 => '无限保存';

  @override
  String get premium_detail_premium_item02 => '自由更改主题颜色';

  @override
  String get premium_detail_premium_item03 => '自由添加图片';

  @override
  String get premium_detail_premium_item04 => '使用多个标签快速搜索';

  @override
  String get premium_detail_premium_item05 => '按类别和评分可视化数据的统计功能';

  @override
  String get premium_detail_premium_item06 => '去除广告';

  @override
  String get premium_detail_note => '1个月免费试用结束后，将自动续订。\n您可以随时取消。';

  @override
  String get premium_detail_restore_not_found => '未找到购买记录';

  @override
  String get premium_detail_free_trial_badge => '1个月免费';

  @override
  String get premium_detail_start_trial => '开始1个月免费试用';

  @override
  String premium_detail_price_after_trial(Object price) {
    return '之后 $price / 月';
  }

  @override
  String get premium_detail_restore_button => '恢复购买';

  @override
  String get premium_detail_purchase_complete => '高级版购买成功！';

  @override
  String get premium_detail_restart_message => '高级功能已启用。\n应用将重新启动。';

  @override
  String get tutorial => '教程';

  @override
  String get tutorial_01 => '首先，创建一个列表。';

  @override
  String get tutorial_02 => '打开刚创建的列表。';

  @override
  String get tutorial_03 => '点击 + 按钮添加项目。';

  @override
  String get tutorial_04 => '输入视频或内容的URL。';

  @override
  String get tutorial_05 => '点击此按钮自动获取标题。';

  @override
  String get tutorial_06 => '最后点击保存，将其添加到列表中。';

  @override
  String get start_tutorial_dialog => '重新开始教程？';

  @override
  String get start_tutorial_dialog_description => '将从创建列表开始重新演示步骤。';

  @override
  String get completed_tutorial => '教程完成！\n做得很好！';

  @override
  String get tutorial_list_name => '稍后观看';

  @override
  String get tutorial_slide_title_01 => '无需下载\n轻松管理视频';

  @override
  String get tutorial_slide_dict_01 => '无需占用存储空间\n无限收集视频';

  @override
  String get tutorial_slide_image_01 => 'assets/tutorial/english01.png';

  @override
  String get tutorial_slide_title_02 => '[两步完成]\n1. 复制URL';

  @override
  String get tutorial_slide_dict_02 => '从任意视频网站复制分享链接或浏览器URL';

  @override
  String get tutorial_slide_image_02 => 'assets/tutorial/english02.png';

  @override
  String get tutorial_slide_title_03 => '[两步完成]\n2. 保存URL';

  @override
  String get tutorial_slide_dict_03 => '粘贴即可保存\n还可添加评分、标签和备注';

  @override
  String get tutorial_slide_image_03 => 'assets/tutorial/english03.png';

  @override
  String get tutorial_slide_title_04 => '应用内搜索';

  @override
  String get tutorial_slide_dict_04 => '通过标题或标签\n即时查找已保存的视频';

  @override
  String get tutorial_slide_image_04 => 'assets/tutorial/english04.png';

  @override
  String get tutorial_slide_title_05 => '网页搜索';

  @override
  String get tutorial_slide_dict_05 => '使用应用内浏览器\n立即浏览并保存视频';

  @override
  String get tutorial_slide_image_05 => 'assets/tutorial/english05.png';

  @override
  String get tutorial_slide_title_06 => '无限可能';

  @override
  String get tutorial_slide_dict_06 => '打造属于你的个人视频收藏！';

  @override
  String get tutorial_slide_image_06 => 'assets/tutorial/english06.png';

  @override
  String get tutorial_slide_next => '下一步';

  @override
  String get tutorial_slide_start => '开始使用';

  @override
  String get share_saved => '已从分享中保存';

  @override
  String get share_already_saved => '该URL已保存';

  @override
  String get share_dialog_title => '保存到 ArchiVe';

  @override
  String get share_list_section => '保存列表';

  @override
  String get share_title_hint => '输入标题';

  @override
  String get clipboard_dialog_title => '是否添加剪贴板中的URL？';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class L10nZhHans extends L10nZh {
  L10nZhHans() : super('zh_Hans');

  @override
  String get app_title => 'ArchiVe';

  @override
  String get version => 'v1.8';

  @override
  String get critical => '强烈推荐';

  @override
  String get normal => '普通';

  @override
  String get maniac => '狂热';

  @override
  String get unrated => '未评分';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get back => '返回';

  @override
  String get add => '添加';

  @override
  String get delete => '删除';

  @override
  String get save => '保存';

  @override
  String get reload => '刷新';

  @override
  String get all_item_list_name => '全部项目';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get clear => '清除';

  @override
  String get favorite => '收藏';

  @override
  String get url => 'URL';

  @override
  String get title => '标题';

  @override
  String get no_select => '未选择';

  @override
  String get modify => '修改';

  @override
  String get close => '关闭';

  @override
  String get skip => '跳过';

  @override
  String get save_limit_dialog_title => '已达到保存上限';

  @override
  String get save_limit_dialog_status_label => '已保存';

  @override
  String get save_limit_dialog_premium_detail => '查看高级版详情';

  @override
  String get save_limit_loading_ad => '广告加载中...';

  @override
  String get main_page_lists => '列表';

  @override
  String get main_page_search => '搜索与收集';

  @override
  String get main_page_analytics => '统计';

  @override
  String get main_page_settings => '设置';

  @override
  String get main_page_update_info => '更新通知';

  @override
  String get main_page_update_later => '稍后';

  @override
  String get main_page_update_now => '立即更新';

  @override
  String get list_page_my_list => '我的列表';

  @override
  String get list_page_my_ranking => '我的排行';

  @override
  String get list_page_make_list => '创建列表';

  @override
  String get list_page_add_list => '添加列表';

  @override
  String get list_page_input_list_name => '输入列表名称';

  @override
  String get ranking_page_dragable => '拖动排序';

  @override
  String get ranking_page_no_title => '(无标题)';

  @override
  String get ranking_page_search_title => '搜索标题';

  @override
  String get ranking_page_no_grid_item => '暂无保存项目';

  @override
  String get ranking_page_limit_error => '最多只能添加10个项目';

  @override
  String get ranking_page_no_ranking_item => '排行中暂无项目';

  @override
  String get ranking_page_no_ranking_item_description => '请从下方列表添加项目';

  @override
  String grid_page_item_count(Object length) {
    return '$length 个项目';
  }

  @override
  String get grid_page_no_item => '暂无项目';

  @override
  String get grid_page_add_item => '选择添加方式';

  @override
  String get grid_page_by_web => '通过网页搜索添加';

  @override
  String get grid_page_by_manual => '手动添加';

  @override
  String get grid_page_cant_load_image => '无法加载图片';

  @override
  String get grid_page_no_title => '(无标题)';

  @override
  String get grid_page_url_unable => '无效的URL';

  @override
  String get grid_page_sort_title => '按标题';

  @override
  String get grid_page_sort_new => '最新优先';

  @override
  String get grid_page_sort_old => '最早优先';

  @override
  String get grid_page_sort_count_asc => '浏览量从高到低';

  @override
  String get grid_page_sort_count_desc => '浏览量从低到高';

  @override
  String grid_page_items_selected_delete(Object count) {
    return '删除选中的 $count 个项目？';
  }

  @override
  String get grid_page_rating_guidance => '已评分的项目将显示在这里';

  @override
  String get detail_page_url_empty => 'URL为空。';

  @override
  String get detail_page_input_url => '请输入URL。';

  @override
  String get detail_page_url_changed => 'URL已更改。';

  @override
  String get detail_page_url_changed_note => '更改URL将作为新项目保存。\n是否继续？';

  @override
  String get detail_page_no_selected => '未选择';

  @override
  String get detail_page_item_detail => '项目详情';

  @override
  String get detail_page_delete => '删除';

  @override
  String get detail_page_access => '浏览器';

  @override
  String get detail_page_modify => '编辑';

  @override
  String get detail_page_save => '保存';

  @override
  String get detail_page_thumbnail_placeholder => '保存后将显示缩略图';

  @override
  String get detail_page_add_image => '添加图片 ★';

  @override
  String get detail_page_rate => '评分';

  @override
  String get detail_page_title => '标题';

  @override
  String get detail_page_title_placeholder => '标题';

  @override
  String get detail_page_cast => '演员 (# 多个)';

  @override
  String get detail_page_cast_placeholder => '#演员1 #演员2 ...';

  @override
  String get detail_page_genre => '类型 (# 多个)';

  @override
  String get detail_page_genre_placeholder => '#类型1 #类型2 ...';

  @override
  String get detail_page_series => '系列 (# 多个)';

  @override
  String get detail_page_series_placeholder => '#系列1 #系列2 ...';

  @override
  String get detail_page_label => '标签 (# 多个)';

  @override
  String get detail_page_label_placeholder => '#标签1 #标签2 ...';

  @override
  String get detail_page_maker => '制作方 (# 多个)';

  @override
  String get detail_page_maker_placeholder => '#制作方1 #制作方2 ...';

  @override
  String get detail_page_paste_url => '粘贴URL';

  @override
  String get detail_page_fetch_title => '从URL获取标题';

  @override
  String get detail_page_list => '列表';

  @override
  String get detail_page_memo => '备注';

  @override
  String get detail_page_fetch_title_fail => '未找到标题。';

  @override
  String get detail_page_fetch_page_fail => '页面加载失败。';

  @override
  String get detail_page_ex => '发生错误。';

  @override
  String get detail_page_delete_confirm01 => '确定删除此项目？';

  @override
  String get detail_page_delete_confirm02 => '此操作无法撤销。';

  @override
  String get detail_page_url_unable => '无效的URL';

  @override
  String get detail_page_review_confirm01 =>
      '您喜欢“ArchiVe - Favorite Video Tracker”吗？';

  @override
  String get detail_page_review_confirm02 =>
      '感谢您的使用。\n\n您的反馈将由开发者认真查看，并用于后续改进。\n\n如果您喜欢本应用，欢迎留下评价支持我们。';

  @override
  String get detail_page_review_contact_support => '反馈或报告问题';

  @override
  String get detail_page_review_later => '稍后';

  @override
  String get detail_page_review_now => '去评价';

  @override
  String get detail_page_mail_subject => 'subject=ArchiVe Feedback';

  @override
  String get detail_page_fetching_thumbnail => '正在获取缩略图...';

  @override
  String get search_page_cast => '演员';

  @override
  String get search_page_genre => '类型';

  @override
  String get search_page_series => '系列';

  @override
  String get search_page_label => '标签';

  @override
  String get search_page_maker => '制作方';

  @override
  String get search_page_search => '搜索';

  @override
  String get search_page_select_category => '选择分类';

  @override
  String get search_page_more => '查看更多';

  @override
  String get search_page_fold => '收起';

  @override
  String get search_page_search_title => '按标题搜索';

  @override
  String get search_page_premium_title => '选择多个标签 ★';

  @override
  String get search_page_premium_description => '多分类搜索功能\n仅限高级版用户使用。';

  @override
  String get search_page_segment_button_app => '应用内';

  @override
  String get search_page_segment_button_web => '网页';

  @override
  String get search_page_text_empty => '请输入搜索内容';

  @override
  String get search_page_web_title => '网页搜索';

  @override
  String get search_page_search_word => '搜索词';

  @override
  String get search_page_select_site => '按网站筛选';

  @override
  String get search_page_open_site => '打开网站';

  @override
  String get search_page_modify_favorite => '编辑收藏';

  @override
  String get search_page_site_name => '网站名称';

  @override
  String get search_page_input_all => '请填写所有字段';

  @override
  String get search_page_add_favorite => '添加收藏网站';

  @override
  String get search_page_random_loading => '正在选择今日推荐…';

  @override
  String get search_page_random_this => '今日推荐！';

  @override
  String get search_result_page_site_saved => '网站已保存';

  @override
  String get search_result_page_saving_as_item => '保存项目';

  @override
  String get search_result_page_saving_list => '保存到列表';

  @override
  String get search_result_page_url_already_saved => '该URL已保存';

  @override
  String get search_result_page_has_saved => '物品已保存';

  @override
  String search_result_page_delete_site(Object siteName) {
    return '是否将“$siteName”从收藏中删除？';
  }

  @override
  String get search_result_page_new_list => '新建列表';

  @override
  String get search_result_page_input_list_name => '输入列表名称';

  @override
  String get search_result_page_list_already_exists => '已存在同名列表';

  @override
  String get search_result_page_history => '历史记录';

  @override
  String get search_result_page_ad_remainder01 => '下次保存后将显示广告';

  @override
  String get search_result_page_ad_remainder02 => '显示广告';

  @override
  String get analytics => '统计';

  @override
  String get analytics_page_summary => '概览';

  @override
  String analytics_page_item_count(Object totalWorks) {
    return '已保存项目：$totalWorks';
  }

  @override
  String get analytics_page_recent_additions => '最近添加的项目';

  @override
  String analytics_page_piechart_others(Object percent) {
    return '其他\n$percent%';
  }

  @override
  String get analytics_page_view_count_top5 => '浏览量前5名';

  @override
  String get analytics_page_no_data => '暂无数据';

  @override
  String get analytics_page_evaluation => '评分';

  @override
  String get analytics_page_cast => '演员';

  @override
  String get analytics_page_genre => '类型';

  @override
  String get analytics_page_series => '系列';

  @override
  String get analytics_page_label => '标签';

  @override
  String get analytics_page_maker => '制作方';

  @override
  String get analytics_page_premium_title => '统计功能 ★';

  @override
  String get analytics_page_premium_description =>
      '统计功能仅在 ArchiVe Premium 中提供。\n请升级后使用。';

  @override
  String get analytics_page_premium_button => '查看高级版详情';

  @override
  String analytics_page_list_value(Object entry, Object percent) {
    return '$percent%（$entry个）';
  }

  @override
  String get analytics_page_count => '（浏览）';

  @override
  String analytics_page_toolchip_count(Object rod) {
    return '$rod 次浏览';
  }

  @override
  String get analytics_page_no_title => '无标题';

  @override
  String get analytics_page_item_count_top5 => '项目数量前5名';

  @override
  String get analytics_page_kpi_saved_count => '收藏数';

  @override
  String get analytics_page_kpi_total_view_count => '总观看次数';

  @override
  String get analytics_page_kpi_rating_rate => '评价率';

  @override
  String get analytics_page_most_watched => '最多播放';

  @override
  String analytics_page_view_times(Object count) {
    return '观看 $count 次';
  }

  @override
  String analytics_page_total_view_subtitle(Object count) {
    return '总观看次数: $count';
  }

  @override
  String analytics_page_rated_subtitle(Object ratedCount, Object total) {
    return '已评价 $ratedCount / $total 件';
  }

  @override
  String get analytics_page_unit_items => '件';

  @override
  String analytics_page_ranked_row_stat(Object count, Object percent) {
    return '$percent%  $count件';
  }

  @override
  String analytics_page_times_unit(Object count) {
    return '$count次';
  }

  @override
  String get analytics_page_view_count_by_rating => '按评价的观看次数';

  @override
  String get analytics_page_saved_by_list => '按列表保存数';

  @override
  String analytics_page_list_count_subtitle(Object count) {
    return '$count个列表';
  }

  @override
  String analytics_page_type_count_subtitle(Object count) {
    return '$count种类';
  }

  @override
  String get settings => '设置';

  @override
  String get settings_page_dark_mode => '深色模式';

  @override
  String get settings_page_theme_color => '主题颜色 ★';

  @override
  String get settings_page_theme_color_orange => '橙色';

  @override
  String get settings_page_theme_color_green => '绿色';

  @override
  String get settings_page_theme_color_blue => '蓝色';

  @override
  String get settings_page_theme_color_white => '白色';

  @override
  String get settings_page_theme_color_red => '红色';

  @override
  String get settings_page_theme_color_yellow => '黄色';

  @override
  String get settings_page_thumbnail_visibility => '显示列表缩略图';

  @override
  String get settings_page_save_status => '保存状态';

  @override
  String get settings_page_save_count => '已保存项目数';

  @override
  String get settings_page_watch_count => '今日浏览数';

  @override
  String settings_page_watch_ad_today(Object watchedAdsToday) {
    return '$watchedAdsToday / 3';
  }

  @override
  String get settings_page_watch_ad => '观看广告（+5个名额）';

  @override
  String get settings_page_ad_limit_reached => '今日广告次数已达上限';

  @override
  String get settings_page_already_purchased => '已购买。';

  @override
  String get settings_page_premium => 'ArchiVe Premium';

  @override
  String get settings_page_app_version => '应用版本';

  @override
  String get settings_page_plivacy_policy => '隐私政策';

  @override
  String get settings_page_disable_link => '无法打开链接';

  @override
  String get settings_page_terms => '服务条款（Apple 标准 EULA）';

  @override
  String get settings_page_save_count_increased => '保存上限增加 +5';

  @override
  String get setting_page_unlimited => '无限制';

  @override
  String view_counter_view_count(Object viewCount) {
    return '浏览次数：$viewCount';
  }

  @override
  String get random_image_no_image => '无法加载图片';

  @override
  String get random_image_change_list_name => '更改列表名称';

  @override
  String get random_image_change_list_name_dialog => '更改列表名称';

  @override
  String get random_image_change_list_name_hint => '输入列表名称';

  @override
  String get random_image_change_list_name_confirm => '更改';

  @override
  String get random_image_delete_list => '删除列表';

  @override
  String get random_image_delete_list_dialog => '确定删除此列表？';

  @override
  String get random_image_delete_list_dialog_description => '该列表中的项目也将被删除。';

  @override
  String get random_image_delete_list_confirm => '删除';

  @override
  String get premium_detail_premium_title => 'ArchiVe Premium';

  @override
  String get premium_detail_premium_item01 => '无限保存';

  @override
  String get premium_detail_premium_item02 => '自由更改主题颜色';

  @override
  String get premium_detail_premium_item03 => '自由添加图片';

  @override
  String get premium_detail_premium_item04 => '使用多个标签快速搜索';

  @override
  String get premium_detail_premium_item05 => '按类别和评分可视化数据的统计功能';

  @override
  String get premium_detail_premium_item06 => '去除广告';

  @override
  String get premium_detail_note => '1个月免费试用结束后，将自动续订。\n您可以随时取消。';

  @override
  String get premium_detail_restore_not_found => '未找到购买记录';

  @override
  String get premium_detail_free_trial_badge => '1个月免费';

  @override
  String get premium_detail_start_trial => '开始1个月免费试用';

  @override
  String premium_detail_price_after_trial(Object price) {
    return '之后 $price / 月';
  }

  @override
  String get premium_detail_restore_button => '恢复购买';

  @override
  String get premium_detail_purchase_complete => '高级版购买成功！';

  @override
  String get premium_detail_restart_message => '高级功能已启用。\n应用将重新启动。';

  @override
  String get tutorial => '教程';

  @override
  String get tutorial_01 => '首先，创建一个列表。';

  @override
  String get tutorial_02 => '打开刚创建的列表。';

  @override
  String get tutorial_03 => '点击 + 按钮添加项目。';

  @override
  String get tutorial_04 => '输入视频或内容的URL。';

  @override
  String get tutorial_05 => '点击此按钮自动获取标题。';

  @override
  String get tutorial_06 => '最后点击保存，将其添加到列表中。';

  @override
  String get start_tutorial_dialog => '重新开始教程？';

  @override
  String get start_tutorial_dialog_description => '将从创建列表开始重新演示步骤。';

  @override
  String get completed_tutorial => '教程完成！\n做得很好！';

  @override
  String get tutorial_list_name => '稍后观看';

  @override
  String get tutorial_slide_title_01 => '无需下载\n轻松管理视频';

  @override
  String get tutorial_slide_dict_01 => '无需占用存储空间\n无限收集视频';

  @override
  String get tutorial_slide_image_01 => 'assets/tutorial/english01.png';

  @override
  String get tutorial_slide_title_02 => '[两步完成]\n1. 复制URL';

  @override
  String get tutorial_slide_dict_02 => '从任意视频网站复制分享链接或浏览器URL';

  @override
  String get tutorial_slide_image_02 => 'assets/tutorial/english02.png';

  @override
  String get tutorial_slide_title_03 => '[两步完成]\n2. 保存URL';

  @override
  String get tutorial_slide_dict_03 => '粘贴即可保存\n还可添加评分、标签和备注';

  @override
  String get tutorial_slide_image_03 => 'assets/tutorial/english03.png';

  @override
  String get tutorial_slide_title_04 => '应用内搜索';

  @override
  String get tutorial_slide_dict_04 => '通过标题或标签\n即时查找已保存的视频';

  @override
  String get tutorial_slide_image_04 => 'assets/tutorial/english04.png';

  @override
  String get tutorial_slide_title_05 => '网页搜索';

  @override
  String get tutorial_slide_dict_05 => '使用应用内浏览器\n立即浏览并保存视频';

  @override
  String get tutorial_slide_image_05 => 'assets/tutorial/english05.png';

  @override
  String get tutorial_slide_title_06 => '无限可能';

  @override
  String get tutorial_slide_dict_06 => '打造属于你的个人视频收藏！';

  @override
  String get tutorial_slide_image_06 => 'assets/tutorial/english06.png';

  @override
  String get tutorial_slide_next => '下一步';

  @override
  String get tutorial_slide_start => '开始使用';

  @override
  String get share_saved => '已从分享中保存';

  @override
  String get share_already_saved => '该URL已保存';

  @override
  String get share_dialog_title => '保存到 ArchiVe';

  @override
  String get share_list_section => '保存列表';

  @override
  String get share_title_hint => '输入标题';

  @override
  String get clipboard_dialog_title => '是否添加剪贴板中的URL？';
}
