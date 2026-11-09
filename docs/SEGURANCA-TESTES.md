# Segurança, permissões e critérios de aceite — proposta v1

P04–P06 confirmados em 09/11/2026: suspensão pelo Android quando pausado/sem vídeo segue reconexão normal, com reserva de 60 s após detecção; número visível nos cards e sala conta somente conectados, mas reservas válidas ainda ocupam o limite de 10; ex-administrador preserva apenas sua permissão individual anterior, sem ganhar controle automaticamente ao transferir. Áudio durante reprodução em segundo plano permanece requisito. Esta atualização substitui pendências históricas desses comportamentos. Nenhuma imagem, implementação, publicação ou teste.

09/11/2026. Plano de segurança e verificação futura, sem políticas SQL, código de testes, infraestrutura ou testes executados. Regras funcionais aprovadas estão em PLANEJAMENTO.md; arquitetura, parâmetros e mecanismos técnicos seguem propostos. Este documento não certifica segurança do aplicativo.

<a id="sec-01"></a>

## 1. Fronteiras de confiança

Não confiar no APK, payload, relógio do celular, apelido, código público ou evento enviado pelo cliente. Identidade vem da sessão validada; papel e permissão vêm do banco no momento da operação. Administrador é administrador apenas da sua sala. Worker é uma identidade operacional separada, não um usuário com flag admin.

Proteger: credenciais, relações de amizade, salas privadas, códigos, URLs assinadas, chat, permissões, fila e disponibilidade/custos. Adversários considerados: usuário autenticado de outra sala, participante sem permissão, usuário expulso, cliente alterado, remetente de URL maliciosa e abuso por múltiplas identidades. Administrador de infraestrutura tem acesso privilegiado: RLS não é proteção absoluta contra esse operador.

Limites: bloquear identidade não bloqueia pessoa após reinstalação; apagar mensagem não retira bytes já vistos por outro aparelho; código compartilhado de sala permite entrada a quem o recebeu; fonte original vê as conexões dos aparelhos. Não prometer DRM, anonimato de rede ou sigilo contra membros autorizados.

<a id="sec-02"></a>

## 2. Estratégia de autorização

