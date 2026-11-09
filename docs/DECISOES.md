# Registro de fechamento do planejamento

09/11/2026. Índice único de decisões abertas, com rastreabilidade aos documentos técnicos. Não aprova propostas por omissão. Não autoriza implementação. PLANEJAMENTO.md continua fonte das regras de produto; registros históricos de pendência não reabrem decisões confirmadas.

<a id="decisoes-confirmadas"></a>

## Confirmado — não perguntar novamente

- Android nativo, Kotlin/Compose/Media3/Supabase, APK; design existente e mesmos cards.
- MP4/HLS gravados inicialmente; YouTube depois; sem lives, sala de espera ou agendamento.
- Até 10 participantes, sala pública por padrão, uma sala por pessoa.
- Convidado sem login visível, amizade por código/solicitação/aceite, sem recuperação após reinstalar.
- Reserva de vaga por 60 segundos após detectar a queda (P01 confirmado); mecanismo e parâmetros da detecção continuam técnicos a especificar.
- Reconexão mostra mensagens novas e mantém as já vistas localmente; não busca intervalo desconectado.
- Saída do administrador com os demais reconectando preserva reservas e deixa administração temporariamente ausente até retorno.
- Play inicial promove primeiro da fila sem início ao adicionar; Play após último vídeo reinicia esse vídeo. Próximo automático para duração confiável; fonte reproduzível inconclusiva exige avanço manual por autorizado (P03).
- Animação horizontal uma por vez em ordem, esquerda→direita, inicialmente embaixo; pular antigas excedentes sem apagar chat.
- Convite válido até uso/encerramento; notificações de convite e amizade também fora do app.
- Notificações salvam interruptores automaticamente; demais ações seguem modelos aprovados.
- Começar com teste fechado entre amigos. Nenhum valor numérico proposto além das decisões explícitas foi aprovado por esse contexto.

<a id="decisoes-p01-p03"></a>

## Lote P01–P03 — confirmado

| ID | Escolha | Recomendação/impacto | Situação |
|---|---|---|---|
| P01 <a id="p01"></a> | Origem dos 60 s | Contar após detectar a queda; frequência/mecanismo de detecção continuam técnicos | Confirmado em 09/11/2026 |
| P02 <a id="p02"></a> | Primeiro Play com fila e player vazio | Play inicia primeiro item; adicionar à fila sozinho não inicia | Confirmado em 09/11/2026 |
| P03 <a id="p03"></a> | Duração de fonte inconclusiva | Permitir reprodução; usuário autorizado avança ao terminar, como exceção ao avanço automático | Confirmado em 09/11/2026 |

P03 não significa que usuário comum pode declarar fim e controlar todos. Resultado inconclusivo não equivale a formato inválido. As três escolhas foram respondidas explicitamente pelo usuário; parâmetros técnicos e interface final da ação manual continuam propostos.

<a id="decisoes-p04-p15"></a>

## Lotes P04–P15 — confirmados

Lote P04–P06 confirmado explicitamente em 09/11/2026: aplicar reconexão normal se Android suspender app pausado/sem mídia; contar visualmente somente conectados; ex-admin conserva apenas sua autorização individual anterior. P04 não altera áudio em segundo plano durante reprodução. P05 não libera vagas reservadas. P06 conserva can_control independente do papel de admin; quem nunca recebeu essa permissão fica sem controle ao transferir.

