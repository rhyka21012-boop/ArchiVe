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
  String get main_page_search => 'Pesquisar & Guardar';

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
  String get detail_page_save => 'Guardar';

  @override
  String get detail_page_thumbnail_placeholder =>
      'A miniatura aparecerá após guardar';

  @override
  String get detail_page_add_image => 'Adicionar imagem ★';

  @override
  String get detail_page_rate => 'Avaliação';

  @override
  String get detail_page_title => 'Título';

  @override
  String get detail_page_title_placeholder => 'Título';

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
  String get detail_page_review_confirm01 =>
      'Está a gostar de \"ArchiVe - Favorite Video Tracker\"?';

  @override
  String get detail_page_review_confirm02 =>
      'Obrigado por utilizar a nossa aplicação.\n\nO seu feedback será cuidadosamente analisado pelo programador e usado para melhorar futuras atualizações.\n\nSe estiver a gostar da aplicação, agradecemos muito a sua avaliação.';

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
  String get search_page_search_word => 'Termo de pesquisa';

  @override
  String get search_page_select_site => 'Filtrar por site';

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
  String get search_result_page_site_saved => 'O site foi guardado';

  @override
  String get search_result_page_saving_as_item => 'Guardar item';

  @override
  String get search_result_page_saving_list => 'Lista de destino';

  @override
  String get search_result_page_url_already_saved => 'Este URL já foi guardado';

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
      'Um anúncio será exibido após o próximo salvamento';

  @override
  String get search_result_page_ad_remainder02 => 'Exibir anúncio';

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
  String get settings => 'Definições';

  @override
  String get settings_page_dark_mode => 'Modo escuro';

  @override
  String get settings_page_theme_color => 'Cor do tema ★';

  @override
  String get settings_page_theme_color_orange => 'Laranja';

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
  String get settings_page_save_status => 'Estado de armazenamento';

  @override
  String get settings_page_save_count => 'Itens guardados';

  @override
  String get settings_page_watch_count => 'Visualizações de hoje';

  @override
  String settings_page_watch_ad_today(Object watchedAdsToday) {
    return '$watchedAdsToday / 3';
  }

  @override
  String get settings_page_watch_ad => 'Ver anúncio (+5 espaços)';

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
      'Limite de armazenamento aumentado em +5';

  @override
  String get setting_page_unlimited => 'Ilimitado';

  @override
  String view_counter_view_count(Object viewCount) {
    return 'Visualizações: $viewCount';
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
  String get premium_detail_premium_item01 => 'Salvamentos ilimitados';

  @override
  String get premium_detail_premium_item02 => 'Personalize as cores do tema';

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
      'Após o teste gratuito de 1 mês, a assinatura será renovada automaticamente.\nCancele a qualquer momento.';

  @override
  String get premium_detail_restore_not_found =>
      'Nenhum histórico de compra encontrado';

  @override
  String get premium_detail_free_trial_badge => '1 mês grátis';

  @override
  String get premium_detail_start_trial => 'Iniciar teste gratuito de 1 mês';

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
      'Os recursos Premium foram ativados.\nO aplicativo será reiniciado.';

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
  String get share_saved => 'Salvo do compartilhamento';

  @override
  String get share_already_saved => 'Este URL já está salvo';
}
