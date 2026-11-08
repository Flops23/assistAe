# Controle de design

Atualizado em 08/11/2026. Aprovação visual não significa implementação ou teste Android.

| Item | Design | Implementação | Próxima ação |
|---|---|---|---|
| 01 — Home | Aprovado | Não iniciada | Preservar referência e seguir regras funcionais |
| 02 — Criar sala | Aprovado | Não iniciada | Definir padrão inicial do interruptor e estados complementares |
| 03 — Entrar em sala | Aprovado | Não iniciada | Detalhar estados sem convites, carregamento e erros |
| 04 — Player vertical | Aprovado com remoção do botão | Não iniciada | Referência local atualizada; detalhar estado sem mídia e proporções |
| 05 — Player horizontal | Aprovado com mensagem sobreposta | Não iniciada | Detalhar painel de chat e ajustes de mensagens |
| 06 — Configurações | Aprovado | Não iniciada | Referência em design/configuracoes-aprovada.png; detalhar painéis |
| 07 — Todas as salas públicas | Aprovado | Não iniciada | Escolher imagem padrão e detalhar estados |
| Sistema de amizade — lista e gerenciamento | Pendente | Não iniciado | Definir acesso, identificação e fluxo de amizade |
| Convite de amigos para sala | Pendente | Não iniciado | Definir envio; recebimento já representado em Entrar em sala |
| Painel Adicionar vídeo | Pendente | Não iniciado | Dentro de Fila: URL, validação e ações |
| Painel Fila | Pendente | Não iniciado | Pelos três pontos; adicionar, organizar e remover |
| Painel Participantes | Pendente | Não iniciado | Convite, permissões, expulsão e transferência |
| Painel Chat horizontal | Pendente | Não iniciado | Sobreposição e teclado |

## Home aprovada

![Home](design/home-aprovada.png)

Original fornecido pelo usuário e preservado sem edição. Manter preto/roxo profundo, brilho roxo, cantos arredondados, branco legível e aparência cinematográfica.

Divergências entre imagem e regras aprovadas:

1. Os exemplos mostram 12 e 15 pessoas; limite aprovado é 10.
2. A imagem mostra três salas; o aplicativo exibe até três reais e estado vazio quando necessário.
3. Cards devem conter somente imagem, nome e quantidade, com entrada pelo card. Símbolos de play da referência não indicam estado de reprodução; não alterar silenciosamente a arte.
4. A primeira versão usará uma imagem padrão para todos os cards; arquivo ainda não selecionado/aprovado. Não extrair ou criar miniaturas sem autorização.

## Criar sala aprovada

![Criar sala](design/criar-sala-aprovada.png)

Usuário aprovou a revisão simplificada em 08/11/2026: nome, interruptor “Sala pública” e botão “Criar sala”. Ligado = pública; desligado = privada. A imagem exemplifica ligado, mas o padrão inicial ainda não foi definido. Espaço para futuras opções, sem inventá-las. Sem textos explicativos longos nem cards separados de visibilidade.

Administrador controla por padrão e pode autorizar participantes dentro da sala. Criar leva diretamente ao player sem mídia e com chat; sem espera ou agendamento.

Arte criada pela ferramenta integrada de imagens, revisando a proposta anterior para remover subtítulo, explicações e cards Pública/Privada, mantendo a identidade preta/roxa. Referência aprovada copiada sem edição para o projeto.

## Entrar em sala aprovada

![Entrar em sala](design/entrar-sala-aprovada.png)

Usuário aprovou em 08/11/2026: campo “Código da sala” e botão “Entrar” na parte superior; abaixo, “Convites de amigos”. Cards mostram nome do amigo, sala e botão Entrar. Lucas, Marina e nomes de salas são exemplos ilustrativos.

Arte criada pela ferramenta integrada de imagens a partir do modelo anterior: entrada por código agrupada no topo e dois exemplos compactos de convites abaixo, sem ações adicionais. Referência aprovada copiada sem edição para o projeto. Entrada leva diretamente ao player com chat.

Sistema de amizade confirmado pelo usuário e registrado no planejamento. Identificação, adição/remoção, envio e validade dos convites e ponto de acesso à lista ainda precisam ser definidos; não presumir login nem fluxo de amizade.

## Aprovações e validação

### Tela 07 — Todas as salas públicas: proposta em 08/11/2026

**Estado atual: aprovado.** Usuário disse “gostei pode mandar pro git”, autorizando envio da referência. Arquivo preservado sem edição em [Salas públicas aprovada](design/salas-publicas-aprovada.png). Aprovação da composição não seleciona uma imagem padrão definitiva: os marcadores de miniatura são provisórios. Salas/contagens são exemplos. Sem implementação ou teste. Registro abaixo é histórico da proposta.

![Salas públicas aprovada](design/salas-publicas-aprovada.png)

