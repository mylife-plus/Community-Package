import 'community_localizations.dart';

/// Portuguese as written in Portugal, like the host apps' own labels.
class CommunityLocalizationsPt extends CommunityLocalizations {
  const CommunityLocalizationsPt()
    : super(
        feedbackTitle: 'Feedback',
        back: 'Voltar',
        statusPlanned: 'planeado',
        statusInProgress: 'em curso',
        statusDone: 'concluído',
        justNow: 'agora mesmo',
        minutesAgo: _minutesAgo,
        hoursAgo: _hoursAgo,
        daysAgo: _daysAgo,
        monthsAgo: _monthsAgo,
        yearsAgo: _yearsAgo,
        costUsd: _costUsd,
        commentCount: _commentCount,
        reactionCount: _reactionCount,
        emptyFeedbackTitle: 'Ainda sem feedback',
        emptyFeedbackBody: 'As ideias, melhorias e problemas da comunidade vão aparecer aqui.',
        errorOffline: 'Sem ligação à internet. Verifique a sua ligação e tente novamente.',
        errorNetwork: 'A ligação foi interrompida. Tente novamente.',
        errorServer: 'Algo correu mal do nosso lado. Tente novamente mais tarde.',
        errorGeneric: 'Algo correu mal. Tente novamente.',
        retry: 'Tentar novamente',
        loadMoreFailed: 'Não foi possível carregar mais feedback.',
        communityTitle: 'App da Comunidade',
        communityIntro:
            'Esta app é um projeto 100% open source e feito pela comunidade. '
            'Tentamos ser o mais transparentes possível em tudo o que acontece.',
        allFeedback: 'todo o Feedback',
        privacyNotice: 'Aviso de Privacidade',
        privacyIntro:
            'Quando envia o seu primeiro feedback, geramos um identificador único (UUID), '
            'guardado de forma segura no seu dispositivo.',
        privacyWhyTitle: 'Porque o fazemos:',
        privacyWhyBody:
            'Para associar o seu feedback e comentários a si, para que possa identificar e gerir '
            'as suas próprias publicações. (Fundamento jurídico: interesse legítimo – '
            'art. 6.º, n.º 1, alínea f), do RGPD)',
        privacyWhatTitle: 'O que pode fazer:',
        privacyUnlink:
            'Desassociar – Remove o seu UUID de todo o seu feedback e comentários. O conteúdo é '
            'mantido, mas deixa de poder ser associado a si.',
        privacyDelete:
            "Apagar – Remove o seu feedback por completo. Exceção: o feedback marcado com '💪' "
            'pela nossa equipa não pode ser apagado.',
        privacyRetentionTitle: 'Conservação:',
        privacyRetentionBody:
            'O seu UUID mantém-se no seu dispositivo, mesmo que reinstale a app. O feedback é '
            "conservado até o apagar ou desassociar. O feedback marcado com '💪' é conservado "
            'permanentemente.',
        privacyRightsTitle: 'Os seus direitos:',
        privacyRightsBody:
            'Pode, a qualquer momento, aceder aos seus dados, retificá-los, limitar o seu '
            'tratamento ou opor-se a ele. Pode também apresentar uma reclamação à sua autoridade '
            'local de proteção de dados.',
        privacyPolicyBefore: 'Leia a nossa ',
        privacyPolicyLink: 'Política de Privacidade',
        privacyPolicyAfter: ' completa para mais detalhes.',
        yourId: _yourId,
        agree: 'aceitar',
        decline: 'recusar',
        close: 'fechar',
        rulesTitle: 'Evite',
        ruleNoPrivateInfo: 'Partilhar informações privadas',
        ruleNoUnrelated: 'Publicar conteúdo sem relação com a app',
        ruleNoHate: 'Assediar ou usar discurso de ódio',
        rulesWarning: 'As infrações podem levar à remoção do feedback ou a restrições da conta.',
        rulesThanks: 'Obrigado',
        errorStorage: 'Não foi possível guardar neste dispositivo. Tente novamente.',
        linkFailed: 'Não foi possível abrir a ligação.',
        newFeedbackTitle: 'novo Feedback',
        chooseTopic: 'Escolher tema',
        typeImprovement: 'Melhoria',
        typeProblem: 'Problema',
        typeIdea: 'Ideia',
        topicHint: 'A sua ideia de melhoria...',
        improvementPrompt: 'O que quer melhorar?',
        ideaPrompt: 'Qual é a sua ideia?',
        agreeToRules: 'aceitar as Regras',
        rulesLink: 'Regras',
        cancel: 'cancelar',
        submit: 'enviar',
        discardTitle: 'Descartar este feedback?',
        discard: 'descartar',
        keepEditing: 'continuar a editar',
        postedAs: _postedAs,
        errorRateLimited: 'Demasiadas publicações. Tente novamente daqui a pouco.',
        selectScreen: 'escolher um ecrã',
        stepHint: 'Passo para reproduzir o problema',
        problemDescriptionHint: 'O que correu mal?',
        deviceOs: 'SO',
        deviceApp: 'App',
        devicePhone: 'Telefone',
        appVersionShort: _appVersionShort,
        sortTooltip: 'Ordenar',
        filterTooltip: 'Filtrar',
        searchTooltip: 'Pesquisar',
        closeSearch: 'Fechar pesquisa',
        sortNewest: 'Mais novo',
        sortOldest: 'Mais antigo',
        sortReactions: 'Mais corações',
        sortComments: 'Mais comentários',
        filterType: 'Tipo',
        filterProgress: 'Progresso',
        resetFilter: 'repor',
        searchHint: 'Pesquisar feedback',
        noMatchesTitle: 'Nada encontrado',
        noMatchesBody: 'Experimente outras palavras ou filtros.',
        clearSearchAndFilter: 'limpar',
        addHeart: 'Dar um coração',
        removeHeart: 'Retirar o seu coração',
        errorTooManyHearts: 'Demasiados corações. Tente novamente daqui a pouco.',
        sortReplies: 'Mais respostas',
        filterMine: 'Meus',
        filterAdmin: 'Admin',
        searchCommentsHint: 'Pesquisar comentários',
        feedbackNotFound: 'Este feedback já não existe.',
        newCommentHint: 'novo Comentário...',
        writeComment: 'Escrever um comentário',
        sendComment: 'Enviar',
        noCommentsTitle: 'Ainda sem comentários',
        noCommentsBody: 'Seja o primeiro a comentar.',
        commentDeleted: 'Comentário apagado',
        edited: 'editado',
        showReplies: _showReplies,
        hideReplies: 'Ocultar respostas',
        reply: 'Responder',
        editComment: 'Editar comentário',
        editCommentTitle: 'editar Comentário',
        save: 'guardar',
        delete: 'apagar',
        keep: 'manter',
        deleteCommentTitle: 'Apagar este comentário?',
        deleteCommentKeepsReplies: 'Apagar este comentário? As respostas mantêm-se.',
        commentNotFound: 'Este comentário já não existe.',
        errorTooManyComments: 'Demasiados comentários. Tente novamente daqui a pouco.',
        offlineShowingSaved: 'Sem ligação. A mostrar feedback guardado.',
        loadMoreCommentsFailed: 'Não foi possível carregar mais comentários.',
        screenCommunity: 'Comunidade',
        screenAllFeedback: 'Todo o feedback',
        screenFeedbackDetail: 'Detalhe do feedback',
        screenNewFeedback: 'Novo feedback',
      );

  static String _minutesAgo(int n) => 'há $n min';
  static String _hoursAgo(int n) => 'há $n h';
  static String _daysAgo(int n) => 'há $n d';
  static String _monthsAgo(int n) => n == 1 ? 'há 1 mês' : 'há $n meses';
  static String _yearsAgo(int n) => n == 1 ? 'há 1 ano' : 'há $n anos';
  static String _costUsd(String amount) => '${amount.replaceAll('.', ',')} \$';
  static String _commentCount(int n) => n == 1 ? '1 comentário' : '$n comentários';
  static String _reactionCount(int n) => n == 1 ? '1 coração' : '$n corações';
  static String _yourId(String id) => 'O seu ID: $id';
  static String _postedAs(int n) => 'Obrigado! Publicado como #$n';
  static String _appVersionShort(String version) => 'App $version';
  static String _showReplies(int n) => n == 1 ? 'Mostrar 1 resposta' : 'Mostrar $n respostas';
}
