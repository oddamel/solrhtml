#!/usr/bin/env bash

# Eksempel: ./convert_lov.sh dyrevelferdsloven.html
# Skriptet lager da "dyrevelferdsloven-op.xml" og "dyrevelferdsloven-op-pretty.xml"

input="$1"

# Add .html if missing
[[ $input != *.html ]] && input="${input}.html"

# Remove .html to get prefix
prefix="${input%.html}"

xsltproc -o "lov-${prefix}-op-temp.xml" \
         --encoding UTF-8 \
         lov_med_id_hieraki_op.xslt \
         "${input}"

xmllint -o "lov-${prefix}-op.xml" \
         --encode utf-8 \
         --format "lov-${prefix}-op-temp.xml"
rm "lov-${prefix}-op-temp.xml"

