# Planejamento consolidado — assistAe

## Avanço de implementação e aparelho — 09/11/2026

Backend agora possui 13 migrações, 23 tabelas privadas e 21 RPCs: identidade/preferências, salas/catálogo, leases/reconexão, chat e administração. Treze suítes SQL passaram; cron observado encerrando fixture privada, apagando mensagem e invalidando código. Papéis de API limitados, sem login/BYPASSRLS/DDL permanente. [Estado, escolhas técnicas e evidências](IMPLEMENTACAO.md). Ainda faltam mídia/fila, social/push/Realtime, getOperationStatus e app Android/APK. REST/Auth real, contenção entre sessões e aparelhos ainda não validados. P01–P15 e design preservados; blocos completos/B00 não declarados concluídos. Usuário confirmou Galaxy A54 com Play Store, APK direto, somente Android; versões exatas do SO não informadas. Isso não escolhe push/SDK/assinatura/orçamento. Sem imagem nova ou publicação de APK. Notas de somente planejamento abaixo são históricas.


## P13–P15 confirmados — 09/11/2026

P13: Voltar fecha primeiro teclado/painel; horizontal retorna ao vertical; vertical confirma saída. Parar externo interrompe só o aparelho, sem pausar demais/encerrar sala ou saída voluntária automática, com possível reconexão. Avançar/retroceder usa saltos de 10 s por autorizado. P14: aceitar HTTP e HTTPS para fontes diretas MP4/HLS gravadas, inclusive URLs assinadas; sem login/cookies de terceiros. Usuário escolheu ambos, diferente da recomendação de somente HTTPS. P15: apelido 2–24 caracteres, sala 2–60, mensagem até 500, fila até 50 próximos e até 5 animações pendentes, pulando espera maior que 20 s. Não apagar chat nem descartar a animação corrente repetida na rotação. Contagem Unicode e demais limites técnicos ainda a especificar.

P01–P15 confirmados, sem reapresentar. Fechado o conjunto catalogado de escolhas de comportamento; T01–T11, operação e revisão técnica continuam abertos. Planejamento completo não declarado concluído/aprovado. Somente documentação; sem imagem, código, infraestrutura, publicação ou teste funcional. Esta seção prevalece sobre pendências históricas abaixo.

## P10–P12 confirmados — 09/11/2026

Avisos de convites/solicitações inicialmente ligados; tela bloqueada mostra só “Você recebeu um convite” ou “Nova solicitação de amizade”, sem nomes. Permissão Android continua necessária. Chat somente em memória nesta versão: queda/rotação no mesmo processo preserva já vistas; morte do processo perde cache, sem recuperação de janelas antigas ou intervalo desconectado. Na sobreposição horizontal, reticências só na animação, texto inteiro no chat; repetir do início a animação interrompida ao girar, mantendo próximas em ordem e uma por vez. Usuário escolheu repetir, diferente da recomendação inicial. P01–P12 confirmados; restam P13–P15 e fechamento técnico. Esta seção prevalece sobre pendências históricas abaixo. Somente documentação, sem imagem, implementação, publicação ou teste funcional.

## Alinhamento de decisões P07–P09 — 09/11/2026

Usuário confirmou: solicitações cruzadas exigem aceite explícito; remetente pode cancelar enquanto pendente; qualquer envolvido remove amizade bilateral com confirmação. Convites já emitidos continuam válidos até uso/encerramento. Mensagens antigas mantêm apelido usado no envio, mesmo após alteração de perfil; novas capturam o nome vigente no envio. A mesma URL pode ser adicionada à fila em itens independentes; retry da mesma intenção não duplica item. Confirmados registrados em DECISOES.md; P01–P09 não devem ser reapresentados. P10–P15 e fechamento técnico continuam abertos. Somente documentação, sem imagem, código, publicação ou teste funcional.

## Organização do trabalho em blocos — 09/11/2026

Revisão do repositório resultou em [BLOCOS.md](BLOCOS.md), proposta de sequência B00–B09 com dependências, entregas e aceite. Etapa atual B00: conciliar documentos e fechar decisões/engenharia antes de implementar. Substitui a sequência anterior de execução de DESENVOLVIMENTO.md, sem mudar regras aprovadas ou encerrar o planejamento. DECISOES.md permanece o registro único de escolhas abertas; P01–P06 confirmados não serão reapresentados. Nenhuma implementação, imagem, publicação ou teste funcional.

