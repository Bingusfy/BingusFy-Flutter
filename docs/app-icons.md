# Ícones do BingusFy

A imagem atual é o dado de vidro fumê enviado pelo usuário, preservado em
`assets/branding/bingusfy-dice.png`.
Os ícones são redimensionados a partir dela, sem redesenhar a arte.

A imagem já contém transparência externa real. A interface, os ícones web
e Android usam essa mesma arte. O gerador remove a transparência apenas no
catálogo iOS, que exige uma imagem opaca.

- Web: favicon PNG e ICO (16 a 256 px), ícone Apple de 180 px e ícones do
  manifesto de 192 e 512 px, incluindo versões maskable.
- Android: ícones de launcher nas densidades do projeto e ícone adaptativo.
- iOS: catálogo AppIcon, incluindo a imagem de 1024 px sem transparência.

Para gerar novamente, execute na raiz do projeto:

```powershell
dart run flutter_launcher_icons
dart run scripts/generate_web_icon_extras.dart
```

A configuração está em `flutter_launcher_icons.yaml`. Após gerar, confira o
diff de `ios/Runner.xcodeproj/project.pbxproj`: o gerador 0.14.4 pode alterar
`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` para `AppIcon`;
esse campo deve continuar `YES`.

O título da aba e o nome do app instalado estão em `web/index.html` e
`web/manifest.json`. Para publicar os ícones atualizados, use o script de
deploy descrito em `docs/firebase-hosting.md`.

O botão de login usa `assets/branding/spotify-icon-black.png`, extraído do
pacote oficial de ícones do Spotify, sem modificar o desenho:
https://developer.spotify.com/images/guidelines/design/2024-spotify-logo-icon.zip

O troféu decorativo da tela de login está em
`assets/branding/bingusfy-trophy-transparent.png`. O arquivo original está em
`assets/branding/bingusfy-trophy.png`. O recorte usa imagegen integrado com o
pedido: "Remover apenas o fundo externo e os espaços vazios das alças,
preservando o cristal, o número verde e os reflexos, com transparência real."
O dado e o troféu compartilham transparência, escala e flutuação suave no
widget `entry_floating_background.dart`.

As 25 fotos do mosaico estão em `assets/artists/`. Os nomes e as URLs
originais retornadas pelo oEmbed público do Spotify estão em
`assets/artists/sources.json`. As fotos são locais e pré-carregadas antes
de mostrar o mosaico, sem exigir login ou consultas à API nessa tela.

O mosaico ocupa 80% da largura, com cards quadrados (1:1) e espaçamento
uniforme. São 10 colunas no celular, 14 em telas intermediárias e 18 a 32
no desktop, mantendo os cards pequenos em monitores maiores. A ordem é
embaralhada e distribui todos os artistas antes de repetir.

O movimento ascendente lento usa uma velocidade comum para manter o
alinhamento. Os fades acontecem somente na entrada e na saída de cada
card, com duração variável; a foto fica estável durante o percurso e só
muda ao reciclar fora da tela. Não há ciclos periódicos de apagar e acender.
A preferência por reduzir animações pausa o movimento.

A opacidade geral é de 25% no desktop e 19% no celular. A faixa entre
44% e 68% da altura fica totalmente transparente para as ondas, com
transições suaves acima e abaixo. Um degradê radial em formato oval vertical escurece as bordas
da galeria antes do dado e do troféu, mantendo o foco no centro.

Além da faixa das ondas, uma máscara radial oval remove totalmente as
fotos no centro e faz a opacidade aumentar suavemente ao redor. Essa
máscara afeta somente o mosaico, mantendo ondas, dado e troféu visíveis.

