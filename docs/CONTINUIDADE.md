# Ponto de continuidade

Atualizado em 08/11/2026.

## Aprovação atual — quatro painéis de Configurações

Usuário aprovou e autorizou enviar ao GitHub as quatro referências atuais: Mudar apelido v1, Configuração de mensagem v1, Notificações v2 e Sobre o app v1, em `docs/design/propostas/`. Notificações salva automaticamente ao alterar cada interruptor; sua v1 com Salvar preferências foi substituída e fica somente local, fora do envio. Prompts e documentação acompanham as quatro imagens aprovadas. Não houve geração ou edição de imagem nesta etapa, implementação ou testes Android.

As sete telas principais e os dez painéis complementares apresentados têm referências aprovadas, com a ressalva de que a composição principal de Configurações ainda precisa incorporar Amigos. Restam estados complementares, teclado, confirmações, solicitações enviadas, parâmetros técnicos/funcionais e miniatura definitiva adiada. Não tratar esses estados como desenhados ou o aplicativo como implementado. Registros de propostas abaixo são históricos.

## Ponto atual — quatro últimas propostas de Configurações

**Correção mais recente:** em Notificações, usuário definiu salvamento automático ao mudar cada interruptor; remover botão Salvar preferências. Prévia revisada com imagegen, v1 preservada; caminho da revisão: `docs/design/propostas/notificacoes-proposta-v2.png`. Não estender essa decisão aos demais painéis sem solicitação. Sem implementação/teste ou envio dessa revisão ao GitHub. As quatro propostas seguem para análise; não houve aprovação geral nesta correção.

Compartilhar/Convidar, Chat horizontal aberto e Amigos aprovados pelo usuário e enviados ao GitHub com documentação no commit `05a0b01`, main. As três referências foram preservadas sem edição. Seis painéis complementares agora têm design aprovado: esses três e Fila, Adicionar vídeo e Participantes.

Usuário solicitou as quatro últimas prévias; geradas com imagegen integrada: `docs/design/propostas/mudar-apelido-proposta-v1.png`, `configuracao-mensagem-proposta-v1.png`, `notificacoes-proposta-v1.png` e `sobre-app-proposta-v1.png`. Prompts completos no mesmo diretório em `prompts-configuracoes-v1.md`. As quatro são propostas locais para análise; sem aprovação, envio ao GitHub, implementação ou testes Android. Documentação e quatro novas artes permanecem locais até nova autorização.

Mudar apelido: campo, inicial ilustrativa e salvar/cancelar. Mensagens: posição embaixo, tamanho/velocidade qualitativos e prévia estática ilustrativa (não redefine tamanho pequeno aprovado no player). Notificações: convites de sala/solicitações de amizade com interruptores ligados apenas como exemplo, padrões pendentes. Sobre: apresentação curta proposta, sem versão/contato inventados. Inspeção visual confirma textos/ações sem cortes aparentes; não equivale a validação Android.

Próximo passo: usuário analisar estas quatro. Ainda restam estados de erro/vazio/carregamento/reconexão, teclado, confirmações administrativas/remoção, aba de solicitações enviadas, detalhamento de parâmetros e ajustes da composição principal com botão Amigos. Miniatura das salas continua adiada. Nenhum aplicativo/backend/APK implementado/testado. Histórico abaixo não substitui este ponto atual.

## Último avanço — aprovação de três painéis e novas propostas

**Atualização posterior:** usuário aprovou Compartilhar, Chat horizontal aberto e Amigos e autorizou seu envio ao GitHub. Solicitou as quatro últimas prévias: Mudar apelido, Configuração de mensagem, Notificações e Sobre o app. A geração destas quatro está autorizada; não há autorização de envio destas novas quatro imagens. Histórico abaixo não altera a aprovação das três anteriores.

Usuário aprovou Fila, Adicionar vídeo e Participantes e autorizou envio ao GitHub. Enviados sem edição com documentação no commit `9fa1e45` (main). Nenhuma implementação/teste Android.

A pedido de “gere mais 3 telas”, foram criadas com imagegen as propostas de Compartilhar/Convidar, Chat horizontal aberto e Amigos (próximos itens da lista apresentada). Arquivos em `docs/design/propostas/`: `compartilhar-proposta-v1.png`, `chat-horizontal-proposta-v1.png`, `amigos-proposta-v1.png`. Prompts completos em `prompts-compartilhar-chat-amigos-v1.md`. Propostas locais aguardando análise; não enviadas ao GitHub e sem autorização para esse envio. Referências aprovadas preservadas.

