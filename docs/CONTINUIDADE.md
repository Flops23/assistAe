# Ponto de continuidade

## Android, Realtime e notificações — 11/11/2026

O primeiro app Android liga Home, perfil, salas, chat, fila, player Media3 e amigos ao Supabase. A entrada anônima foi ativada no painel e a lista de teste continua obrigatória. Uma verificação com duas sessões reais confirmou autenticação, renovação, chat por REST, canal privado próprio e perda de acesso depois da expulsão. O APK usa assinatura de teste. A instalação, reprodução, rotação e notificações no Galaxy A54 continuam pendentes. O Firebase assistAe foi criado no plano Spark e o app Android foi registrado. O envio do dispatcher continua desativado até configurar a conta de serviço e verificar a entrega. [Estado e evidências](IMPLEMENTACAO.md)

## Mídia, fila e reprodução no Supabase — 11/11/2026

O backend tem 18 migrações, 40 RPCs autenticadas e duas RPCs de serviço para o validador. A fila e o player usam revisões e autorização da sala. Adicionar mantém o player no estado atual. O Play inicial promove o primeiro item e o fim com duração confirmada é tratado pelo agendador. Duração inconclusiva usa avanço explícito por participante autorizado. Passaram 19 suítes SQL e 18 testes do validador. O worker hospedado confirmou MP4 e HLS VOD públicos. O próximo bloco é dispatcher de notificações, Realtime e integração Android/Media3, com validação de Auth/REST, reprodução no Galaxy A54 e APK direto. [Evidências](IMPLEMENTACAO.md)

## Avanço de implementação e aparelho — 09/11/2026

Backend possui 16 migrações, 23 tabelas privadas e 30 RPCs: identidade/preferências, salas/catálogo, leases/reconexão, chat/administração, amizade/convites e status de comandos. Dezessete suítes SQL passaram. Aceite explícito nas cruzadas, remoção bilateral preservando convites emitidos, outbox sem envio push. Papéis de API limitados, sem login/BYPASSRLS/DDL permanente. Locks de perfis UUID antes de par/sala/FKs; disputa entre duas sessões ainda não demonstrada. [Estado, decisões técnicas e evidências](IMPLEMENTACAO.md). Pendentes mídia/fila, dispatcher push, Realtime e app Android/APK; Auth/REST e aparelho não validados. P01–P15/design preservados, B00/blocos completos não concluídos. Galaxy A54 com Play Store confirmado, APK direto, somente Android; versões exatas do SO não informadas. Sem imagem nova, publicação de APK ou notificações reais enviadas. Notas abaixo são históricas.

## Implementação autorizada e banco inicial — 09/11/2026

Pedido mais recente: iniciar o app pelo banco Supabase, analisando planejamento/design/decisões do repositório. Projeto assistae já existente e vazio foi aproveitado; quatro migrações aplicadas, 23 tabelas privadas e seis RPCs de identidade/preferências. Cinco suítes SQL passaram com rollback; fixtures removidas. Ver [IMPLEMENTACAO.md](IMPLEMENTACAO.md) e [guia do banco](../supabase/README.md) para escolhas, avisos de segurança e limites. App Android/APK e operações de sala/player/chat/social ainda não existem. Não declarar B00/B01/B02 concluídos nem planejamento integral aprovado. Próximo: sala/reconexão/gates/janelas com testes; reduzir privilégios do owner da API antes de ampliar superfície. P01–P15/design preservados; sem imagens novas/publicação de APK. As notas de somente planejamento abaixo são históricas.


## Ponto atual — revisão cruzada banco/contratos/estados (09/11/2026)

Usuário solicitou conferir consistência. Superpowers systematic-debugging/verification-before-completion usados na revisão documental. [CONSISTENCIA.md](CONSISTENCIA.md) registra causa, dez divergências centrais, conciliação e pendências. BANCO/CONTRATOS/ALGORITMOS agora alinham detecção/generation, gates LIVE/CONTROL/ADMIN, administração nula, avaliação assíncrona obrigatória, modo de término derivado, contextos/recibos, claims de outbox e fechamento sem FK de mídia órfã. Associados: snapshot de apelido com perfil antes da sala, chave room_id/seq, revisões por domínio e geração histórica de janelas fechadas.

API propõe getMyParticipation, getCommandContext e getMediaValidation; modelo inclui media_validations/command_contexts e campos faltantes. C11–C16 acrescentados à matriz e não executados. Refinamentos são propostas técnicas, sem aprovação integral, SQL, app, infraestrutura ou teste funcional. P01–P15 confirmados e preservados. T01/T02/T03/T11 avançaram na revisão, mas não estão encerrados; T04–T10 também permanecem conforme DECISOES. Próximo trabalho: constraints/grants/revogação, parâmetros e variantes remanescentes, executor/serviços/operação. B00 não concluído; não iniciar programação. Esta seção prevalece sobre indicações históricas abaixo.

## Ponto atual — blocos com links diretos às fontes (09/11/2026)

Usuário pediu que os blocos apontassem aos locais das decisões para acelerar o desenvolvimento, usando Superpowers. Aplicadas as orientações de using-superpowers/brainstorming para alteração documental de escopo definido e de verification-before-completion para conferir os links. Não se trata de novo planejamento funcional ou autorização de implementação.