Configurações enviada ao GitHub no commit bc47423. A pedido do usuário, modelo da tela 07 gerado pela ferramenta integrada e apresentado no chat. Referências de estilo: Home e Configurações aprovadas. Prompt: título Salas públicas, busca por nome, lista de cards contendo só miniatura/nome/quantidade, sem play ou botão Entrar, ordenados por participantes. Cinco salas e contagens são exemplos ilustrativos (não dados reais). Mesma miniatura neutra provisória em todos os cards; não é aprovação da imagem padrão definitiva, ainda pendente. Inspeção visual: busca, cinco cards e contagens abaixo do limite presentes. Prévia aguarda aprovação, sem envio dessa imagem ao GitHub, implementação ou testes. Ainda faltam estados sem salas, sem resultados, carregando, falha e validação com teclado/Android.

### Tela 06 — Configurações: proposta em 08/11/2026

**Estado atual: aprovado.** Usuário autorizou envio ao GitHub e pediu seguir para tela 07. Referência preservada sem edição em [Configurações aprovada](design/configuracoes-aprovada.png): somente quatro botões — Mudar apelido, Configuração de mensagem, Notificações e Sobre o app. Painéis internos ainda pendentes. Não implementada/testada. Histórico abaixo não altera esse status.

Revisão atual: usuário limitou a tela a Mudar apelido, Configuração de mensagem, Notificações e Sobre o app, deixando os demais itens para depois. Nova prévia gerada pela ferramenta integrada com exatamente quatro botões; perfil/avatar inline, Reprodução e Chat removidos. Prompt restrito a essa simplificação mantendo identidade visual. Inspeção visual confirma quatro linhas e ausência dos itens retirados. Escopo registrado no planejamento; composição revisada ainda aguarda aprovação visual, sem publicação, implementação ou teste. Histórico abaixo está substituído por essa decisão.

Última revisão solicitada: transformar Mensagens sobre o vídeo em botão igual aos demais, abrindo painel ao tocar. Nova imagem gerada a partir da prévia anterior, removendo bloco expandido e mantendo perfil e cinco linhas: Mensagens sobre o vídeo, Reprodução, Notificações, Chat e Sobre o aplicativo. Prompt limitado a essa reorganização; inspeção visual confirma botão e remoção dos controles expandidos. Comportamento solicitado registrado no planejamento; composição completa ainda aguarda aprovação. Nenhuma publicação, implementação ou teste. Reprodução/Notificações/Chat continuam categorias sem conteúdo interno definido; explicação deve distingui-las de funcionalidades aprovadas.

Usuário confirmou que os ajustes das mensagens ficam na tela 06 e pediu seu modelo. Prévia gerada pela ferramenta integrada e apresentada no chat: avatar/apelido; grupo “Mensagens sobre o vídeo” com posição cima/baixo, controle de tamanho, controle de velocidade e exemplo; acessos Reprodução, Notificações, Chat e Sobre o aplicativo. Prompt usou Criar sala como referência visual, pediu interface concisa, sem login ou opções internas inventadas. Valores “Em cima” e “Lenta” são exemplos; tamanho Padrão remete à referência aprovada do horizontal, sem definir número. A prévia ampliada de texto nas configurações é ilustrativa e não substitui a referência de tamanho no player. Inspeção visual: controles/textos presentes e sem cortes aparentes. Proposta ainda não aprovada nem enviada ao GitHub; sem implementação/teste. Detalhes das seções internas, salvamento das preferências, faixas de ajuste, teclado e responsividade permanecem pendentes.

### Player horizontal — proposta em 08/11/2026

**Estado atual: aprovado.** Usuário aprovou a função e o tamanho pequeno da mensagem como padrão e autorizou enviar esta referência ao GitHub. Arquivo copiado sem edição para [Player horizontal aprovado](design/player-horizontal-aprovado.png). Requisito de movimento lento da esquerda para a direita e configurações de posição/tamanho/velocidade registrado em PLANEJAMENTO.md. Tamanho padrão é referência visual, sem inventar valor em sp. Posição/velocidade iniciais e faixas ainda pendentes; topo é exemplo. Prévia estática não é animação implementada ou testada. Os parágrafos abaixo são histórico de elaboração, não o status atual de aprovação.

![Player horizontal aprovado](design/player-horizontal-aprovado.png)

Revisão solicitada: mensagens pequenas passando lentamente da esquerda para a direita sobre o vídeo, com posição (cima/baixo), tamanho e velocidade configuráveis. Nova prévia estática gerada pela ferramenta integrada a partir do horizontal anterior: uma mensagem “Lucas: Que cena linda!” no topo abaixo dos controles, autor lilás e texto branco. Prompt restrito a adicionar uma mensagem discreta, preservando os demais elementos. Inspeção visual: texto presente e legível; imagem representa apenas um instante, não demonstra animação/velocidade. Posição superior é exemplo, não padrão aprovado. Visual ainda aguarda aprovação; sem implementação/teste, publicação no GitHub ou nova arte aprovada. Faixas, padrões e mensagens simultâneas pendentes.

