#!/bin/bash
mkdir -p tiles
vips dzsave data/AGN_map_2018.pdf[dpi=600] tiles --layout google --suffix .png --vips-progress