[BLOCOS.md](BLOCOS.md) agora contém navegação da sequência para B00–B09 e um guia por bloco com decisões, seções técnicas, referências visuais quando aplicáveis, verificações futuras e pendências T01–T11. Âncoras explícitas nos IDs de decisões/trabalho técnico/casos e nas seções de banco, contratos, algoritmos, Android/infra, parâmetros, produto e design permitem abrir o trecho exato sem usar números de linha. Conteúdo das decisões permanece na fonte original; links não representam aprovação de propostas técnicas ou execução dos testes.

P01–P15 continuam confirmados, sem reapresentar. B00 e revisão técnica/operacional ainda abertos. Próximo trabalho permanece fechar consistência de modelo/estados/contratos/segurança. Nenhuma imagem, código de produto, infraestrutura, publicação ou teste funcional. Esta seção prevalece sobre indicações históricas de próximo passo abaixo.

## Ponto atual — P01–P15 confirmados (09/11/2026)

Últimas respostas explícitas: P13 adotar Voltar fechando teclado/painel, horizontal→vertical, vertical com confirmação de saída; Parar externo só local sem pausar demais/encerrar sala, com possível reconexão; saltos de 10 s por autorizado. P14 aceita HTTP e HTTPS, diferente da recomendação somente HTTPS, para fontes diretas MP4/HLS gravadas/URLs assinadas sem login/cookies de terceiros. P15 aprova limites iniciais de apelido 2–24 caracteres, sala 2–60, mensagem 500, fila 50 próximos e animações pendentes 5/20 s, preservando chat/animação corrente repetida na rotação. Não reapresentar P01–P15.

DECISOES, contratos, parâmetros, algoritmos, banco, Android/infra, roteiro e matriz alinhados às respostas; F20–F22 planejados, não executados. Conjunto catalogado de comportamentos fechado, mas T01–T11 e informações operacionais continuam abertos. Próximo trabalho: revisão documental de consistência do modelo/estados/contratos e segurança, com mecanismos técnicos identificados como propostas, depois serviços/custos/aparelhos. Não declarar B00 encerrado ou avançar para implementação. Esta seção substitui próximos passos históricos abaixo. Nenhuma imagem, código, infraestrutura, publicação ou teste funcional.

## Ponto atual — P10–P12 confirmados (09/11/2026)

Usuário respondeu: P10 ambos os avisos ligados, texto discreto sem nomes na tela bloqueada, permissão Android necessária; P11 cache de chat só em memória nesta versão, perdido após morte do processo, preservado na queda/rotação do mesmo processo; P12 reticências só na animação, texto inteiro no chat, repetir a animação interrompida ao girar. P12 é a opção de repetir, não a recomendação inicial de descartar. Repetir do início antes das próximas em ordem, sem reenviar mensagem, repetir concluídas ou restaurar geração invalidada. Nunca recuperar intervalo desconectado ou janelas antigas por causa da perda do cache.

DECISOES e documentos técnicos/roteiro alinhados; F17–F19 planejados e não executados. P01–P12 confirmados, não reapresentar. Lote P13–P15 apresentado e aguardando resposta explícita: navegação/Parar externo/saltos de 10 s, HTTP/HTTPS e limites percebidos; não assumir preseleções. T01–T11 e fechamento do planejamento continuam abertos. Nenhuma imagem, implementação, infraestrutura, publicação ou teste funcional. Esta seção prevalece sobre registros históricos abaixo.

## Ponto atual — decisões alinhadas e P07–P09 confirmados (09/11/2026)

Usuário pediu alinhar decisões e respondeu explicitamente: P07 adotar aceite explícito nas cruzadas, remetente cancela pending, remoção bilateral com confirmação por qualquer envolvido e convites emitidos preservados até uso/encerramento; P08 manter apelido do envio nas mensagens antigas; P09 permitir mesma URL em itens independentes. Registrar como confirmado, não reapresentar P01–P09.

Corrigidas pendências superadas em arquitetura, banco, contratos, algoritmos, Android/infra e parâmetros: 60 s após detecção; Play inicial promove primeiro sem auto-início ao adicionar; inconclusiva reproduzível com avanço manual autorizado; manter cache já visto; background pausado segue reconexão; só conectados na contagem; ex-admin conserva apenas permissão individual anterior. Banco agora propõe sender_nickname como snapshot no envio; contratos/algoritmos refletem P07–P09. Matriz recebeu F10–F16 e A05 alinhado, todos não executados.

B00.1 avançou na conciliação das regras, sem concluir revisão de tipos, estados, grants, transporte ou mecanismos operacionais. Restam P10–P15 e T01–T11. Lote P10–P12 apresentado e aguardando resposta explícita: padrões/privacidade das notificações, chat após morte do processo e mensagem longa/rotação; não assumir preseleção. DECISOES é o registro único. Nenhuma imagem, implementação, infraestrutura, publicação ou teste funcional. Esta seção prevalece sobre próximos passos históricos abaixo.

## Ponto atual — desenvolvimento organizado em blocos (09/11/2026)

Usuário pediu revisão completa do repositório e divisão do desenvolvimento para eficiência. Revisados inventário local, histórico recente e documentação de produto, design, banco, contratos, algoritmos, Android/infra, parâmetros, segurança/testes e decisões. Não há código Android/Gradle, migrações, backend implementado ou APK; alterações locais anteriores foram preservadas.

Criado [BLOCOS.md](BLOCOS.md), proposta B00–B09: fechamento do planejamento; base Android; identidade/segurança; salas/presença/administração; player/validador; sincronização/fila; chat/horizontal; amigos/convites; notificações; integração/operação/APK. Inclui dependências, entregas, aceite e associação aos casos existentes. README e DESENVOLVIMENTO apontam para o roteiro; DECISOES continua registro único de escolhas.

