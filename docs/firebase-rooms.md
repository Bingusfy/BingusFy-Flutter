# Salas do BingusFy no Firebase gratuito

Projeto criado: **bingusfy-rooms-20261008**, plano Spark. O app Web está configurado
em `lib/firebase_options.dart`, com Firestore em São Paulo (`southamerica-east1`)
e Authentication anônimo habilitado. Não utiliza Cloud Functions nem precisa de
conta de faturamento. As configurações Web do Firebase são identificadores públicos.

## Usar as salas

1. Execute o Flutter com seu Client ID e Redirect URI do Spotify, como explicado
   em [spotify-login.md](spotify-login.md). A configuração Firebase já está no código.
2. Entre no Spotify, escolha os artistas da fila e as configurações da tabela.
3. Clique em **Criar sala**, depois em **Copiar convite**.
4. Os convidados abrem o link e informam um nome, sem login no Spotify.
5. Todos veem as tabelas da sala. A própria aparece primeiro, com o marcador
   **Sua tabela**. Cada pessoa marca apenas a própria; as marcações aparecem ao
   vivo para os outros. O dono também recebe uma tabela.
6. Apenas o dono controla o player principal e o mini player. Use **Encerrar sala**
   para finalizar a sessão para todos. Convidados podem usar **Sair da sala**.

Compartilhe uma URL acessível aos convidados. `127.0.0.1` funciona apenas no
computador que está rodando o site; um teste remoto exige uma URL publicada.

## Spotify e sincronização

O navegador do dono consulta o Spotify a cada 3 segundos e envia os comandos
diretamente ao dispositivo Spotify ativo. O Firebase recebe somente os metadados
da música, fila e progresso; tokens Spotify não são enviados nem gravados no banco.
Mudanças de música, fila ou pausa são compartilhadas após a próxima consulta.
Correções de progresso são publicadas no máximo uma vez a cada 10 segundos
(normalmente 12 segundos devido ao intervalo de consultas). Cada navegador anima
o progresso localmente. O dono precisa manter o site aberto e em primeiro plano
para continuar consultando o Spotify.

O player dos convidados mostra o estado da sala; ele não transmite áudio. Para
ouvir juntos, use o Spotify/Jam ou o som ambiente. A lista de participantes é a
lista de pessoas que entraram no BingusFy, não a lista da Jam. Fechar uma aba não
remove automaticamente um participante; use **Sair da sala**.

## Identidade e proteção

O Firebase gera uma identidade anônima persistida no navegador. A propriedade da
sala usa o UID de quem a criou; nome e papéis enviados pelo cliente não concedem
controle. O login Spotify é validado pelo frontend para o dono; sem servidor, o
Firestore não verifica o token Spotify nem vincula o UID à conta Spotify.

Reabrir o mesmo link no mesmo navegador preserva tabela e marcações. Limpar os
dados do site ou usar outro navegador cria outra identidade e não recupera a
propriedade da sala. O dono também precisa preservar sua sessão Spotify na aba.

As regras publicadas impedem listar salas, trocar o dono ou os artistas depois da
criação, alterar tabelas alheias e enviar estado do player como convidado. As
tabelas são sorteadas no navegador, com artistas limitados à lista da sala, e ficam
imutáveis depois de criadas. Este fluxo ainda não valida automaticamente um bingo
ou declara um vencedor; marcações são manuais.

## Limites e manutenção

O Firestore Standard oferece 50.000 leituras e 20.000 escritas gratuitas por dia,
além de 1 GiB de armazenamento. Listeners e verificações das regras também podem
consumir leituras. Monitore o uso no console; no Spark, exceder a cota pode
interromper a operação até sua renovação, sem migrar automaticamente para cobrança.
Consulte as [cotas oficiais](https://firebase.google.com/docs/firestore/quotas).

Para republicar regras após alterações, use Firebase CLI atual:

```powershell
npx --yes firebase-tools@15.33.0 deploy --only "firestore,auth" --project bingusfy-rooms-20261008
```

Para testar regras localmente (Java 17 e Firebase CLI 14.14.0 instalados):

```powershell
npm --prefix firebase_tests ci
firebase emulators:exec --only firestore --project demo-bingusfy "npm --prefix firebase_tests run test:rules"
flutter test
```

Os testes verificam criação e entrada atômicas, leitura compartilhada de tabelas,
marcações permitidas, bloqueio de alterações de artistas e papéis, proteção do
player, encerramento e os três tamanhos de tabela.
