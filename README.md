
##Script
xsltproc -o dyrevelderdsloven_med_id.xml --encoding UTF-8 lov_med_id.xslt dyrevelferdsloven.html
xmllint -o dyre_pretty.xml --encode utf-8 --format dyrevelderdsloven_med_id.xml

xsltproc -o dyrevelderdsloven_med_id.xml --encoding UTF-8 lov_med_id.xslt dyrevelferdsloven.html
xmllint -o dyre_pretty.xml --encode utf-8 --format dyrevelderdsloven_med_id.xml

xsltproc -o dyrevelderdsloven_med_id.xml --encoding UTF-8 lov_med_id_hieraki.xslt dyrevelferdsloven.html
xsltproc -o folketrygdloven_med_id.xml --encoding UTF-8 lov_med_id_hieraki.xslt folketrygdloven.html
xmllint -o folketrygdloven_med_id_pretty.xml --encode utf-8 --format folketrygdloven_med_id.xml

xsltproc -o akvakulturloven_med_id.xml  --encoding UTF-8 lov_med_id_1111.xslt akvakulturloven.html
xmllint -o akvakulturloven_med_id_pretty.xml --encode utf-8 --format akvakulturloven_med_id.xml


##import to solr json
curl -X POST -H 'Content-Type: application/json' https://ss929090-2ape21mx-eu-west-1-aws.searchstax.com/solr/juridika-lover-test/update?commit=true' --data-binary @dyrevelferdsloven.json

##import to solr xml
curl -X POST -H 'Content-Type: application/xml' 'https://ss929090-2ape21mx-eu-west-1-aws.searchstax.com/solr/juridika-lover-test/update?commit=true' --data-binary @dyre_pretty.xml -u $SOLR_USERNAME:$SOLR_PASSWORD
curl -X POST -H 'Content-Type: application/xml' 'https://ss929090-2ape21mx-eu-west-1-aws.searchstax.com/solr/juridika-lover-test/update?commit=true' --data-binary @akvakulturloven_med_id_pretty.xml -u $SOLR_USERNAME:$SOLR_PASSWORD

##delete
curl -X POST -H 'Content-Type: application/xml' 'https://ss929090-2ape21mx-eu-west-1-aws.searchstax.com/solr/juridika-lover-test/update?commit=true' \
--data-binary '<delete><id>lov/2009-06-19-97</id></delete>' \
-u $SOLR_USERNAME:$SOLR_PASSWORD


xsltproc -o dyrevelderdsloven-op.xml --encoding UTF-8 4-alle-lover.xslt dyrevelferdsloven.html
xmllint -o dyrevelderdsloven-op-pretty.xml --encode utf-8 --format dyrevelderdsloven-op.xml

curl -X POST -H 'Content-Type: application/xml' 'https://ss929090-2ape21mx-eu-west-1-aws.searchstax.com/solr/juridika-lover-test/update?commit=true' --data-binary @lov-folketrygdloven-op.xml -u $SOLR_USERNAME:$SOLR_PASSWORD

