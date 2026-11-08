# Ponto de continuidade

Atualizado em 08/11/2026.

## Estado atual

Projeto exclusivamente Android, Kotlin/Compose, Media3 e Supabase; distribuição por APK. Planejamento em PLANEJAMENTO.md. Não há aplicativo, backend ou APK implementado/testado.

Três referências visuais aprovadas:

- Home: docs/design/home-aprovada.png, original preservada.
- Criar sala: docs/design/criar-sala-aprovada.png, nome e interruptor Sala pública, sem explicações longas.
- Entrar em sala: docs/design/entrar-sala-aprovada.png, código no topo e convites de amigos abaixo.

Usuário autorizou explicitamente enviar as duas últimas referências ao GitHub e pediu registrar o sistema de amizade no planejamento. Novas imagens fora dessas referências continuam exigindo autorização. Não tratar design aprovado como implementação/teste.

## Próxima etapa

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

Ler AGENTS.md, README.md, PLANEJAMENTO.md, DESIGN.md e este arquivo. Consultar as três referências aprovadas. Próxima tela: player vertical com chat. Não redesenhar as referências nem gerar novas imagens sem autorização.
