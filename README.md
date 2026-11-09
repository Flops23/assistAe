# assistAe

Aplicativo nativo Android para assistir a vídeos com amigos em salas públicas ou privadas, com player sincronizado e chat.

**Estado em 08/11/2026:** telas principais 01 a 07 com design aprovado. Sistema de amizade e convites internos confirmado no planejamento. Painéis e estados complementares ainda pendentes. Ainda não há aplicativo implementado nem APK validado.

**Revisão de decisões em 08/11/2026:** sala pública por padrão; amizade por código único com solicitação/aceite e sem login ou recuperação; novo botão Amigos em Configurações, com ajuste visual pendente. Convites válidos até uso ou encerramento da sala. Mensagens horizontais começam embaixo e passam uma por vez, por ordem de chegada ao servidor. Demais decisões registradas no planejamento; nenhuma nova imagem ou implementação nesta revisão.

## Comece aqui

- [Planejamento completo](docs/PLANEJAMENTO.md)
- [Telas aprovadas e pendentes](docs/DESIGN.md)
- [Ponto de continuidade para outro modelo](docs/CONTINUIDADE.md)
- [Instruções para agentes](AGENTS.md)

## Home aprovada

![Home aprovada](docs/design/home-aprovada.png)

A imagem original foi fornecida pelo usuário e seu envio foi autorizado. É uma referência de design, não uma captura de um aplicativo implementado. As divergências entre os exemplos da imagem e as regras funcionais estão registradas em [DESIGN.md](docs/DESIGN.md).

## Outras telas aprovadas

- [Criar sala](docs/design/criar-sala-aprovada.png): nome e interruptor de sala pública/privada.
- [Entrar em sala](docs/design/entrar-sala-aprovada.png): código e convites de amigos.
- [Player vertical](docs/design/player-vertical-aprovado.png): vídeo com chat; participantes pelo contador e Fila/Compartilhar nos três pontos.
- [Player horizontal](docs/design/player-horizontal-aprovado.png): imersivo, com mensagens pequenas passando da esquerda para a direita; tamanho visual aprovado como padrão e ajustes de posição, tamanho e velocidade previstos.
- [Configurações](docs/design/configuracoes-aprovada.png): Mudar apelido, Configuração de mensagem, Notificações e Sobre o app.
- [Salas públicas](docs/design/salas-publicas-aprovada.png): busca por nome e entrada pelo card; miniatura definitiva ainda pendente.

As referências foram aprovadas e seu envio ao GitHub foi autorizado pelo usuário. São modelos estáticos de design, não capturas de aplicativo implementado.

**Painéis aprovados:** [Fila](docs/design/propostas/fila-proposta-v1.png), [Adicionar vídeo](docs/design/propostas/adicionar-video-proposta-v1.png) e [Participantes](docs/design/propostas/participantes-proposta-v1.png), com envio das três referências ao GitHub autorizado. Sem implementação/testes.

**Também aprovados:** [Compartilhar/Convidar](docs/design/propostas/compartilhar-proposta-v1.png), [Chat horizontal aberto](docs/design/propostas/chat-horizontal-proposta-v1.png) e [Amigos](docs/design/propostas/amigos-proposta-v1.png), com envio dessas três referências ao GitHub autorizado. Sem implementação/testes.

**Painéis de Configurações aprovados:** [Mudar apelido](docs/design/propostas/mudar-apelido-proposta-v1.png), [Configuração de mensagem](docs/design/propostas/configuracao-mensagem-proposta-v1.png), [Notificações](docs/design/propostas/notificacoes-proposta-v2.png) e [Sobre o app](docs/design/propostas/sobre-app-proposta-v1.png). Envio autorizado pelo usuário. Notificações usa salvamento automático ao alterar os interruptores, sem botão de salvar.

**Estados e confirmações aprovados:** [Sala sem vídeo](docs/design/propostas/sala-sem-video-proposta-v1.png), [Fim da fila](docs/design/propostas/fim-fila-proposta-v1.png), [Menu da sala](docs/design/propostas/menu-sala-proposta-v1.png), [Encerramento](docs/design/propostas/confirmar-encerrar-proposta-v1.png), [Expulsão](docs/design/propostas/confirmar-expulsar-proposta-v1.png) e [Transferência](docs/design/propostas/confirmar-transferir-proposta-v1.png). Envio dessas seis referências autorizado; somente a versão final corrigida da transferência foi selecionada.

**Ainda pendentes:** demais estados complementares, teclado, saída com sucessor, parâmetros e composição principal de Configurações com Amigos. Miniatura definitiva adiada. Nenhum aplicativo/backend/APK implementado ou testado. Novas imagens exigem autorização específica de envio ao GitHub.