Próxima ação recomendada: B00.1, conciliação documental das decisões já confirmadas e dos campos/contratos refinados. Depois fechar P07–P15 por assunto e T01–T11, sem reapresentar P01–P06. Inconsistências históricas identificadas no roteiro não foram todas corrigidas nesta revisão; planejamento ainda não está encerrado/aprovado como conjunto. Implementação só após solicitação posterior. Nenhuma imagem, código, infraestrutura, publicação ou teste funcional nesta etapa. Esta seção substitui indicações antigas de próximo passo abaixo.

P04–P06 confirmados em 09/11/2026: suspensão pelo Android quando pausado/sem vídeo segue reconexão normal, com reserva de 60 s após detecção; número visível nos cards e sala conta somente conectados, mas reservas válidas ainda ocupam o limite de 10; ex-administrador preserva apenas sua permissão individual anterior, sem ganhar controle automaticamente ao transferir. Áudio durante reprodução em segundo plano permanece requisito. Esta atualização substitui pendências históricas desses comportamentos. Nenhuma imagem, implementação, publicação ou teste.

Ponto atual (09/11/2026): perguntas P04–P06 apresentadas, aguardando resposta: suspensão pelo Android quando pausado/sem vídeo; inclusão de reservas no número de pessoas; permissão do ex-administrador. Não assumir opções preselecionadas. P01–P03 já confirmados e não devem ser perguntados novamente. Continuar planejamento; sem código/imagens/testes.

Confirmado em 09/11/2026 (P01–P03 de DECISOES.md): reserva de 60 segundos contada após detectar a queda; Play com sala ainda sem mídia inicia o primeiro item da fila, mas adicionar sozinho não inicia; fonte reproduzível com duração inconclusiva é permitida, com avanço manual por administrador/participante autorizado ao terminar. Essa última regra é exceção explícita ao avanço automático, não permissão a usuário comum. Detecção/limites técnicos e apresentação da ação manual ainda precisam de especificação. Substitui pendências históricas desses três pontos abaixo. Somente planejamento, sem implementação/testes.

## Fechamento do planejamento — registro único (09/11/2026)

Criado [DECISOES.md](DECISOES.md), separando decisões confirmadas, escolhas abertas de produto, trabalho técnico e informações operacionais. Não reabrir decisões já confirmadas por causa de pendências históricas abaixo. Perguntas atuais P01–P03: origem dos 60 segundos, primeiro Play com fila e fonte com duração inconclusiva; respostas ainda pendentes nesta atualização. Design preservado. Nenhuma imagem, código, infraestrutura, publicação ou teste funcional. Próximo passo: incorporar respostas e fechar contratos afetados, permanecendo no planejamento.

## Avanço — segurança e testes planejados (09/11/2026)

Criado [SEGURANCA-TESTES.md](SEGURANCA-TESTES.md): fronteiras de confiança, matriz por tabela, RLS/grants/funções, revogação Realtime, credenciais, riscos do validador e casos de segurança, concorrência, Android, notificações e operação. Critérios de aceite documentados; todos os testes não executados. Parâmetros e decisões pendentes continuam explícitos, sem aprovação integral. Design preservado, sem imagens ou código. Nenhuma infraestrutura, publicação ou teste funcional. Próximo planejamento: consolidar decisões abertas e fechar bloqueadores em pequenos lotes; não iniciar implementação.

## Avanço — arquitetura Android e infraestrutura (09/11/2026)

Criado [ANDROID-INFRA.md](ANDROID-INFRA.md): camadas/pacotes, coordenador único de sala, MediaSessionService/player, foco de áudio, controles externos, cache, API Supabase, push, validador, ambientes e APK. Proposta técnica baseada em documentação oficial; nenhum projeto/serviço criado. Restrições a fechar: presença em background quando pausado/sem mídia, aparelhos-alvo, fornecedor de push, executor de metadados e fonte inconclusiva. Design preservado, sem nova arte ou aprovação visual. Nenhuma implementação, publicação ou teste funcional. Próximo planejamento: segurança/RLS e matriz de testes/aceite, além dessas decisões operacionais.

Atualização de 09/11/2026: usuário confirmou manter as mensagens já vistas antes da queda, sem recuperar o intervalo desconectado; notificações de convites/solicitações também com app fechado; uso inicial em teste fechado com amigos. Cache persistente após morte do processo e fornecedor de push não foram definidos. P15 confirmou limites de uso em [PARAMETROS.md](PARAMETROS.md); demais parâmetros de engenharia, retenção e capacidade de infraestrutura continuam propostos e não testados. Nenhuma implementação, infraestrutura, imagem ou publicação.

Decisões confirmadas pelo usuário em 08/11/2026: (1) se o administrador sair e os demais estiverem reconectando, preservar reservas e manter sala temporariamente sem administrador, atribuindo o papel quando alguém retornar; (2) Play após terminar o último vídeo recomeça esse vídeo; (3) pular animações antigas excedentes, mantendo mensagens no chat autorizado. P15 confirmou depois até 5 animações pendentes e pular espera maior que 20 s, sem apagar chat/descartar corrente repetida por rotação. Isso não permite recuperar mensagens do intervalo desconectado nem aprova integralmente os mecanismos técnicos. Nenhuma imagem, implementação, publicação ou teste. Esta atualização substitui pendências históricas desses três comportamentos abaixo.

## Avanço — estados e algoritmos (08/11/2026)

