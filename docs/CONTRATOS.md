# Contratos de operações — proposta v1

## Avanço de implementação e aparelho — 09/11/2026

Backend agora possui 13 migrações, 23 tabelas privadas e 21 RPCs: identidade/preferências, salas/catálogo, leases/reconexão, chat e administração. Treze suítes SQL passaram; cron observado encerrando fixture privada, apagando mensagem e invalidando código. Papéis de API limitados, sem login/BYPASSRLS/DDL permanente. [Estado, escolhas técnicas e evidências](IMPLEMENTACAO.md). Ainda faltam mídia/fila, social/push/Realtime, getOperationStatus e app Android/APK. REST/Auth real, contenção entre sessões e aparelhos ainda não validados. P01–P15 e design preservados; blocos completos/B00 não declarados concluídos. Usuário confirmou Galaxy A54 com Play Store, APK direto, somente Android; versões exatas do SO não informadas. Isso não escolhe push/SDK/assinatura/orçamento. Sem imagem nova ou publicação de APK. Notas de somente planejamento abaixo são históricas.


Revisão cruzada de 09/11/2026 em [CONSISTENCIA.md](CONSISTENCIA.md): conciliação com BANCO/ALGORITMOS. Refinamentos continuam proposta técnica sem implementação, testes ou aprovação integral. P01–P15 permanecem confirmados.

P04–P06 confirmados em 09/11/2026: suspensão pelo Android quando pausado/sem vídeo segue reconexão normal, com reserva de 60 s após detecção; número visível nos cards e sala conta somente conectados, mas reservas válidas ainda ocupam o limite de 10; ex-administrador preserva apenas sua permissão individual anterior, sem ganhar controle automaticamente ao transferir. Áudio durante reprodução em segundo plano permanece requisito. Esta atualização substitui pendências históricas desses comportamentos. Nenhuma imagem, implementação, publicação ou teste.

Confirmado em 09/11/2026 (P01–P03 de DECISOES.md): reserva de 60 segundos contada após detectar a queda; Play com sala ainda sem mídia inicia o primeiro item da fila, mas adicionar sozinho não inicia; fonte reproduzível com duração inconclusiva é permitida, com avanço manual por administrador/participante autorizado ao terminar. Essa última regra é exceção explícita ao avanço automático, não permissão a usuário comum. Detecção/limites técnicos e apresentação da ação manual ainda precisam de especificação. Substitui pendências históricas desses três pontos abaixo. Somente planejamento, sem implementação/testes.

Atualização de 09/11/2026: usuário confirmou manter as mensagens já vistas antes da queda, sem recuperar o intervalo desconectado; notificações de convites/solicitações também com app fechado; uso inicial em teste fechado com amigos. P11 confirmou cache somente em memória, perdido após morte do processo; fornecedor de push continua aberto. P15 confirmou limites de uso em [PARAMETROS.md](PARAMETROS.md); demais parâmetros de engenharia, retenção e capacidade de infraestrutura continuam propostos e não testados. Nenhuma implementação, infraestrutura, imagem ou publicação.

Decisões confirmadas pelo usuário em 08/11/2026: (1) se o administrador sair e os demais estiverem reconectando, preservar reservas e manter sala temporariamente sem administrador, atribuindo o papel quando alguém retornar; (2) Play após terminar o último vídeo recomeça esse vídeo; (3) pular animações antigas excedentes, mantendo mensagens no chat autorizado. P15 confirmou depois até 5 animações pendentes e pular espera maior que 20 s, sem apagar chat/descartar corrente repetida por rotação. Isso não permite recuperar mensagens do intervalo desconectado nem aprova integralmente os mecanismos técnicos. Nenhuma imagem, implementação, publicação ou teste. Esta atualização substitui pendências históricas desses três comportamentos abaixo.

## Avanço — estados e algoritmos (08/11/2026)

Algoritmos detalhados em [ALGORITMOS.md](ALGORITMOS.md). Refinamentos propostos: startQueue com revisões de fila/player; replay com nova epoch; heartbeat após suspect_at exige reconexão; contexto de validade para retry; avanço condicionado à duração confiável. Permanecem propostas, não contratos finais ou implementados.

08/11/2026. Planejamento documental baseado em PLANEJAMENTO.md, BANCO.md e ARQUITETURA.md. Nomes abaixo são interfaces lógicas propostas, não endpoints ou funções implementadas. Não há SQL, código Android, infraestrutura ou testes executados. Regras marcadas como pendentes não devem receber defaults silenciosos.

