# Checklist — Publicar VetVem Pro no iOS

Já feito (sem precisar de Mac):
- [x] Pasta `ios/` verificada e íntegra
- [x] App iOS registrado no Firebase (`com.vetvem.vetvemPro`, App ID `1:184640610145:ios:c82767c6acfba37dcaef20`)
- [x] `GoogleService-Info.plist` baixado e colocado em `ios/Runner/`
- [x] Permissões de câmera e galeria adicionadas no `Info.plist`
- [x] "Sign in with Apple" implementado no código (`login_controller.dart`/`login_view.dart`) — obrigatório pela Apple porque o app já oferece login com Google
- [x] `ios/Runner/Runner.entitlements` criado com a permissão de Apple Sign In (ainda precisa ser linkado no Xcode, ver abaixo)
- [x] Git iniciado nos dois projetos e enviados para o GitHub (`vetvemaplicativo/vetvem` e `vetvemaplicativo/vetvem-pro`)
- [x] Build de teste no Codemagic (simulador iOS, sem assinatura) — **passou sem erros** ✅ (confirma que o projeto compila para iOS)
- [x] Política de privacidade — já existe e está no ar em https://vetvem.com.br/privacidade (cobre tutores e profissionais), usar essa URL direto na App Store Connect
- [x] Rascunhos de ficha da loja e formulário de App Privacy em `docs/app_store/`

Falta fazer (precisa de Mac + Xcode):
- [x] Conta Apple Developer paga e aprovada (2026-08-27)
- [x] App ID `com.vetvem.vetvemPro` registrado no developer.apple.com com **Push Notifications** e **Sign In with Apple** habilitados
- [x] Chave APNs criada (Key ID `3T22X4M94W`, Team ID `X3K2T22232`, ambiente Sandbox & Production) e enviada ao Firebase Console → Cloud Messaging (dev + produção)
- [x] Build assinado real gerado com sucesso no Codemagic (certificado "Apple Distribution" + perfil de provisionamento App Store, ambos criados manualmente e carregados nas Code Signing Identities da conta Codemagic — a criação automática via API deu erro persistente, ver nota abaixo)
- [x] `GoogleService-Info.plist` incluído de verdade no bundle do app (existia no disco mas não estava referenciado no `project.pbxproj` — Firebase nunca inicializava no iOS, causava tela travada)
- [x] `CODE_SIGN_ENTITLEMENTS` linkado no `project.pbxproj` (o `Runner.entitlements` existia mas não estava aplicado ao build — Sign in with Apple falhava)
- [x] URL Scheme do Google Sign-In adicionado no `Info.plist` (obrigatório no iOS, ausência causava fechamento do app ao tentar logar com Google)
- [x] Ícones iOS sem canal alpha (exigência da Apple pro ícone de 1024×1024)
- [x] Provedor "Apple" habilitado no Firebase Console → Authentication → Sign-in method (não bastava configurar só do lado da Apple)
- [x] `OAuthProvider('apple.com').credential(...)` corrigido — faltava passar `accessToken: appleCredential.authorizationCode` além do `idToken`, causava `invalid-credential`
- [x] **Sign in with Apple e Google testados com sucesso nos dois apps, de ponta a ponta, em iPhone físico via TestFlight** ✅ (2026-09-04)
- [ ] Testar o restante do fluxo (agendamentos, notificações push) em iPhone físico
- [ ] Preencher a ficha completa na App Store Connect (screenshots, descrição — rascunhos em `docs/app_store/`)
- [ ] Preencher "Beta App Information" e "Beta App Review Information" no TestFlight (necessário pra testadores externos e pra submissão final)
- [ ] Enviar build para revisão da Apple

**Nota técnica (assinatura)**: `app-store-connect fetch-signing-files --create` do Codemagic falhou repetidamente com "Cannot save Signing Certificates without certificate private key", mesmo com chave individual e keychain inicializado. Contornado gerando CSR localmente (openssl), criando o certificado "Apple Distribution" manualmente no developer.apple.com, e subindo o `.p12` resultante + os perfis `.mobileprovision` (um por bundle ID) direto em Codemagic → Settings → Code signing identities. O `codemagic.yaml` usa o bloco `ios_signing` simples (sem fetch-signing-files). A chave da App Store Connect usada pra **publicar** (`integrations.app_store_connect`) precisa ser a de **equipe** ("VetVem"), não a individual — a individual dava 401 nas chamadas de API de listagem/upload.

Alternativa sem Mac próprio: usar **Codemagic** (codemagic.io) conectando o repositório — ele builda, assina e pode até publicar direto, tudo em macOS na nuvem.
