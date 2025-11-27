# Dockerfile
FROM sharelatex/sharelatex:4.1.6

# (1) Environment: TeX Live paths (safe even if TL2023 dir isn't exactly that)
ENV TL_YEAR=2023 \
    TL_ROOT=/usr/local/texlive \
    TL_DIR=/usr/local/texlive/2023 \
    TL_BIN=/usr/local/texlive/2023/bin/x86_64-linux

# Put TeX bin early in PATH, but keep default system paths too
ENV PATH=/usr/local/bin:${TL_BIN}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# (2) Install TeX Live packages
RUN set -eux; \
  \
  # Stub ONLY fmtutil-sys to avoid long format rebuilds in CI
  printf '#!/bin/sh\nprintf "fmtutil-sys skipped during image build\n" >&2\nexit 0\n' > /usr/local/bin/fmtutil-sys; \
  chmod +x /usr/local/bin/fmtutil-sys; \
  \
  # Optionally pin to frozen TL2023 repo (you can comment this out if it causes issues)
  tlmgr option repository http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2023/tlnet-final || true; \
  \
  # Update tlmgr itself
  tlmgr update --self || true; \
  \
  # Install the packages needed for typical journal manuscripts, including txfonts
  tlmgr install \
    latexmk \
    biber biblatex biblatex-apa csquotes logreq xpatch xstring \
    graphicx xcolor pgf tikz-cd pgfplots standalone svg pdfpages caption float endfloat placeins pdflscape setspace \
    booktabs threeparttable tabularx longtable array dcolumn multirow makecell \
    hyperref cleveref url xurl doi orcidlink \
    amsmath amsfonts amssymb mathtools \
    etoolbox xkeyval kvoptions subfiles comment adjustbox \
    siunitx mhchem physics \
    fontspec unicode-math polyglossia \
    apa7 aastex mnras revtex4-2 aas_macros \
    scalerel tikzsymbols \
    collection-lang-cyrillic \
    babel-russian \
    cm-super \
    collection-latexrecommended \
    collection-latexextra \
    collection-fontsrecommended \
    collection-fontsextra \
    collection-mathscience \
    collection-bibtexextra \
    collection-pictures \
    txfonts \
    elsarticle \
  ; \
  \
  # Refresh filename DB and rebuild font maps
  mktexlsr; \
  updmap-sys --syncwithtrees || true; \
  updmap-sys || true; \
  \
  # Ensure binaries are on PATH
  tlmgr path add || true; \
  \
  # Sanity checks
  which pdflatex || true; \
  which lualatex || true; \
  which latexmk || true; \
  which biber || true; \
  \
  # Check that txfonts/rtxr is visible
  kpsewhich rtxr.tfm || echo "WARNING: rtxr.tfm not found"; \
  kpsewhich txfonts.map || echo "WARNING: txfonts.map not found"; \
  pdflatex --version | head -n 1 || true; \
  biber --version | head -n 1 || true

# (3) Optional: unify biber path for Overleaf’s scripts (symlink)
RUN set -eux; \
  if [ -x "${TL_BIN}/biber" ]; then ln -sf "${TL_BIN}/biber" /usr/bin/biber; fi