<a id="sec-01"></a>

## 1. Convenções comuns

- Ator vem da sessão autenticada validada, nunca de user_id informado pelo cliente. Criar identidade anônima/renovar sessão é responsabilidade do mecanismo de autenticação a especificar, não de uma função que aceite identidade arbitrária.
- Toda mutação funcional recebe request_id UUID e command_context_id, exceto ensureProfile convergente, emissão de contexto e heartbeat com deduplicação própria. Tabelas omitem envelope comum por concisão. Sala usa room_id, membership_id e generation; reconnectRoom recebe expected_generation para estabelecer a nova. Administração recebe expected_room_revision. Contexto não substitui autorização.
- UUIDs são strings; versões, sequências e posições bigint devem ter representação decimal sem perda de precisão no transporte. Horários são UTC ISO 8601. Limites P15 estão confirmados; contagem Unicode, códigos e tetos técnicos continuam a especificar.
- Sucesso contém operation, request_id quando houver, server_time, outcome (applied/already_applied/unchanged), data e revisions pertinentes. Leitura contém data, revisions e next_cursor opcional. server_time de resposta não substitui reference_at de playback.
- Falha contém code, field opcional, retryable, retry_after_ms opcional e correlation_id sem segredo. Detalhes e versões só são devolvidos se o ator ainda puder ler o recurso.
- Campos extras, enum inválido, tamanho excessivo, número fora de faixa e id de outra sala são rejeitados; não converter silenciosamente input inválido em uma ação diferente.
- LIVE exige sala ativa, dono/participação/geração correspondentes e fase efetiva active por tempo do servidor após locks. CONTROL=LIVE e (admin vigente OU can_control); ADMIN=LIVE e admin_membership_id correspondente. Grace só permite reconexão/saída própria/status mínimo, sem snapshot/chat/comandos. Admin em grace mantém papel até prazo, sem CONTROL. Reavaliar no ponto de decisão; flags do app não autorizam.

<a id="sec-02"></a>

## 2. Erros e comportamento do cliente

| Código | Significado | Resposta do cliente |
|---|---|---|
| UNAUTHENTICATED | Sessão ausente/expirada | Renovar sessão pelo provedor; não criar identidade nova por erro transitório |
| INVALID_INPUT | Formato/valor inválido | Mostrar validação no campo; corrigir antes de reenviar |
| NOT_FOUND_OR_UNAVAILABLE | Recurso inexistente ou não acessível | Aviso genérico; não revelar sala privada ou identidade por enumeração |
| ROOM_FULL | Entrada autorizada, mas 10 vagas ocupadas incluindo reserva | Manter convite pendente; sem fila de espera |
| ALREADY_IN_ROOM | Participação em outra sala, incluindo reserva | Exibir retorno/saída da sala atual; não sair automaticamente |
| CLOSED | Sala conhecida pelo ator está encerrada | Limpar estado da sala e atualizar convites |
| FORBIDDEN | Ator conhece o recurso, mas não pode executar ação | Atualizar permissões e impedir a ação |
| CONFLICT | Revisão mudou ou estado não permite a transição | Ler estado e pedir nova ação; não repetir comando antigo como se fosse novo |
| STALE_CONNECTION | Geração antiga | Descartar comandos dessa geração e reconciliar conexão |
| RECONNECT_REQUIRED | Mesma geração, queda detectada e reserva ainda válida | Suspender leituras/comandos e executar reconnectRoom |
| REJOIN_REQUIRED | Participação/reserva expirou | Não retomar automaticamente como se fosse mesma participação; oferecer entrada normal |
| RATE_LIMITED | Limite de operação atingido | Aguardar retry_after_ms; sem loop imediato |
| SOURCE_UNAVAILABLE | Fonte não validada/disponível | Manter mídia atual; permitir corrigir URL |
| IDEMPOTENCY_MISMATCH | Mesmo request_id com conteúdo/operação diferente | Erro de protocolo; não executar |
| REQUEST_EXPIRED | Pedido fora da janela de retry suportada | Consultar resultado/estado antes de formular nova ação |
| TEMPORARILY_UNAVAILABLE | Falha transitória de serviço | Retry com mesmo pedido e backoff com jitter, dentro da janela |

