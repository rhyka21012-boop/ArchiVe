// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class L10nPt extends L10n {
  L10nPt([String locale = 'pt']) : super(locale);

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
  String get unrated => 'Sem avaliação';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancelar';

  @override
  String get back => 'Voltar';

  @override
  String get add => 'Adicionar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get reload => 'Recarregar';

  @override
  String get all_item_list_name => 'Todos os Itens';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get clear => 'Limpar';

  @override
  String get favorite => 'Favorito';

  @override
  String get url => 'URL';

  @override
  String get title => 'Título';

  @override
  String get no_select => 'Nenhum';

  @override
  String get modify => 'Editar';

  @override
  String get close => 'Fechar';

  @override
  String get skip => 'Ignorar';

  @override
  String get save_limit_dialog_title => 'Limite de guardados atingido';

  @override
  String get save_limit_dialog_status_label => 'Guardado';

  @override
  String get save_limit_dialog_premium_detail => 'Ver detalhes Premium';

  @override
  String get save_limit_loading_ad => 'A carregar anúncio...';

  @override
  String get main_page_lists => 'Listas';

  @override
  String get main_page_search => 'Pesquisar';

  @override
  String get main_page_browser => 'Navegador';

  @override
  String get browser_home_url_hint => 'Introduzir URL ou pesquisar';

  @override
  String get browser_home_history => 'Histórico';

  @override
  String get browser_home_history_empty => 'Sem histórico';

  @override
  String get browser_home_history_clear => 'Limpar';

  @override
  String get browser_home_history_clear_confirm => 'Limpar todo o histórico?';

  @override
  String get browser_home_favorites => 'Sites favoritos';

  @override
  String get main_page_analytics => 'Análises';

  @override
  String get main_page_settings => 'Definições';

  @override
  String get main_page_update_info => 'Aviso de atualização';

  @override
  String get main_page_update_later => 'Mais tarde';

  @override
  String get main_page_update_now => 'Atualizar';

  @override
  String get list_page_home => 'Início';

  @override
  String get list_page_my_list => 'As minhas listas';

  @override
  String get list_page_my_ranking => 'As minhas classificações';

  @override
  String get list_page_make_list => 'Criar lista';

  @override
  String get list_page_add_list => 'Adicionar lista';

  @override
  String get list_page_input_list_name => 'Introduzir nome da lista';

  @override
  String get reset => 'Redefinir';

  @override
  String get list_page_rating_rename_title => 'Renomear avaliação';

  @override
  String get list_page_reorder => 'Reordenar';

  @override
  String get list_page_reorder_done => 'Concluído';

  @override
  String get list_page_reorder_hint => 'Arraste para alterar a ordem';

  @override
  String get list_page_all_item_fixed =>
      '«Todos os itens» não pode ser reordenado';

  @override
  String list_page_save_count(int count, int limit) {
    return 'Guardado $count / $limit';
  }

  @override
  String get list_page_item_unit => ' itens';

  @override
  String list_page_item_count(int count) {
    return '$count itens';
  }

  @override
  String get ranking_page_dragable => 'Arraste para reorganizar';

  @override
  String get ranking_page_no_title => '(Sem título)';

  @override
  String get ranking_page_search_title => 'Pesquisar título';

  @override
  String get ranking_page_no_grid_item => 'Sem itens guardados';

  @override
  String get ranking_page_limit_error => 'Só pode adicionar até 10 itens';

  @override
  String get ranking_page_no_ranking_item => 'Sem itens na classificação';

  @override
  String get ranking_page_no_ranking_item_description =>
      'Adicione itens da lista abaixo';

  @override
  String grid_page_item_count(Object length) {
    return '$length itens';
  }

  @override
  String get grid_page_no_item => 'Sem itens';

  @override
  String get grid_page_add_item => 'Escolha como adicionar um item';

  @override
  String get grid_page_by_web => 'Adicionar via pesquisa web';

  @override
  String get grid_page_by_manual => 'Adicionar manualmente';

  @override
  String get grid_page_cant_load_image => 'Não foi possível carregar a imagem';

  @override
  String get grid_page_no_title => '(Sem título)';

  @override
  String get grid_page_url_unable => 'URL inválido';

  @override
  String get grid_page_sort_title => 'Título';

  @override
  String get grid_page_sort_new => 'Mais recentes primeiro';

  @override
  String get grid_page_sort_old => 'Mais antigos primeiro';

  @override
  String get grid_page_sort_count_asc => 'Mais visualizados';

  @override
  String get grid_page_sort_count_desc => 'Menos visualizados';

  @override
  String get grid_page_sort_rating => 'Por avaliação';

  @override
  String get grid_page_sort_offline_first => 'Offline primeiro';

  @override
  String get grid_page_sort_list_name => 'Por nome da lista';

  @override
  String get grid_page_sort_random => 'Aleatório';

  @override
  String get grid_page_sort_by_cast => 'Por elenco';

  @override
  String get grid_page_sort_by_date => 'Por data adicionada';

  @override
  String grid_page_sort_current(String label) {
    return 'Ordenar: $label';
  }

  @override
  String grid_page_items_selected_delete(Object count) {
    return 'Eliminar $count itens selecionados?';
  }

  @override
  String get grid_page_rating_guidance => 'Os itens avaliados aparecerão aqui';

  @override
  String get detail_page_url_empty => 'O URL está vazio.';

  @override
  String get detail_page_input_url => 'Introduza um URL.';

  @override
  String get detail_page_url_changed => 'O URL foi alterado.';

  @override
  String get detail_page_url_changed_note =>
      'Alterar o URL irá guardar como novo item.\nDeseja continuar?';

  @override
  String get detail_page_no_selected => 'Não selecionado';

  @override
  String get detail_page_item_detail => 'Detalhes do item';

  @override
  String get detail_page_delete => 'Eliminar';

  @override
  String get detail_page_access => 'Navegador';

  @override
  String get detail_page_modify => 'Editar';

  @override
  String get detail_page_share => 'Partilhar';

  @override
  String get detail_page_copied => 'Copiado';

  @override
  String detail_page_saved_to(String listName) {
    return 'Guardado em $listName';
  }

  @override
  String get detail_page_save => 'Guardar';

  @override
  String get detail_page_thumbnail_placeholder =>
      'A miniatura aparecerá após guardar';

  @override
  String get detail_page_add_image => 'Adicionar miniatura ★';

  @override
  String get detail_page_offline => 'Offline';

  @override
  String get detail_page_offline_downloaded => 'Guardado offline';

  @override
  String get detail_page_offline_confirm_title => 'Guardar este item offline?';

  @override
  String get detail_page_offline_confirm_body =>
      'O vídeo será transferido para este dispositivo.\n※Guarde apenas vídeos dos quais detém os direitos ou tenha autorização.';

  @override
  String get detail_page_offline_no_url => 'URL vazio';

  @override
  String get detail_page_offline_started => 'Transferência iniciada';

  @override
  String get detail_page_offline_probing =>
      'A verificar resoluções disponíveis…';

  @override
  String get detail_page_delete_offline_confirm =>
      'Eliminar a cópia offline deste item?\n(A reprodução online não é afetada)';

  @override
  String get detail_page_offline_deleted => 'Dados offline eliminados';

  @override
  String get consent_page_title => 'Antes de começar';

  @override
  String get consent_page_subtitle =>
      'Por favor, lê e aceita o seguinte antes de usar a aplicação.';

  @override
  String get consent_page_privacy_title => 'Política de Privacidade';

  @override
  String get consent_page_privacy_body =>
      'Esta aplicação trata os dados pessoais com responsabilidade. Consulta a política completa abaixo.';

  @override
  String get consent_page_terms_title => 'Termos de Utilização';

  @override
  String get consent_page_terms_body =>
      'Lê os termos que regem o uso desta aplicação.';

  @override
  String get consent_page_ip_summary =>
      'Esta aplicação é uma ferramenta genérica para transferir e reproduzir offline os URLs que introduzires. És responsável por cumprir os direitos de autor e os termos do site de origem.';

  @override
  String get consent_page_agree_checkbox => 'Li e aceito todos os pontos acima';

  @override
  String get consent_page_agree => 'Aceitar e começar';

  @override
  String get consent_page_read_more => 'Ler texto completo';

  @override
  String get settings_page_ip_disclaimer =>
      'Isenção sobre propriedade intelectual';

  @override
  String get settings_page_ip_disclaimer_body =>
      'Esta aplicação é uma ferramenta de utilidade geral que oferece download e reprodução offline para URLs de vídeo inseridos pelo utilizador. Não está concebida para obter conteúdos de nenhum site específico.\n\nO utilizador é o único responsável por:\n・Cumprir os direitos de autor do conteúdo e os termos do site de origem\n・Não copiar, distribuir, publicar ou usar comercialmente o conteúdo guardado além do uso privado\n・Não infringir direitos de autor, de imagem ou outros de terceiros\n・Não contornar medidas técnicas de proteção do site de origem\n\nO fornecedor da aplicação não assume qualquer responsabilidade por infrações ou outras questões legais.\n\nEm caso de dúvida, absteste do uso e contacta o titular dos direitos. A aplicação funciona apenas com base nas entradas do utilizador e não implica qualquer parceria com serviços específicos.';

  @override
  String get detail_page_offline_not_direct_video =>
      'Este URL não é um link direto para um ficheiro de vídeo, por isso não pode ser guardado offline.\n(URLs de páginas como o YouTube não são suportados. Utilize um link direto para um ficheiro mp4/m4v/mov/webm/mkv.)';

  @override
  String get detail_page_offline_failed => 'Falha no download';

  @override
  String get download_failed_but_saved =>
      'URL adicionado aos favoritos (vídeo não transferido)';

  @override
  String get download_cancel_confirm_title => 'Cancelar esta transferência?';

  @override
  String get download_cancel_confirm_body =>
      'A transferência em curso será cancelada e esta tarefa removida. Continuar?';

  @override
  String get detail_page_offline_hls_not_supported =>
      'Este vídeo usa o formato HLS (.m3u8), que não é suportado para guardar offline.';

  @override
  String get browser_video_detected_chip => 'Vídeo detetado';

  @override
  String get browser_video_detected_sheet_title => 'Vídeos detetados';

  @override
  String get browser_video_detected_sheet_desc =>
      'Seleciona um vídeo para transferir.';

  @override
  String get browser_video_download => 'Transferir este vídeo';

  @override
  String get browser_video_download_started => 'Transferência iniciada';

  @override
  String get browser_video_download_saved_first =>
      'A página será guardada primeiro e depois começará a transferência';

  @override
  String get search_result_page_offline => 'Guardar offline';

  @override
  String get search_result_page_offline_desc =>
      'Transfira este item para reproduzir sem ligação.';

  @override
  String get download_queue_title => 'Transferências';

  @override
  String get download_clear_finished => 'Limpar concluídas';

  @override
  String get download_empty => 'Sem transferências ativas';

  @override
  String get download_status_queued => 'Em fila';

  @override
  String get download_status_completed => 'Concluído';

  @override
  String get download_status_failed => 'Falhou';

  @override
  String get download_cancel_all_confirm => 'Cancelar todas as transferências?';

  @override
  String get download_status_canceled => 'Cancelado';

  @override
  String get download_premium_required_title => 'Funcionalidade Premium';

  @override
  String get download_premium_required_body =>
      'As transferências offline estão disponíveis nos planos Premium e Pro.';

  @override
  String get detail_page_rate => 'Avaliação';

  @override
  String get detail_page_title => 'Título';

  @override
  String get detail_page_title_placeholder => 'Título';

  @override
  String get detail_page_cast_short => 'Elenco';

  @override
  String get detail_page_genre_short => 'Género';

  @override
  String get detail_page_series_short => 'Série';

  @override
  String get detail_page_maker_short => 'Produtora';

  @override
  String get detail_page_label_short => 'Editora';

  @override
  String get detail_page_cast => 'Elenco (# múltiplos)';

  @override
  String get detail_page_cast_placeholder => '#Elenco1 #Elenco2 ...';

  @override
  String get detail_page_genre => 'Género (# múltiplos)';

  @override
  String get detail_page_genre_placeholder => '#Género1 #Género2 ...';

  @override
  String get detail_page_series => 'Série (# múltiplos)';

  @override
  String get detail_page_series_placeholder => '#Série1 #Série2 ...';

  @override
  String get detail_page_label => 'Etiqueta (# múltiplas)';

  @override
  String get detail_page_label_placeholder => '#Etiqueta1 #Etiqueta2 ...';

  @override
  String get detail_page_maker => 'Produtor (# múltiplos)';

  @override
  String get detail_page_maker_placeholder => '#Produtor1 #Produtor2 ...';

  @override
  String get detail_page_paste_url => 'Colar URL';

  @override
  String get detail_page_fetch_title => 'Obter título do URL';

  @override
  String get detail_page_list => 'Lista';

  @override
  String get detail_page_memo => 'Nota';

  @override
  String get detail_page_fetch_title_fail => 'Título não encontrado.';

  @override
  String get detail_page_fetch_page_fail => 'Falha ao carregar a página.';

  @override
  String get detail_page_ex => 'Ocorreu um erro.';

  @override
  String get detail_page_delete_confirm01 => 'Eliminar este item?';

  @override
  String get detail_page_delete_confirm02 => 'Esta ação não pode ser desfeita.';

  @override
  String get detail_page_url_unable => 'URL inválido';

  @override
  String get detail_page_review_confirm01 => 'Está a gostar do ArchiVe?';

  @override
  String get detail_page_review_confirm02 => 'Uma avaliação ajudaria muito!';

  @override
  String get detail_page_review_contact_support => 'Reportar feedback ou erro';

  @override
  String get detail_page_review_later => 'Mais tarde';

  @override
  String get detail_page_review_now => 'Deixar avaliação';

  @override
  String get detail_page_mail_subject => 'subject=ArchiVe Feedback';

  @override
  String get detail_page_fetching_thumbnail => 'Obtendo miniatura...';

  @override
  String get search_page_cast => 'Elenco';

  @override
  String get search_page_genre => 'Género';

  @override
  String get search_page_series => 'Série';

  @override
  String get search_page_label => 'Etiqueta';

  @override
  String get search_page_maker => 'Produtor';

  @override
  String get search_page_search => 'Pesquisar';

  @override
  String get search_page_select_category => 'Selecionar categoria';

  @override
  String get search_page_more => 'Mostrar mais';

  @override
  String get search_page_fold => 'Mostrar menos';

  @override
  String get search_page_search_title => 'Pesquisar por título';

  @override
  String get search_page_premium_title => 'Selecionar várias etiquetas ★';

  @override
  String get search_page_premium_description =>
      'A pesquisa com várias categorias\nestá disponível apenas para utilizadores Premium.';

  @override
  String get search_page_segment_button_app => 'Na aplicação';

  @override
  String get search_page_segment_button_web => 'Web';

  @override
  String get search_page_text_empty => 'Introduza um termo de pesquisa';

  @override
  String get search_page_web_title => 'Pesquisa Web';

  @override
  String get search_page_search_word => 'Pesquisa web';

  @override
  String get search_page_hint_web_1 => 'Pesquise com bloqueador de anúncios';

  @override
  String get search_page_hint_web_2 => 'Ex.: anime OP';

  @override
  String get search_page_hint_web_3 => 'Recolha vídeos no navegador integrado';

  @override
  String get search_page_hint_web_4 => 'Ex.: ao vivo 2026';

  @override
  String get search_page_hint_web_5 => 'Aprofunde nos seus sites favoritos';

  @override
  String get search_page_hint_web_6 => 'Ex.: receitas fáceis';

  @override
  String get search_page_select_site => 'Sites favoritos';

  @override
  String get search_page_select_site_help_title => 'Filtrar por site';

  @override
  String get search_page_select_site_help_description =>
      'Pode restringir a pesquisa de vídeos a sites específicos. Registe os seus sites de vídeo favoritos e pesquise apenas dentro deles. Selecione um site na lista abaixo e toque em pesquisar.';

  @override
  String get search_page_open_site => 'Abrir site';

  @override
  String get search_page_modify_favorite => 'Editar favoritos';

  @override
  String get search_page_site_name => 'Nome do site';

  @override
  String get search_page_input_all => 'Preencha todos os campos';

  @override
  String get search_page_add_favorite => 'Adicionar site aos favoritos';

  @override
  String get search_page_random_loading => 'Escolhendo a recomendação de hoje…';

  @override
  String get search_page_random_this => 'Recomendação de hoje!';

  @override
  String get search_page_random_again => 'Girar de novo';

  @override
  String get search_result_page_site_saved => 'O site foi guardado';

  @override
  String get search_result_page_saving_as_item => 'Guardar item';

  @override
  String get search_result_page_saving_list => 'Lista de destino';

  @override
  String get search_result_page_url_already_saved => 'Este URL já foi guardado';

  @override
  String get search_result_page_url_already_saved_offline_prompt =>
      'Queres transferir este item para uso offline?';

  @override
  String get search_result_page_url_already_saved_and_downloaded =>
      'Este item já foi guardado e transferido';

  @override
  String get download_retry => 'Tentar novamente';

  @override
  String get player_minimize => 'Mudar para mini-leitor';

  @override
  String get player_close => 'Fechar';

  @override
  String get player_speed => 'Velocidade de reprodução';

  @override
  String player_speed_x(String v) {
    return '${v}x';
  }

  @override
  String get player_speed_custom => 'Personalizado';

  @override
  String get player_bookmarks => 'Marcadores';

  @override
  String get player_bookmarks_empty => 'Ainda não há marcadores';

  @override
  String get browser_video_size => 'Tamanho';

  @override
  String get browser_video_size_unknown => 'Tamanho desconhecido';

  @override
  String get browser_video_quality => 'Qualidade';

  @override
  String get browser_tab_max_reached =>
      'Limite de separadores atingido. Fecha um antes de abrir um novo.';

  @override
  String get browser_tabs_title => 'Separadores';

  @override
  String get browser_new_tab => 'Novo separador';

  @override
  String get offline_quality_title => 'Qualidade offline';

  @override
  String get offline_quality_desc =>
      'Escolhe a qualidade do vídeo a transferir';

  @override
  String get offline_quality_none => 'Sem transferência offline';

  @override
  String get search_result_page_has_saved => 'O item foi guardado';

  @override
  String search_result_page_delete_site(Object siteName) {
    return 'Remover \"$siteName\" dos favoritos?';
  }

  @override
  String get search_result_page_new_list => 'Nova lista';

  @override
  String get search_result_page_input_list_name => 'Introduzir nome da lista';

  @override
  String get search_result_page_list_already_exists =>
      'Já existe uma lista com este nome';

  @override
  String get search_result_page_history => 'Histórico';

  @override
  String get search_result_page_ad_remainder01 =>
      'Um anúncio será exibido após a próxima gravação';

  @override
  String get search_result_page_ad_remainder02 => 'Mostrar anúncio';

  @override
  String get analytics => 'Análises';

  @override
  String get analytics_page_summary => 'Resumo';

  @override
  String analytics_page_item_count(Object totalWorks) {
    return 'Itens guardados: $totalWorks';
  }

  @override
  String get analytics_page_recent_additions =>
      'Itens adicionados recentemente';

  @override
  String analytics_page_piechart_others(Object percent) {
    return 'Outros\n$percent%';
  }

  @override
  String get analytics_page_view_count_top5 => 'Top 5 Visualizações';

  @override
  String get analytics_page_no_view_records_title =>
      'Ainda sem registos de visualização';

  @override
  String get analytics_page_no_view_records_hint =>
      'As visualizações registadas nos detalhes serão apresentadas aqui';

  @override
  String get analytics_page_no_data => 'Sem dados disponíveis';

  @override
  String get analytics_page_evaluation => 'Avaliação';

  @override
  String get analytics_page_cast => 'Elenco';

  @override
  String get analytics_page_genre => 'Género';

  @override
  String get analytics_page_series => 'Série';

  @override
  String get analytics_page_label => 'Etiqueta';

  @override
  String get analytics_page_maker => 'Produtor';

  @override
  String get analytics_page_premium_title => 'Análises ★';

  @override
  String get analytics_page_premium_description =>
      'As funcionalidades de análise estão disponíveis no ArchiVe Premium.\nAtualize para as utilizar.';

  @override
  String get analytics_page_premium_button => 'Ver detalhes Premium';

  @override
  String analytics_page_list_value(Object entry, Object percent) {
    return '$percent% ($entry itens)';
  }

  @override
  String get analytics_page_count => '(visualizações)';

  @override
  String analytics_page_toolchip_count(Object rod) {
    return '$rod visualizações';
  }

  @override
  String get analytics_page_no_title => 'Sem título';

  @override
  String get analytics_page_item_count_top5 => 'Top 5 Quantidade de Itens';

  @override
  String get analytics_page_kpi_saved_count => 'Salvos';

  @override
  String get analytics_page_kpi_total_view_count => 'Total de visualizações';

  @override
  String get analytics_page_kpi_rating_rate => 'Taxa de avaliação';

  @override
  String get analytics_page_most_watched => 'Mais assistido';

  @override
  String analytics_page_view_times(Object count) {
    return 'Assistido $count vezes';
  }

  @override
  String analytics_page_total_view_subtitle(Object count) {
    return 'Total de visualizações: $count';
  }

  @override
  String analytics_page_rated_subtitle(Object ratedCount, Object total) {
    return 'Avaliados $ratedCount / $total';
  }

  @override
  String get analytics_page_unit_items => 'itens';

  @override
  String analytics_page_ranked_row_stat(Object count, Object percent) {
    return '$percent%  $count itens';
  }

  @override
  String analytics_page_times_unit(Object count) {
    return '$count visualizações';
  }

  @override
  String get analytics_page_view_count_by_rating =>
      'Visualizações por avaliação';

  @override
  String get analytics_page_saved_by_list => 'Guardados por lista';

  @override
  String analytics_page_list_count_subtitle(Object count) {
    return '$count listas';
  }

  @override
  String analytics_page_type_count_subtitle(Object count) {
    return '$count tipos';
  }

  @override
  String get settings => 'Definições';

  @override
  String get settings_page_dark_mode => 'Modo escuro';

  @override
  String get settings_page_theme_color => 'Cor do tema';

  @override
  String get settings_page_theme_color_orange => 'Laranja';

  @override
  String get settings_page_theme_color_random => 'Aleatório';

  @override
  String get settings_page_theme_color_green => 'Verde';

  @override
  String get settings_page_theme_color_blue => 'Azul';

  @override
  String get settings_page_theme_color_white => 'Branco';

  @override
  String get settings_page_theme_color_red => 'Vermelho';

  @override
  String get settings_page_theme_color_yellow => 'Amarelo';

  @override
  String get settings_page_thumbnail_visibility =>
      'Mostrar miniaturas nas listas';

  @override
  String get settings_page_save_status => 'Itens';

  @override
  String get settings_page_offline_videos => 'Vídeos offline';

  @override
  String get settings_page_offline_total_size => 'Tamanho total offline';

  @override
  String get settings_page_save_count => 'Marcadores';

  @override
  String get settings_page_watch_count => 'Visualizações de hoje';

  @override
  String settings_page_watch_ad_today(Object watchedAdsToday) {
    return '$watchedAdsToday / 5';
  }

  @override
  String get settings_page_watch_ad => 'Ver anúncio (+1 espaço)';

  @override
  String get settings_page_ad_limit_reached =>
      'Limite diário de anúncios atingido';

  @override
  String get settings_page_already_purchased => 'Já adquirido.';

  @override
  String get settings_page_premium => 'ArchiVe Premium';

  @override
  String get settings_page_app_version => 'Versão da aplicação';

  @override
  String get settings_page_plivacy_policy => 'Política de Privacidade';

  @override
  String get settings_page_disable_link => 'Não foi possível abrir o link';

  @override
  String get settings_page_terms => 'Termos de Serviço (Apple Standard EULA)';

  @override
  String get settings_page_save_count_increased =>
      'Limite de armazenamento aumentado em +1';

  @override
  String get setting_page_unlimited => 'Ilimitado';

  @override
  String view_counter_view_count(Object viewCount) {
    return 'Visualizações $viewCount';
  }

  @override
  String get random_image_no_image => 'Não foi possível carregar a imagem';

  @override
  String get random_image_change_list_name => 'Alterar nome da lista';

  @override
  String get random_image_change_list_name_dialog => 'Alterar nome da lista';

  @override
  String get random_image_change_list_name_hint => 'Introduzir nome da lista';

  @override
  String get random_image_change_list_name_confirm => 'Alterar';

  @override
  String get random_image_delete_list => 'Eliminar lista';

  @override
  String get random_image_delete_list_dialog => 'Eliminar esta lista?';

  @override
  String get random_image_delete_list_dialog_description =>
      'Os itens desta lista também serão eliminados.';

  @override
  String get random_image_delete_list_confirm => 'Eliminar';

  @override
  String get premium_detail_premium_title => 'ArchiVe Premium';

  @override
  String get premium_detail_premium_item01 => 'Guardados ilimitados';

  @override
  String get premium_detail_premium_item02 => 'Adicionar cor de tema Dourado';

  @override
  String get premium_detail_premium_item03 => 'Adicione imagens livremente';

  @override
  String get premium_detail_premium_item04 => 'Busca rápida com várias tags';

  @override
  String get premium_detail_premium_item05 =>
      'Estatísticas para visualizar dados por gênero e avaliação';

  @override
  String get premium_detail_premium_item06 => 'Remover anúncios';

  @override
  String get premium_detail_note =>
      'Após o teste grátis de 3 dias, a subscrição renovar-se-á automaticamente.\nCancele a qualquer momento.';

  @override
  String get premium_detail_restore_not_found =>
      'Nenhum histórico de compra encontrado';

  @override
  String get premium_detail_free_trial_badge => '3 dias grátis';

  @override
  String get premium_detail_start_trial => 'Iniciar teste grátis de 3 dias';

  @override
  String premium_detail_price_after_trial(Object price) {
    return 'Depois $price / mês';
  }

  @override
  String get premium_detail_restore_button => 'Restaurar compras';

  @override
  String get premium_detail_purchase_complete =>
      'Premium adquirido com sucesso!';

  @override
  String get premium_detail_restart_message =>
      'As funcionalidades Premium foram ativadas.\nA aplicação será reiniciada.';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get tutorial_01 => 'Primeiro, vamos criar uma lista.';

  @override
  String get tutorial_02 => 'Abra a lista que acabou de criar.';

  @override
  String get tutorial_03 => 'Toque no botão + para adicionar um item.';

  @override
  String get tutorial_04 => 'Introduza o URL do vídeo ou conteúdo.';

  @override
  String get tutorial_05 =>
      'Toque neste botão para obter automaticamente o título.';

  @override
  String get tutorial_06 => 'Por fim, guarde para adicioná-lo à lista.';

  @override
  String get start_tutorial_dialog => 'Reiniciar o tutorial?';

  @override
  String get start_tutorial_dialog_description =>
      'Isto mostrará novamente os passos desde a criação da lista.';

  @override
  String get completed_tutorial => 'Tutorial concluído!\nExcelente trabalho!';

  @override
  String get tutorial_list_name => 'Ver mais tarde';

  @override
  String get tutorial_slide_title_01 =>
      'Um Gestor de Vídeos\nSem Necessidade de Download';

  @override
  String get tutorial_slide_dict_01 =>
      'Guarde vídeos ilimitados sem usar armazenamento';

  @override
  String get tutorial_slide_image_01 => 'assets/tutorial/english01.png';

  @override
  String get tutorial_slide_title_02 => '[2 Passos Simples]\n1. Copiar o URL';

  @override
  String get tutorial_slide_dict_02 =>
      'Copie o link de partilha ou o URL do navegador de qualquer site de vídeo';

  @override
  String get tutorial_slide_image_02 => 'assets/tutorial/english02.png';

  @override
  String get tutorial_slide_title_03 => '[2 Passos Simples]\n2. Guardar o URL';

  @override
  String get tutorial_slide_dict_03 =>
      'Basta colar para guardar\nAdicione avaliações, etiquetas e notas';

  @override
  String get tutorial_slide_image_03 => 'assets/tutorial/english03.png';

  @override
  String get tutorial_slide_title_04 => 'Pesquisar na Aplicação';

  @override
  String get tutorial_slide_dict_04 =>
      'Encontre vídeos guardados instantaneamente por título ou etiquetas';

  @override
  String get tutorial_slide_image_04 => 'assets/tutorial/english04.png';

  @override
  String get tutorial_slide_title_05 => 'Pesquisa Web';

  @override
  String get tutorial_slide_dict_05 =>
      'Navegue e guarde vídeos instantaneamente com o navegador integrado';

  @override
  String get tutorial_slide_image_05 => 'assets/tutorial/english05.png';

  @override
  String get tutorial_slide_title_06 => 'Possibilidades Ilimitadas';

  @override
  String get tutorial_slide_dict_06 =>
      'Construa a sua coleção pessoal de vídeos!';

  @override
  String get tutorial_slide_image_06 => 'assets/tutorial/english06.png';

  @override
  String get tutorial_slide_next => 'Seguinte';

  @override
  String get tutorial_slide_start => 'Começar';

  @override
  String get share_saved => 'Guardado a partir da partilha';

  @override
  String get share_already_saved => 'Este URL já foi guardado';

  @override
  String get share_dialog_title => 'Guardar no ArchiVe';

  @override
  String get share_list_section => 'Lista';

  @override
  String get share_title_hint => 'Introduzir título';

  @override
  String get clipboard_dialog_title =>
      'Adicionar URL da área de transferência?';

  @override
  String get ranking_page_add_item => 'Adicionar item';

  @override
  String get search_page_url_cant_open => 'Não é possível abrir este URL';

  @override
  String get premium_detail_plan_monthly => 'Mensal';

  @override
  String get premium_detail_plan_annual => 'Anual';

  @override
  String get premium_detail_best_value => 'MELHOR VALOR';

  @override
  String premium_detail_save_percent(String percent) {
    return 'Poupe $percent%';
  }

  @override
  String get premium_detail_per_month => '/ mês';

  @override
  String get premium_detail_per_year => '/ ano';

  @override
  String premium_detail_price_after_trial_yearly(String price) {
    return 'Depois $price / ano';
  }

  @override
  String get settings_page_free_plan => 'Plano Gratuito';

  @override
  String get settings_page_current_plan => 'Plano Atual';

  @override
  String get settings_page_premium_details_link =>
      'Desbloqueie o limite de guardados e veja mais detalhes';

  @override
  String get settings_page_section_appearance => 'Aparência';

  @override
  String get settings_page_section_about => 'Sobre o app';

  @override
  String get settings_page_section_legal => 'Informações legais';

  @override
  String get settings_page_period_monthly => 'Mensal';

  @override
  String get settings_page_period_annual => 'Anual';

  @override
  String get settings_page_theme_color_pink => 'Rosa';

  @override
  String get settings_page_theme_color_purple => 'Roxo';

  @override
  String get settings_page_theme_color_teal => 'Verde-azulado';

  @override
  String get login_page_title => 'Iniciar sessão';

  @override
  String get login_page_description =>
      'Inicie sessão para usar as funcionalidades ArchiVe Pro.';

  @override
  String get login_with_apple => 'Iniciar sessão com Apple';

  @override
  String get login_with_google => 'Iniciar sessão com Google';

  @override
  String get login_failed => 'Falha ao iniciar sessão';

  @override
  String get logout => 'Terminar sessão';

  @override
  String get logout_confirm => 'Terminar sessão?';

  @override
  String get settings_page_section_account => 'Conta';

  @override
  String get settings_page_not_signed_in => 'Sem sessão iniciada';

  @override
  String get pro_detail_title => 'ArchiVe Pro';

  @override
  String get pro_detail_subtitle =>
      'Todas as funcionalidades Premium além das seguintes';

  @override
  String get pro_detail_feature_cloud_sync =>
      'Sincronização na nuvem (vários dispositivos)';

  @override
  String get pro_detail_feature_ai_tagging => 'Etiquetagem automática IA';

  @override
  String get pro_detail_feature_ai_recommend =>
      'Palavras-chave recomendadas por IA';

  @override
  String get pro_detail_feature_monthly_report => 'Relatório mensal IA';

  @override
  String get pro_detail_feature_public_sharing => 'Partilha de listas públicas';

  @override
  String get pro_detail_feature_theme_teal =>
      'Adicionar cor de tema Verde-azulado';

  @override
  String get plans_page_title => 'Planos';

  @override
  String get plans_page_current_badge => 'Atual';

  @override
  String get plans_page_includes_premium =>
      'Inclui todas as funcionalidades Premium';

  @override
  String get detail_page_ai_suggest => 'Sugerir etiquetas com IA';

  @override
  String get detail_page_ai_suggest_dialog_title => 'Sugestões de etiquetas IA';

  @override
  String get detail_page_ai_suggest_dialog_hint =>
      'Aqui estão as etiquetas recomendadas! Selecione as que deseja aplicar.';

  @override
  String get detail_page_ai_apply => 'Aplicar';

  @override
  String get detail_page_ai_no_suggestions => 'Sem sugestões';

  @override
  String get detail_page_ai_from_library => 'A partir das etiquetas existentes';

  @override
  String get detail_page_ai_daily_limit_title => 'Limite diário de IA atingido';

  @override
  String get detail_page_ai_daily_limit_body =>
      'As sugestões de etiquetas IA estão disponíveis 1 vez por dia nos planos Gratuito / Premium.\nAtualize para Pro para uso ilimitado.';

  @override
  String get detail_page_ai_upgrade_pro => 'Ver plano Pro';

  @override
  String get detail_page_ai_loading => 'Analisando com IA...';

  @override
  String get detail_page_ai_error => 'Erro de sugestão IA';

  @override
  String get share_title => 'Partilhar lista';

  @override
  String get share_loading => 'A partilhar...';

  @override
  String get share_url_label => 'URL de partilha';

  @override
  String get share_copy => 'Copiar';

  @override
  String get share_copied => 'Copiado';

  @override
  String get share_unshare => 'Parar de partilhar';

  @override
  String get share_unshare_confirm => 'Parar de partilhar esta lista?';

  @override
  String get share_create_action => 'Partilhar esta lista';

  @override
  String get share_error => 'Erro de partilha';

  @override
  String get share_open_url => 'Abrir URL de partilha';

  @override
  String get share_description =>
      'Qualquer pessoa com o URL pode ver esta lista (apenas leitura)';

  @override
  String get share_limit_notice => 'Até 200 itens serão partilhados';

  @override
  String get analytics_monthly_report_title => 'Resumo IA';

  @override
  String analytics_monthly_report_subtitle(int month) {
    return 'Resumo do mês $month';
  }

  @override
  String get analytics_monthly_report_generate => 'Gerar resumo';

  @override
  String get analytics_monthly_report_regenerate => 'Regenerar';

  @override
  String get analytics_monthly_report_loading => 'IA a analisar...';

  @override
  String get analytics_monthly_report_empty =>
      'Toque para a IA resumir a sua atividade de arquivo deste mês.';

  @override
  String get analytics_monthly_report_error => 'Erro de relatório';

  @override
  String get analytics_monthly_report_cached => 'Da cache';

  @override
  String get search_result_loading => 'A carregar';

  @override
  String get grid_page_move_action => 'Mover';

  @override
  String get grid_page_move_to_list_title => 'Selecionar lista de destino';

  @override
  String get grid_page_move_done => 'itens movidos';

  @override
  String get undo => 'Desfazer';

  @override
  String get settings_page_theme_color_gold => 'Dourado';

  @override
  String get plans_page_premium_short => 'Premium';

  @override
  String get plans_page_pro_short => 'Pro';

  @override
  String get plans_page_free_short => 'Grátis';

  @override
  String get plans_page_free_price => 'R\$0';

  @override
  String get plans_page_free_item01 => 'Guardar até 100 itens';

  @override
  String get plans_page_free_item02 => 'Ver anúncios: +15 vagas/dia';

  @override
  String get plans_page_free_item03 => 'Pesquisa por etiqueta única';

  @override
  String get plans_page_free_item04 => 'Com anúncios';

  @override
  String get share_pro_required_title => 'Recurso do plano Pro';

  @override
  String get share_pro_required_description =>
      'A partilha pública de listas requer a compra do plano Pro.';

  @override
  String get share_pro_required_action => 'Ver plano Pro';

  @override
  String get pro_locked_badge => 'Apenas Pro';

  @override
  String get pro_locked_unlock => 'Desbloquear com Pro';

  @override
  String get apple_signin_warning_title => 'Iniciar sessão com a Apple?';

  @override
  String get apple_signin_warning_description =>
      'As contas Apple não podem ser usadas no Android, por isso os dados não serão partilhados entre plataformas. Recomendamos a Google se vai usar vários dispositivos.';

  @override
  String get apple_signin_warning_continue => 'Continuar com a Apple';

  @override
  String get settings_page_manage_subscription => 'Gerir subscrição';

  @override
  String get search_page_ai_recommend_title => 'Sugestões da IA';

  @override
  String get search_page_ai_recommend_subtitle =>
      'Ideias com base na sua biblioteca';

  @override
  String get search_page_ai_recommend_generate => 'Obter sugestões';

  @override
  String get search_page_ai_recommend_refresh => 'Regenerar';

  @override
  String get search_page_ai_recommend_loading => 'A IA está a analisar...';

  @override
  String get search_page_ai_recommend_error => 'Falha ao obter sugestões';

  @override
  String get search_page_ai_recommend_empty =>
      'Itens guardados insuficientes para sugerir. Adicione mais e tente novamente.';

  @override
  String get search_page_ai_recommend_intro =>
      'Toque no botão para a IA sugerir palavras-chave relacionadas com a sua biblioteca.';
}
