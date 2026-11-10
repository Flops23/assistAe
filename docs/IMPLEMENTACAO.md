# Implementação — assistAe

## Estado atual — 09/11/2026
Implementação autorizada pelo usuário, começando pelo Supabase. Projeto existente assistae
(siizxjtyaphwjfdjsgom, us-east-1), PostgreSQL 17. Sem projeto adicional contratado.
16 migrações aplicadas, 23 tabelas privadas e 30 RPCs. Código na branch codex/supabase-base.
Isso é backend parcial: aplicativo Android, player/mídia, envio push e Realtime ainda pendentes; amizade/convites já têm backend.

Usuário confirmou Galaxy A54 como primeiro aparelho, com Play Store. Distribuição por APK direto,
sem publicação na Play Store. Demais aparelhos são Android; versões exatas ainda não informadas.
Design aprovado e P01–P15 preservados. Nenhuma imagem criada, alterada ou enviada.

## Implementado e verificado
- Identidade/preferências: bootstrap convergente, perfil próprio, contexto, apelido e preferências com revisão/recibo/quota.
- Segurança: assistae_identity_api, assistae_room_api e assistae_social_api sem login, BYPASSRLS, superuser ou DDL permanente.
  Tabelas continuam owned por postgres e RLS limita o papel de identidade ao próprio ator.
  Papel de salas tem acesso interno aos dados do domínio; gates explícitos nas RPCs protegem os usuários.
- Ponte privada session_actor, única função estreita owned por postgres, somente retorna auth.uid().
  Execução negada aos papéis externos. Schema auth é gerido pelo Supabase, sem GRANT OPTION para postgres.
- Salas: criar, entrar por código/pública/convite, código autorizado, snapshot, presença/heartbeat,
  participação própria, reconexão com nova geração/janela, saída e encerramento.
- Capacidade: até 10 incluindo reservas; uma sala por identidade; catálogo e snapshot contam apenas conectados.
- Administração: permitir controle, transferir preservando permissão individual anterior e expulsar/bloquear retorno.
- Chat: sequência no servidor, apelido do envio, recibo mínimo e client_message_id vinculado ao corpo.
  Leitura somente da janela atual; cursores não recuperam entrada anterior ou intervalo desconectado.
- Catálogo: público/ativo, busca parcial sem diferença de maiúsculas, ordenação por conectados/recência/id,
  cursor por tupla e limite máximo 50 (Home pede 3); sem código, URL ou lista de pessoas.
- Prazo: detecção por silêncio D=25 s; reserva 60 s após detecção. Nova geração não reutiliza janela antiga.
- Worker privado em lotes de 100, executado pelo pg_cron a cada 5 s; limpeza diária de histórico dos próprios jobs após 7 dias.
  Não há gravação de corpo, URL de mídia ou credencial em jobs/recibos.

