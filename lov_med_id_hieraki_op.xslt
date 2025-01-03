<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">
    <!--
      Oppdatert XSLT for Lovdata -> Solr, nå med underkapittel (nodeType=subchapter).
      Strukturen er:
        del       -> part
        underdel  -> subpart
        kapittel  -> chapter
        underkap  -> subchapter
        paragraf  -> section
        ledd      -> subsection
    -->

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

    <!-- ========== 1) ROOT-TEMPLATE ========== -->
    <xsl:template match="/">
        <add>
            <doc>
                <!-- ID for selve loven, basert på "LOV-xxxx" -->
                <field name="id">
                    <xsl:value-of select="concat('lov-', substring-after(//dd[@class='legacyID'], 'LOV-'))"/>
                </field>
                <field name="title">
                    <xsl:value-of select="//dd[@class='title']"/>
                </field>
                <field name="nodeType">law</field>
                <field name="source">Lovdata</field>

                <!-- Timestamp om ønskelig -->
                <field name="timestamp">
                    <xsl:value-of select="substring-before(//dd[@class='xmlGenerated'], ' ')"/>
                </field>

                <!-- Start prosessering av <section>, parentId => "lov-XXXX" -->
                <xsl:apply-templates select="//section">
                    <xsl:with-param name="parentId"
                                    select="concat('lov-', substring-after(//dd[@class='legacyID'], 'LOV-'))"/>
                </xsl:apply-templates>
            </doc>
        </add>
    </xsl:template>

    <!-- ========== 2) SECTION ========== -->
    <xsl:template match="section">
        <xsl:param name="parentId"/>

        <!-- Hent @data-name, f.eks. "delIII", "kapI", "underkap2" ... -->
        <xsl:variable name="dnRaw" select="@data-name"/>
        <xsl:variable name="dnClean" select="translate($dnRaw, '_', '-')"/>

        <xsl:choose>
            <!-- DEL -->
            <xsl:when test="contains($dnClean, 'del')">
                <xsl:variable name="suffix" select="substring-after($dnClean, 'del')"/>
                <xsl:variable name="currentId" select="concat($parentId, '/del-', $suffix)"/>

                <doc>
                    <field name="id"><xsl:value-of select="$currentId"/></field>
                    <field name="title"><xsl:value-of select="h2"/></field>
                    <field name="nodeType">part</field>
                    <field name="_nest_parent_">
                        <xsl:value-of select="$parentId"/>
                    </field>

                    <field name="bodytext">
                        <xsl:value-of select="."/>
                    </field>
                    <field name="bodytext_html">
                        <xsl:copy-of select="node()"/>
                    </field>
                    <field name="text_ngram">
                        <xsl:value-of select="."/>
                    </field>

                    <xsl:apply-templates select="section|article">
                        <xsl:with-param name="parentId" select="$currentId"/>
                    </xsl:apply-templates>
                </doc>
            </xsl:when>

            <!-- UNDERDEL -->
            <xsl:when test="contains($dnClean, 'underdel')">
                <xsl:variable name="suffix" select="substring-after($dnClean, 'underdel')"/>
                <xsl:variable name="currentId" select="concat($parentId, '/underdel-', $suffix)"/>

                <doc>
                    <field name="id"><xsl:value-of select="$currentId"/></field>
                    <field name="title"><xsl:value-of select="h2"/></field>
                    <field name="nodeType">subpart</field>
                    <field name="_nest_parent_">
                        <xsl:value-of select="$parentId"/>
                    </field>

                    <field name="bodytext">
                        <xsl:value-of select="."/>
                    </field>
                    <field name="bodytext_html">
                        <xsl:copy-of select="node()"/>
                    </field>
                    <field name="text_ngram">
                        <xsl:value-of select="."/>
                    </field>

                    <xsl:apply-templates select="section|article">
                        <xsl:with-param name="parentId" select="$currentId"/>
                    </xsl:apply-templates>
                </doc>
            </xsl:when>

            <!-- KAPITTEL -->
            <xsl:when test="contains($dnClean, 'kap') and not(contains($dnClean, 'underkap'))">
                <!--
                  NB! `contains($dnClean, 'kap')` vil også treffe "underkap",
                  så vi legger til en test for `not(contains($dnClean,'underkap'))`
                  for å ikke kollidere med underkapittel.
                -->
                <xsl:variable name="suffix" select="substring-after($dnClean, 'kap')"/>
                <xsl:variable name="currentId" select="concat($parentId, '/kapittel-', $suffix)"/>

                <doc>
                    <field name="id"><xsl:value-of select="$currentId"/></field>
                    <field name="title"><xsl:value-of select="h2"/></field>
                    <field name="nodeType">chapter</field>
                    <field name="_nest_parent_">
                        <xsl:value-of select="$parentId"/>
                    </field>

                    <field name="bodytext">
                        <xsl:value-of select="."/>
                    </field>
                    <field name="bodytext_html">
                        <xsl:copy-of select="node()"/>
                    </field>
                    <field name="text_ngram">
                        <xsl:value-of select="."/>
                    </field>

                    <xsl:apply-templates select="section|article">
                        <xsl:with-param name="parentId" select="$currentId"/>
                    </xsl:apply-templates>
                </doc>
            </xsl:when>

            <!-- UNDERKAPITTEL -->
            <xsl:when test="contains($dnClean, 'underkap')">
                <xsl:variable name="suffix" select="substring-after($dnClean, 'underkap')"/>
                <xsl:variable name="currentId" select="concat($parentId, '/underkapittel-', $suffix)"/>

                <doc>
                    <field name="id"><xsl:value-of select="$currentId"/></field>
                    <field name="title"><xsl:value-of select="h2"/></field>
                    <!-- nodeType = subchapter -->
                    <field name="nodeType">subchapter</field>
                    <field name="_nest_parent_">
                        <xsl:value-of select="$parentId"/>
                    </field>

                    <field name="bodytext">
                        <xsl:value-of select="."/>
                    </field>
                    <field name="bodytext_html">
                        <xsl:copy-of select="node()"/>
                    </field>
                    <field name="text_ngram">
                        <xsl:value-of select="."/>
                    </field>

                    <!-- Rekursiv prosessering av children -->
                    <xsl:apply-templates select="section|article">
                        <xsl:with-param name="parentId" select="$currentId"/>
                    </xsl:apply-templates>
                </doc>
            </xsl:when>

            <!-- HVIS INGENTING TRAFF (eksempel: "annex1") => re-apply barne-noder -->
            <xsl:otherwise>
                <xsl:apply-templates select="section|article">
                    <xsl:with-param name="parentId" select="$parentId"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ========== 3) ARTICLE class="legalArticle" (Paragraf) ========== -->
    <xsl:template match="article[@class='legalArticle']">
        <xsl:param name="parentId"/>

        <doc>
            <field name="id">
                <!-- "§4-b" => "/paragraf-4-b" -->
                <xsl:value-of select="
                  concat($parentId, '/paragraf-',
                    translate(substring-after(@data-partID, '§'), '_', '-')
                  )
                "/>
            </field>
            <field name="title">
                <!-- "§4-b Tittel" -->
                <xsl:value-of select="
                  concat(h3/span[@class='legalArticleValue'], ' ',
                         h3/span[@class='legalArticleTitle'])
                "/>
            </field>
            <field name="nodeType">section</field>
            <field name="_nest_parent_">
                <xsl:value-of select="$parentId"/>
            </field>

            <field name="bodytext">
                <xsl:value-of select="."/>
            </field>
            <field name="bodytext_html">
                <xsl:copy-of select="node()"/>
            </field>
            <field name="text_ngram">
                <xsl:value-of select="."/>
            </field>

            <!-- Ledd: <article class="legalP"> -->
            <xsl:apply-templates select=".//article[@class='legalP']">
                <xsl:with-param name="parentId" select="
                  concat($parentId, '/paragraf-',
                         translate(substring-after(@data-partID, '§'), '_', '-')
                  )
                "/>
            </xsl:apply-templates>
        </doc>
    </xsl:template>

    <!-- ========== 4) LEDD: <article class="legalP"> ========== -->
    <xsl:template match="article[@class='legalP']">
        <xsl:param name="parentId"/>

        <doc>
            <field name="id">
                <!-- Teller ledd i rekkefølge. -->
                <xsl:value-of select="concat($parentId, '/ledd-', position())"/>
            </field>
            <field name="nodeType">subsection</field>
            <field name="_nest_parent_">
                <xsl:value-of select="$parentId"/>
            </field>

            <field name="bodytext">
                <xsl:value-of select="."/>
            </field>
            <field name="bodytext_html">
                <xsl:copy-of select="node()"/>
            </field>
            <field name="text_ngram">
                <xsl:value-of select="."/>
            </field>
        </doc>
    </xsl:template>

    <!-- ========== 5) GENERISK MATCH, ignorer alt annet ========== -->
    <xsl:template match="node()">
        <!-- Tom for å unngå støy -->
    </xsl:template>

</xsl:stylesheet>