Criado [ALGORITMOS.md](ALGORITMOS.md), proposta documental de máquinas de estado e algoritmos. Inclui participação/gerações/janelas, prazo mensurável de queda, sucessão sem candidatos conectados, sincronização por referência de tempo, duração validada para término, fila transacional, contextos de validade para retry e leases da outbox. Três perguntas apresentadas sobre administração ausente, Play no fim e excesso de animações; não assumir respostas. Origem dos 60 segundos, validador de mídia e parâmetros também continuam abertos. Próxima etapa é consolidar decisões/parâmetros, infraestrutura e arquitetura Android, não código. Nenhuma implementação, imagem, publicação ou teste funcional.

## Ponto atual — contratos v1 (08/11/2026)

A pedido do usuário, criado [CONTRATOS.md](CONTRATOS.md): catálogo de operações de perfil, sala, conexão, reprodução, fila, chat, administração, amizade, convites e workers; entradas, permissões, alterações atômicas, respostas, erros, retries, versões e eventos. Ajustados no modelo documental revision de perfil e last_heartbeat_seq da conexão.

Proposta técnica, não aprovação integral. Mantidas as decisões de uma sala por pessoa, reserva de 60 segundos e apenas mensagens novas após reconexão. Nenhuma implementação, imagem, publicação ou teste funcional. Próximo planejamento: máquinas de estado e algoritmos; fechar especialmente origem do prazo de queda, sucessão sem candidatos conectados, término confiável de mídia, primeiro play com fila, validade de retries e parâmetros listados no documento. Não iniciar programação.

## Ponto atual — banco detalhado v1 (08/11/2026)

Usuário pediu seguir no planejamento, não implementar. Criado [BANCO.md](BANCO.md): campos/tipos, relações, constraints, acesso, transações, índices, retenção e cenários de teste futuro. Proposta documental; nada executado no banco.

Respostas explícitas confirmadas: reservar vaga por 60 segundos na queda; uma sala por pessoa; reconectar mostra só mensagens novas, sem recuperar intervalo desconectado. ARQUITETURA.md foi corrigido para retirar a recomendação anterior de replay. O banco separa participação, geração da conexão e janela do chat. Manter ou limpar mensagens já vistas antes da queda continua em aberto.

Próximo passo: revisar pendências do banco e detalhar contratos de métodos, sem avançar automaticamente para código. Proposta técnica ainda não aprovada como conjunto. DESIGN atualizado sem arte nova; nenhum teste funcional, provisionamento ou envio ao GitHub.

**Correção de escopo — 08/11/2026:** usuário pediu planejar integralmente banco, métodos, algoritmos, segurança, contratos, operação e testes antes do desenvolvimento. Não iniciar código, projeto Android, migrações executáveis ou provisionamento por consequência deste planejamento. O design existente continua como base e ajustes reutilizam os mesmos cards. A proposta técnica inicial está em [ARQUITETURA.md](ARQUITETURA.md). Ainda há decisões abertas; não declarar planejamento concluído ou aprovado. Implementação somente após solicitação posterior do usuário. Esta correção prevalece sobre referências anteriores a construir a base/navegação como próximo passo. Nesta revisão: somente documentação, sem imagens, publicação, implementação ou testes funcionais.

## Etapa atual — planejamento do desenvolvimento (08/11/2026)

O usuário considera o design pronto para avançar e determinou reutilizar os mesmos modelos de cards em ajustes necessários. Esta orientação substitui a exigência de novas prévias antes do desenvolvimento e a sequência antiga Fila → Adicionar vídeo → Participantes. Preservar Home, referências e regras aprovadas; nenhuma imagem gerada ou editada nesta revisão.

Configurações com Amigos, solicitações enviadas, saída com sucessor, permissões e carregamentos/feedbacks serão detalhados com os componentes existentes. Não são variantes já implementadas ou testadas. Miniatura definitiva continua adiada; teclado será validado no Android, sem nova prévia.

Próxima etapa: [Plano de desenvolvimento](DESENVOLVIMENTO.md). A sequência técnica é proposta; parâmetros abertos não se tornam decisões aprovadas. Nenhum app/backend/APK implementado ou testado. Registros anteriores abaixo são históricos quando conflitarem com esta orientação.


Atualizado em 08/11/2026.

## Aprovação mais recente — nove estados de erros e vazios

Usuário autorizou enviar as nove referências de erros/reconexão e vazios ao GitHub e perguntou se todos os designs estão completos. Aprovação registrada para os nove arquivos listados abaixo; usar Sala lotada corrigida. Sem novas imagens, implementação ou testes nesta etapa. Notificações v1 obsoleta continua somente local e fora do envio.

Resposta de continuidade: design principal e maioria dos estados aprovados, cobertura ainda não integral. Pendências: Configurações com Amigos; solicitações de amizade enviadas com itens; saída do administrador com escolha de sucessor; variantes sem permissão; carregamentos, feedbacks e validações restantes. Miniatura definitiva adiada, parâmetros e validação Android pendentes. Prévia de teclado foi dispensada pelo usuário e não deve ser recolocada como tarefa de geração. Nenhum aplicativo/backend/APK implementado/testado. Registros anteriores de propostas abaixo são históricos.

## Ponto atual — nove propostas de erros e vazios

Usuário dispensou item 1 (prévia com teclado horizontal) e pediu itens 2 e 3: erros/reconexão e estados vazios. Criadas nove propostas com imagegen integrada em `docs/design/propostas/`: `erro-codigo-proposta-v1.png`, `sala-lotada-proposta-v1.png`, `sala-encerrada-proposta-v1.png`, `video-invalido-proposta-v1.png`, `reconectando-proposta-v1.png`, `sem-salas-proposta-v1.png`, `sem-resultados-proposta-v1.png`, `sem-amigos-proposta-v1.png` e `sem-convites-proposta-v1.png`. Prompts em `prompts-erros-vazios-v1.md`. Referências aprovadas preservadas.

