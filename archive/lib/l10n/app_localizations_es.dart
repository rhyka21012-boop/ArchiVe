// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class L10nEs extends L10n {
  L10nEs([String locale = 'es']) : super(locale);

  @override
  String get app_title => 'ArchiVe';

  @override
  String get version => 'v1.8';

  @override
  String get critical => 'Crítico';

  @override
  String get normal => 'Normal';

  @override
  String get maniac => 'Maníaco';

  @override
  String get unrated => 'Sin calificar';

  @override
  String get ok => 'Aceptar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get back => 'Atrás';

  @override
  String get add => 'Añadir';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get reload => 'Actualizar';

  @override
  String get all_item_list_name => 'Todos los elementos';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get clear => 'Borrar';

  @override
  String get favorite => 'Favorito';

  @override
  String get url => 'URL';

  @override
  String get title => 'Título';

  @override
  String get no_select => 'Ninguno';

  @override
  String get modify => 'Editar';

  @override
  String get close => 'Cerrar';

  @override
  String get save_limit_dialog_title => 'Límite de guardado alcanzado';

  @override
  String get save_limit_dialog_status_label => 'Guardado';

  @override
  String get save_limit_dialog_premium_detail => 'Ver detalles Premium';

  @override
  String get save_limit_loading_ad => 'Cargando anuncio...';

  @override
  String get main_page_lists => 'Listas';

  @override
  String get main_page_search => 'Buscar y guardar';

  @override
  String get main_page_analytics => 'Estadísticas';

  @override
  String get main_page_settings => 'Ajustes';

  @override
  String get main_page_update_info => 'Aviso de actualización';

  @override
  String get main_page_update_later => 'Más tarde';

  @override
  String get main_page_update_now => 'Actualizar';

  @override
  String get list_page_my_list => 'Mis listas';

  @override
  String get list_page_my_ranking => 'Mi ranking';

  @override
  String get list_page_make_list => 'Crear lista';

  @override
  String get list_page_add_list => 'Añadir lista';

  @override
  String get list_page_input_list_name => 'Introducir nombre de la lista';

  @override
  String get ranking_page_dragable => 'Arrastra para ordenar';

  @override
  String get ranking_page_no_title => '(Sin título)';

  @override
  String get ranking_page_search_title => 'Buscar título';

  @override
  String get ranking_page_no_grid_item => 'No hay elementos guardados';

  @override
  String get ranking_page_limit_error =>
      'Solo puedes añadir hasta 10 elementos';

  @override
  String get ranking_page_no_ranking_item => 'No hay elementos en el ranking';

  @override
  String get ranking_page_no_ranking_item_description =>
      'Añade elementos desde la lista inferior';

  @override
  String grid_page_item_count(Object length) {
    return '$length elementos';
  }

  @override
  String get grid_page_no_item => 'Sin elementos';

  @override
  String get grid_page_add_item => 'Elegir cómo añadir';

  @override
  String get grid_page_by_web => 'Añadir desde la web';

  @override
  String get grid_page_by_manual => 'Añadir manualmente';

  @override
  String get grid_page_cant_load_image => 'No se puede cargar la imagen';

  @override
  String get grid_page_no_title => '(Sin título)';

  @override
  String get grid_page_url_unable => 'URL inválida';

  @override
  String get grid_page_sort_title => 'Por título';

  @override
  String get grid_page_sort_new => 'Más recientes primero';

  @override
  String get grid_page_sort_old => 'Más antiguos primero';

  @override
  String get grid_page_sort_count_asc => 'Más vistos';

  @override
  String get grid_page_sort_count_desc => 'Menos vistos';

  @override
  String grid_page_items_selected_delete(Object count) {
    return '¿Eliminar $count elementos seleccionados?';
  }

  @override
  String get grid_page_rating_guidance =>
      'Los elementos calificados aparecerán aquí';

  @override
  String get detail_page_url_empty => 'La URL está vacía.';

  @override
  String get detail_page_input_url => 'Introduce una URL.';

  @override
  String get detail_page_url_changed => 'La URL ha cambiado.';

  @override
  String get detail_page_url_changed_note =>
      'Cambiar la URL guardará esto como un nuevo elemento.\n¿Deseas continuar?';

  @override
  String get detail_page_no_selected => 'No seleccionado';

  @override
  String get detail_page_item_detail => 'Detalles del elemento';

  @override
  String get detail_page_delete => 'Eliminar';

  @override
  String get detail_page_access => 'Navegador';

  @override
  String get detail_page_modify => 'Editar';

  @override
  String get detail_page_save => 'Guardar';

  @override
  String get detail_page_thumbnail_placeholder =>
      'La miniatura aparecerá después de guardar';

  @override
  String get detail_page_add_image => 'Añadir imagen ★';

  @override
  String get detail_page_rate => 'Calificación';

  @override
  String get detail_page_title => 'Título';

  @override
  String get detail_page_title_placeholder => 'Título';

  @override
  String get detail_page_cast => 'Reparto (# múltiples)';

  @override
  String get detail_page_cast_placeholder => '#Actor1 #Actor2 ...';

  @override
  String get detail_page_genre => 'Género (# múltiples)';

  @override
  String get detail_page_genre_placeholder => '#Género1 #Género2 ...';

  @override
  String get detail_page_series => 'Serie (# múltiples)';

  @override
  String get detail_page_series_placeholder => '#Serie1 #Serie2 ...';

  @override
  String get detail_page_label => 'Etiqueta (# múltiples)';

  @override
  String get detail_page_label_placeholder => '#Etiqueta1 #Etiqueta2 ...';

  @override
  String get detail_page_maker => 'Productor (# múltiples)';

  @override
  String get detail_page_maker_placeholder => '#Productor1 #Productor2 ...';

  @override
  String get detail_page_paste_url => 'Pegar URL';

  @override
  String get detail_page_fetch_title => 'Obtener título desde URL';

  @override
  String get detail_page_list => 'Lista';

  @override
  String get detail_page_memo => 'Nota';

  @override
  String get detail_page_fetch_title_fail => 'Título no encontrado.';

  @override
  String get detail_page_fetch_page_fail => 'Error al cargar la página.';

  @override
  String get detail_page_ex => 'Ocurrió un error.';

  @override
  String get detail_page_delete_confirm01 => '¿Eliminar este elemento?';

  @override
  String get detail_page_delete_confirm02 =>
      'Esta acción no se puede deshacer.';

  @override
  String get detail_page_url_unable => 'URL inválida';

  @override
  String get detail_page_review_confirm01 =>
      '¿Te gusta \"ArchiVe - Favorite Video Tracker\"?';

  @override
  String get detail_page_review_confirm02 =>
      'Gracias por usar nuestra app.\n\nTu opinión será revisada cuidadosamente y utilizada para mejorar futuras actualizaciones.\n\nSi te gusta la app, agradeceríamos mucho tu reseña.';

  @override
  String get detail_page_review_contact_support =>
      'Enviar comentario o reportar error';

  @override
  String get detail_page_review_later => 'Más tarde';

  @override
  String get detail_page_review_now => 'Dejar reseña';

  @override
  String get detail_page_mail_subject => 'subject=Comentarios ArchiVe';

  @override
  String get search_page_cast => 'Reparto';

  @override
  String get search_page_genre => 'Género';

  @override
  String get search_page_series => 'Serie';

  @override
  String get search_page_label => 'Etiqueta';

  @override
  String get search_page_maker => 'Productor';

  @override
  String get search_page_search => 'Buscar';

  @override
  String get search_page_select_category => 'Seleccionar categoría';

  @override
  String get search_page_more => 'Ver más';

  @override
  String get search_page_fold => 'Ver menos';

  @override
  String get search_page_search_title => 'Buscar por título';

  @override
  String get search_page_premium_title => 'Seleccionar varias etiquetas ★';

  @override
  String get search_page_premium_description =>
      'La búsqueda con múltiples categorías\nestá disponible solo para usuarios Premium.';

  @override
  String get search_page_segment_button_app => 'En la app';

  @override
  String get search_page_segment_button_web => 'Web';

  @override
  String get search_page_text_empty => 'Introduce un término de búsqueda';

  @override
  String get search_page_web_title => 'Búsqueda web';

  @override
  String get search_page_search_word => 'Término de búsqueda';

  @override
  String get search_page_select_site => 'Filtrar por sitio';

  @override
  String get search_page_open_site => 'Abrir sitio';

  @override
  String get search_page_modify_favorite => 'Editar favoritos';

  @override
  String get search_page_site_name => 'Nombre del sitio';

  @override
  String get search_page_input_all => 'Completa todos los campos';

  @override
  String get search_page_add_favorite => 'Añadir sitio favorito';

  @override
  String get search_result_page_site_saved => 'Sitio guardado';

  @override
  String get search_result_page_saving_as_item => 'Guardar elemento';

  @override
  String get search_result_page_saving_list => 'Lista de destino';

  @override
  String get search_result_page_url_already_saved =>
      'Esta URL ya está guardada';

  @override
  String get search_result_page_has_saved => 'El artículo ha sido guardado';

  @override
  String search_result_page_delete_site(Object siteName) {
    return '¿Eliminar \"$siteName\" de favoritos?';
  }

  @override
  String get search_result_page_new_list => 'Nueva lista';

  @override
  String get search_result_page_input_list_name =>
      'Introducir nombre de la lista';

  @override
  String get search_result_page_list_already_exists =>
      'Ya existe una lista con ese nombre';

  @override
  String get analytics => 'Estadísticas';

  @override
  String get analytics_page_summary => 'Resumen';

  @override
  String analytics_page_item_count(Object totalWorks) {
    return 'Elementos guardados: $totalWorks';
  }

  @override
  String get analytics_page_recent_additions =>
      'Elementos añadidos recientemente';

  @override
  String analytics_page_piechart_others(Object percent) {
    return 'Otros\n$percent%';
  }

  @override
  String get analytics_page_view_count_top5 => 'Top 5 más vistos';

  @override
  String get analytics_page_no_data => 'No hay datos disponibles';

  @override
  String get analytics_page_evaluation => 'Calificación';

  @override
  String get analytics_page_cast => 'Reparto';

  @override
  String get analytics_page_genre => 'Género';

  @override
  String get analytics_page_series => 'Serie';

  @override
  String get analytics_page_label => 'Etiqueta';

  @override
  String get analytics_page_maker => 'Productor';

  @override
  String get analytics_page_premium_title => 'Estadísticas ★';

  @override
  String get analytics_page_premium_description =>
      'Las funciones de estadísticas están disponibles en ArchiVe Premium.\nActualiza para usarlas.';

  @override
  String get analytics_page_premium_button => 'Ver detalles Premium';

  @override
  String analytics_page_list_value(Object entry, Object percent) {
    return '$percent% ($entry elementos)';
  }

  @override
  String get analytics_page_count => '(vistas)';

  @override
  String analytics_page_toolchip_count(Object rod) {
    return '$rod vistas';
  }

  @override
  String get analytics_page_no_title => 'Sin título';

  @override
  String get analytics_page_item_count_top5 => 'Top 5 por número de elementos';

  @override
  String get settings => 'Ajustes';

  @override
  String get settings_page_dark_mode => 'Modo oscuro';

  @override
  String get settings_page_theme_color => 'Color del tema ★';

  @override
  String get settings_page_theme_color_orange => 'Naranja';

  @override
  String get settings_page_theme_color_green => 'Verde';

  @override
  String get settings_page_theme_color_blue => 'Azul';

  @override
  String get settings_page_theme_color_white => 'Blanco';

  @override
  String get settings_page_theme_color_red => 'Rojo';

  @override
  String get settings_page_theme_color_yellow => 'Amarillo';

  @override
  String get settings_page_thumbnail_visibility =>
      'Mostrar miniaturas en listas';

  @override
  String get settings_page_save_status => 'Estado de guardado';

  @override
  String get settings_page_save_count => 'Elementos guardados';

  @override
  String get settings_page_watch_count => 'Vistas de hoy';

  @override
  String settings_page_watch_ad_today(Object watchedAdsToday) {
    return '$watchedAdsToday / 3';
  }

  @override
  String get settings_page_watch_ad => 'Ver anuncio (+5 espacios)';

  @override
  String get settings_page_ad_limit_reached =>
      'Límite diario de anuncios alcanzado';

  @override
  String get settings_page_already_purchased => 'Ya comprado.';

  @override
  String get settings_page_premium => 'ArchiVe Premium';

  @override
  String get settings_page_app_version => 'Versión de la app';

  @override
  String get settings_page_plivacy_policy => 'Política de privacidad';

  @override
  String get settings_page_disable_link => 'No se puede abrir el enlace';

  @override
  String get settings_page_terms =>
      'Términos de servicio (EULA estándar de Apple)';

  @override
  String get settings_page_save_count_increased =>
      'Límite de guardado aumentado en +5';

  @override
  String get setting_page_unlimited => 'Ilimitado';

  @override
  String view_counter_view_count(Object viewCount) {
    return 'Vistas: $viewCount';
  }

  @override
  String get random_image_no_image => 'No se puede cargar la imagen';

  @override
  String get random_image_change_list_name => 'Cambiar nombre de la lista';

  @override
  String get random_image_change_list_name_dialog =>
      'Cambiar nombre de la lista';

  @override
  String get random_image_change_list_name_hint =>
      'Introduce el nombre de la lista';

  @override
  String get random_image_change_list_name_confirm => 'Cambiar';

  @override
  String get random_image_delete_list => 'Eliminar lista';

  @override
  String get random_image_delete_list_dialog => '¿Eliminar esta lista?';

  @override
  String get random_image_delete_list_dialog_description =>
      'Los elementos de esta lista también se eliminarán.';

  @override
  String get random_image_delete_list_confirm => 'Eliminar';

  @override
  String get premium_detail_purchase_complete => '¡Premium comprado con éxito!';

  @override
  String get premium_detail_purchase_incomplete =>
      'Compra completada, pero Premium no se activó';

  @override
  String get premium_detail_no_item => 'No hay planes disponibles';

  @override
  String premium_detail_ex(Object ex) {
    return 'Error de compra: $ex';
  }

  @override
  String get premium_detail_premium_title => 'ArchiVe Premium';

  @override
  String get premium_detail_premium_item01 => 'Espacios de guardado ilimitados';

  @override
  String get premium_detail_premium_item02 =>
      'Cambiar colores del tema libremente';

  @override
  String get premium_detail_premium_item03 => 'Añadir imágenes libremente';

  @override
  String get premium_detail_premium_item04 =>
      'Búsqueda rápida con múltiples etiquetas';

  @override
  String get premium_detail_premium_item05 =>
      'Visualizar estadísticas por género y calificación';

  @override
  String get premium_detail_premium_item06 => 'Eliminar anuncios';

  @override
  String get premium_detail_price => 'Desde ¥170 / mes';

  @override
  String get premium_detail_note => 'Cancela en cualquier momento';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get tutorial_01 => 'Primero, crea una lista.';

  @override
  String get tutorial_02 => 'Abre la lista que acabas de crear.';

  @override
  String get tutorial_03 => 'Pulsa el botón + para añadir un elemento.';

  @override
  String get tutorial_04 => 'Introduce la URL del video o contenido.';

  @override
  String get tutorial_05 =>
      'Pulsa este botón para obtener el título automáticamente.';

  @override
  String get tutorial_06 => 'Por último, guarda para añadirlo a la lista.';

  @override
  String get start_tutorial_dialog => '¿Reiniciar el tutorial?';

  @override
  String get start_tutorial_dialog_description =>
      'Se mostrarán nuevamente los pasos desde la creación de la lista.';

  @override
  String get completed_tutorial => '¡Tutorial completado!\n¡Buen trabajo!';

  @override
  String get tutorial_list_name => 'Ver más tarde';

  @override
  String get tutorial_slide_title_01 => 'Gestor de videos\nSin descargas';

  @override
  String get tutorial_slide_dict_01 =>
      'Colecciona videos ilimitados sin usar almacenamiento';

  @override
  String get tutorial_slide_image_01 => 'assets/tutorial/english01.png';

  @override
  String get tutorial_slide_title_02 => '[2 pasos fáciles]\n1. Copiar la URL';

  @override
  String get tutorial_slide_dict_02 =>
      'Copia el enlace compartido o la URL del navegador desde cualquier sitio de videos';

  @override
  String get tutorial_slide_image_02 => 'assets/tutorial/english02.png';

  @override
  String get tutorial_slide_title_03 => '[2 pasos fáciles]\n2. Guardar la URL';

  @override
  String get tutorial_slide_dict_03 =>
      'Pega para guardar\nAñade calificaciones, etiquetas y notas';

  @override
  String get tutorial_slide_image_03 => 'assets/tutorial/english03.png';

  @override
  String get tutorial_slide_title_04 => 'Buscar en la app';

  @override
  String get tutorial_slide_dict_04 =>
      'Encuentra videos guardados al instante por título o etiquetas';

  @override
  String get tutorial_slide_image_04 => 'assets/tutorial/english04.png';

  @override
  String get tutorial_slide_title_05 => 'Búsqueda web';

  @override
  String get tutorial_slide_dict_05 =>
      'Navega y guarda videos al instante con el navegador integrado';

  @override
  String get tutorial_slide_image_05 => 'assets/tutorial/english05.png';

  @override
  String get tutorial_slide_title_06 => 'Posibilidades ilimitadas';

  @override
  String get tutorial_slide_dict_06 =>
      '¡Crea tu propia colección personal de videos!';

  @override
  String get tutorial_slide_image_06 => 'assets/tutorial/english06.png';

  @override
  String get tutorial_slide_next => 'Siguiente';

  @override
  String get tutorial_slide_start => 'Comenzar';
}