P04–P06 confirmados em 09/11/2026: suspensão pelo Android quando pausado/sem vídeo segue reconexão normal, com reserva de 60 s após detecção; número visível nos cards e sala conta somente conectados, mas reservas válidas ainda ocupam o limite de 10; ex-administrador preserva apenas sua permissão individual anterior, sem ganhar controle automaticamente ao transferir. Áudio durante reprodução em segundo plano permanece requisito. Esta atualização substitui pendências históricas desses comportamentos. Nenhuma imagem, implementação, publicação ou teste.

Confirmado em 09/11/2026 (P01–P03 de DECISOES.md): reserva de 60 segundos contada após detectar a queda; Play com sala ainda sem mídia inicia o primeiro item da fila, mas adicionar sozinho não inicia; fonte reproduzível com duração inconclusiva é permitida, com avanço manual por administrador/participante autorizado ao terminar. Essa última regra é exceção explícita ao avanço automático, não permissão a usuário comum. Detecção/limites técnicos e apresentação da ação manual ainda precisam de especificação. Substitui pendências históricas desses três pontos abaixo. Somente planejamento, sem implementação/testes.

## Fechamento do planejamento — registro único (09/11/2026)

Criado [DECISOES.md](DECISOES.md), separando decisões confirmadas, escolhas abertas de produto, trabalho técnico e informações operacionais. Não reabrir decisões já confirmadas por causa de pendências históricas abaixo. Perguntas atuais P01–P03: origem dos 60 segundos, primeiro Play com fila e fonte com duração inconclusiva; respostas ainda pendentes nesta atualização. Design preservado. Nenhuma imagem, código, infraestrutura, publicação ou teste funcional. Próximo passo: incorporar respostas e fechar contratos afetados, permanecendo no planejamento.

## Avanço — segurança e testes planejados (09/11/2026)

Criado [SEGURANCA-TESTES.md](SEGURANCA-TESTES.md): fronteiras de confiança, matriz por tabela, RLS/grants/funções, revogação Realtime, credenciais, riscos do validador e casos de segurança, concorrência, Android, notificações e operação. Critérios de aceite documentados; todos os testes não executados. Parâmetros e decisões pendentes continuam explícitos, sem aprovação integral. Design preservado, sem imagens ou código. Nenhuma infraestrutura, publicação ou teste funcional. Próximo planejamento: consolidar decisões abertas e fechar bloqueadores em pequenos lotes; não iniciar implementação.

## Avanço — arquitetura Android e infraestrutura (09/11/2026)

Criado [ANDROID-INFRA.md](ANDROID-INFRA.md): camadas/pacotes, coordenador único de sala, MediaSessionService/player, foco de áudio, controles externos, cache, API Supabase, push, validador, ambientes e APK. Proposta técnica baseada em documentação oficial; nenhum projeto/serviço criado. Restrições a fechar: presença em background quando pausado/sem mídia, aparelhos-alvo, fornecedor de push, executor de metadados e fonte inconclusiva. Design preservado, sem nova arte ou aprovação visual. Nenhuma implementação, publicação ou teste funcional. Próximo planejamento: segurança/RLS e matriz de testes/aceite, além dessas decisões operacionais.

Atualização de 09/11/2026: usuário confirmou manter as mensagens já vistas antes da queda, sem recuperar o intervalo desconectado; notificações de convites/solicitações também com app fechado; uso inicial em teste fechado com amigos. Cache persistente após morte do processo e fornecedor de push não foram definidos. P15 confirmou limites de uso em [PARAMETROS.md](PARAMETROS.md); demais parâmetros de engenharia, retenção e capacidade de infraestrutura continuam propostos e não testados. Nenhuma implementação, infraestrutura, imagem ou publicação.

Decisões confirmadas pelo usuário em 08/11/2026: (1) se o administrador sair e os demais estiverem reconectando, preservar reservas e manter sala temporariamente sem administrador, atribuindo o papel quando alguém retornar; (2) Play após terminar o último vídeo recomeça esse vídeo; (3) pular animações antigas excedentes, mantendo mensagens no chat autorizado. P15 confirmou depois até 5 animações pendentes e pular espera maior que 20 s, sem apagar chat/descartar corrente repetida por rotação. Isso não permite recuperar mensagens do intervalo desconectado nem aprova integralmente os mecanismos técnicos. Nenhuma imagem, implementação, publicação ou teste. Esta atualização substitui pendências históricas desses três comportamentos abaixo.

