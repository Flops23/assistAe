# Planejamento técnico — assistAe

Refinamento de 09/11/2026: o resumo inicial abaixo é histórico onde divergir do modelo detalhado atual de [BANCO](BANCO.md), da API em [CONTRATOS](CONTRATOS.md) e das transições em [ALGORITMOS](ALGORITMOS.md), conciliados em [CONSISTENCIA](CONSISTENCIA.md). Em particular, usar administrador por participação, códigos privados recuperáveis, janelas por geração, avaliação assíncrona e contextos persistidos. Isso não altera a precedência das regras confirmadas nem aprova integralmente mecanismos técnicos.

## Avanço — segurança e testes planejados (09/11/2026)

Criado [SEGURANCA-TESTES.md](SEGURANCA-TESTES.md): fronteiras de confiança, matriz por tabela, RLS/grants/funções, revogação Realtime, credenciais, riscos do validador e casos de segurança, concorrência, Android, notificações e operação. Critérios de aceite documentados; todos os testes não executados. Parâmetros e decisões pendentes continuam explícitos, sem aprovação integral. Design preservado, sem imagens ou código. Nenhuma infraestrutura, publicação ou teste funcional. Próximo planejamento: consolidar decisões abertas e fechar bloqueadores em pequenos lotes; não iniciar implementação.

## Avanço — arquitetura Android e infraestrutura (09/11/2026)

Criado [ANDROID-INFRA.md](ANDROID-INFRA.md): camadas/pacotes, coordenador único de sala, MediaSessionService/player, foco de áudio, controles externos, cache, API Supabase, push, validador, ambientes e APK. Proposta técnica baseada em documentação oficial; nenhum projeto/serviço criado. Restantes: aparelhos-alvo, push e executor de metadados. P04 definiu suspensão como reconexão normal; P03 permite inconclusiva com avanço manual autorizado. Design preservado, sem nova arte ou aprovação visual. Nenhuma implementação, publicação ou teste funcional. Próximo planejamento: segurança/RLS e matriz de testes/aceite, além dessas decisões operacionais.

Decisões confirmadas pelo usuário em 08/11/2026: (1) se o administrador sair e os demais estiverem reconectando, preservar reservas e manter sala temporariamente sem administrador, atribuindo o papel quando alguém retornar; (2) Play após terminar o último vídeo recomeça esse vídeo; (3) pular animações antigas excedentes, mantendo mensagens no chat autorizado. P15 confirmou depois até 5 animações pendentes e pular espera maior que 20 s, sem apagar chat/descartar corrente repetida por rotação. Isso não permite recuperar mensagens do intervalo desconectado nem aprova integralmente os mecanismos técnicos. Nenhuma imagem, implementação, publicação ou teste. Esta atualização substitui pendências históricas desses três comportamentos abaixo.

## Avanço — estados e algoritmos (08/11/2026)

Estados e algoritmos detalhados em [ALGORITMOS.md](ALGORITMOS.md), com decisões pendentes explícitas. Nenhuma implementação. Preservação de reservas sem administrador na saída e 60 s após detectar queda estão confirmados; mecanismos e variantes de eleição continuam técnicos.

Contratos lógicos detalhados em [CONTRATOS.md](CONTRATOS.md): entradas, autorização, efeitos atômicos, respostas, erros, idempotência e eventos. Proposta documental v1, sem aprovação integral ou implementação. Próximo planejamento: máquinas de estado/algoritmos e pendências impeditivas listadas no contrato.

Detalhamento posterior: [BANCO.md](BANCO.md) contém modelo proposto v1, campos/tipos, integridade, acesso, índices e retenção. Decisões confirmadas em 08/11/2026: reservar vaga por 60 segundos na queda; somente uma sala por pessoa; reconectar mostra apenas mensagens novas, sem recuperar o intervalo desconectado. O modelo detalhado refina administrador por participação, códigos recuperáveis privados e janelas de chat por conexão. Propostas técnicas ainda não aprovadas como conjunto; nenhuma implementação.

