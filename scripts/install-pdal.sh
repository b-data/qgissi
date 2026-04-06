#!/bin/bash
# Copyright (c) 2026 b-data GmbH
# Distributed under the terms of the MIT License.

set -e

if [ "$WITH_PDAL" = "TRUE" ]; then
  # Test if PREFIX location is whithin limits
  if [[ ! "$PREFIX" == "/usr/local" && ! "$PREFIX" =~ ^"/opt" ]]; then
    echo "ERROR:  PREFIX set to '$PREFIX'. Must either be '/usr/local' or within '/opt'."
    exit 1
  fi

  # Download and extract source code
  curl -sSL https://github.com/PDAL/PDAL/releases/download/"$PDAL_VERSION"/PDAL-"$PDAL_VERSION"-src.tar.gz \
    -o "/tmp/PDAL-$PDAL_VERSION.tar.gz"
  mkdir "/tmp/PDAL-$PDAL_VERSION"
  tar xfz "/tmp/PDAL-$PDAL_VERSION.tar.gz" \
    --no-same-owner \
    --strip-components=1 \
    -C "/tmp/PDAL-$PDAL_VERSION"

  cmake \
    -GNinja \
    -DBUILD_PLUGIN_PGPOINTCLOUD=ON \
    -DBUILD_PLUGIN_ICEBRIDGE=ON \
    -DBUILD_PLUGIN_HDF=ON \
    -DBUILD_PLUGIN_DRACO=ON \
    -DBUILD_PLUGIN_E57=ON \
    -DBUILD_PGPOINTCLOUD_TESTS=OFF \
    -DWITH_ZSTD=ON \
    -DWITH_TESTS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    "/tmp/PDAL-$PDAL_VERSION"

  if [[ "$MODE" == "install" ]]; then
    mkdir -p "$PREFIX"
    ninja "$MODE"
  fi
fi