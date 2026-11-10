# Banco inicial assistAe — plano de implementação

09/11/2026. Execução solicitada nesta conversa: começar o aplicativo pelo Supabase.
Especificação: BANCO.md, CONTRATOS.md, CONSISTENCIA.md, DECISOES.md e BLOCOS.md.
Preservar P01–P15 e o Android/design aprovado. Registros antigos de “somente planejamento” descrevem a etapa anterior.

## Entrega e arquitetura
Usar o projeto existente assistae (siizxjtyaphwjfdjsgom), inicialmente vazio. PostgreSQL 17.
Tabelas de domínio em private; RLS sem políticas de acesso direto e sem grants de CRUD ao cliente.
API pública pequena, funções com search_path vazio, ator auth.uid() e checagens próprias.
Migrações versionadas precedem implementação Android. Não publicar imagens/APK.

## Etapas
- [x] Escrever testes SQL de comportamento e executar contra o banco vazio para registrar RED.
- [x] Criar esquema relacional previsto, constraints/FKs/índices e grants restritos.
- [x] Implementar bootstrap convergente, perfil, contexto, apelido e preferências com revisão/idempotência.
- [x] Executar testes com rollback e papéis anon/authenticated; consultar advisors.
- [x] Registrar evidências e limitações em README, DESIGN e CONTINUIDADE.
- [ ] Implementar operações de sala/chat/reconexão, reprodução, social e workers em migrações posteriores, com testes próprios.
- [ ] Integrar Android/Compose/Media3, validar em aparelhos e gerar APK.

## Escolhas técnicas desta entrega
Contagem de caracteres: code points do PostgreSQL char_length, após trim de espaço ASCII nas bordas; não contar bytes nem grafemas.
Códigos pessoais: 12 caracteres hexadecimais aleatórios, não credenciais.
Contexto: 15 minutos; recibos até expiração do contexto + 24 horas; não há limpeza automática ainda.
Sobreposição: size_key=small, speed_key=normal; chaves são semânticas, não definem sp/velocidade.
Teste fechado: allowlist de UUIDs autenticados em private.beta_testers, administrada fora do APK.
Não há login visível; habilitar Auth anônimo e controlar inclusão dos testadores antes de integrar o app.
Token de push fica adiado até definir fornecedor/prova de propriedade.
RLS privado é defesa adicional; revogação de beta também é checada em cada RPC.
Schema reserva tabelas futuras, mas não libera operações de sala ou conteúdo antes de implementar gates LIVE/CONTROL/ADMIN.
Capacidade, leases e validade de tickets dependem de transações futuras; schema sozinho não prova essas garantias.

## Arquivos
supabase/migrations: DDL e API incremental; supabase/tests: SQL transacional sem efeitos persistentes.
supabase/README.md: aplicação, configuração e limitações.
docs/IMPLEMENTACAO.md: progresso e evidências, distinguindo schema, operação e validação.

## Revisão de risco
Negar leitura/mutação direta e execução sem sessão; impedir perfil alheio, repetição com payload diferente,
recibo/contexto de outro ator, revisão antiga, beta revogado e expansão de campos por RPC.
Testes desta entrega não comprovam concorrência de vagas, revogação Realtime, mídia, push nem Android.

## Progresso posterior — 09/11/2026
- [x] Papéis limitados, salas/catálogo, heartbeat/reconexão, sucessão/encerramento, cron, chat e administração; 13 suítes passaram.
- [ ] Mídia/fila, social/push/Realtime, getOperationStatus e Android/APK; evidências/limites em docs/IMPLEMENTACAO.md.