Compartilhar: código ilustrativo e convites da lista. Chat: painel à direita, sem teclado, mensagem sobreposta embaixo. Amigos: código pessoal, adicionar, solicitações e remoção. Inspecionados visualmente, sem testes funcionais. Ver DESIGN.md para limitações: aba enviadas, teclado, confirmações e estados complementares ainda pendentes. Próximo passo é avaliação dessas três propostas. Painéis Mudar apelido, Configuração de mensagem, Notificações e Sobre o app continuam pendentes.

## Avanço atual — três painéis propostos para análise

**Atualização mais recente:** usuário aprovou Fila, Adicionar vídeo e Participantes e autorizou enviar as três imagens v1 ao GitHub. Permanecem sem implementação/testes. Pediu gerar mais três telas; sequência adotada conforme lista apresentada: Compartilhar/Convidar, Chat horizontal aberto e Amigos. A geração dessas três está autorizada; seu envio ao GitHub depende de nova autorização. Histórico de elaboração abaixo.

Usuário pediu modelos de Fila, Adicionar vídeo e Participantes. Prévias criadas com ferramenta integrada imagegen, seguindo o player vertical aprovado, preservado sem edição. Arquivos locais em `docs/design/propostas/`: `fila-proposta-v1.png`, `adicionar-video-proposta-v1.png` e `participantes-proposta-v1.png`. Fila separa vídeo atual/próximos; Adicionar vídeo mostra URL validada ilustrativa e duas ações; Participantes mostra visão administrativa com permissões, transferência, expulsão e convite.

Estado: propostas aguardando análise/aprovação do usuário; sem implementação, teste Android ou envio dessas imagens ao GitHub. URLs, nomes e validação exibidos são ilustrativos. Estados complementares e confirmações ainda pendentes. Próximo passo: receber avaliação dos três painéis, sem tratar as propostas como aprovadas. Usuário também autorizou ajustes simples de botões nas telas existentes conforme necessidade, preservando identidade/conceito.

## Última decisão — respostas à revisão de pendências

Usuário confirmou as decisões abaixo e autorizou registrá-las no planejamento e enviar ao GitHub. Esta seção e PLANEJAMENTO.md prevalecem sobre pendências antigas nos registros históricos.

1. Sala pública ligada por padrão ao criar.
2. Amigos identificados/adicionados por código único de usuário, mantendo entrada sem login.
3. Amizade exige solicitação e aceite.
4. Lista de amigos por novo botão Amigos em Configurações. São agora cinco opções funcionais; referência de quatro botões preservada e ajuste visual pendente.
5. Sem recuperação de identidade e amizades após reinstalar/trocar de aparelho na primeira versão.
6. Convites de sala válidos até serem usados ou a sala encerrar.
7. Reproduzir agora retira o vídeo interrompido da reprodução sem adicioná-lo automaticamente à fila.
8. Usuário respondeu “ambos” aos estados sem vídeo/fila vazia: combinação registrada como área sem vídeo com “Adicione um vídeo” antes da primeira mídia; último quadro com “Fila vazia” e acesso a adicionar vídeo ao terminar a fila. Chat continua disponível; composição pendente.
9. Sair e Encerrar nos três pontos; Encerrar somente para administrador, com confirmação.
10. Mensagens sobre o vídeo horizontal começam embaixo.
11. Exibir uma mensagem por vez, em ordem de chegada ao servidor; implementação técnica da ordenação pendente.
12. Notificações inicialmente para convites de sala e solicitações de amizade.
13. Imagem padrão das salas adiada; manter marcador provisório.
14. Continuar designs: Fila → Adicionar vídeo → Participantes.

Aprovado funcionalmente, sem novas imagens, implementação ou testes. Detalhes ainda abertos: remoção/gerenciamento de amizades, entrega dos convites, faixas de tamanho/velocidade, painéis e estados complementares e pendências técnicas restantes em PLANEJAMENTO.md. Não gerar imagens sem autorização específica.

## Estado atual

Projeto exclusivamente Android, Kotlin/Compose, Media3 e Supabase; distribuição por APK. Planejamento em PLANEJAMENTO.md. Não há aplicativo, backend ou APK implementado/testado.

Sete referências visuais aprovadas:

- Home: docs/design/home-aprovada.png, original preservada.
- Criar sala: docs/design/criar-sala-aprovada.png, nome e interruptor Sala pública, sem explicações longas.
- Entrar em sala: docs/design/entrar-sala-aprovada.png, código no topo e convites de amigos abaixo.
- Player vertical: docs/design/player-vertical-aprovado.png, vídeo e chat sem barra de atalhos ou botão de adicionar vídeo.
- Player horizontal: docs/design/player-horizontal-aprovado.png, com mensagem pequena sobre o vídeo; tamanho mostrado aprovado como padrão.
- Configurações: docs/design/configuracoes-aprovada.png, somente os quatro botões pedidos.
- Salas públicas: docs/design/salas-publicas-aprovada.png, busca e cards; miniaturas provisórias.