Esses são códigos lógicos; mapeamento para HTTP/RPC e mensagens exatas de interface fica para escolha do transporte. Timeout não prova falha: operação pode ter sido confirmada no servidor.

<a id="sec-03"></a>

## 3. Idempotência, versões e transações

Hash do pedido inclui operação, versão do contrato e payload canônico; exclui token de sessão. Mesmo ator/request_id/payload confirmado não reaplica efeitos. Pedidos simultâneos iguais compartilham uma única execução por exclusividade transacional. Resultado mínimo não guarda corpo de chat, código da sala, URL ou token.

Em retry, autenticar e consultar recibo antes de exigir que uma revisão antiga ainda seja atual. Devolver resultado mínimo do pedido original; dados sensíveis e estado atual exigem autorização atual. Se já saiu/foi expulso, sucesso passado não readmite nem concede leitura. Falha de infraestrutura com rollback não confirma recibo. Resultado de negócio rejeitado pode ter recibo estável; usuário que corrige conteúdo ou decide tentar novamente após mudança de estado cria nova intenção/request_id.

Proposta conciliada: command_contexts persistido e opaco, ligado ao ator/versão/validade. getCommandContext() exige perfil autenticado/quota e emite contexto. Execução nova exige contexto existente/não revogado e agora < expires_at; ausente/vencido retorna REQUEST_EXPIRED. Hash vincula operação/versão/contexto/payload, não token de sessão. Recibo fica pelo menos até expires_at do contexto mais margem. Recibo existente é consultado antes de revisar versões e pode devolver resultado mínimo mesmo após expiração, sem restaurar acesso. Sem recibo e com contexto inválido, não executar. getOperationStatus recebe contexto para distinguir expired de unknown; unknown não prova ausência de commit. TTL/margem/revogação continuam T05/T07/T08.

Revisões propostas: room_revision para participantes/permissões/administração; playback_revision e media_epoch para reprodução; queue_revision para fila; profile_revision e preferences_revision para edições pessoais. Um heartbeat não incrementa room_revision se não alterar estado visível. Revisão é por domínio; não tratar ausência de número no canal como prova de evento perdido sem conhecer o fluxo.

Mutações seguem locks na ordem de BANCO.md. Entrada em outra sala deve reconciliar participação vencida na sala anterior antes de admitir: localizar ids, bloquear salas em ordem estável, reler estado e repetir a transação se o conjunto mudou. Nenhuma chamada externa ocorre com lock aberto. Snapshot exige leitura consistente entre tabelas; consultas independentes sem snapshot não atendem. Conferir horário do servidor após os locks. sendMessage adquire perfil antes da sala para capturar apelido sem inversão. Revisões seguem BANCO §5: incremento uma vez por transação/domínio alterado; eventos só para revisões alteradas após commit. Snapshot pode reconciliar prazos antes da leitura, sem executar intenção de reprodução.

<a id="sec-04"></a>

## 4. Identidade, perfil e preferências

| Método e entrada específica | Validação/autorização | Alteração atômica e resposta | Evento/erros específicos |
|---|---|---|---|
| ensureProfile(nickname, request_id) | Sessão válida; apelido válido | Criar perfil/código único e preferências somente se ausentes; retorna perfil próprio e revisions. Retry não troca apelido existente | profile.changed; INVALID_INPUT. P10 fixa notify_invites=true e notify_friendships=true na criação; não redefinir preferências já salvas. Faixas/padrões numéricos de sobreposição ainda a especificar |
| getCommandContext() | Perfil autenticado e quota | Contexto opaco próprio, validade e versão de contrato; não admite sala nem concede controle | Sem outbox funcional |
| getMyProfile() | Dono | Perfil, código pessoal e preferências próprias, revisões | Sem efeito |
| changeNickname(nickname, expected_profile_revision) | Dono; formato/limites | Atualizar apelido/versão; retornar valor confirmado; não alterar apelido registrado em mensagens anteriores (P08) | profile.changed; CONFLICT |
| saveMessagePreferences(position,size_key,speed_key,expected_preferences_revision) | Dono; valores reconhecidos | Atualizar apenas ajustes de sobreposição; retornar preferências confirmadas | preferences.changed; CONFLICT |
| setNotificationPreference(kind,enabled,expected_preferences_revision) | Dono; kind convite/amizade | Atualizar só interruptor escolhido, automaticamente; retornar valor/versão | preferences.changed; conflito/falha mostra estado não salvo, sem confirmar visualmente algo não persistido |

