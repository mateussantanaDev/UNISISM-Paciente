# UNISISM Paciente — Contrato Backend (gabarito de verificação)

> **Doc final do que o app Flutter precisa do backend.** Extraído do código em
> `lib/data/repositories/*Http.dart` e `lib/data/models/*.dart`. Use como
> checklist contra o backend real.
>
> **Audiência**: dev backend (Node 22 / TS / Express 5 / Prisma 6).
>
> **Formato**: cada endpoint lista método, URL exata, request, response,
> erros e side effects esperados. Marca ✅/❌ no checklist final.

**Última auditoria**: 2026-05-28.
**Versão do app**: 0.1.0.

---

## Índice

1. [Configuração global](#1-configuração-global)
2. [Convenções (auth, erros, datas, headers)](#2-convenções)
3. [Catálogo de endpoints (tabelão)](#3-catálogo-de-endpoints)
4. [Auth — 8 endpoints](#4-auth)
5. [Encaminhamentos — 5 endpoints](#5-encaminhamentos)
6. [Notificações — 4 endpoints](#6-notificações)
7. [Dossiê médico — 4 endpoints](#7-dossiê-médico)
8. [UBS vinculada — 1 endpoint](#8-ubs-vinculada)
9. [Banners SMS — 3 endpoints](#9-banners-sms)
10. [TFD do paciente — 6 endpoints](#10-tfd-do-paciente)
11. [Push (ntfy.sh) — infra](#11-push-via-ntfysh)
12. [Enums canônicos](#12-enums-canônicos)
13. [Fluxos críticos](#13-fluxos-críticos)
14. [Checklist final](#14-checklist-final)

---

## 1. Configuração global

| Item | Valor esperado pelo app |
|---|---|
| Base URL (dev) | `http://localhost:3333/v1` |
| Base URL (prod) | `https://api.unisism.aguasbelas.pe.gov.br/v1` |
| Prefixo auth | `/auth/paciente/*` |
| Prefixo recursos | `/paciente/*` |
| Content-Type | `application/json` (request + response) |
| Encoding | UTF-8 |
| Timeouts cliente | connect 15s · receive 30s · send 30s |

⚠️ **App NÃO usa `/paciente-app/*`** — todos os endpoints estão sob
`/auth/paciente/*` (auth) ou `/paciente/*` (recursos). Se o backend usa
`/paciente-app/*`, **renomear no backend** ou expor alias.

---

## 2. Convenções

### 2.1 Headers (em todo request)

```
Authorization: Bearer <accessToken>     ← omitido nas rotas públicas
Content-Type: application/json
Accept: application/json
X-Client-Platform: flutter-mobile
X-Client-Version: 0.1.0
```

### 2.2 Auth

| Mecanismo | Detalhe |
|---|---|
| **Access token** | JWT ou opaco, header `Authorization: Bearer <token>` |
| **TTL access** | 30 min (rotação via refresh) **OU** 24h (sem refresh — degradação aceita) |
| **Refresh token** | Opaco, rotativo, TTL 30d |
| **Storage cliente** | `flutter_secure_storage` (Keychain iOS / EncryptedSharedPrefs Android) |
| **401 com refresh disponível** | App tenta refresh automaticamente (1 retry, single-flight) |
| **401 sem refresh OU refresh falhou** | App limpa tokens e vai pra `/login` |

### 2.3 Shape de erro (obrigatório)

App suporta **dois shapes** e desempacota ambos:

```json
// Shape envelopado (preferido)
{ "error": { "code": "...", "message": "...", "details": {...} } }

// Shape plano (compat)
{ "code": "...", "message": "...", "details": {...} }
```

- `code`: SCREAMING_SNAKE_CASE
- `message`: pt-BR amigável (vai pra UI)
- `details`: opcional, objeto livre

### 2.4 Códigos HTTP → comportamento do app

| HTTP | App entende como | Ação |
|---|---|---|
| 200/201/204 | Sucesso | parseia ou segue |
| 400/422 | `VALIDATION_ERROR` | mostra inline no form |
| 401 | `AUTH_INVALID_CREDENTIALS` / `TOKEN_EXPIRED` | tenta refresh; senão derruba sessão |
| 403 | `FORBIDDEN_RESOURCE` | mostra erro genérico |
| 404 | `NOT_FOUND` | mostra "não encontrado" ou empty state |
| 409 | `CONFLICT` ou específico | mensagem inline |
| 429 | `RATE_LIMIT` | mensagem "tente em alguns minutos" |
| 5xx | `INTERNAL_ERROR` | ErrorView com retry |

### 2.5 Datas

| Tipo | Formato |
|---|---|
| Datetime | ISO 8601 UTC: `"2026-05-28T15:32:18.000Z"` |
| Date pura | `"YYYY-MM-DD"` |
| Hora pura | `"HH:mm"` 24h |

⚠️ Nunca `DD/MM/YYYY` — o parsing Dart quebra. App formata pt-BR só na UI.

### 2.6 Row-level / anti-enumeration

- Toda query filtrada por `cpf = req.paciente.cpf` (extraído do token).
- Recurso de outro paciente → **404 `NOT_FOUND`** (não 403, não vazar existência).

### 2.7 CPF

- App envia **sempre só dígitos** (`12345678909`)
- Backend deve aceitar formatado também e normalizar internamente
- Backend deve enviar **`cpfFormatado`** em campos onde o paciente é destinatário visível

---

## 3. Catálogo de endpoints

| # | Método | URL | Auth | Seção |
|---|---|---|---|---|
| 1 | POST | `/auth/paciente/login` | ❌ | [§4.1](#41-post-authpacientelogin) |
| 2 | POST | `/auth/paciente/refresh` | ❌ | [§4.2](#42-post-authpacienterefresh) |
| 3 | POST | `/auth/paciente/logout` | ✅ | [§4.3](#43-post-authpacientelogout) |
| 4 | GET | `/auth/paciente/me` | ✅ | [§4.4](#44-get-authpacienteme) |
| 5 | POST | `/auth/paciente/trocar-senha` | ✅ | [§4.5](#45-post-authpacientetrocar-senha) |
| 6 | POST | `/auth/paciente/esqueci-senha` | ❌ | [§4.6](#46-post-authpacienteesqueci-senha) |
| 7 | POST | `/auth/paciente/redefinir-senha` | ❌ | [§4.7](#47-post-authpacienteredefinir-senha) |
| 8 | POST | `/auth/paciente/registrar-dispositivo` | ✅ | [§4.8](#48-post-authpacienteregistrar-dispositivo) |
| 9 | GET | `/paciente/encaminhamentos` | ✅ | [§5.1](#51-get-pacienteencaminhamentos) |
| 10 | GET | `/paciente/encaminhamentos/ativo` | ✅ | [§5.2](#52-get-pacienteencaminhamentosativo) |
| 11 | GET | `/paciente/encaminhamentos/:id` | ✅ | [§5.3](#53-get-pacienteencaminhamentosid) |
| 12 | GET | `/paciente/encaminhamentos/:id/anexos` | ✅ | [§5.4](#54-get-pacienteencaminhamentosidanexos) |
| 13 | GET | `/paciente/encaminhamentos/:id/timeline` | ✅ | [§5.5](#55-get-pacienteencaminhamentosidtimeline) |
| 14 | GET | `/paciente/notificacoes` | ✅ | [§6.1](#61-get-pacientenotificacoes) |
| 15 | GET | `/paciente/notificacoes/contagem-nao-lidas` | ✅ | [§6.2](#62-get-pacientenotificacoescontagem-nao-lidas) |
| 16 | POST | `/paciente/notificacoes/:id/marcar-lida` | ✅ | [§6.3](#63-post-pacientenotificacoesidmarcar-lida) |
| 17 | POST | `/paciente/notificacoes/marcar-todas-lidas` | ✅ | [§6.4](#64-post-pacientenotificacoesmarcar-todas-lidas) |
| 18 | GET | `/paciente/dossie/resumo` | ✅ | [§7.1](#71-get-pacientedossieresumo) |
| 19 | GET | `/paciente/dossie/atendimentos` | ✅ | [§7.2](#72-get-pacientedossieatendimentos) |
| 20 | GET | `/paciente/dossie/vacinacoes` | ✅ | [§7.3](#73-get-pacientedossievacinacoes) |
| 21 | GET | `/paciente/dossie/exames` | ✅ | [§7.4](#74-get-pacientedossiexames) |
| 22 | GET | `/paciente/ubs/minha` | ✅ | [§8](#8-ubs-vinculada) |
| 23 | GET | `/paciente/banners` | ✅ | [§9.1](#91-get-pacientebanners) |
| 24 | GET | `/paciente/banners/:id` | ✅ | [§9.2](#92-get-pacientebannersid) |
| 25 | POST | `/paciente/banners/:id/visto` | ✅ | [§9.3](#93-post-pacientebannersidvisto) |
| 26 | GET | `/paciente/tfd/viagens` | ✅ | [§10.1](#101-get-pacientetfdviagens) |
| 27 | GET | `/paciente/tfd/viagens/:id` | ✅ | [§10.2](#102-get-pacientetfdviagensid) |
| 28 | GET | `/paciente/tfd/solicitacoes` | ✅ | [§10.3](#103-get-pacientetfdsolicitacoes) |
| 29 | GET | `/paciente/tfd/solicitacoes/:id` | ✅ | [§10.4](#104-get-pacientetfdsolicitacoesid) |
| 30 | POST | `/paciente/tfd/solicitacoes` | ✅ | [§10.5](#105-post-pacientetfdsolicitacoes) |
| 31 | DELETE | `/paciente/tfd/solicitacoes/:id` | ✅ | [§10.6](#106-delete-pacientetfdsolicitacoesid) |

**Total: 31 endpoints HTTP** + WebSocket ntfy (não-HTTP).

---

## 4. Auth

### 4.1 `POST /auth/paciente/login`

**Público**.

**Request**:
```json
{ "cpf": "12345678909", "senha": "MinhaSenha123" }
```

- `cpf`: dígitos ou formatado, backend normaliza
- `senha`: plain text via TLS, bcrypt no banco

**Response 200**:
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

⚠️ **Campo crítico**: `senhaProvisoria: true` quando o paciente nunca trocou
(senha = CPF dígitos). App detecta e força fluxo bloqueante em
`/perfil/trocar-senha`.

**Erros**:
| HTTP | code | Quando |
|---|---|---|
| 401 | `AUTH_INVALID_CREDENTIALS` | CPF ou senha errados (mesma resposta — anti-enum) |
| 403 | `CONTA_DESATIVADA` | conta `ativo=false` |
| 422 | `CPF_INVALIDO` | < 11 dígitos |
| 429 | `RATE_LIMIT` | 5 tentativas/15min por CPF+IP |

---

### 4.2 `POST /auth/paciente/refresh`

**Público** (sem `Authorization`).

**Request**:
```json
{ "refreshToken": "<opaco>" }
```

**Response 200**: idêntico ao login (`accessToken`, `refreshToken` **NOVO**,
`expiresAt`, `paciente`).

**Erros**:
| HTTP | code | Quando |
|---|---|---|
| 401 | `TOKEN_INVALIDO` | refresh não existe ou já foi rotacionado |
| 401 | `TOKEN_EXPIRADO` | passou do TTL |
| 401 | `REUSE_DETECTED` | refresh já rotacionado → **revoga toda a cadeia** |

**Side effects** (transação):
1. Buscar sessão pelo `refreshToken`. Inexistente/expirada → 401.
2. **Detecção de reuse**: se `rotatedFrom` da sessão atual aponta pra alguém, é
   replay → deletar TODAS as sessões do paciente + log de fraude + 401.
3. Criar nova sessão com `rotatedFrom = sessaoAntiga.id`.
4. Revogar sessão antiga (delete ou flag).

---

### 4.3 `POST /auth/paciente/logout`

**Autenticado**. Body vazio.

**Response**: `204 No Content`.

**Side effect**: revogar a `SessaoPaciente` correspondente ao access token.

**Comportamento defensivo**: app limpa tokens locais **mesmo se backend falhar**.

---

### 4.4 `GET /auth/paciente/me`

**Autenticado**.

**Response 200**: shape **idêntico** ao `paciente` do login (sem accessToken).

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

**Quando o app chama**:
- Boot (splash) → valida sessão + detecta `senhaProvisoria`
- Após `trocar-senha` → confirma flag zerada

**Erros**: 401 se token inválido/expirado → app tenta refresh ou vai pra `/login`.

---

### 4.5 `POST /auth/paciente/trocar-senha`

**Autenticado**.

**Request**:
```json
{
  "senhaAtual": "12345678909",
  "novaSenha": "MinhaNova2026"
}
```

**Response**: `204 No Content`.

**Erros**:
| HTTP | code | Quando |
|---|---|---|
| 401 | `SENHA_ATUAL_INCORRETA` | `senhaAtual` não bate |
| 422 | `SENHA_FRACA` | nova < 8 chars |
| 422 | `SENHA_IGUAL_ATUAL` | nova == atual |

**Side effects** (transação):
1. `paciente.senhaHash = bcrypt(novaSenha, 12)`
2. **`paciente.senhaProvisoria = false`** ← crítico
3. Opcional: invalidar outras `SessaoPaciente` ativas (segurança)

**Política**: app valida 8 chars no provisório, 6 no normal. Backend revalida.

---

### 4.6 `POST /auth/paciente/esqueci-senha`

**Público**.

**Request**:
```json
{ "cpf": "12345678909" }
```

**Response**: `204 No Content` **sempre** (anti-enumeration).

**Side effects** (apenas se CPF existir e tiver email):
1. Token opaco: `crypto.randomBytes(32).toString('hex')`
2. `tokenHash = SHA-256(token)` armazenado
3. TTL 30 min, uso único
4. Enviar email com link `https://app.unisism.<dominio>/redefinir?t=<token>`
5. Rate limit: 3 tentativas/h por CPF+IP

---

### 4.7 `POST /auth/paciente/redefinir-senha`

**Público**.

**Request**:
```json
{
  "token": "<token-do-email>",
  "novaSenha": "NovaSegura2026"
}
```

**Response**: `204 No Content`.

**Erros**:
| HTTP | code | Quando |
|---|---|---|
| 404 | `TOKEN_INVALIDO` | não existe |
| 401 | `TOKEN_EXPIRADO` | > 30min |
| 409 | `TOKEN_JA_USADO` | `usadoEm != null` |
| 422 | `SENHA_FRACA` | < 8 chars |

**Side effects**: igual `trocar-senha` + marca token usado + invalida sessões.

---

### 4.8 `POST /auth/paciente/registrar-dispositivo`

**Autenticado**. Push via ntfy.sh.

**Request**:
```json
{
  "fcmToken": "<endpoint-ntfy-uuid>",
  "plataforma": "android"
}
```

- `fcmToken`: nome legado — na verdade é o **endpoint ntfy** (topic UUID)
- `plataforma`: `"android" | "ios"`

**Response**: `204` ou `200 { "endpoint": "...", "subscribeUrl": "wss://...", "provider": "NTFY" }`.

⚠️ App falha silenciosamente se este endpoint não existir — não derruba o
fluxo. Mas push não funciona.

**Side effect**: UPSERT em `paciente_push_token` por `endpoint` único.

---

## 5. Encaminhamentos

### 5.1 `GET /paciente/encaminhamentos`

**Autenticado**.

**Response 200**: array (pode ser `[]`).

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
    "justificativaResumida": "Paciente com HAS...",
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

| Campo | Tipo | Nullable | Notas |
|---|---|---|---|
| `id` | string UUID | ❌ | |
| `protocolo` | string | ❌ | `"UBS-AAAA-NNNNNN"` |
| `status` | enum | ❌ | [§12.1](#121-encaminhamentostatus) |
| `prioridade` | enum | ❌ | [§12.2](#122-prioridade-clínica) |
| `especialidade` | string | ❌ | |
| `cid10` | string | ✅ | |
| `cid10Descricao` | string | ✅ | |
| `justificativaResumida` | string | ✅ | |
| `ubsOrigemNome` | string | ✅ | |
| `medicoSolicitanteNome` | string | ✅ | |
| `dataAgendamento` | ISO 8601 | ✅ | Presente quando `status=AGENDADO` |
| `localAgendamento` | string | ✅ | |
| `observacoesRegulacao` | string | ✅ | |
| `motivoRejeicao` | string | ✅ | Presente quando `status=REJEITADO` |
| `pendenciasAbertas` | int | ❌ | Derivado (count pendências abertas) |
| `podeSolicitarTfd` | bool | ❌ | Derivado: `APROVADO` + cidade ≠ UBS |
| `criadoEm` | ISO 8601 | ❌ | |
| `atualizadoEm` | ISO 8601 | ❌ | |

**Ordenação**: `atualizadoEm DESC` (app reordena também).

### 5.2 `GET /paciente/encaminhamentos/ativo`

**Response 200**: `Encaminhamento` ou `null` literal.

Encaminhamento "ativo" = mais recente com `status NOT IN (CONCLUIDO, REJEITADO, CANCELADO)`.

⚠️ Backend deve retornar **`null` literal** quando não há, **não 404**.

### 5.3 `GET /paciente/encaminhamentos/:id`

**Response 200**: 1 `Encaminhamento` (mesmo shape).
**404 `NOT_FOUND`** se não existe ou pertence a outro paciente.

### 5.4 `GET /paciente/encaminhamentos/:id/anexos`

**Response 200**:
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

| Campo | Tipo | Nullable | Notas |
|---|---|---|---|
| `tipo` | enum | ❌ | `"PDF" \| "IMG" \| "DOC"` (derivar do MIME) |
| `tamanhoBytes` | int | ❌ | App formata em KB/MB |

### 5.5 `GET /paciente/encaminhamentos/:id/timeline`

**Response 200**:
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

`tipo`: ver [§12.3](#123-eventotimelinetipo). Ordenação: `em ASC`.

### 5.6 Download de anexo

App constrói URL com a base + path do anexo. Endpoint sugerido:
`GET /paciente/anexos/:anexoId/download` (binário).

Headers obrigatórios:
```
Content-Type: application/pdf (ou MIME real)
Content-Disposition: attachment; filename="..."
Content-Length: <bytes>
```

Anti-enum: validar posse via JWT, não via path. **404 `ANEXO_NAO_ENCONTRADO`** se de outro paciente.

ClamAV: `scanStatus != LIMPO` → **409 `ANEXO_NAO_LIBERADO`** com `details.scanStatus`.

---

## 6. Notificações

### 6.1 `GET /paciente/notificacoes`

**Response 200**: array (pode ser `[]`).

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

| Campo | Tipo | Nullable | Notas |
|---|---|---|---|
| `tipo` | enum | ❌ | [§12.6](#126-notificacaotipo) |
| `em` | ISO 8601 | ❌ | |
| `lida` | bool | ❌ | Backend pode mandar `lidaEm: string\|null` — app aceita ambos |
| `tone` | enum | ❌ | `INFO \| SUCCESS \| WARNING \| CRITICAL` |
| `deepLink` | string | ✅ | Path interno do app (ex `/encaminhamento/uuid`) |

**Ordenação**: `em DESC`. **Limite**: 100.

### 6.2 `GET /paciente/notificacoes/contagem-nao-lidas`

**Response 200**:
```json
{ "count": 3 }
```

Backend pode usar `"naoLidas"` em vez de `"count"` — app aceita ambos.

Cache server-side recomendado (TTL 30s).

### 6.3 `POST /paciente/notificacoes/:id/marcar-lida`

**Response**: `204`. **Idempotente**.

### 6.4 `POST /paciente/notificacoes/marcar-todas-lidas`

**Response**: `204` ou `200 { "atualizadas": N }` (app não exige).

---

## 7. Dossiê médico

### 7.1 `GET /paciente/dossie/resumo`

**Response 200**:
```json
{
  "totalEncaminhamentos": 4,
  "totalAtendimentos": 21,
  "totalVacinas": 14,
  "totalExames": 5,
  "tipoSanguineo": "O+",
  "alergias": ["Dipirona", "Iodo"],
  "condicoesCronicas": ["Hipertensão arterial", "Diabetes mellitus tipo 2"],
  "medicamentosUsoContinuo": [
    "Losartana 50mg · 1x/dia",
    "Metformina 850mg · 2x/dia"
  ]
}
```

Arrays podem ser `[]`. `tipoSanguineo` pode ser `null`.

### 7.2 `GET /paciente/dossie/atendimentos`

**Response 200**: array OU `{ items: [...], nextCursor?: string }`.

```json
{
  "items": [
    {
      "id": "uuid",
      "data": "2026-05-19T10:30:00.000Z",
      "tipo": "CONSULTA_MEDICA",
      "localNome": "UBS Central",
      "profissionalNome": "Dr. Ricardo Santos",
      "profissionalEspecialidade": "Clínica geral",
      "queixaPrincipal": "Glicemia descompensada",
      "cid10": "E11.9",
      "cid10Descricao": "DM2 sem complicações",
      "condutaResumida": "Ajuste de metformina"
    }
  ],
  "nextCursor": null
}
```

`tipo`: ver [§12.4](#124-atendimentotipo). Ordenação: `data DESC`.

### 7.3 `GET /paciente/dossie/vacinacoes`

**Response 200** (array ou `{items}`):
```json
[
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
]
```

`via`: ver [§12.5](#125-vacinacaovia). Nullable, igual `aplicadorNome`.

### 7.4 `GET /paciente/dossie/exames`

**Response 200** (array ou `{items}`):
```json
[
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
]
```

⚠️ **LGPD/médico**: `resultadoResumo` é **frase amigável**, não dump técnico
sem contexto. Não incluir valores que exigem interpretação médica.

### 7.5 Audit CFM

Toda leitura → linha em `paciente_prontuario_audit` (retenção 20 anos).

---

## 8. UBS vinculada

### `GET /paciente/ubs/minha`

**Response 200**:
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
  "coordenadoresNomes": ["Dra. Helena Rocha", "Enf. Carla Mendes"],
  "latitude": -8.7234,
  "longitude": -37.1234,
  "observacoes": "Vacinação rotina às quartas"
}
```

⚠️ **Crítico**: `whatsapp` deve ser **só dígitos com DDI** (`5575998765432`).
App concatena em `https://wa.me/{whatsapp}` — qualquer máscara quebra.

**Erros**:
- 404 `PACIENTE_SEM_UBS` quando paciente não tem vínculo.
  App mostra `EmptyView` orientando procurar a SMS.

---

## 9. Banners SMS

### 9.1 `GET /paciente/banners`

**Response 200**: array (pode ser `[]`).

```json
[
  {
    "id": "uuid",
    "titulo": "Campanha de vacinação Influenza",
    "corpo": "Procure sua UBS...",
    "tone": "CAMPANHA",
    "publicadoEm": "2026-05-26T08:00:00.000Z",
    "expiraEm": "2026-07-26T00:00:00.000Z",
    "imagemUrl": "https://cdn.sms.../banner1.jpg",
    "ctaLabel": "Saiba mais",
    "ctaUrl": "https://www.aguasbelas.pe.gov.br/saude/influenza",
    "prioridadeOrdem": 100
  }
]
```

`tone`: `URGENTE | CAMPANHA | INFO | ATENCAO`.

**Filtros**: `ativo=true AND (expiraEm IS NULL OR expiraEm > now())`.
Ordenação: `prioridadeOrdem DESC, publicadoEm DESC`.

⚠️ `imagemUrl` e `ctaUrl` **HTTPS obrigatório** (Android bloqueia HTTP).

### 9.2 `GET /paciente/banners/:id`

**Response**: 1 banner. 404 se expirado/inativo/inexistente.

### 9.3 `POST /paciente/banners/:id/visto`

**Response**: `204`. **Idempotente**. Falha silenciosa no cliente.

UPSERT em `sms_banner_view(bannerId, pacienteId)`.

---

## 10. TFD do paciente

### 10.1 `GET /paciente/tfd/viagens`

**Response 200**: array de viagens futuras.

```json
[
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
]
```

**Filtros**: `dataPartida >= today` AND cidade paciente compatível.
Ordenação: `dataPartida ASC`.

### 10.2 `GET /paciente/tfd/viagens/:id`

**Response**: 1 viagem. 404 se inexistente.

### 10.3 `GET /paciente/tfd/solicitacoes`

**Response 200**: solicitações do paciente.

```json
[
  {
    "id": "uuid",
    "viagemId": "uuid",
    "status": "APROVADA",
    "prioridade": "PRIORITARIA",
    "criadaEm": "2026-05-24T11:00:00.000Z",
    "viagem": { /* TfdViagem embedado */ },
    "numeroAssento": "07",
    "justificativaPaciente": "Consulta cardio agendada",
    "motivoRecusa": null,
    "encaminhamentoId": "uuid",
    "encaminhamentoProtocolo": "UBS-2026-100137",
    "acompanhante": null,
    "aprovadaEm": "2026-05-26T08:00:00.000Z"
  }
]
```

`viagem` **embedado completo**. `status`: [§12.7](#127-tfdsolicitacaostatus).

### 10.4 `GET /paciente/tfd/solicitacoes/:id`

**Response**: 1 solicitação. 404 se de outro paciente.

### 10.5 `POST /paciente/tfd/solicitacoes`

**Request**:
```json
{
  "viagemId": "uuid",
  "encaminhamentoId": "uuid",
  "justificativa": "Consulta com cardiologista",
  "acompanhante": "João Souza (filho)"
}
```

**Response 201**: `TfdSolicitacao` com `status='AGUARDANDO'`, `prioridade=derivada`.

### 🚨 Regra CRÍTICA — derivação de prioridade NO SERVIDOR

App **NÃO envia** prioridade. Backend deriva:

```typescript
if (encaminhamentoId == null) return 'NORMAL';
const enc = await encaminhamentoRepo.findById(encaminhamentoId);
if (!enc || enc.paciente.cpf !== cpfPaciente) {
  throw ValidationError('ENC_NAO_ENCONTRADO');  // anti-enum
}
if (['URGENTE', 'EMERGENCIA'].includes(enc.prioridade)) return 'URGENTE';
return 'PRIORITARIA';
```

**Erros**:
| HTTP | code | Quando |
|---|---|---|
| 404 | `VIAGEM_NAO_ENCONTRADA` | viagemId inválida |
| 422 | `VALIDATION_ERROR` | `justificativa.length < 10` |
| 422 | `ENC_NAO_ENCONTRADO` | encaminhamento inválido ou de outro |
| 409 | `TFD_JA_TEM_SOLICITACAO` | já tem AGUARDANDO/APROVADA pra mesma viagem |
| 409 | `TFD_VIAGEM_ENCERRADA` | `dataPartida < now()` |
| 409 | `CONFLICT_NO_SEATS` | sem vagas (opcional) |

**Side effects**: criar com `AGUARDANDO`, **NÃO** decrementar `vagasOcupadas`.

### 10.6 `DELETE /paciente/tfd/solicitacoes/:id`

**Response**: `204`.

**Erros**:
- 404 `NOT_FOUND` (de outro paciente)
- 409 `CONFLICT` se `status != AGUARDANDO`

---

## 11. Push via ntfy.sh

App migrou de FCM para ntfy.sh self-hosted (sem Firebase).

### 11.1 Infra

Docker compose com container `binwiederhier/ntfy:v2.11`, reverse proxy via
Caddy em `ntfy.<dominio>`.

### 11.2 Token register

`POST /auth/paciente/registrar-dispositivo` ([§4.8](#48-post-authpacienteregistrar-dispositivo)).

### 11.3 Worker backend → ntfy

Toda criação de `NotificacaoPaciente` deve enfileirar push:

```typescript
await axios.post(`${NTFY_BASE_URL}/${token.endpoint}`, JSON.stringify({
  message: notif.corpo,
  meta: {
    tipo: 'ENCAMINHAMENTO',
    deepLink: `/encaminhamento/${notif.encaminhamentoId}`,
    notificacaoId: notif.id,
    encaminhamentoId: notif.encaminhamentoId,
  },
}), {
  headers: {
    'Title': notif.titulo,
    'Priority': '4',
    'Authorization': `Bearer ${NTFY_AUTH_TOKEN}`,
  },
});
```

App tem PushService que conecta WebSocket `wss://ntfy.<host>/<topic>/ws`,
recebe mensagens e exibe via `flutter_local_notifications`.

---

## 12. Enums canônicos

### 12.1 `EncaminhamentoStatus`

```
RASCUNHO                   Sua UBS está preparando
AGUARDANDO_REGULACAO       Enviado, aguardando análise
EM_ANALISE                 Em análise ativa
PENDENCIA_DOCUMENTO        Falta documento — paciente vai à UBS
APROVADO                   Aprovado, sem data ainda
AGUARDANDO_AGENDAMENTO     Aprovado, em fila de agendamento
AGENDADO                   Data marcada (com dataAgendamento populado)
REJEITADO                  Não aprovado (com motivoRejeicao)
CANCELADO                  Cancelado
CONCLUIDO                  Atendimento realizado
```

### 12.2 Prioridade clínica

```
ELETIVA | PRIORITARIA | URGENTE | EMERGENCIA
```

### 12.3 `EventoTimelineTipo`

```
CRIACAO | ANEXO | PENDENCIA | APROVACAO | AGENDAMENTO | REJEICAO | ATUALIZACAO
```

### 12.4 `AtendimentoTipo`

```
CONSULTA_MEDICA | ENFERMAGEM | VACINACAO | CURATIVO |
ODONTOLOGICO | PROCEDIMENTO | ACOLHIMENTO
```

(App aceita legados: `CONSULTA | EMERGENCIA | EXAME | RETORNO`)

### 12.5 `VacinacaoVia`

```
INTRAMUSCULAR | ORAL | SUBCUTANEA | INTRADERMICA | NASAL
```

### 12.6 `NotificacaoTipo`

App aceita qualquer string e mapeia visualmente. Tipos esperados:
```
ENCAMINHAMENTO_CRIADO
PENDENCIA_REGISTRADA
PENDENCIA_RESOLVIDA
APROVADO
AGENDADO
REJEITADO
RESPOSTA_SUS_DISPONIVEL
TFD_*
CAMPANHA | BANNER
ALERTA
SISTEMA
```

### 12.7 `TfdSolicitacaoStatus` + Prioridade

```
AGUARDANDO | APROVADA | RECUSADA | CANCELADA | EMBARCADA | CONCLUIDA

NORMAL | PRIORITARIA | URGENTE
```

### 12.8 `BannerTone`

```
URGENTE | CAMPANHA | INFO | ATENCAO
```

### 12.9 `ExameCategoria` + `ResultadoStatus`

```
LABORATORIAL | IMAGEM | FUNCIONAL | OUTROS

NORMAL | ALTERADO | CRITICO | PENDENTE
```

### 12.10 `AnexoTipo`

```
PDF | IMG | DOC    (derivado do MIME — não dos enums Face 1/2)
```

---

## 13. Fluxos críticos

### 13.1 🚨 Senha provisória (primeiro acesso)

Sequência:
1. **Backend** auto-cria conta na consolidação do 1º encaminhamento da UBS:
   ```
   cpf, nome, senhaHash = bcrypt(cpf-digitos),
   ativo = true, senhaProvisoria = true
   ```
2. App: login com `cpf + senha=cpf-digitos`
3. Backend: response `paciente.senhaProvisoria=true`
4. App: router força redirect pra `/perfil/trocar-senha`
5. App: tela bloqueante (sem botão X, PopScope bloqueia back)
6. App: chama `POST /auth/paciente/trocar-senha`
7. Backend: zera `senhaProvisoria=false`
8. App: chama `GET /me` confirmando
9. App: router libera, navega pra `/home`

⚠️ Sem o campo `senhaProvisoria` no login + me, o fluxo quebra.

### 13.2 🚨 Refresh transparente (401 → refresh → retry)

App tem interceptor Dio com single-flight:
1. Request → 401
2. Tem refresh token? → tenta `POST /auth/paciente/refresh`
3. Sucesso → retry original com novo access (marcado `_retried`)
4. Falha → derruba sessão + vai pra `/login`

Backend deve:
- Garantir `/auth/paciente/refresh` aceita sem `Authorization` header
- Rotacionar refresh a cada chamada (uso único)
- Detectar replay (`rotatedFrom` apontando pra sessão já rotacionada) → revoga toda a cadeia

### 13.3 🚨 Anti-enumeration global

Toda rota `/paciente/:recurso/:id` deve:
- Filtrar por `cpf = req.paciente.cpf`
- Retornar **404 `NOT_FOUND`** quando o recurso é de outro paciente
- **Nunca 403** (vaza existência)

### 13.4 🚨 Backend não pagina (universo pequeno)

App não envia `?page=` nem `?limit=`. Backend pode limitar a 100 itens.
Para listas grandes (atendimentos), aceitar opcional `?cursor=...`
(app já suporta no dossiê).

---

## 14. Checklist final

Use isso pra validar o backend contra esta doc.

### 14.1 Configuração ✅/❌

- [ ] Backend rodando em `http://localhost:3333/v1`
- [ ] Prefixo `/auth/paciente/*` (ou alias para o que estiver lá)
- [ ] Prefixo `/paciente/*` (ou alias)
- [ ] Shape de erro envelopado `{ error: { code, message, details } }`
- [ ] Suporte CORS para origem do app (não-issue em mobile)

### 14.2 Auth — 8 endpoints

- [ ] `POST /auth/paciente/login` retorna `{ accessToken, refreshToken, expiresAt, paciente }`
- [ ] `paciente.senhaProvisoria` é boolean (não omitido)
- [ ] `paciente.cpfFormatado` presente
- [ ] `POST /auth/paciente/refresh` rotaciona e detecta replay
- [ ] `POST /auth/paciente/logout` 204
- [ ] `GET /auth/paciente/me` retorna shape idêntico ao paciente do login
- [ ] `POST /auth/paciente/trocar-senha` zera `senhaProvisoria`
- [ ] `POST /auth/paciente/esqueci-senha` retorna 204 sempre (anti-enum)
- [ ] `POST /auth/paciente/redefinir-senha` com TTL 30min + uso único
- [ ] `POST /auth/paciente/registrar-dispositivo` aceita `{fcmToken, plataforma}`

### 14.3 Encaminhamentos — 5 endpoints

- [ ] `GET /paciente/encaminhamentos` array
- [ ] `GET /paciente/encaminhamentos/ativo` retorna **`null`** literal (não 404)
- [ ] `GET /paciente/encaminhamentos/:id` 404 se de outro
- [ ] `GET /paciente/encaminhamentos/:id/anexos` array
- [ ] `GET /paciente/encaminhamentos/:id/timeline` array ordenada `em ASC`
- [ ] Campo `senhaProvisoria` populado corretamente
- [ ] Status enum match com [§12.1](#121-encaminhamentostatus)
- [ ] `dataAgendamento` ISO 8601 quando `AGENDADO`
- [ ] Audit CFM em todas leituras

### 14.4 Notificações — 4 endpoints

- [ ] `GET /paciente/notificacoes` array
- [ ] `GET /paciente/notificacoes/contagem-nao-lidas` retorna `{count}` ou `{naoLidas}`
- [ ] `POST .../marcar-lida` idempotente
- [ ] `POST .../marcar-todas-lidas` 204

### 14.5 Dossiê — 4 endpoints

- [ ] `GET /paciente/dossie/resumo` com `totalExames` (v0.14+)
- [ ] `GET /paciente/dossie/atendimentos` com enum [§12.4](#124-atendimentotipo)
- [ ] `GET /paciente/dossie/vacinacoes` com `via` e `aplicadorNome`
- [ ] `GET /paciente/dossie/exames` com `categoria` e `resultadoStatus`
- [ ] Aceita `{items, nextCursor}` ou array direto
- [ ] Audit CFM 20 anos

### 14.6 UBS — 1 endpoint

- [ ] `GET /paciente/ubs/minha` retorna 200 ou 404 `PACIENTE_SEM_UBS`
- [ ] `whatsapp` é dígitos com DDI (`5575998765432`)
- [ ] Auto-bond na consolidação do 1º encaminhamento

### 14.7 Banners — 3 endpoints

- [ ] `GET /paciente/banners` filtrado por prefeitura + ativo + não expirado
- [ ] `GET /paciente/banners/:id` 404 se expirado
- [ ] `POST .../visto` idempotente
- [ ] `imagemUrl` e `ctaUrl` HTTPS obrigatório

### 14.8 TFD — 6 endpoints

- [ ] `GET /paciente/tfd/viagens` array futuras
- [ ] `GET /paciente/tfd/viagens/:id` 404
- [ ] `GET /paciente/tfd/solicitacoes` com `viagem` embedado
- [ ] `GET /paciente/tfd/solicitacoes/:id` 404 se de outro
- [ ] `POST /paciente/tfd/solicitacoes`: **prioridade derivada no servidor**
- [ ] `DELETE /paciente/tfd/solicitacoes/:id`: 409 se não AGUARDANDO
- [ ] Hash chain TFD em todas operações

### 14.9 Push ntfy

- [ ] Container ntfy rodando + Caddy reverse proxy
- [ ] Tabela `paciente_push_token` com UPSERT por endpoint
- [ ] Worker `notif criada → publish ntfy` (com fallback email)
- [ ] Auth do publisher backend → ntfy via `NTFY_AUTH_TOKEN`

### 14.10 Gotchas que travam o app

- [ ] Datas ISO 8601 UTC (nunca `DD/MM/YYYY`)
- [ ] `null` literal em vez de objeto vazio em `/encaminhamentos/ativo`
- [ ] 404 (não 403) para recurso de outro paciente
- [ ] CPF normalizado pra dígitos no banco
- [ ] WhatsApp em UBS com DDI dígitos
- [ ] HTTPS em todas URLs externas (banners, fotos)

---

## Verificação rápida via curl

```bash
TOKEN=$(curl -sX POST http://localhost:3333/v1/auth/paciente/login \
  -H 'Content-Type: application/json' \
  -d '{"cpf":"12345678909","senha":"12345678909"}' | jq -r .accessToken)

# Validar shape do me
curl -sH "Authorization: Bearer $TOKEN" \
  http://localhost:3333/v1/auth/paciente/me | jq

# Deve ter:  senhaProvisoria, cpfFormatado, ubsVinculadaId, etc.

# Encaminhamentos
curl -sH "Authorization: Bearer $TOKEN" \
  http://localhost:3333/v1/paciente/encaminhamentos | jq '.[0] | keys'

# Dossiê
curl -sH "Authorization: Bearer $TOKEN" \
  http://localhost:3333/v1/paciente/dossie/resumo | jq

# UBS
curl -sH "Authorization: Bearer $TOKEN" \
  http://localhost:3333/v1/paciente/ubs/minha | jq

# Notificações count
curl -sH "Authorization: Bearer $TOKEN" \
  http://localhost:3333/v1/paciente/notificacoes/contagem-nao-lidas | jq
```

---

**FIM.** Última auditoria: 2026-05-28 contra app `0.1.0`.
Para o que **está implementado** no backend, ver `backend/docs/PACIENTE_APP_API.md`.
Para o histórico de releases, ver `BACKEND_PENDENTES.md` (já fechado).
