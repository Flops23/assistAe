# Ponto de continuidade

Atualizado em 08/11/2026.

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

Confirmado pelo usuário: haverá lista de amigos e convites internos de amigos para salas, exibidos em Entrar em sala, além da entrada por código. Lista/gerenciamento e envio de convites ainda aguardam design. Identificação, adição/remoção de amigos, entrega/validade de convites e acesso à lista não foram definidos. Não assumir contas, busca por apelido ou substituir identidade de convidado sem discutir.

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
- Sala pública: ligado=pública, desligado=privada; padrão inicial pendente.

## Pendências

Consultar PLANEJAMENTO.md para pendências técnicas e funcionais completas e DESIGN.md para inventário atualizado. Estados de erro, carregamento, teclado e convites vazios das telas aprovadas ainda precisam de detalhamento/validação.

## Como retomar

Ler AGENTS.md, README.md, PLANEJAMENTO.md, DESIGN.md e este arquivo. Consultar as sete referências aprovadas. Próxima etapa prevista: painéis Fila/Adicionar vídeo. Não redesenhar as referências nem gerar novas imagens sem autorização.
