# Controle de design

Atualizado em 08/11/2026. “Aprovado” significa aprovação visual do usuário; não significa tela implementada.

| Item | Design | Implementação | Próxima ação |
|---|---|---|---|
| 01 — Home | Referência aprovada | Não iniciada | Preservar referência; aplicar regras funcionais na implementação |
| 02 — Criar sala | Pendente | Não iniciada | Próximo design a trabalhar |
| 03 — Entrar em sala | Pendente | Não iniciada | Elaborar após Criar sala |
| 04 — Player vertical | Pendente | Não iniciada | Incluir estado sem mídia e controles |
| 05 — Player horizontal | Pendente | Não iniciada | Imersão e painel de chat |
| 06 — Configurações | Pendente | Não iniciada | Definir opções |
| 07 — Todas as salas públicas | Pendente | Não iniciada | Busca, lista e estados vazios |
| Painel Adicionar vídeo | Pendente | Não iniciado | URL, validação e ações |
| Painel Fila | Pendente | Não iniciado | Permissões, organizar e remover |
| Painel Participantes | Pendente | Não iniciado | Convite, permissões, expulsão e transferência |
| Painel Chat horizontal | Pendente | Não iniciado | Sobreposição e teclado |

## Referência aprovada

![Home](design/home-aprovada.png)

- Original fornecido pelo usuário: “Tela inicial neon roxa com salas públicas.png”.
- Copiado sem edição como home-aprovada.png, com autorização explícita para envio ao GitHub.
- Não gerar, modificar ou enviar outras imagens sem autorização explícita.
- Manter preto/roxo profundo, brilho roxo, cantos arredondados, branco legível, ícones consistentes e aparência cinematográfica.

## Diferenças entre a ilustração e as regras aprovadas

A imagem continua intacta. As decisões funcionais posteriores devem orientar a implementação:

1. Os exemplos mostram 12 e 15 pessoas, mas o limite aprovado é 10 por sala.
2. A imagem tem três salas; o aplicativo mostra até três reais e estado vazio quando necessário.
3. Há botões com símbolo de play nos cards. A regra textual permite somente imagem, nome e quantidade; entrada pelo próprio card, sem indicador de reprodução. Não interpretar os símbolos como estado de reprodução. A eventual revisão visual deve ser apresentada ao usuário antes de alterar a referência aprovada.
4. As miniaturas são diferentes na imagem, mas a decisão para a primeira versão é uma única imagem padrão aprovada. O arquivo dessa miniatura ainda precisa ser selecionado/aprovado; não extrair, criar ou alterar arte silenciosamente.

## Checklist para cada próximo design

- Seguir a identidade da Home sem substituir seu conceito.
- Registrar proposta separadamente de aprovação.
- Cobrir estado normal, vazio, carregando, erro e falta de permissão quando aplicável.
- Verificar legibilidade, teclado, diferentes tamanhos de celular e navegação.
- Não inserir espera, agendamento ou campo de código na Home.
- Após aprovação, adicionar referência autorizada e atualizar esta tabela e CONTINUIDADE.md.
