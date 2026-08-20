# Guia — Formulário "App Privacy" da App Store Connect

Baseado no que o código do VetVem Pro realmente coleta (conferido em `notification_service.dart`, `auth`, `profile`, `service_area`). Use isto para preencher o questionário na App Store Connect (Apple não aceita texto livre lá, é tudo por checkbox — este guia mapeia o que marcar).

## O app coleta dados? 
**Sim**

## Tipos de dados coletados

### Contact Info
- **Name** — usado para: funcionalidade do app (perfil profissional) — vinculado à identidade: sim
- **Email Address** — funcionalidade do app (login) — vinculado: sim
- **Phone Number** — funcionalidade do app (contato) — vinculado: sim
- **Physical Address** — funcionalidade do app (área de atendimento) — vinculado: sim

### User Content
- **Photos or Videos** — foto de perfil, opcional — funcionalidade do app — vinculado: sim

### Identifiers
- **User ID** — o UID do Firebase Auth — funcionalidade do app — vinculado: sim

### Usage Data
- Não coletamos analytics de uso (sem Firebase Analytics/Crashlytics no projeto atualmente)

### Diagnostics
- Não coletamos (sem Crashlytics)

## O que NÃO marcar
- **Precise Location / Coarse Location** — não usamos GPS, o endereço é digitado manualmente pelo usuário (CEP)
- **Financial Info** — não há coleta de dados de pagamento no app (confirmar se isso mudar)
- **Health & Fitness** — não se aplica (dados são sobre pets, não do usuário)
- **Search History / Browsing History** — não se aplica
- **Contacts** — o app não acessa a agenda de contatos do telefone

## Dados usados para rastreamento (tracking)?
**Não** — não há SDKs de publicidade/rastreamento entre apps ou sites de terceiros.

## Observação importante
Se no futuro adicionarem Firebase Analytics, Crashlytics, ou qualquer SDK de ads, esse formulário precisa ser atualizado — a Apple audita isso e pode suspender o app se o formulário não bater com o comportamento real.
