/// Exceção tipada da camada API.
///
/// Campos:
/// - [status]: código HTTP retornado pelo backend
/// - [code]: chave de erro estável (`CREDENCIAIS_INVALIDAS`, `RATE_LIMIT_EXCEDIDO`, ...)
/// - [message]: mensagem amigável em PT-BR vinda do backend (pode ser sobrescrita
///   com [mensagemAmigavel] quando o app tiver UX específica)
/// - [details]: payload bruto
class ApiException implements Exception {
  const ApiException({
    required this.status,
    required this.code,
    required this.message,
    this.details,
  });

  final int status;
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  bool get isUnauthorized => status == 401;
  bool get isForbidden => status == 403;
  bool get isNotFound => status == 404;
  bool get isConflict => status == 409;
  bool get isValidation => status == 422;
  bool get isServerError => status >= 500;
  bool get isNetwork => status == 0;
  bool get isRateLimit => status == 429;

  /// Mensagem otimizada pra exibir ao paciente — prioriza UX específica do
  /// app sobre a mensagem genérica do backend. Cobre **todos os códigos
  /// críticos** documentados em `backend/docs/PACIENTE_APP_API.md §10` +
  /// específicos de TFD/Anexo/Recovery.
  String get mensagemAmigavel {
    switch (code) {
      // ─── Auth / Sessão ────────────────────────────────────────────
      case 'CREDENCIAIS_INVALIDAS':
        return 'CPF ou senha incorretos. Verifique e tente novamente.';
      case 'CONTA_DESATIVADA':
      case 'CONTA_INATIVA':
        return 'Sua conta foi desativada. Procure sua UBS para reativação.';
      case 'TOKEN_AUSENTE':
      case 'TOKEN_INVALIDO':
        return 'Sua sessão expirou. Entre novamente.';
      case 'REFRESH_TOKEN_INVALIDO':
      case 'REFRESH_TOKEN_EXPIRADO':
      case 'REFRESH_TOKEN_REVOGADO':
        return 'Sua sessão expirou. Faça login novamente.';
      case 'REFRESH_REUSE_DETECTED':
        return 'Detectamos uso suspeito da sua conta. Por segurança, '
            'todas as sessões foram encerradas. Entre novamente.';

      // ─── Senha ───────────────────────────────────────────────────
      case 'SENHA_FRACA':
        return 'A nova senha precisa ter pelo menos 8 caracteres e não pode '
            'ser uma sequência óbvia (12345678, senha, seu CPF).';
      case 'SENHA_IGUAL_ATUAL':
        return 'A nova senha precisa ser diferente da atual.';

      // ─── Recovery de senha ───────────────────────────────────────
      case 'TOKEN_EXPIRADO':
        return 'O link de redefinição expirou (válido por 30 minutos). '
            'Solicite um novo no app.';
      case 'TOKEN_JA_USADO':
        return 'Este link já foi usado. Solicite um novo se precisar trocar a senha.';

      // ─── Ativação ────────────────────────────────────────────────
      case 'CONFIRMACAO_INVALIDA':
        return 'Os dados informados não conferem. Verifique e tente novamente.';
      case 'CONTA_JA_ATIVADA':
        return 'Sua conta já está ativa. Faça login normalmente.';
      case 'CONTA_NAO_ENCONTRADA':
        return 'CPF não cadastrado. Procure sua UBS.';

      // ─── Validação genérica ──────────────────────────────────────
      case 'CPF_INVALIDO':
        return 'CPF inválido. Verifique os 11 dígitos.';
      case 'VALIDATION_ERROR':
        return 'Alguns campos estão preenchidos incorretamente.';

      // ─── Anexos ──────────────────────────────────────────────────
      case 'ANEXO_NAO_ENCONTRADO':
        return 'Arquivo não encontrado.';
      case 'ANEXO_NAO_LIBERADO':
        final scan = details?['scanStatus'] as String?;
        if (scan == 'PENDENTE') {
          return 'Arquivo em análise de segurança. Tente novamente em alguns minutos.';
        }
        if (scan == 'INFECTADO') {
          return 'Este arquivo não pôde ser liberado por questões de segurança. '
              'Procure sua UBS.';
        }
        return 'Arquivo não disponível no momento.';
      case 'ARQUIVO_NAO_ENCONTRADO':
        return 'Arquivo indisponível. Contate sua UBS.';
      case 'FALHA_LEITURA_ARQUIVO':
        return 'Falha ao baixar o arquivo. Tente novamente.';

      // ─── Notificação ─────────────────────────────────────────────
      case 'NOTIFICACAO_NAO_ENCONTRADA':
        return 'Aviso não encontrado.';

      // ─── TFD ─────────────────────────────────────────────────────
      case 'VIAGEM_NAO_ENCONTRADA':
        return 'Esta viagem não está mais disponível.';
      case 'TFD_VIAGEM_ENCERRADA':
        return 'Esta viagem não aceita mais pedidos.';
      case 'TFD_JA_TEM_SOLICITACAO':
        return 'Você já tem uma solicitação ativa para esta viagem. '
            'Acompanhe na lista "Minhas solicitações".';
      case 'TFD_LIMITE_REABERTURAS':
        return 'Você atingiu o limite de tentativas para esta viagem. '
            'Procure a Secretaria.';
      case 'SOLICITACAO_NAO_ENCONTRADA':
        return 'Solicitação não encontrada.';

      // ─── UBS ─────────────────────────────────────────────────────
      case 'PACIENTE_SEM_UBS':
        return 'Você ainda não tem uma UBS vinculada. Procure a Secretaria de Saúde.';

      // ─── Banner ──────────────────────────────────────────────────
      case 'BANNER_NAO_ENCONTRADO':
        return 'Este aviso não está mais disponível.';

      // ─── Encaminhamento ──────────────────────────────────────────
      case 'ENCAMINHAMENTO_NAO_ENCONTRADO':
        return 'Encaminhamento não encontrado.';
      case 'ATENDIMENTO_NAO_ENCONTRADO':
        return 'Atendimento não encontrado.';
      case 'VACINACAO_NAO_ENCONTRADA':
        return 'Vacinação não encontrada.';
      case 'EXAME_NAO_ENCONTRADO':
        return 'Exame não encontrado.';

      // ─── Rede / rate limit ───────────────────────────────────────
      case 'RATE_LIMIT_EXCEDIDO':
      case 'RATE_LIMIT':
        return 'Muitas tentativas em pouco tempo. Aguarde alguns minutos.';
      case 'NETWORK_OFFLINE':
        return 'Sem conexão. Verifique sua internet e tente de novo.';

      // ─── Servidor ────────────────────────────────────────────────
      case 'INTERNAL_ERROR':
      case 'ERRO_INTERNO':
        return 'Estamos com instabilidade. Tente novamente em alguns minutos.';

      default:
        return message;
    }
  }

  @override
  String toString() => 'ApiException($status, $code): $message';
}
