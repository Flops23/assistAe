# Implementação — assistAe

## Autorização e escopo atual — 09/11/2026
Usuário solicitou analisar o repositório completo e iniciar a implementação pelo Supabase.
Isso substitui a restrição de somente planejamento para o trabalho explicitamente autorizado nesta conversa.
P01–P15 e design Android permanecem como especificação. Não houve geração/alteração/envio de imagens.

Projeto assistae já existia e estava ACTIVE_HEALTHY, vazio e sem migrações.
Foi aproveitado siizxjtyaphwjfdjsgom, us-east-1; não foi criado outro projeto nem contratado serviço.

## Entregue
- 23 tabelas privadas: perfis/preferências, beta, salas/participação/conexão, mídia/fila/chat,
  pares sociais/solicitações/amizades/convites, contextos/recibos/buckets/outbox.
- Constraints/índices, FKs compostas entre sala/participação/ator e administrador de mesma sala.
- Bloqueio de CRUD genérico; RLS habilitado em todas as tabelas privadas.
- Bootstrap convergente de perfil e preferências, leitura própria, emissão de contexto,
  alteração de apelido, autosave de notificações e preferências de sobreposição.
- CAS por revisão, recibos idempotentes mínimos, ator da sessão, allowlist de teste fechado e quota.
- Erros de negócio em envelope JSON; quota permanece consumida quando pedido é rejeitado.
- Contexto revalidado depois do lock de perfil/preferências, antes da mutação.
- Quatro migrações aplicadas, nomes locais alinhados ao histórico UTC do Supabase.

## Evidências
PostgreSQL remoto 17; testes administrativos preparam fixtures e usam papéis reais
authenticated/anon nas chamadas de app. Sem mocks; rollback ao terminar.

| Verificação | Resultado observado |
|---|---|
| 001_identity.sql | Passou: convergência, padrões, isolamento, revisão, retry/mismatch, preferências, contexto vencido/alheio, beta revogado e anon negado |
| 002_schema.sql | Passou: RLS/grants, uma sala por identidade, FKs entre salas, player sem mídia e lease sem token rejeitados |
| 003_media_validation.sql | RED: validade nula foi admitida; GREEN após constraint explícita |
| 004_rejected_attempts.sql | RED: rejeições não consumiam quota; GREEN: 31ª tentativa conflitante recebe RATE_LIMITED, sem alterar perfil |
| 005_post_lock_context.sql | Passou: contexto vence após lock e verificação posterior o rejeita; não cobre disputa real de duas sessões |
| Limpeza final | 0 profiles, 0 beta_testers, 0 auth.users; nenhuma fixture persistente |
| Advisors | Avisos intencionais de SECURITY DEFINER/RLS sem policy e índices sem tráfego; detalhes em supabase/README.md |

As duas primeiras suítes falharam inicialmente com ausência das funções/tabelas, antes da implementação.
Tentativa de reproduzir bloqueio entre duas sessões pelo plugin não demonstrou o cenário (contexto foi
rejeitado já na entrada). Não contar como teste de contenção aprovado.
A revisão independente encontrou quota revertida, validade antes de locks e nome temporário de migração
fora de ordem; correções registradas em 20261110003512 e renomeações conforme histórico remoto.

## Escolhas do implementador
Allowlist manual por UUID; contexto 15 min e margem 24 h; quotas conforme supabase/README.md;
contagem Unicode por code points; chaves semânticas de sobreposição.
São decisões técnicas desta implementação, não novas aprovações do usuário sobre produto ou operação.
A allowlist mantém fechado o domínio, mas Auth anônimo remoto/bootstrap Android ainda precisam de integração.
Owner postgres nas seis RPCs exige reduzir privilégios e testar papel dedicado antes de ampliar a API;
os avisos do advisor permanecem documentados.

## Revisão menor adiada
Salvar exatamente o valor atual incrementa revisão e retorna applied.
Refinamento: retornar unchanged e manter recibo sem aumentar revisão. Risco: conflitos adicionais entre
telas, sem perda silenciosa de dados; CAS impede sobrescrita. Não bloqueia esta base de desenvolvimento.

## Situação dos blocos e próxima execução
B00 ainda tem operação/transporte/retencão a fechar; implementação autorizada não aprova pendências por omissão.
B01 tem somente identidade/preferências do backend; Android ainda não criado.
B02 tem modelo físico e infraestrutura de comandos; operações de salas/LIVE/CONTROL/ADMIN ainda não implementadas.
B03–B09 continuam sem entrega funcional.
Próximo trabalho: operações transacionais de sala/reconexão/snapshot/chat, preservando janelas e leases;
depois mídia/fila, social/push e integração Android/Media3 conforme BLOCOS.
Não habilitar leitura direta de chat/URL nem publicar conteúdo sensível em canais para contornar gates faltantes.

## Ainda não validado
Instalação limpa CLI/Docker; chamadas REST com Auth anônimo real; contenção de duas sessões;
capacidade de 10 vagas; leases/sucessão/worker; revogação Realtime; reprodução/validador/SSRF;
push/tokens; retenção/backups; Android/rotação/background; build/assinatura/APK.
Nenhum app/APK funcional foi entregue. Banco inicial não significa backend inteiro pronto.
