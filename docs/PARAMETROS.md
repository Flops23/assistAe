# Parâmetros e operação inicial — proposta v1

## Avanço de implementação e aparelho — 09/11/2026

Backend possui 16 migrações, 23 tabelas privadas e 30 RPCs: identidade/preferências, salas/catálogo, leases/reconexão, chat/administração, amizade/convites e status de comandos. Dezessete suítes SQL passaram. Aceite explícito nas cruzadas, remoção bilateral preservando convites emitidos, outbox sem envio push. Papéis de API limitados, sem login/BYPASSRLS/DDL permanente. Locks de perfis UUID antes de par/sala/FKs; disputa entre duas sessões ainda não demonstrada. [Estado, decisões técnicas e evidências](IMPLEMENTACAO.md). Pendentes mídia/fila, dispatcher push, Realtime e app Android/APK; Auth/REST e aparelho não validados. P01–P15/design preservados, B00/blocos completos não concluídos. Galaxy A54 com Play Store confirmado, APK direto, somente Android; versões exatas do SO não informadas. Sem imagem nova, publicação de APK ou notificações reais enviadas. Notas abaixo são históricas.

## Decisões confirmadas nesta etapa

- Manter na tela as mensagens já vistas antes da queda. Não buscar mensagens recebidas durante a desconexão.
- Avisar sobre convites e solicitações de amizade também com o app fechado.
- Começar com teste fechado entre amigos.

Cache do chat deve pertencer à identidade/participação e ser separado da janela de leitura atual. P11 confirmou cache somente em memória, preservado na queda/rotação do mesmo processo e perdido quando o processo morre; não adicionar arquivo persistente de histórico nem reconstruir mensagens de janelas anteriores. Ao sair/encerrar/expulsar, limpar cache local quando o app tomar conhecimento. O cache não autoriza baixar o intervalo desconectado nem replay das animações antigas.

<a id="parametros-limites"></a>

## Limites de uso confirmados e candidatos técnicos

| Item | Valor e situação | Motivo e efeito |
|---|---|---|
| Apelido | 2–24 caracteres (P15 confirmado) | Nomes legíveis nos cards; contagem Unicode compartilhada entre cliente e servidor precisa especificação |
| Nome de sala | 2–60 caracteres (P15 confirmado) | Espaço para título sem transformar card em parágrafo |
| Mensagem | Até 500 caracteres (P15 confirmado); teto de 4 KiB UTF-8 ainda proposto | Permite conversa; limita payload e animações longas. Emojis/normalização precisam casos de teste |
| Fila | Até 50 próximos vídeos (P15 confirmado) | Reordenação simples e custo previsível; mídia atual não entra nessa contagem |
| URL | Até 8 KiB UTF-8 | Aceita URLs assinadas extensas sem tamanho ilimitado; validar antes de buscar |
| Página de chat | 50 mensagens, máximo 100 | Cursor sempre restrito à janela atual |
| Página de salas/amigos/convites | 20 itens, máximo 50 | Carregamento incremental; Home continua até três salas |
| Animações pendentes | Até 5, pular espera maior que 20 s (P15 confirmado) | Não apagar chat; animação em curso interrompida pela rotação repete conforme P12 e não entra no descarte de pendentes; demais mantêm ordem |

Mensagens continuam inteiras no chat autorizado. P12 confirmou reticências só na animação, sem alterar texto inteiro no chat. Repetir do início a animação interrompida ao girar, antes das próximas em ordem; não repetir concluídas. Limite visual depende da tela e ainda precisa de especificação técnica. Não escolher tamanho em sp diferente da referência aprovada sem comparação no Android.

<a id="parametros-sincronizacao"></a>

## Conexão e sincronização — candidatos, não compromissos

