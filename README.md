# UNISISM Paciente

App Flutter do **paciente** do ecossistema UNISISM — terceira Face (cidadão) do sistema. Acompanhamento de encaminhamentos médicos, dossiê de saúde, solicitação de vaga no TFD, banners da Secretaria e notificações push.

> Faces relacionadas: UBS (Svelte) em `../unisism-ubs/frontend` · SMS/Regulação (Svelte, planejada) · Backend Node/TS compartilhado em `../unisism-ubs/backend`.

---

## 1. Requisitos

- Flutter `3.41.x` (canal stable)
- Dart `3.11+`
- Android Studio / Xcode pra rodar em device
- Backend UNISISM disponível em `http://localhost:3000/api/v1` (ou rodar com mocks — ver §4)

---

## 2. Setup

```bash
flutter pub get
flutter run  # com mocks habilitados por padrão
```

Pra rodar contra backend real:

```bash
flutter run --dart-define=USE_MOCK=false \
            --dart-define=API_BASE_URL=https://api.unisism.muni.gov.br/v1
```

### Push notifications (opcional)

Pra ativar push remoto, adicionar:
- Android: `android/app/google-services.json` + plugin Gradle
- iOS: `ios/Runner/GoogleService-Info.plist` + APNs cert no Firebase Console

Sem esses arquivos, o app **roda normalmente** — apenas o push remoto é desabilitado (notificações locais continuam funcionando).

---

## 3. Estrutura

```
lib/
├── main.dart                                 ← entrypoint, wire de auth+push+router
├── core/
│   ├── constants/app_constants.dart          ← URLs, flags, chaves de storage
│   ├── errors/api_exception.dart             ← tipo de erro tipado
│   ├── router/app_router.dart                ← go_router + auth guard
│   ├── services/push_service.dart            ← FCM + flutter_local_notifications
│   └── theme/                                ← tokens (cores, type, spacing, theme)
├── data/
│   ├── api/api_client.dart                   ← Dio singleton + interceptors
│   ├── models/                               ← entidades (Paciente, Encaminhamento, …)
│   └── repositories/
│       ├── *_repository.dart                 ← contrato + Http impl + Mock impl
│       └── mock/mock_seed.dart               ← dados demo realistas
├── providers/                                ← Riverpod providers + controllers
└── presentation/
    ├── shared/widgets/                       ← design system (PanelCard, IconCard, …)
    └── features/
        ├── auth/                             ← splash + login + esqueci-senha
        ├── home/                             ← central de comando
        ├── encaminhamento/                   ← detail + timeline + anexos
        ├── dossie/                           ← resumo + atendimentos + vacinas + exames
        ├── tfd/                              ← viagens + solicitar + detalhe
        ├── notificacoes/                     ← inbox
        ├── perfil/                           ← dados + logout
        └── main_shell.dart                   ← bottom nav de 4 abas
```

---

## 4. Modo mock

`USE_MOCK=true` (default) usa `MockSeed` em memória. Login com:

- **CPF**: qualquer (123.456.789-09 sugerido)
- **Senha**: `senha123`

Os mocks têm dados realistas: paciente Maria Aparecida (62 anos), encaminhamento de Cardiologia aprovado com consulta marcada, viagens de TFD para Águas Belas e Salvador, banners de campanha contra gripe e alerta de dengue.

---

## 5. Design system

**"Brutalismo simpático"** — tokens visuais herdados do DS UBS (azul institucional, cantos retos, paleta sóbria) com tipografia/densidade **invertidas** pra paciente com baixo letramento.

Resumo da inversão (vs. [DS UBS](../unisism-ubs/frontend/DESIGN_SYSTEM.md)):

| DS UBS (operador) | App Paciente |
|---|---|
| `text-xs`/`text-[10px]` | `text-base` mínimo (17px) |
| `font-mono` em quase tudo | `font-sans` em quase tudo; mono só em CPF/protocolo/datas |
| Densidade Bloomberg | Cards grandes, 1 ação por tela |
| Labels uppercase + `<kbd>` | Ícones grandes + label em frase normal |
| Botão 32-40dp altura | Botão 60dp altura |
| Cor = só estado | Mesmo princípio, mantido |

Tokens compartilhados:
- `blue-900` = ação institucional
- `slate-*` = neutros
- Borda fina `slate-200`, sem `rounded`, sem `shadow` difuso
- Verde/âmbar/vermelho **apenas** pra estado

Componentes em `lib/presentation/shared/widgets/`.

---

## 6. Contrato com backend

O contrato completo de endpoints esperados (auth, encaminhamentos, dossiê, TFD, banners, notificações, push) está em **[BACKEND_API_PACIENTE.md](BACKEND_API_PACIENTE.md)**.

Quando o backend estiver pronto:
1. Rodar com `--dart-define=USE_MOCK=false --dart-define=API_BASE_URL=...`
2. Implementar `google-services.json` / `GoogleService-Info.plist` pra push remoto

---

## 7. Comandos úteis

```bash
flutter analyze                     # lint + type check (zero erros)
flutter test                        # roda smoke tests
flutter run -d <device>             # roda no device/emulador
flutter build apk --release         # APK release
flutter build ios --release         # iOS release (precisa Mac + Xcode)
```

---

## 8. Roadmap

Próximas fases pós-MVP:
- [ ] Onboarding (paciente autocadastra-se com biometria do gov.br?)
- [ ] Modo offline-first (cache local com Drift/Isar)
- [ ] Chat com a UBS via webview/iframe
- [ ] Tela de **lembretes de medicação**
- [ ] Pedir 2ª via de receita
- [ ] Acessibilidade leitor de tela (TalkBack/VoiceOver) com `Semantics` revisadas
- [ ] Modo escuro (paleta já preparada via tokens)

---

## 9. Governança visual

Qualquer alteração nos tokens (`core/theme/`) requer alinhamento com o time do UNISISM-UBS — o objetivo é manter as Faces visualmente coerentes. Componentes específicos pra paciente (cards maiores, ícones grandes etc.) podem ser criados livremente desde que respeitem as regras de:
- ZERO `BorderRadius` arredondado
- ZERO `BoxShadow` difuso
- Apenas paletas `slate-*`, `blue-900/950`, `emerald-*`, `amber-*`, `red-*`
- Touch target mínimo 56dp
