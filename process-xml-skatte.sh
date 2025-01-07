#!/usr/bin/env bash

# Eksempel: ./convert_lov.sh dyrevelferdsloven
# Skriptet lager da "2_solr/dyrevelferdsloven-op.xml" og "2_solr/dyrevelferdsloven-op-pretty.xml"

input="$1"

# Add .html if missing
[[ $input != *.html ]] && input="${input}.html"

# Remove .html to get prefix
prefix="${input%.html}"
prefix="${prefix##*/}"

java -jar ~/saxon/saxon-he-12.5.jar \
     -s:"lovdata/${input}" \
     -xsl:lov_med_id_hieraki_dyn_skatteloven.xslt \
     -o:"2_solr/lov-${prefix}-dyn-temp.xml"

xmllint -o "2_solr/lov-${prefix}-dyn.xml" \
         --encode utf-8 \
         --format "2_solr/lov-${prefix}-dyn-temp.xml"
rm "2_solr/lov-${prefix}-dyn-temp.xml"
