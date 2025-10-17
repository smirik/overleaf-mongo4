# Dockerfile
FROM sharelatex/sharelatex:4.1.6

# (1) Environment: make TeX binaries visible everywhere
ENV TL_YEAR=2023 \
    TL_ROOT=/usr/local/texlive \
    TL_DIR=/usr/local/texlive/2023 \
    TL_BIN=/usr/local/texlive/2023/bin/x86_64-linux

# Put our own /usr/local/bin first so a shim can shadow fmtutil-sys
ENV PATH=/usr/local/bin:${TL_BIN}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# (2) Install TeX packages from the *frozen* TL2023 repo, but skip auto fmt rebuilds
#     by shadowing fmtutil-sys with a no-op during tlmgr installs
RUN set -eux; \
  # --- shim to bypass fmtutil during tlmgr postactions ---
  printf '#!/bin/sh\nprintf "fmtutil-sys temporarily disabled during build\\n" >&2\nexit 0\n' > /usr/local/bin/fmtutil-sys; \
  chmod +x /usr/local/bin/fmtutil-sys; \
  \
  tlmgr option repository http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2023/tlnet-final; \
  tlmgr update --self; \
  \
  # Core packages you need (targeted set; no giant collections to keep it fast)
  tlmgr install \
    latexmk \
    # bibliography stack
    biber biblatex biblatex-apa csquotes logreq xpatch xstring \
    # graphics + tables + refs
    graphicx xcolor pgf tikz-cd pgfplots standalone svg pdfpages \
    booktabs threeparttable tabularx longtable array dcolumn multirow makecell \
    hyperref cleveref url xurl doi orcidlink \
    # math
    amsmath amsfonts amssymb mathtools \
    # misc utilities
    etoolbox xkeyval kvoptions subfiles comment adjustbox \
    # units/chem
    siunitx mhchem physics \
    # engines / unicode
    fontspec unicode-math polyglossia \
    # journal classes you mentioned
    apa7 aastex mnras revtex4-2 aas_macros \
    # scalerel + tikz helpers
    scalerel tikzsymbols; \
  \
  # --- remove shim and build only the formats we actually use ---
  rm -f /usr/local/bin/fmtutil-sys; \
  \
  mktexlsr; \
  updmap-sys; \
  fmtutil-sys --byfmt latex; \
  fmtutil-sys --byfmt pdflatex; \
  fmtutil-sys --byfmt xelatex; \
  fmtutil-sys --byfmt lualatex; \
  \
  # sanity: show engines & biber on PATH
  which pdflatex xelatex lualatex biber latexmk; \
  pdflatex --version | head -n1; \
  biber --version | head -n1

# (3) Optional: unify biber path for Overleaf’s scripts (symlink)
RUN set -eux; \
  test -x "${TL_BIN}/biber" && ln -sf "${TL_BIN}/biber" /usr/bin/biber

# (4) Keep image small(er)
RUN tlmgr path add