# Desenvolvimento em blocos — assistAe

## Avanço de implementação e aparelho — 09/11/2026

Backend possui 16 migrações, 23 tabelas privadas e 30 RPCs: identidade/preferências, salas/catálogo, leases/reconexão, chat/administração, amizade/convites e status de comandos. Dezessete suítes SQL passaram. Aceite explícito nas cruzadas, remoção bilateral preservando convites emitidos, outbox sem envio push. Papéis de API limitados, sem login/BYPASSRLS/DDL permanente. Locks de perfis UUID antes de par/sala/FKs; disputa entre duas sessões ainda não demonstrada. [Estado, decisões técnicas e evidências](IMPLEMENTACAO.md). Pendentes mídia/fila, dispatcher push, Realtime e app Android/APK; Auth/REST e aparelho não validados. P01–P15/design preservados, B00/blocos completos não concluídos. Galaxy A54 com Play Store confirmado, APK direto, somente Android; versões exatas do SO não informadas. Sem imagem nova, publicação de APK ou notificações reais enviadas. Notas abaixo são históricas.

## Início de execução autorizado — 09/11/2026

Usuário solicitou começar a implementação pelo Supabase. B01 iniciou somente backend de identidade/preferências; B02 recebeu modelo físico e base de comandos, sem operações de sala. B00 não concluído; demais blocos não implementados. Estado/evidências em [IMPLEMENTACAO.md](IMPLEMENTACAO.md). As seções históricas abaixo continuam como roteiro e não como afirmação de que código atual é apenas proposta.


09/11/2026. Proposta de organização após revisão do repositório local. **Etapa atual: B00, somente planejamento.** Nenhuma implementação iniciada ou teste funcional executado. Concluir e revisar o planejamento com o usuário antes de programação, que depende de solicitação posterior explícita.

## Diagnóstico e escopo

O repositório contém documentação de produto/técnica, referências PNG e prompts. Não há projeto Android/Gradle, código Kotlin, migrações, backend implementado, suíte de testes ou APK. O histórico recente registra aprovações de design. A análise considera também as alterações locais anteriores, inclusive documentos técnicos ainda não rastreados pelo Git; nada foi publicado nesta revisão.

Produto, banco, contratos, algoritmos, Android, infraestrutura, parâmetros, segurança e testes já têm propostas documentadas. O roteiro anterior de sete etapas agrupava identidade e salas em uma entrega grande. Reconexão, segurança e validação precisam aparecer desde os blocos que estabelecem suas garantias. A nova divisão abaixo substitui aquela sequência para organização futura, sem declarar as propostas técnicas aprovadas.

Escopo preservado: Android nativo, Kotlin/Compose/Media3/Supabase, APK, MP4/HLS gravados, até 10 vagas por sala, chat, fila, administração, amigos e convites com avisos fora do app. YouTube fica para depois; sem lives, sala de espera, agendamento, login visível ou recuperação de identidade. Home/referências aprovadas permanecem base; ajustes reutilizam os mesmos componentes. Miniatura definitiva adiada.

Fontes: [PLANEJAMENTO](PLANEJAMENTO.md) rege produto; [DECISOES](DECISOES.md) é o registro único das escolhas; [DESIGN](DESIGN.md) controla referências; [ARQUITETURA](ARQUITETURA.md), [BANCO](BANCO.md), [CONTRATOS](CONTRATOS.md) e [ALGORITMOS](ALGORITMOS.md) detalham propostas técnicas; [ANDROID-INFRA](ANDROID-INFRA.md) e [PARAMETROS](PARAMETROS.md) cobrem Android/operação; [SEGURANCA-TESTES](SEGURANCA-TESTES.md) contém os casos futuros. Este roteiro associa entregas às fontes, sem duplicar questionários ou decisões.

## Como usar os links

Na tabela de sequência, clique no bloco. No guia de cada bloco, consulte primeiro as regras confirmadas, depois a especificação técnica e os critérios de verificação futura. Os IDs P01–P15 apontam à decisão original; T01–T11 apontam a trabalho técnico ainda aberto; os casos apontam a critérios planejados, sem execução. As fontes mantêm o conteúdo completo, sem copiá-lo para este roteiro. Âncoras explícitas não dependem de números de linha.

Conflito com registro histórico não reabre decisão confirmada. Proposta técnica vinculada não se torna aprovada. Todos os blocos continuam sujeitos ao fechamento de B00 e à solicitação posterior para implementar.

## Ordem e dependências

