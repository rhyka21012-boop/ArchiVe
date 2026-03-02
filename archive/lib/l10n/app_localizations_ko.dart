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
  String get version => 'v1.8';

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
  String get main_page_search => '검색 & 수집';

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
  String get detail_page_save => '저장';

  @override
  String get detail_page_thumbnail_placeholder => '저장 후 썸네일이 표시됩니다';

  @override
  String get detail_page_add_image => '이미지 추가 ★';

  @override
  String get detail_page_rate => '평가';

  @override
  String get detail_page_title => '제목';

  @override
  String get detail_page_title_placeholder => '제목';

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
  String get detail_page_review_confirm01 =>
      '\"ArchiVe - Favorite Video Tracker\"를 잘 사용하고 계신가요?';

  @override
  String get detail_page_review_confirm02 =>
      '항상 이용해 주셔서 감사합니다.\n\n보내주신 의견은 개발자가 확인하여 개선에 반영하겠습니다.\n\n앱이 마음에 드셨다면 리뷰로 응원해 주세요.';

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
  String get search_page_search_word => '검색어';

  @override
  String get search_page_select_site => '사이트 필터';

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
  String get search_result_page_site_saved => '사이트가 저장되었습니다';

  @override
  String get search_result_page_saving_as_item => '항목 저장';

  @override
  String get search_result_page_saving_list => '저장할 리스트';

  @override
  String get search_result_page_url_already_saved => '이미 저장된 URL입니다';

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
  String get settings => '설정';

  @override
  String get settings_page_dark_mode => '다크 모드';

  @override
  String get settings_page_theme_color => '테마 색상 ★';

  @override
  String get settings_page_theme_color_orange => '오렌지';

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
  String get settings_page_save_status => '저장 상태';

  @override
  String get settings_page_save_count => '저장된 항목 수';

  @override
  String get settings_page_watch_count => '오늘 조회수';

  @override
  String settings_page_watch_ad_today(Object watchedAdsToday) {
    return '$watchedAdsToday / 3';
  }

  @override
  String get settings_page_watch_ad => '광고 보기 (+5 슬롯)';

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
  String get settings_page_save_count_increased => '저장 한도가 +5 증가했습니다';

  @override
  String get setting_page_unlimited => '무제한';

  @override
  String view_counter_view_count(Object viewCount) {
    return '조회수: $viewCount';
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
  String get premium_detail_purchase_complete => '프리미엄 구매가 완료되었습니다!';

  @override
  String get premium_detail_purchase_incomplete =>
      '구매는 완료되었지만 프리미엄이 활성화되지 않았습니다';

  @override
  String get premium_detail_no_item => '구매 가능한 상품이 없습니다';

  @override
  String premium_detail_ex(Object ex) {
    return '구매 오류: $ex';
  }

  @override
  String get premium_detail_premium_title => 'ArchiVe Premium';

  @override
  String get premium_detail_premium_item01 => '저장 슬롯 무제한';

  @override
  String get premium_detail_premium_item02 => '테마 색상 자유 변경';

  @override
  String get premium_detail_premium_item03 => '이미지 자유 추가';

  @override
  String get premium_detail_premium_item04 => '여러 태그로 빠른 검색';

  @override
  String get premium_detail_premium_item05 => '장르 및 평가 통계 시각화';

  @override
  String get premium_detail_premium_item06 => '광고 제거';

  @override
  String get premium_detail_price => '월 ₩1,100.00부터 시작';

  @override
  String get premium_detail_note => '언제든지 해지 가능';

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
}
