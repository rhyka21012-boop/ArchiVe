// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class L10nDe extends L10n {
  L10nDe([String locale = 'de']) : super(locale);

  @override
  String get app_title => 'ArchiVe';

  @override
  String get version => 'v1.8';

  @override
  String get critical => 'Kritisch';

  @override
  String get normal => 'Normal';

  @override
  String get maniac => 'Maniac';

  @override
  String get unrated => 'Unbewertet';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get back => 'Zurück';

  @override
  String get add => 'Hinzufügen';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get reload => 'Neu laden';

  @override
  String get all_item_list_name => 'Alle Einträge';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get clear => 'Löschen';

  @override
  String get favorite => 'Favorit';

  @override
  String get url => 'URL';

  @override
  String get title => 'Titel';

  @override
  String get no_select => 'Keine';

  @override
  String get modify => 'Bearbeiten';

  @override
  String get close => 'Schließen';

  @override
  String get save_limit_dialog_title => 'Speicherlimit erreicht';

  @override
  String get save_limit_dialog_status_label => 'Gespeichert';

  @override
  String get save_limit_dialog_premium_detail => 'Premium-Details anzeigen';

  @override
  String get save_limit_loading_ad => 'Werbung wird geladen...';

  @override
  String get main_page_lists => 'Listen';

  @override
  String get main_page_search => 'Suchen & Sammeln';

  @override
  String get main_page_analytics => 'Analyse';

  @override
  String get main_page_settings => 'Einstellungen';

  @override
  String get main_page_update_info => 'Update-Hinweis';

  @override
  String get main_page_update_later => 'Später';

  @override
  String get main_page_update_now => 'Aktualisieren';

  @override
  String get list_page_my_list => 'Meine Listen';

  @override
  String get list_page_my_ranking => 'Meine Rankings';

  @override
  String get list_page_make_list => 'Liste erstellen';

  @override
  String get list_page_add_list => 'Liste hinzufügen';

  @override
  String get list_page_input_list_name => 'Listennamen eingeben';

  @override
  String get ranking_page_dragable => 'Ziehen zum Sortieren';

  @override
  String get ranking_page_no_title => '(Kein Titel)';

  @override
  String get ranking_page_search_title => 'Titel suchen';

  @override
  String get ranking_page_no_grid_item => 'Keine gespeicherten Einträge';

  @override
  String get ranking_page_limit_error =>
      'Es können nur bis zu 10 Einträge hinzugefügt werden';

  @override
  String get ranking_page_no_ranking_item => 'Keine Einträge im Ranking';

  @override
  String get ranking_page_no_ranking_item_description =>
      'Bitte Einträge aus der Liste unten hinzufügen';

  @override
  String grid_page_item_count(Object length) {
    return '$length Einträge';
  }

  @override
  String get grid_page_no_item => 'Keine Einträge';

  @override
  String get grid_page_add_item => 'Wie möchten Sie einen Eintrag hinzufügen?';

  @override
  String get grid_page_by_web => 'Über Websuche hinzufügen';

  @override
  String get grid_page_by_manual => 'Manuell hinzufügen';

  @override
  String get grid_page_cant_load_image => 'Bild konnte nicht geladen werden';

  @override
  String get grid_page_no_title => '(Kein Titel)';

  @override
  String get grid_page_url_unable => 'Ungültige URL';

  @override
  String get grid_page_sort_title => 'Titel';

  @override
  String get grid_page_sort_new => 'Neueste zuerst';

  @override
  String get grid_page_sort_old => 'Älteste zuerst';

  @override
  String get grid_page_sort_count_asc => 'Meist angesehen';

  @override
  String get grid_page_sort_count_desc => 'Wenigste Aufrufe';

  @override
  String grid_page_items_selected_delete(Object count) {
    return '$count ausgewählte Einträge löschen?';
  }

  @override
  String get grid_page_rating_guidance =>
      'Bewertete Einträge werden hier angezeigt';

  @override
  String get detail_page_url_empty => 'URL ist leer.';

  @override
  String get detail_page_input_url => 'Bitte eine URL eingeben.';

  @override
  String get detail_page_url_changed => 'URL wurde geändert.';

  @override
  String get detail_page_url_changed_note =>
      'Beim Ändern der URL wird ein neuer Eintrag erstellt.\nMöchten Sie fortfahren?';

  @override
  String get detail_page_no_selected => 'Nicht ausgewählt';

  @override
  String get detail_page_item_detail => 'Eintragsdetails';

  @override
  String get detail_page_delete => 'Löschen';

  @override
  String get detail_page_access => 'Browser';

  @override
  String get detail_page_modify => 'Bearbeiten';

  @override
  String get detail_page_save => 'Speichern';

  @override
  String get detail_page_thumbnail_placeholder =>
      'Vorschaubild erscheint nach dem Speichern';

  @override
  String get detail_page_add_image => 'Bild hinzufügen ★';

  @override
  String get detail_page_rate => 'Bewertung';

  @override
  String get detail_page_title => 'Titel';

  @override
  String get detail_page_title_placeholder => 'Titel';

  @override
  String get detail_page_cast => 'Darsteller (# mehrere)';

  @override
  String get detail_page_cast_placeholder => '#Darsteller1 #Darsteller2 ...';

  @override
  String get detail_page_genre => 'Genre (# mehrere)';

  @override
  String get detail_page_genre_placeholder => '#Genre1 #Genre2 ...';

  @override
  String get detail_page_series => 'Serie (# mehrere)';

  @override
  String get detail_page_series_placeholder => '#Serie1 #Serie2 ...';

  @override
  String get detail_page_label => 'Label (# mehrere)';

  @override
  String get detail_page_label_placeholder => '#Label1 #Label2 ...';

  @override
  String get detail_page_maker => 'Produzent (# mehrere)';

  @override
  String get detail_page_maker_placeholder => '#Produzent1 #Produzent2 ...';

  @override
  String get detail_page_paste_url => 'URL einfügen';

  @override
  String get detail_page_fetch_title => 'Titel von URL abrufen';

  @override
  String get detail_page_list => 'Liste';

  @override
  String get detail_page_memo => 'Notiz';

  @override
  String get detail_page_fetch_title_fail => 'Titel nicht gefunden.';

  @override
  String get detail_page_fetch_page_fail =>
      'Seite konnte nicht geladen werden.';

  @override
  String get detail_page_ex => 'Ein Fehler ist aufgetreten.';

  @override
  String get detail_page_delete_confirm01 => 'Diesen Eintrag löschen?';

  @override
  String get detail_page_delete_confirm02 =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get detail_page_url_unable => 'Ungültige URL';

  @override
  String get detail_page_review_confirm01 =>
      'Gefällt Ihnen \"ArchiVe - Favorite Video Tracker\"?';

  @override
  String get detail_page_review_confirm02 =>
      'Vielen Dank für die Nutzung unserer App.\n\nIhr Feedback wird vom Entwickler sorgfältig geprüft und zur Verbesserung verwendet.\n\nWenn Ihnen die App gefällt, würden wir uns sehr über eine Bewertung freuen.';

  @override
  String get detail_page_review_contact_support =>
      'Feedback oder Fehler melden';

  @override
  String get detail_page_review_later => 'Später';

  @override
  String get detail_page_review_now => 'Bewertung abgeben';

  @override
  String get detail_page_mail_subject => 'subject=ArchiVe Feedback';

  @override
  String get search_page_cast => 'Darsteller';

  @override
  String get search_page_genre => 'Genre';

  @override
  String get search_page_series => 'Serie';

  @override
  String get search_page_label => 'Label';

  @override
  String get search_page_maker => 'Produzent';

  @override
  String get search_page_search => 'Suchen';

  @override
  String get search_page_select_category => 'Kategorie auswählen';

  @override
  String get search_page_more => 'Mehr anzeigen';

  @override
  String get search_page_fold => 'Weniger anzeigen';

  @override
  String get search_page_search_title => 'Nach Titel suchen';

  @override
  String get search_page_premium_title => 'Mehrere Tags auswählen ★';

  @override
  String get search_page_premium_description =>
      'Die Suche mit mehreren Kategorien\nist nur für Premium-Nutzer verfügbar.';

  @override
  String get search_page_segment_button_app => 'In der App';

  @override
  String get search_page_segment_button_web => 'Web';

  @override
  String get search_page_text_empty => 'Bitte einen Suchbegriff eingeben';

  @override
  String get search_page_web_title => 'Websuche';

  @override
  String get search_page_search_word => 'Suchbegriff';

  @override
  String get search_page_select_site => 'Nach Website filtern';

  @override
  String get search_page_open_site => 'Website öffnen';

  @override
  String get search_page_modify_favorite => 'Favoriten bearbeiten';

  @override
  String get search_page_site_name => 'Name der Website';

  @override
  String get search_page_input_all => 'Bitte alle Felder ausfüllen';

  @override
  String get search_page_add_favorite => 'Website zu Favoriten hinzufügen';

  @override
  String get search_result_page_site_saved => 'Website wurde gespeichert';

  @override
  String get search_result_page_saving_as_item => 'Eintrag speichern';

  @override
  String get search_result_page_saving_list => 'Zielliste';

  @override
  String get search_result_page_url_already_saved =>
      'Diese URL wurde bereits gespeichert';

  @override
  String get search_result_page_has_saved => 'Eintrag wurde gespeichert';

  @override
  String search_result_page_delete_site(Object siteName) {
    return '\"$siteName\" aus Favoriten entfernen?';
  }

  @override
  String get search_result_page_new_list => 'Neue Liste';

  @override
  String get search_result_page_input_list_name => 'Listennamen eingeben';

  @override
  String get search_result_page_list_already_exists =>
      'Eine Liste mit diesem Namen existiert bereits';

  @override
  String get analytics => 'Analyse';

  @override
  String get analytics_page_summary => 'Übersicht';

  @override
  String analytics_page_item_count(Object totalWorks) {
    return 'Gespeicherte Elemente: $totalWorks';
  }

  @override
  String get analytics_page_recent_additions =>
      'Kürzlich hinzugefügte Elemente';

  @override
  String analytics_page_piechart_others(Object percent) {
    return 'Andere\n$percent%';
  }

  @override
  String get analytics_page_view_count_top5 => 'Top 5 Aufrufe';

  @override
  String get analytics_page_no_data => 'Keine Daten verfügbar';

  @override
  String get analytics_page_evaluation => 'Bewertung';

  @override
  String get analytics_page_cast => 'Darsteller';

  @override
  String get analytics_page_genre => 'Genre';

  @override
  String get analytics_page_series => 'Serie';

  @override
  String get analytics_page_label => 'Label';

  @override
  String get analytics_page_maker => 'Produzent';

  @override
  String get analytics_page_premium_title => 'Analyse ★';

  @override
  String get analytics_page_premium_description =>
      'Analysefunktionen sind in ArchiVe Premium verfügbar.\nBitte upgraden Sie, um sie zu nutzen.';

  @override
  String get analytics_page_premium_button => 'Premium-Details anzeigen';

  @override
  String analytics_page_list_value(Object entry, Object percent) {
    return '$percent% ($entry Einträge)';
  }

  @override
  String get analytics_page_count => '(Aufrufe)';

  @override
  String analytics_page_toolchip_count(Object rod) {
    return '$rod Aufrufe';
  }

  @override
  String get analytics_page_no_title => 'Kein Titel';

  @override
  String get analytics_page_item_count_top5 => 'Top 5 Eintragsanzahl';

  @override
  String get settings => 'Einstellungen';

  @override
  String get settings_page_dark_mode => 'Dunkelmodus';

  @override
  String get settings_page_theme_color => 'Designfarbe ★';

  @override
  String get settings_page_theme_color_orange => 'Orange';

  @override
  String get settings_page_theme_color_green => 'Grün';

  @override
  String get settings_page_theme_color_blue => 'Blau';

  @override
  String get settings_page_theme_color_white => 'Weiß';

  @override
  String get settings_page_theme_color_red => 'Rot';

  @override
  String get settings_page_theme_color_yellow => 'Gelb';

  @override
  String get settings_page_thumbnail_visibility =>
      'Vorschaubilder in Listen anzeigen';

  @override
  String get settings_page_save_status => 'Speicherstatus';

  @override
  String get settings_page_save_count => 'Gespeicherte Einträge';

  @override
  String get settings_page_watch_count => 'Heutige Aufrufe';

  @override
  String settings_page_watch_ad_today(Object watchedAdsToday) {
    return '$watchedAdsToday / 3';
  }

  @override
  String get settings_page_watch_ad => 'Werbung ansehen (+5 Slots)';

  @override
  String get settings_page_ad_limit_reached => 'Tägliches Werbelimit erreicht';

  @override
  String get settings_page_already_purchased => 'Bereits gekauft.';

  @override
  String get settings_page_premium => 'ArchiVe Premium';

  @override
  String get settings_page_app_version => 'App-Version';

  @override
  String get settings_page_plivacy_policy => 'Datenschutzrichtlinie';

  @override
  String get settings_page_disable_link => 'Link konnte nicht geöffnet werden';

  @override
  String get settings_page_terms => 'Nutzungsbedingungen (Apple Standard EULA)';

  @override
  String get settings_page_save_count_increased => 'Speicherlimit um +5 erhöht';

  @override
  String get setting_page_unlimited => 'Unbegrenzt';

  @override
  String view_counter_view_count(Object viewCount) {
    return 'Aufrufe: $viewCount';
  }

  @override
  String get random_image_no_image => 'Bild konnte nicht geladen werden';

  @override
  String get random_image_change_list_name => 'Listennamen ändern';

  @override
  String get random_image_change_list_name_dialog => 'Listennamen ändern';

  @override
  String get random_image_change_list_name_hint => 'Listennamen eingeben';

  @override
  String get random_image_change_list_name_confirm => 'Ändern';

  @override
  String get random_image_delete_list => 'Liste löschen';

  @override
  String get random_image_delete_list_dialog => 'Diese Liste löschen?';

  @override
  String get random_image_delete_list_dialog_description =>
      'Die Einträge in dieser Liste werden ebenfalls gelöscht.';

  @override
  String get random_image_delete_list_confirm => 'Löschen';

  @override
  String get premium_detail_purchase_complete => 'Premium erfolgreich gekauft!';

  @override
  String get premium_detail_purchase_incomplete =>
      'Kauf abgeschlossen, aber Premium wurde nicht aktiviert';

  @override
  String get premium_detail_no_item => 'Keine kaufbaren Pläne gefunden';

  @override
  String premium_detail_ex(Object ex) {
    return 'Kauffehler: $ex';
  }

  @override
  String get premium_detail_premium_title => 'ArchiVe Premium';

  @override
  String get premium_detail_premium_item01 => 'Unbegrenzte Speicherplätze';

  @override
  String get premium_detail_premium_item02 => 'Designfarben frei ändern';

  @override
  String get premium_detail_premium_item03 => 'Bilder frei hinzufügen';

  @override
  String get premium_detail_premium_item04 => 'Schnellsuche mit mehreren Tags';

  @override
  String get premium_detail_premium_item05 =>
      'Statistiken nach Genre und Bewertung visualisieren';

  @override
  String get premium_detail_premium_item06 => 'Werbung entfernen';

  @override
  String get premium_detail_price => 'Start ab ¥170 / Monat';

  @override
  String get premium_detail_note => 'Jederzeit kündbar';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get tutorial_01 => 'Erstellen wir zuerst eine Liste.';

  @override
  String get tutorial_02 => 'Öffnen Sie die gerade erstellte Liste.';

  @override
  String get tutorial_03 =>
      'Tippen Sie auf die + Taste, um einen Eintrag hinzuzufügen.';

  @override
  String get tutorial_04 => 'Geben Sie die URL des Videos oder Inhalts ein.';

  @override
  String get tutorial_05 =>
      'Tippen Sie auf diese Schaltfläche, um den Titel automatisch abzurufen.';

  @override
  String get tutorial_06 =>
      'Speichern Sie abschließend, um es zur Liste hinzuzufügen.';

  @override
  String get start_tutorial_dialog => 'Tutorial neu starten?';

  @override
  String get start_tutorial_dialog_description =>
      'Die Schritte ab der Listenerstellung werden erneut angezeigt.';

  @override
  String get completed_tutorial => 'Tutorial abgeschlossen!\nGut gemacht!';

  @override
  String get tutorial_list_name => 'Später ansehen';

  @override
  String get tutorial_slide_title_01 => 'Ein Video-Manager\nOhne Downloads';

  @override
  String get tutorial_slide_dict_01 =>
      'Sammeln Sie unbegrenzt Videos ohne Speicherplatz zu verbrauchen';

  @override
  String get tutorial_slide_image_01 => 'assets/tutorial/english01.png';

  @override
  String get tutorial_slide_title_02 =>
      '[2 einfache Schritte]\n1. URL kopieren';

  @override
  String get tutorial_slide_dict_02 =>
      'Kopieren Sie den Freigabelink oder die Browser-URL von einer beliebigen Videoseite';

  @override
  String get tutorial_slide_image_02 => 'assets/tutorial/english02.png';

  @override
  String get tutorial_slide_title_03 =>
      '[2 einfache Schritte]\n2. URL speichern';

  @override
  String get tutorial_slide_dict_03 =>
      'Einfach einfügen und speichern\nBewertungen, Tags und Notizen hinzufügen';

  @override
  String get tutorial_slide_image_03 => 'assets/tutorial/english03.png';

  @override
  String get tutorial_slide_title_04 => 'In der App suchen';

  @override
  String get tutorial_slide_dict_04 =>
      'Gespeicherte Videos sofort nach Titel oder Tags finden';

  @override
  String get tutorial_slide_image_04 => 'assets/tutorial/english04.png';

  @override
  String get tutorial_slide_title_05 => 'Websuche';

  @override
  String get tutorial_slide_dict_05 =>
      'Videos direkt im In-App-Browser durchsuchen und speichern';

  @override
  String get tutorial_slide_image_05 => 'assets/tutorial/english05.png';

  @override
  String get tutorial_slide_title_06 => 'Unbegrenzte Möglichkeiten';

  @override
  String get tutorial_slide_dict_06 =>
      'Erstellen Sie Ihre eigene persönliche Videosammlung!';

  @override
  String get tutorial_slide_image_06 => 'assets/tutorial/english06.png';

  @override
  String get tutorial_slide_next => 'Weiter';

  @override
  String get tutorial_slide_start => 'Loslegen';
}
