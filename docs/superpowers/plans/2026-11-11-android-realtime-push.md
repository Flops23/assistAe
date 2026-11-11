# Android, Realtime e push

**Objetivo:** Instalar a primeira versão Android do assistAe e ligar os fluxos do app ao Supabase existente.

**Base:** PLANEJAMENTO.md, DESIGN.md, BLOCOS.md, ANDROID-INFRA.md e decisões P01–P15. A distribuição é por APK direto no teste fechado.

- [x] Preparar build Kotlin/Compose com Media3, configurar cliente com chave publicável e provar autenticação e RPC no Supabase.
- [x] Implementar Home, entrada/criação, sala, chat, fila, reprodução e operações de perfil/social conforme as referências aprovadas.
- [x] Implementar e testar aviso privado por conta no Realtime. A API revalida cada leitura e a geração da sala limita a janela de chat.
- [x] Implementar registro de instalação e dispatcher FCM. Testar concessões, resultados e retries com dados sintéticos.
- [ ] Instalar configuração Firebase do cliente e segredo de envio no ambiente. Validar uma entrega no aparelho.
- [ ] Compilar e verificar APK de teste. Registrar os passos que dependem do Galaxy A54, dos testadores ou da conta Firebase.

Android 8.0 (API 26) é o mínimo inicial escolhido para este build. O projeto começa com assinatura de teste local e identificador com.flops23.assistae. Sem publicação em loja e sem novas imagens.