## Avanço — estados e algoritmos (08/11/2026)

Criado [ALGORITMOS.md](ALGORITMOS.md), proposta v1 com estados de participação/administração/player, reconexão, relógio, término, fila, chat, retry, antispam e outbox. Regras existentes preservadas. Permanecem pendentes confirmação de administração temporariamente ausente, Play após fim da fila, excesso de animações, origem da contagem dos 60 segundos e estratégia de validação de mídia. Nenhuma implementação ou teste.

## Avanço técnico — contratos propostos (08/11/2026)

Usuário solicitou detalhar os métodos. Criado [CONTRATOS.md](CONTRATOS.md), com entradas, autorização, transações, respostas, erros, retries e eventos de cada grupo de operação. Nenhuma regra nova de produto aprovada nesta etapa; propostas/pendências estão identificadas. BANCO.md recebeu campos documentais de versão de perfil e sequência de heartbeat. Próximo trabalho: planejamento dos estados e algoritmos, sem implementação.

## Decisões de banco confirmadas — 08/11/2026

- Queda de conexão reserva a vaga por 60 segundos.
- Uma pessoa participa de somente uma sala por vez, incluindo a vaga reservada na reconexão.
- Ao reconectar, mostrar somente mensagens novas; não recuperar mensagens recebidas no intervalo desconectado. Saída voluntária e nova entrada também não permitem histórico anterior.
- Detalhamento técnico proposto em [BANCO.md](BANCO.md). Manter/limpar mensagens já visíveis antes da queda, contagem visual de reconectando e demais parâmetros continuam abertos. Não confundir as três respostas confirmadas com aprovação integral da arquitetura.

Etapa atual: planejamento do banco e contratos, sem código, infraestrutura ou testes funcionais.

**Correção de escopo — 08/11/2026:** usuário pediu planejar integralmente banco, métodos, algoritmos, segurança, contratos, operação e testes antes do desenvolvimento. Não iniciar código, projeto Android, migrações executáveis ou provisionamento por consequência deste planejamento. O design existente continua como base e ajustes reutilizam os mesmos cards. A proposta técnica inicial está em [ARQUITETURA.md](ARQUITETURA.md). Ainda há decisões abertas; não declarar planejamento concluído ou aprovado. Implementação somente após solicitação posterior do usuário. Esta correção prevalece sobre referências anteriores a construir a base/navegação como próximo passo. Nesta revisão: somente documentação, sem imagens, publicação, implementação ou testes funcionais.

## Etapa atual — planejamento do desenvolvimento (08/11/2026)

O usuário considera o design pronto para avançar e determinou reutilizar os mesmos modelos de cards em ajustes necessários. Esta orientação substitui a exigência de novas prévias antes do desenvolvimento e a sequência antiga Fila → Adicionar vídeo → Participantes. Preservar Home, referências e regras aprovadas; nenhuma imagem gerada ou editada nesta revisão.

Configurações com Amigos, solicitações enviadas, saída com sucessor, permissões e carregamentos/feedbacks serão detalhados com os componentes existentes. Não são variantes já implementadas ou testadas. Miniatura definitiva continua adiada; teclado será validado no Android, sem nova prévia.

Próxima etapa: [Plano de desenvolvimento](DESENVOLVIMENTO.md). A sequência técnica é proposta; parâmetros abertos não se tornam decisões aprovadas. Nenhum app/backend/APK implementado ou testado. Registros anteriores abaixo são históricos quando conflitarem com esta orientação.


Atualizado em 08/11/2026. Consolida a especificação original e as respostas explícitas do usuário. Valores técnicos ainda não escolhidos são identificados como pendências, não decisões aprovadas.

## Objetivo e tecnologia

Aplicativo nativo exclusivamente Android, inspirado na experiência de assistir junto do Rave, com salas públicas e privadas, reprodução sincronizada e chat em tempo real. Distribuição por APK.

