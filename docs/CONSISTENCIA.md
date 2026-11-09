# Revisão de consistência — banco, contratos e estados

09/11/2026. Revisão documental solicitada pelo usuário, restrita ao planejamento. P01–P15 preservados. Nenhum SQL executável, código de app, serviço ou teste funcional criado/executado. Conciliações técnicas abaixo são propostas documentadas, não aprovação integral da arquitetura.

<a id="resultado"></a>

## Resultado e causa

Havia refinamentos em ALGORITMOS que não chegaram ao modelo de BANCO nem ao envelope/API de CONTRATOS. Também persistiam descrições anteriores de nulabilidade, validação opcional e encerramento. Isso permitia que cada documento fosse implementado de maneira diferente.

Foram conciliados dez pontos centrais, com ajustes associados de leitura/permissões, FKs, revisões e transições. A conferência documental compara os modelos e as descrições; não prova correção de transações reais ou segurança do sistema funcionando. T01–T11 continuam acompanhados em DECISOES, com as pendências remanescentes abaixo.

<a id="achados"></a>

## Achados e conciliação

| ID | Evidência anterior | Conciliação documental | Fontes atuais |
|---|---|---|---|
| R01 | Algoritmo usava suspect_at sem campo no banco; disconnected_at não distinguia queda física de detecção | connections passa a registrar suspect_at, detected_at e detection_source; fase efetiva e deadline são avaliados após locks. Worker atrasado não reinicia os 60 s | [Dados](BANCO.md#dados-sala), [algoritmo](ALGORITMOS.md#sec-02), [API](CONTRATOS.md#sec-06) |
| R02 | Nulabilidade de admin permitia awaiting_successor, mas outra frase proibia qualquer sala ativa sem admin | Invariantes separados para assigned, awaiting_successor e closed/none; admin em grace conserva papel, sem comandos até reconectar | [Invariantes](BANCO.md#sec-05), [sucessão](ALGORITMOS.md#sec-04) |
| R03 | Algoritmo exigia contexto de validade, ausente no modelo e no envelope comum | Proposta command_contexts persistida, recibos vinculados e envelope command_context_id; bootstrap/heartbeat com exceções explícitas | [Dados internos](BANCO.md#dados-internos), [envelope](CONTRATOS.md#sec-01), [retry](ALGORITMOS.md#sec-11) |
| R04 | Retenção de recibos podia permitir reexecutar pedido velho; assinatura de status não permitia identificar contexto expirado | Sem recibo, contexto inválido impede nova execução; recibo existente só devolve mínimo histórico sem restaurar acesso; status recebe request_id/contexto; TTL/margem ainda abertos | [Idempotência](CONTRATOS.md#sec-03), [modelo](BANCO.md#dados-internos) |
| R05 | Android propunha validação assíncrona, mas API retornava avaliação sem consulta e banco não tinha registro correspondente | media_validations, validateMedia retornando validation_id e getMediaValidation; análise fora dos locks e leitura restrita ao dono/LIVE | [Dados](BANCO.md#dados-reproducao-chat), [API](CONTRATOS.md#sec-07), [fluxo](ALGORITMOS.md#sec-08) |
| R06 | Contrato exigia ticket e confiança, mas add/play recebiam referência opcional e media_items não tinha proveniência/confiança | Referência obrigatória admitida/não vencida; snapshot de avaliação na mídia; termination_mode e expected_end_at derivados, sem cópia mutável conflitante | [Modelo](BANCO.md#dados-reproducao-chat), [contratos](CONTRATOS.md#sec-07) |
| R07 | Outbox mudava para leased e usava token, mas banco não tinha lease_until/attempt_token nem proteção contra conclusão velha | Campos/estados/claims conciliados; conclusão exige leased e token atual; supressão invalida claim, envio continua fora da transação | [Outbox](BANCO.md#dados-internos), [algoritmo](ALGORITMOS.md#sec-12) |
| R08 | API alternava connection_generation, generation e expected_generation | generation é nome comum; expected_generation só na tentativa de reconexão; nova geração reinicia seq e prazo e invalida anterior | [Envelope](CONTRATOS.md#sec-01), [conexões](BANCO.md#dados-sala), [reconexão](ALGORITMOS.md#sec-03) |
| R09 | “Membro vigente” podia incluir grace em leituras; heartbeat em grace não tinha erro específico; retomada sem memória não tinha operação mínima | LIVE/CONTROL/ADMIN uniformes; RECONNECT_REQUIRED distinto de REJOIN_REQUIRED; getMyParticipation permite localizar só a própria participação sem chat/URL/código | [Gates](CONTRATOS.md#sec-01), [retomada](CONTRATOS.md#sec-06), [acesso](BANCO.md#sec-04) |
| R10 | Encerramento removia URLs, mas reprodução podia manter FK da mídia; ended/replay se confundiam com closed | Em closed, playback tombstone empty/media_id=null, nova epoch/revisão e fila limpa antes de exclusões elegíveis. ended em sala ativa preserva mídia para replay. Revisões/eventos só dos domínios alterados | [Fechamento](BANCO.md#sec-05), [transições](ALGORITMOS.md#sec-06), [closeRoom](CONTRATOS.md#sec-09) |

Ajustes associados: FK de mensagem/avaliação liga sala, participação e ator; janelas fechadas preservam geração histórica sem FK à geração mutável atual; sendMessage retorna chave composta room_id/seq e captura apelido com lock de perfil antes de sala. Modo manual exige CONTROL e playing; timer de modo confiável relê fila atual sem usar revisão de fila antiga.

<a id="contrato-comum"></a>

## Contrato comum conciliado

| Domínio | Dado de referência | Operação/transição | Garantia |
|---|---|---|---|
| Participação | memberships + connections | active → grace → active (nova generation) ou ended | Reserva não se estende por heartbeat tardio; estado calculado prevalece sobre worker atrasado |
| Administração | rooms.admin_state/admin_membership_id | assigned, awaiting_successor, none em closed | No máximo um admin da mesma sala; estar em grace não autoriza controle |
| Mídia | media_validations → media_items | pending → resultado admitido; add/play copia snapshot | Cliente não fabrica duração ou modo de término; inconclusivo permitido conforme P03 |
| Player/fila | playback + room_counters.queue_revision | empty/paused/playing/ended, promoção transacional | Play inicial/manual/replay seguem P02/P03; encerramento não é término reproduzível |
| Chat | messages + chat_windows | Abrir janela no commit de entrada/reconexão | Nenhuma janela antiga reaberta; cache em memória não concede leitura adicional |
| Retry | command_contexts + command_receipts | Mesma intenção mantém contexto/request_id | Um único efeito; expiração/limpeza não transforma pedido velho em novo |
| Notificação | notification_outbox | pending/leased/delivered/failed/suppressed | Claim antigo não sobrescreve supressão; envio externo ainda pode duplicar |

<a id="cenarios"></a>

## Cenários de revisão e verificação futura

Os resultados abaixo são raciocínio documental, não execuções:

1. Heartbeat aceito em t=0, D hipotético de 25 s: silêncio detectado logicamente em 25, deadline=85. Worker em 90 materializa expiração; não cria reserva até 150.
2. Retorno antes de suspect_at após interrupção observada: reconnectRoom ainda abre janela/geração novas. Geração antiga nunca ganha leitura por continuar antes do timeout.
3. Retorno em agora=deadline após lock: REJOIN_REQUIRED; fronteira é proposta técnica explícita. Sem membro/reserva restante, sala termina; não reabrir participação ended.
4. getRoomSnapshot em grace: RECONNECT_REQUIRED, não conteúdo de chat/fila. Identidade após morte do processo usa getMyParticipation antes de retomar.
5. validateMedia pending/expired ou referência de outro ator/sala/participação: add/play não altera reprodução/fila. Avaliação inconclusiva admitida mantém avanço somente manual autorizado.
6. Modo manual paused: comando de término rejeitado; relato comum não promove. Em playing e autorizado, uma promoção no máximo ou ended se não houver próximos.
7. Fechamento concorrente com envio/entrada/avanço: ordem de locks e revalidação determinam commit único; sala closed não recebe nova mensagem/replay.
8. Alterar apelido concorre com sendMessage: perfil bloqueado antes da sala define nome do envio; mensagem antiga permanece imutável. Não capturar apelido por lock invertido.
9. Contexto expira após commit e resposta se perde: recibo só confirma resultado mínimo. Após limpeza do recibo, contexto expirado rejeita execução; não migrar para novo contexto automaticamente.
10. Worker de push conclui após supressão/reclaim: estado/token deixam de coincidir, conclusão antiga não muda registro; notificação já enviada não pode ser desfeita.

Casos futuros complementares estão em [C11–C16](SEGURANCA-TESTES.md#c11), todos não executados. Os casos anteriores de capacidade, revogação, chat e repetição continuam necessários.

<a id="pendencias"></a>

## Limites e pendências remanescentes

- [T01](DECISOES.md#t01): H/D/S, origem/prova do sinal de transporte, materialização e eleição em variantes de admin expirado/novos entrantes. A estrutura aceita ausência temporária; não afirmar essas variantes aprovadas como comportamento novo.
- [T02](DECISOES.md#t02): detalhamento final de constraints/índices/grants e representação de transporte; esta revisão concilia desenho lógico, sem demonstrar constraints em banco real.
- [T03/T04](DECISOES.md#t03): executor da avaliação, protocolo de claim/conclusão/resultado tardio do worker, capacidade/custo e reavaliação de fonte mutável. Snapshot do resultado admitido não prova que URL mutável continuará igual.
- [T05](DECISOES.md#t05): owners/grants/RLS, revogação de canais/tokens/contextos e ponto de decisão de revogação concorrente. Predicado lógico não equivale a política implementada.
- [T07/T08](DECISOES.md#t07): TTLs/margens, quotas, Unicode, retenção de avaliações e exclusões/restauração sem perder revogações. Nenhum número técnico novo aprovado por este relatório.
- [T06/T09/T10/T11](DECISOES.md#trabalho-tecnico): bootstrap dos amigos, sessão Android, métricas, ambiente/aparelhos e transporte/eventos. Novos métodos lógicos não escolhem SDK ou fornecedor.

Conclusão restrita: dez divergências centrais receberam conciliação documental; a arquitetura continua proposta em revisão e B00 não está encerrado. Implementação e testes reais dependem de solicitação posterior do usuário.
