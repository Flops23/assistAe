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
- Telas 01 a 07 têm referências aprovadas, sem implementação; envio das referências ao GitHub autorizado individualmente em 08/11/2026. No horizontal, mensagens pequenas passam da esquerda para a direita, inicialmente embaixo, uma por vez na ordem de chegada ao servidor; tamanho do modelo aprovado como padrão. Tela 06 tinha quatro botões aprovados; usuário acrescentou funcionalmente o quinto botão Amigos, com atualização visual pendente. Amizade por código único de usuário e solicitação/aceite, sem login nem recuperação na primeira versão; convites até uso ou encerramento da sala. Sala pública ligada por padrão. Próxima etapa confirmada: designs Fila → Adicionar vídeo → Participantes. Miniatura definitiva adiada, manter marcador provisório. Leia PLANEJAMENTO.md para todas as decisões e pendências antes de implementar.
