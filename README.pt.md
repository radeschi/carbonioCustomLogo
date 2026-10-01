# carbonio_customLogo

[English](README.md)

Script em Bash que aplica logo, imagem de login e papel de parede personalizados ao webmail do [Carbonio CE](https://www.zextras.com/carbonio/), inclusive com visual diferente por domínio hospedado.

Ele automatiza o procedimento manual descrito pelo Anahuac em [Customizing Carbonio CE appearance](https://www.anahuac.eu/customizing-carbonio-appearance/). Esse guia é a origem do script, e a página o cita como contribuição.

**Essas alterações não sobrevivem a uma atualização do Carbonio.** Execute o script de novo depois de cada upgrade. Veja [Depois de uma atualização](#depois-de-uma-atualização).

## O que ele faz

Para cada domínio, o script:

1. Faz backup do diretório de login original e dos arquivos JavaScript que vai editar (uma única vez) em `/opt/zextras/web/backup_orig`.
2. Obtém os domínios com `carbonio gad` e acrescenta os hostnames extras passados na linha de comando.
3. Cria `/opt/zextras/web/logos/<hostname>/` e copia os três arquivos de imagem para lá. Diretórios que já existem ficam como estão.
4. Altera o JavaScript da tela de login para carregar `wallpaper.jpg` e `login.png` da pasta correspondente a `window.location.hostname`.
5. Substitui o logo SVG padrão do Carbonio dentro do webmail por `inside_logo.png`.
6. Substitui o título da aba do navegador, `Carbonio Client`, pela string definida no script (padrão: `YourSiteName`).

A tela de login escolhe a pasta a partir do hostname da barra de endereços. Uma pasta chamada `example.com` só é usada quando o usuário abre `https://example.com`. Se o acesso for por `webmail.example.com`, esse hostname precisa da própria pasta ou de um link simbólico. Veja [Hosts virtuais](#hosts-virtuais).

## Requisitos

- Carbonio CE, com os arquivos web em `/opt/zextras`.
- Root, porque o script grava em `/opt/zextras/web` e executa `su - zextras -c "carbonio gad"`.
- `bash` e `sed`.
- Os três arquivos de imagem no diretório em que o script é executado.

## Arquivos de imagem

Coloque estes arquivos ao lado do script antes de executá-lo. As especificações seguem o [guia original](https://www.anahuac.eu/customizing-carbonio-appearance/):

| Arquivo | Uso | Tipo | Tamanho sugerido | Fundo |
| --- | --- | --- | --- | --- |
| `wallpaper.jpg` | Fundo da tela de login | JPG | 1920×1080 | — |
| `login.png` | Logo na tela de login | PNG | 602×108 | branco |
| `inside_logo.png` | Logo dentro do webmail | PNG | 602×108 | transparente |

Os mesmos três arquivos são copiados para a pasta de cada domínio. Para dar imagens próprias a um domínio, substitua os arquivos em `/opt/zextras/web/logos/<hostname>/` depois que o script terminar. O script não sobrescreve uma pasta que já existe.

## Título da página

Edite esta linha em `carbonio_customLogo.sh` antes da primeira execução e coloque o nome que deve aparecer na aba do navegador:

```bash
sed -i s/"Carbonio Client"/"YourSiteName"/g "$title_file"
```

O título é global. O guia original indica que não há título por domínio.

## Uso

```bash
chmod +x carbonio_customLogo.sh

# Domínios retornados por `carbonio gad`
sudo ./carbonio_customLogo.sh

# Também cria pastas para hostnames extras (hosts virtuais, aliases)
sudo ./carbonio_customLogo.sh webmail.example.com mail.example.com
```

Estrutura resultante:

```text
/opt/zextras/web/logos/example.com/wallpaper.jpg
/opt/zextras/web/logos/example.com/login.png
/opt/zextras/web/logos/example.com/inside_logo.png
/opt/zextras/web/logos/webmail.example.com/...
```

Recarregue a tela de login depois que o script terminar.

## Hosts virtuais

O webmail carrega as imagens de `/logos/<hostname>/`, em que `<hostname>` é exatamente o que o navegador mostra. O `carbonio gad` lista domínios de e-mail, que muitas vezes diferem do nome digitado pelo usuário (`webmail.example.com`, `mail.example.com`).

Duas formas de cobrir esses nomes:

- Passe-os como argumentos. O script copia as imagens para uma pasta nova de cada um.
- Ou crie links simbólicos para a pasta do domínio, como no [guia original](https://www.anahuac.eu/customizing-carbonio-appearance/):

```bash
cd /opt/zextras/web/logos
ln -s example.com webmail.example.com
ln -s example.com mail.example.com
```

## O que é alterado

| Caminho | Alteração |
| --- | --- |
| `/opt/zextras/web/logos/<hostname>/` | Imagens personalizadas, uma pasta por hostname |
| `/opt/zextras/web/login/*.js` | Papel de parede e logo de login apontam para essas pastas |
| `/opt/zextras/web/iris/carbonio-shell-ui/**/*.js` | Logo SVG substituído por `inside_logo.png`; título da aba substituído |

Os originais são copiados para `/opt/zextras/web/backup_orig` na primeira execução. Execuções seguintes pulam o backup se esse diretório já existir.

O script localiza os bundles certos buscando strings que vêm com o Carbonio (`8b90fe7b942c6f389f1ddd01103d3b0e.jpg`, o path do SVG do logo e `Carbonio Client`). Essas strings podem mudar entre versões. Se uma busca não achar nada, essa parte é ignorada.

## Depois de uma atualização

O Carbonio substitui `/opt/zextras/web` no upgrade, então os patches de JavaScript e, às vezes, a árvore `logos` desaparecem.

1. Coloque de novo `wallpaper.jpg`, `login.png` e `inside_logo.png` no diretório de trabalho.
2. Se quiser um backup novo dos originais atualizados, mova ou remova `/opt/zextras/web/backup_orig` antes. Enquanto esse diretório existir, o script não faz backup de novo.
3. Execute o script outra vez, incluindo os hostnames extras da primeira execução.

Pastas de domínio que ainda existirem não são recriadas. Se o upgrade as removeu, o script as cria de novo.

## Créditos

Procedimento e estrutura de arquivos: Anahuac, [Customizing Carbonio CE appearance](https://www.anahuac.eu/customizing-carbonio-appearance/) (publicado em 27/09/2023, atualizado em 07/11/2024).

## Autor

Maicon Radeschi — radeschi@me.com