Usuário autorizou explicitamente enviar as duas últimas referências ao GitHub e pediu registrar o sistema de amizade no planejamento. Novas imagens fora dessas referências continuam exigindo autorização. Não tratar design aprovado como implementação/teste.

## Próxima etapa

Estado mais recente: usuário aprovou a tela 07 (“gostei pode mandar pro git”) e autorizou envio de salas-publicas-aprovada.png. Telas principais 01 a 07 aprovadas visualmente, sem implementação/testes. Próxima etapa prevista: painéis da sala, começando por Fila e Adicionar vídeo (acesso pelos três pontos). Também pendem participantes, convite, chat horizontal aberto, painéis das configurações, amizade e estados complementares. Miniatura padrão definitiva ainda não selecionada; aprovação do layout não transforma o marcador provisório em arte definitiva. Registros abaixo são histórico.

Atualização: Configurações aprovada enviada ao GitHub (bc47423). Modelo da tela 07 — Todas as salas públicas apresentado no chat, ainda não aprovado: busca, cinco cards de exemplo com miniatura neutra repetida, nome e quantidade. Card inteiro dá entrada direta. Imagem padrão definitiva ainda não escolhida/aprovada; placeholders são provisórios. Aguardar avaliação; sem publicação da arte da tela 07, implementação ou teste. Estados vazio/erro/carregamento e painéis continuam pendentes.

Estado mais recente: tela 06 aprovada e envio de configuracoes-aprovada.png ao GitHub autorizado. Usuário pediu seguir para tela 07 — Todas as salas públicas. Painéis internos das quatro opções continuam pendentes. Sem implementação ou testes Android. Histórico abaixo não representa o status atual de aprovação.

Último pedido: Configurações deve conter por enquanto só Mudar apelido, Configuração de mensagem, Notificações e Sobre o app, todos como botões que abrem painéis. Reprodução, avatar e demais ajustes de chat adiados. Nova prévia de quatro botões apresentada e planejamento atualizado; aguardar avaliação visual. Sem envio ao GitHub, implementação ou teste nesta etapa.

Revisão atual de Configurações: usuário pediu Mensagens sobre o vídeo como botão de lista que abre painel, igual aos demais, e explicação das opções. Nova prévia apresentada com perfil e cinco botões; sem controles expandidos. Ajustes de posição/tamanho/velocidade ficam no painel aberto por esse botão. Demais categorias ainda precisam de definição interna. Aguardar avaliação da composição; sem publicação, implementação/testes nesta etapa.

Avanço mais recente: modelo da tela 06 — Configurações apresentado a pedido do usuário. Avatar/apelido, posição/tamanho/velocidade das mensagens, prévia e acessos Reprodução/Notificações/Chat/Sobre. Aguardar revisão visual. Nenhuma nova aprovação, publicação de arte, implementação ou teste nesta etapa. Opções internas e parâmetros ainda pendentes. Preferências de mensagens ficam nesta tela conforme confirmação explícita; preservar tamanho padrão aprovado do player horizontal.

**Estado atual:** usuário aprovou o player horizontal com mensagem sobreposta, confirmou o tamanho mostrado como padrão e autorizou enviar ao GitHub. Função consolidada no planejamento: mensagens recebidas passam lentamente da esquerda para a direita e têm ajustes de posição (cima/baixo), tamanho e velocidade nas Configurações. Posição/velocidade iniciais, valores numéricos e tratamento simultâneo pendentes; tamanho é referência visual, ainda sem sp validado. Sem implementação ou teste de animação. Próxima tela principal na ordem: Configurações; painel de chat horizontal aberto e estados complementares também pendentes. Registros abaixo são histórico.

Pedido mais recente: mensagens pequenas sobre o vídeo horizontal movendo lentamente da esquerda para a direita; configurações de cima/baixo, tamanho e velocidade. Requisito registrado no planejamento. Prévia estática apresentada com “Lucas: Que cena linda!” no topo como exemplo; aguardar avaliação visual. Não representa animação testada e não define padrões/faixas. Sem implementação, testes ou envio dessa arte ao GitHub.

Vertical aprovado enviado ao GitHub com documentação no commit d48b1a9. Em seguida, modelo horizontal apresentado no chat: tela imersiva, controles temporários e botão de chat, inicialmente fechado. Aguardar aprovação/comentários; proposta horizontal ainda não aprovada nem enviada ao GitHub. Próximo detalhamento dessa tela: painel de chat aberto e teclado. Sem implementação/testes.

