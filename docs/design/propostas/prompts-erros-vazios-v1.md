# Prompts — erros, reconexão e estados vazios

Correção selecionada para Sala lotada: imagegen em modo de edição, alvo primeira prévia. Remover somente card Marina duplicado abaixo do modal, preencher com fundo preto/roxo e camada escura existente, mantendo os dois cards superiores, o modal, textos, botão Entendi, cabeçalho, dimensões e demais elementos. Primeiro resultado não selecionado para entrega.

Ferramenta imagegen integrada, sem CLI. Nove imagens separadas. Usuário dispensou prévia do teclado horizontal e solicitou os lotes de erros/reconexão e vazios. Propostas locais, sem aprovação ou autorização de envio ao GitHub.

## erro-codigo

Referência: docs/design/entrar-sala-aprovada.png

Use case: ui-mockup. ONE polished portrait Android assistAe screen proposal. Input image is style/layout reference only, never alter source. Match black/deep purple glow, rounded lilac outlined surfaces, bold white Portuguese labels, purple gradient primary buttons. Flat edge-to-edge screen, no phone mockup or external labels. All text Brazilian Portuguese crisp and legible, generous spacing, no clipping. Preserve established concept and navigation. No login, scheduling, waiting room, external links, website, new imagery or keyboard. Fictional example data, static proposal. State of approved Entrar em sala screen after invalid code. Keep brand/back/title, labeled Código da sala field, main Entrar button and existing Convites de amigos sample cards below. Field contains '@@@' as illustrative invalid code; highlight only field border and inline error in restrained pink: 'Código inválido. Confira e tente novamente.' No modal, no success state, no loading indicator, no room visible. User can edit the field. Do not define actual code length/format.

## sala-lotada

Referência: docs/design/entrar-sala-aprovada.png

Use case: ui-mockup. ONE polished portrait Android assistAe screen proposal. Input image is style/layout reference only, never alter source. Match black/deep purple glow, rounded lilac outlined surfaces, bold white Portuguese labels, purple gradient primary buttons. Flat edge-to-edge screen, no phone mockup or external labels. All text Brazilian Portuguese crisp and legible, generous spacing, no clipping. Preserve established concept and navigation. No login, scheduling, waiting room, external links, website, new imagery or keyboard. Fictional example data, static proposal. Approved Entrar em sala screen background softly dimmed, a SINGLE centered compact rounded error dialog. Icon people, title 'Sala lotada', body 'Esta sala já tem 10 participantes. Tente novamente mais tarde.' One purple button 'Entendi'. Keep underlying code field and friend invites recognizable. No waiting list, reserved place, automatic admission, timer or capacity over 10. Only this error.

## sala-encerrada

Referência: docs/design/entrar-sala-aprovada.png

Use case: ui-mockup. ONE polished portrait Android assistAe screen proposal. Input image is style/layout reference only, never alter source. Match black/deep purple glow, rounded lilac outlined surfaces, bold white Portuguese labels, purple gradient primary buttons. Flat edge-to-edge screen, no phone mockup or external labels. All text Brazilian Portuguese crisp and legible, generous spacing, no clipping. Preserve established concept and navigation. No login, scheduling, waiting room, external links, website, new imagery or keyboard. Fictional example data, static proposal. Approved Entrar em sala screen background softly dimmed, SINGLE centered compact rounded error dialog. Icon closed door, title 'Sala encerrada', body 'Esta sala foi encerrada. Peça um novo convite ao seu amigo.' One purple button 'Entendi'. Keep underlying field and friend invites recognizable but dimmed, no entry occurs. No recreate room action, no fake new code, no retry closed room, no misleading active invitation as successful.

## video-invalido

Referência: docs/design/propostas/adicionar-video-proposta-v1.png

Use case: ui-mockup. ONE polished portrait Android assistAe screen proposal. Input image is style/layout reference only, never alter source. Match black/deep purple glow, rounded lilac outlined surfaces, bold white Portuguese labels, purple gradient primary buttons. Flat edge-to-edge screen, no phone mockup or external labels. All text Brazilian Portuguese crisp and legible, generous spacing, no clipping. Preserve established concept and navigation. No login, scheduling, waiting room, external links, website, new imagery or keyboard. Fictional example data, static proposal. Error variant of Adicionar vídeo bottom sheet inside approved room. Retain room/video upper context, sheet back arrow, title Adicionar vídeo and X. Label Link do vídeo with input containing illustrative 'https://exemplo.com/video.mp4'. Under input concise restrained pink error 'Não foi possível abrir este vídeo.' helper 'Confira o link ou tente outra URL MP4 ou HLS.' No green check, no Link validado, no valid media preview. Reproduzir agora and Adicionar à fila remain visible DISABLED grey/dimmed because URL failed validation. Existing room video behind remains unchanged; no invalid media added or room-wide playback error. Error cause unknown, do not claim DRM bypass or unsupported every page.

## reconectando

Referência: docs/design/player-vertical-aprovado.png

