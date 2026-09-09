// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class L10nKo extends L10n {
  L10nKo([String locale = 'ko']) : super(locale);

  @override
  String get app_title => 'ArchiVe';

  @override
  String get version => 'v2.0';

  @override
  String get critical => '크리티컬';

  @override
  String get normal => '노멀';

  @override
  String get maniac => '매니악';

  @override
  String get unrated => '평가 없음';

  @override
  String get ok => '확인';

  @override
  String get cancel => '취소';

  @override
  String get back => '뒤로';

  @override
  String get add => '추가';

  @override
  String get delete => '삭제';

  @override
  String get save => '저장';

  @override
  String get reload => '새로고침';

  @override
  String get all_item_list_name => '전체 항목';

  @override
  String get yes => '예';

  @override
  String get no => '아니요';

  @override
  String get clear => '지우기';

  @override
  String get favorite => '즐겨찾기';

  @override
  String get url => 'URL';

  @override
  String get title => '제목';

  @override
  String get no_select => '선택 없음';

  @override
  String get modify => '수정';

  @override
  String get close => '닫기';

  @override
  String get skip => '건너뛰기';

  @override
  String get save_limit_dialog_title => '저장 한도에 도달했습니다';

  @override
  String get save_limit_dialog_status_label => '저장됨';

  @override
  String get save_limit_dialog_premium_detail => '프리미엄 상세 보기';

  @override
  String get save_limit_loading_ad => '광고 로딩 중...';

  @override
  String get main_page_lists => '리스트';

  @override
  String get main_page_search => '검색';

  @override
  String get main_page_browser => '브라우저';

  @override
  String get browser_home_url_hint => 'URL 입력 또는 검색';

  @override
  String get browser_home_history => '방문 기록';

  @override
  String get browser_home_history_empty => '방문 기록이 없습니다';

  @override
  String get browser_home_history_clear => '지우기';

  @override
  String get browser_home_history_clear_confirm => '모든 방문 기록을 삭제하시겠습니까?';

  @override
  String get browser_home_favorites => '즐겨찾는 사이트';

  @override
  String get main_page_analytics => '통계';

  @override
  String get main_page_settings => '설정';

  @override
  String get main_page_update_info => '업데이트 안내';

  @override
  String get main_page_update_later => '나중에';

  @override
  String get main_page_update_now => '업데이트';

  @override
  String get list_page_home => '홈';

  @override
  String get list_page_my_list => '내 리스트';

  @override
  String get list_page_my_ranking => '내 랭킹';

  @override
  String get list_page_make_list => '리스트 만들기';

  @override
  String get list_page_add_list => '리스트 추가';

  @override
  String get list_page_input_list_name => '리스트 이름 입력';

  @override
  String get reset => '초기화';

  @override
  String get list_page_rating_rename_title => '평가 이름 변경';

  @override
  String get list_page_reorder => '정렬';

  @override
  String get list_page_reorder_done => '완료';

  @override
  String get list_page_reorder_hint => '드래그하여 순서를 변경할 수 있습니다';

  @override
  String get list_page_all_item_fixed => '「모든 항목」은 순서를 변경할 수 없습니다';

  @override
  String list_page_save_count(int count, int limit) {
    return '저장 $count / $limit';
  }

  @override
  String get list_page_item_unit => '개';

  @override
  String list_page_item_count(int count) {
    return '$count개';
  }

  @override
  String get ranking_page_dragable => '드래그하여 순서 변경';

  @override
  String get ranking_page_no_title => '(제목 없음)';

  @override
  String get ranking_page_search_title => '제목 검색';

  @override
  String get ranking_page_no_grid_item => '저장된 항목 없음';

  @override
  String get ranking_page_limit_error => '최대 10개까지 추가할 수 있습니다';

  @override
  String get ranking_page_no_ranking_item => '랭킹에 항목이 없습니다';

  @override
  String get ranking_page_no_ranking_item_description => '아래 리스트에서 항목을 추가하세요';

  @override
  String grid_page_item_count(Object length) {
    return '$length개 항목';
  }

  @override
  String get grid_page_no_item => '항목 없음';

  @override
  String get grid_page_add_item => '항목 추가 방법 선택';

  @override
  String get grid_page_by_web => '웹 검색으로 추가';

  @override
  String get grid_page_by_manual => '직접 추가';

  @override
  String get grid_page_cant_load_image => '이미지를 불러올 수 없습니다';

  @override
  String get grid_page_no_title => '(제목 없음)';

  @override
  String get grid_page_url_unable => '잘못된 URL';

  @override
  String get grid_page_sort_title => '제목순';

  @override
  String get grid_page_sort_new => '최신순';

  @override
  String get grid_page_sort_old => '오래된순';

  @override
  String get grid_page_sort_count_asc => '조회수 많은순';

  @override
  String get grid_page_sort_count_desc => '조회수 적은순';

  @override
  String get grid_page_sort_rating => '평가순';

  @override
  String get grid_page_sort_offline_first => '오프라인 우선';

  @override
  String get grid_page_sort_list_name => '리스트명순';

  @override
  String get grid_page_sort_random => '랜덤';

  @override
  String get grid_page_sort_by_cast => '출연자별';

  @override
  String get grid_page_sort_by_date => '추가일순';

  @override
  String grid_page_sort_current(String label) {
    return '정렬: $label';
  }

  @override
  String grid_page_items_selected_delete(Object count) {
    return '선택한 $count개 항목을 삭제하시겠습니까?';
  }

  @override
  String get grid_page_rating_guidance => '평가한 항목이 여기에 표시됩니다';

  @override
  String get detail_page_url_empty => 'URL이 비어 있습니다.';

  @override
  String get detail_page_input_url => 'URL을 입력하세요.';

  @override
  String get detail_page_url_changed => 'URL이 변경되었습니다.';

  @override
  String get detail_page_url_changed_note =>
      'URL을 변경하면 새 항목으로 저장됩니다.\n계속하시겠습니까?';

  @override
  String get detail_page_no_selected => '선택되지 않음';

  @override
  String get detail_page_item_detail => '항목 상세';

  @override
  String get detail_page_delete => '삭제';

  @override
  String get detail_page_access => '브라우저';

  @override
  String get detail_page_modify => '수정';

  @override
  String get detail_page_share => '공유';

  @override
  String get detail_page_copied => '복사됨';

  @override
  String detail_page_saved_to(String listName) {
    return '$listName에 저장';
  }

  @override
  String get detail_page_save => '저장';

  @override
  String get detail_page_thumbnail_placeholder => '저장 후 썸네일이 표시됩니다';

  @override
  String get detail_page_add_image => '썸네일 이미지 추가 ★';

  @override
  String get detail_page_offline => '오프라인';

  @override
  String get detail_page_offline_downloaded => '오프라인 저장 완료';

  @override
  String get detail_page_offline_confirm_title => '이 작품을 오프라인으로 저장하시겠습니까?';

  @override
  String get detail_page_offline_confirm_body =>
      '이 기기에 동영상을 다운로드합니다.\n※권리를 보유하거나 허가받은 동영상만 저장하세요.';

  @override
  String get detail_page_offline_no_url => 'URL이 입력되지 않았습니다';

  @override
  String get detail_page_offline_started => '다운로드를 시작했습니다';

  @override
  String get detail_page_offline_probing => '사용 가능한 해상도 확인 중…';

  @override
  String get detail_page_delete_offline_confirm =>
      '이 작품의 오프라인 데이터를 삭제하시겠습니까?\n(온라인 재생에는 영향 없음)';

  @override
  String get detail_page_offline_deleted => '오프라인 데이터를 삭제했습니다';

  @override
  String get consent_page_title => '시작하기 전에';

  @override
  String get consent_page_subtitle => '본 앱을 이용하기 전에 아래 내용을 확인하고 동의해 주세요.';

  @override
  String get consent_page_privacy_title => '개인정보 처리방침';

  @override
  String get consent_page_privacy_body =>
      '본 앱은 개인정보를 적절히 취급합니다. 아래 정책 전문을 확인해 주세요.';

  @override
  String get consent_page_terms_title => '이용 약관';

  @override
  String get consent_page_terms_body => '본 앱 이용에 관한 약관을 반드시 읽어주세요.';

  @override
  String get consent_page_ip_summary =>
      '본 앱은 사용자가 입력한 URL의 다운로드 및 오프라인 재생을 제공하는 범용 도구입니다. 저작권 및 배포처 이용 약관 준수는 사용자 책임입니다.';

  @override
  String get consent_page_agree_checkbox => '위 내용을 모두 이해했으며 동의합니다';

  @override
  String get consent_page_agree => '동의하고 시작';

  @override
  String get consent_page_read_more => '전문 보기';

  @override
  String get settings_page_ip_disclaimer => '지적 재산권 면책 조항';

  @override
  String get settings_page_ip_disclaimer_body =>
      '본 앱은 사용자가 스스로 입력한 동영상 URL의 다운로드 및 오프라인 재생 기능을 제공하는 범용 도구입니다. 특정 웹사이트의 콘텐츠를 취득하는 것을 목적으로 하지 않습니다.\n\n사용자는 다음에 대해 스스로 책임을 집니다:\n・저장한 동영상의 저작권 및 배포 사이트 이용 약관 준수\n・저장한 콘텐츠를 사적 이용 범위를 넘어 복제·배포·공개·상업적 이용하지 않음\n・제3자의 저작권, 초상권, 퍼블리시티권 등 권리 침해 금지\n・배포 사이트의 기술적 보호 조치를 회피하지 않음\n\n본 앱 제공자는 사용자의 앱 이용으로 인한 저작권 침해, 약관 위반 등에 대해 일체 법적 책임을 지지 않습니다.\n\n의문이 있는 경우 저작권자 또는 배포사에 확인 후 이용을 삼가시기 바랍니다. 본 앱은 사용자의 입력에 따라 작동하며 특정 서비스의 추천이나 제휴를 의미하지 않습니다.';

  @override
  String get detail_page_offline_not_direct_video =>
      '이 URL은 동영상 파일의 직접 링크가 아니므로 오프라인 저장할 수 없습니다.\n(YouTube 등의 페이지 URL은 지원되지 않습니다. mp4/m4v/mov/webm/mkv 형식의 직접 링크를 사용해 주세요.)';

  @override
  String get detail_page_offline_failed => '다운로드에 실패했습니다';

  @override
  String get download_failed_but_saved => 'URL은 북마크에 저장되었습니다 (동영상 파일은 미다운로드)';

  @override
  String get download_cancel_confirm_title => '다운로드를 중단하시겠습니까？';

  @override
  String get download_cancel_confirm_body =>
      '진행 중인 다운로드를 중단하고 이 항목을 삭제합니다. 계속하시겠습니까?';

  @override
  String get detail_page_offline_hls_not_supported =>
      '이 동영상은 HLS 형식(.m3u8)이므로 오프라인 저장을 지원하지 않습니다.';

  @override
  String get browser_video_detected_chip => '동영상 감지';

  @override
  String get browser_video_detected_sheet_title => '감지된 동영상';

  @override
  String get browser_video_detected_sheet_desc => '다운로드할 동영상을 선택하세요.';

  @override
  String get browser_video_download => '이 동영상 다운로드';

  @override
  String get browser_video_download_started => '다운로드를 시작했습니다';

  @override
  String get browser_video_download_saved_first => '먼저 작품으로 저장한 후 다운로드합니다';

  @override
  String get search_result_page_offline => '오프라인 저장';

  @override
  String get search_result_page_offline_desc =>
      '이 작품을 기기에 다운로드하여 통신 없이 재생할 수 있게 합니다.';

  @override
  String get download_queue_title => '다운로드';

  @override
  String get download_clear_finished => '완료 항목 지우기';

  @override
  String get download_empty => '진행 중인 다운로드가 없습니다';

  @override
  String get download_status_queued => '대기 중';

  @override
  String get download_status_completed => '완료';

  @override
  String get download_status_failed => '실패';

  @override
  String get download_cancel_all_confirm => '모든 다운로드를 취소하시겠습니까?';

  @override
  String get download_status_canceled => '취소';

  @override
  String get download_premium_required_title => 'Premium 전용 기능';

  @override
  String get download_premium_required_body =>
      '오프라인 다운로드는 Premium 이상 요금제에서 이용할 수 있습니다.';

  @override
  String get detail_page_rate => '평가';

  @override
  String get detail_page_title => '제목';

  @override
  String get detail_page_title_placeholder => '제목';

  @override
  String get detail_page_cast_short => '출연';

  @override
  String get detail_page_genre_short => '장르';

  @override
  String get detail_page_series_short => '시리즈';

  @override
  String get detail_page_maker_short => '제작사';

  @override
  String get detail_page_label_short => '레이블';

  @override
  String get detail_page_cast => '출연 (# 여러 개)';

  @override
  String get detail_page_cast_placeholder => '#출연1 #출연2 ...';

  @override
  String get detail_page_genre => '장르 (# 여러 개)';

  @override
  String get detail_page_genre_placeholder => '#장르1 #장르2 ...';

  @override
  String get detail_page_series => '시리즈 (# 여러 개)';

  @override
  String get detail_page_series_placeholder => '#시리즈1 #시리즈2 ...';

  @override
  String get detail_page_label => '레이블 (# 여러 개)';

  @override
  String get detail_page_label_placeholder => '#레이블1 #레이블2 ...';

  @override
  String get detail_page_maker => '제작사 (# 여러 개)';

  @override
  String get detail_page_maker_placeholder => '#제작사1 #제작사2 ...';

  @override
  String get detail_page_paste_url => 'URL 붙여넣기';

  @override
  String get detail_page_fetch_title => 'URL에서 제목 가져오기';

  @override
  String get detail_page_list => '리스트';

  @override
  String get detail_page_memo => '메모';

  @override
  String get detail_page_fetch_title_fail => '제목을 찾을 수 없습니다.';

  @override
  String get detail_page_fetch_page_fail => '페이지를 불러오지 못했습니다.';

  @override
  String get detail_page_ex => '오류가 발생했습니다.';

  @override
  String get detail_page_delete_confirm01 => '이 항목을 삭제하시겠습니까?';

  @override
  String get detail_page_delete_confirm02 => '이 작업은 되돌릴 수 없습니다.';

  @override
  String get detail_page_url_unable => '잘못된 URL';

  @override
  String get detail_page_review_confirm01 => 'ArchiVe가 마음에 드시나요?';

  @override
  String get detail_page_review_confirm02 => '리뷰로 응원해 주시면 큰 힘이 됩니다.';

  @override
  String get detail_page_review_contact_support => '의견/버그 신고';

  @override
  String get detail_page_review_later => '나중에';

  @override
  String get detail_page_review_now => '리뷰 작성';

  @override
  String get detail_page_mail_subject => 'subject=ArchiVe Feedback';

  @override
  String get detail_page_fetching_thumbnail => '썸네일을 가져오는 중...';

  @override
  String get search_page_cast => '출연';

  @override
  String get search_page_genre => '장르';

  @override
  String get search_page_series => '시리즈';

  @override
  String get search_page_label => '레이블';

  @override
  String get search_page_maker => '제작사';

  @override
  String get search_page_search => '검색';

  @override
  String get search_page_select_category => '카테고리 선택';

  @override
  String get search_page_more => '더보기';

  @override
  String get search_page_fold => '접기';

  @override
  String get search_page_search_title => '제목으로 검색';

  @override
  String get search_page_premium_title => '태그 여러 개 선택 ★';

  @override
  String get search_page_premium_description =>
      '여러 카테고리로 검색 기능은\n프리미엄 사용자만 이용할 수 있습니다.';

  @override
  String get search_page_segment_button_app => '앱 내';

  @override
  String get search_page_segment_button_web => '웹';

  @override
  String get search_page_text_empty => '검색어를 입력하세요';

  @override
  String get search_page_web_title => '웹 검색';

  @override
  String get search_page_search_word => '웹 검색';

  @override
  String get search_page_hint_web_1 => '광고 차단 기능으로 쾌적 검색';

  @override
  String get search_page_hint_web_2 => '예: 애니메이션 OP';

  @override
  String get search_page_hint_web_3 => '앱 내 브라우저로 빠른 동영상 수집';

  @override
  String get search_page_hint_web_4 => '예: 라이브 2026';

  @override
  String get search_page_hint_web_5 => '즐겨찾는 사이트 깊게 탐색';

  @override
  String get search_page_hint_web_6 => '예: 간단 레시피';

  @override
  String get search_page_select_site => '즐겨찾는 사이트';

  @override
  String get search_page_select_site_help_title => '사이트 필터';

  @override
  String get search_page_select_site_help_description =>
      '특정 사이트로 동영상 검색을 좁힐 수 있습니다. 즐겨찾는 동영상 사이트를 등록하면 해당 사이트 내에서만 검색이 가능합니다. 아래 목록에서 사이트를 선택하고 검색 버튼을 누르세요.';

  @override
  String get search_page_open_site => '사이트 열기';

  @override
  String get search_page_modify_favorite => '즐겨찾기 수정';

  @override
  String get search_page_site_name => '사이트 이름';

  @override
  String get search_page_input_all => '모든 항목을 입력하세요';

  @override
  String get search_page_add_favorite => '즐겨찾기 사이트 추가';

  @override
  String get search_page_random_loading => '오늘의 추천을 선택하는 중…';

  @override
  String get search_page_random_this => '오늘의 추천!';

  @override
  String get search_page_random_again => '다시 돌리기';

  @override
  String get search_result_page_site_saved => '사이트가 저장되었습니다';

  @override
  String get search_result_page_saving_as_item => '항목 저장';

  @override
  String get search_result_page_saving_list => '저장할 리스트';

  @override
  String get search_result_page_url_already_saved => '이미 저장된 URL입니다';

  @override
  String get search_result_page_url_already_saved_offline_prompt =>
      '이 작품을 오프라인용으로 다운로드하시겠습니까?';

  @override
  String get search_result_page_url_already_saved_and_downloaded =>
      '이 작품은 이미 저장 & 다운로드되었습니다';

  @override
  String get download_retry => '다시 시도';

  @override
  String get player_minimize => '미니 플레이어로 전환';

  @override
  String get player_close => '닫기';

  @override
  String get player_speed => '재생 속도';

  @override
  String player_speed_x(String v) {
    return '${v}x';
  }

  @override
  String get player_speed_custom => '사용자 지정';

  @override
  String get player_bookmarks => '북마크';

  @override
  String get player_bookmarks_empty => '아직 북마크가 없습니다';

  @override
  String get browser_video_size => '크기';

  @override
  String get browser_video_size_unknown => '크기 알 수 없음';

  @override
  String get browser_video_quality => '화질';

  @override
  String get browser_tab_max_reached => '탭 상한에 도달했습니다. 기존 탭을 닫고 새 탭을 여세요.';

  @override
  String get browser_tabs_title => '탭';

  @override
  String get browser_new_tab => '새 탭';

  @override
  String get offline_quality_title => '오프라인 화질';

  @override
  String get offline_quality_desc => '다운로드할 동영상의 화질을 선택하세요';

  @override
  String get offline_quality_none => '오프라인 다운로드 안 함';

  @override
  String get search_result_page_has_saved => '항목이 저장되었습니다';

  @override
  String search_result_page_delete_site(Object siteName) {
    return '\"$siteName\"을(를) 즐겨찾기에서 삭제하시겠습니까?';
  }

  @override
  String get search_result_page_new_list => '새 리스트';

  @override
  String get search_result_page_input_list_name => '리스트 이름 입력';

  @override
  String get search_result_page_list_already_exists => '같은 이름의 리스트가 이미 존재합니다';

  @override
  String get search_result_page_history => '기록';

  @override
  String get search_result_page_ad_remainder01 => '다음 저장 후 광고가 표시됩니다';

  @override
  String get search_result_page_ad_remainder02 => '광고 표시';

  @override
  String get analytics => '통계';

  @override
  String get analytics_page_summary => '개요';

  @override
  String analytics_page_item_count(Object totalWorks) {
    return '저장된 항목: $totalWorks';
  }

  @override
  String get analytics_page_recent_additions => '최근 추가된 항목';

  @override
  String analytics_page_piechart_others(Object percent) {
    return '기타\n$percent%';
  }

  @override
  String get analytics_page_view_count_top5 => '조회수 TOP 5';

  @override
  String get analytics_page_no_view_records_title => '아직 조회 기록이 없습니다';

  @override
  String get analytics_page_no_view_records_hint => '작품 상세에서 조회수를 기록하면 표시됩니다';

  @override
  String get analytics_page_no_data => '데이터가 없습니다';

  @override
  String get analytics_page_evaluation => '평가';

  @override
  String get analytics_page_cast => '출연';

  @override
  String get analytics_page_genre => '장르';

  @override
  String get analytics_page_series => '시리즈';

  @override
  String get analytics_page_label => '레이블';

  @override
  String get analytics_page_maker => '제작사';

  @override
  String get analytics_page_premium_title => '통계 ★';

  @override
  String get analytics_page_premium_description =>
      '통계 기능은 ArchiVe Premium에서\n이용할 수 있습니다.\n업그레이드 후 사용해 주세요.';

  @override
  String get analytics_page_premium_button => '프리미엄 상세 보기';

  @override
  String analytics_page_list_value(Object entry, Object percent) {
    return '$percent% ($entry개)';
  }

  @override
  String get analytics_page_count => '(조회)';

  @override
  String analytics_page_toolchip_count(Object rod) {
    return '$rod회 조회';
  }

  @override
  String get analytics_page_no_title => '제목 없음';

  @override
  String get analytics_page_item_count_top5 => '항목 수 TOP 5';

  @override
  String get analytics_page_kpi_saved_count => '저장 수';

  @override
  String get analytics_page_kpi_total_view_count => '총 시청 횟수';

  @override
  String get analytics_page_kpi_rating_rate => '평가율';

  @override
  String get analytics_page_most_watched => '최다 시청';

  @override
  String analytics_page_view_times(Object count) {
    return '$count회 시청';
  }

  @override
  String analytics_page_total_view_subtitle(Object count) {
    return '총 시청 횟수: $count회';
  }

  @override
  String analytics_page_rated_subtitle(Object ratedCount, Object total) {
    return '평가됨 $ratedCount / $total개';
  }

  @override
  String get analytics_page_unit_items => '개';

  @override
  String analytics_page_ranked_row_stat(Object count, Object percent) {
    return '$percent%  $count개';
  }

  @override
  String analytics_page_times_unit(Object count) {
    return '$count회';
  }

  @override
  String get analytics_page_view_count_by_rating => '평가별 시청 횟수';

  @override
  String get analytics_page_saved_by_list => '리스트별 저장 수';

  @override
  String analytics_page_list_count_subtitle(Object count) {
    return '$count개 리스트';
  }

  @override
  String analytics_page_type_count_subtitle(Object count) {
    return '$count종류';
  }

  @override
  String get settings => '설정';

  @override
  String get settings_page_dark_mode => '다크 모드';

  @override
  String get settings_page_theme_color => '테마 색상';

  @override
  String get settings_page_theme_color_orange => '오렌지';

  @override
  String get settings_page_theme_color_random => '랜덤';

  @override
  String get settings_page_theme_color_green => '그린';

  @override
  String get settings_page_theme_color_blue => '블루';

  @override
  String get settings_page_theme_color_white => '화이트';

  @override
  String get settings_page_theme_color_red => '레드';

  @override
  String get settings_page_theme_color_yellow => '옐로우';

  @override
  String get settings_page_thumbnail_visibility => '리스트 썸네일 표시';

  @override
  String get settings_page_save_status => '아이템 수';

  @override
  String get settings_page_offline_videos => '오프라인 동영상';

  @override
  String get settings_page_offline_total_size => '오프라인 총 용량';

  @override
  String get settings_page_save_count => '북마크';

  @override
  String get settings_page_watch_count => '오늘 조회수';

  @override
  String settings_page_watch_ad_today(Object watchedAdsToday) {
    return '$watchedAdsToday / 5';
  }

  @override
  String get settings_page_watch_ad => '광고 보기 (+1 슬롯)';

  @override
  String get settings_page_ad_limit_reached => '오늘 광고 한도에 도달했습니다';

  @override
  String get settings_page_already_purchased => '이미 구매되었습니다.';

  @override
  String get settings_page_premium => 'ArchiVe Premium';

  @override
  String get settings_page_app_version => '앱 버전';

  @override
  String get settings_page_plivacy_policy => '개인정보 처리방침';

  @override
  String get settings_page_disable_link => '링크를 열 수 없습니다';

  @override
  String get settings_page_terms => '이용 약관 (Apple 표준 EULA)';

  @override
  String get settings_page_save_count_increased => '저장 한도가 +1 증가했습니다';

  @override
  String get setting_page_unlimited => '무제한';

  @override
  String view_counter_view_count(Object viewCount) {
    return '조회 $viewCount';
  }

  @override
  String get random_image_no_image => '이미지를 불러올 수 없습니다';

  @override
  String get random_image_change_list_name => '리스트 이름 변경';

  @override
  String get random_image_change_list_name_dialog => '리스트 이름 변경';

  @override
  String get random_image_change_list_name_hint => '리스트 이름 입력';

  @override
  String get random_image_change_list_name_confirm => '변경';

  @override
  String get random_image_delete_list => '리스트 삭제';

  @override
  String get random_image_delete_list_dialog => '이 리스트를 삭제하시겠습니까?';

  @override
  String get random_image_delete_list_dialog_description =>
      '이 리스트의 항목도 함께 삭제됩니다.';

  @override
  String get random_image_delete_list_confirm => '삭제';

  @override
  String get premium_detail_premium_title => 'ArchiVe Premium';

  @override
  String get premium_detail_premium_item01 => '무제한 저장';

  @override
  String get premium_detail_premium_item02 => '테마 색상 골드 추가';

  @override
  String get premium_detail_premium_item03 => '이미지 자유 추가';

  @override
  String get premium_detail_premium_item04 => '여러 태그로 빠른 검색';

  @override
  String get premium_detail_premium_item05 => '장르 및 평점별 데이터 시각화 통계';

  @override
  String get premium_detail_premium_item06 => '광고 제거';

  @override
  String get premium_detail_note => '3일 무료 체험 후 자동으로 결제됩니다.\n언제든 취소할 수 있습니다.';

  @override
  String get premium_detail_restore_not_found => '구매 내역을 찾을 수 없습니다';

  @override
  String get premium_detail_free_trial_badge => '3일 무료';

  @override
  String get premium_detail_start_trial => '3일 무료로 시작';

  @override
  String premium_detail_price_after_trial(Object price) {
    return '이후 $price / 월';
  }

  @override
  String get premium_detail_restore_button => '구매 복원';

  @override
  String get premium_detail_purchase_complete => '프리미엄 구매가 완료되었습니다!';

  @override
  String get premium_detail_restart_message => '프리미엄 기능이 활성화되었습니다.\n앱이 재시작됩니다.';

  @override
  String get tutorial => '튜토리얼';

  @override
  String get tutorial_01 => '먼저 리스트를 만들어 보세요.';

  @override
  String get tutorial_02 => '방금 만든 리스트를 열어보세요.';

  @override
  String get tutorial_03 => '+ 버튼을 눌러 항목을 추가하세요.';

  @override
  String get tutorial_04 => '영상 또는 콘텐츠의 URL을 입력하세요.';

  @override
  String get tutorial_05 => '이 버튼을 눌러 제목을 자동으로 가져오세요.';

  @override
  String get tutorial_06 => '마지막으로 저장하여 리스트에 추가하세요.';

  @override
  String get start_tutorial_dialog => '튜토리얼을 다시 시작하시겠습니까?';

  @override
  String get start_tutorial_dialog_description => '리스트 생성 단계부터 다시 안내합니다.';

  @override
  String get completed_tutorial => '튜토리얼 완료!\n수고하셨습니다!';

  @override
  String get tutorial_list_name => '나중에 보기';

  @override
  String get tutorial_slide_title_01 => '다운로드 없이\n영상 관리';

  @override
  String get tutorial_slide_dict_01 => '저장 공간을 사용하지 않고\n무제한으로 영상 수집';

  @override
  String get tutorial_slide_image_01 => 'assets/tutorial/english01.png';

  @override
  String get tutorial_slide_title_02 => '[2단계로 간편하게]\n1. URL 복사';

  @override
  String get tutorial_slide_dict_02 => '영상 사이트에서 공유 링크 또는\n브라우저 URL을 복사하세요';

  @override
  String get tutorial_slide_image_02 => 'assets/tutorial/english02.png';

  @override
  String get tutorial_slide_title_03 => '[2단계로 간편하게]\n2. URL 저장';

  @override
  String get tutorial_slide_dict_03 => '붙여넣기만 하면 저장 완료\n평가, 태그, 메모도 추가 가능';

  @override
  String get tutorial_slide_image_03 => 'assets/tutorial/english03.png';

  @override
  String get tutorial_slide_title_04 => '앱 내 검색';

  @override
  String get tutorial_slide_dict_04 => '제목이나 태그로\n저장한 영상을 즉시 찾기';

  @override
  String get tutorial_slide_image_04 => 'assets/tutorial/english04.png';

  @override
  String get tutorial_slide_title_05 => '웹 검색';

  @override
  String get tutorial_slide_dict_05 => '앱 내 브라우저로\n바로 탐색하고 저장';

  @override
  String get tutorial_slide_image_05 => 'assets/tutorial/english05.png';

  @override
  String get tutorial_slide_title_06 => '무한한 가능성';

  @override
  String get tutorial_slide_dict_06 => '나만의 영상 컬렉션을 만들어 보세요!';

  @override
  String get tutorial_slide_image_06 => 'assets/tutorial/english06.png';

  @override
  String get tutorial_slide_next => '다음';

  @override
  String get tutorial_slide_start => '시작하기';

  @override
  String get share_saved => '공유에서 저장했습니다';

  @override
  String get share_already_saved => '이 URL은 이미 저장되어 있습니다';

  @override
  String get share_dialog_title => 'ArchiVe에 저장';

  @override
  String get share_list_section => '저장할 목록';

  @override
  String get share_title_hint => '제목을 입력';

  @override
  String get clipboard_dialog_title => '클립보드의 URL을 추가하시겠습니까?';

  @override
  String get ranking_page_add_item => '아이템 추가';

  @override
  String get search_page_url_cant_open => '이 URL을 열 수 없습니다';

  @override
  String get premium_detail_plan_monthly => '월간';

  @override
  String get premium_detail_plan_annual => '연간';

  @override
  String get premium_detail_best_value => '추천';

  @override
  String premium_detail_save_percent(String percent) {
    return '$percent% 할인';
  }

  @override
  String get premium_detail_per_month => '/ 월';

  @override
  String get premium_detail_per_year => '/ 년';

  @override
  String premium_detail_price_after_trial_yearly(String price) {
    return '이후 $price / 년';
  }

  @override
  String get settings_page_free_plan => '무료 플랜';

  @override
  String get settings_page_current_plan => '현재 플랜';

  @override
  String get settings_page_premium_details_link => '저장 한도 해제 및 자세히 보기';

  @override
  String get settings_page_section_appearance => '외관';

  @override
  String get settings_page_section_about => '앱 정보';

  @override
  String get settings_page_section_legal => '법적 정보';

  @override
  String get settings_page_period_monthly => '월간';

  @override
  String get settings_page_period_annual => '연간';

  @override
  String get settings_page_theme_color_pink => '핑크';

  @override
  String get settings_page_theme_color_purple => '보라';

  @override
  String get settings_page_theme_color_teal => '청록';

  @override
  String get login_page_title => '로그인';

  @override
  String get login_page_description => 'ArchiVe Pro 기능을 사용하려면 로그인하세요.';

  @override
  String get login_with_apple => 'Apple로 로그인';

  @override
  String get login_with_google => 'Google로 로그인';

  @override
  String get login_failed => '로그인에 실패했습니다';

  @override
  String get logout => '로그아웃';

  @override
  String get logout_confirm => '로그아웃하시겠습니까?';

  @override
  String get settings_page_section_account => '계정';

  @override
  String get settings_page_not_signed_in => '로그인되어 있지 않음';

  @override
  String get pro_detail_title => 'ArchiVe Pro';

  @override
  String get pro_detail_subtitle => '모든 프리미엄 기능 외에 다음 기능 제공';

  @override
  String get pro_detail_feature_cloud_sync => '클라우드 동기화 (여러 기기)';

  @override
  String get pro_detail_feature_ai_tagging => 'AI 자동 태그';

  @override
  String get pro_detail_feature_ai_recommend => 'AI 추천 키워드';

  @override
  String get pro_detail_feature_monthly_report => 'AI 월간 보고서';

  @override
  String get pro_detail_feature_public_sharing => '공개 목록 공유';

  @override
  String get pro_detail_feature_theme_teal => '테마 색상 청록 추가';

  @override
  String get plans_page_title => '플랜';

  @override
  String get plans_page_current_badge => '현재';

  @override
  String get plans_page_includes_premium => '모든 Premium 기능 포함';

  @override
  String get detail_page_ai_suggest => 'AI로 태그 제안';

  @override
  String get detail_page_ai_suggest_dialog_title => 'AI 태그 제안';

  @override
  String get detail_page_ai_suggest_dialog_hint => '추천 태그입니다! 적용할 태그를 선택해 주세요.';

  @override
  String get detail_page_ai_apply => '적용';

  @override
  String get detail_page_ai_no_suggestions => '제안된 태그가 없습니다';

  @override
  String get detail_page_ai_from_library => '기존 태그에서';

  @override
  String get detail_page_ai_daily_limit_title => '오늘의 AI 사용 한도에 도달했습니다';

  @override
  String get detail_page_ai_daily_limit_body =>
      'AI 태그 제안은 무료판 / Premium 요금제에서 하루 1회 이용할 수 있습니다.\nPro 요금제라면 무제한으로 사용할 수 있습니다.';

  @override
  String get detail_page_ai_upgrade_pro => 'Pro 요금제 보기';

  @override
  String get detail_page_ai_loading => 'AI 분석 중...';

  @override
  String get detail_page_ai_error => 'AI 제안 오류';

  @override
  String get share_title => '목록 공유';

  @override
  String get share_loading => '공유 중...';

  @override
  String get share_url_label => '공유 URL';

  @override
  String get share_copy => '복사';

  @override
  String get share_copied => '복사됨';

  @override
  String get share_unshare => '공유 해제';

  @override
  String get share_unshare_confirm => '이 목록의 공유를 해제하시겠습니까?';

  @override
  String get share_create_action => '이 목록 공유';

  @override
  String get share_error => '공유 오류';

  @override
  String get share_open_url => '공유 URL 열기';

  @override
  String get share_description => 'URL이 있는 사람은 누구나 이 목록을 볼 수 있습니다 (읽기 전용)';

  @override
  String get share_limit_notice => '최대 200개 항목이 공유됩니다';

  @override
  String get analytics_monthly_report_title => 'AI 요약';

  @override
  String analytics_monthly_report_subtitle(int month) {
    return '$month월 요약';
  }

  @override
  String get analytics_monthly_report_generate => '요약 생성';

  @override
  String get analytics_monthly_report_regenerate => '다시 생성';

  @override
  String get analytics_monthly_report_loading => 'AI가 분석 중입니다...';

  @override
  String get analytics_monthly_report_empty =>
      '버튼을 누르면 AI가 이번 달 아카이브 활동을 요약합니다.';

  @override
  String get analytics_monthly_report_error => '보고서 오류';

  @override
  String get analytics_monthly_report_cached => '캐시에서';

  @override
  String get search_result_loading => '로딩 중';

  @override
  String get grid_page_move_action => '이동';

  @override
  String get grid_page_move_to_list_title => '이동할 목록 선택';

  @override
  String get grid_page_move_done => '개 항목 이동됨';

  @override
  String get undo => '실행 취소';

  @override
  String get settings_page_theme_color_gold => '골드';

  @override
  String get plans_page_premium_short => '프리미엄';

  @override
  String get plans_page_pro_short => 'Pro';

  @override
  String get plans_page_free_short => '무료';

  @override
  String get plans_page_free_price => '₩0';

  @override
  String get plans_page_free_item01 => '100개까지 저장 가능';

  @override
  String get plans_page_free_item02 => '광고 시청으로 15개/일 확장';

  @override
  String get plans_page_free_item03 => '단일 태그 검색';

  @override
  String get plans_page_free_item04 => '광고 표시';

  @override
  String get share_pro_required_title => 'Pro 요금제 전용 기능';

  @override
  String get share_pro_required_description => '공개 목록 공유는 Pro 요금제 구매가 필요합니다.';

  @override
  String get share_pro_required_action => 'Pro 요금제 보기';

  @override
  String get pro_locked_badge => 'Pro 전용';

  @override
  String get pro_locked_unlock => 'Pro로 잠금 해제';

  @override
  String get apple_signin_warning_title => 'Apple 계정으로 로그인하시겠습니까?';

  @override
  String get apple_signin_warning_description =>
      'Apple 계정은 Android 기기에서 로그인할 수 없어 데이터가 플랫폼 간 공유되지 않습니다. 여러 기기를 사용한다면 Google 계정을 권장합니다.';

  @override
  String get apple_signin_warning_continue => 'Apple로 계속';

  @override
  String get settings_page_manage_subscription => '구독 관리';

  @override
  String get search_page_ai_recommend_title => 'AI 추천';

  @override
  String get search_page_ai_recommend_subtitle => '라이브러리 기반 키워드 제안';

  @override
  String get search_page_ai_recommend_generate => '추천 받기';

  @override
  String get search_page_ai_recommend_refresh => '다시 생성';

  @override
  String get search_page_ai_recommend_loading => 'AI가 분석 중...';

  @override
  String get search_page_ai_recommend_error => '추천 가져오기 실패';

  @override
  String get search_page_ai_recommend_empty =>
      '저장된 항목이 부족합니다. 항목을 더 추가한 후 다시 시도해 주세요.';

  @override
  String get search_page_ai_recommend_intro =>
      '버튼을 누르면 저장한 라이브러리에서 관련 키워드를 AI가 제안합니다.';
}