Pedido mais recente: enviar player-vertical-aprovado.png ao GitHub (autorização explícita) e seguir para o modelo horizontal. Layout vertical aprovado, sem botão junto ao chat. Próxima proposta: player horizontal imersivo com chat inicialmente fechado e controles temporários ao toque.

Estado atual: usuário confirmou que o player vertical já estava aprovado e pediu só remover o botão junto a Chat. Edição executada e referência local salva em docs/design/player-vertical-aprovado.png, sem publicação no GitHub. Layout aprovado com essa remoção, sem implementação/testes. Adicionar vídeo continua dentro de Fila nos três pontos; participantes pelo contador. Próxima tela principal na ordem: player horizontal, além dos estados pendentes do vertical. Os registros abaixo são histórico.

Decisão atual confirmada: remover Adicionar vídeo do chat; acesso por três pontos → Fila → Adicionar vídeo, com URL e escolha Reproduzir agora/Adicionar à fila conforme permissão. Participantes pelo contador superior. Planejamento agora explica Fila e Compartilhar nos três pontos; Sair/Encerrar nesse menu são localização proposta, ainda não aprovada. Última imagem do player ficou desatualizada por conter botão Adicionar vídeo ao lado de Chat; atualizar em próxima revisão visual autorizada. Nenhuma imagem, implementação/teste ou envio ao GitHub nesta etapa. Os parágrafos anteriores de proposta abaixo são histórico.

Última revisão do player: contador superior abre participantes; Fila/Compartilhar vão nos três pontos, conforme pedido do usuário. Nova prévia remove barra de atalhos e propõe botão compacto “Adicionar vídeo” junto ao título Chat (adição por URL). Aguardar avaliação dessa revisão; não considerar aprovada. Sem nova publicação, implementação ou testes. Estado sem mídia e demais variantes continuam pendentes.

Modelo do player vertical com chat solicitado e apresentado como proposta no chat. Mostra administrador com vídeo pausado, barra Vídeo/Fila/Pessoas/Convidar e chat com campo inferior. Aguardar avaliação do usuário; ainda não aprovado. Sem envio dessa imagem ao GitHub. Restam estado sem mídia e demais estados, proporção exata da mídia e validação Android; ver DESIGN.md. Nenhum código/teste realizado.

Design do player vertical com chat, incluindo sala ainda sem mídia, mantendo identidade preta/roxa aprovada. Perguntar em caso de dúvida em vez de inventar decisões. Sem sala de espera ou agendamento.

## Sistema de amizade

Confirmado pelo usuário: lista de amigos pelo novo botão Amigos em Configurações, identificação por código único de usuário, solicitação e aceite, mantendo convidado sem login. Sem recuperação após reinstalar ou trocar de aparelho na primeira versão. Convites internos exibidos em Entrar em sala, válidos até uso ou encerramento da sala. Lista/gerenciamento, remoção e envio/entrega de convites ainda precisam de detalhamento e design.

## Decisões consolidadas

- MP4/HLS gravados inicialmente; YouTube depois; sem lives.
- Convidado com apelido e identidade no aparelho; até 10 participantes.
- Administrador controla e concede permissões individuais, inclusive para fila.
- Criar ou entrar leva diretamente ao player e chat. Início manual; entrada acompanha estado atual; próximo vídeo automático.
- Travamento individual não pausa os demais; realinhar ao recuperar. Áudio em segundo plano.
- Transferência manual ou para conectado há mais tempo; tolerância de queda de 60 segundos.
- Último saindo voluntariamente encerra; última conexão perdida tem 60 segundos.
- Encerrar para todos exige confirmação. Mensagens somente após entrada, apagadas ao encerrar.
- Expulsão e bloqueio da identidade, com limite contra spam.
- Até três salas reais na Home, ordenadas por participantes e depois recência.
- Imagem padrão dos cards ainda sem arquivo aprovado.
- Player vertical limitado à metade da área útil para vídeo vertical, preservando proporção.
- Sala pública: ligado=pública, desligado=privada; padrão inicial ligado.

## Pendências

Consultar PLANEJAMENTO.md para pendências técnicas e funcionais completas e DESIGN.md para inventário atualizado. Estados de erro, carregamento, teclado e convites vazios das telas aprovadas ainda precisam de detalhamento/validação.

## Como retomar

Ler AGENTS.md, README.md, PLANEJAMENTO.md, DESIGN.md e este arquivo. Consultar as sete referências aprovadas. Próxima etapa prevista: painéis Fila/Adicionar vídeo. Não redesenhar as referências nem gerar novas imagens sem autorização.
