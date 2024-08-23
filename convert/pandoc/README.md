# Pandoc tools

## Pandoc container

This `Containerfile` uses the `pandoc/extra` image that already has the Eisvogel template installed.
We just had to add the fonts we normally use in the docs: Inter and DejaVu Sans Mono.

The fonts are configured in the Markdown frontmatter so we just need those packages to be installed in the OS.