Estado: propostas locais aguardando avaliação, sem aprovação/autorização de envio ao GitHub, implementação ou testes. Sala lotada teve card duplicado de fundo corrigido; só resultado final selecionado. Reconexão é aviso local, não pausa compartilhada. Sem salas é variante da listagem pública, não redesenho da Home. Amigos vazios também mostra solicitações zeradas, sem definir aba Enviadas preenchida. Ver DESIGN.md para limites e conteúdo por imagem.

Não produzir prévia com teclado nesta etapa. Restam avaliar estas nove propostas, solicitações enviadas com itens, saída do administrador com sucessor, estados sem permissão, carregamentos/erros técnicos restantes e composição de Configurações com Amigos. Sem Android/backend/APK implementado/testado; validação de teclado/rede continua futura. Miniatura definitiva adiada. As seis referências do lote anterior foram aprovadas e enviadas no commit `8c06381`. Histórico abaixo não substitui este ponto atual.

## Aprovação mais recente — estados da sala, menu e confirmações

Usuário aprovou o design e autorizou enviar ao GitHub as seis referências atuais: sala sem vídeo, fim da fila, menu de três pontos, confirmar encerramento, confirmar expulsão e confirmar transferência. Caminhos listados na seção abaixo e em DESIGN.md. A transferência foi mostrada duas vezes durante a geração por correção do fundo; somente o resultado final corrigido será publicado. Seis arquivos finais distintos conferidos. Sem nova arte, implementação ou testes nesta etapa.

Próximas pendências de design: teclado do chat horizontal, erros/carregamento/reconexão, listas vazias, solicitações enviadas, estados sem permissão, saída do administrador com escolha de sucessor e composição de Configurações com Amigos. Miniatura definitiva segue adiada. As referências aprovadas não demonstram aplicativo funcionando. Registros abaixo são históricos e não anulam esta aprovação.

## Ponto atual — estados da sala, menu e confirmações em análise

Após envio dos quatro painéis de Configurações ao GitHub no commit `4a4ccf1`, usuário pediu criar os estados sugeridos. Seis propostas locais em `docs/design/propostas/`: `sala-sem-video-proposta-v1.png`, `fim-fila-proposta-v1.png`, `menu-sala-proposta-v1.png`, `confirmar-encerrar-proposta-v1.png`, `confirmar-expulsar-proposta-v1.png`, `confirmar-transferir-proposta-v1.png`. Ferramenta imagegen integrada, referência player vertical aprovado, preservado sem edição. Prompts no mesmo diretório em `prompts-estados-sala-v1.md`.

Propostas aguardam avaliação; não há aprovação ou autorização de envio dessas seis novas imagens ao GitHub, implementação ou teste Android. Sala sem vídeo orienta abrir Fila pelo menu; fim mantém último quadro e permite Abrir fila. Menu de administrador com Fila/Compartilhar/Sair/Encerrar. Três confirmações separadas, sem execução de ações reais. Transferência é manual, permanecendo na sala; não cobre saída com sucessor ou queda do administrador. Ver DESIGN.md para inventário e limitações.

Próximo passo: receber avaliação das seis. Ainda faltam teclado horizontal, erros/carregamento/reconexão, listas vazias, solicitações enviadas, estados sem permissão, saída com sucessor e composição de Configurações com Amigos. Miniatura e parâmetros técnicos continuam pendentes. Registros abaixo são históricos.

## Aprovação atual — quatro painéis de Configurações

Usuário aprovou e autorizou enviar ao GitHub as quatro referências atuais: Mudar apelido v1, Configuração de mensagem v1, Notificações v2 e Sobre o app v1, em `docs/design/propostas/`. Notificações salva automaticamente ao alterar cada interruptor; sua v1 com Salvar preferências foi substituída e fica somente local, fora do envio. Prompts e documentação acompanham as quatro imagens aprovadas. Não houve geração ou edição de imagem nesta etapa, implementação ou testes Android.

As sete telas principais e os dez painéis complementares apresentados têm referências aprovadas, com a ressalva de que a composição principal de Configurações ainda precisa incorporar Amigos. Restam estados complementares, teclado, confirmações, solicitações enviadas, parâmetros técnicos/funcionais e miniatura definitiva adiada. Não tratar esses estados como desenhados ou o aplicativo como implementado. Registros de propostas abaixo são históricos.

## Ponto atual — quatro últimas propostas de Configurações

**Correção mais recente:** em Notificações, usuário definiu salvamento automático ao mudar cada interruptor; remover botão Salvar preferências. Prévia revisada com imagegen, v1 preservada; caminho da revisão: `docs/design/propostas/notificacoes-proposta-v2.png`. Não estender essa decisão aos demais painéis sem solicitação. Sem implementação/teste ou envio dessa revisão ao GitHub. As quatro propostas seguem para análise; não houve aprovação geral nesta correção.

Compartilhar/Convidar, Chat horizontal aberto e Amigos aprovados pelo usuário e enviados ao GitHub com documentação no commit `05a0b01`, main. As três referências foram preservadas sem edição. Seis painéis complementares agora têm design aprovado: esses três e Fila, Adicionar vídeo e Participantes.

