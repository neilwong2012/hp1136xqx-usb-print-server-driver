# Third-Party Notices

This repository contains project scripts and packaging metadata under the MIT
License. The generated installer bundles third-party runtime components that
remain under their own licenses.

## foo2zjs / foo2xqx

The package uses `foo2xqx`, `foo2xqx-wrapper`, and `foo2zjs-pstops` from the
foo2zjs project for HP host-based printer output.

- Upstream source used by the build script: `foo2zjs_20200505dfsg0.orig.tar.xz`
- Source URL: `https://deb.debian.org/debian/pool/main/f/foo2zjs/foo2zjs_20200505dfsg0.orig.tar.xz`
- License: GPL-family terms from the upstream foo2zjs source distribution.

## Ghostscript

The package bundles a Homebrew-built Ghostscript binary, its Homebrew dylib
dependencies, and Ghostscript resource files so CUPS can render PDF jobs inside
the CUPS runtime.

- Homebrew formula: `ghostscript`
- Upstream project: `https://ghostscript.com/`
- License: Ghostscript is distributed by Artifex under AGPL/commercial terms.

## GNU sed

When available, the package bundles Homebrew `gnu-sed` as `gsed` because the
foo2zjs wrapper scripts expect GNU sed-compatible behavior.

- Homebrew formula: `gnu-sed`
- License: GPL-family terms from GNU sed.