08/11/2026. Proposta para discussão antes de qualquer desenvolvimento. Nenhuma tabela, função, infraestrutura ou código de aplicativo criado. Não é especificação fechada: o registro de decisões ao final indica o que falta resolver.

## 1. Limites e responsabilidades

Android/Compose apresenta as telas aprovadas. Media3 reproduz a fonte diretamente. Supabase/PostgreSQL mantém identidade, regras, estado e persistência. Realtime sinaliza alterações; banco é a autoridade. Rotinas de servidor cuidam de prazos sem depender de um celular permanecer aberto.

Recomendação: arquitetura simples em camadas (interface → casos de uso → repositórios), com player separado da navegação. Evitar microserviços, consenso entre aparelhos e armazenamento de cada segundo do vídeo: não resolvem uma necessidade inicial deste produto e aumentam operação.

## 2. Banco relacional proposto

UUID para identidades internas; códigos públicos separados. Instantes em UTC no servidor; posições de mídia em milissegundos inteiros; versões/sequências em bigint. Valores e relacionamentos abaixo são desenho lógico, não migração SQL.

| Entidade | Campos principais | Integridade e acesso |
|---|---|---|
| profiles | user_id PK/FK da identidade, public_code único, nickname, created_at | Apelido mutável; código não autentica. Perfil completo somente dono; exposição mínima para amigos/participantes |
| preferences | user_id PK/FK, posição/tamanho/velocidade de mensagem, avisos de convite/amizade | Dono lê/altera; limites e padrões por definir |
| rooms | id PK, name, visibility, status, admin_id FK, created_at, closed_at, revision | Estado ativa/encerrada; no máximo um administrador; projeção pública só nome, id, marcador e contagem |
| room_codes | room_id FK único, code_digest único, created_at, invalidated_at | Resolver código por operação controlada; não expor listagem de códigos. Representação recuperável para copiar requer desenho separado de proteção |
| memberships | id PK, room_id/user_id FKs, joined_at, join_order, state, can_control, chat_start_seq | Uma participação ativa por usuário/sala; entrada nova cria nova sessão de participação |
| connections | id PK, membership_id FK, generation, last_seen_at, lease_until | Coração da detecção de queda. Atualizações antigas de conexão não ressuscitam participação encerrada |
| room_bans | room_id/user_id PK composta, actor_id, created_at | Bloqueio vale para esta sala e identidade; consultar antes de admitir |
| playback | room_id PK/FK, media_id, media_epoch, status, position_ms, reference_at, revision | Vazio/pausado/reproduzindo/finalizado; troca de mídia muda epoch; posição não negativa |
| media_items | id PK, room_id FK, source_url, kind, title, duration_ms opcional, created_by | URL restrita aos membros; tipo/duração informados pelo cliente não são prova confiável |
| queue_items | id PK, room_id/media_id FKs, position, added_by | Posição única na fila da sala; mídia atual separada dos próximos itens |
| room_counters | room_id PK, next_message_seq, next_join_order | Incrementos transacionais, sem relógio do aparelho |
| messages | room_id/seq PK composta, membership_id FK, sender_id, body, client_message_id | Unicidade de remetente + client_message_id; visibilidade após limite da participação |
| friendship_requests | id PK, sender_id/recipient_id FKs, state, created_at | Sem auto-solicitação; par canônico para impedir pendências duplicadas em sentidos opostos |
| friendships | user_low/user_high PK composta, created_at | Par ordenado, sem relação consigo mesmo; aceite cria vínculo e encerra solicitação atomicamente |
| room_invites | id PK, room_id/sender_id/recipient_id FKs, state, created_at, used_at | Uma pendência por sala/destinatário; usar somente após entrada bem-sucedida |
| command_receipts | actor_id/request_id PK composta, operation, payload_hash, result, created_at | Mesmo pedido retorna resultado anterior; mesmo id com conteúdo diferente é rejeitado |
| notification_outbox | id PK, recipient_id, event_key único, kind, state, attempts, next_attempt_at | Evento durável na mesma transação da operação social; entrega pode repetir e precisa deduplicação |
| device_tokens | id PK, user_id FK, token protegido, platform, updated_at | Somente se push for escolhido; nunca legível por outros usuários |