| Bloco | Entrega principal | Depende de | Estado atual |
|---|---|---|---|
| [B00 — Fechamento do planejamento](#b00) | Especificação coerente e revisão consolidada | Documentação e decisões restantes | Em planejamento |
| [B01 — Base Android e componentes](#b01) | App compilável, navegação e componentes reutilizáveis | B00 e solicitação posterior para implementar | Futuro |
| [B02 — Identidade e segurança do backend](#b02) | Identidade persistente, API protegida e ambiente isolado | B01 | Futuro |
| [B03 — Salas, presença e administração](#b03) | Criar/entrar/sair, reservas, reconexão, sucessão e encerramento | B02 | Futuro |
| [B04 — Player local e validação de mídia](#b04) | MP4/HLS, player único e avaliação segura de fonte | B03 | Futuro |
| [B05 — Sincronização e fila](#b05) | Reprodução compartilhada e transições atômicas | B04 | Futuro |
| [B06 — Chat e horizontal](#b06) | Janelas de mensagens, cache e animação ordenada | B03; integração final com B05 | Futuro |
| [B07 — Amigos e convites internos](#b07) | Solicitações, gerenciamento e ingresso por convite | B03 | Futuro |
| [B08 — Notificações fora do app](#b08) | Push, preferências, tokens e recuperação de falhas | B07 | Futuro |
| [B09 — Integração, operação e APK](#b09) | Evidências do escopo completo e pacote de teste fechado | B01–B08 | Futuro |

Sequência recomendada: B00 → B01 → B02 → B03 → B04 → B05 → B06 → B07 → B08 → B09. Dependências permitem preparar chat/social depois de B03; isso não exige equipes paralelas nem autoriza trabalho agora. Priorizar uma entrega verificável por vez. Segurança, tratamento de erros, observabilidade e testes pertinentes acompanham cada bloco; B09 consolida a evidência e os fluxos entre blocos. Marcos internos não reduzem o escopo da primeira versão.

<a id="b00"></a>

## B00 — Fechar o planejamento

**Guia de consulta do bloco**

| Consulta | Local exato |
|---|---|
| Decisões | [Confirmadas](DECISOES.md#decisoes-confirmadas), [P01–P03](DECISOES.md#decisoes-p01-p03) e [P04–P15](DECISOES.md#decisoes-p04-p15); [critério de encerramento](DECISOES.md#fechamento-planejamento). |
| Especificação | [Pendências do modelo](BANCO.md#sec-08), [contratos a fechar](CONTRATOS.md#sec-14), [refinamentos dos estados](ALGORITMOS.md#sec-14) e [condições de avanço](SEGURANCA-TESTES.md#sec-10). |
| Revisão cruzada | [Achados/ajustes de banco, contratos e estados](CONSISTENCIA.md#achados), [contrato comum](CONSISTENCIA.md#contrato-comum) e [pendências remanescentes](CONSISTENCIA.md#pendencias). Revisão documental; nenhum caso funcional executado. |
| Aceite e bloqueadores | [Matriz de evidência](SEGURANCA-TESTES.md#sec-06), [T01–T11](DECISOES.md#trabalho-tecnico) e [informações operacionais](DECISOES.md#informacoes-operacionais). Nenhuma dessas pendências vira aprovação por estar vinculada. |

**Entrega:** regras, modelo, operações, estados, acesso, operação e aceite alinhados. Dividir o trabalho documental em quatro partes:

| Parte | Resultado | Referências |
|---|---|---|
| B00.1 — Conciliação | Separar histórico de regra vigente; incorporar respostas e alinhar campos/estados/contratos | T01–T03, T11; P01–P06 já confirmados |
| B00.2 — Escolhas catalogadas fechadas | P01–P15 confirmados: amizade, apelidos, fila, avisos/cache/animação, controles, fontes e limites. Regras incorporadas; não reabrir por pendências históricas | Fechamento de comportamento em 09/11/2026; revisão técnica de B00 ainda aberta |
| B00.3 — Engenharia e operação | Especificar autorização/revogação, identidade/backup, bootstrap dos amigos, serviços, parâmetros candidatos, retenção/restauração e responsabilidades | T04–T09; aparelhos, volume e orçamento ainda necessários |
| B00.4 — Aceite consolidado | Ligar requisitos aos casos; completar cobertura das decisões recentes; definir ambientes, dispositivos, rede, métricas e responsáveis | T10 e SEGURANCA-TESTES |

Conciliação de B00.1 em 09/11/2026: regras confirmadas corrigidas nos corpos dos documentos; revisão técnica do modelo ainda em andamento. Achados e situação:

- Corrigida referência temporal em ARQUITETURA/ALGORITMOS/PARAMETROS: 60 s após detecção. H/D/S e mecanismo continuam técnicos.
- BANCO incorporou os refinamentos propostos de conexão, contextos/recibos, avaliação/término e claim da outbox; [revisão cruzada](CONSISTENCIA.md#achados) conciliou dez divergências centrais. Constraints/grants finais, parâmetros, executor e variantes indicadas continuam abertos.
- Corrigidas pendências superadas de Play inicial, cache já visto e ex-admin em CONTRATOS/ALGORITMOS. P07–P09 também incorporados.
- ANDROID-INFRA alinhado a P04: suspensão pausado/sem vídeo segue reconexão normal.
- A05 e fechamento de SEGURANCA-TESTES corrigidos; F10–F16 acrescentados para P02/P03 e P05–P09, sem execução.

**Critério de saída:** decisões necessárias resolvidas ou alternativas delimitadas aceitas na revisão; nenhuma contradição vigente entre banco/contratos/algoritmos; autorização especificada por operação; serviços/custos compatíveis com teste fechado; matriz de aceite rastreável. Parâmetros de engenharia podem ser hipóteses de ensaio explícitas com método de calibração, sem alegar medição prévia.

**Próxima ação: continuar fechamento de B00.** Regras P01–P15 conciliadas; conjunto de escolhas catalogadas fechado. Continuar T01–T11 e informações operacionais, sem reapresentar confirmados; revisão técnica de B00.1 ainda aberta. B00 não está concluído e seu fechamento não libera automaticamente B01.

<a id="b01"></a>

## B01 — Base Android e componentes

**Guia de consulta do bloco**

| Consulta | Local exato |
|---|---|
| Regras confirmadas | [Plataforma/escopo](PLANEJAMENTO.md#produto-escopo), [P13 — Voltar e controles](DECISOES.md#p13) e [P15 — limites](DECISOES.md#p15). |
| Especificação técnica | [Organização Android](ANDROID-INFRA.md#sec-02), [navegação/estado local](ANDROID-INFRA.md#sec-05) e [limites de uso](PARAMETROS.md#parametros-limites). |
| Visual | [Home aprovada](DESIGN.md#design-home), [Criar sala](DESIGN.md#design-criar), [Entrar em sala](DESIGN.md#design-entrar) e [regras das telas](PLANEJAMENTO.md#produto-telas). |
| Verificação futura | [U01 — referências e acessibilidade](SEGURANCA-TESTES.md#u01); [A02 — teclado/painéis](SEGURANCA-TESTES.md#a02). |
| Pendências técnicas | [T09 — arquitetura Android](DECISOES.md#t09), [T10 — evidências](DECISOES.md#t10) e [aparelhos/versões](DECISOES.md#informacoes-operacionais). |

**Entrega futura:** projeto compilável com SDK/versões definidos em B00; tema, rotas, cards, campos, botões, avisos e confirmações. Home → Criar/Entrar → Sala; Configurações com Amigos como quinta opção. Estados vazio/carregando/erro/sem permissão reutilizam componentes existentes. Dados simulados devem ser identificados e isolados nos repositórios.

Preparar fronteiras de UI/domínio/dados e coordenação única da sala. Detalhar telas conforme cada funcionalidade for integrada, sem exigir todas as telas completas primeiro.

**Aceite futuro:** compilação reproduzível, navegação inspecionada no Android, Home comparada à referência e componentes utilizáveis com fonte ampliada (U01). Isso não comprova funcionalidades conectadas.

<a id="b02"></a>

## B02 — Identidade e segurança do backend

**Guia de consulta do bloco**

| Consulta | Local exato |
|---|---|
| Regras confirmadas | [Identidade sem login/recuperação](DECISOES.md#decisoes-confirmadas), [P10 — preferências iniciais](DECISOES.md#p10) e [P15 — limites](DECISOES.md#p15). |
| Especificação técnica | [Dados de identidade/preferências](BANCO.md#dados-identidade), [API de perfil](CONTRATOS.md#sec-04), [idempotência](CONTRATOS.md#sec-03), [autorização](SEGURANCA-TESTES.md#sec-02) e [credenciais](SEGURANCA-TESTES.md#sec-05). |
| Verificação futura | [S01 — sem sessão](SEGURANCA-TESTES.md#s01), [S05 — adulteração](SEGURANCA-TESTES.md#s05), [C04 — retry](SEGURANCA-TESTES.md#c04), [C05 — contexto expirado](SEGURANCA-TESTES.md#c05) e [A06 — identidade/atualização](SEGURANCA-TESTES.md#a06). |
| Pendências técnicas | [T02 — modelo](DECISOES.md#t02), [T05 — acesso](DECISOES.md#t05), [T06 — liberar testadores](DECISOES.md#t06), [T07 — parâmetros](DECISOES.md#t07), [T08 — retenção](DECISOES.md#t08) e [T11 — erros/eventos](DECISOES.md#t11). |

**Entrega futura:** ambiente isolado, perfil/preferências, identidade sem login visível, armazenamento de sessão e exclusão de backup. Código público separado de credencial; erro transitório não cria identidade nova. Estabelecer migrações versionadas, grants/RLS, autorização explícita, contratos de erro/versões e contexto de pedidos/idempotência.

Incluir base de logs sanitizados, quotas e liberação dos amigos especificada em B00. Tabelas/rotinas dos próximos blocos entram com suas proteções e verificações antes de exposição; não implementar todo o domínio antecipadamente neste bloco.

**Aceite futuro:** identidade persiste no reinício; reinstalação não recupera identidade; dados pessoais isolados; sem sessão não há acesso de produto; retry não duplica efeito. Referências S01, S05, S07, C04–C05, A06 e O01, nas partes aplicáveis. Nenhum segredo privilegiado no repositório/APK.

<a id="b03"></a>

## B03 — Salas, presença e administração

**Guia de consulta do bloco**

| Consulta | Local exato |
|---|---|
| Regras confirmadas | [P01 — prazo](DECISOES.md#p01), [P04 — background pausado](DECISOES.md#p04), [P05 — contagem/capacidade](DECISOES.md#p05), [P06 — ex-admin](DECISOES.md#p06), [P13 — saída](DECISOES.md#p13) e [administração/ciclo de vida](PLANEJAMENTO.md#produto-administracao). |
| Especificação técnica | [Sala/participação/conexão](BANCO.md#dados-sala), [entrada](CONTRATOS.md#sec-05), [reconexão](CONTRATOS.md#sec-06), [administração/saída](CONTRATOS.md#sec-09), [detecção/prazo](ALGORITMOS.md#sec-02), [sucessão](ALGORITMOS.md#sec-04) e [worker](ALGORITMOS.md#sec-05). |
| Visual | [Home](DESIGN.md#design-home), [Criar](DESIGN.md#design-criar), [Entrar](DESIGN.md#design-entrar), [menu/confirmações](DESIGN.md#design-estados-sala) e [erros/reconexão](DESIGN.md#design-erros-vazios). |
| Verificação futura | [C01 — última vaga](SEGURANCA-TESTES.md#c01), [C02 — uma sala](SEGURANCA-TESTES.md#c02), [F04 — deadline](SEGURANCA-TESTES.md#f04), [F05 — admin ausente](SEGURANCA-TESTES.md#f05), [F12 — contagem](SEGURANCA-TESTES.md#f12), [F13 — ex-admin](SEGURANCA-TESTES.md#f13) e [F20 — saída/Parar](SEGURANCA-TESTES.md#f20). |
| Pendências técnicas | [T01 — leases/sucessão](DECISOES.md#t01), [T02 — modelo](DECISOES.md#t02), [T05 — acesso](DECISOES.md#t05), [T07 — parâmetros](DECISOES.md#t07) e [T11 — eventos](DECISOES.md#t11). |

**Entrega futura:** criação/entrada por código/catálogo, Home com até três salas reais, busca/listagem, snapshot e coordenador de participação. Implementar geração, heartbeat, detecção/reserva de 60 s, reconexão formal, worker de prazos e uma sala por identidade. Incluir permissões, transferência, saída com sucessor, expulsão/bloqueio da identidade e encerramento.

Conectados formam o número visível; reservas válidas ocupam capacidade de 10. Preservar reservas quando a administração ficar temporariamente ausente; sucessão segue algoritmo fechado em B00. Ex-admin mantém somente autorização individual prévia. Suspensão em background pausado/sem vídeo segue reconexão normal.

**Aceite futuro:** concorrência na última vaga e em duas salas; expiração/reconexão na fronteira; geração antiga rejeitada; expulso sem acesso; encerrada não reabre. Referências S02–S05, C01–C03, F01–F06, F09, A05 e O03. A parte de chat desses cenários será completada em B06.

<a id="b04"></a>

## B04 — Player local e validação de mídia

**Guia de consulta do bloco**

| Consulta | Local exato |
|---|---|
| Regras confirmadas | [P03 — duração inconclusiva](DECISOES.md#p03), [P13 — Parar local](DECISOES.md#p13), [P14 — HTTP/HTTPS](DECISOES.md#p14) e [mídias da primeira versão](PLANEJAMENTO.md#produto-escopo). |
| Especificação técnica | [Player/lifecycle](ANDROID-INFRA.md#sec-03), [controles externos](ANDROID-INFRA.md#sec-04), [validador](ANDROID-INFRA.md#sec-08), [contratos de mídia](CONTRATOS.md#sec-07), [término](ALGORITMOS.md#sec-08) e [segurança de mídia](SEGURANCA-TESTES.md#sec-05). |
| Visual | [Player vertical](DESIGN.md#design-player-vertical), [horizontal](DESIGN.md#design-player-horizontal) e [Adicionar vídeo](DESIGN.md#design-paineis-sala). |
| Verificação futura | [V01 — MP4/HLS](SEGURANCA-TESTES.md#v01), [S08 — SSRF/recursos](SEGURANCA-TESTES.md#s08), [A01 — rotação](SEGURANCA-TESTES.md#a01), [A03 — background](SEGURANCA-TESTES.md#a03) e [F21 — HTTP/HTTPS](SEGURANCA-TESTES.md#f21). |
| Pendências técnicas | [T03 — avaliação/ticket/avanço](DECISOES.md#t03), [T04 — executor](DECISOES.md#t04), [T05 — segurança](DECISOES.md#t05), [T07 — orçamentos](DECISOES.md#t07) e [T09 — lifecycle](DECISOES.md#t09). |

**Entrega futura:** player único/serviço, superfície reanexável na rotação, foco de áudio, MP4/HLS gravados e falhas locais. Preparar controles para o caso de uso autorizado de B05, sem habilitar controle compartilhado sem validação de servidor.

Integrar validador no executor escolhido, fora de transação: formato/VOD, ticket, origem/validade da duração e resultado inconclusivo. Proteção contra SSRF, limites de rede/recursos e isolamento acompanham a primeira integração. Fonte reproduzível inconclusiva continua permitida com avanço manual por autorizado (P03); não equivale a fonte inválida. Indicação/ação manual usa os controles existentes.

**Aceite futuro:** fixtures MP4/HLS, fonte expirada/alterada, ticket forjado/vencido e URL adversarial; rotação sem novo player, áudio durante reprodução em background (S08, V01, A01, A03–A04). Sincronização em background é concluída em B05. Reprodução local ainda não comprova assistir junto.

<a id="b05"></a>

## B05 — Sincronização e fila

**Guia de consulta do bloco**

| Consulta | Local exato |
|---|---|
| Regras confirmadas | [P02 — Play inicial](DECISOES.md#p02), [P03 — avanço manual](DECISOES.md#p03), [P09 — URL repetida](DECISOES.md#p09), [P13 — saltos de 10 s](DECISOES.md#p13), [P15 — fila 50](DECISOES.md#p15) e [replay/entrada sincronizada](PLANEJAMENTO.md#produto-sincronizacao). |
| Especificação técnica | [API de player/fila](CONTRATOS.md#sec-07), [estado do player](ALGORITMOS.md#sec-06), [relógio/drift](ALGORITMOS.md#sec-07), [fim](ALGORITMOS.md#sec-08), [fila/concorrência](ALGORITMOS.md#sec-09), [dados](BANCO.md#dados-reproducao-chat) e [parâmetros candidatos](PARAMETROS.md#parametros-sincronizacao). |
| Visual | [Fila/Adicionar vídeo](DESIGN.md#design-paineis-sala), [sala sem vídeo/fim da fila](DESIGN.md#design-estados-sala) e [player horizontal](DESIGN.md#design-player-horizontal). |
| Verificação futura | [C06 — avanço único](SEGURANCA-TESTES.md#c06), [C07 — timer/seek](SEGURANCA-TESTES.md#c07), [C08 — fila concorrente](SEGURANCA-TESTES.md#c08), [F07 — replay](SEGURANCA-TESTES.md#f07), [F10 — Play inicial](SEGURANCA-TESTES.md#f10), [F11 — inconclusiva](SEGURANCA-TESTES.md#f11) e [F16 — URL/retry](SEGURANCA-TESTES.md#f16). |
| Pendências técnicas | [T03 — API de mídia](DECISOES.md#t03), [T07 — drift/retry](DECISOES.md#t07), [T09 — coordenador](DECISOES.md#t09), [T10 — medição](DECISOES.md#t10) e [T11 — eventos](DECISOES.md#t11). |

**Entrega futura:** estado autoritativo com revisão/epoch, relógio estimado, play/pause/seek autorizados, entrada na posição atual e recuperação de drift. Controles de tela/Bluetooth/notificação seguem a mesma autorização. Falha, buffering ou foco locais não pausam os demais.

Adicionar, Reproduzir agora, remover/reordenar e promover fila são transacionais. Adicionar não inicia sozinho; Play inicial promove o primeiro item. Duração confiável permite avanço automático único; inconclusiva exige avanço manual autorizado. Fim sem próximo preserva última mídia; Play reinicia esse vídeo com nova epoch. Término antigo não afeta replay.

**Aceite futuro:** dois aparelhos em redes distintas; comandos simultâneos; perda/duplicação de eventos; reconexão; timer disputando pause/seek; avanço repetido e fila concorrente (S03, C03–C08, F07, A04, O01–O03 e novos casos P02/P03). Medir drift/recuperação no protocolo definido, incluindo exclusões. 500 ms/95% continua alvo proposto até revisão, sem resultado obtido.

<a id="b06"></a>

## B06 — Chat e horizontal

**Guia de consulta do bloco**

| Consulta | Local exato |
|---|---|
| Regras confirmadas | [P08 — apelido do envio](DECISOES.md#p08), [P11 — memória](DECISOES.md#p11), [P12 — reticências/rotação](DECISOES.md#p12), [P15 — mensagem/animações](DECISOES.md#p15) e [chat/moderação](PLANEJAMENTO.md#produto-chat). |
| Especificação técnica | [API de chat](CONTRATOS.md#sec-08), [reconexão/janelas](ALGORITMOS.md#sec-03), [ordem/animações](ALGORITMOS.md#sec-10), [dados/janelas](BANCO.md#dados-sala), [mensagens](BANCO.md#dados-reproducao-chat), [cache](ANDROID-INFRA.md#sec-05) e [limites](PARAMETROS.md#parametros-limites). |
| Visual | [Chat horizontal aberto](DESIGN.md#design-social-chat), [ajustes de mensagem](DESIGN.md#design-configuracoes) e [horizontal](DESIGN.md#design-player-horizontal). |
| Verificação futura | [F02 — intervalo inacessível](SEGURANCA-TESTES.md#f02), [F03 — cache](SEGURANCA-TESTES.md#f03), [F08 — excesso](SEGURANCA-TESTES.md#f08), [F15 — apelido](SEGURANCA-TESTES.md#f15), [F18 — morte do processo](SEGURANCA-TESTES.md#f18), [F19 — rotação](SEGURANCA-TESTES.md#f19) e [F22 — limites](SEGURANCA-TESTES.md#f22). |
| Pendências técnicas | [T02 — modelo/janelas](DECISOES.md#t02), [T05 — acesso](DECISOES.md#t05), [T07 — antispam](DECISOES.md#t07), [T09 — estado local](DECISOES.md#t09) e [T11 — eventos](DECISOES.md#t11). |

**Entrega futura:** sequência de servidor, envio/paginação por janela vigente, deduplicação, antispam e cache já visto. Reconexão abre janela nova sem recuperar intervalo desconectado por qualquer caminho. P11: somente memória, perdido após morte do processo; sem recuperar janelas antigas.

Integrar chat vertical, painel horizontal/teclado e sobreposição esquerda→direita, inicialmente embaixo, uma mensagem por vez. Pular animações antigas excedentes preserva mensagens no chat autorizado. Preferências de posição/tamanho/velocidade usam salvamento explícito; P12 define reticências só na animação e repetição da interrompida ao girar, antes das próximas em ordem; chat mantém texto inteiro. P15 fixa até 5 pendentes e pular espera maior que 20 s, preservando a animação em curso repetida na rotação. Não inventar tamanho em sp a partir da referência estática.

**Aceite futuro:** API/eventos/cursores/recibos não revelam intervalo proibido; cache permanece na queda do mesmo processo; ordem e descarte corretos; rotação sem nova sessão; teclado e fonte ampliada utilizáveis (S04–S05, F02–F03, F08–F09, A01–A02, U01). Saída/expulsão/encerramento limpam cache quando conhecidos pelo app.

<a id="b07"></a>

## B07 — Amigos e convites internos

**Guia de consulta do bloco**

| Consulta | Local exato |
|---|---|
| Regras confirmadas | [P07 — amizade](DECISOES.md#p07), [validade de convites e identidade](PLANEJAMENTO.md#produto-amigos) e [P15 — limites de campos](DECISOES.md#p15). |
| Especificação técnica | [Dados sociais](BANCO.md#dados-social), [operações de amigos/convites](CONTRATOS.md#sec-10), [par/convites/outbox](ALGORITMOS.md#sec-12) e [admissão por convite](CONTRATOS.md#sec-05). |
| Visual | [Amigos/Compartilhar](DESIGN.md#design-social-chat), [Entrar em sala](DESIGN.md#design-entrar) e [estados vazios](DESIGN.md#design-erros-vazios). |
| Verificação futura | [S06 — destinatário](SEGURANCA-TESTES.md#s06), [C09 — cruzadas](SEGURANCA-TESTES.md#c09), [C10 — uso único](SEGURANCA-TESTES.md#c10) e [F14 — cancelar/remover](SEGURANCA-TESTES.md#f14). |
| Pendências técnicas | [T02 — modelo](DECISOES.md#t02), [T05 — acesso](DECISOES.md#t05), [T07 — reenvio/cotas](DECISOES.md#t07) e [T11 — eventos](DECISOES.md#t11). |

**Entrega futura:** código pessoal, solicitações recebidas/enviadas, aceite/recusa e gerenciamento conforme P07 confirmado. Reutilizar cards/confirmações; sem login/recuperação. Convites aparecem em Entrar em sala e usam admissão de B03. Gerar outbox social na transação para B08; recurso é consultável sem push.

Convite não reserva vaga, é consumido junto à admissão confirmada e vale até uso/encerramento. Sala lotada ou outra participação válida não consome convite. Remoção de amizade não deve invalidá-lo silenciosamente contra essa regra.

**Aceite futuro:** identidades distintas, solicitações cruzadas/concorrentes, aceite/convite alheio negado, lotação, uso repetido e encerramento (S06, C09–C10, F09). Convite consultável no app não comprova aviso fora dele.

<a id="b08"></a>

## B08 — Notificações fora do app

**Guia de consulta do bloco**

| Consulta | Local exato |
|---|---|
| Regras confirmadas | [P10 — padrão/privacidade](DECISOES.md#p10), [avisos com app fechado](DECISOES.md#decisoes-confirmadas) e [autosave de Notificações](PLANEJAMENTO.md#tela-06). |
| Especificação técnica | [Push Android](ANDROID-INFRA.md#sec-07), [workers/token](CONTRATOS.md#sec-11), [preferências](CONTRATOS.md#sec-04), [claim/retry](ALGORITMOS.md#sec-12), [dados internos](BANCO.md#dados-internos) e [entrega/limitações](PARAMETROS.md#parametros-notificacoes). |
| Visual | [Notificações v2](DESIGN.md#design-configuracoes), [Amigos/convites](DESIGN.md#design-social-chat). |
| Verificação futura | [N01 — aberto/fechado](SEGURANCA-TESTES.md#n01), [N02 — negada/token](SEGURANCA-TESTES.md#n02), [N03 — aviso atrasado](SEGURANCA-TESTES.md#n03), [O04 — worker interrompido](SEGURANCA-TESTES.md#o04) e [F17 — defaults/privacidade](SEGURANCA-TESTES.md#f17). |
| Pendências técnicas | [T04 — provedor](DECISOES.md#t04), [T05 — propriedade de token](DECISOES.md#t05), [T07 — retry/cotas](DECISOES.md#t07), [T08 — retenção](DECISOES.md#t08), [T09 — integração Android](DECISOES.md#t09) e [compatibilidade dos aparelhos](DECISOES.md#informacoes-operacionais). |

**Entrega futura:** provedor escolhido em B00, propriedade/rotação/revogação de token, worker de outbox com claim/retry e deduplicação. Preferências com autosave, permissão Android e privacidade da tela bloqueada seguem P10 confirmado: ambos ligados inicialmente, texto discreto sem nomes. Não redefinir escolha já salva.

Push abre consulta autenticada do recurso atual, sem entrada automática. Permissão negada ou push indisponível não remove convite. Separar canais de reprodução/social; falha de salvamento não mostra confirmação falsa.

**Aceite futuro:** app aberto/fechado, permissão negada, token rotacionado/reassociação indevida, worker interrompido e aviso duplicado/atrasado (N01–N03, S07, O04). Registrar limitações de force-stop/sistema, sem prometer entrega garantida.

<a id="b09"></a>

## B09 — Integração, operação e APK

**Guia de consulta do bloco**

| Consulta | Local exato |
|---|---|
| Regras confirmadas | [Escopo completo](PLANEJAMENTO.md#produto-escopo), [P01–P03](DECISOES.md#decisoes-p01-p03), [P04–P15](DECISOES.md#decisoes-p04-p15) e [teste fechado/APK](DECISOES.md#decisoes-confirmadas). |
| Especificação técnica | [Ambientes/assinatura/atualização](ANDROID-INFRA.md#sec-09), [retenção/exclusão](BANCO.md#sec-07), [capacidade proposta](PARAMETROS.md#parametros-capacidade), [restauração/desempenho](SEGURANCA-TESTES.md#sec-09) e [condições de entrega](SEGURANCA-TESTES.md#sec-10). |
| Visual | [Checklist de validação](DESIGN.md#design-checklist); usar as referências indicadas em B01/B03–B08. |
| Verificação futura | [Matriz de segurança/concorrência](SEGURANCA-TESTES.md#sec-07), [matriz funcional/Android](SEGURANCA-TESTES.md#sec-08), [O05 — restore](SEGURANCA-TESTES.md#o05), [O06 — compatibilidade](SEGURANCA-TESTES.md#o06), [O07 — custo](SEGURANCA-TESTES.md#o07) e [A06 — APK](SEGURANCA-TESTES.md#a06). |
| Pendências técnicas | [T04 — serviços/custo](DECISOES.md#t04), [T06 — liberação dos amigos](DECISOES.md#t06), [T08 — restore](DECISOES.md#t08), [T10 — evidências](DECISOES.md#t10) e [responsáveis/orçamento/distribuição](DECISOES.md#informacoes-operacionais). |

**Entrega futura:** fluxos completos, acessibilidade, métricas/limites/custos, proteção do teste fechado, retenção/restauração e compatibilidade de contrato/APK. Preparar assinatura com guarda externa, instalação limpa, atualização e instruções de distribuição ao grupo definido.

**Aceite futuro:** matriz pertinente executada com revisão de código/schema/configuração, ambiente, aparelhos/rede e evidências; nenhuma falha crítica ou bloqueio do escopo de autorização, integridade, capacidade, chat ou encerramento. Cobrir O05–O07, A06, U01 e jornadas entre blocos; repetir casos anteriores quando a integração afetar suas garantias. Restauração não ressuscita salas/acessos encerrados. Chave de assinatura fora do repositório.

APK só será descrito como testado com evidência registrada. Distribuição requer autorização posterior do usuário; preparar pacote não é publicar. Marco destinado ao teste fechado entre amigos, sem declarar produção pública.

## Como acompanhar a execução futura

Trabalhar em pequenas entregas completas: revisar contrato/dependências → implementar um fluxo com UI/operação/dados → verificar permissões, falhas e concorrência pertinentes → registrar evidência → revisar resultado. Evitar todas as telas prontas com rede adiada para o fim.

| Campo por bloco | Registro |
|---|---|
| Estado | Planejado, liberado para implementação, em implementação, em validação, concluído ou bloqueado com motivo |
| Entrada | Dependências, decisões aplicáveis e autorização de execução |
| Escopo | Fluxos incluídos e pendências que afetam a entrega |
| Evidência | Revisão/ambiente/casos/resultados; simulação identificada |
| Saída | Critérios atendidos, limitações e próximo bloco elegível |

Usar BLOCOS para sequência, DECISOES para escolhas e SEGURANCA-TESTES para casos/evidências futuras; atualizar DESIGN e CONTINUIDADE a cada avanço. Não criar um controle separado por tela nem copiar decisões para vários lugares. Repetir verificações apenas quando mudanças/falhas/riscos justificarem.

Não há estimativa de prazo sem fechar ambiente, aparelhos e operação. Próximo marco documental: B00 concluído e revisado. Marcos funcionais futuros: identidade + sala com acesso/reconexão; depois reprodução compartilhada em dois aparelhos; por fim versão completa de teste fechado. Nenhum marco funcional foi atingido nesta revisão.
