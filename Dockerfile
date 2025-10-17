# Dockerfile
FROM sharelatex/sharelatex:4.1.6

# ---- knobs ----
ARG TL_MIRROR=http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2023/tlnet-final
ENV TEXLIVE_BIN=/usr/local/texlive/2023/bin/x86_64-linux
ENV PATH="${TEXLIVE_BIN}:${PATH}"

# Make RUN noisy & fail-fast
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

# 1) Pin tlmgr to TL2023 historic mirror and self-update
RUN echo ">> pin tlmgr to ${TL_MIRROR}" \
 && tlmgr option repository "${TL_MIRROR}" \
 && tlmgr update --self

# 2) Core collections (split into layers so you see progress + benefit from cache)
RUN echo ">> install core TeX collections" \
 && tlmgr install \
    collection-latex collection-latexrecommended collection-latexextra \
    collection-fontsrecommended collection-bibtexextra \
    collection-publishers collection-science collection-mathscience \
    collection-xetex collection-luatex

# 3) Your common pkgs (APA, astro/psych, graphics, etc.)
RUN echo ">> install common pkgs" \
 && tlmgr install \
    csquotes biblatex biblatex-apa biber apa7 scalerel \
    hyperref cleveref xurl url doi orcidlink \
    siunitx booktabs threeparttable tabularx longtable array dcolumn multirow makecell adjustbox \
    amsmath amsfonts amssymb mathtools \
    graphicx xcolor pgf pgfplots tikz-cd standalone svg pdfpages \
    etoolbox xstring xkeyval kvoptions subfiles comment \
    mhchem physics unicode-math fontspec polyglossia \
    aastex mnras revtex4-2 aas_macros

# 4) Index + only the formats we actually need (avoid xelatex-dev noise)
RUN echo ">> mktexlsr + minimal fmtutil" \
 && mktexlsr \
 && fmtutil-sys --byfmt pdflatex \
 && fmtutil-sys --byfmt xetex \
 && fmtutil-sys --byfmt xelatex \
 && fmtutil-sys --byfmt lualatex

# 5) Stable tool paths for Overleaf toolchain
RUN ln -sf ${TEXLIVE_BIN}/biber /usr/local/bin/biber \
 && ln -sf ${TEXLIVE_BIN}/latexmk /usr/local/bin/latexmk \
 && printf '%s\n' \
      "\$bibtex_use = 2;" \
      "\$pdflatex = 'pdflatex -interaction=nonstopmode -synctex=1 %O %S';" \
      > /etc/latexmkrc