#!/bin/sh

# add these two lines at the beginning, after the graph0 line
#   <script xlink:href="../SVGPan.js"/>
#   <g id="viewport" transform="translate(0,0)">

# add </g> before </svg>

perl -p -i -e 's/^<svg.*$/<svg/; s/^<g id="graph0/<script xlink:href="..\/SVGPan.js"\/>\n<g id="viewport" transform="translate(0,0)">\n<g id="graph0/; s/<\/svg>/<\/g>\n<\/svg>/' $1
