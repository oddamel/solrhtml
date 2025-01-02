
##Script
xsltproc --nonet -o _tilsolr_fab.22.3.4.xml --encoding UTF-8 journal_med_id.xslt fab.22.3.4.xml
xmllint -o _tilsolr_fab.22.3.4_pretty.xml --encode utf-8 --format _tilsolr_fab.22.3.4.xml

##import to solr xml
curl -X POST -H 'Content-Type: application/xml' 'https://ss929090-2ape21mx-eu-west-1-aws.searchstax.com/solr/juridika-lover-test/update?commit=true' --data-binary @_tilsolr_fab.22.3.4.xml -u $SOLR_USERNAME:$SOLR_PASSWORD

##delete
curl -X POST -H 'Content-Type: application/xml' 'https://ss929090-2ape21mx-eu-west-1-aws.searchstax.com/solr/juridika-lover-test/update?commit=true' \
--data-binary '<delete><id>lov/2009-06-19-97</id></delete>' \
-u $SOLR_USERNAME:$SOLR_PASSWORD
