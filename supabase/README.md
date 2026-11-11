# Banco assistAe

Projeto remoto [assistae](https://supabase.com/dashboard/project/siizxjtyaphwjfdjsgom), PostgreSQL 17, us-east-1.
18 migrações, 23 tabelas privadas, 40 RPCs autenticadas e duas RPCs exclusivas de serviço. Estado e evidências em
[IMPLEMENTACAO](../docs/IMPLEMENTACAO.md). Backend parcial; ainda não há Android/APK.

## Fronteira de acesso
Schemas expostos: public. private não tem USAGE/CRUD para anon/authenticated/service_role.
Papéis sem login/bypass/DDL: assistae_identity_api (RLS do próprio usuário), assistae_social_api (domínio social) e assistae_room_api
(tabelas internas do domínio, autorizadas por gates explícitos em cada operação).
Usuários não têm membership nesses papéis. postgres pode SET ROLE para migração/teste, sem herança automática.
Ponte private.session_actor owned por postgres apenas lê auth.uid; execução externa negada.
As funções definer são intencionais: não trocar owner/grants ou expor helpers/tabelas para contornar erros.

## API
RPCs em /rest/v1/rpc/<nome>, JWT autenticado e parâmetros nomeados conforme assinatura SQL.
Bigints de resposta são strings decimais; UUIDs são strings. Erro de negócio retorna code/retryable/correlation_id;
inspecionar JSON mesmo quando HTTP 200. Erros de permissão/tipo/transporte também podem usar HTTP de erro.
Sucesso: operation/server_time/outcome/data/revisions e request_id quando aplicável.
Retry confirmado retorna mínimo, nunca corpo, URL ou código histórico.

| Grupo | RPCs |
|---|---|
| Identidade | ensure_profile, get_my_profile, get_command_context, change_nickname, get_operation_status |
| Preferências | set_notification_preference, save_message_preferences |
| Descoberta/admissão | list_public_rooms, create_room, join_room |
| Sala/presença | get_room_code, get_room_snapshot, heartbeat, reconnect_room, get_my_participation |
| Saída/admin | leave_room, close_room, set_control_permission, transfer_admin, kick_member |
| Chat | send_message, list_messages |
| Social | request_friendship, answer_friend_request, cancel_friend_request, remove_friend, list_friends, list_friend_requests, invite_friend, list_invites |
| Mídia | validate_media, get_media_validation |
| Fila | add_to_queue, reorder_queue, remove_queue_item |
| Reprodução | play_now, start_queue, set_playback, advance_after_unverified_end, report_media_ended |

Mutações recebem command_context_id/request_id; heartbeat deduplica por geração/seq e bootstrap converge.
Usar geração/janela atuais. Contexto é emitido por get_command_context; ele não concede permissão de sala.
save_message_preferences recebe p_position/size_key/speed_key.
send_message recebe p_body e client_message_id, além de sala/participação/geração/janela e envelope.
list_messages aceita after_seq OU before_seq, nunca ambos. A janela é aplicada antes do limite.
join_room recebe target com exatamente code OU public_room_id OU invite_id.
list_public_rooms usa query/cursor/limit_; limite máximo 50, Home solicita 3.
leave_room aceita successor_membership_id e expected_room_revision nulos se não houver escolha explícita.
Administração requer expected_room_revision e ADMIN LIVE. can_control anterior não é alterado pela transferência.

Snapshot retorna participantes/projeções de mídia/fila e janela; não retorna histórico.
Snapshot e chat usam APIs autorizadas. Emissão Realtime e envio push são etapas pendentes.

## Fluxo de mídia

1. Com a participação e geração atuais, chame `validate_media` com a URL e o envelope do comando.
2. Envie `validation_id` e `execution_token` por POST JSON para `/functions/v1/media-validator`. A capacidade é descartável e autoriza somente a avaliação criada. A função retorna 202 ao iniciar e mantém as credenciais de serviço no Supabase.
3. Consulte `get_media_validation`. Resultados `valid` e `inconclusive` fornecem `validation_reference`. Use a mesma URL e participação para `add_to_queue` ou `play_now` antes do vencimento de 5 min. Quando a conclusão ainda estiver pendente, a consulta indica `processing` e pode devolver a capacidade para retomar uma tentativa após o fim da concessão de 30 s. O trabalho pendente vence em 10 min e tem até três tentativas.
4. Use as revisões do snapshot. `start_queue` exige as revisões de fila e reprodução. `set_playback` aceita `play`, `pause` ou `seek`, com posição em milissegundos somente para `seek`. `advance_after_unverified_end` exige as duas revisões e a epoch atual. `report_media_ended` confirma a participação e a epoch sem mudar a reprodução.

A função verifica metadados e referências. Limites iniciais de 4 MiB, 15 s, 32 requisições e três redirecionamentos por requisição. O DNS é resolvido pelo Deno com fallback fixo da Cloudflare quando o DNS nativo fica sem resposta. O fallback recebe somente o hostname. A conexão fica presa ao IP público selecionado e mantém o hostname original para TLS. URLs assinadas, HTTP e HTTPS são aceitos. A avaliação é conservadora para MP4 fragmentado e recursos de HLS como DRM, substituição de variáveis e content steering. Reprodução e disponibilidade dos segmentos no aparelho exigem teste Media3.

O agendador `assistae_advance_playback` roda a cada 5 s, em lotes de até 100 salas, e relê a duração e o estado antes de avançar. O mesmo item permanece disponível para replay quando é o último.

## Auth e teste fechado
config.toml configura ambiente LOCAL, não a configuração Auth remota.
Auth anônimo real deve ser habilitado/verificado antes da integração Android.
Sessão anônima fornece UUID/JWT; operador autorizado inclui UUID em private.beta_testers.
App nunca recebe service role, senha administrativa ou chave de assinatura.
Nenhum testador real cadastrado nesta entrega. Bootstrap e proteção global do Auth ainda precisam de integração.
Usuário confirmou Galaxy A54 com Play Store; APK será distribuído diretamente, sem publicação na loja.

## Prazos/rotinas
Detector por silêncio D=25 s, reserva de 60 s a partir da detecção.
Heartbeat saudável renova para agora+25/+85; duplicata não renova.
Reconexão formal aceita antes do timeout após interrupção observada, sempre com geração/janela novas.
Sem sinal de transporte confiável implementado: não prometer detecção de toda queda física imperceptível.

pg_cron chama private.expire_rooms(100) a cada 5 s, como postgres; função definer executa como papel de sala limitado.
Job assistae_expire_rooms observado succeeded; teste de sala privada vencida verificou fechamento real pelo agendador.
Job assistae_cron_history mantém 7 dias de histórico SOMENTE dos jobs assistAe, diariamente às 03:19 UTC.
Sua execução diária ainda não foi observada. Não apagar histórico/jobs de outros aplicativos.
Medir fila/atraso/custo do cron no teste fechado; atraso nunca reinicia os 60 s.

## Parâmetros desta implementação
Contexto 15 min; recibo até fim do contexto +24 h, sem GC automático desses dados.
Código de 12 hexadecimais aleatórios; contagem Unicode via char_length/code points.
Quotas de identidade: bootstrap/contexto 10/min, leitura 120/min, mutadores 30/min.
Sala: criar 6/min, entrar 20/min, leituras/heartbeat 120/min, reconectar/admin/sair 30/min, catálogo 60/min.
Chat: burst 10, refill em 10 s; leitura 120/min. Não substitui defesa global de rede/Auth.
Chaves small/medium/large e slow/normal/fast não definem ainda sp/velocidade Android.

## Migrações e testes
Nomes de arquivo coincidem com versões aplicadas pelo plugin, em UTC.
10/11 UTC ainda corresponde à noite de 09/11 em America/Sao_Paulo.
CLI local não estava instalada; DDL remoto foi aplicado com o plugin e os timestamps resultantes foram preservados.
Antes de instalar/usar CLI, conferir --version e --help; [CLI v3 mudou os destinos padrão](https://supabase.com/changelog).
Não reaplicar SQL manualmente no projeto migrado nem executar reset remoto para rodar testes.
Instalação limpa CLI/Docker ainda não testada.

tests/*.sql são scripts PostgreSQL com ASSERT, não pgTAP. Todos terminam com rollback.
Executar em ambiente de desenvolvimento com psql e credenciais externas:
```powershell
Get-ChildItem supabase/tests/*.sql | Sort-Object Name | ForEach-Object {
  psql "service=assistae-dev" -X -v ON_ERROR_STOP=1 -f $_.FullName
  if ($LASTEXITCODE -ne 0) { throw "Falha em $($_.Name)" }
}
```
Definir o serviço fora do repositório. Administrador prepara fixtures; chamadas do app usam papéis reais.
19 suítes passaram no banco remoto. A disputa entre sessões e a carga do agendador seguem pendentes de teste.

Para testar o validador com Deno, execute `deno test --allow-read --allow-net=127.0.0.1 supabase/functions/media-validator/tests/`. São 18 testes, incluindo transporte real em loopback.
A integração cron usou fixture privada confirmada/removida; as suítes restantes usam rollback.

## Avisos ainda documentados
- [SECURITY DEFINER acessível a autenticados](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable): 30 APIs intencionais, com papéis limitados/gates.
- [RLS sem policy](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy): nenhuma ocorrência na última consulta; as tabelas sociais agora têm políticas restritas aos papéis internos.
- [Índice sem uso](https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index): 7 registros informativos, sem tráfego real.
- [Proteção contra senha vazada](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection): alerta anterior não reapareceu na última consulta; nenhuma configuração Auth alterada por este trabalho.
Não confundir ausência de erro nos testes com auditoria integral aprovada.

## Social e status
Solicitações cruzadas exigem aceite; remetente cancela pending; envolvidos removem amizade bilateral.
Convites já emitidos sobrevivem à remoção da amizade. Destinatário lista/usa; convite não reserva vaga.
Listas limitadas a 50: amigos usam cursor UUID; solicitações/convites usam cursor created_at/id.
ListFriendRequests aceita direction incoming/outgoing, incluindo estados resolvidos do próprio envolvido.
Request_friendship recebe user_code; answer/cancel usam friend_request_id; invite_friend usa friend_user_id e admissão LIVE.
Quotas: requestFriendship 10/min; mutadores sociais 30/min; leituras/getOperationStatus 60/min.

Outbox contém somente tipo/recurso/destinatário/event_key. Não existe dispatcher/token/envio nesta entrega.
Preferência off suprime evento sem esconder recurso no app. Evento de convite já usado ainda pode estar pending:
futuro worker deverá revalidar status/ban/preferência e suprimir antes de enviar.
Get_operation_status(request_id,command_context_id) retorna applied/unknown/expired próprio e mínimo histórico;
unknown não permite nova intenção automática. Nenhum corpo, nickname, código ou URL é retornado.