| ID | Tema | Decisão confirmada | Documentos afetados |
|---|---|---|---|
| P04 <a id="p04"></a> — confirmado | Presença em background sem reprodução | Suspensão segue reconexão normal e reserva de 60 s após detecção | ANDROID-INFRA, ALGORITMOS, testes A05 |
| P05 <a id="p05"></a> — confirmado | Contagem visível | Somente conectados; reservas continuam ocupando capacidade | BANCO, Home/listagem |
| P06 <a id="p06"></a> — confirmado | Controle do ex-administrador | Preservar somente autorização individual prévia | CONTRATOS |
| P07 <a id="p07"></a> — confirmado em 09/11/2026 | Solicitação cruzada/cancelamento/remoção de amizade | Aceite explícito; remetente cancela enquanto pendente; qualquer envolvido remove amizade bilateral com confirmação; convites emitidos preservados até uso/encerramento | BANCO, CONTRATOS |
| P08 <a id="p08"></a> — confirmado em 09/11/2026 | Apelido em mensagens antigas | Preservar apelido usado no envio, mesmo após alteração do perfil | BANCO, cache/chat |
| P09 <a id="p09"></a> — confirmado em 09/11/2026 | Repetir URL na fila | Permitir itens independentes para cada adição intencional; retry do mesmo pedido não duplica item | CONTRATOS/fila |
| P10 <a id="p10"></a> — confirmado em 09/11/2026 | Padrão dos avisos e privacidade em tela bloqueada | Ambos ligados; tela bloqueada usa “Você recebeu um convite” ou “Nova solicitação de amizade”, sem nomes; permissão Android continua necessária | PARAMETROS, push |
| P11 <a id="p11"></a> — confirmado em 09/11/2026 | Chat após morte do processo | Somente memória nesta versão; morte do processo perde cache; queda/rotação no mesmo processo preservam já vistas; nunca recuperar intervalo desconectado | ANDROID-INFRA |
| P12 <a id="p12"></a> — confirmado em 09/11/2026 | Sobreposição de mensagem longa/rotação | Reticências só na animação, texto inteiro no chat; repetir do início a animação interrompida por rotação, antes das próximas em ordem | DESIGN, ALGORITMOS |
| P13 <a id="p13"></a> — confirmado em 09/11/2026 | Voltar/Parar externo e saltos | Voltar fecha teclado/painel; horizontal retorna ao vertical; vertical confirma saída. Parar externo só local, sem pausar demais/encerrar sala, com possível reconexão. Saltos de 10 s por autorizado | ANDROID-INFRA, CONTRATOS |
| P14 <a id="p14"></a> — confirmado em 09/11/2026 | Protocolos de mídia | Aceitar HTTP e HTTPS para fontes diretas MP4/HLS gravadas; URLs assinadas permanecem permitidas; sem adicionar login/cookies de terceiros | Validador/player |
| P15 <a id="p15"></a> — confirmado em 09/11/2026 | Limites iniciais de uso | Apelido 2–24 caracteres; sala 2–60; mensagem até 500; fila até 50 próximos; até 5 animações pendentes, pular espera maior que 20 s; preservar chat e animação em curso repetida na rotação | PARAMETROS, validação UI/API |

Não apresentar todos esses itens de uma vez ao usuário. Agrupar por impacto e aproveitar respostas existentes. Reproduzir agora mantém sentido de ação explícita; decidir apenas os casos ainda ambíguos, sem reabrir o fluxo aprovado.

Lote P10–P12 respondido explicitamente em 09/11/2026. P12 foi escolhido com repetição da animação interrompida, diferente da recomendação apresentada de não repetir. Não reapresentar P01–P12. P13–P15 também foram confirmados no lote seguinte.

Lote P13–P15 respondido explicitamente em 09/11/2026: P13/P15 adotados; P14 aceita HTTP e HTTPS, diferente da recomendação de somente HTTPS. Animação em curso interrompida pela rotação não entra no descarte de pendentes. P01–P15 confirmados; não reapresentar. Isso fecha o conjunto de escolhas catalogadas, sem encerrar a especificação técnica ou autorizar código.

<a id="trabalho-tecnico"></a>

## Trabalho técnico a concluir sem delegar jargão ao usuário

