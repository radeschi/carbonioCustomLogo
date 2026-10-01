# carbonio_customLogo

[Português](README.pt.md)

Bash script that applies a custom logo, login image, and wallpaper to the [Carbonio CE](https://www.zextras.com/carbonio/) webmail, including a different look per hosted domain.

It automates the manual procedure described by Anahuac in [Customizing Carbonio CE appearance](https://www.anahuac.eu/customizing-carbonio-appearance/). That guide is the source of this script, and the page links to it as a contribution.

**These changes do not survive a Carbonio upgrade.** Re-run the script after every upgrade. See [After an upgrade](#after-an-upgrade).

## What it does

For each domain, the script:

1. Backs up the original login directory and the JavaScript files it is about to edit (once) into `/opt/zextras/web/backup_orig`.
2. Collects domains from `carbonio gad`, plus any extra hostnames passed on the command line.
3. Creates `/opt/zextras/web/logos/<hostname>/` and copies the three image files into it. Existing directories are left untouched.
4. Patches the login JavaScript so the page loads `wallpaper.jpg` and `login.png` from the folder that matches `window.location.hostname`.
5. Replaces the built-in Carbonio SVG logo inside the webmail with `inside_logo.png`.
6. Replaces the browser tab title `Carbonio Client` with the string set in the script (default: `YourSiteName`).

The login page picks the folder from the hostname in the address bar. A folder named `example.com` is used only when users open `https://example.com`. If they open `webmail.example.com`, that hostname needs its own folder or a symlink. See [Virtual hosts](#virtual-hosts).

## Requirements

- Carbonio CE, with the web files under `/opt/zextras`.
- Root, because the script writes under `/opt/zextras/web` and runs `su - zextras -c "carbonio gad"`.
- `bash` and `sed`.
- The three image files in the directory where you run the script.

## Image files

Place these files next to the script before running it. Specs follow the [original guide](https://www.anahuac.eu/customizing-carbonio-appearance/):

| File | Use | Type | Suggested size | Background |
| --- | --- | --- | --- | --- |
| `wallpaper.jpg` | Login background | JPG | 1920×1080 | — |
| `login.png` | Logo on the login screen | PNG | 602×108 | white |
| `inside_logo.png` | Logo inside the webmail | PNG | 602×108 | transparent |

The same three files are copied into every domain folder. To give a domain its own images, replace the files in `/opt/zextras/web/logos/<hostname>/` after the script finishes. The script will not overwrite a folder that already exists.

## Page title

Edit this line in `carbonio_customLogo.sh` before the first run and set the name you want in the browser tab:

```bash
sed -i s/"Carbonio Client"/"YourSiteName"/g "$title_file"
```

The title is global. The original guide notes there is no per-domain title.

## Usage

```bash
chmod +x carbonio_customLogo.sh

# Domains returned by `carbonio gad`
sudo ./carbonio_customLogo.sh

# Also create folders for extra hostnames (virtual hosts, aliases)
sudo ./carbonio_customLogo.sh webmail.example.com mail.example.com
```

Resulting layout:

```text
/opt/zextras/web/logos/example.com/wallpaper.jpg
/opt/zextras/web/logos/example.com/login.png
/opt/zextras/web/logos/example.com/inside_logo.png
/opt/zextras/web/logos/webmail.example.com/...
```

Reload the login page after the script finishes.

## Virtual hosts

The webmail loads images from `/logos/<hostname>/`, where `<hostname>` is exactly what the browser shows. `carbonio gad` lists mail domains, which often differ from the name people type (`webmail.example.com`, `mail.example.com`).

Two ways to cover those names:

- Pass them as arguments. The script copies the images into a new folder for each one.
- Or symlink them to the domain folder, as in the [original guide](https://www.anahuac.eu/customizing-carbonio-appearance/):

```bash
cd /opt/zextras/web/logos
ln -s example.com webmail.example.com
ln -s example.com mail.example.com
```

## What gets changed

| Path | Change |
| --- | --- |
| `/opt/zextras/web/logos/<hostname>/` | Custom images, one folder per hostname |
| `/opt/zextras/web/login/*.js` | Login wallpaper and login logo point at those folders |
| `/opt/zextras/web/iris/carbonio-shell-ui/**/*.js` | SVG logo replaced by `inside_logo.png`; tab title replaced |

Originals are copied to `/opt/zextras/web/backup_orig` the first time the script runs. Later runs skip the backup if that directory is already there.

The script finds the right bundles by searching for strings that ship with Carbonio (`8b90fe7b942c6f389f1ddd01103d3b0e.jpg`, the logo SVG path, and `Carbonio Client`). Those strings can change between versions. If a search finds nothing, that part is skipped.

## After an upgrade

Carbonio replaces `/opt/zextras/web` on upgrade, so the JavaScript patches and sometimes the `logos` tree are gone.

1. Put `wallpaper.jpg`, `login.png`, and `inside_logo.png` back in the working directory.
2. If you want a fresh backup of the new originals, move or remove `/opt/zextras/web/backup_orig` first. While that directory exists, the script does not back up again.
3. Run the script again, including any extra hostnames you passed the first time.

Domain folders that are still present are not recreated. If an upgrade removed them, the script creates them again.

## Credits

Procedure and file layout: Anahuac, [Customizing Carbonio CE appearance](https://www.anahuac.eu/customizing-carbonio-appearance/) (published 2023-09-27, updated 2024-11-07).

## Author

Maicon Radeschi — radeschi@me.com