Após envio do vertical aprovado ao GitHub (commit d48b1a9), modelo horizontal gerado com ferramenta integrada e apresentado no chat. Prompt: mesma sala e mídia ilustrativa em paisagem, vídeo imersivo sem barras Android, controles temporários, nome da sala, contador de participantes, botão de chat e três pontos; chat inicialmente fechado. Inspeção visual: composição e controles presentes. Ícone inferior de saída da tela cheia ainda deve ter semântica visual validada no detalhamento. Modelo ainda não aprovado, sem publicação da nova arte, implementação ou teste. Painel de chat aberto, teclado, falta de permissão, reconexão e rotação sem perder estado ainda pendentes.

### Proposta do player vertical — 08/11/2026

Usuário autorizou posteriormente o envio de player-vertical-aprovado.png ao GitHub e pediu seguir para o player horizontal. A autorização de envio é específica para essa referência.

Estado atual: usuário esclareceu que a tela já estava aprovada e pediu somente retirar o botão Adicionar vídeo do chat. Edição realizada com a ferramenta integrada, usando a última prévia como alvo; prompt restrito a remover esse botão e preencher seu fundo, preservando os demais elementos. Resultado inspecionado visualmente: botão removido, composição mantida. Referência local em [Player vertical aprovado](design/player-vertical-aprovado.png). Sem envio dessa arte ao GitHub. Aprovação cobre essa composição com mídia; variantes/estados e validação Android seguem pendentes. Histórico abaixo não representa o status atual.

Decisão mais recente: usuário confirmou retirar “Adicionar vídeo” do chat e colocar a ação dentro de Fila. Caminho: três pontos → Fila → Adicionar vídeo → URL → Reproduzir agora ou Adicionar à fila, conforme permissão. Participantes pelo contador; Fila e Compartilhar nos três pontos. Explicação registrada em PLANEJAMENTO.md, distinguindo os itens confirmados da proposta de localização de Sair/Encerrar. A última imagem ainda contém o botão junto a Chat e está desatualizada nesse ponto; nenhuma nova arte foi gerada nesta etapa. O player completo e o menu ainda aguardam aprovação visual. Sem implementação ou teste.

Revisão posterior: usuário pediu participantes pelo contador superior e Fila/Compartilhar nos três pontos. Barra de quatro atalhos removida na nova prévia. “Vídeo” foi explicado como adicionar por URL e renomeado para “Adicionar vídeo”; posição ao lado de Chat é proposta, ainda não aprovada. Menu mostrado fechado. Prompt de edição: preservar visual, remover barra, manter contador e menu, adicionar botão compacto e ampliar quadro de vídeo para aproximar 16:9. Inspeção visual: barra removida, chat/compositor presentes, proporção mais próxima; preservação exata da mídia ainda requer validação. Nova composição aguarda avaliação, sem implementação/teste Android ou envio ao GitHub. Registro anterior abaixo é histórico.

Usuário pediu um modelo após o envio das duas telas aprovadas. Nova prévia gerada pela ferramenta integrada de imagens, com Entrar em sala como referência de estilo. Prompt: tela Android vertical preta/roxa, cabeçalho com nome/participantes/menu, vídeo até as bordas com controles temporários, ações Vídeo/Fila/Pessoas/Convidar, chat abaixo e campo fixo inferior. Exemplo de administrador com vídeo pausado; nomes, mensagens, mídia e tempos são ilustrativos. Modelo apresentado no chat, ainda não aprovado nem enviado ao GitHub.

Inspeção visual: ações e chat presentes, vídeo até as bordas. Arte ilustrativa não comprova proporção da mídia; o quadro gerado é mais largo que o 16:9 solicitado no prompt. Preservação exata da proporção original continua requisito, a ajustar/validar nas próximas revisões. Ainda faltam estado sem mídia, vídeo vertical limitado à metade da área útil, visitante sem permissão, carregamento/erros, teclado e validação Android. Nenhuma implementação ou teste funcional.

Usuário autorizou explicitamente enviar as duas telas novas ao GitHub em 08/11/2026. A autorização é específica para essas referências; novas imagens continuam exigindo autorização. Home preservada.

As composições geradas foram inspecionadas visualmente. Nenhum código Android, backend ou APK implementado ou testado. Ainda não validados teclado, tamanhos de celular, acessibilidade ou estados complementares.

## Checklist para próximos designs

- Seguir identidade das telas aprovadas e distinguir proposta de aprovação.
- Cobrir normal, vazio, carregamento, erro e falta de permissão quando aplicável.
- Verificar legibilidade, teclado, diferentes tamanhos e navegação.
- Sem espera, agendamento ou campo de código na Home.
- Atualizar este documento e CONTINUIDADE.md a cada avanço.