Salvar ajustes de mensagem e apelido permanece ação explícita conforme modelos; autosave vale somente para notificações. Cliente serializa autosaves e reaplica apenas intenção ainda vigente após refresh, sem sobrescrever outros campos. Permissão Android negada é diferente de preferência salva e não muda o valor silenciosamente.

<a id="sec-05"></a>

## 5. Descoberta, criação e entrada

| Método e entrada específica | Validação/autorização | Alteração/resposta | Evento/erros específicos |
|---|---|---|---|
| listPublicRooms(query?,cursor?,limit) | Autenticado; limite máximo do servidor | Cards active/public com connected_count, ordenação por conectados/recência/id; reservas ocupam capacidade, sem entrar no número visível. Home solicita até três | Sem efeito; catálogo pode mudar entre páginas |
| createRoom(name,public=true) | Sem outra participação válida; limites de criação | Criar sala/código, admin, conexão, janela de chat, reprodução vazia e contadores; retornar admissão | room.changed; ALREADY_IN_ROOM |
| joinRoom(target) | target tem exatamente code OU public_room_id OU invite_id; validar direito de entrada, bloqueio e vagas | Criar participação/conexão/janela; convite só usado após sucesso; retorna admissão | room.changed e convite alterado; ROOM_FULL, ALREADY_IN_ROOM, indisponível |
| getRoomCode(room_id,membership_id,generation) | Membro atual, conectado e não expulso | Código recuperável, sem incluir URL ou token | Sem efeito; não registrar código em logs |

Admissão contém room_id, membership_id, generation, chat_window_id, chat_start_after_seq, grace_deadline e revisões; estado detalhado vem do snapshot autorizado. Para sala já ocupada pelo próprio ator, join não cria nova janela arbitrariamente: retorna indicação de participação existente; reconexão usa reconnectRoom. Entrada pública por UUID não concede entrada privada. Convite interno autoriza apenas seu destinatário; código é meio compartilhável de entrada.

Listagem e sucesso de entrada não prometem reprodução disponível: sala pode ainda estar sem vídeo. Entrar não dispara play global. Nenhuma operação cria sala de espera, agendamento ou código na Home.

<a id="sec-06"></a>

## 6. Conexão e leitura da sala

| Método e entrada específica | Validação/autorização | Alteração/resposta | Evento/erros específicos |
|---|---|---|---|
| getMyParticipation() | Dono autenticado | Referência mínima própria: room_id/membership_id/generation/fase efetiva/deadline/room_revision; null sem participação válida. Sem chat/URL/código | Retomada decide reconectar ou oferecer entrada normal |
| getRoomSnapshot(room_id,membership_id,generation) | LIVE; reconciliar prazos e reler | Snapshot consistente de sala/pessoas/permissões/playback/fila/revisões/janela atual, sem histórico | CLOSED, STALE_CONNECTION, RECONNECT_REQUIRED, REJOIN_REQUIRED |
| heartbeat(room_id,membership_id,generation,heartbeat_seq) | LIVE, seq monotônica e agora antes da detecção; revalidar após lock | Renovar last_seen_at/suspect_at e prazo candidato; duplicata não estende; grace exige reconexão formal | STALE_CONNECTION/RECONNECT_REQUIRED/REJOIN_REQUIRED |
| reconnectRoom(room_id,membership_id,expected_generation,request_id) | Mesma identidade, reserva ainda válida, sala ativa | Incrementar geração, invalidar geração anterior, abrir janela com sequência atual, preservar join_order; retornar admissão atualizada | room.changed se estado muda; STALE_CONNECTION/REJOIN_REQUIRED |
| getOperationStatus(request_id,command_context_id) | Dono do pedido | Resultado mínimo existente, unknown ou expired; unknown não autoriza repetir com id diferente | Sem dados sensíveis/efeito |

Heartbeat é exceção ao recibo geral: deduplicado por geração/heartbeat_seq no registro de conexão. Não escrever recibo separado para cada batimento. P01 fixa início dos 60 segundos na detecção da queda; frequência, mecanismo de detecção e atraso admissível do worker continuam técnicos. Pacote atrasado não ressuscita reserva vencida. Antes da reconexão formal o cliente suspende comandos e leitura de chat; primeira renovação de transporte passa por reconnectRoom, não por fetch que recuperaria intervalo desconectado.