## Evidências das suítes
17 scripts de tests/*.sql executados integralmente contra o PostgreSQL remoto, com fixtures e rollback.
As chamadas de app usam authenticated/anon; administrador somente prepara/verifica fixtures.
Nenhum mock. Última execução completa: todas as 17 suítes passaram.

| Suite | Evidência |
|---|---|
| 001_identity | Convergência, padrões, isolamento, CAS, retry/mismatch, contexto e beta revogado, anon negado |
| 002_schema | RLS/grants, uma sala por identidade, FKs entre salas, player e lease inválidos rejeitados |
| 003_media_validation | RED validade nula admitida; GREEN após constraint |
| 004_rejected_attempts | RED quota revertida; GREEN 31ª tentativa conflitante limitada, sem alteração de perfil |
| 005_post_lock_context | Contexto revalidado após lock; não demonstra contenção entre sessões |
| 006_limited_identity_role | Owner limitado, sem membership de authenticated, isolamento RLS e escrita em beta/auth/DDL negada |
| 007_rooms | Criação/entrada, geração/janela, heartbeat duplicado, grace negado, ausência temporária de admin e sucessão/fechamento |
| 008_deadline_worker | Worker encerra participação vencida, detecta em suspect_at e fecha sala sem renovar prazo |
| 009_capacity_privacy | Décima vaga, reserva conta capacidade, expiração libera vaga, convite consumido só no sucesso, sala privada/ban e chat removido no fechamento |
| 010_public_catalog | Privacidade, ordem, busca, limite, cursor e reservas excluídas do número visível |
| 011_chat | Limites de janela/entrada/queda, geração antiga, snapshot de apelido e deduplicação de mensagem |
| 012_participants | Só admin altera permissão, transferência conserva can_control prévio, expulsão terminal e retorno negado |
| 013_window_generation | RED comparação sombreada permitia janela inconsistente; GREEN envio/leitura falham fechados |
| 014_participant_profile_lock_order | Perfis dos envolvidos bloqueáveis antes da sala; mutação do perfil negada pelo CHECK false |
| 015_social | Aceite explícito/cruzadas, cancelamento, remoção bilateral, convites preservados e consumidos por destinatário |
| 016_operation_status | applied/unknown/expired próprios, recibo mínimo após expiração e nenhum efeito no domínio |
| 017_social_notifications_permissions | Deduplicação, preferência desligada não apaga recurso do app, outbox suprimida e helper/DDL negados |

Correções de revisão: quota não é revertida por rejeição de negócio; contexto conferido após locks;
revisão de sala finaliza uma vez por comando; getMyParticipation serializa pelo perfil e filtra sala;
geração de janela qualificada explicitamente. Alteração de owner exigiu grants administrativos no novo owner.

Teste real do cron: fixture PRIVADA, com reserva vencida e uma mensagem, confirmada no banco.
Sem chamar o worker manualmente, execução agendada mudou active→closed, terminou participação por
lease_expired, invalidou código e apagou mensagem. Histórico cron marcou succeeded.
Fixture removida depois; verificação final sem salas, perfis ou usuários de teste persistentes.
A limpeza diária de histórico está agendada; sua execução ainda não foi observada.

## Amizades, convites e resultado de comandos
O papel social não tem login/BYPASSRLS/DDL. Perfis são lidos somente nas colunas necessárias;
preferências somente nos flags de notificação. RLS restringe pares/solicitações/amizades aos envolvidos.
Recibos/contextos/buckets/beta continuam próprios. Convites/outbox têm acesso interno controlado por operações;
nenhuma listagem genérica fica disponível ao aplicativo.

Solicitação por código exato, aceite/recusa pelo destinatário, cancelamento pelo remetente e remoção bilateral.
Solicitação cruzada retorna received_request e nunca cria amizade automaticamente.
Convite exige LIVE, amizade aceita e destinatário não banido; duplicata pendente reutiliza recurso/outbox.
Remover amizade não invalida convite emitido; lista/uso respeitam destinatário, vaga e sala.
Novo convite após uso exige nova intenção, sujeito à quota técnica; nenhuma validade artificial foi adicionada.
Listagens paginam e projetam somente nomes/identificadores/estados necessários, sem código/URL da sala.

Outbox é armazenamento, sem dispatcher, token ou envio push. Preferência desligada cria evento suppressed,
sem apagar solicitação/convite do app. Resolver solicitação suprime claim antigo. Convite consumido pode
ainda ter evento pending: antes de enviar, futuro dispatcher deverá revalidar uso/encerramento/ban/preferência,
ou o consumo deverá suprimir atomicamente. Não exigir amizade atual para convite já emitido (P07).

get_operation_status confirma resultado mínimo do próprio comando. unknown não prova ausência de commit
e não autoriza trocar request_id. Recibo confirmado permanece consultável após contexto vencer;
sem recibo/contexto válido, expired. Nenhum conteúdo de chat/perfil/código é restaurado.

A ordem de lock de expulsão foi corrigida para perfis UUID→sala, antes da FK de room_bans.
Isso evita inversão com perfis→par→sala dos convites. Teste 014 valida permissões/negação de escrita;
disputa entre duas sessões ainda não demonstrada. Quotas sociais: solicitação 10/min, demais mutadores 30/min,
leituras e consulta de resultado 60/min; hipóteses de engenharia.

## Escolhas técnicas e limites
D=25 s, heartbeat cliente candidato H=10 s, cron=5 s; hipóteses de engenharia, sem medição de carga/Android.
Contexto 15 min; recibos até expiração +24 h, sem GC de contexto/recibo ainda.
Contagem por code points; trim de espaço ASCII para nomes; corpo do chat inteiro, até 500.
Código pessoal/sala aleatório com 12 hexadecimais. Códigos não são credenciais.
Quotas por ator/operação; envio de chat burst 10/refill em 10 s; leitura 120/min.
Sobreposição ainda usa chaves semânticas; sp/velocidade Android não definidos.
Rejeições de negócio retornam JSON com code; cliente precisa inspecionar o JSON mesmo com HTTP 200.
Auth anônimo real remoto/configuração/API HTTP e bootstrap dos testadores ainda precisam de integração.
A allowlist é administrativa por UUID; nenhum testador real cadastrado.
Sessões e credenciais do APK ainda não existem; não há chave privilegiada nem assinatura no repositório.

## Revisões menores adiadas
- Setters de identidade ainda incrementam revisão quando o valor é idêntico: conflitos extras possíveis, sem sobrescrita silenciosa.
- Papel de identidade tem UPDATE de tabela em profiles/preferences; estreitar às colunas mutáveis melhora defesa, sem caminho atual de acesso arbitrário do app.
- Ampliar testes de before_seq, mesmo client_message_id com novo request/corpo igual e transferência para alvo grace/outra sala.
Esses pontos não foram descritos como corrigidos.

## Advisors
Última consulta: 30 WARN para RPCs SECURITY DEFINER executáveis por authenticated, intencionais,
sob papéis limitados e gates. Sem aviso de RLS sem policy nessa consulta; 7 índices sem uso observado.
O aviso anterior de senha vazada não apareceu nessa consulta; nenhuma configuração Auth foi alterada por este trabalho.
Isso não comprova segurança integral ou elimina a necessidade de REST/concorrência real.
Links/procedimentos em supabase/README.md.

## Situação e próximo trabalho
B00 permanece com operação/contratos finais a fechar. B01 tem backend de identidade; Android não criado.
B02 tem operações de sala/leases e worker verificadas funcionalmente, sem prova concorrente entre conexões reais.
B03 tem catálogo backend; B05 tem chat API, sem UI/Realtime/overlay.
B04 (validação/reprodução/fila), B08/push e B09/APK ainda sem entrega funcional completa. B06/social agora tem amizade/convite backend, sem UI/push.
Administração backend implementada; painéis Android ainda não.

Próximo: mídia/fila/validador, dispatcher de notificações, transporte Realtime e integração Android/Media3.
Preservar Home/cards aprovados. Não publicar APK ou imagem por consequência de autorização de implementação.
Não fechar planejamento por omissão nem declarar banco/app inteiros concluídos.

## Ainda não validado
Instalação limpa CLI/Docker; Auth/REST real; corridas entre duas sessões;
carga/latência/consumo do cron; Realtime/revogação de canais; mídia/SSRF e fonte mutável;
push/tokens; retenção/backups/restauração; Android/rotação/background; build/assinatura/APK.
