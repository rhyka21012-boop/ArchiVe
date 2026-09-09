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
  String get critical => '神级';

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
  String get main_page_search => '搜索';

  @override
  String get main_page_browser => '浏览器';

  @override
  String get browser_home_url_hint => '输入网址或搜索';

  @override
  String get browser_home_history => '历史记录';

  @override
  String get browser_home_history_empty => '还没有历史记录';

  @override
  String get browser_home_history_clear => '清除';

  @override
  String get browser_home_history_clear_confirm => '清除所有浏览历史？';

  @override
  String get browser_home_favorites => '常用网站';

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
  String get list_page_home => '主页';

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
  String get reset => '重置';

  @override
  String get list_page_rating_rename_title => '修改评价名称';

  @override
  String get list_page_reorder => '排序';

  @override
  String get list_page_reorder_done => '完成';

  @override
  String get list_page_reorder_hint => '拖动以更改顺序';

  @override
  String get list_page_all_item_fixed => '「全部项目」无法排序';

  @override
  String list_page_save_count(int count, int limit) {
    return '已保存 $count / $limit';
  }

  @override
  String get list_page_item_unit => '项';

  @override
  String list_page_item_count(int count) {
    return '$count项';
  }

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
  String get grid_page_sort_rating => '按评价';

  @override
  String get grid_page_sort_offline_first => '离线优先';

  @override
  String get grid_page_sort_list_name => '按列表名';

  @override
  String get grid_page_sort_random => '随机';

  @override
  String get grid_page_sort_by_cast => '按演员';

  @override
  String get grid_page_sort_by_date => '按添加日期';

  @override
  String grid_page_sort_current(String label) {
    return '排序: $label';
  }

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
  String get detail_page_share => '分享';

  @override
  String get detail_page_copied => '已复制';

  @override
  String detail_page_saved_to(String listName) {
    return '已保存到 $listName';
  }

  @override
  String get detail_page_save => '保存';

  @override
  String get detail_page_thumbnail_placeholder => '保存后将显示缩略图';

  @override
  String get detail_page_add_image => '添加缩略图 ★';

  @override
  String get detail_page_offline => '离线';

  @override
  String get detail_page_offline_downloaded => '已离线保存';

  @override
  String get detail_page_offline_confirm_title => '将该作品保存到本地？';

  @override
  String get detail_page_offline_confirm_body =>
      '视频将被下载到此设备。\n※仅可保存您拥有版权或已获得授权的视频。';

  @override
  String get detail_page_offline_no_url => 'URL 未输入';

  @override
  String get detail_page_offline_started => '开始下载';

  @override
  String get detail_page_offline_probing => '正在检查可用分辨率…';

  @override
  String get detail_page_delete_offline_confirm => '要删除该作品的离线数据吗？\n（不影响在线播放）';

  @override
  String get detail_page_offline_deleted => '已删除离线数据';

  @override
  String get consent_page_title => '使用前须知';

  @override
  String get consent_page_subtitle => '使用本应用前，请阅读并同意以下内容。';

  @override
  String get consent_page_privacy_title => '隐私政策';

  @override
  String get consent_page_privacy_body => '本应用致力于妥善处理个人信息，请查阅完整政策。';

  @override
  String get consent_page_terms_title => '使用条款';

  @override
  String get consent_page_terms_body => '请务必阅读本应用的使用条款。';

  @override
  String get consent_page_ip_summary =>
      '本应用是一款通用工具，对用户输入的URL提供下载和离线播放。您需自行遵守著作权及来源网站的使用条款。';

  @override
  String get consent_page_agree_checkbox => '我已阅读并同意上述所有内容';

  @override
  String get consent_page_agree => '同意并开始';

  @override
  String get consent_page_read_more => '阅读全文';

  @override
  String get settings_page_ip_disclaimer => '知识产权免责声明';

  @override
  String get settings_page_ip_disclaimer_body =>
      '本应用是一款通用工具，提供用户自行输入的视频URL的下载与离线播放功能，并非以获取特定网站内容为目的。\n\n用户应自行负责以下事项：\n・遵守所保存视频内容的著作权及来源网站的使用条款\n・不得将所保存内容超出私人使用范围进行复制、发布、公开或商业利用\n・不得侵犯第三方著作权、肖像权、公开权等其他权利\n・不得规避来源网站的技术保护措施\n\n本应用提供方对因用户使用本应用而产生的著作权侵犯、条款违反等任何法律责任概不承担。\n\n如有疑虑，请勿使用并咨询著作权人或内容提供方。本应用仅根据用户输入运行，不代表对特定服务的推荐或合作。';

  @override
  String get detail_page_offline_not_direct_video =>
      '此网址不是视频文件的直链，无法离线保存。\n（不支持 YouTube 等页面网址，请使用 mp4/m4v/mov/webm/mkv 格式的直链）';

  @override
  String get detail_page_offline_failed => '下载失败';

  @override
  String get download_failed_but_saved => '已保存网址书签（视频文件未下载）';

  @override
  String get download_cancel_confirm_title => '取消此下载吗？';

  @override
  String get download_cancel_confirm_body => '将中断进行中的下载并删除此任务。确定继续？';

  @override
  String get detail_page_offline_hls_not_supported =>
      '该视频为 HLS 格式 (.m3u8)，不支持离线保存。';

  @override
  String get browser_video_detected_chip => '检测到视频';

  @override
  String get browser_video_detected_sheet_title => '检测到的视频';

  @override
  String get browser_video_detected_sheet_desc => '请选择要下载的视频。';

  @override
  String get browser_video_download => '下载此视频';

  @override
  String get browser_video_download_started => '已开始下载';

  @override
  String get browser_video_download_saved_first => '先保存为作品，然后开始下载';

  @override
  String get search_result_page_offline => '离线保存';

  @override
  String get search_result_page_offline_desc => '将该作品下载到本地，可在无网络时播放。';

  @override
  String get download_queue_title => '下载';

  @override
  String get download_clear_finished => '清除已完成';

  @override
  String get download_empty => '当前没有下载任务';

  @override
  String get download_status_queued => '等待中';

  @override
  String get download_status_completed => '已完成';

  @override
  String get download_status_failed => '失败';

  @override
  String get download_cancel_all_confirm => '取消所有下载吗？';

  @override
  String get download_status_canceled => '已取消';

  @override
  String get download_premium_required_title => 'Premium 专属功能';

  @override
  String get download_premium_required_body => '离线下载功能仅在 Premium 及以上方案中提供。';

  @override
  String get detail_page_rate => '评分';

  @override
  String get detail_page_title => '标题';

  @override
  String get detail_page_title_placeholder => '标题';

  @override
  String get detail_page_cast_short => '演员';

  @override
  String get detail_page_genre_short => '类型';

  @override
  String get detail_page_series_short => '系列';

  @override
  String get detail_page_maker_short => '制作方';

  @override
  String get detail_page_label_short => '厂牌';

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
  String get detail_page_review_confirm01 => '您喜欢 ArchiVe 吗？';

  @override
  String get detail_page_review_confirm02 => '期待您的好评支持！';

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
  String get search_page_search_word => '网络搜索';

  @override
  String get search_page_hint_web_1 => '内置广告拦截，畅快搜索';

  @override
  String get search_page_hint_web_2 => '例：动漫 OP';

  @override
  String get search_page_hint_web_3 => '应用内浏览器，快速收藏视频';

  @override
  String get search_page_hint_web_4 => '例：现场直播 2026';

  @override
  String get search_page_hint_web_5 => '在收藏的网站深入探索';

  @override
  String get search_page_hint_web_6 => '例：简单菜谱';

  @override
  String get search_page_select_site => '收藏站点';

  @override
  String get search_page_select_site_help_title => '按网站筛选';

  @override
  String get search_page_select_site_help_description =>
      '可以将视频搜索范围限定到特定网站。注册您喜欢的视频网站，仅在该网站内进行搜索。从下方列表选择网站后，点击搜索按钮。';

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
  String get search_page_random_again => '再转一次';

  @override
  String get search_result_page_site_saved => '网站已保存';

  @override
  String get search_result_page_saving_as_item => '保存项目';

  @override
  String get search_result_page_saving_list => '保存到列表';

  @override
  String get search_result_page_url_already_saved => '该URL已保存';

  @override
  String get search_result_page_url_already_saved_offline_prompt =>
      '要将该作品下载到本地以便离线观看吗？';

  @override
  String get search_result_page_url_already_saved_and_downloaded =>
      '该作品已保存并已下载';

  @override
  String get download_retry => '重试';

  @override
  String get player_minimize => '切换到迷你播放器';

  @override
  String get player_close => '关闭';

  @override
  String get player_speed => '播放速度';

  @override
  String player_speed_x(String v) {
    return '${v}x';
  }

  @override
  String get player_speed_custom => '自定义';

  @override
  String get player_bookmarks => '书签';

  @override
  String get player_bookmarks_empty => '还没有书签';

  @override
  String get browser_video_size => '大小';

  @override
  String get browser_video_size_unknown => '大小未知';

  @override
  String get browser_video_quality => '画质';

  @override
  String get browser_tab_max_reached => '已达到标签页上限，请先关闭标签页再新建。';

  @override
  String get browser_tabs_title => '标签页';

  @override
  String get browser_new_tab => '新标签页';

  @override
  String get offline_quality_title => '离线画质';

  @override
  String get offline_quality_desc => '请选择要下载的视频画质';

  @override
  String get offline_quality_none => '不下载离线';

  @override
  String get search_result_page_has_saved => '作品已保存';

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
  String get analytics_page_no_view_records_title => '尚无浏览记录';

  @override
  String get analytics_page_no_view_records_hint => '在作品详情中记录浏览次数后会显示';

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
  String get analytics_page_kpi_saved_count => '保存数';

  @override
  String get analytics_page_kpi_total_view_count => '总观看次数';

  @override
  String get analytics_page_kpi_rating_rate => '评价率';

  @override
  String get analytics_page_most_watched => '最多观看';

  @override
  String analytics_page_view_times(Object count) {
    return '观看 $count 次';
  }

  @override
  String analytics_page_total_view_subtitle(Object count) {
    return '总观看次数：$count';
  }

  @override
  String analytics_page_rated_subtitle(Object ratedCount, Object total) {
    return '已评价 $ratedCount / $total 项';
  }

  @override
  String get analytics_page_unit_items => '项';

  @override
  String analytics_page_ranked_row_stat(Object count, Object percent) {
    return '$percent%  $count项';
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
  String get settings_page_theme_color => '主题颜色';

  @override
  String get settings_page_theme_color_orange => '橙色';

  @override
  String get settings_page_theme_color_random => '随机';

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
  String get settings_page_save_status => '项目数';

  @override
  String get settings_page_offline_videos => '离线视频';

  @override
  String get settings_page_offline_total_size => '离线视频总大小';

  @override
  String get settings_page_save_count => '书签';

  @override
  String get settings_page_watch_count => '今日浏览数';

  @override
  String settings_page_watch_ad_today(Object watchedAdsToday) {
    return '$watchedAdsToday / 5';
  }

  @override
  String get settings_page_watch_ad => '观看广告（+1个名额）';

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
  String get settings_page_save_count_increased => '保存上限增加 +1';

  @override
  String get setting_page_unlimited => '无限制';

  @override
  String view_counter_view_count(Object viewCount) {
    return '浏览 $viewCount';
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
  String get premium_detail_premium_item02 => '新增主题色 金色';

  @override
  String get premium_detail_premium_item03 => '自由添加图片';

  @override
  String get premium_detail_premium_item04 => '使用多个标签快速搜索';

  @override
  String get premium_detail_premium_item05 => '按类别和评分可视化数据的统计功能';

  @override
  String get premium_detail_premium_item06 => '去除广告';

  @override
  String get premium_detail_note => '3 天免费试用后将自动续费。\n随时可以取消。';

  @override
  String get premium_detail_restore_not_found => '未找到购买记录';

  @override
  String get premium_detail_free_trial_badge => '3 天免费';

  @override
  String get premium_detail_start_trial => '开始 3 天免费试用';

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

  @override
  String get ranking_page_add_item => '添加项目';

  @override
  String get search_page_url_cant_open => '无法打开此URL';

  @override
  String get premium_detail_plan_monthly => '月度';

  @override
  String get premium_detail_plan_annual => '年度';

  @override
  String get premium_detail_best_value => '推荐';

  @override
  String premium_detail_save_percent(String percent) {
    return '节省 $percent%';
  }

  @override
  String get premium_detail_per_month => '/ 月';

  @override
  String get premium_detail_per_year => '/ 年';

  @override
  String premium_detail_price_after_trial_yearly(String price) {
    return '之后 $price / 年';
  }

  @override
  String get settings_page_free_plan => '免费方案';

  @override
  String get settings_page_current_plan => '当前方案';

  @override
  String get settings_page_premium_details_link => '解锁保存上限及更多详情';

  @override
  String get settings_page_section_appearance => '外观';

  @override
  String get settings_page_section_about => '关于';

  @override
  String get settings_page_section_legal => '法律信息';

  @override
  String get settings_page_period_monthly => '月度';

  @override
  String get settings_page_period_annual => '年度';

  @override
  String get settings_page_theme_color_pink => '粉色';

  @override
  String get settings_page_theme_color_purple => '紫色';

  @override
  String get settings_page_theme_color_teal => '青绿色';

  @override
  String get login_page_title => '登录';

  @override
  String get login_page_description => '登录以使用 ArchiVe Pro 功能。';

  @override
  String get login_with_apple => '使用 Apple 登录';

  @override
  String get login_with_google => '使用 Google 登录';

  @override
  String get login_failed => '登录失败';

  @override
  String get logout => '退出登录';

  @override
  String get logout_confirm => '要退出登录吗？';

  @override
  String get settings_page_section_account => '账户';

  @override
  String get settings_page_not_signed_in => '未登录';

  @override
  String get pro_detail_title => 'ArchiVe Pro';

  @override
  String get pro_detail_subtitle => '在所有 Premium 功能基础上还包含以下功能';

  @override
  String get pro_detail_feature_cloud_sync => '云同步（多设备）';

  @override
  String get pro_detail_feature_ai_tagging => 'AI 自动标签';

  @override
  String get pro_detail_feature_ai_recommend => 'AI 推荐关键词';

  @override
  String get pro_detail_feature_monthly_report => 'AI 月度报告';

  @override
  String get pro_detail_feature_public_sharing => '公开列表分享';

  @override
  String get pro_detail_feature_theme_teal => '新增主题色 青绿色';

  @override
  String get plans_page_title => '方案';

  @override
  String get plans_page_current_badge => '当前';

  @override
  String get plans_page_includes_premium => '包含所有 Premium 功能';

  @override
  String get detail_page_ai_suggest => '使用 AI 推荐标签';

  @override
  String get detail_page_ai_suggest_dialog_title => 'AI 标签建议';

  @override
  String get detail_page_ai_suggest_dialog_hint => '以下是推荐的标签！请选择要应用的标签。';

  @override
  String get detail_page_ai_apply => '应用';

  @override
  String get detail_page_ai_no_suggestions => '没有可推荐的标签';

  @override
  String get detail_page_ai_from_library => '来自已有标签';

  @override
  String get detail_page_ai_daily_limit_title => '已达到今日 AI 使用上限';

  @override
  String get detail_page_ai_daily_limit_body =>
      'AI 标签建议在免费版 / Premium 方案中每天可使用 1 次。\n升级至 Pro 方案即可无限使用。';

  @override
  String get detail_page_ai_upgrade_pro => '查看 Pro 方案';

  @override
  String get detail_page_ai_loading => 'AI 分析中...';

  @override
  String get detail_page_ai_error => 'AI 推荐错误';

  @override
  String get share_title => '分享列表';

  @override
  String get share_loading => '分享中...';

  @override
  String get share_url_label => '分享 URL';

  @override
  String get share_copy => '复制';

  @override
  String get share_copied => '已复制';

  @override
  String get share_unshare => '取消分享';

  @override
  String get share_unshare_confirm => '要取消分享此列表吗？';

  @override
  String get share_create_action => '分享此列表';

  @override
  String get share_error => '分享错误';

  @override
  String get share_open_url => '打开分享 URL';

  @override
  String get share_description => '任何拥有此 URL 的人都可以查看此列表（只读）';

  @override
  String get share_limit_notice => '最多分享 200 个项目';

  @override
  String get analytics_monthly_report_title => 'AI 摘要';

  @override
  String analytics_monthly_report_subtitle(int month) {
    return '$month月摘要';
  }

  @override
  String get analytics_monthly_report_generate => '生成总结';

  @override
  String get analytics_monthly_report_regenerate => '重新生成';

  @override
  String get analytics_monthly_report_loading => 'AI 正在分析...';

  @override
  String get analytics_monthly_report_empty => '点击让 AI 总结本月的归档活动。';

  @override
  String get analytics_monthly_report_error => '报告错误';

  @override
  String get analytics_monthly_report_cached => '来自缓存';

  @override
  String get search_result_loading => '加载中';

  @override
  String get grid_page_move_action => '移动';

  @override
  String get grid_page_move_to_list_title => '选择目标列表';

  @override
  String get grid_page_move_done => '项已移动';

  @override
  String get undo => '撤销';

  @override
  String get settings_page_theme_color_gold => '金色';

  @override
  String get plans_page_premium_short => '高级版';

  @override
  String get plans_page_pro_short => 'Pro';

  @override
  String get plans_page_free_short => '免费';

  @override
  String get plans_page_free_price => '¥0';

  @override
  String get plans_page_free_item01 => '可保存 100 件';

  @override
  String get plans_page_free_item02 => '观看广告扩展 15 个名额/日';

  @override
  String get plans_page_free_item03 => '单一标签搜索';

  @override
  String get plans_page_free_item04 => '显示广告';

  @override
  String get share_pro_required_title => 'Pro 套餐专属功能';

  @override
  String get share_pro_required_description => '公开列表分享需要购买 Pro 套餐。';

  @override
  String get share_pro_required_action => '查看 Pro 套餐';

  @override
  String get pro_locked_badge => 'Pro 限定';

  @override
  String get pro_locked_unlock => '用 Pro 解锁';

  @override
  String get apple_signin_warning_title => '使用 Apple 帐户登录？';

  @override
  String get apple_signin_warning_description =>
      'Apple 帐户无法在 Android 设备上登录，因此数据无法跨平台共享。如需多设备使用，建议使用 Google 帐户。';

  @override
  String get apple_signin_warning_continue => '继续使用 Apple';

  @override
  String get settings_page_manage_subscription => '管理订阅';

  @override
  String get search_page_ai_recommend_title => 'AI 推荐';

  @override
  String get search_page_ai_recommend_subtitle => '根据你的库提供关键词建议';

  @override
  String get search_page_ai_recommend_generate => '获取推荐';

  @override
  String get search_page_ai_recommend_refresh => '重新生成';

  @override
  String get search_page_ai_recommend_loading => 'AI 正在分析...';

  @override
  String get search_page_ai_recommend_error => '获取推荐失败';

  @override
  String get search_page_ai_recommend_empty => '已保存的内容不足，无法生成建议。请添加更多后再试。';

  @override
  String get search_page_ai_recommend_intro => '点击按钮，让 AI 根据已保存的库推荐相关搜索关键词。';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class L10nZhHans extends L10nZh {
  L10nZhHans() : super('zh_Hans');

  @override
  String get app_title => 'ArchiVe';

  @override
  String get version => 'v1.8';

  @override
  String get critical => '神级';

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
  String get main_page_search => '搜索';

  @override
  String get main_page_browser => '浏览器';

  @override
  String get browser_home_url_hint => '输入网址或搜索';

  @override
  String get browser_home_history => '历史记录';

  @override
  String get browser_home_history_empty => '还没有历史记录';

  @override
  String get browser_home_history_clear => '清除';

  @override
  String get browser_home_history_clear_confirm => '清除所有浏览历史？';

  @override
  String get browser_home_favorites => '常用网站';

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
  String get list_page_home => '主页';

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
  String get reset => '重置';

  @override
  String get list_page_rating_rename_title => '修改评价名称';

  @override
  String get list_page_reorder => '排序';

  @override
  String get list_page_reorder_done => '完成';

  @override
  String get list_page_reorder_hint => '拖动以更改顺序';

  @override
  String get list_page_all_item_fixed => '「全部项目」无法排序';

  @override
  String list_page_save_count(int count, int limit) {
    return '已保存 $count / $limit';
  }

  @override
  String get list_page_item_unit => '项';

  @override
  String list_page_item_count(int count) {
    return '$count项';
  }

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
  String get grid_page_sort_rating => '按评价';

  @override
  String get grid_page_sort_offline_first => '离线优先';

  @override
  String get grid_page_sort_list_name => '按列表名';

  @override
  String get grid_page_sort_random => '随机';

  @override
  String get grid_page_sort_by_cast => '按演员';

  @override
  String get grid_page_sort_by_date => '按添加日期';

  @override
  String grid_page_sort_current(String label) {
    return '排序: $label';
  }

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
  String get detail_page_share => '分享';

  @override
  String get detail_page_copied => '已复制';

  @override
  String detail_page_saved_to(String listName) {
    return '已保存到 $listName';
  }

  @override
  String get detail_page_save => '保存';

  @override
  String get detail_page_thumbnail_placeholder => '保存后将显示缩略图';

  @override
  String get detail_page_add_image => '添加缩略图 ★';

  @override
  String get detail_page_offline => '离线';

  @override
  String get detail_page_offline_downloaded => '已离线保存';

  @override
  String get detail_page_offline_confirm_title => '将该作品保存到本地？';

  @override
  String get detail_page_offline_confirm_body =>
      '视频将被下载到此设备。\n※仅可保存您拥有版权或已获得授权的视频。';

  @override
  String get detail_page_offline_no_url => 'URL 未输入';

  @override
  String get detail_page_offline_started => '开始下载';

  @override
  String get detail_page_offline_probing => '正在检查可用分辨率…';

  @override
  String get detail_page_delete_offline_confirm => '要删除该作品的离线数据吗？\n（不影响在线播放）';

  @override
  String get detail_page_offline_deleted => '已删除离线数据';

  @override
  String get consent_page_title => '使用前须知';

  @override
  String get consent_page_subtitle => '使用本应用前，请阅读并同意以下内容。';

  @override
  String get consent_page_privacy_title => '隐私政策';

  @override
  String get consent_page_privacy_body => '本应用致力于妥善处理个人信息，请查阅完整政策。';

  @override
  String get consent_page_terms_title => '使用条款';

  @override
  String get consent_page_terms_body => '请务必阅读本应用的使用条款。';

  @override
  String get consent_page_ip_summary =>
      '本应用是一款通用工具，对用户输入的URL提供下载和离线播放。您需自行遵守著作权及来源网站的使用条款。';

  @override
  String get consent_page_agree_checkbox => '我已阅读并同意上述所有内容';

  @override
  String get consent_page_agree => '同意并开始';

  @override
  String get consent_page_read_more => '阅读全文';

  @override
  String get settings_page_ip_disclaimer => '知识产权免责声明';

  @override
  String get settings_page_ip_disclaimer_body =>
      '本应用是一款通用工具，提供用户自行输入的视频URL的下载与离线播放功能，并非以获取特定网站内容为目的。\n\n用户应自行负责以下事项：\n・遵守所保存视频内容的著作权及来源网站的使用条款\n・不得将所保存内容超出私人使用范围进行复制、发布、公开或商业利用\n・不得侵犯第三方著作权、肖像权、公开权等其他权利\n・不得规避来源网站的技术保护措施\n\n本应用提供方对因用户使用本应用而产生的著作权侵犯、条款违反等任何法律责任概不承担。\n\n如有疑虑，请勿使用并咨询著作权人或内容提供方。本应用仅根据用户输入运行，不代表对特定服务的推荐或合作。';

  @override
  String get detail_page_offline_not_direct_video =>
      '此网址不是视频文件的直链，无法离线保存。\n（不支持 YouTube 等页面网址，请使用 mp4/m4v/mov/webm/mkv 格式的直链）';

  @override
  String get detail_page_offline_failed => '下载失败';

  @override
  String get download_failed_but_saved => '已保存网址书签（视频文件未下载）';

  @override
  String get download_cancel_confirm_title => '取消此下载吗？';

  @override
  String get download_cancel_confirm_body => '将中断进行中的下载并删除此任务。确定继续？';

  @override
  String get detail_page_offline_hls_not_supported =>
      '该视频为 HLS 格式 (.m3u8)，不支持离线保存。';

  @override
  String get browser_video_detected_chip => '检测到视频';

  @override
  String get browser_video_detected_sheet_title => '检测到的视频';

  @override
  String get browser_video_detected_sheet_desc => '请选择要下载的视频。';

  @override
  String get browser_video_download => '下载此视频';

  @override
  String get browser_video_download_started => '已开始下载';

  @override
  String get browser_video_download_saved_first => '先保存为作品，然后开始下载';

  @override
  String get search_result_page_offline => '离线保存';

  @override
  String get search_result_page_offline_desc => '将该作品下载到本地，可在无网络时播放。';

  @override
  String get download_queue_title => '下载';

  @override
  String get download_clear_finished => '清除已完成';

  @override
  String get download_empty => '当前没有下载任务';

  @override
  String get download_status_queued => '等待中';

  @override
  String get download_status_completed => '已完成';

  @override
  String get download_status_failed => '失败';

  @override
  String get download_cancel_all_confirm => '取消所有下载吗？';

  @override
  String get download_status_canceled => '已取消';

  @override
  String get download_premium_required_title => 'Premium 专属功能';

  @override
  String get download_premium_required_body => '离线下载功能仅在 Premium 及以上方案中提供。';

  @override
  String get detail_page_rate => '评分';

  @override
  String get detail_page_title => '标题';

  @override
  String get detail_page_title_placeholder => '标题';

  @override
  String get detail_page_cast_short => '演员';

  @override
  String get detail_page_genre_short => '类型';

  @override
  String get detail_page_series_short => '系列';

  @override
  String get detail_page_maker_short => '制作方';

  @override
  String get detail_page_label_short => '厂牌';

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
  String get detail_page_review_confirm01 => '您喜欢 ArchiVe 吗？';

  @override
  String get detail_page_review_confirm02 => '期待您的好评支持！';

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
  String get search_page_search_word => '网络搜索';

  @override
  String get search_page_hint_web_1 => '内置广告拦截，畅快搜索';

  @override
  String get search_page_hint_web_2 => '例：动漫 OP';

  @override
  String get search_page_hint_web_3 => '应用内浏览器，快速收藏视频';

  @override
  String get search_page_hint_web_4 => '例：现场直播 2026';

  @override
  String get search_page_hint_web_5 => '在收藏的网站深入探索';

  @override
  String get search_page_hint_web_6 => '例：简单菜谱';

  @override
  String get search_page_select_site => '收藏站点';

  @override
  String get search_page_select_site_help_title => '按网站筛选';

  @override
  String get search_page_select_site_help_description =>
      '可以将视频搜索范围限定到特定网站。注册您喜欢的视频网站，仅在该网站内进行搜索。从下方列表选择网站后，点击搜索按钮。';

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
  String get search_page_random_again => '再转一次';

  @override
  String get search_result_page_site_saved => '网站已保存';

  @override
  String get search_result_page_saving_as_item => '保存项目';

  @override
  String get search_result_page_saving_list => '保存到列表';

  @override
  String get search_result_page_url_already_saved => '该URL已保存';

  @override
  String get search_result_page_url_already_saved_offline_prompt =>
      '要将该作品下载到本地以便离线观看吗？';

  @override
  String get search_result_page_url_already_saved_and_downloaded =>
      '该作品已保存并已下载';

  @override
  String get download_retry => '重试';

  @override
  String get player_minimize => '切换到迷你播放器';

  @override
  String get player_close => '关闭';

  @override
  String get player_speed => '播放速度';

  @override
  String player_speed_x(String v) {
    return '${v}x';
  }

  @override
  String get player_speed_custom => '自定义';

  @override
  String get player_bookmarks => '书签';

  @override
  String get player_bookmarks_empty => '还没有书签';

  @override
  String get browser_video_size => '大小';

  @override
  String get browser_video_size_unknown => '大小未知';

  @override
  String get browser_video_quality => '画质';

  @override
  String get browser_tab_max_reached => '已达到标签页上限，请先关闭标签页再新建。';

  @override
  String get browser_tabs_title => '标签页';

  @override
  String get browser_new_tab => '新标签页';

  @override
  String get offline_quality_title => '离线画质';

  @override
  String get offline_quality_desc => '请选择要下载的视频画质';

  @override
  String get offline_quality_none => '不下载离线';

  @override
  String get search_result_page_has_saved => '作品已保存';

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
  String get analytics_page_no_view_records_title => '尚无浏览记录';

  @override
  String get analytics_page_no_view_records_hint => '在作品详情中记录浏览次数后会显示';

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
  String get analytics_page_kpi_saved_count => '保存数';

  @override
  String get analytics_page_kpi_total_view_count => '总观看次数';

  @override
  String get analytics_page_kpi_rating_rate => '评价率';

  @override
  String get analytics_page_most_watched => '最多观看';

  @override
  String analytics_page_view_times(Object count) {
    return '观看 $count 次';
  }

  @override
  String analytics_page_total_view_subtitle(Object count) {
    return '总观看次数：$count';
  }

  @override
  String analytics_page_rated_subtitle(Object ratedCount, Object total) {
    return '已评价 $ratedCount / $total 项';
  }

  @override
  String get analytics_page_unit_items => '项';

  @override
  String analytics_page_ranked_row_stat(Object count, Object percent) {
    return '$percent%  $count项';
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
  String get settings_page_theme_color => '主题颜色';

  @override
  String get settings_page_theme_color_orange => '橙色';

  @override
  String get settings_page_theme_color_random => '随机';

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
  String get settings_page_save_status => '项目数';

  @override
  String get settings_page_offline_videos => '离线视频';

  @override
  String get settings_page_offline_total_size => '离线视频总大小';

  @override
  String get settings_page_save_count => '书签';

  @override
  String get settings_page_watch_count => '今日浏览数';

  @override
  String settings_page_watch_ad_today(Object watchedAdsToday) {
    return '$watchedAdsToday / 5';
  }

  @override
  String get settings_page_watch_ad => '观看广告（+1个名额）';

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
  String get settings_page_save_count_increased => '保存上限增加 +1';

  @override
  String get setting_page_unlimited => '无限制';

  @override
  String view_counter_view_count(Object viewCount) {
    return '浏览 $viewCount';
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
  String get premium_detail_premium_item02 => '新增主题色 金色';

  @override
  String get premium_detail_premium_item03 => '自由添加图片';

  @override
  String get premium_detail_premium_item04 => '使用多个标签快速搜索';

  @override
  String get premium_detail_premium_item05 => '按类别和评分可视化数据的统计功能';

  @override
  String get premium_detail_premium_item06 => '去除广告';

  @override
  String get premium_detail_note => '3 天免费试用后将自动续费。\n随时可以取消。';

  @override
  String get premium_detail_restore_not_found => '未找到购买记录';

  @override
  String get premium_detail_free_trial_badge => '3 天免费';

  @override
  String get premium_detail_start_trial => '开始 3 天免费试用';

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

  @override
  String get ranking_page_add_item => '添加项目';

  @override
  String get search_page_url_cant_open => '无法打开此URL';

  @override
  String get premium_detail_plan_monthly => '月度';

  @override
  String get premium_detail_plan_annual => '年度';

  @override
  String get premium_detail_best_value => '推荐';

  @override
  String premium_detail_save_percent(String percent) {
    return '节省 $percent%';
  }

  @override
  String get premium_detail_per_month => '/ 月';

  @override
  String get premium_detail_per_year => '/ 年';

  @override
  String premium_detail_price_after_trial_yearly(String price) {
    return '之后 $price / 年';
  }

  @override
  String get settings_page_free_plan => '免费方案';

  @override
  String get settings_page_current_plan => '当前方案';

  @override
  String get settings_page_premium_details_link => '解锁保存上限及更多详情';

  @override
  String get settings_page_section_appearance => '外观';

  @override
  String get settings_page_section_about => '关于';

  @override
  String get settings_page_section_legal => '法律信息';

  @override
  String get settings_page_period_monthly => '月度';

  @override
  String get settings_page_period_annual => '年度';

  @override
  String get settings_page_theme_color_pink => '粉色';

  @override
  String get settings_page_theme_color_purple => '紫色';

  @override
  String get settings_page_theme_color_teal => '青绿色';

  @override
  String get login_page_title => '登录';

  @override
  String get login_page_description => '登录以使用 ArchiVe Pro 功能。';

  @override
  String get login_with_apple => '使用 Apple 登录';

  @override
  String get login_with_google => '使用 Google 登录';

  @override
  String get login_failed => '登录失败';

  @override
  String get logout => '退出登录';

  @override
  String get logout_confirm => '要退出登录吗？';

  @override
  String get settings_page_section_account => '账户';

  @override
  String get settings_page_not_signed_in => '未登录';

  @override
  String get pro_detail_title => 'ArchiVe Pro';

  @override
  String get pro_detail_subtitle => '在所有 Premium 功能基础上还包含以下功能';

  @override
  String get pro_detail_feature_cloud_sync => '云同步（多设备）';

  @override
  String get pro_detail_feature_ai_tagging => 'AI 自动标签';

  @override
  String get pro_detail_feature_ai_recommend => 'AI 推荐关键词';

  @override
  String get pro_detail_feature_monthly_report => 'AI 月度报告';

  @override
  String get pro_detail_feature_public_sharing => '公开列表分享';

  @override
  String get pro_detail_feature_theme_teal => '新增主题色 青绿色';

  @override
  String get plans_page_title => '方案';

  @override
  String get plans_page_current_badge => '当前';

  @override
  String get plans_page_includes_premium => '包含所有 Premium 功能';

  @override
  String get detail_page_ai_suggest => '使用 AI 推荐标签';

  @override
  String get detail_page_ai_suggest_dialog_title => 'AI 标签建议';

  @override
  String get detail_page_ai_suggest_dialog_hint => '以下是推荐的标签！请选择要应用的标签。';

  @override
  String get detail_page_ai_apply => '应用';

  @override
  String get detail_page_ai_no_suggestions => '没有可推荐的标签';

  @override
  String get detail_page_ai_from_library => '来自已有标签';

  @override
  String get detail_page_ai_daily_limit_title => '已达到今日 AI 使用上限';

  @override
  String get detail_page_ai_daily_limit_body =>
      'AI 标签建议在免费版 / Premium 方案中每天可使用 1 次。\n升级至 Pro 方案即可无限使用。';

  @override
  String get detail_page_ai_upgrade_pro => '查看 Pro 方案';

  @override
  String get detail_page_ai_loading => 'AI 分析中...';

  @override
  String get detail_page_ai_error => 'AI 推荐错误';

  @override
  String get share_title => '分享列表';

  @override
  String get share_loading => '分享中...';

  @override
  String get share_url_label => '分享 URL';

  @override
  String get share_copy => '复制';

  @override
  String get share_copied => '已复制';

  @override
  String get share_unshare => '取消分享';

  @override
  String get share_unshare_confirm => '要取消分享此列表吗？';

  @override
  String get share_create_action => '分享此列表';

  @override
  String get share_error => '分享错误';

  @override
  String get share_open_url => '打开分享 URL';

  @override
  String get share_description => '任何拥有此 URL 的人都可以查看此列表（只读）';

  @override
  String get share_limit_notice => '最多分享 200 个项目';

  @override
  String get analytics_monthly_report_title => 'AI 摘要';

  @override
  String analytics_monthly_report_subtitle(int month) {
    return '$month月摘要';
  }

  @override
  String get analytics_monthly_report_generate => '生成总结';

  @override
  String get analytics_monthly_report_regenerate => '重新生成';

  @override
  String get analytics_monthly_report_loading => 'AI 正在分析...';

  @override
  String get analytics_monthly_report_empty => '点击让 AI 总结本月的归档活动。';

  @override
  String get analytics_monthly_report_error => '报告错误';

  @override
  String get analytics_monthly_report_cached => '来自缓存';

  @override
  String get search_result_loading => '加载中';

  @override
  String get grid_page_move_action => '移动';

  @override
  String get grid_page_move_to_list_title => '选择目标列表';

  @override
  String get grid_page_move_done => '项已移动';

  @override
  String get undo => '撤销';

  @override
  String get settings_page_theme_color_gold => '金色';

  @override
  String get plans_page_premium_short => '高级版';

  @override
  String get plans_page_pro_short => 'Pro';

  @override
  String get plans_page_free_short => '免费';

  @override
  String get plans_page_free_price => '¥0';

  @override
  String get plans_page_free_item01 => '可保存 100 件';

  @override
  String get plans_page_free_item02 => '观看广告扩展 15 个名额/日';

  @override
  String get plans_page_free_item03 => '单一标签搜索';

  @override
  String get plans_page_free_item04 => '显示广告';

  @override
  String get share_pro_required_title => 'Pro 套餐专属功能';

  @override
  String get share_pro_required_description => '公开列表分享需要购买 Pro 套餐。';

  @override
  String get share_pro_required_action => '查看 Pro 套餐';

  @override
  String get pro_locked_badge => 'Pro 限定';

  @override
  String get pro_locked_unlock => '用 Pro 解锁';

  @override
  String get apple_signin_warning_title => '使用 Apple 帐户登录？';

  @override
  String get apple_signin_warning_description =>
      'Apple 帐户无法在 Android 设备上登录，因此数据无法跨平台共享。如需多设备使用，建议使用 Google 帐户。';

  @override
  String get apple_signin_warning_continue => '继续使用 Apple';

  @override
  String get settings_page_manage_subscription => '管理订阅';

  @override
  String get search_page_ai_recommend_title => 'AI 推荐';

  @override
  String get search_page_ai_recommend_subtitle => '根据你的库提供关键词建议';

  @override
  String get search_page_ai_recommend_generate => '获取推荐';

  @override
  String get search_page_ai_recommend_refresh => '重新生成';

  @override
  String get search_page_ai_recommend_loading => 'AI 正在分析...';

  @override
  String get search_page_ai_recommend_error => '获取推荐失败';

  @override
  String get search_page_ai_recommend_empty => '已保存的内容不足，无法生成建议。请添加更多后再试。';

  @override
  String get search_page_ai_recommend_intro => '点击按钮，让 AI 根据已保存的库推荐相关搜索关键词。';
}