Reconectar repetidamente por timeout usa o mesmo request_id e recebe a mesma geração/janela; novo pedido não pode substituir conexão mais recente sem expected_generation correta. Depois do prazo, nova entrada deve respeitar vaga e regras de sala ativa e criar novo join_order.

<a id="sec-07"></a>

## 7. Player e fila

P14 confirmado: validateMedia/addToQueue/playNow aceitam fontes diretas HTTP ou HTTPS de MP4/HLS gravados, inclusive URLs assinadas, sem introduzir login/cookies de terceiros. Ticket e validação de destino/redirect continuam obrigatórios conforme a especificação; HTTP não significa fonte inválida. Credenciais do assistAe não acompanham pedidos à mídia. P13 fixa saltos de seek de 10 s por autorizado; Parar externo é intenção local e não chama pause/leaveRoom/closeRoom automaticamente. Ao retomar, revalidar participação, obter snapshot e realinhar.

Complemento decorrente de P02/P03 confirmados (modelo de campos e revisões em BANCO §3/§5):

- startQueue(expected_playback_revision, expected_queue_revision): exige CONTROL e playback empty; sob lock promove primeiro item, remove-o da fila, incrementa epoch/revisões e inicia playing. Fila vazia não altera estado. Retry é idempotente; concorrência produz conflito. É a ação do Play inicial, não início automático ao adicionar.
- advanceAfterUnverifiedEnd(expected_media_epoch, expected_playback_revision, expected_queue_revision): ação manual explícita de CONTROL, playback playing e termination_mode=authorized_manual para mídia cuja duração ficou inconclusiva. Sob lock, revalidar autorização, modo de término e revisões; promover próximo ou marcar ended preservando última mídia se fila vazia. Recibo/epoch impedem avanço repetido. Um relato automático de cliente comum não chama esse caminho. O servidor confia na ação autorizada, não a apresenta como prova independente do término físico. Sem próximo, Play posterior reinicia a última mídia, conforme regra aprovada.
- Proposta de modelo: media_validations mantém status da avaliação; media_items mantém validation_id e snapshot de duration_confidence/duração/proveniência admitidos. API deriva termination_mode=server_timeline ou authorized_manual, nunca de flag do cliente; em empty é null. expected_end_at é derivado só em playing/server_timeline, sem campo independente mutável. Inconclusive não dispensa validação de URL, escopo VOD e segurança; uma fonte inválida continua rejeitada. ticket de resultado inconclusivo permitido é distinto de ticket de duração confirmada.
- UI deve indicar avanço manual quando aplicável e oferecer ação nos controles/painel existentes, sem gerar nova imagem. Texto/localização ainda precisam de detalhamento; não confundir avançar vídeo com seek.

| Método e entrada específica | Validação/autorização | Alteração/resposta | Evento/erros específicos |
|---|---|---|---|
| validateMedia(source_url) | CONTROL; limites e fonte permitida | Criar media_validations pending em transação curta e retornar validation_id; avaliar rede fora da transação; cache autorizado pode antecipar resultado | Não muda fila/player |
| getMediaValidation(validation_id) | Dono da avaliação e LIVE na mesma sala/participação | pending/valid/invalid/inconclusive/expired, metadados mínimos e validade; resultado admitido fornece validation_reference=validation_id | Fonte rejeitada não fornece ticket utilizável |
| addToQueue(source_url,validation_reference,expected_queue_revision) | CONTROL; referência obrigatória admitida/não vencida do ator/sala/participação/mesma URL; até 50 próximos | Criar mídia/item com snapshot da avaliação e incrementar queue_revision | queue.changed; CONFLICT; pending/expired não adiciona |
| playNow(source_url,validation_reference,expected_playback_revision,expected_media_epoch) | CONTROL; mesma referência obrigatória de addToQueue | Nova mídia/epoch/revisão, playing e posição zero; interrompido não entra na fila; fila não muda | playback.changed; falha preserva atual |
| startQueue(expected_playback_revision,expected_queue_revision) | CONTROL; empty e fila não vazia | Promover primeiro/renumerar, nova epoch e revisões player/fila, playing | playback.changed/queue.changed; fila vazia INVALID_INPUT |
| advanceAfterUnverifiedEnd(expected_media_epoch,expected_playback_revision,expected_queue_revision) | CONTROL; playing/authorized_manual | Promover um próximo ou ended com última mídia; nova epoch só ao promover. Posição final materializa timeline no commit, sem alegar duração comprovada | playback.changed; queue.changed só se promove; retry não repete |
| setPlayback(action,position_ms?,expected_playback_revision,expected_media_epoch) | CONTROL; play/pause/seek; posição só em seek; transição de ALGORITMOS §6 | pause materializa posição; play em paused retoma, em ended recomeça zero/nova epoch; seek só playing/paused preserva estado; empty usa startQueue | playback.changed se altera; CONFLICT/INVALID_INPUT |
| reorderQueue(ordered_item_ids,expected_queue_revision) | Autorizado; ids são permutação completa dos itens atuais sem duplicados | Renumerar atomicamente; retornar fila/revisão | queue.changed; CONFLICT |
| removeQueueItem(item_id,expected_queue_revision) | Autorizado; item da sala e entre próximos | Remover/renumerar, incrementar revisão; não remover mídia atual por esse método | queue.changed; CONFLICT |
| reportMediaEnded(media_epoch,observed_position_ms) | LIVE; modo manual não avança por relato; não confiar na posição enviada | Registrar/avaliar indício limitado; somente critério confiável definido pode acionar avanço | accepted_for_evaluation/unchanged; não promete troca |
| advancePlayback(room_id,expected_epoch,expected_playback_revision,evidence) — interno | Serviço confiável; playing/server_timeline, duração verified e alvo no fim | Reler fila atual sob lock; promover um com nova epoch ou ended preservando mídia. Fila/revisão são do commit, não do timer antigo | playback.changed; queue.changed só se promove; no máximo um avanço por epoch |