Usuário solicitou as quatro últimas prévias; geradas com imagegen integrada: `docs/design/propostas/mudar-apelido-proposta-v1.png`, `configuracao-mensagem-proposta-v1.png`, `notificacoes-proposta-v1.png` e `sobre-app-proposta-v1.png`. Prompts completos no mesmo diretório em `prompts-configuracoes-v1.md`. As quatro são propostas locais para análise; sem aprovação, envio ao GitHub, implementação ou testes Android. Documentação e quatro novas artes permanecem locais até nova autorização.

Mudar apelido: campo, inicial ilustrativa e salvar/cancelar. Mensagens: posição embaixo, tamanho/velocidade qualitativos e prévia estática ilustrativa (não redefine tamanho pequeno aprovado no player). Notificações: convites de sala/solicitações de amizade com interruptores ligados apenas como exemplo, padrões pendentes. Sobre: apresentação curta proposta, sem versão/contato inventados. Inspeção visual confirma textos/ações sem cortes aparentes; não equivale a validação Android.

Próximo passo: usuário analisar estas quatro. Ainda restam estados de erro/vazio/carregamento/reconexão, teclado, confirmações administrativas/remoção, aba de solicitações enviadas, detalhamento de parâmetros e ajustes da composição principal com botão Amigos. Miniatura das salas continua adiada. Nenhum aplicativo/backend/APK implementado/testado. Histórico abaixo não substitui este ponto atual.

## Último avanço — aprovação de três painéis e novas propostas

**Atualização posterior:** usuário aprovou Compartilhar, Chat horizontal aberto e Amigos e autorizou seu envio ao GitHub. Solicitou as quatro últimas prévias: Mudar apelido, Configuração de mensagem, Notificações e Sobre o app. A geração destas quatro está autorizada; não há autorização de envio destas novas quatro imagens. Histórico abaixo não altera a aprovação das três anteriores.

Usuário aprovou Fila, Adicionar vídeo e Participantes e autorizou envio ao GitHub. Enviados sem edição com documentação no commit `9fa1e45` (main). Nenhuma implementação/teste Android.

A pedido de “gere mais 3 telas”, foram criadas com imagegen as propostas de Compartilhar/Convidar, Chat horizontal aberto e Amigos (próximos itens da lista apresentada). Arquivos em `docs/design/propostas/`: `compartilhar-proposta-v1.png`, `chat-horizontal-proposta-v1.png`, `amigos-proposta-v1.png`. Prompts completos em `prompts-compartilhar-chat-amigos-v1.md`. Propostas locais aguardando análise; não enviadas ao GitHub e sem autorização para esse envio. Referências aprovadas preservadas.

Compartilhar: código ilustrativo e convites da lista. Chat: painel à direita, sem teclado, mensagem sobreposta embaixo. Amigos: código pessoal, adicionar, solicitações e remoção. Inspecionados visualmente, sem testes funcionais. Ver DESIGN.md para limitações: aba enviadas, teclado, confirmações e estados complementares ainda pendentes. Próximo passo é avaliação dessas três propostas. Painéis Mudar apelido, Configuração de mensagem, Notificações e Sobre o app continuam pendentes.

## Avanço atual — três painéis propostos para análise

**Atualização mais recente:** usuário aprovou Fila, Adicionar vídeo e Participantes e autorizou enviar as três imagens v1 ao GitHub. Permanecem sem implementação/testes. Pediu gerar mais três telas; sequência adotada conforme lista apresentada: Compartilhar/Convidar, Chat horizontal aberto e Amigos. A geração dessas três está autorizada; seu envio ao GitHub depende de nova autorização. Histórico de elaboração abaixo.

Usuário pediu modelos de Fila, Adicionar vídeo e Participantes. Prévias criadas com ferramenta integrada imagegen, seguindo o player vertical aprovado, preservado sem edição. Arquivos locais em `docs/design/propostas/`: `fila-proposta-v1.png`, `adicionar-video-proposta-v1.png` e `participantes-proposta-v1.png`. Fila separa vídeo atual/próximos; Adicionar vídeo mostra URL validada ilustrativa e duas ações; Participantes mostra visão administrativa com permissões, transferência, expulsão e convite.

Estado: propostas aguardando análise/aprovação do usuário; sem implementação, teste Android ou envio dessas imagens ao GitHub. URLs, nomes e validação exibidos são ilustrativos. Estados complementares e confirmações ainda pendentes. Próximo passo: receber avaliação dos três painéis, sem tratar as propostas como aprovadas. Usuário também autorizou ajustes simples de botões nas telas existentes conforme necessidade, preservando identidade/conceito.

## Última decisão — respostas à revisão de pendências

Usuário confirmou as decisões abaixo e autorizou registrá-las no planejamento e enviar ao GitHub. Esta seção e PLANEJAMENTO.md prevalecem sobre pendências antigas nos registros históricos.

1. Sala pública ligada por padrão ao criar.
2. Amigos identificados/adicionados por código único de usuário, mantendo entrada sem login.
3. Amizade exige solicitação e aceite.
4. Lista de amigos por novo botão Amigos em Configurações. São agora cinco opções funcionais; referência de quatro botões preservada e ajuste visual pendente.
5. Sem recuperação de identidade e amizades após reinstalar/trocar de aparelho na primeira versão.
6. Convites de sala válidos até serem usados ou a sala encerrar.
7. Reproduzir agora retira o vídeo interrompido da reprodução sem adicioná-lo automaticamente à fila.
8. Usuário respondeu “ambos” aos estados sem vídeo/fila vazia: combinação registrada como área sem vídeo com “Adicione um vídeo” antes da primeira mídia; último quadro com “Fila vazia” e acesso a adicionar vídeo ao terminar a fila. Chat continua disponível; composição pendente.
9. Sair e Encerrar nos três pontos; Encerrar somente para administrador, com confirmação.
10. Mensagens sobre o vídeo horizontal começam embaixo.
11. Exibir uma mensagem por vez, em ordem de chegada ao servidor; implementação técnica da ordenação pendente.
12. Notificações inicialmente para convites de sala e solicitações de amizade.
13. Imagem padrão das salas adiada; manter marcador provisório.
14. Continuar designs: Fila → Adicionar vídeo → Participantes.

