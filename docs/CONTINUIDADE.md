# Ponto de continuidade

Atualizado em 08/11/2026.

## O que o usuário pediu por último

Salvar o planejamento no GitHub, guardar a imagem enviada como design atual aprovado da Home e deixar claro quais telas estão prontas e quais faltam, para poder trocar de modelo e continuar normalmente. Depois, continuar o design das telas.

## Entregue nesta etapa

- Planejamento original e decisões da rodada de perguntas consolidados em PLANEJAMENTO.md.
- Referência original da Home em design/home-aprovada.png, sem edição.
- Inventário de telas/painéis e divergências visuais em DESIGN.md.
- Instruções de preservação e continuidade em AGENTS.md.
- Nenhum código Android, backend ou APK foi implementado nesta etapa.

## Próximo passo

Trabalhar o design da tela 02 — Criar sala, usando a Home como referência. Deve conter nome, pública/privada, permissões e Criar sala. A ação leva diretamente ao player; não criar espera nem agendamento.

O pedido de salvar a imagem original não é autorização geral para gerar novas imagens. Antes de produzir/enviar uma nova imagem de tela, obter autorização explícita. É possível avançar na descrição de layout e textos sem modificar a arte aprovada.

## Decisões que não precisam ser perguntadas novamente

- MP4/HLS gravados inicialmente; YouTube depois; sem lives na primeira versão.
- Convidado com apelido e identidade no aparelho; 10 pessoas por sala.
- Administrador controla e concede permissões individuais, inclusive para adicionar à fila.
- Início manual; entrada acompanha estado atual; próximo vídeo automático.
- Travamento individual não pausa a sala; realinhar ao recuperar.
- Áudio em segundo plano.
- Transferência manual ou para conectado há mais tempo; tolerância de queda de 60 segundos.
- Último saindo voluntariamente encerra imediatamente; última conexão perdida tem 60 segundos.
- Administrador pode encerrar para todos com confirmação.
- Somente mensagens posteriores à entrada; apagar ao encerrar.
- Expulsão e bloqueio da mesma identidade, com limite contra spam.
- Até três salas reais na Home, ordenadas por participantes e depois recência.
- Convite por código; imagem padrão aprovada para cards.
- Conteúdo vertical com player limitado à metade da área útil.

## Como retomar em outro modelo

Solicitação sugerida: “Continue o assistAe neste repositório. Leia AGENTS.md, docs/PLANEJAMENTO.md, docs/DESIGN.md e docs/CONTINUIDADE.md. A Home está aprovada; a próxima tela é Criar sala. Preserve as decisões e não gere nem envie novas imagens sem minha autorização.”

Manter este arquivo atualizado após cada etapa. Não depender do histórico do chat para decisões de produto.
