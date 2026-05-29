# UNISISM-Paciente — Contrato de Backend

Este documento é a **fonte da verdade** dos endpoints que o app Flutter do paciente espera consumir. Toda integração entre app e backend deve respeitar exatamente:

- nomes de campos (camelCase no JSON),
- chaves canônicas de status / prioridade / tipo,
- formato de datas (ISO 8601 com timezone),
- formato de erro padronizado,
- regras de autorização (row-level — paciente só enxerga o **próprio** recurso).

> **Base URL esperada (dev):** `http://localhost:3000/api/v1`
> **Base URL esperada (prod):** `https://api.unisism.muni.gov.br/v1`
> O app injeta via `--dart-define=API_BASE_URL=...`.

---

## Sumário

1. [Convenções gerais](#1-convenções-gerais)
2. [Auth do paciente](#2-auth-do-paciente)
3. [Encaminhamentos](#3-encaminhamentos)
4. [Dossiê médico](#4-dossiê-médico)
5. [TFD — Tratamento Fora de Domicílio](#5-tfd--tratamento-fora-de-domicílio)
6. [Banners da Secretaria](#6-banners-da-secretaria)
7. [Notificações](#7-notificações)
8. [Push notifications — payload FCM](#8-push-notifications--payload-fcm)
9. [Enums canônicos (status, prioridade, tipos)](#9-enums-canônicos)
10. [Checklist de implementação (backend)](#10-checklist-de-implementação)

---

## 1. Convenções gerais

### 1.1. Autenticação

- Header obrigatório em **todas** as rotas autenticadas:
  `Authorization: Bearer <accessToken>`
- Access token JWT. Sugerido `exp = 1h`.
- Refresh token rotativo. Sugerido `exp = 30d`. O app guarda em `flutter_secure_storage`.
- Quando o backend retorna **401**, o app:
  1. Limpa tokens locais
  2. Tenta `POST /auth/paciente/refresh` (se ainda tiver refresh válido)
  3. Falhou? Redireciona pra `/login`.
- O app envia **headers extras** que o backend pode usar pra telemetria:
  - `X-Client-Platform: flutter-mobile`
  - `X-Client-Version: 0.1.0`

### 1.2. Formato de resposta

JSON em todas as respostas. Datas em ISO 8601 com timezone (`2026-05-27T10:17:00-03:00`).

### 1.3. Formato de erro padronizado

Todos os endpoints retornam erro neste shape:

```json
{
  "code": "AUTH_INVALID_CREDENTIALS",
  "message": "CPF ou senha inválidos.",
  "details": { "campo": "valor opcional" }
}
```

Codes que o app já trata:

| HTTP | Code sugerido | Exibição no app |
|---|---|---|
| 400 | `VALIDATION_ERROR` | "Alguns campos não foram preenchidos corretamente." |
| 401 | `AUTH_INVALID_CREDENTIALS` / `TOKEN_EXPIRED` | "Sua sessão expirou. Entre novamente." |
| 403 | `FORBIDDEN_RESOURCE` | "Você não tem permissão." |
| 404 | `NOT_FOUND` | "Não encontramos o que você procurou." |
| 409 | `CONFLICT` | "Esta ação entra em conflito com algo já feito." |
| 422 | `VALIDATION_ERROR` | "Alguns campos não foram preenchidos corretamente." |
| 429 | `RATE_LIMIT` | "Muitas tentativas. Espere alguns segundos." |
| 5xx | `INTERNAL_ERROR` | "O servidor está com problemas." |

### 1.4. Paginação

Para listagens longas (atendimentos, notificações, viagens passadas), use cursor-based:

```
GET /paciente/notificacoes?cursor=eyJpZCI6...&limit=20
```

Resposta:

```json
{
  "items": [ /* … */ ],
  "nextCursor": "eyJpZCI6..." | null
}
```

> **MVP**: pode entregar todos os recursos sem paginação. Manter contrato pronto pra adicionar.

### 1.5. Authorization & row-level security

**Regra dura**: o paciente só pode acessar recursos **vinculados a ele mesmo** (encaminhamento dele, dossiê dele, etc.). O backend deve validar `pacienteId` extraído do JWT em **toda** chamada — nunca confiar em parâmetro de URL.

| Tipo de acesso | Quem pode |
|---|---|
| GET `/paciente/encaminhamentos/:id` | Apenas se `encaminhamento.pacienteId === jwt.pacienteId` |
| GET `/paciente/dossie/*` | Apenas dados onde `pacienteId === jwt.pacienteId` |
| POST `/paciente/tfd/solicitacoes` | Pode criar; backend deriva `pacienteId` do JWT (não confiar em body) |

### 1.6. Rate limit

Endpoints sensíveis (login, esqueci-senha) devem ter rate limit por IP **e** por CPF:

| Rota | Limite sugerido |
|---|---|
| `POST /auth/paciente/login` | 5 tentativas / 15 min / CPF |
| `POST /auth/paciente/esqueci-senha` | 3 tentativas / hora / CPF |
| `POST /auth/paciente/redefinir-senha` | 5 tentativas / hora / token |

---

## 2. Auth do paciente

Modelo: paciente identifica-se com **CPF (sem máscara, só dígitos)** + **senha** definida pela UBS no cadastro / autocadastro futuro. Senha hashada com argon2id ou bcrypt cost 12+.

### 2.1. `POST /auth/paciente/login`

**Request**
```json
{ "cpf": "12345678909", "senha": "..." }
```

**Response 200**
```json
{
  "accessToken": "eyJhbGciOi...",
  "refreshToken": "eyJhbGciOi...",
  "expiresAt": "2026-05-27T11:17:00-03:00",
  "paciente": {
    "id": "pac-001",
    "nome": "Maria Aparecida Souza",
    "cpf": "123.456.789-09",
    "dataNascimento": "1962-08-14",
    "cartaoSus": "700123456789012",
    "email": null,
    "telefone": "(75) 99876-5432",
    "fotoUrl": null,
    "ubsVinculadaId": "ubs-031",
    "ubsVinculadaNome": "UBS Centro - Dr. João Mendes"
  }
}
```

**Erros**:
- `401 AUTH_INVALID_CREDENTIALS` — CPF/senha inválidos.
- `403 AUTH_ACCOUNT_LOCKED` — bloqueado por excesso de tentativas.

### 2.2. `POST /auth/paciente/refresh`

**Request**
```json
{ "refreshToken": "..." }
```

**Response 200** — mesma estrutura do `login`. **Refresh é rotativo** — sempre retornar refreshToken novo e invalidar o anterior.

### 2.3. `POST /auth/paciente/logout`
Auth obrigatória. Invalida `accessToken` (lista de revogação ou jti curto + Redis). Retorna **204**.

### 2.4. `GET /auth/paciente/me`
Auth obrigatória. Retorna **Paciente** (mesmo objeto do login).

### 2.5. `POST /auth/paciente/esqueci-senha`

```json
{ "cpf": "12345678909" }
```
**204** mesmo quando o CPF não existe (anti-enumeration). Envia SMS / email pro contato cadastrado com link/`token` válido por 30 min.

### 2.6. `POST /auth/paciente/redefinir-senha`

```json
{ "token": "abc...", "novaSenha": "..." }
```
**204**. Invalida o token após uso. Política de senha: 6+ caracteres, ao menos 1 número.

### 2.7. `POST /auth/paciente/registrar-dispositivo`
Auth obrigatória. Registra token FCM no banco vinculado ao paciente.

```json
{ "fcmToken": "fGz...", "plataforma": "android" | "iOS" | "macOS" }
```
**204**. Idempotente — se o token já existir, atualiza `lastSeenAt`. Suporta múltiplos devices por paciente.

---

## 3. Encaminhamentos

Visão **paciente** dos encaminhamentos. Subset do que UBS/SMS veem (sem detalhes operacionais sensíveis).

### 3.1. `GET /paciente/encaminhamentos`
Lista TODOS os encaminhamentos do paciente, ordenados por `criadoEm` desc.

Resposta: `Encaminhamento[]`.

### 3.2. `GET /paciente/encaminhamentos/ativo`
Retorna o **encaminhamento em curso** (não-CONCLUIDO/REJEITADO/CANCELADO) mais recente. `null` se não houver. Usado na home.

### 3.3. `GET /paciente/encaminhamentos/:id`
Retorna um **Encaminhamento** específico.

**Encaminhamento shape**:
```json
{
  "id": "enc-100137",
  "protocolo": "UBS-2026-100137",
  "status": "AGUARDANDO_AGENDAMENTO",
  "prioridade": "PRIORITARIA",
  "especialidade": "Cardiologia",
  "cid10": "I10",
  "cid10Descricao": "Hipertensão essencial",
  "justificativaResumida": "Paciente apresenta hipertensão de difícil controle…",
  "ubsOrigemNome": "UBS Centro - Dr. João Mendes",
  "medicoSolicitanteNome": "Dr. Ricardo Lima — CRM/BA 12345",
  "dataAgendamento": "2026-06-08T09:30:00-03:00",
  "localAgendamento": "Hospital Regional - Ambulatório 3",
  "observacoesRegulacao": null,
  "motivoRejeicao": null,
  "pendenciasAbertas": 0,
  "podeSolicitarTfd": true,
  "criadoEm": "2026-05-19T08:14:00-03:00",
  "atualizadoEm": "2026-05-27T04:17:00-03:00"
}
```

Notas:
- `justificativaResumida` deve esconder informações sensíveis cruas — backend pode resumir/sanitizar.
- `podeSolicitarTfd = true` quando: status ∈ {AGENDADO, AGUARDANDO_AGENDAMENTO, APROVADO} **AND** destino é em outra cidade.

### 3.4. `GET /paciente/encaminhamentos/:id/anexos`
Lista anexos do encaminhamento.

**Anexo shape**:
```json
{
  "id": "anx-1",
  "nome": "Solicitacao_Medica_Cardiologia.pdf",
  "tipo": "application/pdf",
  "tamanhoBytes": 248310,
  "criadoEm": "2026-05-19T09:00:00-03:00",
  "url": null
}
```

`url` pode ser preenchida com URL pré-assinada se preferir CDN; o app também aceita download via endpoint do próximo item.

### 3.5. `GET /paciente/encaminhamentos/:id/anexos/:anexoId/download`
Download binário. Headers:
- `Content-Type: application/pdf` (ou apropriado)
- `Content-Disposition: attachment; filename="Solicitacao_Medica_Cardiologia.pdf"`

**Importante:** stream com authorization Bearer; **não** servir via URL pública. Resposta 200 → binário.

### 3.6. `GET /paciente/encaminhamentos/:id/timeline`
Eventos cronológicos, ordenados ascendente por `em`.

**EventoTimeline shape**:
```json
{
  "id": "ev-5",
  "tipo": "AGENDAMENTO",
  "titulo": "Consulta marcada!",
  "descricao": "Sua consulta foi marcada no Hospital Regional...",
  "autorNome": "Daniel Rocha",
  "autorPapel": "Agendamento SMS",
  "em": "2026-05-27T04:17:00-03:00"
}
```

`tipo ∈ {CRIACAO, ANEXO, PENDENCIA, APROVACAO, AGENDAMENTO, REJEICAO, ATUALIZACAO}`. Backend pode adicionar tipos — app cai em "ATUALIZACAO" visual se for desconhecido.

---

## 4. Dossiê médico

Histórico clínico **somente leitura** do paciente.

### 4.1. `GET /paciente/dossie/resumo`

```json
{
  "totalEncaminhamentos": 4,
  "totalAtendimentos": 21,
  "totalVacinas": 14,
  "tipoSanguineo": "O+",
  "alergias": ["Dipirona", "Iodo (contraste)"],
  "condicoesCronicas": ["Hipertensão arterial", "Diabetes tipo 2"],
  "medicamentosUsoContinuo": ["Losartana 50mg", "Metformina 850mg", "AAS 100mg"]
}
```

### 4.2. `GET /paciente/dossie/atendimentos`
Lista `Atendimento[]` ordenado por `data` desc.

```json
{
  "id": "at-1",
  "data": "2026-05-07T10:30:00-03:00",
  "tipo": "CONSULTA",
  "localNome": "UBS Centro",
  "profissionalNome": "Dr. Ricardo Lima",
  "profissionalEspecialidade": "Clínica Geral",
  "queixaPrincipal": "Pressão alta com dor de cabeça frequente",
  "cid10": "I10",
  "cid10Descricao": "Hipertensão essencial",
  "condutaResumida": "Encaminhar à Cardiologia..."
}
```

`tipo ∈ {CONSULTA, EMERGENCIA, EXAME, VACINACAO, RETORNO}`.

### 4.3. `GET /paciente/dossie/vacinacoes`
Lista `Vacinacao[]` ordenado por `aplicadaEm` desc.

```json
{
  "id": "vc-1",
  "vacina": "Influenza 2026",
  "dose": "Dose anual",
  "aplicadaEm": "2026-04-12",
  "lote": "INF-2026-A",
  "localAplicacao": "UBS Centro"
}
```

### 4.4. `GET /paciente/dossie/exames`
Lista `Exame[]` ordenado por `realizadoEm` desc.

```json
{
  "id": "ex-1",
  "nome": "Hemograma completo",
  "realizadoEm": "2026-03-28",
  "solicitanteNome": "Dr. Ricardo Lima",
  "resultadoResumo": "Dentro dos valores de referência.",
  "alterado": false,
  "urlLaudo": null
}
```

`resultadoResumo` deve ser **escrito pra paciente leigo** — não copiar diretamente o laudo técnico. `urlLaudo` é opcional; se fornecido, o app abre via WebView/share.

---

## 5. TFD — Tratamento Fora de Domicílio

Domínio **novo** — provavelmente o backend não tem ainda. Modelo "blablacar municipal": SMS programa viagens em vans / micro-ônibus para destinos onde há consultas/exames; pacientes solicitam vaga vinculada ao seu encaminhamento; regulação aprova/recusa; ao aprovar, retorna número do assento.

### 5.1. Entidades

**TfdViagem** (programada pela SMS — paciente só lê):
```json
{
  "id": "vg-1",
  "destinoCidade": "Águas Belas",
  "destinoUf": "BA",
  "destinoLocal": "Hospital Regional - Ambulatório Cardiologia",
  "dataPartida": "2026-06-08",
  "horaPartida": "05:30",
  "localEmbarque": "Praça Central - UBS Centro",
  "vagasTotal": 14,
  "vagasOcupadas": 9,
  "veiculoDescricao": "Van Iveco Daily - Branca",
  "veiculoPlaca": "OUW-3A12",
  "observacoes": "Levar documento com foto, cartão SUS e a receita atual.",
  "motoristaNome": "José Carlos Andrade"
}
```

**TfdSolicitacao** (criada pelo paciente):
```json
{
  "id": "sol-1",
  "viagemId": "vg-2",
  "status": "APROVADA",
  "prioridade": "PRIORITARIA",
  "criadaEm": "2026-05-24T15:00:00-03:00",
  "viagem": { /* TfdViagem embedado */ },
  "numeroAssento": "07",
  "justificativaPaciente": "Consulta de retorno na oncologia, viagem essencial.",
  "motivoRecusa": null,
  "encaminhamentoProtocolo": "UBS-2026-099833",
  "aprovadaEm": "2026-05-26T14:17:00-03:00",
  "acompanhante": null
}
```

`status ∈ {AGUARDANDO, APROVADA, RECUSADA, CANCELADA, EMBARCADA, CONCLUIDA}`.
`prioridade ∈ {NORMAL, PRIORITARIA, URGENTE}`.

### 5.2.bis Regra de prioridade

- **NORMAL**: solicitação sem encaminhamento anexado. Analisada pela ordem de chegada na fila normal.
- **PRIORITARIA**: o paciente anexou um encaminhamento ativo (não-concluído, não-rejeitado). Backend deve **derivar** automaticamente — não confiar no campo enviado.
- **URGENTE**: definida pela Regulação SMS (não pelo paciente) com base na gravidade clínica do encaminhamento anexado (ex.: prioridade `URGENTE` ou `EMERGENCIA`).

### 5.2. Endpoints

| Método | Rota | Descrição |
|---|---|---|
| GET | `/paciente/tfd/viagens` | Viagens futuras, com vaga ou não. Ordenadas por `dataPartida` asc. |
| GET | `/paciente/tfd/viagens/:id` | Detalhe de 1 viagem. |
| GET | `/paciente/tfd/solicitacoes` | **Suas** solicitações (ordenadas desc por `criadaEm`). |
| GET | `/paciente/tfd/solicitacoes/:id` | Detalhe de uma solicitação sua. |
| POST | `/paciente/tfd/solicitacoes` | Criar uma solicitação. **Body**: `{ viagemId, encaminhamentoId?, justificativa, acompanhante? }`. `encaminhamentoId` é **opcional** — sem ele a prioridade fica `NORMAL`; com ele e válido, o backend deriva `prioridade=PRIORITARIA`. Backend valida `encaminhamento.pacienteId === jwt.pacienteId` quando enviado. Retorna a solicitação com `status=AGUARDANDO` e `prioridade` calculada. |
| DELETE | `/paciente/tfd/solicitacoes/:id` | Cancelar (somente se `status === AGUARDANDO`). 204. |

### 5.3. Regras de negócio críticas

- Paciente **não** pode ter 2 solicitações `AGUARDANDO|APROVADA` para a **mesma viagem**.
- Ao aprovar, o backend deve **alocar atomicamente** (`vagasOcupadas++`). Se passar de `vagasTotal`, recusa com `409 CONFLICT_NO_SEATS`.
- `numeroAssento` é gerado pelo backend (sequencial 01..N por viagem) na aprovação.
- Cancelar uma `APROVADA` libera vaga (`vagasOcupadas--`).
- Quando o status muda, disparar **push notification** ao paciente (ver §8).

---

## 6. Banners da Secretaria

CMS leve da SMS pra publicar campanhas / alertas no app. Paciente só lê.

### 6.1. `GET /paciente/banners`
Lista banners ativos (`expiraEm > now() OR expiraEm IS NULL`), ordenados por `prioridadeOrdem` desc + `publicadoEm` desc.

```json
{
  "id": "bn-2",
  "titulo": "Alerta: surto de dengue na região",
  "corpo": "Foi registrado aumento de casos…",
  "tone": "URGENTE",
  "publicadoEm": "2026-05-26T19:17:00-03:00",
  "imagemUrl": "https://cdn.unisism.muni.gov.br/banners/bn-2.jpg",
  "ctaLabel": "Saber mais",
  "ctaUrl": "https://saude.muni.gov.br/dengue",
  "expiraEm": "2026-06-15T23:59:59-03:00",
  "prioridadeOrdem": 100
}
```

`tone ∈ {URGENTE, CAMPANHA, INFO, ATENCAO}`.

### 6.2. `POST /paciente/banners/:id/visto`
Marcar visualização (telemetria) — 204. Best-effort, o app não bloqueia se falhar.

---

## 7. Notificações

Inbox in-app de tudo que aconteceu pro paciente.

### 7.1. `GET /paciente/notificacoes`
Lista `Notificacao[]` ordenada desc por `em`.

```json
{
  "id": "nt-1",
  "tipo": "ENCAMINHAMENTO",
  "titulo": "Sua consulta foi marcada!",
  "corpo": "Cardiologia no Hospital Regional. Toque aqui para ver detalhes.",
  "em": "2026-05-27T04:17:00-03:00",
  "lida": false,
  "tone": "SUCCESS",
  "deepLink": "/encaminhamento/enc-100137",
  "encaminhamentoId": "enc-100137",
  "tfdSolicitacaoId": null
}
```

`tipo ∈ {ENCAMINHAMENTO, TFD, CAMPANHA, ALERTA, SISTEMA}`
`tone ∈ {INFO, SUCCESS, WARNING, CRITICAL}`
`deepLink` deve ser uma **rota interna** do app (`/encaminhamento/:id`, `/tfd/solicitacao/:id`, `/dossie/exames` etc.).

### 7.2. `GET /paciente/notificacoes/contagem-nao-lidas`
```json
{ "count": 2 }
```
Chamado pelo app a cada navegação pra atualizar o badge da bottom nav. **Deve ser barato** (cache 30s OK).

### 7.3. `POST /paciente/notificacoes/:id/marcar-lida` → 204
### 7.4. `POST /paciente/notificacoes/marcar-todas-lidas` → 204

---

## 8. Push notifications — payload FCM

Quando algo relevante muda (status de encaminhamento, aprovação TFD, novo banner urgente), backend envia push via FCM v1 API pra todos os tokens do paciente.

### 8.1. Payload obrigatório

```json
{
  "notification": {
    "title": "Sua consulta foi marcada!",
    "body": "Cardiologia · 08/06 · 09:30"
  },
  "data": {
    "tipo": "ENCAMINHAMENTO",
    "deepLink": "/encaminhamento/enc-100137",
    "notificacaoId": "nt-1"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "unisism_paciente_default",
      "color": "#1E3A8A"
    }
  },
  "apns": {
    "headers": { "apns-priority": "10" },
    "payload": { "aps": { "sound": "default", "badge": 1 } }
  }
}
```

Campos obrigatórios em `data`:
- `tipo` — ENCAMINHAMENTO / TFD / CAMPANHA / ALERTA / SISTEMA
- `deepLink` — rota interna que o app abrirá ao tocar

### 8.2. Quando disparar

| Evento | Push? | Notificacao no inbox? |
|---|---|---|
| Status do encaminhamento muda | ✅ | ✅ |
| Pendência aberta pela Regulação | ✅ | ✅ |
| Encaminhamento aprovado | ✅ | ✅ |
| Consulta agendada | ✅ | ✅ |
| Solicitação TFD aprovada/recusada | ✅ | ✅ |
| Banner URGENTE publicado | ✅ (broadcast) | ✅ |
| Banner CAMPANHA publicado | ❌ (só inbox) | ✅ |
| Notas internas (UBS↔SMS) | ❌ | ❌ |

### 8.3. Token lifecycle

- App registra token via `POST /auth/paciente/registrar-dispositivo` no login e em cada refresh do FCM.
- Quando um envio FCM retornar `UNREGISTERED` / `INVALID_ARGUMENT`, o backend deve **remover o token** da base.

---

## 9. Enums canônicos

Os enums abaixo são compartilhados com as Faces UBS e SMS. **Sob hipótese alguma renomear** sem migração coordenada.

### 9.1. EncaminhamentoStatus

`RASCUNHO`, `AGUARDANDO_REGULACAO`, `PENDENCIA_DOCUMENTO`, `EM_ANALISE`, `AGUARDANDO_AGENDAMENTO`, `AGENDADO`, `APROVADO`, `REJEITADO`, `CANCELADO`, `CONCLUIDO`.

### 9.2. Prioridade

`ELETIVA`, `PRIORITARIA`, `URGENTE`, `EMERGENCIA`.

### 9.3. EventoTimelineTipo

`CRIACAO`, `ANEXO`, `PENDENCIA`, `APROVACAO`, `AGENDAMENTO`, `REJEICAO`, `ATUALIZACAO`.

### 9.4. AtendimentoTipo

`CONSULTA`, `EMERGENCIA`, `EXAME`, `VACINACAO`, `RETORNO`.

### 9.5. TfdSolicitacaoStatus

`AGUARDANDO`, `APROVADA`, `RECUSADA`, `CANCELADA`, `EMBARCADA`, `CONCLUIDA`.

### 9.5.bis TfdSolicitacaoPrioridade

`NORMAL`, `PRIORITARIA`, `URGENTE`.

### 9.6. BannerTone

`URGENTE`, `CAMPANHA`, `INFO`, `ATENCAO`.

### 9.7. NotificacaoTipo

`ENCAMINHAMENTO`, `TFD`, `CAMPANHA`, `ALERTA`, `SISTEMA`.

### 9.8. NotificacaoTone

`INFO`, `SUCCESS`, `WARNING`, `CRITICAL`.

---

## 10. Checklist de implementação

Sugestão de ordem pra desbloquear o app:

### Fase 1 — Login funcional (libera tudo)
- [ ] `POST /auth/paciente/login`
- [ ] `POST /auth/paciente/refresh`
- [ ] `GET /auth/paciente/me`
- [ ] Hash de senha com argon2id/bcrypt
- [ ] JWT com `pacienteId`, `exp`
- [ ] Rate limit por CPF no login

### Fase 2 — Encaminhamento end-to-end
- [ ] `GET /paciente/encaminhamentos`
- [ ] `GET /paciente/encaminhamentos/ativo`
- [ ] `GET /paciente/encaminhamentos/:id`
- [ ] `GET /paciente/encaminhamentos/:id/anexos`
- [ ] `GET /paciente/encaminhamentos/:id/anexos/:id/download`
- [ ] `GET /paciente/encaminhamentos/:id/timeline`
- [ ] Row-level security garantida (testes!)

### Fase 3 — Dossiê
- [ ] `GET /paciente/dossie/resumo`
- [ ] `GET /paciente/dossie/atendimentos`
- [ ] `GET /paciente/dossie/vacinacoes`
- [ ] `GET /paciente/dossie/exames`

### Fase 4 — Push + Notificações in-app
- [ ] Tabela `paciente_dispositivos (pacienteId, fcmToken, plataforma, lastSeenAt)`
- [ ] `POST /auth/paciente/registrar-dispositivo`
- [ ] Listener de eventos do encaminhamento → cria registro em `notificacoes` + dispara FCM
- [ ] `GET /paciente/notificacoes`
- [ ] `GET /paciente/notificacoes/contagem-nao-lidas`
- [ ] `POST /paciente/notificacoes/:id/marcar-lida`
- [ ] `POST /paciente/notificacoes/marcar-todas-lidas`

### Fase 5 — Banners
- [ ] CRUD admin na Face SMS (separado deste app)
- [ ] `GET /paciente/banners`
- [ ] `POST /paciente/banners/:id/visto`

### Fase 6 — TFD (domínio novo, maior esforço)
- [ ] Modelagem `tfd_viagens`, `tfd_solicitacoes` no Prisma
- [ ] CRUD admin na Face SMS (separado)
- [ ] `GET /paciente/tfd/viagens`
- [ ] `GET /paciente/tfd/viagens/:id`
- [ ] `GET /paciente/tfd/solicitacoes`
- [ ] `GET /paciente/tfd/solicitacoes/:id`
- [ ] `POST /paciente/tfd/solicitacoes`
- [ ] `DELETE /paciente/tfd/solicitacoes/:id`
- [ ] Alocação atômica de assento
- [ ] Aprovação/recusa pela SMS (endpoint na Face 2, fora deste contrato)

### Fase 7 — Recuperação de senha
- [ ] `POST /auth/paciente/esqueci-senha` (SMS/email)
- [ ] `POST /auth/paciente/redefinir-senha`

### Smoke tests recomendados (E2E)
- [ ] Login com CPF/senha válida → access + refresh token + Paciente
- [ ] Login com CPF certo + senha errada → 401 com `code: AUTH_INVALID_CREDENTIALS`
- [ ] Paciente A tenta acessar encaminhamento do paciente B → 403/404
- [ ] Refresh com refresh expirado → 401
- [ ] FCM token registrado aparece em `paciente_dispositivos`
- [ ] Mudança de status do encaminhamento dispara push + cria `notificacao`
- [ ] Aprovação TFD aloca atomicamente sob concorrência