Aprovado funcionalmente, sem novas imagens, implementação ou testes. Detalhes ainda abertos: remoção/gerenciamento de amizades, entrega dos convites, faixas de tamanho/velocidade, painéis e estados complementares e pendências técnicas restantes em PLANEJAMENTO.md. Não gerar imagens sem autorização específica.

## Estado atual

Projeto exclusivamente Android, Kotlin/Compose, Media3 e Supabase; distribuição por APK. Planejamento em PLANEJAMENTO.md. Não há aplicativo, backend ou APK implementado/testado.

Sete referências visuais aprovadas:

- Home: docs/design/home-aprovada.png, original preservada.
- Criar sala: docs/design/criar-sala-aprovada.png, nome e interruptor Sala pública, sem explicações longas.
- Entrar em sala: docs/design/entrar-sala-aprovada.png, código no topo e convites de amigos abaixo.
- Player vertical: docs/design/player-vertical-aprovado.png, vídeo e chat sem barra de atalhos ou botão de adicionar vídeo.
- Player horizontal: docs/design/player-horizontal-aprovado.png, com mensagem pequena sobre o vídeo; tamanho mostrado aprovado como padrão.
- Configurações: docs/design/configuracoes-aprovada.png, somente os quatro botões pedidos.
- Salas públicas: docs/design/salas-publicas-aprovada.png, busca e cards; miniaturas provisórias.

Usuário autorizou explicitamente enviar as duas últimas referências ao GitHub e pediu registrar o sistema de amizade no planejamento. Novas imagens fora dessas referências continuam exigindo autorização. Não tratar design aprovado como implementação/teste.

## Próxima etapa

Estado mais recente: usuário aprovou a tela 07 (“gostei pode mandar pro git”) e autorizou envio de salas-publicas-aprovada.png. Telas principais 01 a 07 aprovadas visualmente, sem implementação/testes. Próxima etapa prevista: painéis da sala, começando por Fila e Adicionar vídeo (acesso pelos três pontos). Também pendem participantes, convite, chat horizontal aberto, painéis das configurações, amizade e estados complementares. Miniatura padrão definitiva ainda não selecionada; aprovação do layout não transforma o marcador provisório em arte definitiva. Registros abaixo são histórico.

Atualização: Configurações aprovada enviada ao GitHub (bc47423). Modelo da tela 07 — Todas as salas públicas apresentado no chat, ainda não aprovado: busca, cinco cards de exemplo com miniatura neutra repetida, nome e quantidade. Card inteiro dá entrada direta. Imagem padrão definitiva ainda não escolhida/aprovada; placeholders são provisórios. Aguardar avaliação; sem publicação da arte da tela 07, implementação ou teste. Estados vazio/erro/carregamento e painéis continuam pendentes.

Estado mais recente: tela 06 aprovada e envio de configuracoes-aprovada.png ao GitHub autorizado. Usuário pediu seguir para tela 07 — Todas as salas públicas. Painéis internos das quatro opções continuam pendentes. Sem implementação ou testes Android. Histórico abaixo não representa o status atual de aprovação.

Último pedido: Configurações deve conter por enquanto só Mudar apelido, Configuração de mensagem, Notificações e Sobre o app, todos como botões que abrem painéis. Reprodução, avatar e demais ajustes de chat adiados. Nova prévia de quatro botões apresentada e planejamento atualizado; aguardar avaliação visual. Sem envio ao GitHub, implementação ou teste nesta etapa.

Revisão atual de Configurações: usuário pediu Mensagens sobre o vídeo como botão de lista que abre painel, igual aos demais, e explicação das opções. Nova prévia apresentada com perfil e cinco botões; sem controles expandidos. Ajustes de posição/tamanho/velocidade ficam no painel aberto por esse botão. Demais categorias ainda precisam de definição interna. Aguardar avaliação da composição; sem publicação, implementação/testes nesta etapa.

Avanço mais recente: modelo da tela 06 — Configurações apresentado a pedido do usuário. Avatar/apelido, posição/tamanho/velocidade das mensagens, prévia e acessos Reprodução/Notificações/Chat/Sobre. Aguardar revisão visual. Nenhuma nova aprovação, publicação de arte, implementação ou teste nesta etapa. Opções internas e parâmetros ainda pendentes. Preferências de mensagens ficam nesta tela conforme confirmação explícita; preservar tamanho padrão aprovado do player horizontal.

**Estado atual:** usuário aprovou o player horizontal com mensagem sobreposta, confirmou o tamanho mostrado como padrão e autorizou enviar ao GitHub. Função consolidada no planejamento: mensagens recebidas passam lentamente da esquerda para a direita e têm ajustes de posição (cima/baixo), tamanho e velocidade nas Configurações. Posição/velocidade iniciais, valores numéricos e tratamento simultâneo pendentes; tamanho é referência visual, ainda sem sp validado. Sem implementação ou teste de animação. Próxima tela principal na ordem: Configurações; painel de chat horizontal aberto e estados complementares também pendentes. Registros abaixo são histórico.

