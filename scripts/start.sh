#!/bin/bash
# Copyright (c) 2023 b-data GmbH.
# Distributed under the terms of the MIT License.

set -e

# Test if PREFIX location is whithin limits
if [[ ! "$PREFIX" == "/usr/local" && ! "$PREFIX" =~ ^"/opt" ]]; then
  echo "ERROR:  PREFIX set to '$PREFIX'. Must either be '/usr/local' or within '/opt'."
  exit 1
fi

# Download and extract source code
curl -sSL https://download.qgis.org/downloads/qgis-"$QGIS_VERSION".tar.bz2 \
  -o "/tmp/qgis-$QGIS_VERSION.tar.bz2"
tar xf "/tmp/qgis-$QGIS_VERSION.tar.bz2" --no-same-owner -C /tmp

CMAKE_EXTRA_ARGS=()

# Automatically configure the path to search for grass installation
if [[ "$WITH_GRASS7" == "ON" || "$WITH_GRASS8" == "ON" ]]; then
  CMAKE_EXTRA_ARGS+=(
    "-DGRASS_PREFIX$(grass --config version | cut -b 1)=$(grass --config path)"
  )
fi

# shellcheck disable=SC1091
. /etc/os-release

# Enable compiling with 3D on old Debian based distributions
if echo "$VERSION_CODENAME" | grep -Eq "buster|focal"; then
  CMAKE_EXTRA_ARGS+=(
    "-DCMAKE_PREFIX_PATH=/var/tmp/QGIS/external/qt3dextra-headers/cmake"
    "-DQT5_3DEXTRA_INCLUDE_DIR=/var/tmp/QGIS/external/qt3dextra-headers"
    "-DQT5_3DEXTRA_LIBRARY=/usr/lib/$(uname -m)-linux-gnu/libQt53DExtras.so"
    "-DQt53DExtras_DIR=/var/tmp/QGIS/external/qt3dextra-headers/cmake/Qt53DExtras"
  )
fi

# Build and install
cmake \
  -GNinja \
  -DWITH_3D="$WITH_3D" \
  -DWITH_ANALYSIS="$WITH_ANALYSIS" \
  -DWITH_APIDOC="$WITH_APIDOC" \
  -DWITH_ASAN="$WITH_ASAN" \
  -DWITH_ASTYLE="$WITH_ASTYLE" \
  -DWITH_AUTH="$WITH_AUTH" \
  -DWITH_BINDINGS="$WITH_BINDINGS" \
  -DWITH_CLAZY="$WITH_CLAZY" \
  -DWITH_COPC="$WITH_COPC" \
  -DWITH_CORE="$WITH_CORE" \
  -DWITH_CRASH_HANDLER="$WITH_CRASH_HANDLER" \
  -DWITH_CUSTOM_WIDGETS="$WITH_CUSTOM_WIDGETS" \
  -DWITH_DESKTOP="$WITH_DESKTOP" \
  -DWITH_DRACO="$WITH_DRACO" \
  -DWITH_EPT="$WITH_EPT" \
  -DWITH_GRASS7="$WITH_GRASS7" \
  -DWITH_GRASS8="$WITH_GRASS8" \
  -DWITH_GRASS_PLUGIN="$WITH_GRASS_PLUGIN" \
  -DWITH_GSL="$WITH_GSL" \
  -DWITH_GUI="$WITH_GUI" \
  -DWITH_HANA="$WITH_HANA" \
  -DWITH_INTERNAL_LAZPERF="$WITH_INTERNAL_LAZPERF" \
  -DWITH_INTERNAL_MDAL="$WITH_INTERNAL_MDAL" \
  -DWITH_INTERNAL_O2="$WITH_INTERNAL_O2" \
  -DWITH_INTERNAL_POLY2TRI="$WITH_INTERNAL_POLY2TRI" \
  -DWITH_OAUTH2_PLUGIN="$WITH_OAUTH2_PLUGIN" \
  -DWITH_ORACLE="$WITH_ORACLE" \
  -DWITH_PDAL="$WITH_PDAL" \
  -DWITH_PDF4QT="$WITH_PDF4QT" \
  -DWITH_POSTGRESQL="$WITH_POSTGRESQL" \
  -DWITH_PY_COMPILE="$WITH_PY_COMPILE" \
  -DWITH_QGIS_PROCESS="$WITH_QGIS_PROCESS" \
  -DWITH_QSCIAPI="$WITH_QSCIAPI" \
  -DWITH_QSPATIALITE="$WITH_QSPATIALITE" \
  -DWITH_QTGAMEPAD="$DWITH_QTGAMEPAD" \
  -DWITH_QTPRINTER="$WITH_QTPRINTER" \
  -DWITH_QT5SERIALPORT="$WITH_QT5SERIALPORT" \
  -DWITH_QTSERIALPORT="$WITH_QTSERIALPORT" \
  -DWITH_QTWEBENGINE="$WITH_QTWEBENGINE" \
  -DWITH_QTWEBKIT="$WITH_QTWEBKIT" \
  -DWITH_QUICK="$WITH_QUICK" \
  -DWITH_QWTPOLAR="$WITH_QWTPOLAR" \
  -DWITH_SERVER="$WITH_SERVER" \
  -DWITH_SERVER_LANDINGPAGE_WEBAPP="$WITH_SERVER_LANDINGPAGE_WEBAPP" \
  -DWITH_SERVER_PLUGINS="$WITH_SERVER_PLUGINS" \
  -DWITH_SPATIALITE="$WITH_SPATIALITE" \
  -DWITH_STAGED_PLUGINS="$WITH_STAGED_PLUGINS" \
  -DWITH_THREAD_LOCAL="$WITH_THREAD_LOCAL" \
  -DBINDINGS_GLOBAL_INSTALL=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DDISABLE_DEPRECATED=ON \
  -DENABLE_TESTS=OFF \
  -DSUPPRESS_QT_WARNINGS=ON \
  -DUSE_CCACHE=OFF \
  -DUSE_OPENCL=ON \
  "${CMAKE_EXTRA_ARGS[@]}" \
  "/tmp/qgis-$QGIS_VERSION"

if [[ "$MODE" == "install" ]]; then
  mkdir -p "$PREFIX"
  ninja "$MODE"

  # Install Python bindings to QGIS
  if [[ -d /usr/lib/python3/dist-packages/qgis ]]; then
    mkdir -p /tmp/usr/lib/python3/dist-packages
    cp -a /usr/lib/python3/dist-packages/qgis \
      /tmp/usr/lib/python3/dist-packages
  fi

  # Install QGIS server landingpage
  if [[ -d /var/cache/qgis-build/output/data/resources/server/api/ogc/static/landingpage ]]; then
    if [[ ! -d "$PREFIX/share/qgis/resources/server/api/ogc/static/landingpage" ]]; then
      mkdir -p "$PREFIX/share/qgis/resources/server/api/ogc/static"
      cp -a /var/cache/qgis-build/output/data/resources/server/api/ogc/static/landingpage \
        "$PREFIX/share/qgis/resources/server/api/ogc/static"
    fi
  fi
else
  ninja "$MODE"

  # Remove QGIS server landingpage
  if [[ "$MODE" == "uninstall" ]]; then
    if [[ -d "$PREFIX/share/qgis/resources/server/api/ogc/static/landingpage" ]]; then
      rm -rf "$PREFIX/share/qgis/resources/server/api/ogc/static/landingpage"
    fi
  fi
fi
