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
- [ ] Testar o `.ipa` num iPhone físico (via TestFlight) antes de submeter pra revisão
- [ ] Preencher a ficha completa na App Store Connect (screenshots, descrição — rascunhos em `docs/app_store/`)
- [ ] Enviar build para o TestFlight e depois para revisão da Apple

**Nota técnica**: `app-store-connect fetch-signing-files --create` do Codemagic falhou repetidamente com "Cannot save Signing Certificates without certificate private key", mesmo com chave individual e keychain inicializado. Contornado gerando CSR localmente (openssl), criando o certificado "Apple Distribution" manualmente no developer.apple.com, e subindo o `.p12` resultante + os perfis `.mobileprovision` (um por bundle ID) direto em Codemagic → Settings → Code signing identities. O `codemagic.yaml` usa o bloco `ios_signing` simples (sem fetch-signing-files).
- [ ] Rodar `flutter build ipa` e ver se builda sem erro (corrigir o que aparecer — normal ter 1-2 ajustes na primeira vez)
- [ ] Testar em um iPhone físico ou simulador antes de submeter
- [ ] Preencher ficha do app na App Store Connect (screenshots, descrição, política de privacidade — obrigatória por causa de login e dados de localização)
- [ ] Submeter para revisão da Apple

Alternativa sem Mac próprio: usar **Codemagic** (codemagic.io) conectando o repositório — ele builda, assina e pode até publicar direto, tudo em macOS na nuvem.