- Kotlin e Jetpack Compose.
- Android Media3 / ExoPlayer.
- Supabase, PostgreSQL e Supabase Realtime.
- YouTube por IFrame Player API em etapa posterior.
- Cada dispositivo acessa a mídia diretamente na fonte original; o servidor mantém o estado compartilhado.
- Não contornar DRM, restrições de plataformas ou proteção de conteúdo.

<a id="produto-escopo"></a>

## Escopo da primeira versão

- Vídeos gravados por URLs diretas MP4 e HLS/M3U8. Sem transmissões ao vivo.
- YouTube depois da primeira versão.
- WebM e MP3 pertencem à visão original, mas não ao escopo inicial selecionado; priorização futura pendente.
- Links de páginas comuns dependem de uma fonte reproduzível e das permissões do serviço. Não prometer reprodução de qualquer link.
- Entrada como convidado com apelido e identidade persistida no aparelho.
- Limite inicial de 10 participantes por sala, sujeito a validação em testes.

## Regras fundamentais

- Sem sala de espera e sem agendamento.
- Criar ou entrar leva diretamente à sala com player e chat.
- O administrador pode deixar a mídia pausada até decidir começar.
- O início da sessão é manual por usuário autorizado.
- Entrar em uma sala em reprodução inicia localmente na posição atual. Entrar em sala pausada mantém a pausa.
- Ao terminar um vídeo, o próximo item da fila começa automaticamente.
- Convidados sem autorização não controlam a reprodução compartilhada.

<a id="produto-telas"></a>

## Telas

### 01 — Home

Design de referência aprovado, em docs/design/home-aprovada.png. Fundo preto e roxo profundo, iluminação roxa, cards arredondados, tipografia branca legível e ilustração de amigos assistindo juntos.

- Logo assistAe e subtítulo “assista com amigos”.
- Avatar e configurações.
- Botões grandes “Criar sala” e “Entrar em sala”.
- Até três salas públicas reais; esta decisão substitui a exigência original de exatamente três.
- Sem salas: “Nenhuma sala pública no momento”.
- Cards com somente imagem, nome e quantidade de participantes; sem tags, horários ou indicadores de reprodução.
- Imagem padrão aprovada pelo usuário para todas as salas. Arquivo específico ainda não escolhido.
- “Ver todas” abre a listagem completa.
- Ordenação: mais participantes primeiro; empate por salas mais recentes.
- Campo de código somente na tela Entrar em sala.

### 02 — Criar sala

- Nome da sala.
- Interruptor “Sala pública”: ligado = pública, desligado = privada; padrão inicial ligado (sala pública).
- Design simplificado aprovado: nome, interruptor e botão, sem bloco explicativo de permissões. Regras de controle permanecem abaixo.
- Botão Criar sala leva imediatamente ao player como administrador.
- Por padrão, somente o administrador controla. Ele pode autorizar pessoas específicas.
- Como não há seleção de mídia nesta tela, detalhar no design o estado do player ainda sem vídeo, sem criar uma sala de espera.

### 03 — Entrar em sala

- Tela ou painel com campo de código e botão Entrar.
- Mensagens para código inválido e sala inexistente.
- Código válido leva diretamente ao player.
- Convites por código com copiar e compartilhar; links diretos de convite não fazem parte da decisão inicial.
- Convites internos enviados pela lista de amigos aparecem abaixo da entrada por código. Amizade por código único de usuário, com solicitação e aceite, mantendo entrada sem login. Convite de sala válido até ser usado ou a sala encerrar. Ver regras de amizade abaixo; detalhes visuais do envio e gerenciamento seguem pendentes.

### 04 — Sala vertical

- Player com largura disponível até as bordas laterais e proporção original preservada, sem cortes.
- Para vídeos verticais, limitar a altura do player à metade da área útil; acomodar o conteúdo inteiro sem deformar.
- Chat abaixo com rolagem independente; campo de mensagem fixo na parte inferior.
- Controles ao tocar no player.
- Play/pause, avançar/retroceder e troca de mídia conforme permissões.
- Adicionar URL, abrir fila, chat, participantes, compartilhar convite e controles administrativos.
- Navegação confirmada pelo usuário: participantes pelo contador no cabeçalho, sem botão Pessoas duplicado; Fila e Compartilhar no menu de três pontos. Adicionar vídeo fica dentro de Fila, sem botão separado junto ao chat.