Recomendação: tabelas de domínio em esquema privado, sem SELECT/INSERT/UPDATE/DELETE direto para papéis de aplicativo; expor operações e projeções mínimas. RLS é camada adicional nas tabelas pertinentes. Na API pública, papel sem sessão não recebe dados de produto; identidade anônima autenticada passa pela autorização normal. RLS controla linhas e não deve ser confundida com proteção de colunas. [Supabase — RLS](https://supabase.com/docs/guides/database/postgres/row-level-security).

Para funções invoker, grants e políticas devem permitir exatamente o necessário. Onde funções definer forem necessárias para acessar tabelas privadas, autorização explícita é obrigatória: dono mínimo, search_path fixo, nomes qualificados, EXECUTE revogado por padrão e liberado só aos papéis esperados. Não depender de RLS que o dono da função pode contornar. [Supabase — funções](https://supabase.com/docs/guides/database/functions).

A matriz abaixo define predicados da API e critérios da futura revisão RLS/grants. Não é política SQL pronta. Helpers de autorização não devem gerar recursão de políticas sobre memberships; desenhar acesso auxiliar privado, função limitada e testes de caminho negativo.

Predicados comuns: SELF = ator é dono; MEMBER = participação da sala não encerrada e ainda válida; LIVE = MEMBER com geração vigente e conexão habilitada; CONTROL = LIVE e administrador vigente ou can_control; ADMIN = LIVE e admin_membership_id igual à participação; WINDOW = LIVE e janela atual do ator, com seq > start_after_seq. Durante grace, só reconexão/saída/status mínimos são permitidos pela API; não presumir leitura contínua do chat.

<a id="sec-03"></a>

## 3. Matriz por tabela

Todas as mutações abaixo são operações restritas, nunca CRUD genérico do cliente.

| Tabela/grupo | Leitura pela API | Escrita autorizada | Negação que precisa ser testada |
|---|---|---|---|
| profiles | SELF completo; projeção de apelido/inicial por relação autorizada | SELF em campos permitidos; código/identidade só servidor | Listar perfis/códigos ou editar outra identidade |
| preferences | SELF | SELF; alteração validada e versionada | Ler preferências alheias ou mudar owner |
| rooms | Catálogo public/active mínimo; detalhes por LIVE | Criar autenticado; controle administrativo por ADMIN | UUID privado não concede acesso |
| room_codes | LIVE por getRoomCode | Servidor cria/invalida | SELECT/listagem de códigos e leitura após saída |
| memberships | LIVE vê projeção dos participantes da própria sala | Entrada/saída/transferência/expulsão transacionais | Autoatribuir can_control/admin ou trocar room_id |
| connections | Próprio status mínimo; deadlines internos não listados | Próprio heartbeat/reconnect validado; worker expira | Renovar conexão alheia ou geração antiga |
| room_bans | Sem listagem genérica do app | ADMIN por expulsão; servidor limpa conforme retenção | Apagar próprio bloqueio ou bloquear em outra sala |
| playback | LIVE na mesma sala | CONTROL; avanço por rotina confiável | Mudar por duração ou finished enviados como verdade pelo cliente |
| media_items | LIVE, somente campos necessários da sala | CONTROL via validação/adicionar | Obter URL de outra sala ou forjar ticket |
| media_validations | Dono da avaliação e LIVE na sala/participação vinculada, projeção mínima | CONTROL cria pedido; worker confiável conclui; add/play validam resultado/validade | Ler resultado/URL alheios, trocar ator/sala, usar pending/expired como avaliação admitida |
| queue_items | LIVE | CONTROL, versão e ids da mesma sala | Reordenar/remover mídia de outro room_id |
| room_counters | Sem leitura direta | Operações transacionais | Escolher sequência ou join_order |
| messages | WINDOW; cursor não reduz limite | LIVE, remetente derivado da sessão, limite e deduplicação | Histórico anterior/intervalo desconectado por qualquer endpoint |
| chat_windows | Própria janela atual, campos mínimos | Servidor na admissão/reconexão | Reabrir janela antiga ou baixar start_after_seq |
| friendship_pairs | Sem leitura direta | Operações sociais internas | Enumerar pares ou alterar par canônico |
| friendship_requests | Remetente/destinatário | Remetente solicita/cancela; destinatário aceita/recusa | Aceitar no lugar do outro ou alterar envolvidos |
| friendships | Envolvidos, projeção de amigos | Aceite cria; envolvido remove conforme regra final | Criar vínculo unilateral direto |
| room_invites | Destinatário; remetente recebe status mínimo pertinente | Membro convida amigo; ingresso consome; encerramento invalida | Consumir convite alheio ou marcar usado sem entrada |
| command_receipts | SELF, resultado mínimo via status | Operação cria junto com commit | Usar recibo para recuperar acesso revogado |
| command_contexts | Dono recebe referência opaca/validade pela operação própria | Servidor emite/revoga; nova execução exige validade | Forjar contexto, usar contexto alheio/vencido ou executar após limpeza de recibo |
| rate_buckets | Sem leitura direta | Serviço com atualização atômica | Zerar cota ou falsificar tempo |
| notification_outbox | Sem leitura direta | Transação social e worker com claim | App publicar push ou marcar entregue |
| device_tokens | Sem listagem geral; status próprio se necessário | Registro/revogação autenticados e prova de associação a definir | Associar token alheio ou expor tokens |

Campos adicionados futuramente não entram automaticamente nas projeções. Preferir lista explícita de campos; revisar views para não contornar RLS. Garantias entre tabelas também exigem FKs/constraints e transações, não apenas políticas de leitura.

<a id="sec-04"></a>

## 4. Realtime e revogação

Autorização de Broadcast/Presence usa políticas próprias; não equivale à autorização das tabelas do domínio. Canal privado e nome imprevisível não dispensam verificar participação. [Supabase — Realtime Authorization](https://supabase.com/docs/guides/realtime/authorization).

Proposta: cliente não publica eventos autoritativos. Servidor envia invalidações mínimas; conteúdo é lido por API reautorizada. Expulsão/saída/encerramento revogam direitos no commit, mesmo que assinatura antiga ainda exista. Não colocar corpo de chat, URL ou código em broadcast antigo. Metadados de atividade também podem ser sensíveis: decidir tolerância ou rotação de tópicos/geração de audiência para evitar avisos posteriores a expulsos. Isso permanece condição a fechar, não segurança garantida por token atual.

Testar também acesso via REST/RPC, views, joins embutidos, paginação, contagens, erros, recibos, cache e eventos. Resultado autorizado produzido antes da revogação pode chegar depois; cliente honesto descarta geração antiga. Não afirmar que um adversário esquece dados recebidos legitimamente antes do commit.

<a id="sec-05"></a>

## 5. Credenciais, mídia e abuso

| Risco | Controle proposto | Evidência futura |
|---|---|---|
| Credencial privilegiada no APK/repositório | Só configuração publicável no cliente; segredos de worker/push/assinatura externos | Inspeção do APK, histórico Git, logs e configuração de build |
| Roubo/backup da identidade | Armazenamento privado protegido; excluir credenciais de backup/transferência | Reinstalação e backup/restore controlados, sem exportar tokens em evidências |
| SSRF no validador | Rede pública permitida, DNS/IP e redirects verificados a cada salto; bloquear loopback/privadas/link-local/metadados | Servidores de teste controlados, IPv4/IPv6, redirect e rebinding; nenhum alvo real de terceiros |
| Parser consumindo recursos | Limites de bytes/tempo/expansão, isolamento, cancelamento | Arquivos de teste grandes/malformados e quota medida |
| Fonte muda após validar | Ticket vinculado à avaliação/versão/validade; reavaliar divergência | Fixture que muda metadados e conteúdo |
| Enumeração/brute force | Resposta mínima, códigos aleatórios, rate limit e proteção global | Tentativas limitadas em ambiente de teste; ausência de vazamento por erro |
| Repetição/conflito | Contexto válido, request_id/hash, versões e locks | Timeout após commit e concorrência reproduzível |
| Push indevido | Worker restrito, destinatário validado, payload mínimo | Token rotacionado, tentativa de reassociação e convite expirado |
| Custos por identidades em massa | Proteção no bootstrap anônimo e cotas globais | Carga sintética autorizada e teto de consumo definido |

Escopo dos testes de segurança: infraestrutura própria de teste e fixtures. Nenhuma exploração ou carga é autorizada em serviços de mídia de terceiros. Código de convite é um meio compartilhável de entrada, não substitui autenticação de identidade. URL assinada é tratada como segredo até entre logs de erro.

<a id="sec-06"></a>

## 6. Ambiente e evidência dos testes

Usar banco isolado com identidades A (admin), B (autorizado), C (membro comum), D (externo), E (expulso) e F (segunda sala). Nenhum teste de permissão usa service role como ator de aplicativo. Executor privilegiado serve somente para preparar fixture e verificar invariantes, separado da chamada que está sendo testada.

Cada execução registra: id do caso, revisão do código/schema/configuração, aparelhos/Android quando aplicável, rede/fixture, passos, resultado esperado, observado, duração e evidência sanitizada. Estados: não executado, passou, falhou, bloqueado por decisão ou não aplicável com motivo. “Bloqueado” nunca conta como passou. Resultado de revisão documental não é teste funcional.

<a id="sec-07"></a>

## 7. Matriz de testes de segurança e concorrência

Todos os casos abaixo estão **não executados**; os que dependem de decisão também ficam bloqueados até ela ser fechada.

| ID | Ação e cenário | Critério objetivo de aceite |
|---|---|---|
| S01 <a id="s01"></a> | Sem sessão tenta ler/mutar dados | Nenhum dado de produto ou alteração; só fluxo de autenticação permitido |
| S02 <a id="s02"></a> | D/F tenta sala privada de A por todos os caminhos | Zero conteúdo, código, URL, chat ou metadado privado indevido |
| S03 <a id="s03"></a> | C tenta play/fila/admin com flags/id adulterados | Zero alteração compartilhada; erro coerente |
| S04 <a id="s04"></a> | E conserva JWT/canal/recibos após expulsão | Nenhuma nova leitura/mutação autorizada após commit; nenhum conteúdo sensível via canal antigo |
| S05 <a id="s05"></a> | C muda owner/room_id/generation/window em payload | Rejeição, sem efeito cruzado |
| S06 <a id="s06"></a> | D aceita solicitação ou usa convite destinado a C | Zero vínculo/entrada/consumo indevido |
| S07 <a id="s07"></a> | Dados sensíveis em erro/log/push/APK | Zero token privilegiado, assinatura privada, corpo de chat ou URL assinada indevida |
| S08 <a id="s08"></a> | URL adversarial em validador isolado | Nenhuma conexão a destino proibido; limite de recurso respeitado |
| C01 <a id="c01"></a> | Duas entradas disputam décima vaga | Exatamente uma entra; contagem final ≤10 incluindo reservas |
| C02 <a id="c02"></a> | Mesma identidade entra em duas salas simultaneamente | No máximo uma participação válida |
| C03 <a id="c03"></a> | Dois comandos com mesma revisão | Uma transição aceita, outro conflito ou resultado idempotente pertinente |
| C04 <a id="c04"></a> | Repetir mesmo pedido após resposta perdida | Um único efeito; payload diferente com mesmo id é rejeitado |
| C05 <a id="c05"></a> | Pedido velho após limpeza de recibo | Não reexecuta sob contexto expirado |
| C06 <a id="c06"></a> | Três relatos de término para mesma epoch | No máximo uma promoção; nenhum salto de dois itens |
| C07 <a id="c07"></a> | Pause/seek disputa timer de fim | Resultado corresponde à ordem transacional/revisões, sem avanço antigo |
| C08 <a id="c08"></a> | Reorder disputa add/remove | Nenhum item perdido/duplicado e posições únicas ao commit |
| C09 <a id="c09"></a> | Aceites/solicitações cruzados | Um vínculo por par; nenhuma amizade sem aceite autorizado |
| C10 <a id="c10"></a> | Convite usado duas vezes | Uma admissão válida; convite só consumido junto com sucesso |
| C11 <a id="c11"></a> | Worker atrasado, heartbeat em grace e retomada | detected_at por silêncio é suspect_at, deadline não recomeça; grace nega snapshot/chat/controle com RECONNECT_REQUIRED; getMyParticipation só expõe referência própria; generation antiga não renova |
| C12 <a id="c12"></a> | Validação assíncrona e referência de mídia | pending/expired, outro ator/sala/participação ou URL diferente não alteram mídia/fila; inconclusive admitida usa modo manual; cliente comum ou modo paused não avança; modo/timer derivam do snapshot admitido |
| C13 <a id="c13"></a> | Contexto expirado e recibo existente/limpo | Recibo existente retorna só mínimo sem reexecução; sem recibo e contexto inexistente/vencido rejeita; não converter pedido para novo contexto; exceções bootstrap/heartbeat mantêm deduplicação própria |
| C14 <a id="c14"></a> | Supressão/reclaim disputa conclusão de outbox | Resultado só grava com status leased e attempt_token vigente; claim antigo não sobrescreve suppressed/delivered; push duplicado não altera recurso social |
| C15 <a id="c15"></a> | Encerramento com player/fila/mídia | Fechamento retira referência playback e limpa fila antes de excluir mídia elegível; admin none, gerações/janelas inválidas; closed nega replay; revisões/eventos apenas de domínios alterados; sem FK órfã |
| C16 <a id="c16"></a> | Apelido/locks, relações e janelas antigas | Envio adquire perfil antes da sala, registra nome do envio e retorna chave room_id/seq; FKs rejeitam ator/sala divergentes; reconexão preserva geração histórica fechada sem reabri-la ou bloquear troca da conexão atual |

<a id="sec-08"></a>

## 8. Matriz funcional e Android

| ID | Cenário | Critério de aceite |
|---|---|---|
| F01 <a id="f01"></a> | Criar/entrar | Direto ao player/chat; pública ligada por padrão; sem espera/agendamento |
| F02 <a id="f02"></a> | Queda e retorno antes do prazo | Vaga preservada, geração nova e mesma participação; nenhuma mensagem do intervalo recuperada |
| F03 <a id="f03"></a> | Cache de mensagens já vistas | Conteúdo visto permanece na reconexão do mesmo processo; novas mensagens se acrescentam sem duplicação |
| F04 <a id="f04"></a> | Deadline antes/igual/depois | Resultado determinístico conforme origem/fronteira aprovadas; pacotes antigos não prolongam prazo |
| F05 <a id="f05"></a> | Admin sai com todos em grace | Reservas preservadas, admin temporariamente ausente; atribuído ao retorno conforme eleição definida |
| F06 <a id="f06"></a> | Saída/queda do último | Voluntária encerra imediatamente; queda respeita prazo definido; código não readmite encerrada |
| F07 <a id="f07"></a> | Término e replay | Próximo automático quando houver; último quadro ao esvaziar; Play recomeça último vídeo com nova epoch |
| F08 <a id="f08"></a> | Excesso de animações | Uma por vez, esquerda→direita, ordem preservada entre restantes; excedentes pulados sem apagar chat |
| F09 <a id="f09"></a> | Encerrar sala | Chat removido no banco ativo, convites/código inválidos; cliente informado para e limpa estado |
| A01 <a id="a01"></a> | Dez rotações com mídia tocando | Um player e uma participação, sem reinício do vídeo nem perda do chat local |
| A02 <a id="a02"></a> | Teclado/painéis em duas orientações | Campo/ações alcançáveis; fechar painel não pausa mídia; proporção preservada |
| A03 <a id="a03"></a> | Tela bloqueada por 15 min reproduzindo | Áudio continua em aparelhos-alvo e sincronização observada; período é proposta de ensaio |
| A04 <a id="a04"></a> | Chamadas/foco/Bluetooth | Efeito local não pausa todos; controle compartilhado respeita permissão |
| A05 <a id="a05"></a> | Pausa prolongada/sem mídia em background | P04: se Android suspender, aplicar reconexão normal e reserva de 60 s após detecção; não exigir presença permanente. Áudio durante reprodução continua requisito |
| A06 <a id="a06"></a> | Processo morto/reinstalação/atualização | Retorno revalida participação; reinstalação não recupera identidade; atualização assinada preserva identidade |
| N01 <a id="n01"></a> | Push em app aberto/fechado | Solicitação/convite abre recurso atual da identidade correta, sem entrada automática |
| N02 <a id="n02"></a> | Permissão negada/offline/token rotacionado | Convite continua consultável; não mostrar envio/entrega garantidos sem evidência |
| N03 <a id="n03"></a> | Push atrasado/duplicado após sala encerrar | Não reabre sala, não duplica convite; feedback de indisponibilidade |
| V01 <a id="v01"></a> | MP4/HLS VOD válidos e fontes incompatíveis | Avaliação coerente; falha local não pausa demais; inconclusivo não vira “inválido” sem regra |
| U01 <a id="u01"></a> | Referências aprovadas e acessibilidade | Home preservada, cards consistentes, textos/ações sem corte em aparelhos-alvo e fonte ampliada |
| F10 <a id="f10"></a> | Play inicial em sala sem mídia com fila | P02: adicionar não inicia; Play de autorizado promove só primeiro item atomicamente; retry não promove outro |
| F11 <a id="f11"></a> | Fonte reproduzível com duração inconclusiva | P03: permitida; aviso de cliente comum não avança; comando manual autorizado promove no máximo um ou marca ended; Play posterior reinicia última mídia |
| F12 <a id="f12"></a> | Contagem versus capacidade com reservas | P05: 8 conectados + 2 reservas válidas exibe 8, mas rejeita nova entrada; reserva expirada não continua ocupando vaga |
| F13 <a id="f13"></a> | Controle depois de transferir administração | P06: ex-admin com can_control prévio mantém controle; sem permissão prévia perde controle; transferência não concede permissão automaticamente |
| F14 <a id="f14"></a> | Amizade cruzada, cancelamento e remoção | P07: sem amizade automática; remetente só cancela pending; qualquer envolvido pode remover vínculo para ambos com confirmação na UI; convites emitidos permanecem até uso/encerramento |
| F15 <a id="f15"></a> | Alteração de apelido após envio | P08: mensagens antigas mantêm apelido do envio em leitura/cache; novas capturam apelido vigente no commit; payload não pode forjar remetente/apelido |
| F16 <a id="f16"></a> | Repetição intencional de URL e retry | P09: duas adições intencionais geram itens independentes; retry do mesmo pedido gera um único item; remover um não remove o outro |
| F17 <a id="f17"></a> | Preferências iniciais e tela bloqueada | P10: ambos os avisos ligados no primeiro perfil, sem redefinir preferências existentes; texto bloqueado só “Você recebeu um convite” ou “Nova solicitação de amizade”, sem nomes; permissão Android negada não altera preferência silenciosamente |
| F18 <a id="f18"></a> | Morte do processo versus queda/rotação | P11: queda/rotação no mesmo processo preserva já vistas; morte elimina cache de chat; retorno revalida identidade/participação e não recupera janelas antigas ou intervalo desconectado |
| F19 <a id="f19"></a> | Texto longo e animação interrompida por rotação | P12: reticências só na animação, chat inteiro; interrompida repete do início antes das próximas em ordem, uma por vez; concluídas não repetem, não há novo envio/registro no chat nem replay de geração invalidada |
| F20 <a id="f20"></a> | Voltar, Parar externo e saltos | P13: Voltar fecha teclado/painel, horizontal retorna ao vertical, vertical confirma saída; cancelar mantém sala, confirmar segue sucessão. Parar externo só local, sem pausa global/encerramento/saída automática; snapshots não anulam a parada local. Retomada revalida estado; saltos de 10 s só por autorizado e dentro dos limites da mídia |
| F21 <a id="f21"></a> | Fontes HTTP e HTTPS | P14: fontes diretas MP4/HLS VOD controladas abrem com ambos os protocolos, inclusive URLs assinadas; não recusar apenas por HTTP. Validar redirects/destinos também nas playlists/segmentos; não enviar credenciais de app ao host de mídia; manter proteções de S08 |
| F22 <a id="f22"></a> | Limites iniciais e fila de animações | P15: validar limites inferior/superior e imediatamente fora para apelido 2–24 e sala 2–60; mensagem até 500; 50 próximos aceitos, 51º recusado inclusive em concorrência. Até 5 animações pendentes; pular espera maior que 20 s, preservando ordem/chat e animação corrente repetida na rotação. Contagem Unicode comum precisa ser especificada antes de executar |

P11 confirmou cache somente em memória: morte do processo perde já vistas; queda/rotação no mesmo processo preservam cache. Não recuperar intervalo desconectado nem reconstruir janelas antigas.

<a id="sec-09"></a>

## 9. Desempenho, resiliência e operação

Protocolo de ensaio proposto: duas redes distintas e pelo menos dois aparelhos; mídia VOD de teste controlada; sessão de 30 min; rede base e perfis degradados com latência/perda registradas. Amostrar drift a cada 2 s; considerar estabilização após 10 s sem preparing/buffering/reconexão. Medir posição contra referência comum; não confiar em comparação de relógios civis dos aparelhos.

Alvo proposto, não aprovado/medido: |drift| ≤500 ms em 95% das amostras elegíveis. Relatar também percentual de amostras excluídas e tempo de recuperação; se quase tudo for excluído, resultado é inconclusivo, não aprovação. Calibrar perfil de rede, limite de exclusões e aparelhos antes de congelar esse teste. Carga inicial: 10/50/100 participantes distribuídos conforme PARAMETROS.md; não confundir cenário sintético com capacidade comprovada.

| ID | Injeção/ensaio | Resultado esperado |
|---|---|---|
| O01 <a id="o01"></a> | Falha antes/depois do commit | Antes não altera; depois retry recupera efeito único |
| O02 <a id="o02"></a> | Evento Realtime perdido/duplicado | Snapshot/revisões convergem sem ação duplicada ou histórico proibido |
| O03 <a id="o03"></a> | Worker de deadline atrasado | Operações negam prazo vencido; worker reconcilia sem ressuscitar participação |
| O04 <a id="o04"></a> | Worker de push morre após enviar | Retry não altera recurso; duplicação tratada, sem alegar entrega exatamente uma vez |
| O05 <a id="o05"></a> | Backup restaurado | Não disponibilizar antes de reaplicar revogações/encerramentos/exclusões pertinentes |
| O06 <a id="o06"></a> | Atualização de backend com APK anterior | Contrato compatível ou atualização exigida claramente; sem corrupção silenciosa |
| O07 <a id="o07"></a> | Limite global/custo excedido | Proteção definida atua sem vazar segredo ou derrubar integridade |

Restauração deve ser praticada em ambiente isolado. Tempo máximo aceitável, perda de dados tolerável, política de backups, limites de custos e alerta ainda são decisões operacionais abertas.

<a id="sec-10"></a>

## 10. Condições para avançar

Antes de considerar planejamento fechado: fechar dispositivos, mecanismos de push/validação, grants/RLS finais, bootstrap do teste fechado, parâmetros técnicos, retenção e detalhes de detecção/concorrência. P01–P15 estão confirmados; F10–F22 documentam cobertura adicional, ainda não executada. Vincular requisitos a casos, responsáveis e ambientes; não inventar defaults.

Antes de distribuir APK funcional futuramente: todos os casos críticos de autorização, integridade, chat, capacidade e fechamento passam; nenhum vazamento ou efeito duplicado aberto; casos bloqueados que afetam escopo impedem declarar entrega completa. Critérios de desempenho e experiência precisam ser aprovados e medidos. Falhas menores documentadas não podem ser escondidas como “testado”. Distribuição futura continua dependendo de autorização do usuário, não desta lista.

Próximo trabalho de planejamento: consolidar registro único de decisões abertas e resolver os bloqueadores em pequenos lotes. Não iniciar código ou executar testes por consequência deste documento.