Reproduzir agora é ação explícita autorizada de troca e início da mídia. addToQueue nunca inicia sozinho; Play inicial promove o primeiro item por startQueue (P02). P09 permite a mesma URL em itens independentes, com novos ids para novas adições intencionais; retry do mesmo request_id continua produzindo um único efeito. Próximo automático vale para duração confiável; P03 exige avanço manual autorizado quando a duração é inconclusiva.

Ticket de mídia não pode ser produzido pelo cliente como prova confiável. Fonte pode expirar depois da validação; falha local não pausa os outros. Estratégia de validação e término confiável ainda é pendência impeditiva para fechar validateMedia/advancePlayback. Retroceder/avançar da interface usa seek com revisão; P13 fixa saltos de 10 s, sujeitos à autorização e limites da mídia; não confundir seek com avanço de item. Nenhum relato de erro local altera estado global automaticamente.

<a id="sec-08"></a>

## 8. Chat

| Método e entrada específica | Validação/autorização | Alteração/resposta | Evento/erros específicos |
|---|---|---|---|
| sendMessage(body,client_message_id,chat_window_id,generation) | LIVE, janela atual; limite/antispam | Perfil antes da sala/contador, capturar sender_nickname e atribuir seq; retornar room_id,seq,created_at (sem id avulso de mensagem) | chat.changed sem corpo; RATE_LIMITED/STALE_CONNECTION/RECONNECT_REQUIRED |
| listMessages(chat_window_id,generation,after_seq?,before_seq?,limit) | LIVE e dono da janela atual; cursores válidos | Aplicar limite start_after_seq antes de paginar; retorna mensagens autorizadas ordenadas e cursor | STALE_CONNECTION/REJOIN_REQUIRED |

Não aceitar after_seq e before_seq juntos. after busca posteriores; before pagina anteriores dentro da mesma janela; servidor nunca permite seq ≤ start_after_seq. Offset não concede leitura. client_message_id permanece igual em retry e fica vinculado ao mesmo corpo; id reutilizado para outro corpo é erro.

Mensagem escrita offline não é enviada automaticamente após reconectar: preservar rascunho local é proposta; envio depende de nova ação na janela nova. Pedido confirmado antes da queda pode retornar recibo mínimo, sem corpo do intervalo desconectado. Manter no cache as mensagens já vistas é decisão confirmada; P11 define perda do cache após morte do processo, sem reconstrução de janelas antigas. P08 preserva apelido do envio: sendMessage captura o apelido do perfil no commit; listMessages retorna esse snapshot, sem substituí-lo pelo nome atual.

<a id="sec-09"></a>

## 9. Administração e saída