#### Menu de três pontos da sala

Itens com localização confirmada pelo usuário:

| Item | O que abre e permite fazer |
|---|---|
| Fila | Ver os vídeos da sala. Dentro do painel, “Adicionar vídeo” abre o campo de URL e a validação da fonte; usuário autorizado escolhe “Reproduzir agora” ou “Adicionar à fila”. Reorganizar e remover itens também dependem de permissão. |
| Compartilhar | Abrir as opções de convite: copiar/compartilhar o código da sala e convidar pela lista de amigos. O detalhamento visual do envio interno ainda está pendente. |

Não haverá item “Adicionar vídeo” separado nesse menu nem botão dessa ação no chat. O acesso será três pontos → Fila → Adicionar vídeo. Reproduzir agora altera a mídia compartilhada, enquanto adicionar à fila mantém a mídia atual; ambas as ações exigem autorização. Ao reproduzir outra imediatamente, o vídeo interrompido sai da reprodução sem ser adicionado automaticamente à fila.

Estados sem mídia/fila: antes do primeiro vídeo, mostrar área sem vídeo com “Adicione um vídeo” e orientação para abrir Fila no menu. Ao acabar o último vídeo, manter o último quadro com “Fila vazia” e oferecer Abrir fila para adicionar outro vídeo dentro dela. Esta combinação registra a resposta “ambos” do usuário; composições visuais v1 aprovadas, com envio ao GitHub autorizado. Chat continua disponível em ambos. Sem implementação/teste.

Opções administrativas/de saída com localização aprovada no menu de três pontos:

- “Sair da sala”: segue as regras de saída e sucessão do administrador.
- “Encerrar sala”: somente administrador, com confirmação, encerra para todos.

Participantes, permissões individuais, expulsão e transferência de administração ficam no painel aberto pelo contador superior; não duplicar um botão Pessoas no menu ou no chat. Menu completo aprovado visualmente com Fila, Compartilhar, Sair da sala e Encerrar sala (só administrador). Confirmações de encerramento, expulsão e transferência manual também aprovadas, com Cancelar e ação explícita. Na transferência manual, quem transfere permanece na sala como participante. Fluxo de saída com escolha de sucessor ainda precisa de design. Sem implementação/teste.

### 05 — Sala horizontal

- Player em tela cheia imersiva; barras de status e navegação ocultas.
- Controles temporários ao toque.
- Chat oculto inicialmente; botão abre painel flutuante com mensagens e digitação.
- Mensagens recebidas também aparecem pequenas sobre o vídeo, percorrendo lentamente da esquerda para a direita. Usuário pediu configurar posição (em cima ou embaixo), tamanho e velocidade. O painel completo de chat continua acessível pelo botão.
- Tamanho padrão aprovado: o texto pequeno mostrado em docs/design/player-horizontal-aprovado.png. Essa referência visual orienta a implementação; tamanho numérico em sp e adaptação entre telas ainda precisam ser validados no Android.
- Posição inicial embaixo. Mensagens exibidas uma por vez, na ordem de chegada ao servidor. Velocidade inicial numérica e faixas de ajuste ainda precisam ser definidas; não assumir parâmetros numéricos. Movimento lento foi solicitado, mas não demonstrado pela imagem estática. Ordenação técnica no servidor ainda precisa ser projetada.
- Fechar chat não interrompe reprodução.
- Rotação não reinicia vídeo nem perde sincronização.

<a id="tela-06"></a>

### 06 — Configurações

Referências internas aprovadas e envio ao GitHub autorizado: Mudar apelido v1, Configuração de mensagem v1, Notificações v2 e Sobre o app v1. A aprovação cobre composição e conteúdo apresentados, sem definir faixas numéricas de tamanho/velocidade, padrões dos interruptores, versão ou contatos do app. Sem implementação ou testes.

Notificações: cada interruptor salva automaticamente ao ser alterado, sem botão Salvar preferências, conforme correção do usuário. Decisão restrita a Notificações; não altera silenciosamente o salvamento dos demais painéis. Comportamento ainda sem implementação/teste.