| Parâmetro | Proposta | O que verificar futuramente |
|---|---|---|
| Heartbeat H | 10 s, apenas enquanto houver participação | Custo, consumo e continuidade com tela bloqueada |
| Detecção por silêncio D | 25 s desde último heartbeat | Evitar expulsão por perda isolada; ainda é detecção aproximada |
| Reserva | 60 s após detecção (P01 confirmado) | Mecanismo e parâmetros da detecção continuam candidatos técnicos |
| Varredura de prazos | A cada 5 s, sem sobrepor lotes | Atraso real sob carga e indisponibilidade |
| Conferência local de drift | A cada 2 s quando ready/playing | Usa estado/relógio estimado, não grava posição a cada 2 s |
| Drift pequeno | Até 150 ms sem correção | Não perseguir ruído de rede |
| Drift intermediário | 150–800 ms, velocidade entre 0,98× e 1,02× | Correção gradual pode demorar; avaliar percepção de áudio |
| Drift grande | A partir de 800 ms, seek com cooldown de 3 s | Evitar saltos repetidos; buffering suspende correções |
| Histerese | Voltar à velocidade normal abaixo de 80 ms | Evitar oscilar no limiar de 150 ms |
| Reamostra de relógio | Admissão/reconexão e a cada 30 s | Preferir amostras de baixa latência, sem rajada ilimitada |
| Reconciliação de estado | Evento, retomada/reconexão e verificação de revisão a cada 15 s | Custo de leitura versus recuperação de eventos perdidos |
| Retry de rede | Base 500 ms, teto 10 s, jitter; respeitar retry_after | Parar por erro permanente/contexto expirado; um loop por operação |

Exemplo da regra P01 com D=25 s ainda hipotético: último heartbeat em t=0, detecção em t=25, reserva até t=85; rotina pode materializar encerramento depois, mas operações negam prazo vencido. Não comunicar isso como 60 s exatos desde queda física. A origem após detecção está confirmada; D e rotina não estão aprovados/medidos.