A [revisão cruzada](CONSISTENCIA.md#resultado) conciliou divergências do desenho lógico, sem concluir T01–T11 ou aprovar mecanismos por omissão.

Organização de execução proposta em [BLOCOS.md](BLOCOS.md): T01–T11 e informações operacionais alimentam o fechamento restante de B00. P01–P15 estão confirmados e não devem ser reapresentados. A divisão em blocos não encerra o planejamento nem autoriza programação.

| ID | Resultado necessário | Dependência/critério de fechamento |
|---|---|---|
| T01 <a id="t01"></a> | Especificação final de leases/sucessão | Revisão em CONSISTENCIA alinhou campos/fase efetiva/deadline e fronteira pós-lock. Restam H/D/S, prova do sinal de transporte e variantes de eleição/admin expirado/novos entrantes |
| T02 <a id="t02"></a> | Modelo final consistente | Revisão lógica conciliou nulabilidade, FKs, revisões, geração/janelas e modelos de avaliação/contexto/outbox. Restam detalhamento final de constraints/índices, retenção e revisão de integração, sem migração |
| T03 <a id="t03"></a> | API final de mídia/avanço | Avaliação assíncrona/referência obrigatória/snapshot e término derivado conciliados; P02/P03 preservados. Restam executor, ciclo do worker/resultado tardio, fonte mutável/proveniência e erros/limites finais |
| T04 <a id="t04"></a> | Seleção de executor/serviços | Comparar validador e push com capacidades, custo e limites, sem provisionar |
| T05 <a id="t05"></a> | Segurança executável em especificação | Fechar grants/predicados/owner das funções, revogação de canais e propriedade de token, sem escrever migração |
| T06 <a id="t06"></a> | Bootstrap do teste fechado | Método para liberar amigos mantendo identidade anônima; não embutir senha no APK |
| T07 <a id="t07"></a> | Parâmetros de engenharia | Congelar candidatos de heartbeat/drift/retry como hipóteses de teste; não exigir do usuário escolha de algoritmo numérico |
| T08 <a id="t08"></a> | Retenção/restauração | TTL alinhado à idempotência, backups, revogações e exclusão de identidade |
| T09 <a id="t09"></a> | Arquitetura Android final | Um player/coordenador, fronteira de serviço/UI, credenciais/backup e lifecycle definidos |
| T10 <a id="t10"></a> | Matriz de evidência final | Casos ligados a requisitos, ambiente, aparelhos, perfil de rede, limites de exclusões de amostras e responsáveis |
| T11 <a id="t11"></a> | Contratos de erro/eventos | Envelope generation/contexto, RECONNECT_REQUIRED e revisões/invalidações conciliados. Restam transporte final, revogação/audiência e mapeamento de erros/eventos, sem payload sensível em canal antigo |

Escolher tecnicamente uma recomendação documentada não significa declarar implementação testada. É possível fechar design técnico com hipóteses quantitativas explícitas; validação real acontece somente no desenvolvimento autorizado depois.

<a id="informacoes-operacionais"></a>

## Informações operacionais necessárias depois

- Modelos/versões Android dos celulares do teste e presença de serviços Google.
- Número aproximado de amigos simultâneos e duração/frequência das sessões; cenários atuais não são previsão aprovada.
- Responsável pelas contas, distribuição/assinatura e teto mensal aceitável (inclusive preferência por custo zero).
- Forma de entregar APK e como liberar testadores no backend.
- Tolerância a indisponibilidade/perda de dados para desenhar backup e monitoramento.

Não pedir credenciais no chat, não criar contas/chaves nem contratar serviços para obter essas informações.

<a id="fechamento-planejamento"></a>

## Critério de planejamento encerrado

Decisões de produto necessárias resolvidas; banco/contratos/algoritmos sem contradições; arquitetura/serviços selecionados ou alternativa delimitada com critério; parâmetros e riscos documentados; custos e operação compatíveis com teste; matriz de aceite ligada ao escopo. Revisão consolidada com usuário antes de programação. Testes continuam não executados até haver implementação autorizada.

Status atual: registro consolidado; P01–P15 confirmados e regras conciliadas nos documentos técnicos. Revisão técnica T01–T11 e informações operacionais ainda abertas; planejamento não encerrado. Nenhuma imagem, código, infraestrutura, publicação ou teste funcional nesta etapa.