Use case: ui-mockup. ONE polished portrait Android assistAe screen proposal. Input image is style/layout reference only, never alter source. Match black/deep purple glow, rounded lilac outlined surfaces, bold white Portuguese labels, purple gradient primary buttons. Flat edge-to-edge screen, no phone mockup or external labels. All text Brazilian Portuguese crisp and legible, generous spacing, no clipping. Preserve established concept and navigation. No login, scheduling, waiting room, external links, website, new imagery or keyboard. Fictional example data, static proposal. Room Noite de cinema with participant count 3, mountain video in original area, Chat and three existing sample messages and bottom composer. Show narrow prominent purple reconnection banner under header with small circular loading icon and exact 'Reconectando...' and smaller 'Sua conexão caiu. Tentando reconectar.' Current frame remains visible; media control buttons and message composer visibly disabled, not removed. Show small 'Tentar novamente' outlined action within banner/card. No giant blocking modal, no global pause command, no statement other participants stopped, no success message or invented countdown. This is only local connection state with automatic retry; last-known participant count is illustrative, recovery not demonstrated.

## sem-salas

Referência: docs/design/salas-publicas-aprovada.png

Use case: ui-mockup. ONE polished portrait Android assistAe screen proposal. Input image is style/layout reference only, never alter source. Match black/deep purple glow, rounded lilac outlined surfaces, bold white Portuguese labels, purple gradient primary buttons. Flat edge-to-edge screen, no phone mockup or external labels. All text Brazilian Portuguese crisp and legible, generous spacing, no clipping. Preserve established concept and navigation. No login, scheduling, waiting room, external links, website, new imagery or keyboard. Fictional example data, static proposal. Empty approved Salas públicas list screen. Keep back arrow, assistAe wordmark, title Salas públicas and search field Buscar sala. Remove all room cards. Below search one understated centered people/video outline icon, exact primary text 'Nenhuma sala pública no momento', secondary 'As salas disponíveis aparecerão aqui.' Plenty of quiet space. No fake cards, schedule, tags, error message, spinner, create button or new navigation. This represents truly zero public rooms with blank search.

## sem-resultados

Referência: docs/design/salas-publicas-aprovada.png

Use case: ui-mockup. ONE polished portrait Android assistAe screen proposal. Input image is style/layout reference only, never alter source. Match black/deep purple glow, rounded lilac outlined surfaces, bold white Portuguese labels, purple gradient primary buttons. Flat edge-to-edge screen, no phone mockup or external labels. All text Brazilian Portuguese crisp and legible, generous spacing, no clipping. Preserve established concept and navigation. No login, scheduling, waiting room, external links, website, new imagery or keyboard. Fictional example data, static proposal. Zero search results variant of approved Salas públicas screen. Keep back arrow, brand and title, outlined search field containing example 'Aventura espacial' and clear X icon. No room cards. Below centered magnifying-glass icon and exact text 'Nenhuma sala encontrada', smaller 'Tente buscar por outro nome.' compact text action 'Limpar busca'. No keyboard, no claim no rooms exist at all, no schedule or error state.

## sem-amigos

Referência: docs/design/propostas/amigos-proposta-v1.png

Use case: ui-mockup. ONE polished portrait Android assistAe screen proposal. Input image is style/layout reference only, never alter source. Match black/deep purple glow, rounded lilac outlined surfaces, bold white Portuguese labels, purple gradient primary buttons. Flat edge-to-edge screen, no phone mockup or external labels. All text Brazilian Portuguese crisp and legible, generous spacing, no clipping. Preserve established concept and navigation. No login, scheduling, waiting room, external links, website, new imagery or keyboard. Fictional example data, static proposal. Empty Amigos screen variant. Keep back arrow and assistAe header, title Amigos, card Seu código with sample U8F2K9 plus copy icon, Adicionar amigo area with input Código do usuário and Enviar solicitação. Solicitações section has tabs Recebidas (0) and Enviadas (0) and short text 'Nenhuma solicitação no momento.' Below heading Seus amigos, simple people outline icon with exact 'Você ainda não tem amigos' and short 'Adicione alguém pelo código para começar.' No Lucas Marina Rafa rows, no remove icons on empty list, no login, status online or recovery feature. Keep known subtle note 'Sem recuperação após reinstalar ou trocar de aparelho.' All fits readable. Sample code not production format.

## sem-convites

Referência: docs/design/entrar-sala-aprovada.png

Use case: ui-mockup. ONE polished portrait Android assistAe screen proposal. Input image is style/layout reference only, never alter source. Match black/deep purple glow, rounded lilac outlined surfaces, bold white Portuguese labels, purple gradient primary buttons. Flat edge-to-edge screen, no phone mockup or external labels. All text Brazilian Portuguese crisp and legible, generous spacing, no clipping. Preserve established concept and navigation. No login, scheduling, waiting room, external links, website, new imagery or keyboard. Fictional example data, static proposal. Empty invitations variant of approved Entrar em sala screen. Keep exactly top code section: brand/back/title, Código da sala label, empty Digite o código input and purple Entrar button. Below heading Convites de amigos, remove all sample invite cards. Replace with modest envelope outline icon, text 'Nenhum convite no momento', smaller 'Os convites dos seus amigos aparecerão aqui.' Quiet empty space below, no new buttons, code error, sample friends, notifications feed or schedule. Code entry still available.
