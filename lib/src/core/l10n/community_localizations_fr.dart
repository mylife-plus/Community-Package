import 'community_localizations.dart';

class CommunityLocalizationsFr extends CommunityLocalizations {
  const CommunityLocalizationsFr()
    : super(
        feedbackTitle: 'Feedback',
        back: 'Retour',
        statusPlanned: 'prévu',
        statusInProgress: 'en cours',
        statusDone: 'terminé',
        justNow: "à l'instant",
        minutesAgo: _minutesAgo,
        hoursAgo: _hoursAgo,
        daysAgo: _daysAgo,
        monthsAgo: _monthsAgo,
        yearsAgo: _yearsAgo,
        costUsd: _costUsd,
        commentCount: _commentCount,
        reactionCount: _reactionCount,
        emptyFeedbackTitle: 'Aucun feedback pour le moment',
        emptyFeedbackBody:
            'Les idées, améliorations et problèmes de la communauté apparaîtront ici.',
        errorOffline: 'Pas de connexion internet. Vérifiez votre connexion et réessayez.',
        errorNetwork: 'La connexion a été interrompue. Veuillez réessayer.',
        errorServer: 'Un problème est survenu de notre côté. Veuillez réessayer plus tard.',
        errorGeneric: 'Un problème est survenu. Veuillez réessayer.',
        retry: 'Réessayer',
        loadMoreFailed: "Impossible de charger plus de feedback.",
        communityTitle: 'App Communautaire',
        communityIntro:
            'Cette app est un projet 100 % open source, porté par la communauté. '
            'Nous essayons d’être aussi transparents que possible sur tout ce qui se passe.',
        allFeedback: 'tout le Feedback',
        privacyNotice: 'Avis de confidentialité',
        privacyIntro:
            'Lorsque vous envoyez votre premier feedback, nous générons un identifiant unique '
            '(UUID), stocké de façon sécurisée sur votre appareil.',
        privacyWhyTitle: 'Pourquoi\u00A0:',
        privacyWhyBody:
            'Pour relier vos feedbacks et commentaires à vous, afin que vous puissiez retrouver et '
            'gérer vos propres contributions. (Base légale\u00A0: intérêt légitime – art. 6, '
            'paragraphe 1, point f) du RGPD)',
        privacyWhatTitle: 'Ce que vous pouvez faire\u00A0:',
        privacyUnlink:
            'Dissocier – Retire votre UUID de tous vos feedbacks et commentaires. Le contenu est '
            'conservé, mais ne peut plus être relié à vous.',
        privacyDelete:
            "Supprimer – Supprime entièrement votre feedback. Exception\u00A0: un feedback marqué "
            "'💪' par notre équipe ne peut pas être supprimé.",
        privacyRetentionTitle: 'Conservation\u00A0:',
        privacyRetentionBody:
            'Votre UUID reste sur votre appareil, même après une réinstallation de l’app. Le '
            'feedback est conservé jusqu’à ce que vous le supprimiez ou le dissociiez. Un '
            "feedback marqué '💪' est conservé définitivement.",
        privacyRightsTitle: 'Vos droits\u00A0:',
        privacyRightsBody:
            'Vous pouvez à tout moment accéder à vos données, les rectifier, en limiter le '
            'traitement ou vous y opposer. Vous pouvez aussi déposer une plainte auprès de votre '
            'autorité locale de protection des données.',
        privacyPolicyBefore: 'Consultez notre ',
        privacyPolicyLink: 'Politique de confidentialité',
        privacyPolicyAfter: ' complète pour plus de détails.',
        yourId: _yourId,
        agree: 'accepter',
        decline: 'refuser',
        close: 'fermer',
        rulesTitle: 'À éviter',
        ruleNoPrivateInfo: 'Partager des informations privées',
        ruleNoUnrelated: 'Publier du contenu hors sujet',
        ruleNoHate: 'Harceler ou tenir des propos haineux',
        rulesWarning:
            'Tout manquement peut entraîner la suppression du feedback ou des restrictions du compte.',
        rulesThanks: 'Merci',
        errorStorage: "Impossible d'enregistrer sur cet appareil. Veuillez réessayer.",
        linkFailed: "Impossible d'ouvrir le lien.",
        newFeedbackTitle: 'nouveau Feedback',
        chooseTopic: 'Choisir un sujet',
        typeImprovement: 'Amélioration',
        typeProblem: 'Problème',
        typeIdea: 'Idée',
        topicHint: "Votre idée d'amélioration...",
        improvementPrompt: 'Que voulez-vous améliorer\u00A0?',
        ideaPrompt: 'Quelle est votre idée\u00A0?',
        agreeToRules: 'accepter les Règles',
        rulesLink: 'Règles',
        cancel: 'annuler',
        submit: 'envoyer',
        discardTitle: 'Abandonner ce feedback\u00A0?',
        discard: 'abandonner',
        keepEditing: 'continuer',
        postedAs: _postedAs,
        errorRateLimited: 'Trop de publications. Réessayez dans un instant.',
        selectScreen: 'choisir un écran',
        stepHint: 'Étape pour reproduire le problème',
        problemDescriptionHint: "Qu'est-ce qui n'a pas marché ?",
        deviceOs: 'OS',
        deviceApp: 'App',
        devicePhone: 'Téléphone',
        appVersionShort: _appVersionShort,
        sortTooltip: 'Trier',
        filterTooltip: 'Filtrer',
        searchTooltip: 'Rechercher',
        closeSearch: 'Fermer la recherche',
        sortNewest: 'Plus récent',
        sortOldest: 'Plus ancien',
        sortReactions: 'Plus de cœurs',
        sortComments: 'Plus de commentaires',
        filterType: 'Type',
        filterProgress: 'Avancement',
        resetFilter: 'réinitialiser',
        searchHint: 'Rechercher du feedback',
        noMatchesTitle: 'Aucun résultat',
        noMatchesBody: "Essayez d'autres mots ou filtres.",
        clearSearchAndFilter: 'effacer',
        addHeart: 'Ajouter un cœur',
        removeHeart: 'Retirer votre cœur',
        errorTooManyHearts: 'Trop de cœurs. Réessayez dans un instant.',
        sortReplies: 'Plus de réponses',
        filterMine: 'Les miens',
        filterAdmin: 'Admin',
        searchCommentsHint: 'Rechercher des commentaires',
        feedbackNotFound: "Ce feedback n'existe plus.",
        newCommentHint: 'nouveau Commentaire...',
        writeComment: 'Écrire un commentaire',
        sendComment: 'Envoyer',
        noCommentsTitle: 'Aucun commentaire pour le moment',
        noCommentsBody: 'Soyez le premier à commenter.',
        commentDeleted: 'Commentaire supprimé',
        edited: 'modifié',
        showReplies: _showReplies,
        hideReplies: 'Masquer les réponses',
        reply: 'Répondre',
        editComment: 'Modifier le commentaire',
        editCommentTitle: 'modifier le Commentaire',
        save: 'enregistrer',
        delete: 'supprimer',
        keep: 'garder',
        deleteCommentTitle: 'Supprimer ce commentaire\u00A0?',
        deleteCommentKeepsReplies: 'Supprimer ce commentaire\u00A0? Ses réponses restent.',
        commentNotFound: "Ce commentaire n'existe plus.",
        errorTooManyComments: 'Trop de commentaires. Réessayez dans un instant.',
        offlineShowingSaved: 'Hors ligne. Feedback enregistré affiché.',
        loadMoreCommentsFailed: 'Impossible de charger plus de commentaires.',
      );

  // French puts a no-break space (U+00A0) before ? ! : so the sign never
  // wraps onto a line of its own.
  static String _minutesAgo(int n) => 'il y a $n min';
  static String _hoursAgo(int n) => 'il y a $n h';
  static String _daysAgo(int n) => 'il y a $n j';
  static String _monthsAgo(int n) => 'il y a $n mois';
  static String _yearsAgo(int n) => n == 1 ? 'il y a 1 an' : 'il y a $n ans';
  static String _costUsd(String amount) => '${amount.replaceAll('.', ',')} \$';
  static String _commentCount(int n) => n <= 1 ? '$n commentaire' : '$n commentaires';
  static String _reactionCount(int n) => n <= 1 ? '$n cœur' : '$n cœurs';
  static String _yourId(String id) => 'Votre ID\u00A0: $id';
  static String _postedAs(int n) => 'Merci\u00A0! Publié en tant que #$n';
  static String _appVersionShort(String version) => 'App $version';
  static String _showReplies(int n) =>
      n == 1 ? 'Afficher 1 réponse' : 'Afficher $n réponses';
}
