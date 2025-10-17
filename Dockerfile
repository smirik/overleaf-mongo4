# Dockerfile
FROM sharelatex/sharelatex:4.1.6

# (1) Environment: make TeX binaries visible everywhere
ENV TEXLIVE_BIN=/usr/local/texlive/2023/bin/x86_64-linux
ENV PATH="${TEXLIVE_BIN}:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# (2) Pin tlmgr to the frozen TL2023 'tlnet-final' mirror
#     and install packages you need.
#     This is intentionally verbose so you can edit later.
RUN set -eux; \
    tlmgr option repository http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2023/tlnet-final; \
    tlmgr update --self; \
    # Core collections (broad coverage, still reasonable size)
    tlmgr install \
      collection-latex collection-latexrecommended collection-latexextra \
      collection-fontsrecommended collection-bibtexextra \
      collection-pictures collection-science collection-mathscience \
      collection-xetex collection-luatex; \
    # Workhorses used across many papers
    tlmgr install \
      csquotes biblatex biblatex-apa biber logreq xpatch xstring \
      hyperref cleveref xurl url doi orcidlink \
      siunitx booktabs threeparttable tabularx longtable array dcolumn multirow makecell adjustbox \
      amsmath amsfonts amssymb mathtools \
      graphicx xcolor pgf pgfplots tikz-cd standalone svg pdfpages \
      etoolbox xkeyval kvoptions subfiles comment \
      mhchem physics unicode-math fontspec polyglossia \
      scalerel; \
    # Astronomy/publishing classes
    tlmgr install aastex aas_macros mnras revtex4-2; \
    # Psychology
    tlmgr install apa7; \
    # Refresh texlsr and formats
    mktexlsr; \
    fmtutil-sys --all || true

# (3) Symlinks as belt-and-suspenders (so PATH issues never bite)
RUN set -eux; \
    ln -sf ${TEXLIVE_BIN}/biber    /usr/local/bin/biber; \
    ln -sf ${TEXLIVE_BIN}/bibtex   /usr/local/bin/bibtex; \
    ln -sf ${TEXLIVE_BIN}/latexmk  /usr/local/bin/latexmk || true

# (4) Global latexmkrc: auto-use biber when biblatex is present
#     (Overleaf CE uses latexmk under the hood)
RUN printf '%s\n' "\
# /etc/latexmkrc (system-wide) \n\
\$bibtex_use = 2;            # Use biber when .bcf present (biblatex) \n\
\$pdflatex   = 'pdflatex -interaction=nonstopmode -synctex=1 %O %S'; \n\
" > /etc/latexmkrc