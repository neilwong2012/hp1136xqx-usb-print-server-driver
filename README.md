# HP LaserJet M1136 via FusionWrt XQX

macOS CUPS driver package for printing to an HP LaserJet Professional M1136 MFP
through a FusionWrt/OpenWrt USB print server (`p910nd`) over JetDirect socket
printing.

This is for printing only. Scanning is not shared by `p910nd`; use direct USB or
a separate scan server for scanning.

## Install

Download the latest `.pkg` from the GitHub Releases page and install it.

The installer creates this CUPS queue by default:

- Queue: `HP1136XQX`
- Address: `socket://192.168.31.119:9100`
- Paper: A4
- Resolution: 600 dpi

## Configure Router Address And Port

After installation, run:

```sh
sudo hp1136xqx-setup --host 192.168.31.119 --port 9100
```

For a different router:

```sh
sudo hp1136xqx-setup --host 192.168.1.1 --port 9100
```

You can also change the queue name:

```sh
sudo hp1136xqx-setup --host 192.168.1.1 --port 9100 --queue HP1136Office
```

## Test

Check the socket:

```sh
nc -zv 192.168.31.119 9100
```

Check the CUPS queue:

```sh
lpstat -p HP1136XQX -v HP1136XQX
```

Print a small test:

```sh
echo test | lp -d HP1136XQX
```

## Build From Source

Requirements:

```sh
brew install ghostscript gnu-sed
```

Build:

```sh
./scripts/build-pkg.sh
```

The installer will be written to `dist/`.

## Uninstall

```sh
sudo hp1136xqx-uninstall
```

The uninstaller removes the queue and installed files. It does not automatically
restore CUPS sandbox configuration because the installer backs up the previous
file and multiple package installs may exist.

## Notes

This package uses a CUPS filter built around `foo2xqx`, not HP's official macOS
driver. It exists because the HP LaserJet M1136 is a host-based printer and does
not behave like a normal PCL/PostScript printer through raw socket printing.

