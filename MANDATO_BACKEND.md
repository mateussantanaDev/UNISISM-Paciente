# MANDATO TÉCNICO — Alinhamento Backend ↔ App Paciente

**Documento autoritativo.** O Frontend (`UNISISM-Paciente`, Flutter 3.41.7,
versão 0.1.0) é a **fonte da verdade** do contrato HTTP. O Backend
(`unisism-ubs-backend`) **DEVE** se alinhar ao especificado neste documento.

---

| Campo | Valor |
|---|---|
| **Documento** | `MANDATO_BACKEND.md` |
| **Versão do contrato** | 1.0 |
| **Emissão** | 2026-05-28 |
| **Aplicação** | UNISISM Paciente (Face 3) |
| **Cliente vinculante** | `lib/data/repositories/*Http.dart` + `lib/data/models/*.dart` |
| **Backend alvo** | `unisism-ubs-backend@0.18.0+` |
| **Severidade** | 🔴 BLOQUEANTE — sem alinhamento, o app não funciona em produção |
| **Prazo sugerido de compliance** | T+5 dias úteis |

---

## Por que o frontend é a fonte de verdade

1. **O app é o ponto de contato com o cidadão.** Qualquer divergência impacta
   diretamente a experiência do paciente — não há mediador entre app e usuário.
2. **O app possui 76 arquivos Dart, ~12.500 linhas, 28 widgets e 24 telas**
   integralmente acoplados ao contrato aqui especificado. Reescrever o app pra
   acomodar mudanças do backend tem custo > backend ajustar o contrato.
3. **O contrato aqui foi extraído diretamente do código do app**, não de uma
   spec teórica. Cada URL, cada campo, cada enum está sendo lido em runtime.
4. **O backend está em hardening de qualidade, não de contrato.** As 9 etapas
   v0.10 → v0.18 entregaram qualidade (audit, rate-limit, anti-fraude) sob um
   contrato que não foi acordado com o cliente Flutter. A correção é renomear
   rotas e re-shapear payloads — não reescrever lógica.

---

## Índice

