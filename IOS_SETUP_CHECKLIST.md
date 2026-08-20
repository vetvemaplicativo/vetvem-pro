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

Falta fazer (precisa de Mac + Xcode):
- [ ] Concluir e pagar a inscrição no Apple Developer Program (US$99/ano) — cadastro já iniciado
- [ ] Abrir `ios/Runner.xcworkspace` no Xcode (não o `.xcodeproj`)
- [ ] Rodar `flutter pub get` e `pod install` (gera o `Podfile.lock`)
- [ ] Configurar assinatura (Signing & Capabilities → selecionar o Team da Apple Developer)
- [ ] Em Signing & Capabilities, clicar em "+ Capability" → **Sign in with Apple** (o Xcode vai usar o `Runner.entitlements` que já deixei pronto e ligar ele ao projeto sozinho)
- [ ] No developer.apple.com, no App ID `com.vetvem.vetvemPro`, habilitar a capability "Sign In with Apple" (só aparece depois do pagamento da conta)
- [ ] Habilitar a capability **Push Notifications** no Xcode (usada pelo `firebase_messaging`)
- [ ] Gerar uma chave APNs (Apple Push Notification) em developer.apple.com e subir no Firebase Console → Project Settings → Cloud Messaging
- [ ] Rodar `flutter build ipa` e ver se builda sem erro (corrigir o que aparecer — normal ter 1-2 ajustes na primeira vez)
- [ ] Testar em um iPhone físico ou simulador antes de submeter
- [ ] Preencher ficha do app na App Store Connect (screenshots, descrição, política de privacidade — obrigatória por causa de login e dados de localização)
- [ ] Submeter para revisão da Apple

Alternativa sem Mac próprio: usar **Codemagic** (codemagic.io) conectando o repositório — ele builda, assina e pode até publicar direto, tudo em macOS na nuvem.
