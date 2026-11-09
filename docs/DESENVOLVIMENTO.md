# Plano de desenvolvimento — assistAe

## Organização atual em blocos — 09/11/2026

Consulta rápida: [B00 — fechamento](BLOCOS.md#b00), [B01 — Android](BLOCOS.md#b01), [B02 — identidade](BLOCOS.md#b02), [B03 — salas](BLOCOS.md#b03), [B04 — player](BLOCOS.md#b04), [B05 — sincronização/fila](BLOCOS.md#b05), [B06 — chat](BLOCOS.md#b06), [B07 — amigos](BLOCOS.md#b07), [B08 — notificações](BLOCOS.md#b08) e [B09 — APK](BLOCOS.md#b09). Cada guia aponta aos IDs e seções exatos de suas fontes.

O roteiro operacional atual está em [BLOCOS.md](BLOCOS.md), com B00–B09, dependências, entregas e aceite. Ele substitui a sequência de sete etapas abaixo para organização futura. B00 é fechamento do planejamento; B01–B09 dependem de solicitação posterior para implementar. Nenhum bloco funcional iniciado ou testado. Conteúdo abaixo preservado como proposta anterior; pendências superadas devem ser conferidas em DECISOES.md.

**Escopo corrigido pelo usuário em 08/11/2026:** este roteiro de execução futura não autoriza nem define programação como próximo passo. Primeiro concluir planejamento de banco, métodos, algoritmos, segurança, contratos, operação e testes em [ARQUITETURA.md](ARQUITETURA.md), com revisão das decisões abertas. Não criar projeto Android ou infraestrutura nesta etapa. As entregas de implementação abaixo ficam como referência futura.

Atualizado em 08/11/2026. Planejamento proposto, sem código Android, backend provisionado ou APK testado. Regras de produto aprovadas estão em PLANEJAMENTO.md.

## Base visual e escopo

Etapa de design liberada pelo usuário para avançar. Usar as sete telas, dez painéis e estados aprovados; ajustes seguem os mesmos cards, botões, campos e confirmações. Preservar Home e navegação. Não gerar/editar imagens. Miniatura definitiva adiada, com marcador provisório.

Primeira versão: Android nativo, Kotlin/Compose, Media3 e Supabase; MP4/HLS gravados, até 10 participantes, chat, fila, salas públicas/privadas, permissões, amigos e convites. YouTube, lives, login visível, recuperação de conta e edição de avatar ficam fora desta versão.

## O que falta resolver

| Tema | Trabalho necessário | Momento |
|---|---|---|
| Ambiente Android | Escolher Android mínimo, identificador do app, versões compatíveis de ferramentas e aparelhos de teste | Antes de criar a base |
| Identidade | Definir criação segura e persistência da identidade de convidado; código público não deve funcionar como credencial | Antes do backend |
| Supabase | Projeto, ambiente de desenvolvimento, orçamento, migrações, políticas de acesso e operação | Antes de integrar rede real |
| Códigos e limites | Formato/colisões de códigos, tentativas de entrada, tamanho de nomes/mensagens/URLs, fila e antispam | Antes dos contratos de operações |
| Sincronização | Versão de estado, ordenação, comandos simultâneos, tolerância de desvio e reconexão | Antes do player compartilhado |
| Chat | Reconexão mantém já vistas sem recuperar intervalo; nova entrada sem histórico. P11: cache só em memória; P12: reticências e repetir animação interrompida na rotação. P15: até 5 pendentes, pular espera maior que 20 s | Antes do chat completo |
| Amizades | P07 confirmado: aceite explícito, cancelamento pendente e remoção bilateral confirmada; convites emitidos preservados. Detalhar reenvio/limites | Antes das funções sociais |
| Notificações | Entrega com app aberto/fechado e permissão Android; P10: ambos ligados com texto discreto sem nomes na tela bloqueada | Antes de concluir convites |
| Player | Falha/expiração de mídia, perda de áudio, chamadas, Voltar, teclado e valores da animação horizontal | Durante implementação e testes do player |
| APK | Assinatura, guarda externa da chave, distribuição e estratégia de atualização | Antes da entrega instalável |

As pendências não impedem planejar a estrutura. Decisões de produto novas devem ser explicitadas; números de exemplo nas imagens não definem contratos. Conferir documentação oficial atual ao selecionar dependências e mecanismos concretos.

## Estrutura proposta

- Interface Compose com tema e componentes reutilizáveis: card de sala, pessoa, vídeo, opção, campo, aviso e confirmação. Estados de carregamento, vazio, erro e permissão pertencem aos mesmos componentes.
- Estado de tela separado das regras de sala, fila, chat e amizade. Repositórios isolam Supabase e persistência local, permitindo navegação inicial com dados simulados claramente identificados.
- Controlador de reprodução separado da tela para preservar mídia e posição na rotação; planejar sessão/serviço de reprodução para áudio em segundo plano.
- Backend como autoridade sobre participantes, permissões, fila, reprodução e encerramento. Ocultar botão não substitui verificar autorização no servidor.
- Modelo de dados proposto: perfis, salas, participações, bloqueios por sala, estado de reprodução, itens da fila, mensagens, solicitações, amizades e convites. Definir ciclo de vida e políticas de leitura/escrita antes das migrações.
- Avaliar autenticação anônima interna para sustentar identidade segura sem tela de login. É proposta técnica, não alteração da experiência aprovada; confirmar persistência e perda após reinstalação, inclusive comportamento de backup Android.

## Entregas e critérios de conclusão

| Etapa | Entrega | Evidência necessária |
|---|---|---|
| 1. Base Android e componentes | Projeto compilável, tema preto/roxo, navegação e telas com dados simulados; Amigos como quinta opção | Compilação e inspeção em Android, comparação com referências, rolagem e áreas de toque |
| 2. Identidade e salas | Perfil persistente, criar/entrar, listagem pública, limite e permissões no servidor | Dois clientes entram; sala privada não aparece; 11ª entrada é recusada mesmo com concorrência; acesso indevido é negado |
| 3. Player e sincronização | MP4/HLS, play/pause/busca autorizados, entrada na posição atual e reconexão | Dois aparelhos, redes distintas, desvio medido, eventos antigos ignorados, rotação sem reinício e falha local sem pausar os demais |
| 4. Fila e administração | Adicionar/reproduzir agora, remover/reordenar, próximo automático, expulsão, transferência e encerramento | Próximo avança uma única vez; sucessão e encerramento cumprem os 60 segundos; identidade expulsa não retorna |
| 5. Chat e horizontal | Chat após entrada, painel horizontal, mensagens uma por vez e preferências | Ordem do servidor, proteção contra spam, teclado utilizável e ausência de histórico anterior à entrada |
| 6. Amigos, convites e configurações | Solicitação/aceite, remoção, convites e notificações conforme mecanismo definido | Fluxo entre identidades distintas; convite consumido ao entrar com sucesso e invalidado ao encerrar; preferências persistem |
| 7. Validação e APK | Integração completa, acessibilidade, correções e pacote assinado | Testes em aparelhos, instalação limpa, atualização preservando identidade e áudio com tela bloqueada |

Essa sequência é proposta para execução incremental; as etapas 1–5 são marcos internos e não substituem o escopo completo da primeira versão. Não considerar uma tela com dados simulados como funcionalidade conectada pronta.

## Contrato proposto de sincronização

Manter mídia, posição de referência, estado pausado/reproduzindo, horário do servidor e versão crescente por sala. O cliente estima a posição atual usando o tempo transcorrido quando a sala está reproduzindo. Correções pequenas/grandes precisam de limites medidos em aparelhos, ainda não definidos.

Processar comandos autorizados de forma serializada por sala, com identificação de pedido para impedir repetição por retry. Mudança de mídia/fila deve ser atômica. Na reconexão, obter estado atual e reconciliar eventos por versão; não reaplicar comandos antigos cegamente. Avanço automático precisa de proteção contra vários clientes notificando o mesmo término.

Presença visual não deve, sozinha, decidir administração. Planejar registro de conexão e rotina no servidor para aplicar tolerância de 60 segundos, desempate estável e encerramento mesmo quando nenhum app está conectado. Ordenar mensagens por sequência atribuída no servidor; horário do aparelho não define ordem.

## Detalhes de interface sem novas artes

- Configurações: acrescentar Amigos com o mesmo botão de lista.
- Solicitações enviadas: reutilizar card de pessoa; definir ações conforme regra funcional escolhida.
- Saída do administrador: reutilizar seleção de participante e confirmação; respeitar sucessor automático quando não houver escolha.
- Sem permissão: manter leitura da fila e ocultar/desativar ações conforme contexto, com validação efetiva no backend.
- Validação e feedback: reutilizar campos, avisos e confirmações aprovados; evitar criar novas telas para cada erro.
- Home: até três salas reais, limite de 10, sem agendamento ou código. Números e miniaturas ilustrativos das referências não viram dados reais.

## Primeiro marco recomendado

Fechar primeiro a especificação técnica completa: modelo de dados, acesso, operações, concorrência, sincronização, estados, arquitetura Android, operação e critérios de teste. Revisar com o usuário antes de qualquer programação. A construção da navegação e a prova em dois aparelhos pertencem à execução futura, não à etapa atual. Não há prazo estimado sem conferir ambiente, aparelhos e infraestrutura disponíveis.

Estado desta revisão: análise e documentação locais. Nenhuma geração de imagem, publicação no GitHub, implementação ou teste funcional.
