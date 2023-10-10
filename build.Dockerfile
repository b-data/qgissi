ARG IMAGE
ARG PREFIX=/usr/local

FROM glcr.b-data.ch/nodejs/nsi/18.18.0/debian:11 as nsi

FROM ${IMAGE} as builder

ARG DEBIAN_FRONTEND=noninteractive

ARG QGIS_VERSION

ARG WITH_3D=ON
ARG WITH_ANALYSIS=TRUE
ARG WITH_APIDOC=OFF
ARG WITH_ASAN=FALSE
ARG WITH_ASTYLE=OFF
ARG WITH_AUTH=TRUE
ARG WITH_BINDINGS=ON
ARG WITH_CLAZY=FALSE
ARG WITH_COPC=TRUE
ARG WITH_CORE=TRUE
ARG WITH_CRASH_HANDLER=TRUE
ARG WITH_CUSTOM_WIDGETS=ON
ARG WITH_DESKTOP=ON
ARG WITH_EPT=TRUE
ARG WITH_GRASS7=ON
ARG WITH_GRASS8=ON
ARG WITH_GRASS_PLUGIN=TRUE
ARG WITH_GSL=TRUE
ARG WITH_GUI=TRUE
ARG WITH_HANA=FALSE
ARG WITH_INTERNAL_LAZPERF=TRUE
ARG WITH_INTERNAL_MDAL=TRUE
ARG WITH_INTERNAL_O2=ON
ARG WITH_INTERNAL_POLY2TRI=TRUE
ARG WITH_OAUTH2_PLUGIN=TRUE
ARG WITH_ORACLE=FALSE
ARG WITH_PDAL=FALSE
ARG WITH_POSTGRESQL=TRUE
ARG WITH_PY_COMPILE=FALSE
ARG WITH_QGIS_PROCESS=TRUE
ARG WITH_QSCIAPI=TRUE
ARG WITH_QSPATIALITE=ON
ARG WITH_QT5SERIALPORT=TRUE
ARG WITH_QTSERIALPORT=TRUE
ARG WITH_QTWEBKIT=TRUE
ARG WITH_QUICK=FALSE
ARG WITH_QWTPOLAR=FALSE
ARG WITH_SERVER=ON
ARG WITH_SERVER_LANDINGPAGE_WEBAPP=TRUE
ARG WITH_SERVER_PLUGINS=ON
ARG WITH_SPATIALITE=TRUE
ARG WITH_STAGED_PLUGINS=ON
ARG WITH_THREAD_LOCAL=TRUE

ARG PREFIX
ARG MODE=install

ENV CC=/usr/lib/ccache/gcc \
    CXX=/usr/lib/ccache/g++ \
    LANG=C.UTF-8 \
    PATH=/usr/lib/ccache:$PATH

## Install Node.js
COPY --from=nsi /usr/local /usr/local

