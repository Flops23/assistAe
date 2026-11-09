# Instruções de continuidade — assistAe

Revisão cruzada banco/contratos/estados (09/11/2026) em docs/CONSISTENCIA.md: dez divergências centrais conciliadas documentalmente; modelos de avaliação assíncrona/contextos persistidos, gates/geração/prazos, nulabilidade de admin, outbox e fechamento alinhados. C11–C16 planejados, não executados. P01–P15 preservados; refinamentos técnicos seguem propostas, T01–T11/B00 ainda abertos. Próximo fechamento: constraints/grants/revogação, parâmetros/variantes e operação. Somente documentação; sem implementação, imagens ou publicação.

P13–P15 confirmados (09/11/2026): Voltar fecha teclado/painel, horizontal→vertical, vertical confirma saída; Parar externo só local sem pausar demais/encerrar sala, com possível reconexão; saltos 10 s por autorizado. Aceitar HTTP e HTTPS para mídia direta MP4/HLS VOD/URLs assinadas, sem login/cookies de terceiros. Limites iniciais: apelido 2–24, sala 2–60, mensagem até 500 caracteres; fila até 50 próximos; até 5 animações pendentes, pular espera maior que 20 s sem apagar chat/descartar corrente repetida na rotação. Não reapresentar P01–P15. T01–T11 e operação continuam abertos; próximo passo revisão técnica documental. F20–F22 planejados, não executados. Somente planejamento; sem imagem, implementação ou publicação.

P10–P12 confirmados (09/11/2026): convites/solicitações com avisos inicialmente ligados e texto discreto sem nomes na tela bloqueada, sujeitos à permissão Android; chat só em memória, perdido ao morrer processo e preservado na queda/rotação do mesmo processo; reticências só na animação, texto inteiro no chat, repetir do início a animação interrompida ao girar antes das próximas em ordem. Não reapresentar P01–P12. Sem recuperar intervalo desconectado/janelas antigas. F17–F19 planejados, não executados. Restam P13–P15 e revisão técnica; somente planejamento.

P07–P09 confirmados (09/11/2026): cruzadas exigem aceite; remetente cancela pending; qualquer envolvido remove amizade bilateral com confirmação, preservando convites emitidos até uso/encerramento. Mensagens antigas mantêm apelido do envio. URL repetida permitida em itens independentes; retry da mesma intenção não duplica. Não reapresentar P01–P09. Regras conciliadas nos documentos técnicos e casos F10–F16 planejados, não executados. Restam P10–P15 e fechamento técnico; somente planejamento.

P04–P06 confirmados (09/11/2026): suspensão em background pausado/sem vídeo segue reconexão normal; contagem visível só conectados, reservas continuam ocupando vagas; ex-admin mantém apenas autorização individual anterior. Não reapresentar perguntas; continuar somente planejamento.

P01–P03 respondidos em 09/11/2026: 60 s após detectar queda; Play inicial promove primeiro da fila sem auto-início ao adicionar; duração inconclusiva permitida com avanço manual por autorizado ao terminar. Não reapresentar essas perguntas. Exceção ao avanço automático registrada em planejamento/contratos; sem implementação.

Registro único de fechamento em docs/DECISOES.md (09/11/2026). Consultar confirmados antes de perguntar; pendências históricas não reabrem decisões. Lote P01–P03 apresentado para origem do prazo, primeiro Play e duração inconclusiva. Continuar somente planejamento, sem assumir respostas.

Segurança/RLS e matriz de testes planejados em docs/SEGURANCA-TESTES.md (09/11/2026). Nenhuma política implementada ou teste executado. Próximo passo: consolidar decisões abertas e fechar bloqueadores; continuar somente planejamento.

Arquitetura Android/infra proposta em docs/ANDROID-INFRA.md (09/11/2026), sem implementação. Próximo planejamento: segurança/RLS e matriz de testes/aceite. Presença em background sem reprodução, aparelhos-alvo, fornecedor de push e executor de validação de mídia continuam pendentes; não presumir aprovações.

Decisões de 09/11/2026: manter mensagens já vistas antes da queda sem recuperar intervalo desconectado; avisar convites/solicitações também com app fechado; começar em teste fechado com amigos. docs/PARAMETROS.md contém hipóteses numéricas e operacionais ainda não aprovadas/testadas. Continuar somente planejamento.

Decisões confirmadas pelo usuário em 08/11/2026: (1) se o administrador sair e os demais estiverem reconectando, preservar reservas e manter sala temporariamente sem administrador, atribuindo o papel quando alguém retornar; (2) Play após terminar o último vídeo recomeça esse vídeo; (3) pular animações antigas excedentes, mantendo mensagens no chat autorizado. Limite da fila de animações ainda aberto. Isso não permite recuperar mensagens do intervalo desconectado nem aprova integralmente os mecanismos técnicos. Nenhuma imagem, implementação, publicação ou teste. Esta atualização substitui pendências históricas desses três comportamentos abaixo.

Estados/algoritmos propostos em docs/ALGORITMOS.md (08/11/2026). Escolhas pendentes não são aprovações: administração temporariamente ausente, replay, excesso de animações, origem dos 60 segundos e validação de mídia. Continuar somente planejamento; sem código, infraestrutura ou imagens.

Contratos propostos em docs/CONTRATOS.md (08/11/2026), sem implementação. Próximo passo é planejar máquinas de estado e algoritmos, resolvendo as pendências listadas; não iniciar código. Os contratos não representam aprovação de regras novas de produto.

Banco detalhado em docs/BANCO.md (proposta, sem implementação). Decisões explícitas de 08/11/2026: vaga reservada por 60 segundos na queda; uma sala por pessoa; reconexão mostra somente mensagens novas e não recupera intervalo desconectado. Próximo trabalho é planejamento de contratos/algoritmos, não programação. Não tratar propostas técnicas como aprovadas.

**Correção de escopo — 08/11/2026:** usuário pediu planejar integralmente banco, métodos, algoritmos, segurança, contratos, operação e testes antes do desenvolvimento. Não iniciar código, projeto Android, migrações executáveis ou provisionamento por consequência deste planejamento. O design existente continua como base e ajustes reutilizam os mesmos cards. A proposta técnica inicial está em [docs/ARQUITETURA.md](docs/ARQUITETURA.md). Ainda há decisões abertas; não declarar planejamento concluído ou aprovado. Implementação somente após solicitação posterior do usuário. Esta correção prevalece sobre referências anteriores a construir a base/navegação como próximo passo. Nesta revisão: somente documentação, sem imagens, publicação, implementação ou testes funcionais.

Orientação mais recente (08/11/2026): usuário considera design pronto para avançar ao planejamento do desenvolvimento. Ajustes devem reutilizar os mesmos modelos de cards, sem exigir nova rodada de imagens. Próxima etapa: docs/DESENVOLVIMENTO.md, substituindo a sequência antiga de designs citada abaixo. Sem implementação/testes nesta revisão.

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