Escopo atualizado por decisão do usuário: cinco botões — Mudar apelido, Configuração de mensagem, Notificações, Sobre o app e novo botão Amigos para abrir a lista/gerenciamento de amizades. Cada um abre seu painel. A referência visual aprovada ainda tem quatro botões; inclusão de Amigos aprovada funcionalmente, com design atualizado pendente. Edição de avatar, preferências de reprodução e demais ajustes de chat ficam para uma etapa futura; não incluir agora.

Preferências de mensagens sobre o player horizontal confirmadas pelo usuário: posição em cima/embaixo, tamanho do texto e velocidade de passagem da esquerda para a direita. Tamanho pequeno do modelo aprovado como padrão e posição inicial embaixo. Design dos controles e faixas de valores pendentes; imagem no topo é exemplo e não substitui a decisão funcional.

Navegação definida pelo usuário: “Configuração de mensagem” aparece como botão de lista igual aos demais na tela 06; tocar abre painel com posição, tamanho, velocidade e prévia das mensagens sobre o vídeo. Não deixar controles expandidos na tela principal. Notificações controla inicialmente convites de sala e solicitações de amizade; design dos dois interruptores aprovado, com entrega e estados ainda pendentes. Sobre o app tem apresentação breve aprovada sobre assistir junto, salas e chat; versão, autoria e contatos não foram definidos nem incluídos.

### 07 — Todas as salas públicas

- Pesquisa por nome e lista completa de salas públicas.
- Imagem, nome e quantidade de participantes.
- Entrar diretamente pelo card.
- Sem tags, agendamentos ou horários de início.
- Mesma ordenação da Home. Salas privadas não aparecem.

<a id="produto-amigos"></a>

## Sistema de amizade e convites internos

Funcionalidade confirmada pelo usuário em 08/11/2026, incluída no projeto além dos convites por código:

- Lista de amigos e possibilidade de convidar amigos para salas pelo sistema.
- Convites recebidos exibidos abaixo da entrada por código em Entrar em sala; esse modelo visual foi aprovado.
- Acesso à lista/gerenciamento pelo novo botão Amigos em Configurações; convite dentro da sala continua por Compartilhar. Designs desses painéis e do envio ainda pendentes.
- Identificação e adição por código único de cada usuário, com solicitação e aceite de amizade. Manter entrada como convidado sem login; código de usuário é distinto do código da sala. Formato do código e detalhes de remoção/gerenciamento ainda pendentes.
- Convite interno de sala válido até ser usado ou a sala encerrar. Entrega, remoção de convites expirados e tratamento de sala lotada ainda precisam de detalhamento; sala encerrada não aceita entrada.
- Sem recuperação da identidade na primeira versão: reinstalar ou trocar de aparelho implica perder a identidade e as amizades. Não adicionar login ou recuperação nesta etapa.

## Painéis dentro da sala

Atualização: Compartilhar/Convidar, Chat horizontal aberto e Amigos também tiveram os modelos v1 aprovados, com envio ao GitHub autorizado. Teclado, feedbacks, confirmações e estados complementares seguem pendentes; sem implementação/teste. Solicitados os quatro painéis restantes das configurações para análise: Mudar apelido, Configuração de mensagem, Notificações e Sobre o app.

Designs de Fila, Adicionar vídeo e Participantes aprovados pelo usuário após análise das prévias v1; envio dessas três referências ao GitHub autorizado. Sem implementação ou testes. Próximas propostas solicitadas: Compartilhar/Convidar, Chat horizontal aberto e Amigos. Ajustes simples de botões nas telas aprovadas permitidos conforme necessidade, preservando conceito/identidade.

- Adicionar vídeo: acessado dentro de Fila; URL, identificação da fonte, validação, Reproduzir agora ou Adicionar à fila conforme permissões.
- Fila: acessada pelos três pontos; vídeos adicionados, acesso a Adicionar vídeo, reorganização e remoção conforme permissões.
- Participantes: conectados, administrador, convite e gerenciamento de permissões.
- Chat horizontal: mensagens e campo de digitação sobre o vídeo.
- Somente administrador e participantes autorizados adicionam vídeos à fila. Troca de mídia e reorganização também respeitam permissões.

<a id="produto-administracao"></a>

## Administração e ciclo de vida

