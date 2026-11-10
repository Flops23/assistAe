# Banco assistAe

Projeto remoto existente: [assistae](https://supabase.com/dashboard/project/siizxjtyaphwjfdjsgom).
PostgreSQL 17, região us-east-1. Nenhum projeto pago adicional foi criado.

## Estado
23 tabelas em private, RLS habilitado, sem USAGE/CRUD para anon/authenticated/service_role.
6 RPCs no schema public: ensure_profile, get_my_profile, get_command_context,
change_nickname, set_notification_preference e save_message_preferences.
As tabelas dos outros domínios reservam o modelo; ainda não há operações de sala/player/chat/social.
Token de dispositivo fica adiado até definir push/prova de associação.

As funções públicas usam SECURITY DEFINER, owner postgres, search_path vazio, auth.uid(),
allowlist beta e validação própria. Isso é acesso privilegiado intencional, não RLS por usuário:
o owner ultrapassa RLS. Não conceder grants genéricos ao aplicativo.
Reduzir o owner a um papel limitado e testar suas políticas antes de ampliar a superfície de API.

## Autenticação e beta
O config.toml configura o ambiente LOCAL. O Auth anônimo remoto ainda precisa ser habilitado/verificado
na configuração de autenticação do projeto antes da integração Android.
A sessão anônima fornece o JWT/UUID; depois um operador autorizado inclui esse UUID em
private.beta_testers. A função não aceita user_id do APK. A inclusão deve ocorrer por canal administrativo;
não embutir senha, service role ou chave de banco no aplicativo.

Nenhum testador real foi cadastrado nesta entrega. A allowlist é uma escolha técnica inicial para
fechar o backend enquanto o bootstrap dos amigos é integrado; não representa fluxo Android pronto.

## RPCs
Chamadas autenticadas por /rest/v1/rpc/<nome>, com parâmetros nomeados conforme assinatura SQL.
ensure_profile recebe nickname; get_my_profile e get_command_context não recebem argumentos.
Mutadores recebem command_context_id, request_id e a revisão esperada correspondente.
save_message_preferences usa p_position, size_key, speed_key.
Resultados de sucesso têm operation, server_time, outcome, data e revisions.
Bigints na resposta JSON são strings decimais; UUIDs são strings.
O cliente precisa inspecionar code no JSON mesmo quando HTTP é 200:
rejeições de negócio usam code/retryable/correlation_id e retry_after_ms quando pertinente.
Falhas de permissão/tipo/transporte do PostgreSQL/PostgREST continuam podendo usar HTTP de erro.
Não repetir intenção antiga com novo request_id automaticamente.

Um retry confirmado retorna somente result_code/resource_id/revisão; não repete apelido, código ou
estado atual. Para ler dados, chamar get_my_profile e revalidar acesso.
Pedidos rejeitados não têm recibo nesta etapa; a tentativa consome quota, mas não modifica o domínio.
O mesmo UUID confirmado com outro payload é IDEMPOTENCY_MISMATCH.

## Configurações técnicas
Contagem por char_length (code points), trim de espaços ASCII nas bordas.
Código pessoal/sala: 12 caracteres hexadecimais aleatórios (não senha).
Contexto válido por 15 min; recibo retido até fim do contexto + 24 h, sem GC automático instalado.
Bucket por identidade/operação em janela de refill de 60 s:
ensureProfile/getCommandContext 10; getMyProfile 120; mutadores 30.
Essas quotas não substituem limites globais de rede/Anti-abuso do Auth.
Sobreposição usa small/medium/large e slow/normal/fast; valores em sp/velocidade ainda não definidos.
Setters atualmente incrementam revisão mesmo para valor idêntico: refinamento menor registrado em IMPLEMENTACAO.

## Migrações e testes
Os timestamps dos arquivos coincidem com o histórico aplicado pelo plugin Supabase, em UTC
(10/11 UTC ainda corresponde à noite de 09/11 em America/Sao_Paulo).
Não reaplicar SQL manualmente no projeto já migrado.
Em ambiente local isolado com Supabase CLI e Docker: supabase start.
Não executar reset no projeto remoto para rodar testes.

Os arquivos tests/*.sql são scripts PostgreSQL com ASSERT, não pgTAP.
Executar em banco de desenvolvimento, com psql e credenciais externas, por exemplo:
```powershell
Get-ChildItem supabase/tests/*.sql | Sort-Object Name | ForEach-Object {
  psql "service=assistae-dev" -X -v ON_ERROR_STOP=1 -f $_.FullName
  if ($LASTEXITCODE -ne 0) { throw "Falha em $($_.Name)" }
}
```
Definir o serviço assistae-dev fora do repositório. Os testes exigem papel administrativo
para fixtures, mas as chamadas de app usam SET LOCAL ROLE authenticated/anon.
Todos os scripts terminam com rollback. Erro aborta a transação, também sem persistir fixture.

Cinco suítes foram executadas via plugin no banco remoto vazio, com rollback; resultados em
[IMPLEMENTACAO](../docs/IMPLEMENTACAO.md). O teste de expiração após lock verifica tempo no mesmo processo,
sem demonstrar contenção de duas sessões. Recriação limpa pela CLI/Docker ainda não foi executada neste computador.

## Avisos do Supabase
[RLS sem políticas](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy):
intencional em tabelas privadas negadas por padrão.
[Funções definer executáveis por autenticados](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable):
seis entradas de API intencionais, com verificação de ator/beta/contexto e grants restritos.
[Índices ainda sem uso](https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index):
esperado no banco sem tráfego; medir antes de remover índices de integridade/consulta.
Esses avisos não foram classificados como resolvidos nem como prova de segurança integral.