Supabase Cron permite tarefas recorrentes inclusive com granularidade de segundos; isso o torna candidato a reconciliar prazos, mas não garante latência nem capacidade do projeto. Jobs precisam ser curtos e monitorados. [Documentação oficial](https://supabase.com/docs/guides/cron).

## Uso indevido e repetição de comandos

Propostas para teste, ajustáveis pelo servidor:

- Chat: token bucket capacidade 5, reposição de 1 mensagem/s por identidade. Não gastar duas vezes em retry confirmado.
- Tentativas de código: 10/min por identidade, com proteção adicional do serviço contra múltiplas identidades; não tratar limite por identidade como proteção completa.
- Solicitações de amizade: 10/h por identidade; convite: 20/h; reenvio da mesma pendência não cria evento adicional.
- Criação de sala: 5 por 10 min por identidade. Uma sala por pessoa continua regra obrigatória.
- Contexto de comandos: validade de 15 min emitida pelo servidor; recibos mantidos pelo menos até expiração do contexto + 24 h. Renovar contexto para novas intenções, nunca reaplicar automaticamente pedidos antigos.

Limites sociais podem atrapalhar testes e devem gerar feedback claro; números não estão aprovados. Bloqueio por identidade não impede alguém de reinstalar e obter outra. Guardas globais, proteção da criação anônima e orçamento de carga ainda precisam de desenho operacional.

<a id="parametros-notificacoes"></a>

## Notificações com app fechado

Necessidade aprovada: convites e solicitações fora do app. Candidato técnico: Firebase Cloud Messaging, além de Supabase para dados e outbox. Não é escolha final de fornecedor e não exige login visível do usuário.

A forma de receber mensagens no Android varia com foreground/background e tipo de payload. Planejar conteúdo mínimo, identificador do evento, destino interno e consulta de estado ao abrir. Nunca colocar URL da mídia, credencial ou autorização de entrada no push. [Documentação oficial do FCM](https://firebase.google.com/docs/cloud-messaging/android/receive-messages).

Fluxo proposto: transação cria convite/solicitação e outbox → worker revalida preferência/estado → envia → registra tentativa; ao tocar, app autentica e lê recurso atual. Sem rede ou com permissão negada, convite continua no banco e aparece no app quando puder consultar. Uma notificação atrasada não reabre sala encerrada.

Fechado significa fora da tela/sem UI aberta; não prometer entrega imediata ou garantida sob force-stop, restrições do sistema, ausência de rede ou permissão negada. Compatibilidade com aparelhos sem serviços Google e disponibilidade de push precisam ser decididas. P10 confirmou ambos ligados inicialmente e texto discreto sem nomes na tela bloqueada: “Você recebeu um convite” ou “Nova solicitação de amizade”. Preferência salva e permissão Android permanecem distintas.

## Mídia e avanço automático

Planejar compatibilidade em três níveis: container/protocolo, codec e capacidades do aparelho. Extensão .mp4 ou .m3u8 sozinha não prova que o celular consegue decodificar. [Media3 — formatos suportados](https://developer.android.com/media/media3/exoplayer/supported-formats).

Caminho recomendado para avaliação: validar MP4/HLS VOD e duração fora da transação; servidor usa timeline/duração para avanço único por epoch. Candidatos de orçamento do validador: timeout total 15 s, máximo 3 redirects e teto inicial 4 MiB de metadados transferidos por análise. Fontes maiores/duração não confirmada retornam resultado inconclusivo, não alegação de vídeo inválido. URLs de metadados/segmentos também precisam de restrições de rede e tamanho.

P03 confirmou permitir fonte reproduzível inconclusiva com avanço manual por administrador/participante autorizado ao terminar, exceção ao próximo automático. Não rejeitar fonte só por duração inconclusiva, nem confiar no término declarado por cliente comum. Validador não deve baixar vídeo inteiro nem virar proxy. P14 confirmou aceitar HTTP e HTTPS, incluindo URLs assinadas diretas, sem login/cookies de terceiros. Não restringir silenciosamente a HTTPS; tráfego de API/autenticação/push mantém transporte protegido.

<a id="parametros-capacidade"></a>

## Capacidade do teste fechado

Cenários de planejamento, não capacidade medida nem limite comercial:

| Cenário | Salas × pessoas | Heartbeats por segundo com H=10 s |
|---|---|---|
| Conversa pequena | 2 × 5 = 10 pessoas | 1 |
| Grupo maior | 5 × 10 = 50 pessoas | 5 |
| Ensaio de carga futuro | 10 × 10 = 100 pessoas | 10 |

Além disso, contabilizar leituras, comandos, chat, autenticação, eventos, análise de mídia e push. Vídeo vai direto da fonte ao aparelho. Uma mensagem por segundo em cada uma de 5 salas com 10 pessoas implica 5 inserções/s e até 50 entregas/s, antes de retries/avisos/consultas. Números são aritmética do cenário, não benchmark.

Não escolher plano pago nem estimar mensalidade sem confirmar volume/duração das sessões e quotas/preços vigentes na etapa de orçamento. Separar métricas e ambiente de teste dos futuros dados de produção. Teste fechado também precisa políticas de acesso; APK distribuído a amigos não torna backend privado automaticamente.

## Retenção e critérios de aceitação a revisar

Proposta: mensagens apagadas ao encerrar conforme regra aprovada; dados mínimos de sala encerrada por 7 dias; outbox/solicitações resolvidas por 7 dias; logs técnicos sem conteúdo por 7 dias. Não apagar perfis/amizades por esse prazo. Recibos seguem contexto + margem, não prazo genérico. Backups, exclusão de identidade e restauração ainda precisam de especificação própria.

Alvos propostos para testes futuros: zero acesso entre salas/identidades; zero dupla promoção de mídia; zero leitura do intervalo desconectado; entrada respeita 10 vagas sob concorrência; drift de até 500 ms em 95% das amostras após estabilização em rede definida, excluindo buffering identificado. Não declarar atingidos. Definir aparelhos, latência/perda simuladas, duração e critérios de estabilização antes de executar.

## Próxima consolidação

P01–P15 fecham as escolhas catalogadas de comportamento; revisar números técnicos como configuração de teste; detalhar arquitetura Android (player/serviço/estado/cache/rotas), provedor de push, validador, RLS e implantação operacional. Fechar matriz de testes e custos antes de qualquer implementação. P01–P15 estão confirmados; limites de uso de P15 e salto de 10 s de P13 estão aprovados. Demais números de engenharia, fornecedores e mecanismos operacionais continuam propostos.
