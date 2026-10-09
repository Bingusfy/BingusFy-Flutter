# Publicar o BingusFy

O Firebase Hosting está configurado em `firebase.json` para publicar `build/web`
no projeto `bingusfy-rooms-20261008`. As rotas retornam `index.html`, permitindo
abrir links de salas. Os arquivos são revalidados para receber novas versões.
A configuração não habilita cobrança nem muda o plano Spark.

Endereço do site e Redirect URI do Spotify:

```text
https://bingusfy-rooms-20261008.web.app/
```

Antes de usar o login, abra seu app no Spotify Developer Dashboard e adicione
essa URL em **Settings > Redirect URIs**. Mantenha a barra final e salve.
Você pode manter também a URL de desenvolvimento `http://127.0.0.1:8080/`.

Na raiz do projeto, com Flutter e Node.js disponíveis no PATH e Firebase CLI
autenticado, execute:

```powershell
.\scripts\deploy-web.ps1 -SpotifyClientId SEU_CLIENT_ID
```

O script exige um Client ID válido, gera uma versão release com o retorno HTTPS
e publica somente o Hosting. Se o build falhar, não publica. Não use Client
Secret: o login usa PKCE. Para atualizar o site, execute novamente o comando.

As salas continuam no Firestore e os participantes são identificados pelo
Firebase Authentication. Não é necessário um servidor WebSocket separado.
O dono precisa manter a sala aberta para compartilhar as consultas ao Spotify.

O endereço acima só estará disponível com o app após um deploy bem-sucedido.

Referências:

- https://firebase.google.com/docs/hosting/quickstart
- https://firebase.google.com/docs/hosting/full-config
- https://developer.spotify.com/documentation/web-api/concepts/redirect_uri
