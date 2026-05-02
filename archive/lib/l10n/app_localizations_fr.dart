// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class L10nFr extends L10n {
  L10nFr([String locale = 'fr']) : super(locale);

  @override
  String get app_title => 'ArchiVe';

  @override
  String get version => 'v1.8';

  @override
  String get critical => 'Critique';

  @override
  String get normal => 'Normal';

  @override
  String get maniac => 'Passionné';

  @override
  String get unrated => 'Non évalué';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annuler';

  @override
  String get back => 'Retour';

  @override
  String get add => 'Ajouter';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String get reload => 'Actualiser';

  @override
  String get all_item_list_name => 'Tous les éléments';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get clear => 'Effacer';

  @override
  String get favorite => 'Favori';

  @override
  String get url => 'URL';

  @override
  String get title => 'Titre';

  @override
  String get no_select => 'Aucun';

  @override
  String get modify => 'Modifier';

  @override
  String get close => 'Fermer';

  @override
  String get skip => 'Ignorer';

  @override
  String get save_limit_dialog_title => 'Limite d’enregistrement atteinte';

  @override
  String get save_limit_dialog_status_label => 'Enregistré';

  @override
  String get save_limit_dialog_premium_detail => 'Voir les détails Premium';

  @override
  String get save_limit_loading_ad => 'Chargement de la publicité...';

  @override
  String get main_page_lists => 'Listes';

  @override
  String get main_page_search => 'Rechercher & Collecter';

  @override
  String get main_page_analytics => 'Statistiques';

  @override
  String get main_page_settings => 'Paramètres';

  @override
  String get main_page_update_info => 'Avis de mise à jour';

  @override
  String get main_page_update_later => 'Plus tard';

  @override
  String get main_page_update_now => 'Mettre à jour';

  @override
  String get list_page_my_list => 'Mes listes';

  @override
  String get list_page_my_ranking => 'Mes classements';

  @override
  String get list_page_make_list => 'Créer une liste';

  @override
  String get list_page_add_list => 'Ajouter une liste';

  @override
  String get list_page_input_list_name => 'Entrer le nom de la liste';

  @override
  String get ranking_page_dragable => 'Glisser pour réorganiser';

  @override
  String get ranking_page_no_title => '(Sans titre)';

  @override
  String get ranking_page_search_title => 'Rechercher un titre';

  @override
  String get ranking_page_no_grid_item => 'Aucun élément enregistré';

  @override
  String get ranking_page_limit_error =>
      'Vous pouvez ajouter jusqu’à 10 éléments maximum';

  @override
  String get ranking_page_no_ranking_item => 'Aucun élément classé';

  @override
  String get ranking_page_no_ranking_item_description =>
      'Veuillez ajouter des éléments depuis la liste ci-dessous';

  @override
  String grid_page_item_count(Object length) {
    return '$length éléments';
  }

  @override
  String get grid_page_no_item => 'Aucun élément';

  @override
  String get grid_page_add_item => 'Choisissez comment ajouter un élément';

  @override
  String get grid_page_by_web => 'Ajouter via recherche web';

  @override
  String get grid_page_by_manual => 'Ajouter manuellement';

  @override
  String get grid_page_cant_load_image => 'Impossible de charger l’image';

  @override
  String get grid_page_no_title => '(Sans titre)';

  @override
  String get grid_page_url_unable => 'URL invalide';

  @override
  String get grid_page_sort_title => 'Titre';

  @override
  String get grid_page_sort_new => 'Plus récent en premier';

  @override
  String get grid_page_sort_old => 'Plus ancien en premier';

  @override
  String get grid_page_sort_count_asc => 'Les plus vus';

  @override
  String get grid_page_sort_count_desc => 'Les moins vus';

  @override
  String grid_page_items_selected_delete(Object count) {
    return 'Supprimer $count éléments sélectionnés ?';
  }

  @override
  String get grid_page_rating_guidance =>
      'Les éléments évalués apparaîtront ici';

  @override
  String get detail_page_url_empty => 'L’URL est vide.';

  @override
  String get detail_page_input_url => 'Veuillez entrer une URL.';

  @override
  String get detail_page_url_changed => 'L’URL a été modifiée.';

  @override
  String get detail_page_url_changed_note =>
      'Modifier l’URL enregistrera cet élément comme nouveau.\nVoulez-vous continuer ?';

  @override
  String get detail_page_no_selected => 'Non sélectionné';

  @override
  String get detail_page_item_detail => 'Détails de l’élément';

  @override
  String get detail_page_delete => 'Supprimer';

  @override
  String get detail_page_access => 'Navigateur';

  @override
  String get detail_page_modify => 'Modifier';

  @override
  String get detail_page_save => 'Enregistrer';

  @override
  String get detail_page_thumbnail_placeholder =>
      'La miniature apparaîtra après l’enregistrement';

  @override
  String get detail_page_add_image => 'Ajouter une image ★';

  @override
  String get detail_page_rate => 'Évaluation';

  @override
  String get detail_page_title => 'Titre';

  @override
  String get detail_page_title_placeholder => 'Titre';

  @override
  String get detail_page_cast => 'Distribution (# multiple)';

  @override
  String get detail_page_cast_placeholder => '#Acteur1 #Acteur2 ...';

  @override
  String get detail_page_genre => 'Genre (# multiple)';

  @override
  String get detail_page_genre_placeholder => '#Genre1 #Genre2 ...';

  @override
  String get detail_page_series => 'Série (# multiple)';

  @override
  String get detail_page_series_placeholder => '#Serie1 #Serie2 ...';

  @override
  String get detail_page_label => 'Label (# multiple)';

  @override
  String get detail_page_label_placeholder => '#Label1 #Label2 ...';

  @override
  String get detail_page_maker => 'Créateur (# multiple)';

  @override
  String get detail_page_maker_placeholder => '#Createur1 #Createur2 ...';

  @override
  String get detail_page_paste_url => 'Coller l’URL';

  @override
  String get detail_page_fetch_title => 'Récupérer le titre depuis l’URL';

  @override
  String get detail_page_list => 'Liste';

  @override
  String get detail_page_memo => 'Mémo';

  @override
  String get detail_page_fetch_title_fail => 'Titre introuvable.';

  @override
  String get detail_page_fetch_page_fail => 'Échec du chargement de la page.';

  @override
  String get detail_page_ex => 'Une erreur est survenue.';

  @override
  String get detail_page_delete_confirm01 => 'Supprimer cet élément ?';

  @override
  String get detail_page_delete_confirm02 => 'Cette action est irréversible.';

  @override
  String get detail_page_url_unable => 'URL invalide';

  @override
  String get detail_page_review_confirm01 =>
      'Appréciez-vous \"ArchiVe - Gestionnaire de vidéos favorites\" ?';

  @override
  String get detail_page_review_confirm02 =>
      'Merci d’utiliser notre application.\n\nVos commentaires seront soigneusement examinés par le développeur et utilisés pour améliorer les futures mises à jour.\n\nSi l’application vous plaît, nous apprécierions beaucoup votre avis.';

  @override
  String get detail_page_review_contact_support => 'Signaler un avis ou un bug';

  @override
  String get detail_page_review_later => 'Plus tard';

  @override
  String get detail_page_review_now => 'Laisser un avis';

  @override
  String get detail_page_mail_subject => 'subject=Retour ArchiVe';

  @override
  String get detail_page_fetching_thumbnail =>
      'Récupération de la miniature...';

  @override
  String get search_page_cast => 'Distribution';

  @override
  String get search_page_genre => 'Genre';

  @override
  String get search_page_series => 'Série';

  @override
  String get search_page_label => 'Label';

  @override
  String get search_page_maker => 'Créateur';

  @override
  String get search_page_search => 'Rechercher';

  @override
  String get search_page_select_category => 'Sélectionner une catégorie';

  @override
  String get search_page_more => 'Afficher plus';

  @override
  String get search_page_fold => 'Afficher moins';

  @override
  String get search_page_search_title => 'Rechercher par titre';

  @override
  String get search_page_premium_title => 'Sélection multiple de tags ★';

  @override
  String get search_page_premium_description =>
      'La recherche avec plusieurs catégories\nest réservée aux utilisateurs Premium.';

  @override
  String get search_page_segment_button_app => 'Dans l’application';

  @override
  String get search_page_segment_button_web => 'Web';

  @override
  String get search_page_text_empty => 'Veuillez entrer un terme de recherche';

  @override
  String get search_page_web_title => 'Recherche web';

  @override
  String get search_page_search_word => 'Mot-clé';

  @override
  String get search_page_select_site => 'Filtrer par site';

  @override
  String get search_page_open_site => 'Ouvrir le site';

  @override
  String get search_page_modify_favorite => 'Modifier les favoris';

  @override
  String get search_page_site_name => 'Nom du site';

  @override
  String get search_page_input_all => 'Veuillez remplir tous les champs';

  @override
  String get search_page_add_favorite => 'Ajouter un site favori';

  @override
  String get search_page_random_loading =>
      'Sélection de la recommandation du jour…';

  @override
  String get search_page_random_this => 'La recommandation du jour !';

  @override
  String get search_result_page_site_saved => 'Site enregistré';

  @override
  String get search_result_page_saving_as_item => 'Enregistrer l’élément';

  @override
  String get search_result_page_saving_list => 'Liste de destination';

  @override
  String get search_result_page_url_already_saved =>
      'Cette URL est déjà enregistrée';

  @override
  String get search_result_page_has_saved => 'L\'article a été enregistré';

  @override
  String search_result_page_delete_site(Object siteName) {
    return 'Supprimer \"$siteName\" des favoris ?';
  }

  @override
  String get search_result_page_new_list => 'Nouvelle liste';

  @override
  String get search_result_page_input_list_name => 'Entrer le nom de la liste';

  @override
  String get search_result_page_list_already_exists =>
      'Une liste avec le même nom existe déjà';

  @override
  String get search_result_page_history => 'Historique';

  @override
  String get search_result_page_ad_remainder01 =>
      'Une publicité sera affichée après le prochain enregistrement';

  @override
  String get search_result_page_ad_remainder02 => 'Afficher la publicité';

  @override
  String get analytics => 'Statistiques';

  @override
  String get analytics_page_summary => 'Aperçu';

  @override
  String analytics_page_item_count(Object totalWorks) {
    return 'Éléments enregistrés : $totalWorks';
  }

  @override
  String get analytics_page_recent_additions => 'Éléments récemment ajoutés';

  @override
  String analytics_page_piechart_others(Object percent) {
    return 'Autres\n$percent%';
  }

  @override
  String get analytics_page_view_count_top5 => 'Top 5 des vues';

  @override
  String get analytics_page_no_data => 'Aucune donnée disponible';

  @override
  String get analytics_page_evaluation => 'Évaluation';

  @override
  String get analytics_page_cast => 'Distribution';

  @override
  String get analytics_page_genre => 'Genre';

  @override
  String get analytics_page_series => 'Série';

  @override
  String get analytics_page_label => 'Label';

  @override
  String get analytics_page_maker => 'Créateur';

  @override
  String get analytics_page_premium_title => 'Statistiques ★';

  @override
  String get analytics_page_premium_description =>
      'Les fonctionnalités statistiques sont disponibles dans ArchiVe Premium.\nVeuillez passer à la version Premium.';

  @override
  String get analytics_page_premium_button => 'Voir les détails Premium';

  @override
  String analytics_page_list_value(Object entry, Object percent) {
    return '$percent% ($entry éléments)';
  }

  @override
  String get analytics_page_count => '(vues)';

  @override
  String analytics_page_toolchip_count(Object rod) {
    return '$rod vues';
  }

  @override
  String get analytics_page_no_title => 'Sans titre';

  @override
  String get analytics_page_item_count_top5 => 'Top 5 du nombre d’éléments';

  @override
  String get settings => 'Paramètres';

  @override
  String get settings_page_dark_mode => 'Mode sombre';

  @override
  String get settings_page_theme_color => 'Couleur du thème ★';

  @override
  String get settings_page_theme_color_orange => 'Orange';

  @override
  String get settings_page_theme_color_green => 'Vert';

  @override
  String get settings_page_theme_color_blue => 'Bleu';

  @override
  String get settings_page_theme_color_white => 'Blanc';

  @override
  String get settings_page_theme_color_red => 'Rouge';

  @override
  String get settings_page_theme_color_yellow => 'Jaune';

  @override
  String get settings_page_thumbnail_visibility => 'Afficher les miniatures';

  @override
  String get settings_page_save_status => 'Statut d’enregistrement';

  @override
  String get settings_page_save_count => 'Éléments enregistrés';

  @override
  String get settings_page_watch_count => 'Vues aujourd’hui';

  @override
  String settings_page_watch_ad_today(Object watchedAdsToday) {
    return '$watchedAdsToday / 3';
  }

  @override
  String get settings_page_watch_ad => 'Regarder une pub (+5 emplacements)';

  @override
  String get settings_page_ad_limit_reached =>
      'Limite quotidienne de publicités atteinte';

  @override
  String get settings_page_already_purchased => 'Déjà acheté.';

  @override
  String get settings_page_premium => 'ArchiVe Premium';

  @override
  String get settings_page_app_version => 'Version de l’application';

  @override
  String get settings_page_plivacy_policy => 'Politique de confidentialité';

  @override
  String get settings_page_disable_link => 'Impossible d’ouvrir le lien';

  @override
  String get settings_page_terms =>
      'Conditions d’utilisation (EULA standard Apple)';

  @override
  String get settings_page_save_count_increased => 'Limite augmentée de +5';

  @override
  String get setting_page_unlimited => 'Illimité';

  @override
  String view_counter_view_count(Object viewCount) {
    return 'Vues : $viewCount';
  }

  @override
  String get random_image_no_image => 'Impossible de charger l’image';

  @override
  String get random_image_change_list_name => 'Changer le nom de la liste';

  @override
  String get random_image_change_list_name_dialog =>
      'Changer le nom de la liste';

  @override
  String get random_image_change_list_name_hint => 'Entrer le nom de la liste';

  @override
  String get random_image_change_list_name_confirm => 'Changer';

  @override
  String get random_image_delete_list => 'Supprimer la liste';

  @override
  String get random_image_delete_list_dialog => 'Supprimer cette liste ?';

  @override
  String get random_image_delete_list_dialog_description =>
      'Les éléments de cette liste seront également supprimés.';

  @override
  String get random_image_delete_list_confirm => 'Supprimer';

  @override
  String get premium_detail_premium_title => 'ArchiVe Premium';

  @override
  String get premium_detail_premium_item01 => 'Sauvegardes illimitées';

  @override
  String get premium_detail_premium_item02 =>
      'Personnaliser les couleurs du thème';

  @override
  String get premium_detail_premium_item03 => 'Ajouter librement des images';

  @override
  String get premium_detail_premium_item04 =>
      'Recherche rapide avec plusieurs tags';

  @override
  String get premium_detail_premium_item05 =>
      'Statistiques pour visualiser les données par genre et évaluation';

  @override
  String get premium_detail_premium_item06 => 'Supprimer les publicités';

  @override
  String get premium_detail_note =>
      'Après l’essai gratuit d’un mois, l’abonnement sera renouvelé automatiquement.\nAnnulation possible à tout moment.';

  @override
  String get premium_detail_restore_not_found =>
      'Aucun historique d’achat trouvé';

  @override
  String get premium_detail_free_trial_badge => '1 mois gratuit';

  @override
  String get premium_detail_start_trial =>
      'Commencer l’essai gratuit d’un mois';

  @override
  String premium_detail_price_after_trial(Object price) {
    return 'Puis $price / mois';
  }

  @override
  String get premium_detail_restore_button => 'Restaurer les achats';

  @override
  String get premium_detail_purchase_complete => 'Premium acheté avec succès !';

  @override
  String get premium_detail_restart_message =>
      'Les fonctionnalités Premium ont été activées.\nL’application va redémarrer.';

  @override
  String get tutorial => 'Tutoriel';

  @override
  String get tutorial_01 => 'Commençons par créer une liste.';

  @override
  String get tutorial_02 => 'Ouvrez la liste que vous venez de créer.';

  @override
  String get tutorial_03 => 'Appuyez sur le bouton + pour ajouter un élément.';

  @override
  String get tutorial_04 => 'Entrez l’URL de la vidéo ou du contenu.';

  @override
  String get tutorial_05 =>
      'Appuyez sur ce bouton pour récupérer automatiquement le titre.';

  @override
  String get tutorial_06 => 'Enfin, enregistrez pour l’ajouter à la liste.';

  @override
  String get start_tutorial_dialog => 'Redémarrer le tutoriel ?';

  @override
  String get start_tutorial_dialog_description =>
      'Les étapes depuis la création de la liste seront affichées à nouveau.';

  @override
  String get completed_tutorial => 'Tutoriel terminé !\nExcellent travail !';

  @override
  String get tutorial_list_name => 'À regarder plus tard';

  @override
  String get tutorial_slide_title_01 =>
      'Un gestionnaire vidéo\nSans téléchargement';

  @override
  String get tutorial_slide_dict_01 =>
      'Collectez des vidéos illimitées sans utiliser de stockage';

  @override
  String get tutorial_slide_image_01 => 'assets/tutorial/english01.png';

  @override
  String get tutorial_slide_title_02 => '[2 étapes faciles]\n1. Copier l’URL';

  @override
  String get tutorial_slide_dict_02 =>
      'Copiez le lien de partage ou l’URL du navigateur depuis n’importe quel site vidéo';

  @override
  String get tutorial_slide_image_02 => 'assets/tutorial/english02.png';

  @override
  String get tutorial_slide_title_03 =>
      '[2 étapes faciles]\n2. Enregistrer l’URL';

  @override
  String get tutorial_slide_dict_03 =>
      'Collez simplement pour enregistrer\nAjoutez évaluations, tags et notes';

  @override
  String get tutorial_slide_image_03 => 'assets/tutorial/english03.png';

  @override
  String get tutorial_slide_title_04 => 'Recherche dans l’application';

  @override
  String get tutorial_slide_dict_04 =>
      'Trouvez instantanément vos vidéos enregistrées par titre ou tags';

  @override
  String get tutorial_slide_image_04 => 'assets/tutorial/english04.png';

  @override
  String get tutorial_slide_title_05 => 'Recherche web';

  @override
  String get tutorial_slide_dict_05 =>
      'Naviguez et enregistrez instantanément avec le navigateur intégré';

  @override
  String get tutorial_slide_image_05 => 'assets/tutorial/english05.png';

  @override
  String get tutorial_slide_title_06 => 'Possibilités illimitées';

  @override
  String get tutorial_slide_dict_06 =>
      'Créez votre propre collection vidéo personnelle !';

  @override
  String get tutorial_slide_image_06 => 'assets/tutorial/english06.png';

  @override
  String get tutorial_slide_next => 'Suivant';

  @override
  String get tutorial_slide_start => 'Commencer';

  @override
  String get share_saved => 'Sauvegardé depuis le partage';

  @override
  String get share_already_saved => 'Cette URL est déjà sauvegardée';
}
