# Controle de design

Atualizado em 08/11/2026. Aprovação visual não significa implementação ou teste Android.

| Item | Design | Implementação | Próxima ação |
|---|---|---|---|
| 01 — Home | Aprovado | Não iniciada | Preservar referência e seguir regras funcionais |
| 02 — Criar sala | Aprovado | Não iniciada | Definir padrão inicial do interruptor e estados complementares |
| 03 — Entrar em sala | Aprovado | Não iniciada | Detalhar estados sem convites, carregamento e erros |
| 04 — Player vertical | Pendente | Não iniciada | Próximo design; incluir estado sem mídia e chat |
| 05 — Player horizontal | Pendente | Não iniciada | Imersão e painel de chat |
| 06 — Configurações | Pendente | Não iniciada | Definir opções |
| 07 — Todas as salas públicas | Pendente | Não iniciada | Busca, lista e estados vazios |
| Sistema de amizade — lista e gerenciamento | Pendente | Não iniciado | Definir acesso, identificação e fluxo de amizade |
| Convite de amigos para sala | Pendente | Não iniciado | Definir envio; recebimento já representado em Entrar em sala |
| Painel Adicionar vídeo | Pendente | Não iniciado | URL, validação e ações |
| Painel Fila | Pendente | Não iniciado | Permissões, organizar e remover |
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

Usuário autorizou explicitamente enviar as duas telas novas ao GitHub em 08/11/2026. A autorização é específica para essas referências; novas imagens continuam exigindo autorização. Home preservada.

As composições geradas foram inspecionadas visualmente. Nenhum código Android, backend ou APK implementado ou testado. Ainda não validados teclado, tamanhos de celular, acessibilidade ou estados complementares.

## Checklist para próximos designs

- Seguir identidade das telas aprovadas e distinguir proposta de aprovação.
- Cobrir normal, vazio, carregamento, erro e falta de permissão quando aplicável.
- Verificar legibilidade, teclado, diferentes tamanhos e navegação.
- Sem espera, agendamento ou campo de código na Home.
- Atualizar este documento e CONTINUIDADE.md a cada avanço.
