# Mídia e fila — plano de implementação

10/11/2026. Pedido: “faça o 1” — implementar vídeos e fila no backend.
Spec: CONTRATOS §7, BANCO, ALGORITMOS §6/8/9, DECISOES P01–P15.

## Arquitetura
PostgreSQL decide CONTROL/LIVE, revisões, fila e timeline. Edge Function analisa MP4/HLS fora de transações.
Somente o worker autenticado pelo segredo de serviço do ambiente pode concluir avaliações. Cliente recebe
capacidade opaca de execução de um único job, com expiração, vinculada ao usuário/sala/participação/geração.
A capacidade não permite ler resultado ou criar avaliações e não vai para recibos/logs. API de consulta exige LIVE.
Worker conecta ao IP público resolvido e mantém Host/SNI/certificado do domínio original; valida cada redirect.
Sem login/cookies de terceiros; aceita HTTP e HTTPS, inclusive query de URLs assinadas.

## Escolhas técnicas
Edge Function no projeto existente com conexão TCP/TLS nativa do Deno.
Somente portas 80/443, máximo 3 redirects por requisição e 4 MiB totais em 15 s.
HLS precisa ENDLIST e aceita AES-128 identity. MP4 precisa de metadados, trilha com amostras e dados de mídia,
com Range limitado para metadados no fim. Fonte segura com duração desconhecida fica inconclusive/manual.
Ticket pending até10min, resultado por5min; lease30s e até3 tentativas. Erros não carregam URL assinada.
Arquivo mutável/URL expirada pode falhar depois da análise: fingerprint é proveniência, não promessa futura.

## Tarefas
- [x] Testes de IP/URL, redirects, orçamento, parsers e transporte Deno.
- [x] RPCs validate/get, claim/finalização worker e snapshot de resultado.
- [x] Fila até50, URL repetida por intenção, playNow/startQueue, remove/reorder e controles CAS/epoch.
- [x] Timer confiável e avanço manual inconclusivo, replay e testes de revisão obsoleta e encerramento.
- [x] Deploy Edge, teste fim a fim com MP4/HLS públicos e regressão SQL.
- [x] Revisão independente, advisors e atualização da continuidade e do design.

## Limites de evidência
Não inclui Android, Realtime ou push. Sem publicar APK/imagem. Não declarar teste em A54 ou disputa real
entre conexões sem execução. Duração é análise de metadados; compatibilidade de codec depende do aparelho.
