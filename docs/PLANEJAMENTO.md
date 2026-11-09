# Planejamento consolidado — assistAe

Atualizado em 08/11/2026. Consolida a especificação original e as respostas explícitas do usuário. Valores técnicos ainda não escolhidos são identificados como pendências, não decisões aprovadas.

## Objetivo e tecnologia

Aplicativo nativo exclusivamente Android, inspirado na experiência de assistir junto do Rave, com salas públicas e privadas, reprodução sincronizada e chat em tempo real. Distribuição por APK.

- Kotlin e Jetpack Compose.
- Android Media3 / ExoPlayer.
- Supabase, PostgreSQL e Supabase Realtime.
- YouTube por IFrame Player API em etapa posterior.
- Cada dispositivo acessa a mídia diretamente na fonte original; o servidor mantém o estado compartilhado.
- Não contornar DRM, restrições de plataformas ou proteção de conteúdo.

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

## Administração e ciclo de vida

- Transferência manual de administração disponível.
- Saída voluntária do administrador com outros presentes: oferecer escolha de sucessor. Sem escolha, transferir para o participante conectado há mais tempo.
- Queda do administrador: aguardar até 60 segundos para reconexão; depois transferir para quem estiver conectado há mais tempo.
- Saída voluntária do último participante: encerrar imediatamente.
- Queda do último participante: aguardar até 60 segundos antes de encerrar.
- Administrador pode encerrar a sala para todos, com confirmação.
- Sala encerrada não aceita mais entrada pelo código.

## Chat e moderação

- Cada participante vê somente mensagens enviadas após sua entrada.
- Apagar mensagens quando a sala encerrar.
- Administrador pode expulsar e impedir o retorno da mesma identidade à sala.
- Limitar envio de mensagens para combater spam; limite numérico ainda não definido.
- Na sobreposição horizontal, apresentar uma mensagem por vez na ordem de chegada ao servidor; estratégia técnica de ordenação e limite da sequência de mensagens pendentes.
- Bloqueio por identidade de convidado não deve ser apresentado como garantia de bloquear a pessoa após reinstalação ou troca de identidade.

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

Ordem original das telas: Home, Criar sala, Entrar em sala, player vertical, player horizontal, Configurações, exploração pública, painéis, backend/chat/sincronização e testes/APK.

Próxima etapa confirmada pelo usuário: continuar os designs na ordem Fila → Adicionar vídeo → Participantes. A sugestão de antecipar uma prova com dois celulares não foi escolhida; a validação de sincronização e reconexão continua necessária antes da entrega funcional.

Antes de declarar entrega funcional, testar permissões, limite de participantes, reconexão, transferência, encerramento, fila, chat, rotação e áudio em segundo plano em dispositivos Android.

## Pendências que não devem ser inventadas como decisões

- Referência/arquivo da imagem padrão dos cards adiado pelo usuário; manter marcador provisório. Opções de avatar também pendentes, fora dos ajustes iniciais.
- Versão mínima Android, assinatura e atualização do APK.
- Projeto Supabase, orçamento e configuração operacional.
- Formato, validade durante a sala e renovação dos códigos; limitação de tentativas.
- Valores dos limites de mensagens, URLs, nomes e fila.
- Semântica de mensagens após reconexão versus saída e nova entrada.
- Tratamento de sala lotada, mídia inválida/expirada e falha individual; design dos estados sem vídeo/fila vazia conforme regras acima.
- Efeitos de chamadas, perda de áudio, botão Voltar e teclado no modo horizontal.
- Legendas, faixas de áudio e opções específicas de qualidade, caso necessárias.
- Arte final e aprovação das telas restantes.