| Método e entrada específica | Validação/autorização | Alteração/resposta | Evento/erros específicos |
|---|---|---|---|
| setControlPermission(target_membership_id,allowed,expected_room_revision) | Administrador; alvo participante da sala, não admin | Alterar can_control e revisão; retornar permissão confirmada | room.changed; FORBIDDEN/CONFLICT |
| transferAdmin(target_membership_id,expected_room_revision) | Admin; alvo conectado elegível e diferente | Trocar admin, preservar participação de quem transfere; retornar novo admin | room.changed; CONFLICT |
| kickMember(target_membership_id,expected_room_revision) | Admin; alvo não é próprio admin | Encerrar participação, invalidar geração/janela, criar ban e liberar vaga | room.changed/participation.ended privado |
| leaveRoom(successor_membership_id?,expected_room_revision) | Própria participação não encerrada em active/grace, generation vigente; sucessor só por admin | Encerrar participação; se admin escolher ou eleger mais antigo conectado; se último encerrar sala | room.changed ou room.closed |
| closeRoom(expected_room_revision) | Admin; ação explícita após confirmação UI | Encerrar e invalidar acessos/código/convites, apagar chat; playback tombstone empty/media_id nulo; limpar fila antes de excluir mídia elegível (BANCO §5) | room.closed e convites alterados |

Não usar flag confirmed do cliente como permissão de servidor: confirmação é proteção de interface, autenticação/autorização são independentes. Alvo de transferência que desconectou entre confirmação e commit produz conflito, sem escolher outro silenciosamente. Eleição automática vale quando sucessor foi omitido, conforme regra aprovada.

Confirmado pelo usuário: se o administrador sair e todos os demais estiverem reconectando, manter sala e reservas temporariamente sem administrador e atribuir o papel quando alguém retornar. Detalhes de eleição concorrente e extensão ao admin expirado seguem proposta de ALGORITMOS.md. P06 confirmou que ex-admin mantém somente a permissão individual prévia; não conceder controle automaticamente.

<a id="sec-10"></a>

## 10. Amigos e convites

| Método e entrada específica | Validação/autorização | Alteração/resposta | Evento/erros específicos |
|---|---|---|---|
| listFriends(cursor?,limit) | Próprio usuário | Projeções de amigos, sem tokens ou perfis completos | Sem efeito |
| listFriendRequests(direction,cursor?,limit) | direction incoming/outgoing; envolvido | Pendências e estados pertinentes ao dono | Sem efeito |
| requestFriendship(user_code) | Não é próprio código; limite; par válido | Criar pending e outbox; se pendência igual existe, retornar existente; cruzada indica received_request sem aceitar automaticamente | friendship.changed privado |
| answerFriendRequest(request_id_of_friendship,answer) | Destinatário; answer accept/reject; ainda pending | Resolver pendência; accept cria vínculo único junto; retornar estado | friendship.changed; CONFLICT |
| cancelFriendRequest(request_id_of_friendship) | Remetente; pending | cancelled; não remover amizade já aceita (P07) | friendship.changed; CONFLICT |
| removeFriend(friend_user_id) | Qualquer envolvido no vínculo; UI exige confirmação | Remover relação bilateral, preservar perfis e convites já enviados até uso/fechamento (P07) | friendship.changed; retry não recria vínculo |
| inviteFriend(friend_user_id,room_id,membership_id,generation) | Membro atual e amigo aceito; não expulso | Criar ou retornar convite pending único por sala/destinatário; outbox sem duplicação | invitations.changed privado |
| listInvites(cursor?,limit) | Destinatário | Convites pendentes e projeções mínimas; não expor URL/código da sala | Sem efeito |

Uso de convite é joinRoom(invite_id), não uma etapa que marca usado antes de tentar entrar. Sala lotada, usuário já em outra sala e falha de rede não consomem convite sem entrada confirmada. Convite não precisa que remetente permaneça na sala, pela validade aprovada até uso/encerramento; eventual mudança exige decisão explícita. Reenvio de convite já usado precisa nova intenção e regra de limite a fechar.

<a id="sec-11"></a>

## 11. Rotinas internas e notificações

