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
  # --- shims to bypass fmt/udpmap during tlmgr postactions ---
  printf '#!/bin/sh\nprintf "fmtutil-sys temporarily disabled during build\n" >&2\nexit 0\n' > /usr/local/bin/fmtutil-sys; \
  printf '#!/bin/sh\nprintf "updmap-sys temporarily disabled during build\n" >&2\nexit 0\n' > /usr/local/bin/updmap-sys; \
  chmod +x /usr/local/bin/fmtutil-sys /usr/local/bin/updmap-sys; \
  \
  # Stay on the frozen TL2023 repo (no cross-release)
  tlmgr option repository http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2023/tlnet-final; \
  tlmgr update --self; \
  \
  # Make downloads more robust on CI with the historic mirror
  tlmgr --verify-repo=none --no-persistent-download install \
    latexmk \
    biber biblatex biblatex-apa csquotes logreq xpatch xstring \
    graphicx xcolor pgf tikz-cd pgfplots standalone svg pdfpages \
    booktabs threeparttable tabularx longtable array dcolumn multirow makecell \
    hyperref cleveref url xurl doi orcidlink \
    amsmath amsfonts amssymb mathtools \
    etoolbox xkeyval kvoptions subfiles comment adjustbox \
    siunitx mhchem physics \
    fontspec unicode-math polyglossia \
    apa7 aastex mnras revtex4-2 aas_macros \
    scalerel tikzsymbols; \
  \
  # --- remove shims; refresh ls-R; build only needed formats ---
  rm -f /usr/local/bin/fmtutil-sys /usr/local/bin/updmap-sys; \
  mktexlsr; \
  # Skip updmap entirely; fonts work out-of-the-box for your stack.
  # If you insist, make it non-fatal:  updmap-sys || true
  fmtutil-sys --byfmt latex  || true; \
  fmtutil-sys --byfmt pdflatex || true; \
  fmtutil-sys --byfmt xelatex || true; \
  fmtutil-sys --byfmt lualatex || true; \
  \
  # sanity: show engines & tools
  which pdflatex xelatex lualatex biber latexmk; \
  pdflatex --version | head -n1; \
  biber --version | head -n1

# (3) Optional: unify biber path for Overleaf’s scripts (symlink)
RUN set -eux; \
  test -x "${TL_BIN}/biber" && ln -sf "${TL_BIN}/biber" /usr/bin/biber

# (4) Keep image small(er)
RUN tlmgr path add