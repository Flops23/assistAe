# Instruções de continuidade — assistAe

Antes de trabalhar, leia README.md, docs/PLANEJAMENTO.md, docs/DESIGN.md e docs/CONTINUIDADE.md.

- Plataforma exclusivamente Android; Kotlin, Jetpack Compose, Media3/ExoPlayer e Supabase. Distribuição por APK. Não transformar em site.
- Preservar a Home aprovada em docs/design/home-aprovada.png. Não redesenhar o conceito sem solicitação.
- Não gerar, modificar ou enviar novas imagens ao GitHub sem aprovação explícita do usuário. Em 08/11/2026, foram autorizados o envio da Home original e, depois, das referências aprovadas Criar sala e Entrar em sala. Isso não autoriza outras imagens.
- Sem sala de espera, agendamento ou campo de código independente na Home.
- Fluxo: Home → Criar/Entrar em sala → Player com chat.
- As decisões consolidadas em PLANEJAMENTO.md prevalecem sobre exemplos visuais conflitantes. Não alterar silenciosamente a imagem aprovada.
- Não apresentar proposta como aprovada, design como implementação, ou implementação como testada sem evidência.
- Atualize DESIGN.md e CONTINUIDADE.md após cada avanço ou nova aprovação, indicando o que foi proposto, aprovado, implementado e testado.
- Nunca colocar credenciais, chaves privilegiadas do Supabase ou chaves de assinatura do APK no repositório.
- Home, Criar sala, Entrar em sala e player vertical têm design aprovado, sem implementação. Envio da referência do player vertical autorizado em 08/11/2026. Próxima etapa: design do player horizontal. Sistema de amizade e convites internos confirmado; gerenciamento e envio ainda precisam de definição/design. Leia as pendências antes de implementar.