| Método lógico | Entrada/autorização | Efeito e retry |
|---|---|---|
| reconcileRoomLeases | room_id e geração/deadline observados; worker confiável | Lock e releitura; expirar somente prazo ainda vencido; sucessão/encerramento conforme regras. Repetir não duplica efeitos |
| dispatchNotification | outbox_id; worker confiável | Revalidar estado do convite/solicitação e preferência; enviar fora da transação; marcar tentativa/resultado. Duplicatas externas deduplicadas por event_key |
| registerDeviceToken / revokeDeviceToken | Token próprio via sessão autenticada; somente se push adotado | Registrar/revogar para identidade atual; vínculo anterior e prova de posse a detalhar |
| purgeExpiredOperationalData | Lote/cutoff de política aprovada; worker confiável | Excluir só dados elegíveis, sem romper retries ou amizades; política de retenção ainda pendente |

Timeout de push pode ocorrer depois de envio: não prometer exatamente uma entrega. Outbox usa claim com lease/attempt e recuperação conforme BANCO e ALGORITMOS §12. Dados do chat não entram em notificações desta versão.

<a id="sec-12"></a>

## 12. Eventos, reconciliação e exemplos

Eventos propostos: room.changed, room.closed, playback.changed, queue.changed, chat.changed, profile.changed, preferences.changed, friendship.changed, invitations.changed e participation.ended. São avisos de invalidação com domínio/id/versão, não comandos confiáveis do cliente. Não transportar corpo de chat, códigos ou URLs para assinantes que possam ter perdido permissão. Canais privados por usuário/sala, minimização de metadados e revogação ainda exigem contrato de transporte.

Publicar somente após commit. Falha na publicação não desfaz mutação: cliente reconcilia por leitura autorizada ao reconectar/retomar e por atualização de segurança planejada. Janela subscribe/snapshot deve ser coberta com buffer de eventos e comparação de revisões. Para chat, subscription concluída seguida de leitura da janela atual cobre mensagens novas durante essa janela, nunca a anterior. Respostas atrasadas de geração antiga são descartadas.

Exemplos de resultado esperado, ainda sem execução:

1. Dois convidados disputam vaga 10: um entra, outro recebe ROOM_FULL, convite deste permanece pending.
2. Play e seek concorrentes com mesma revisão: primeiro confirma; segundo recebe CONFLICT e não move todos para posição antiga.
3. Mensagens 41–48 chegam na desconexão: reconexão fixa start_after_seq=48; listMessages(after_seq=0) retorna apenas seq>48.
4. Resposta de reconexão se perde: retry igual devolve a mesma geração e janela, não descarta novas mensagens criando outra janela.
5. Usuário expulso repete pedido antigo: não recupera acesso por recibo nem pelo canal já aberto.
6. Três aparelhos avisam término: só avanço interno validado da epoch atual muda para o próximo uma vez.

<a id="sec-13"></a>

## 13. Ajustes documentais exigidos no modelo

BANCO já incorpora revision, generation/last_heartbeat_seq/suspect_at/detected_at, avaliações e contextos/recibos. Proposta persistida de contexto foi conciliada; TTL/revogação/limpeza ainda exigem revisão T05/T07/T08. Identidade dos recibos de amizade não deve ser confundida com request_id da própria solicitação (usar friendship_request_id no contrato de transporte).

Outbox de notificações não substitui eventual outbox de eventos de sala. Caso seja escolhida entrega durável desses eventos, desenhar entidade separada; nesta proposta, snapshots autorizados permitem recuperação sem afirmar entrega garantida de Broadcast.

<a id="sec-14"></a>

## 14. O que ainda impede fechar a especificação

- Parâmetros: P15 fixa apelido 2–24, sala 2–60, mensagem até 500 caracteres e fila até 50 próximos. Especificar contagem Unicode uniforme e validação servidor/UI. Códigos, antispam, teto de bytes, TTL, heartbeat e retenção continuam propostas técnicas.
- Produto: P01–P15 confirmados em DECISOES. Detalhes técnicos de contagem Unicode, tamanho visual/velocidade de sobreposição e limites não funcionais ainda precisam de especificação.
- Estados: detalhes técnicos da sucessão concorrente/admin expirado/novos entrantes, detecção e fronteira da reserva vencida. Origem dos 60 segundos e preservação das reservas na saída do admin já confirmadas.
- Infraestrutura: transporte RPC/HTTP, autenticação, validação de mídia/término, push e publicação/revogação Realtime.

Próxima etapa de planejamento: máquinas de estado e algoritmos para concorrência, conexão/sucessão, sincronização/fim de mídia, fila/chat e retry. Só após fechar pendências e revisar o conjunto com o usuário considerar programação mediante solicitação posterior.
