# Configurar o login com Spotify

A tela inicial usa ondas sonoras desenhadas diretamente em Flutter, com linhas
verdes sobrepostas, movimento lento e brilho suave nas laterais.
O login usa Authorization Code com PKCE, sem Client Secret no navegador.

O fundo se move continuamente em um ciclo de 24 segundos, com pulsos discretos
simulados a 70 BPM, sem depender do mouse ou de áudio real. O efeito está em
`lib/modules/entry/widgets/musical_waves_background.dart` e respeita a preferência
de reduzir animações, exibindo ondas estáticas nesse caso. O LiquidEther anterior
continua nos arquivos do projeto, mas não é carregado pela tela inicial.

1. Entre em https://developer.spotify.com/dashboard e crie um app para o BingusFy.
2. Habilite o uso da Web API e cadastre esta Redirect URI para desenvolvimento:
   `http://127.0.0.1:8080/` (incluindo a barra final). Spotify não aceita `localhost`.
3. Copie o **Client ID**. Não é necessário usar o Client Secret.
4. Inicie o projeto:

```powershell
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 8080 --dart-define=SPOTIFY_CLIENT_ID=SEU_CLIENT_ID --dart-define=SPOTIFY_REDIRECT_URI=http://127.0.0.1:8080/
```

Para produção, cadastre a URL HTTPS do site, mantendo o mesmo caminho base e
barra final usados na aplicação. Passe os dois `--dart-define` também no build:

```powershell
flutter build web --dart-define=SPOTIFY_CLIENT_ID=SEU_CLIENT_ID --dart-define=SPOTIFY_REDIRECT_URI=https://seu-dominio.com/
```

O botão permanece desabilitado até configurar ambos os valores. O retorno do
Spotify valida `state`, a idade da tentativa e o verificador PKCE antes de trocar
o código por tokens. A sessão fica em `sessionStorage` apenas nesta aba; o token
expirado é renovado ao entrar novamente. A rota `/home` também verifica a sessão.
Essa verificação controla a interface; um futuro backend precisa validar suas
próprias requisições.

O login solicita `user-read-currently-playing`, `user-read-playback-state`
e `user-modify-playback-state` para os controles do mini player.
Ao abrir a tela principal, o app consulta a música atual e a fila da conta
autorizada. Os artistas de todas as músicas da fila, incluindo participações,
substituem a antiga lista fixa e são selecionados na primeira fila não vazia.
Episódios são ignorados e nomes repetidos são removidos. A música atual é exibida
separadamente; seus artistas só entram na lista se também estiverem na fila.

A tela mostra um mini player nas cores do BingusFy com capa, título, artistas,
progresso, anterior, reproduzir/pausar e próxima música. A fila fica à direita
no desktop e abaixo no celular, com rolagem para consultar todas as faixas.
Quando a área do player principal sai completamente da região visível, um
mini player aparece fixo acima do rodapé, com capa, música, artistas, progresso
e controles. Ele usa o mesmo estado e os mesmos comandos, sem consultas extras.
Ao voltar ao player principal, o mini player desaparece. No desktop, o botão
**Ver player completo** também leva de volta ao player principal.
Os controles atuam no dispositivo ativo do Spotify; abra o Spotify e comece
a reprodução nele antes de usar o player. Eles exigem Premium e a permissão
`user-modify-playback-state`. Quem já estava conectado pode usar
**Autorizar controles do Spotify** para conceder a nova permissão.

Use **Atualizar fila** para buscar mudanças. Também há atualização automática
a cada 3 segundos enquanto a aplicação está em primeiro plano, sem mostrar
carregamento ou alterar a seleção de artistas durante as consultas automáticas.
Ao voltar para a aba, a consulta é imediata. Ao sair da tela, os timers são
cancelados. As consultas não se sobrepõem e respeitam o `Retry-After` do Spotify.
Essa sincronização usa polling da Web API: o evento `player_state_changed` do
Web Playback SDK acompanha o player local do navegador, enquanto este mini
player controla a reprodução no dispositivo ativo do Spotify. Mudanças externas
podem levar aproximadamente 3 segundos mais o tempo da requisição para aparecer.
O botão **Atualizar fila** permanece como opção de consulta manual. O progresso
é estimado entre consultas e sincronizado novamente em cada atualização.
Cada comando consulta novamente a música e a fila após sua execução.
Atualizações posteriores alteram as
sugestões e o painel, preservando a seleção e as cartelas existentes. O botão
**Adicionar artistas da fila** inclui os artistas recém-consultados na seleção.
Uma fila vazia não é preenchida com artistas de exemplo. O áudio continua
no Spotify. **Sair** apaga a sessão nesta aba.

Quem já entrou antes precisa reconectar o Spotify para conceder as novas
permissões. Erros de acesso exibem a opção de reconexão. Tokens expirados são
renovados; respostas 401 têm uma única tentativa de renovação, e 429 respeitam
o intervalo `Retry-After` antes de permitir nova consulta. Em falhas temporárias,
os últimos dados permanecem visíveis com um aviso.

Em modo de desenvolvimento, o proprietário precisa de Spotify Premium e o app
aceita até cinco usuários autorizados. Adicione os usuários em Settings > Users
Management. Essas restrições atuais estão na documentação de quota modes abaixo.
Sem registrar um app,
não é possível realizar um login real no Spotify. Testes locais simulam as
respostas OAuth; a autorização real deve ser validada após obter o Client ID.

Referências oficiais:

- https://developer.spotify.com/documentation/web-api/tutorials/code-pkce-flow
- https://developer.spotify.com/documentation/web-api/concepts/redirect_uri
- https://developer.spotify.com/documentation/web-api/concepts/quota-modes
- https://developer.spotify.com/documentation/web-api/reference/get-queue
- https://developer.spotify.com/documentation/web-api/reference/get-the-users-currently-playing-track
- https://developer.spotify.com/documentation/web-api/reference/start-a-users-playback
- https://developer.spotify.com/documentation/web-api/reference/pause-a-users-playback
- https://developer.spotify.com/documentation/web-api/reference/skip-users-playback-to-next-track
- https://developer.spotify.com/documentation/web-api/reference/skip-users-playback-to-previous-track

Validação local:

```powershell
flutter analyze --no-fatal-infos
flutter test
node --test test/spotify_auth_test.cjs
flutter build web
```
