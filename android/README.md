# APK de teste do assistAe

Instale o APK de teste no Android 8 ou superior. Na primeira abertura, copie o identificador exibido e encaminhe-o ao responsável pelo beta. Após a liberação no Supabase, toque em **Tentar novamente** e escolha o apelido. O identificador permanece na instalação. Apagar os dados do app ou reinstalar do zero pode exigir nova liberação.

## Gerar o APK

Use Java 17, Android SDK 36 e as ferramentas de build 35.0.0. Em `android/local.properties`, defina `sdk.dir` com o caminho do SDK e `assistae.supabase.publicKey` com a chave publicável do projeto. O endereço do projeto assistAe já é o padrão. Para outro projeto, defina `assistae.supabase.url`.

Execute `gradlew.bat :app:assembleDebug` no Windows ou `./gradlew :app:assembleDebug` em outros sistemas. O arquivo fica em `app/build/outputs/apk/debug/app-debug.apk`. Preserve a mesma assinatura entre atualizações do teste para manter os dados instalados.

## Notificações

O registro Android no Firebase usa `com.flops23.assistae`. Para habilitar o cliente, copie os valores públicos do `google-services.json` para `local.properties`: `assistae.firebase.appId` recebe `mobilesdk_app_id`, `assistae.firebase.projectId` recebe `project_id`, `assistae.firebase.apiKey` recebe `current_key` e `assistae.firebase.senderId` recebe `project_number`. A conta de serviço de envio fica no ambiente do Supabase. [Operação do dispatcher](../supabase/functions/push-dispatcher/README.md)
