---
title: Working with MinIO Events
listings-disable-line-numbers: true
listings-no-page-break: true
papersize: letter
mainfont: Inter
monofont: DejaVu Sans Mono
header-includes:
  - \usepackage{fontspec}
logo: /opt/minio/images/minio-logo.png
#logo-height: 0.4cm # default is 0.4cm
copyright: MinIO, Inc., 2024
graphics: true
---

# Pandoc tools

## Pandoc container

This `Containerfile` uses the `pandoc/extra` image that already has the Eisvogel template installed.
We just had to add the fonts we normally use in the docs: Inter and DejaVu Sans Mono.

The fonts are configured in the Markdown frontmatter so we just need those packages to be installed in the OS.