## Install build dependencies (codename-independent)
RUN apt-get update \
  && apt-get -y install \
    bison \
    ca-certificates \
    ccache \
    cmake \
    cmake-curses-gui \
    dh-python \
    doxygen \
    expect \
    flex \
    flip \
    gdal-bin \
    git \
    graphviz \
    grass-dev \
    libexiv2-dev \
    libexpat1-dev \
    libfcgi-dev \
    libgdal-dev \
    libgeos-dev \
    libgsl-dev \
    libpq-dev \
    libproj-dev \
    libprotobuf-dev \
    libqca-qt5-2-dev \
    libqca-qt5-2-plugins \
    libqscintilla2-qt5-dev \
    libqt5opengl5-dev \
    libqt5serialport5-dev \
    libqt5sql5-sqlite \
    libqt5svg5-dev \
    libqt5webkit5-dev \
    libqt5xmlpatterns5-dev \
    libqwt-qt5-dev \
    libspatialindex-dev \
    libspatialite-dev \
    libsqlite3-dev \
    libsqlite3-mod-spatialite \
    libyaml-tiny-perl \
    libzip-dev \
    libzstd-dev \
    lighttpd \
    locales \
    ninja-build \
    ocl-icd-opencl-dev \
    opencl-headers \
    pandoc \
    pkg-config \
    poppler-utils \
    protobuf-compiler \
    pyqt5-dev \
    pyqt5-dev-tools \
    pyqt5.qsci-dev \
    python3-all-dev \
    python3-autopep8 \
    python3-dev \
    python3-gdal \
    python3-jinja2 \
    python3-lxml \
    python3-mock \
    python3-nose2 \
    python3-owslib \
    python3-plotly \
    python3-psycopg2 \
    python3-pygments \
    python3-pyproj \
    python3-pyqt5 \
    python3-pyqt5.qsci \
    python3-pyqt5.qtmultimedia \
    python3-pyqt5.qtpositioning \
    python3-pyqt5.qtsql \
    python3-pyqt5.qtsvg \
    python3-pyqt5.qtwebkit \
    python3-sip \
    python3-termcolor \
    python3-yaml \
    qt3d-assimpsceneimport-plugin \
    qt3d-defaultgeometryloader-plugin \
    qt3d-gltfsceneio-plugin \
    qt3d-scene2d-plugin \
    qt3d5-dev \
    qtbase5-dev \
    qtbase5-private-dev \
    qtmultimedia5-dev \
    qtpositioning5-dev \
    qttools5-dev \
    qttools5-dev-tools \
    spawn-fcgi \
    xauth \
    xfonts-100dpi \
    xfonts-75dpi \
    xfonts-base \
    xfonts-scalable \
    xvfb

## Install build dependencies (codename-dependent)
RUN . /etc/os-release \
  && if echo "$VERSION_CODENAME" | grep -Eq "buster|bullseye|focal|jammy"; then \
    apt-get -y install \
      libpdal-dev \
      pdal; \
  fi \
  && if echo "$VERSION_CODENAME" | grep -Eq "buster|bullseye|focal"; then \
    apt-get -y install \
      python3-sip-dev \
      qt5keychain-dev; \
  fi \
  && if echo "$VERSION_CODENAME" | grep -Eq "buster|focal"; then \
    apt-get -y install \
      qt5-default; \
    git -C /var/tmp clone --depth 1 https://github.com/qgis/QGIS; \
  fi \
  && if echo "$VERSION_CODENAME" | grep -Eq "bookworm|sid|jammy|kinetic|lunar"; then \
    apt-get -y install \
      python3-pyqtbuild \
      qtkeychain-qt5-dev \
      sip-tools; \
  fi

RUN apt-get -y install \
    build-essential \
    curl

## Clean up Node.js installation
RUN bash -c 'rm -f /usr/local/bin/{docker-entrypoint.sh,yarn*}' \
  && bash -c 'rm -f /usr/local/{CHANGELOG.md,LICENSE,README.md}' \
  ## Enable corepack (Yarn, pnpm)
  && corepack enable

COPY scripts/start.sh /usr/bin/

WORKDIR /var/cache/qgis-build

RUN start.sh

## Uninstall Node.js
RUN if [ "$PREFIX" = "/usr/local" ]; then \
    bash -c 'rm -f /usr/local/bin/{corepack,node*,*npm,*npx,yarn*}'; \
    bash -c 'rm -rf /usr/local/{*/node*,*/*/node,share/.cache}'; \
    rm -f /usr/local/share/man/man1/node.1; \
    rm -f /usr/local/share/systemtap/tapset/node.stp; \
  fi

## Remove outdated SAGA GIS provider
RUN rm -rf "${PREFIX}/share/qgis/python/plugins/sagaprovider"

FROM scratch

LABEL org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://gitlab.b-data.ch/qgis/ggissi" \
      org.opencontainers.image.vendor="b-data GmbH" \
      org.opencontainers.image.authors="Olivier Benz <olivier.benz@b-data.ch>"

ARG PREFIX

COPY --from=builder ${PREFIX} ${PREFIX}
COPY --from=builder /usr/lib/python3/dist-packages/qgis /usr/lib/python3/dist-packages/qgis