Relacionamentos principais: identidade → perfil/preferências/participações; sala → participantes/reprodução/fila/mensagens; pessoas → solicitações/amizades/convites. Fechamento invalida códigos/convites e remove mensagens. Retenção das demais entidades e recibos ainda precisa de prazo definido; não apagar identidade automaticamente por ser anônima, pois ela sustenta amizades.

Índices candidatos: salas ativas por visibilidade/data; participações por sala/estado e usuário/estado; conexões por lease_until; fila por sala/posição; mensagens por sala/seq; convites por destinatário/estado; solicitações por destinatário/estado; outbox por estado/next_attempt_at. Adicionar índices das FKs usadas em operações/limpeza. Busca por nome começa com regra de correspondência definida; avaliar índice de trigramas apenas se a escala e o plano de consulta justificarem.

Não armazenar contagem pública sem mecanismo consistente. Proposta inicial: agregação de participantes elegíveis; se houver custo medido, contador atualizado na mesma transação de entrada/saída. P05: reservas válidas ocupam vaga, mas número visível usa somente conectados.

## 3. Identidade e segurança

Recomendação: autenticação anônima interna, sem formulário de login. Supabase permite identidade autenticada sem email/senha; usuário anônimo autenticado é diferente do papel público anon. [Fonte oficial](https://supabase.com/docs/guides/auth/auth-anonymous).

Guardar sessão no aparelho, separar de código público e excluir credenciais de backup/migração para respeitar ausência de recuperação. Ainda especificar armazenamento seguro, renovação, expiração e comportamento de identidade perdida. Não criar identidade nova silenciosamente por uma falha transitória de rede.

Matriz de acesso proposta:

| Recurso/ação | Público autenticado | Membro | Autorizado | Administrador |
|---|---|---|---|---|
| Catálogo de salas públicas | Ler projeção mínima | Igual | Igual | Igual |
| Sala privada, mídia e chat | Sem leitura geral | Ler conforme sessão | Igual | Igual |
| Enviar chat | Não | Sim, com limite | Sim | Sim |
| Controlar mídia/fila | Não | Não | Sim | Sim |
| Permissões, expulsar, transferir, encerrar | Não | Não | Não | Sim |
| Perfil/preferências/convites pessoais | Somente próprios ou projeção permitida | Igual | Igual | Igual |

Todas as tabelas expostas exigem políticas RLS e grants mínimos; mutações críticas passam por operações transacionais, sem UPDATE direto pelo app. Funções privilegiadas, se necessárias, precisam search_path fixo, validação explícita do ator e permissão de execução restrita. O cliente nunca fornece o ator confiável; ele vem da sessão validada. Chaves privilegiadas e assinatura do APK ficam fora do app e repositório.

Realtime tem autorização própria para Broadcast/Presence; sua configuração não substitui segurança das tabelas. Não distribuir mensagens/URLs sensíveis em canal que um expulso possa continuar ouvindo. Proposta inicial: eventos mínimos de invalidação e leitura autorizada do estado; projetar revogação de canal e expiração de sessão antes de escolher payloads completos. [Fonte oficial](https://supabase.com/docs/guides/realtime/authorization).

## 4. Métodos e algoritmos por problema

| Problema | Recomendação inicial | Por quê / alternativa |
|---|---|---|
| Sala lotada e entradas concorrentes | Transação + bloqueio da linha da sala + contagem/admissão | Impede duas entradas consumirem a última vaga; checagem só no app falha |
| Comandos simultâneos | Serialização por sala e comparação de versão | Ordem única e conflito explícito; última escrita cega pode sobrescrever mudança recente |
| Retry de operação | Chave idempotente + hash + resultado na mesma transação | Evita dupla mensagem/entrada/convite após timeout |
| Ordenar chat | Contador por sala incrementado em transação | Define ordem de aceitação pelo servidor; timestamps podem empatar |
| Fila | Posições inteiras e renumeração transacional O(n) | Simples para fila limitada; ranking fracionário só se escala exigir |
| Próximo vídeo | Compare-and-swap por media_epoch sob bloqueio | Vários avisos de término não pulam vários vídeos |
| Escolher administrador | Menor join_order entre conexões elegíveis | Determinístico e sem relógio do cliente; desempate por id |
| Detectar queda | Heartbeat + lease + rotina de vencimento | Presence é sinal de interface, não relógio durável de administração |
| Reconectar | Backoff exponencial com jitter + snapshot/versionamento | Evita tempestade de tentativas e recupera eventos perdidos |
| Antispam | Token bucket por identidade/operação, atualização atômica | Permite pequenas rajadas sem envio sustentado excessivo; limites ainda abertos |
| Gerar códigos | Aleatoriedade criptográfica + unicidade + retry de colisão | Evita sequências previsíveis; comprimento depende de escala e tentativas permitidas |
| Paginar chat/convites | Cursor estável por sequência ou (created_at,id) | Não desloca páginas como OFFSET sob inserções |
| Sincronizar reprodução | Relógio estimado + posição de referência + correção por faixas | Não envia atualização por frame; não exige líder entre aparelhos |
| Entregar notificações | Outbox + retry limitado + deduplicação | Separa transação de envio externo; não promete entrega exatamente uma vez |

Bloqueios de linha do PostgreSQL permitem serializar alterações concorrentes; usar ordem fixa de aquisição e retry limitado para deadlock. A aplicação proposta é uma decisão de arquitetura, não uma promessa automática do banco. [Fonte oficial](https://www.postgresql.org/docs/current/explicit-locking.html).

## 5. Contratos de operações

Operações mutáveis recebem request_id e dados; comandos de sala recebem versão esperada quando necessário. Resposta: resultado, versão atual e horário do servidor. Erros estáveis: INVALID_INPUT, NOT_FOUND_OR_UNAVAILABLE, ROOM_FULL, FORBIDDEN, CLOSED, CONFLICT, RATE_LIMITED, SOURCE_UNAVAILABLE. Texto da interface segue cards aprovados. Não revelar detalhes de sala privada a quem não tem acesso.

| Método lógico | Passos atômicos principais |
|---|---|
| createRoom | Validar nome/limite de criação → criar sala/código → membro administrador → reprodução vazia |
| joinRoom | Resolver código/id/convite autorizado → bloquear sala → verificar ativa/bloqueio/vaga → criar ou retomar participação → registrar limite de chat → consumir convite se sucesso |
| getRoomSnapshot | Autorizar participação → obter estado, versões, fila e participantes consistentes; mensagens paginadas pelo limite da sessão |
| sendPlaybackCommand | Autorizar → verificar versão/epoch → aplicar play/pause/busca → atualizar referência/versão |
| addMedia / playNow | Validar entrada/permissão → cadastrar mídia → adicionar fila ou substituir atual; substituída não entra automaticamente na fila |
| reorderQueue / removeQueueItem | Autorizar → bloquear sala → conferir versão e conjunto de ids → alterar fila → incrementar versão |
| reportMediaEnded | Verificar participante/epoch e critério de término confiável → avançar uma vez; confiança na duração ainda é pendência |
| sendMessage | Autorizar participação → antispam → deduplicar → atribuir sequência → persistir |
| heartbeat / reconnect | Validar geração da conexão → renovar lease se participação ainda válida → retornar necessidade de snapshot |
| leaveRoom / transferAdmin | Bloquear sala → validar sucessor ou selecionar mais antigo → sair/transferir; último saindo encerra |
| kickMember / closeRoom | Validar administrador → revogar acesso e conexão; expulsão cria bloqueio; encerramento invalida convites/código e apaga chat |
| requestFriendship / answerRequest | Validar par/estado/ator → criar pendência ou aceitar/recusar → amizade única no aceite |
| inviteFriend / removeFriend | Validar vínculo e acesso; P07 preserva convites emitidos até uso/encerramento mesmo após remover amizade |
| updatePreferences / nickname | Validar dono e limites → persistir; P08 preserva apelido do envio nas mensagens antigas |

Protocolo padrão de mutação: autenticar → iniciar transação → deduplicar → bloquear agregado → verificar autorização/versão → alterar → gravar recibo/outbox → commit. Nada de chamada HTTP à mídia/provedor dentro de transação com bloqueio. Para operações em múltiplos agregados, definir uma ordem global de bloqueios.

## 6. Reprodução e reconexão em detalhe

Estado compartilhado: media_epoch, mídia, posição base p0, horário de referência t0, status e revision. Posição-alvo: pausado = p0; reproduzindo = p0 + (tempo estimado do servidor − t0), limitada à duração quando conhecida. O servidor materializa a posição atual ao pausar antes de alterar status.

Estimar diferença de relógios usando amostras de ida/volta e ponto médio, priorizando menor latência; medir intervalos com relógio monotônico. Assimetria da rede gera erro residual, portanto não prometer sincronização perfeita. Atualizar estimativa após reconexão e mudanças relevantes de rede.

Correção proposta: desvio pequeno não altera player; intermediário ajusta velocidade temporariamente se suportado; grande faz seek. Histerese e intervalo mínimo evitam oscilar. Valores, velocidades e alvo aceitável serão especificados antes de codificar como hipóteses de teste, e calibrados depois em aparelhos.

Snapshot e eventos: assinar canal, aguardar confirmação, armazenar eventos durante snapshot, aplicar somente revisões posteriores. Lacuna ou reconexão dispara nova leitura. Cada domínio deve ter revisão explícita; não presumir continuidade de uma sequência se o canal filtra eventos. Mensagens usam cursor próprio e deduplicação por id.

Buffering/falha individual não pausa os demais; recuperação realinha à sala. Chamadas e foco de áudio devem afetar reprodução local sem emitir pausa compartilhada automaticamente. Botões Bluetooth/tela bloqueada precisam passar pela mesma autorização que controles visuais.

MediaSessionService é o candidato para manter player/sessão fora da tela e suportar áudio em segundo plano. O planejamento ainda precisa combinar serviço, foco de áudio, encerramento, rotação e comandos externos. [Fonte oficial](https://developer.android.com/media/media3/session/background-playback).

## 7. Prazos, chat e conteúdo

P01 confirmou 60 segundos após detectar a queda. No desenho por silêncio, suspect_at=last_seen+D e grace_deadline=suspect_at+60s; H/D e rotina continuam hipóteses técnicas. Não usar last_seen+60s como regra vigente. Não apresentar execução exatamente no segundo 60 se o agendador só verificar periodicamente. Operações de sala também reconciliam leases vencidos sob bloqueio. Empate entre reconexão e rotina tem resultado determinado pela transação vencedora, que revalida o estado.

Chat: limite de entrada e inserção da mensagem devem compartilhar ordenação transacional. Decisão posterior confirmada: reconexão dentro da mesma participação inicia nova janela de chat e mostra somente mensagens novas; não recupera mensagens do intervalo desconectado. Saída/nova entrada também ganha novo limite. Manter já vistas localmente está confirmado; P11 define cache somente em memória, perdido após morte do processo. Sobreposição horizontal usa FIFO de sequências, uma mensagem por vez. Pular animações antigas excedentes está confirmado; P12 define reticências só na animação e repetição da interrompida por rotação, mantendo texto inteiro no chat. P15 confirmou até 5 pendentes, pulando espera maior que 20 s, sem descartar corrente repetida por rotação.

Mídia: validação sintática não comprova reprodução. Planejar esquemas permitidos, redirects, timeout, codecs, MP4/HLS VOD, fonte expirada, título ausente e duração desconhecida. Não adicionar proxy/extrator genérico. Se o servidor consultar URLs, proteger contra SSRF, endereços locais e redirecionamentos; se somente o aparelho consultar, definir limites e privacidade da conexão direta. Critério de término confiável é especialmente importante: relato de cliente não autorizado não pode sozinho trocar a mídia para todos.

## 8. Operação, dados e testes planejados

Definir ambientes separados, migrações versionadas, backup/restauração, responsável pelo projeto e orçamento. Logs devem usar ids de operação sem tokens, códigos, URLs assinadas ou texto do chat. Medir latência de comandos, drift, reconexões, falhas de fonte, leases atrasados, lock contention e fila de notificações.

Modelo de carga a preencher: salas simultâneas R, participantes médios P, heartbeat H segundos → aproximadamente R×P/H renovações por segundo; mensagens M por sala/segundo → R×M gravações e até R×M×P entregas. Estimar custos depois de definir escala e transporte; limite de 10 pessoas por sala não limita quantidade de salas.

Plano de testes futuro: concorrência na última vaga; comandos repetidos e fora de ordem; três avisos simultâneos de fim; expulsão com canal ainda aberto; crash após commit antes da resposta; reconexão na fronteira do prazo; fila vazia; convite usado duas vezes; ausência de histórico anterior; reinstalação/backup; rotação/teclado/áudio; URL hostil/expirada; restauração de backup. Nenhum desses testes foi executado.

## 9. Registro de decisões e condição para iniciar implementação

| Bloco | Situação atual | Falta fechar antes do código |
|---|---|---|
| Plataforma e experiência | Aprovadas | Android mínimo e dispositivos-alvo |
| Banco | Modelo lógico proposto neste documento | Tipos finais, nulabilidade, constraints, índices, retenção, políticas por tabela e diagrama revisado |
| Identidade | Auth anônima recomendada | Persistência, backup, perda/expiração e antiautomação |
| Concorrência | Bloqueio por sala + versões recomendado | Ordem de locks, versões por domínio, idempotência e expiração de recibos |
| Sincronização | Algoritmo proposto | Faixas numéricas, frequência, alvo de drift e critério confiável de fim |
| Presença | Leases recomendados | Heartbeat, tolerância observável, scheduler, vagas e reconexão |
| Chat | Sequência por sala recomendada | Limites e detalhes técnicos da sobreposição/retencão; P11/P12 já confirmados |
| Social | Relações e transações propostas | Solicitações cruzadas, cancelamento/remoção, convites e push |
| Segurança | Matriz inicial | RLS completa, exposição pública, revogação Realtime, ameaças e mitigação |
| Operação | Áreas identificadas | Escala, orçamento, serviços, observabilidade, backup e SLA pretendido |
| Contratos/testes | Catálogo inicial | Payloads/erros por método, máquinas de estado e critérios quantitativos |

Ordem de planejamento: fechar regras abertas → revisar modelo e acesso → contratos/transações → algoritmos/estados → arquitetura Android → operação/testes → revisão consolidada com usuário. Não passar automaticamente de uma etapa de planejamento para programação.

Este documento inicia o detalhamento técnico; não declara planejamento completo nem decisões técnicas aprovadas. Implementação depende de solicitação posterior do usuário. Pesquisa documental verifica mecanismos disponíveis, não valida este sistema funcionando.