1. [Sumário executivo — violações encontradas](#1-sumário-executivo)
2. [Convenções obrigatórias](#2-convenções-obrigatórias)
3. [Catálogo de endpoints — 31 rotas mandatórias](#3-catálogo-de-endpoints)
4. [Auth — 8 endpoints](#4-auth)
5. [Encaminhamentos — 5 endpoints](#5-encaminhamentos)
6. [Notificações — 4 endpoints](#6-notificações)
7. [Dossiê médico — 4 endpoints](#7-dossiê-médico)
8. [UBS — 1 endpoint](#8-ubs)
9. [Banners SMS — 3 endpoints](#9-banners-sms)
10. [TFD — 6 endpoints](#10-tfd)
11. [Enums canônicos obrigatórios](#11-enums-canônicos-obrigatórios)
12. [Critérios de aceite (smoke test)](#12-critérios-de-aceite)
13. [Cronograma de compliance](#13-cronograma-de-compliance)
14. [Termo de aceite](#14-termo-de-aceite)

---

## 1. Sumário executivo

### 1.1 Status atual: ❌ **NÃO COMPLIANT**

Auditoria realizada em 2026-05-28 contra `backend/docs/PACIENTE_APP_API.md`
(v0.18.0) revelou **3 classes de divergência bloqueante**:

| # | Divergência | Severidade | Impacto |
|---|---|---|---|
| **D1** | Prefixos de rota incorretos | 🔴 BLOQUEANTE | 100% das chamadas HTTP retornam 404 |
| **D2** | Shape do `Sessao` (login/refresh) | 🔴 BLOQUEANTE | Login crasha com `'Null' is not subtype of 'String'` |
| **D3** | Shape do `Encaminhamento` (campos aninhados em `solicitacao.*`) | 🔴 BLOQUEANTE | Tela principal não carrega |

### 1.2 Tabela de violações por endpoint

| Endpoint exigido | Endpoint backend atual | Status |
|---|---|---|
| `POST /v1/auth/paciente/login` | `POST /v1/paciente-app/auth/login` | ❌ URL errada |
| `POST /v1/auth/paciente/refresh` | `POST /v1/paciente-app/auth/refresh` | ❌ URL errada |
| `POST /v1/auth/paciente/logout` | `POST /v1/paciente-app/auth/logout` | ❌ URL errada |
| `GET /v1/auth/paciente/me` | `GET /v1/paciente-app/me` | ❌ URL errada (sem `/auth/`) |
| `POST /v1/auth/paciente/trocar-senha` | `POST /v1/paciente-app/auth/trocar-senha` | ❌ URL errada |
| `POST /v1/auth/paciente/esqueci-senha` | `POST /v1/paciente-app/auth/esqueci-senha` | ❌ URL errada |
| `POST /v1/auth/paciente/redefinir-senha` | `POST /v1/paciente-app/auth/redefinir-senha` | ❌ URL errada |
| `POST /v1/auth/paciente/registrar-dispositivo` | `POST /v1/paciente-app/me/fcm-token` (ou inexistente) | ❌ URL errada |
| `GET /v1/paciente/encaminhamentos` | `GET /v1/paciente-app/meus-encaminhamentos` (embedado) | ❌ URL + shape |
| `GET /v1/paciente/encaminhamentos/ativo` | inexistente | ❌ não existe |
| `GET /v1/paciente/encaminhamentos/:id` | inexistente (vem embedado) | ❌ não existe |
| `GET /v1/paciente/encaminhamentos/:id/anexos` | inexistente | ❌ não existe |
| `GET /v1/paciente/encaminhamentos/:id/timeline` | inexistente | ❌ não existe |
| `GET /v1/paciente/notificacoes` | `GET /v1/paciente-app/notificacoes` | ❌ URL errada |
| `GET /v1/paciente/notificacoes/contagem-nao-lidas` | `GET /v1/paciente-app/notificacoes/count` | ❌ URL errada |
| `POST /v1/paciente/notificacoes/:id/marcar-lida` | `POST /v1/paciente-app/notificacoes/:id/lida` | ❌ URL errada |
| `POST /v1/paciente/notificacoes/marcar-todas-lidas` | `POST /v1/paciente-app/notificacoes/marcar-todas-lidas` | ❌ URL errada |
| `GET /v1/paciente/dossie/resumo` | `GET /v1/paciente-app/dossie/resumo` | ❌ URL errada |
| `GET /v1/paciente/dossie/atendimentos` | `GET /v1/paciente-app/dossie/atendimentos` | ❌ URL errada |
| `GET /v1/paciente/dossie/vacinacoes` | `GET /v1/paciente-app/dossie/vacinacoes` | ❌ URL errada |
| `GET /v1/paciente/dossie/exames` | `GET /v1/paciente-app/dossie/exames` | ❌ URL errada |
| `GET /v1/paciente/ubs/minha` | `GET /v1/paciente-app/ubs/minha` | ❌ URL errada |
| `GET /v1/paciente/banners` | `GET /v1/paciente-app/banners` | ❌ URL errada |
| `GET /v1/paciente/banners/:id` | `GET /v1/paciente-app/banners/:id` | ❌ URL errada |
| `POST /v1/paciente/banners/:id/visto` | `POST /v1/paciente-app/banners/:id/visto` | ❌ URL errada |
| `GET /v1/paciente/tfd/viagens` | `GET /v1/paciente-app/tfd/viagens` | ❌ URL errada |
| `GET /v1/paciente/tfd/viagens/:id` | `GET /v1/paciente-app/tfd/viagens/:id` | ❌ URL errada |
| `GET /v1/paciente/tfd/solicitacoes` | `GET /v1/paciente-app/tfd/solicitacoes` | ❌ URL errada |
| `GET /v1/paciente/tfd/solicitacoes/:id` | `GET /v1/paciente-app/tfd/solicitacoes/:id` | ❌ URL errada |
| `POST /v1/paciente/tfd/solicitacoes` | `POST /v1/paciente-app/tfd/solicitacoes` | ❌ URL errada |
| `DELETE /v1/paciente/tfd/solicitacoes/:id` | `DELETE /v1/paciente-app/tfd/solicitacoes/:id` | ❌ URL errada |

**Total: 31/31 violações de URL · 3 violações de shape.**

### 1.3 Implementação obrigatória

O backend **DEVE**, em uma única release de patch (sugerido v0.18.1):

1. **Renomear todos os prefixos** de `/paciente-app/*` para os definidos neste mandato.
2. **Reshapear o login/refresh** para emitir `{ accessToken, refreshToken, expiresAt, paciente }` (vide [§4.1](#41-post-v1authpacientelogin)).
3. **Desembrulhar o `Encaminhamento`** para um shape flat sem `solicitacao` aninhado (vide [§5.1](#51-get-v1pacienteencaminhamentos)).
4. **Expor as 4 rotas separadas de encaminhamento** (lista, ativo, anexos, timeline) — ainda que internamente venham de um único query (vide [§5](#5-encaminhamentos)).

Aliases adicionais são aceitos, **desde que** os endpoints especificados aqui
estejam operacionais com os shapes exatos.

---

## 2. Convenções obrigatórias

### 2.1 Base URL

| Ambiente | Base URL |
|---|---|
| Dev | `http://localhost:3333/v1` |
| Prod | `https://api.unisism.aguasbelas.pe.gov.br/v1` |

### 2.2 Prefixos canônicos

- **Auth**: `/v1/auth/paciente/*` (sem exceção)
- **Recursos**: `/v1/paciente/*` (sem exceção)

⚠️ O prefixo `/v1/paciente-app/*` atualmente usado pelo backend **não está em
conformidade** e deve ser substituído ou aliasado.

### 2.3 Headers do cliente (informativo)

O app envia em todo request:
```
Authorization: Bearer <accessToken>   (omitido nas rotas públicas)
Content-Type: application/json
Accept: application/json
X-Client-Platform: flutter-mobile
X-Client-Version: 0.1.0
```

### 2.4 Shape de erro obrigatório

```json
{
  "error": {
    "code": "SCREAMING_SNAKE_CASE",
    "message": "pt-BR amigável (será exibido na UI)",
    "details": { "campo": "opcional" }
  }
}
```

Shape plano (`{ code, message, details }` sem envelope) também é aceito por
compatibilidade, **porém** a forma envelopada é a recomendada.

### 2.5 Códigos HTTP — comportamento do cliente

| HTTP | Cliente entende como | Reação |
|---|---|---|
| 200/201/204 | Sucesso | Continua fluxo |
| 400/422 | `VALIDATION_ERROR` | Mostra inline no form |
| 401 | `AUTH_INVALID_CREDENTIALS` ou `TOKEN_EXPIRED` | Tenta refresh; senão `→ /login` |
| 403 | `FORBIDDEN_RESOURCE` | Mensagem de erro |
| 404 | `NOT_FOUND` | Empty state ou erro contextual |
| 409 | `CONFLICT` ou específico | Inline |
| 429 | `RATE_LIMIT` | "Tente em alguns minutos" |
| 5xx | `INTERNAL_ERROR` | ErrorView com retry |

### 2.6 Datas — formato obrigatório

| Tipo | Formato | Exemplo |
|---|---|---|
| Datetime | ISO 8601 UTC com `Z` | `2026-05-28T15:32:18.000Z` |
| Date pura | `YYYY-MM-DD` | `2026-05-28` |
| Hora pura | `HH:mm` 24h | `09:30` |

**Proibido**: `DD/MM/YYYY` em qualquer campo. O parser Dart quebra.

### 2.7 Identificadores

- IDs: UUID v4
- Protocolos human-readable: `UBS-AAAA-NNNNNN`, `TFD-AAAA-NNNNNN`, etc.

### 2.8 CPF

- App envia **sempre só dígitos** (`12345678909`).
- Backend deve aceitar formatado também e normalizar internamente.
- Em respostas, backend deve enviar **ambos**: `cpf` (dígitos) E `cpfFormatado` (com pontuação).

### 2.9 Anti-enumeration

Toda rota `/v1/paciente/:recurso/:id` **DEVE**:
- Filtrar por `cpf = req.paciente.cpf` (extraído do token).
- Retornar **404 `NOT_FOUND`** quando o recurso é de outro paciente.
- **Proibido 403** nesse caso (vaza existência).

### 2.10 Auth

| Item | Valor obrigatório |
|---|---|
| Access token | JWT ou opaco, header `Authorization: Bearer <token>` |
| TTL access | 30 min (com refresh) OU 24h (sem refresh — aceito como degradação) |
| Refresh token | Opaco, rotativo, TTL 30 dias, **uso único** |
| Detecção de replay | Refresh já consumido → revoga TODA a cadeia da conta |

---

## 3. Catálogo de endpoints

Os **31 endpoints abaixo são obrigatórios**. URLs exatas e shapes exatos como
especificado. Variações não serão aceitas.

| # | Método | URL | Auth | Detalhe |
|---|---|---|---|---|
| 1 | POST | `/v1/auth/paciente/login` | ❌ | [§4.1](#41-post-v1authpacientelogin) |
| 2 | POST | `/v1/auth/paciente/refresh` | ❌ | [§4.2](#42-post-v1authpacienterefresh) |
| 3 | POST | `/v1/auth/paciente/logout` | ✅ | [§4.3](#43-post-v1authpacientelogout) |
| 4 | GET | `/v1/auth/paciente/me` | ✅ | [§4.4](#44-get-v1authpacienteme) |
| 5 | POST | `/v1/auth/paciente/trocar-senha` | ✅ | [§4.5](#45-post-v1authpacientetrocar-senha) |
| 6 | POST | `/v1/auth/paciente/esqueci-senha` | ❌ | [§4.6](#46-post-v1authpacienteesqueci-senha) |
| 7 | POST | `/v1/auth/paciente/redefinir-senha` | ❌ | [§4.7](#47-post-v1authpacienteredefinir-senha) |
| 8 | POST | `/v1/auth/paciente/registrar-dispositivo` | ✅ | [§4.8](#48-post-v1authpacienteregistrar-dispositivo) |
| 9 | GET | `/v1/paciente/encaminhamentos` | ✅ | [§5.1](#51-get-v1pacienteencaminhamentos) |
| 10 | GET | `/v1/paciente/encaminhamentos/ativo` | ✅ | [§5.2](#52-get-v1pacienteencaminhamentosativo) |
| 11 | GET | `/v1/paciente/encaminhamentos/:id` | ✅ | [§5.3](#53-get-v1pacienteencaminhamentosid) |
| 12 | GET | `/v1/paciente/encaminhamentos/:id/anexos` | ✅ | [§5.4](#54-get-v1pacienteencaminhamentosidanexos) |
| 13 | GET | `/v1/paciente/encaminhamentos/:id/timeline` | ✅ | [§5.5](#55-get-v1pacienteencaminhamentosidtimeline) |
| 14 | GET | `/v1/paciente/notificacoes` | ✅ | [§6.1](#61-get-v1pacientenotificacoes) |
| 15 | GET | `/v1/paciente/notificacoes/contagem-nao-lidas` | ✅ | [§6.2](#62-get-v1pacientenotificacoescontagem-nao-lidas) |
| 16 | POST | `/v1/paciente/notificacoes/:id/marcar-lida` | ✅ | [§6.3](#63-post-v1pacientenotificacoesidmarcar-lida) |
| 17 | POST | `/v1/paciente/notificacoes/marcar-todas-lidas` | ✅ | [§6.4](#64-post-v1pacientenotificacoesmarcar-todas-lidas) |
| 18 | GET | `/v1/paciente/dossie/resumo` | ✅ | [§7.1](#71-get-v1pacientedossieresumo) |
| 19 | GET | `/v1/paciente/dossie/atendimentos` | ✅ | [§7.2](#72-get-v1pacientedossieatendimentos) |
| 20 | GET | `/v1/paciente/dossie/vacinacoes` | ✅ | [§7.3](#73-get-v1pacientedossievacinacoes) |
| 21 | GET | `/v1/paciente/dossie/exames` | ✅ | [§7.4](#74-get-v1pacientedossieexames) |
| 22 | GET | `/v1/paciente/ubs/minha` | ✅ | [§8](#8-ubs) |
| 23 | GET | `/v1/paciente/banners` | ✅ | [§9.1](#91-get-v1pacientebanners) |
| 24 | GET | `/v1/paciente/banners/:id` | ✅ | [§9.2](#92-get-v1pacientebannersid) |
| 25 | POST | `/v1/paciente/banners/:id/visto` | ✅ | [§9.3](#93-post-v1pacientebannersidvisto) |
| 26 | GET | `/v1/paciente/tfd/viagens` | ✅ | [§10.1](#101-get-v1pacientetfdviagens) |
| 27 | GET | `/v1/paciente/tfd/viagens/:id` | ✅ | [§10.2](#102-get-v1pacientetfdviagensid) |
| 28 | GET | `/v1/paciente/tfd/solicitacoes` | ✅ | [§10.3](#103-get-v1pacientetfdsolicitacoes) |
| 29 | GET | `/v1/paciente/tfd/solicitacoes/:id` | ✅ | [§10.4](#104-get-v1pacientetfdsolicitacoesid) |
| 30 | POST | `/v1/paciente/tfd/solicitacoes` | ✅ | [§10.5](#105-post-v1pacientetfdsolicitacoes) |
| 31 | DELETE | `/v1/paciente/tfd/solicitacoes/:id` | ✅ | [§10.6](#106-delete-v1pacientetfdsolicitacoesid) |

---

## 4. Auth

### 4.1 `POST /v1/auth/paciente/login`

**Público**.

**Request OBRIGATÓRIO**:
```json
{
  "cpf": "12345678909",
  "senha": "SenhaInformada"
}
```

**Response 200 OBRIGATÓRIO**:
```json
{
  "accessToken": "<jwt-ou-opaco>",
  "refreshToken": "<opaco-rotativo>",
  "expiresAt": "2026-05-28T16:02:18.000Z",
  "paciente": {
    "id": "uuid",
    "nome": "MARIA APARECIDA SOUZA",
    "cpf": "12345678909",
    "cpfFormatado": "123.456.789-09",
    "dataNascimento": "1962-08-14",
    "cartaoSus": "700 1234 5678 9012",
    "email": "maria@email.com",
    "telefone": "(75) 99876-5432",
    "fotoUrl": null,
    "ubsVinculadaId": "ubs-031",
    "ubsVinculadaNome": "UBS Centro - Dr. João Mendes",
    "senhaProvisoria": true
  }
}
```

**⚠️ Nomes de campos imutáveis:**
- `accessToken` (NÃO `token`)
- `expiresAt` em ISO 8601 (NÃO `expiresIn` em segundos)
- `refreshToken`
- `paciente.senhaProvisoria` é boolean obrigatório (NÃO omitir, NÃO usar string)

**Erros**:
| HTTP | code | Quando |
|---|---|---|
| 401 | `AUTH_INVALID_CREDENTIALS` | CPF/senha errados (mesma resposta — anti-enum) |
| 403 | `CONTA_DESATIVADA` | conta inativa |
| 422 | `CPF_INVALIDO` | < 11 dígitos |
| 429 | `RATE_LIMIT` | 5 tentativas/15min/IP+CPF |

---

### 4.2 `POST /v1/auth/paciente/refresh`

**Público** (sem `Authorization`).

**Request**:
```json
{ "refreshToken": "<opaco>" }
```

**Response 200**: idêntico ao login — `accessToken`, `refreshToken` **NOVO**,
`expiresAt`, `paciente`.

**Comportamento obrigatório**:
- Refresh anterior fica permanentemente revogado (uso único).
- Detecção de replay: refresh já rotacionado é reapresentado → **revoga TODA a cadeia da conta** + 401.

**Erros**:
| HTTP | code |
|---|---|
| 401 | `REFRESH_TOKEN_INVALIDO` |
| 401 | `REFRESH_TOKEN_EXPIRADO` |
| 401 | `REFRESH_TOKEN_REVOGADO` |
| 401 | `REFRESH_REUSE_DETECTED` |
| 403 | `CONTA_DESATIVADA` |

---

### 4.3 `POST /v1/auth/paciente/logout`

**Autenticado**. Body vazio.

**Response**: `204 No Content`.

**Side effect obrigatório**: revogar a `SessaoPaciente` correspondente
ao access token (access E refresh).

---

### 4.4 `GET /v1/auth/paciente/me`

**Autenticado**.

**Response 200**: shape **idêntico** ao `paciente` do login (sem tokens):

```json
{
  "id": "uuid",
  "nome": "MARIA APARECIDA SOUZA",
  "cpf": "12345678909",
  "cpfFormatado": "123.456.789-09",
  "dataNascimento": "1962-08-14",
  "cartaoSus": "700 1234 5678 9012",
  "email": "maria@email.com",
  "telefone": "(75) 99876-5432",
  "fotoUrl": null,
  "ubsVinculadaId": "ubs-031",
  "ubsVinculadaNome": "UBS Centro - Dr. João Mendes",
  "senhaProvisoria": false
}
```

**Campos OBRIGATÓRIOS no me** (sem omissão):
- `dataNascimento`, `cartaoSus`, `ubsVinculadaId`, `ubsVinculadaNome`

⚠️ A doc backend atual indica que esses campos **não são enviados**. Isso
constitui violação. **DEVE** ser corrigido.

---

### 4.5 `POST /v1/auth/paciente/trocar-senha`

**Autenticado**.

**Request**:
```json
{
  "senhaAtual": "12345678909",
  "novaSenha": "MinhaNova2026"
}
```

**Response**: `204`.

**Side effects obrigatórios**:
1. `paciente.senhaHash = bcrypt(novaSenha, 12)`
2. **`paciente.senhaProvisoria = false`** (crítico — app verifica via `/me`)
3. Opcional: revogar outras sessões.

**Erros**:
| HTTP | code |
|---|---|
| 401 | `SENHA_ATUAL_INCORRETA` |
| 422 | `SENHA_FRACA` (< 8 chars) |
| 422 | `SENHA_IGUAL_ATUAL` |

---

### 4.6 `POST /v1/auth/paciente/esqueci-senha`

**Público**.

**Request**: `{ "cpf": "12345678909" }`

**Response**: `204` **SEMPRE** (anti-enum).

Side effects e rate-limit conforme implementação atual.

---

### 4.7 `POST /v1/auth/paciente/redefinir-senha`

**Público**.

**Request**:
```json
{
  "token": "<token-do-email>",
  "novaSenha": "Nova2026"
}
```

**Response**: `204`.

**Erros**: `404 TOKEN_INVALIDO` · `401 TOKEN_EXPIRADO` · `409 TOKEN_JA_USADO` · `422 SENHA_FRACA` · `422 SENHA_IGUAL_ATUAL` · `429 RATE_LIMIT`.

---

### 4.8 `POST /v1/auth/paciente/registrar-dispositivo`

**Autenticado**. Push via ntfy.sh.

**Request**:
```json
{
  "fcmToken": "<endpoint-ntfy-uuid>",
  "plataforma": "android"
}
```

**Response 200**:
```json
{
  "endpoint": "<topic>",
  "subscribeUrl": "wss://ntfy.aguasbelas.pe.gov.br/<topic>/ws",
  "provider": "NTFY"
}
```

Ou `204 No Content` é aceito.

---

## 5. Encaminhamentos

### 5.1 `GET /v1/paciente/encaminhamentos`

**Autenticado**.

**Response 200**: array (pode ser `[]`).

**Shape FLAT obrigatório por item** (proibido `solicitacao` aninhado):

```json
[
  {
    "id": "uuid",
    "protocolo": "UBS-2026-100137",
    "status": "AGENDADO",
    "prioridade": "PRIORITARIA",
    "especialidade": "Cardiologia",
    "cid10": "I10",
    "cid10Descricao": "Hipertensão essencial",
    "justificativaResumida": "Paciente com HAS de longa data...",
    "ubsOrigemNome": "UBS Central",
    "medicoSolicitanteNome": "Dr. Ricardo Santos",
    "dataAgendamento": "2026-06-08T09:00:00.000Z",
    "localAgendamento": "CEM Sala 3 · Av. Getúlio Vargas, 1100",
    "observacoesRegulacao": "Trazer ECG recente",
    "motivoRejeicao": null,
    "pendenciasAbertas": 0,
    "podeSolicitarTfd": true,
    "criadoEm": "2026-05-06T14:32:18.000Z",
    "atualizadoEm": "2026-05-24T10:15:00.000Z"
  }
]
```

**Mapeamento de campos** que devem ser renomeados no backend atual:

| Backend hoje | Esperado pelo app |
|---|---|
| `solicitacao.especialidadeSolicitada` | `especialidade` (flat) |
| `solicitacao.cid10` | `cid10` (flat) |
| `solicitacao.cidDescricao` | `cid10Descricao` (flat) |
| `solicitacao.prioridade` | `prioridade` (flat) |
| `solicitacao.justificativaClinica` | `justificativaResumida` (flat) |
| `solicitacao.medicoSolicitante` | `medicoSolicitanteNome` (flat) |
| `unidadeOrigem` | `ubsOrigemNome` (renomear) |
| `agendamentoPrevisto` | `dataAgendamento` (renomear) |

**Ordenação**: `atualizadoEm DESC`. **Limite**: 100.

**Filtro automático**: backend filtra por `cpf = req.paciente.cpf`.

**Audit CFM 20 anos** obrigatório em cada leitura.

---

### 5.2 `GET /v1/paciente/encaminhamentos/ativo`

**Autenticado**.

**Response 200**: 1 `Encaminhamento` (mesmo shape de 5.1) OU **`null` literal**.

Critério de "ativo": mais recente com `status NOT IN (CONCLUIDO, REJEITADO, CANCELADO)`.

⚠️ **Proibido retornar 404 quando não há ativo.** **DEVE** retornar `200 null`.

---

### 5.3 `GET /v1/paciente/encaminhamentos/:id`

**Response 200**: 1 `Encaminhamento` (shape de 5.1).

**404 `NOT_FOUND`** se inexistente ou de outro paciente (anti-enum).

---

### 5.4 `GET /v1/paciente/encaminhamentos/:id/anexos`

**Response 200**: array.

```json
[
  {
    "id": "uuid",
    "nome": "solicitacao-medica.pdf",
    "tipo": "PDF",
    "tamanhoBytes": 142336,
    "adicionadoEm": "2026-05-06T14:35:00.000Z",
    "descricao": "Solicitação assinada"
  }
]
```

**Campos OBRIGATÓRIOS**:
- `tipo`: enum `"PDF" | "IMG" | "DOC"` (derivar do MIME, não usar enum interno)
- `tamanhoBytes`: int (NÃO `tamanhoKb` em KB — app espera bytes)

**Mapeamento de tipos**:
- `application/pdf` → `PDF`
- `image/*` → `IMG`
- demais → `DOC`

---

### 5.5 `GET /v1/paciente/encaminhamentos/:id/timeline`

**Response 200**: array ordenado `em ASC`.

```json
[
  {
    "id": "uuid",
    "tipo": "CRIACAO",
    "titulo": "Encaminhamento criado",
    "descricao": "Enviado à regulação",
    "autor": "Dr. Ricardo Santos",
    "autorPapel": "Médico solicitante",
    "em": "2026-05-06T14:32:18.000Z"
  }
]
```

**`tipo`**: enum de [§11.3](#113-eventotimelinetipo). Backend pode mapear seus tipos internos
(`CRIADO`, `DOCUMENTO_ANEXADO`, etc.) para o enum canônico do app.

---

### 5.6 Download de anexo (binário)

**Endpoint sugerido**: `GET /v1/paciente/anexos/:anexoId/download` ou
`GET /v1/paciente/encaminhamentos/:id/anexos/:anexoId/download`.

**Headers obrigatórios**:
```
Content-Type: application/pdf (ou MIME real)
Content-Disposition: attachment; filename="..."
Content-Length: <bytes>
```

Auth via `Authorization: Bearer`. Anti-enum por JWT.

**Erros**:
- 404 `ANEXO_NAO_ENCONTRADO`
- 409 `ANEXO_NAO_LIBERADO` com `details.scanStatus` quando ClamAV ≠ `LIMPO`.

---

## 6. Notificações

### 6.1 `GET /v1/paciente/notificacoes`

**Response 200**: array (pode `[]`).

```json
[
  {
    "id": "uuid",
    "tipo": "ENCAMINHAMENTO_APROVADO",
    "titulo": "Sua consulta foi marcada!",
    "corpo": "Cardiologia · 08/06 · 09:30",
    "em": "2026-05-24T10:15:00.000Z",
    "lida": false,
    "tone": "SUCCESS",
    "deepLink": "/encaminhamento/uuid",
    "encaminhamentoId": "uuid",
    "tfdSolicitacaoId": null
  }
]
```

**Campos com regra especial**:
- `em` (NÃO `criadaEm`)
- `lida` boolean (NÃO `lidaEm: string|null`)
- `tone` enum `INFO | SUCCESS | WARNING | CRITICAL`

Ordenação: `em DESC`.

### 6.2 `GET /v1/paciente/notificacoes/contagem-nao-lidas`

**Response 200**:
```json
{ "count": 3 }
```

App aceita `"naoLidas"` como fallback, mas `count` é o nome obrigatório.

### 6.3 `POST /v1/paciente/notificacoes/:id/marcar-lida`

**Response**: `204`. Idempotente.

### 6.4 `POST /v1/paciente/notificacoes/marcar-todas-lidas`

**Response**: `204`.

---

## 7. Dossiê médico

### 7.1 `GET /v1/paciente/dossie/resumo`

```json
{
  "totalEncaminhamentos": 4,
  "totalAtendimentos": 21,
  "totalVacinas": 14,
  "totalExames": 5,
  "tipoSanguineo": "O+",
  "alergias": ["Dipirona", "Iodo"],
  "condicoesCronicas": ["Hipertensão arterial"],
  "medicamentosUsoContinuo": ["Losartana 50mg · 1x/dia"]
}
```

### 7.2 `GET /v1/paciente/dossie/atendimentos`

Array OU `{ "items": [...], "nextCursor": null }`.

```json
{
  "id": "uuid",
  "data": "2026-05-19T10:30:00.000Z",
  "tipo": "CONSULTA_MEDICA",
  "localNome": "UBS Central",
  "profissionalNome": "Dr. Ricardo Santos",
  "profissionalEspecialidade": "Clínica geral",
  "queixaPrincipal": "...",
  "cid10": "E11.9",
  "cid10Descricao": "...",
  "condutaResumida": "..."
}
```

`tipo`: [§11.4](#114-atendimentotipo). Ordenação: `data DESC`.

### 7.3 `GET /v1/paciente/dossie/vacinacoes`

```json
{
  "id": "uuid",
  "vacina": "Influenza tetravalente",
  "dose": "Anual",
  "aplicadaEm": "2026-04-12T14:00:00.000Z",
  "localAplicacao": "UBS Central",
  "lote": "BR224-2026",
  "fabricante": "Butantan",
  "via": "INTRAMUSCULAR",
  "aplicadorNome": "Enf. João Silva"
}
```

### 7.4 `GET /v1/paciente/dossie/exames`

```json
{
  "id": "uuid",
  "nome": "Hemoglobina glicada (HbA1c)",
  "realizadoEm": "2026-05-05T09:00:00.000Z",
  "solicitanteNome": "Dr. Ricardo Santos",
  "alterado": true,
  "unidadeExecutora": "Laboratório Municipal",
  "categoria": "LABORATORIAL",
  "resultadoStatus": "ALTERADO",
  "resultadoResumo": "HbA1c = 8,4% (acima do alvo)",
  "observacoes": "Reforçar adesão e revisar dieta"
}
```

⚠️ **Frase amigável obrigatória em `resultadoResumo`** — não dump técnico.

Audit CFM 20 anos em todas as leituras.

---

## 8. UBS

### `GET /v1/paciente/ubs/minha`

```json
{
  "id": "uuid",
  "nome": "UBS Central",
  "endereco": "Av. Senhor dos Passos, 1422",
  "bairro": "Centro",
  "cidade": "Águas Belas",
  "uf": "PE",
  "cep": "55.300-000",
  "telefone": "(75) 3603-7800",
  "whatsapp": "5575998765432",
  "email": "ubs.central@aguasbelas.pe.gov.br",
  "horarioFuncionamento": "Segunda a Sexta · 07:00 às 17:00",
  "coordenadoresNomes": ["Dra. Helena Rocha"],
  "latitude": -8.7234,
  "longitude": -37.1234,
  "observacoes": "..."
}
```

**⚠️ Regra crítica — `whatsapp`**: **DEVE ser dígitos com DDI** (`5575998765432`).
App concatena diretamente em `https://wa.me/{whatsapp}`. Qualquer máscara
(espaços, parênteses, `+55`) quebra o deep-link silenciosamente.

**Erros**:
- 404 `PACIENTE_SEM_UBS` quando sem vínculo.

---

## 9. Banners SMS

### 9.1 `GET /v1/paciente/banners`

Array, pode `[]`.

```json
{
  "id": "uuid",
  "titulo": "Campanha Influenza",
  "corpo": "Procure sua UBS...",
  "tone": "CAMPANHA",
  "publicadoEm": "2026-05-26T08:00:00.000Z",
  "expiraEm": "2026-07-26T00:00:00.000Z",
  "imagemUrl": "https://cdn.../banner.jpg",
  "ctaLabel": "Saiba mais",
  "ctaUrl": "https://www.aguasbelas.pe.gov.br/...",
  "prioridadeOrdem": 100
}
```

⚠️ `imagemUrl` e `ctaUrl` **HTTPS obrigatório**.

### 9.2 `GET /v1/paciente/banners/:id`

1 banner. 404 se expirado.

### 9.3 `POST /v1/paciente/banners/:id/visto`

`204`. Idempotente.

---

## 10. TFD

### 10.1 `GET /v1/paciente/tfd/viagens`

```json
{
  "id": "uuid",
  "destinoCidade": "Recife",
  "destinoUf": "PE",
  "destinoLocal": "CEM · Av. Conde da Boa Vista",
  "dataPartida": "2026-06-08T00:00:00.000Z",
  "horaPartida": "06:30",
  "localEmbarque": "Terminal Rodoviário · Plataforma B",
  "vagasTotal": 12,
  "vagasOcupadas": 7,
  "veiculoDescricao": "Van Sprinter · 14 lugares",
  "veiculoPlaca": "JLT-2K84",
  "motoristaNome": "João Pedro Lima",
  "observacoes": "Levar documento com foto"
}
```

### 10.2-10.4 Demais GETs

Conforme [`CONTRATO_BACKEND.md §10`](./CONTRATO_BACKEND.md).

### 10.5 `POST /v1/paciente/tfd/solicitacoes`

**Request**:
```json
{
  "viagemId": "uuid",
  "encaminhamentoId": "uuid",
  "justificativa": "Consulta com cardiologista",
  "acompanhante": "João Souza"
}
```

### 🚨 Regra obrigatória — derivação NO SERVIDOR

```typescript
if (!encaminhamentoId) prioridade = 'NORMAL';
else if (enc.paciente.cpf !== cpfPaciente) throw 'ENC_NAO_ENCONTRADO';
else if (['URGENTE','EMERGENCIA'].includes(enc.prioridade)) prioridade = 'URGENTE';
else prioridade = 'PRIORITARIA';
```

**Proibido** confiar em `prioridade` enviada pelo cliente.

### 10.6 `DELETE /v1/paciente/tfd/solicitacoes/:id`

`204`. 409 se status ≠ `AGUARDANDO`.

---

## 11. Enums canônicos obrigatórios

### 11.1 `EncaminhamentoStatus`
```
RASCUNHO | AGUARDANDO_REGULACAO | EM_ANALISE | PENDENCIA_DOCUMENTO |
APROVADO | AGUARDANDO_AGENDAMENTO | AGENDADO |
REJEITADO | CANCELADO | CONCLUIDO
```

### 11.2 `PrioridadeClinica`
```
ELETIVA | PRIORITARIA | URGENTE | EMERGENCIA
```

### 11.3 `EventoTimelineTipo` (app)
```
CRIACAO | ANEXO | PENDENCIA | APROVACAO | AGENDAMENTO | REJEICAO | ATUALIZACAO
```

Backend pode mapear seus tipos internos para estes.

### 11.4 `AtendimentoTipo`
```
CONSULTA_MEDICA | ENFERMAGEM | VACINACAO | CURATIVO |
ODONTOLOGICO | PROCEDIMENTO | ACOLHIMENTO
```

### 11.5 `VacinacaoVia`
```
INTRAMUSCULAR | ORAL | SUBCUTANEA | INTRADERMICA | NASAL
```

### 11.6 `ExameCategoria` + `ResultadoStatus`
```
LABORATORIAL | IMAGEM | FUNCIONAL | OUTROS
NORMAL | ALTERADO | CRITICO | PENDENTE
```

### 11.7 `TfdSolicitacaoStatus` + Prioridade
```
AGUARDANDO | APROVADA | RECUSADA | CANCELADA | EMBARCADA | CONCLUIDA
NORMAL | PRIORITARIA | URGENTE
```

### 11.8 `BannerTone`
```
URGENTE | CAMPANHA | INFO | ATENCAO
```

### 11.9 `AnexoTipo` (derivado do MIME, não dos enums Face 1/2)
```
PDF | IMG | DOC
```

### 11.10 `NotificacaoTone`
```
INFO | SUCCESS | WARNING | CRITICAL
```

---

## 12. Critérios de aceite

A entrega do backend será **aceita** se todos os comandos abaixo executarem
com sucesso contra `http://localhost:3333/v1`:

### 12.1 Login

```bash
RESP=$(curl -sX POST http://localhost:3333/v1/auth/paciente/login \
  -H 'Content-Type: application/json' \
  -d '{"cpf":"12345678909","senha":"12345678909"}')

# Critério 1.1: response tem accessToken (string)
echo "$RESP" | jq -e '.accessToken | type == "string"' || echo "❌ FAIL"

# Critério 1.2: response tem refreshToken (string)
echo "$RESP" | jq -e '.refreshToken | type == "string"' || echo "❌ FAIL"

# Critério 1.3: response tem expiresAt ISO 8601
echo "$RESP" | jq -e '.expiresAt | test("^\\d{4}-\\d{2}-\\d{2}T")' || echo "❌ FAIL"

# Critério 1.4: paciente.senhaProvisoria é boolean
echo "$RESP" | jq -e '.paciente.senhaProvisoria | type == "boolean"' || echo "❌ FAIL"

# Critério 1.5: paciente.cpfFormatado existe
echo "$RESP" | jq -e '.paciente.cpfFormatado | type == "string"' || echo "❌ FAIL"

# Critério 1.6: paciente.ubsVinculadaId existe (não null)
echo "$RESP" | jq -e '.paciente.ubsVinculadaId | type == "string"' || echo "❌ FAIL"

# Critério 1.7: paciente.dataNascimento existe
echo "$RESP" | jq -e '.paciente.dataNascimento | type == "string"' || echo "❌ FAIL"

TOKEN=$(echo "$RESP" | jq -r .accessToken)
```

### 12.2 Me

```bash
ME=$(curl -sH "Authorization: Bearer $TOKEN" http://localhost:3333/v1/auth/paciente/me)
echo "$ME" | jq -e '.senhaProvisoria | type == "boolean"' || echo "❌ FAIL"
echo "$ME" | jq -e '.ubsVinculadaId | type == "string"' || echo "❌ FAIL"
echo "$ME" | jq -e '.dataNascimento | type == "string"' || echo "❌ FAIL"
echo "$ME" | jq -e '.cartaoSus' || echo "❌ FAIL"  # pode ser null mas chave existe
```

### 12.3 Encaminhamentos shape flat

```bash
ENCS=$(curl -sH "Authorization: Bearer $TOKEN" \
  http://localhost:3333/v1/paciente/encaminhamentos)

# Critério 3.1: campos flat (sem aninhamento em "solicitacao")
echo "$ENCS" | jq -e '.[0].especialidade | type == "string"' || echo "❌ FAIL (solicitacao.especialidadeSolicitada → especialidade flat)"
echo "$ENCS" | jq -e '.[0].cid10 | type == "string"' || echo "❌ FAIL"
echo "$ENCS" | jq -e '.[0].prioridade | type == "string"' || echo "❌ FAIL"
echo "$ENCS" | jq -e '.[0].justificativaResumida' || echo "❌ FAIL"
echo "$ENCS" | jq -e '.[0].ubsOrigemNome' || echo "❌ FAIL (unidadeOrigem → ubsOrigemNome)"
echo "$ENCS" | jq -e '.[0].dataAgendamento' || echo "❌ FAIL (agendamentoPrevisto → dataAgendamento)"

# Critério 3.2: NÃO deve ter campo aninhado "solicitacao"
echo "$ENCS" | jq -e '.[0].solicitacao' && echo "❌ FAIL (campo 'solicitacao' deve ser removido — shape é flat)" || echo "✅ OK"
```

### 12.4 Encaminhamento ativo (null literal)

```bash
ATIVO=$(curl -sH "Authorization: Bearer $TOKEN" \
  http://localhost:3333/v1/paciente/encaminhamentos/ativo)

# Critério 4.1: retorna null OU objeto Encaminhamento (não 404, não {})
if [ "$ATIVO" = "null" ]; then echo "✅ OK (null literal)"; else
  echo "$ATIVO" | jq -e '.id' || echo "❌ FAIL"
fi
```

### 12.5 Anexos por encaminhamento

```bash
ID=$(echo "$ENCS" | jq -r '.[0].id')
ANEXOS=$(curl -sH "Authorization: Bearer $TOKEN" \
  http://localhost:3333/v1/paciente/encaminhamentos/$ID/anexos)

echo "$ANEXOS" | jq -e '.[0].tipo | test("^(PDF|IMG|DOC)$")' || echo "❌ FAIL (tipo deve ser PDF/IMG/DOC)"
echo "$ANEXOS" | jq -e '.[0].tamanhoBytes | type == "number"' || echo "❌ FAIL (tamanhoBytes em bytes, não tamanhoKb)"
```

### 12.6 Timeline

```bash
TL=$(curl -sH "Authorization: Bearer $TOKEN" \
  http://localhost:3333/v1/paciente/encaminhamentos/$ID/timeline)

echo "$TL" | jq -e '.[0].em | type == "string"' || echo "❌ FAIL (campo deve ser 'em', não 'criadaEm')"
```

### 12.7 Notificações

```bash
N=$(curl -sH "Authorization: Bearer $TOKEN" http://localhost:3333/v1/paciente/notificacoes)
echo "$N" | jq -e '.[0].lida | type == "boolean"' || echo "❌ FAIL (campo deve ser 'lida' bool, não 'lidaEm' nullable string)"
echo "$N" | jq -e '.[0].em' || echo "❌ FAIL (campo deve ser 'em', não 'criadaEm')"
echo "$N" | jq -e '.[0].tone | test("^(INFO|SUCCESS|WARNING|CRITICAL)$")' || echo "❌ FAIL"

COUNT=$(curl -sH "Authorization: Bearer $TOKEN" \
  http://localhost:3333/v1/paciente/notificacoes/contagem-nao-lidas)
echo "$COUNT" | jq -e '.count | type == "number"' || echo "❌ FAIL (deve ser 'count', não 'naoLidas')"
```

### 12.8 Dossiê

```bash
curl -sH "Authorization: Bearer $TOKEN" \
  http://localhost:3333/v1/paciente/dossie/resumo | jq -e '.totalExames | type == "number"' || echo "❌ FAIL"

curl -sH "Authorization: Bearer $TOKEN" \
  http://localhost:3333/v1/paciente/dossie/vacinacoes | jq -e '.[0].via | test("^(INTRAMUSCULAR|ORAL|SUBCUTANEA|INTRADERMICA|NASAL)$")' || echo "⚠️ via opcional"
```

### 12.9 UBS

```bash
UBS=$(curl -sH "Authorization: Bearer $TOKEN" http://localhost:3333/v1/paciente/ubs/minha)
echo "$UBS" | jq -e '.whatsapp | test("^55\\d{10,11}$")' || echo "❌ FAIL (whatsapp deve ser DDI dígitos)"
echo "$UBS" | jq -e '.latitude | type == "number"' || echo "⚠️ lat/lng opcionais"
```

### 12.10 TFD

```bash
curl -sH "Authorization: Bearer $TOKEN" \
  http://localhost:3333/v1/paciente/tfd/viagens | jq -e '.[0].horaPartida | test("^[0-2]\\d:[0-5]\\d$")' || echo "❌ FAIL"
```

### 12.11 Script smoke completo

Fornecer `scripts/smoke-test-app-contract.sh` que rode todos os 10 critérios
acima e retorne código 0 se todos passarem.

**Critério final**: smoke `EXIT 0` = backend está em conformidade. **EXIT ≠ 0 = não aceito.**

---

## 13. Cronograma de compliance

| Item | Esforço estimado | SLA |
|---|---|---|
| Renomear prefixos `/paciente-app/*` → `/auth/paciente/*` e `/paciente/*` | 2h (sed em routes + aliases) | T+1 dia |
| Reshapear login/refresh (`token`/`expiresIn` → `accessToken`/`expiresAt`) | 1h | T+1 dia |
| Reshapear encaminhamento (flat em vez de `solicitacao.*`) | 4h (afeta UseCase + serializer) | T+2 dias |
| Adicionar `/encaminhamentos/ativo`, `/:id`, `/:id/anexos`, `/:id/timeline` | 3h (queries reaproveitam) | T+3 dias |
| Renomear campos notificação (`criadaEm` → `em`, `lidaEm` → `lida`) | 1h | T+1 dia |
| Renomear `count` em contagem | 30min | T+1 dia |
| Normalizar `tamanhoBytes` em anexos (bytes, não KB) | 30min | T+1 dia |
| Garantir `me` retorna `dataNascimento`, `cartaoSus`, `ubsVinculadaId`, `ubsVinculadaNome` | 2h (JOIN na query) | T+2 dias |
| **TOTAL backend** | **~14h** | **T+5 dias** |

⚠️ Estratégia recomendada: **uma release de patch** (`0.18.1`) com todas as
mudanças simultâneas + script de smoke validando.

---

## 14. Termo de aceite

A entrega do backend será considerada **CONFORME** quando:

- [ ] **31/31 endpoints** ativos nos caminhos especificados em [§3](#3-catálogo-de-endpoints)
- [ ] **Script smoke** ([§12.11](#1211-script-smoke-completo)) executa com **EXIT 0**
- [ ] App rodando com `--dart-define=API_BASE_URL=http://localhost:3333/v1` consegue:
  - [ ] Logar com `senhaProvisoria=true` e ser redirecionado para `/perfil/trocar-senha`
  - [ ] Trocar senha → ser redirecionado para `/home`
  - [ ] Ver lista de encaminhamentos com especialidade renderizada
  - [ ] Ver detalhe de encaminhamento com bloco "Sua consulta" (data + local)
  - [ ] Ver lista de anexos com ícone correto por tipo (PDF/IMG/DOC)
  - [ ] Ver timeline com tipos mapeados
  - [ ] Aba "Saúde" carregar resumo + atendimentos + vacinações + exames
  - [ ] Aba "Minha UBS" com endereço e WhatsApp funcional
  - [ ] Lista de banners (mesmo vazia, sem 404)
  - [ ] Lista de notificações com badge correto

- [ ] Doc backend `backend/docs/PACIENTE_APP_API.md` atualizada refletindo os novos paths e shapes
- [ ] CHANGELOG do backend com entry `[0.18.1] - Alinhamento contratual com app Paciente`

---

## Assinaturas

| Papel | Nome | Assinatura | Data |
|---|---|---|---|
| Frontend Lead (autor do contrato) | _______________ | _______________ | ___/___/____ |
| Backend Lead (responsável compliance) | _______________ | _______________ | ___/___/____ |
| Product Owner | _______________ | _______________ | ___/___/____ |

---

**Documento autoritativo.** Modificações no contrato exigem revisão conjunta
e nova versão deste documento. Em caso de divergência futura entre o
backend e este documento, prevalece o que está aqui escrito.

**Referências técnicas**:
- Código fonte do app: `lib/data/repositories/*Http.dart` + `lib/data/models/*.dart`
- Doc detalhada do contrato: `CONTRATO_BACKEND.md`
- Estado atual do backend (auditado): `backend/docs/PACIENTE_APP_API.md` (v0.18.0)

**Última atualização do mandato**: 2026-05-28.
