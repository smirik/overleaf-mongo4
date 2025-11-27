# Dockerfile
FROM sharelatex/sharelatex:4.1.6

# (1) Environment: TeX Live paths
ENV TL_YEAR=2023 \
    TL_ROOT=/usr/local/texlive \
    TL_DIR=/usr/local/texlive/2023 \
    TL_BIN=/usr/local/texlive/2023/bin/x86_64-linux

# PATH
ENV PATH=/usr/local/bin:${TL_BIN}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# (2) Install TeX Live packages
RUN set -eux; \
  \
  # Stub ONLY fmtutil-sys to prevent long format rebuilds
  printf '#!/bin/sh\nprintf "fmtutil-sys skipped during image build\n" >&2\nexit 0\n' > /usr/local/bin/fmtutil-sys; \
  chmod +x /usr/local/bin/fmtutil-sys; \
  \
  # Pin to frozen TL2023 repo (like your original Dockerfile)
  tlmgr option repository http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2023/tlnet-final || true; \
  tlmgr update --self || true; \
  \
  echo "=== Installing TeX packages ==="; \
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
    sttools \
    collection-langcyrillic \
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
  tlmgr path add || true; \
  \
  # Sanity checks
  which pdflatex || true; \
  which latexmk || true; \
  which biber || true; \
  kpsewhich rtxr.tfm || echo "WARNING: rtxr.tfm not found"; \
  kpsewhich txfonts.map || echo "WARNING: txfonts.map not found"; \
  kpsewhich cuted.sty || echo "WARNING: cuted.sty not found"; \
  pdflatex --version | head -n 1 || true; \
  biber --version | head -n 1 || true

# (3) Biber symlink for Overleaf
RUN set -eux; \
  if [ -x "${TL_BIN}/biber" ]; then ln -sf "${TL_BIN}/biber" /usr/bin/biber; fi