- Transferência manual de administração disponível.
- Saída voluntária do administrador com outros presentes: oferecer escolha de sucessor. Sem escolha, transferir para o participante conectado há mais tempo.
- Queda do administrador: aguardar até 60 segundos para reconexão; depois transferir para quem estiver conectado há mais tempo.
- Saída voluntária do último participante: encerrar imediatamente.
- Queda do último participante: aguardar até 60 segundos antes de encerrar.
- Administrador pode encerrar a sala para todos, com confirmação.
- Sala encerrada não aceita mais entrada pelo código.

<a id="produto-chat"></a>

## Chat e moderação

- Cada participante vê somente mensagens enviadas após sua entrada.
- Apagar mensagens quando a sala encerrar.
- Administrador pode expulsar e impedir o retorno da mesma identidade à sala.
- Limitar envio de mensagens para combater spam; limite numérico ainda não definido.
- Na sobreposição horizontal, apresentar uma mensagem por vez na ordem de chegada ao servidor; estratégia técnica de ordenação e limite da sequência de mensagens pendentes.
- Bloqueio por identidade de convidado não deve ser apresentado como garantia de bloquear a pessoa após reinstalação ou troca de identidade.

<a id="produto-sincronizacao"></a>

## Sincronização e Android

O estado compartilhado contém identificador/URL da mídia, posição, reproduzindo/pausado, horário de referência do servidor, participantes, permissões, administrador e fila.

- Alterações autorizadas são distribuídas em tempo real.
- Corrigir diferenças entre dispositivos respeitando as limitações da fonte.
- Travamento individual não pausa os demais. Ao recuperar, realinhar à posição da sala.
- Recuperar estado atual após reconexão.
- Áudio continua em segundo plano ao trocar de aplicativo ou bloquear a tela.
- Autorização deve ser garantida no servidor, além da interface.
- Ainda definir tecnicamente ordenação de comandos simultâneos, versões de estado, tolerância de sincronização e tratamento de eventos antigos.

## Ordem de trabalho e validação

Design atualizado: aprovados e com envio ao GitHub autorizado os nove estados de código inválido, sala lotada, sala encerrada, vídeo inválido, reconectando, sem salas públicas, busca sem resultados, sem amigos e sem convites. São referências estáticas; nenhuma implementação/teste. Design ainda não está integralmente concluído: restam composição de Configurações com Amigos, solicitações enviadas com itens, saída com escolha de sucessor, variantes sem permissão e carregamentos/feedbacks/validações restantes. Não acrescentar regras técnicas a partir das imagens sem definição.

Revisão de prioridade: usuário dispensou a geração da prévia de chat horizontal com teclado (“1 n precisa”) e solicitou os lotes 2 e 3: erros/reconexão e estados vazios. Não gerar essa prévia de teclado nesta etapa. A dispensa de imagem não comprova comportamento de teclado implementado/testado nem elimina a validação Android necessária.

Ordem original das telas: Home, Criar sala, Entrar em sala, player vertical, player horizontal, Configurações, exploração pública, painéis, backend/chat/sincronização e testes/APK.

Próxima etapa confirmada pelo usuário: continuar os designs na ordem Fila → Adicionar vídeo → Participantes. A sugestão de antecipar uma prova com dois celulares não foi escolhida; a validação de sincronização e reconexão continua necessária antes da entrega funcional.

Antes de declarar entrega funcional, testar permissões, limite de participantes, reconexão, transferência, encerramento, fila, chat, rotação e áudio em segundo plano em dispositivos Android.

## Pendências que não devem ser inventadas como decisões

- Referência/arquivo da imagem padrão dos cards adiado pelo usuário; manter marcador provisório. Opções de avatar também pendentes, fora dos ajustes iniciais.
- Versão mínima Android, assinatura e atualização do APK.
- Projeto Supabase, orçamento e configuração operacional.
- Formato, validade durante a sala e renovação dos códigos; limitação de tentativas.
- Valores dos limites de mensagens, URLs, nomes e fila.
- Persistência das mensagens já vistas após morte do processo (P11); reconexão sem recuperar intervalo e nova entrada sem histórico já confirmadas.
- Tratamento de sala lotada, mídia inválida/expirada e falha individual; design dos estados sem vídeo/fila vazia conforme regras acima.
- Efeitos de chamadas, perda de áudio, botão Voltar e teclado no modo horizontal.
- Legendas, faixas de áudio e opções específicas de qualidade, caso necessárias.
- Arte final e aprovação das telas restantes.