Pedido mais recente: mensagens pequenas sobre o vídeo horizontal movendo lentamente da esquerda para a direita; configurações de cima/baixo, tamanho e velocidade. Requisito registrado no planejamento. Prévia estática apresentada com “Lucas: Que cena linda!” no topo como exemplo; aguardar avaliação visual. Não representa animação testada e não define padrões/faixas. Sem implementação, testes ou envio dessa arte ao GitHub.

Vertical aprovado enviado ao GitHub com documentação no commit d48b1a9. Em seguida, modelo horizontal apresentado no chat: tela imersiva, controles temporários e botão de chat, inicialmente fechado. Aguardar aprovação/comentários; proposta horizontal ainda não aprovada nem enviada ao GitHub. Próximo detalhamento dessa tela: painel de chat aberto e teclado. Sem implementação/testes.

Pedido mais recente: enviar player-vertical-aprovado.png ao GitHub (autorização explícita) e seguir para o modelo horizontal. Layout vertical aprovado, sem botão junto ao chat. Próxima proposta: player horizontal imersivo com chat inicialmente fechado e controles temporários ao toque.

Estado atual: usuário confirmou que o player vertical já estava aprovado e pediu só remover o botão junto a Chat. Edição executada e referência local salva em docs/design/player-vertical-aprovado.png, sem publicação no GitHub. Layout aprovado com essa remoção, sem implementação/testes. Adicionar vídeo continua dentro de Fila nos três pontos; participantes pelo contador. Próxima tela principal na ordem: player horizontal, além dos estados pendentes do vertical. Os registros abaixo são histórico.

Decisão atual confirmada: remover Adicionar vídeo do chat; acesso por três pontos → Fila → Adicionar vídeo, com URL e escolha Reproduzir agora/Adicionar à fila conforme permissão. Participantes pelo contador superior. Planejamento agora explica Fila e Compartilhar nos três pontos; Sair/Encerrar nesse menu são localização proposta, ainda não aprovada. Última imagem do player ficou desatualizada por conter botão Adicionar vídeo ao lado de Chat; atualizar em próxima revisão visual autorizada. Nenhuma imagem, implementação/teste ou envio ao GitHub nesta etapa. Os parágrafos anteriores de proposta abaixo são histórico.

Última revisão do player: contador superior abre participantes; Fila/Compartilhar vão nos três pontos, conforme pedido do usuário. Nova prévia remove barra de atalhos e propõe botão compacto “Adicionar vídeo” junto ao título Chat (adição por URL). Aguardar avaliação dessa revisão; não considerar aprovada. Sem nova publicação, implementação ou testes. Estado sem mídia e demais variantes continuam pendentes.

Modelo do player vertical com chat solicitado e apresentado como proposta no chat. Mostra administrador com vídeo pausado, barra Vídeo/Fila/Pessoas/Convidar e chat com campo inferior. Aguardar avaliação do usuário; ainda não aprovado. Sem envio dessa imagem ao GitHub. Restam estado sem mídia e demais estados, proporção exata da mídia e validação Android; ver DESIGN.md. Nenhum código/teste realizado.

Design do player vertical com chat, incluindo sala ainda sem mídia, mantendo identidade preta/roxa aprovada. Perguntar em caso de dúvida em vez de inventar decisões. Sem sala de espera ou agendamento.

## Sistema de amizade

Confirmado pelo usuário: lista de amigos pelo novo botão Amigos em Configurações, identificação por código único de usuário, solicitação e aceite, mantendo convidado sem login. Sem recuperação após reinstalar ou trocar de aparelho na primeira versão. Convites internos exibidos em Entrar em sala, válidos até uso ou encerramento da sala. Lista/gerenciamento, remoção e envio/entrega de convites ainda precisam de detalhamento e design.

## Decisões consolidadas

- MP4/HLS gravados inicialmente; YouTube depois; sem lives.
- Convidado com apelido e identidade no aparelho; até 10 participantes.
- Administrador controla e concede permissões individuais, inclusive para fila.
- Criar ou entrar leva diretamente ao player e chat. Início manual; entrada acompanha estado atual; próximo vídeo automático.
- Travamento individual não pausa os demais; realinhar ao recuperar. Áudio em segundo plano.
- Transferência manual ou para conectado há mais tempo; tolerância de queda de 60 segundos.
- Último saindo voluntariamente encerra; última conexão perdida tem 60 segundos.
- Encerrar para todos exige confirmação. Mensagens somente após entrada, apagadas ao encerrar.
- Expulsão e bloqueio da identidade, com limite contra spam.
- Até três salas reais na Home, ordenadas por participantes e depois recência.
- Imagem padrão dos cards ainda sem arquivo aprovado.
- Player vertical limitado à metade da área útil para vídeo vertical, preservando proporção.
- Sala pública: ligado=pública, desligado=privada; padrão inicial ligado.

## Pendências

Consultar PLANEJAMENTO.md para pendências técnicas e funcionais completas e DESIGN.md para inventário atualizado. Estados de erro, carregamento, teclado e convites vazios das telas aprovadas ainda precisam de detalhamento/validação.

## Como retomar

Ler AGENTS.md, README.md, PLANEJAMENTO.md, DESIGN.md e este arquivo. Consultar as sete referências aprovadas. Próxima etapa prevista: painéis Fila/Adicionar vídeo. Não redesenhar as referências nem gerar novas imagens sem autorização.
