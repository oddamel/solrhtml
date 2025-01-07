<xsl:stylesheet
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        version="1.0">

    <!--
      Basic XSLT (1.0) for transforming a Lovdata HTML file into
      nested Solr <doc> elements:
        - The root doc is nodeType="law"
        - <section data-name="delX|underdelX|kapX|underkapX" => part/subpart/chapter/subchapter
        - <article class="legalArticle"> => paragraph (section)
        - <article class="legalP"> => ledd (subsection)
        - <article class="changesToParent"> => skip or optionally store as note

      NOTE:
      XSLT 1.0 doesn't let us do node-set operations inside concat() easily.
      So we store text in variables before concatenation.
    -->

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

    <!--=====================================
         1)  ROOT-TEMPLATE: match="/"
        =====================================-->
    <xsl:template match="/">
        <add>
            <doc>
                <!-- The entire law doc.
                     Example ID: "lov-1999-03-26-14"
                     from e.g. <dd class="legacyID">LOV-1999-03-26-14</dd>
                -->
                <field name="id">
                    <xsl:value-of
                            select="concat('lov-', substring-after(//dd[@class='legacyID'], 'LOV-'))"/>
                </field>

                <field name="title">
                    <xsl:value-of select="//dd[@class='title']"/>
                </field>

                <field name="nodeType">law</field>
                <field name="source">Lovdata</field>

                <!-- optional: timestamp from e.g. <dd class="xmlGenerated"> -->
                <field name="timestamp">
                    <xsl:value-of select="substring-before(//dd[@class='xmlGenerated'], ' ')"/>
                </field>

                <!-- Recurse all <section> -->
                <xsl:apply-templates select="//section">
                    <!-- pass param parentId => top-level "lov-XXXX" -->
                    <xsl:with-param name="parentId"
                                    select="concat('lov-', substring-after(//dd[@class='legacyID'], 'LOV-'))"/>
                </xsl:apply-templates>
            </doc>
        </add>
    </xsl:template>


    <!--======================================================
         2)  MATCH <section> => detect del/underdel/kap/underkap
        ======================================================-->
    <xsl:template match="section">
        <xsl:param name="parentId"/>

        <!-- Safe string transformations for @data-name -->
        <xsl:variable name="dnRaw" select="@data-name"/>
        <xsl:variable name="dnClean" select="translate($dnRaw, '_', '-')"/>

        <xsl:choose>
            <!-- Detect "del" but exclude "underdel" -->
            <xsl:when test="contains($dnClean, 'del')
                            and not(contains($dnClean, 'underdel'))">
                <xsl:variable name="suffix" select="substring-after($dnClean, 'del')"/>
                <xsl:variable name="currentId"
                              select="concat($parentId, '/del-', $suffix)"/>

                <doc>
                    <field name="id">
                        <xsl:value-of select="$currentId"/>
                    </field>
                    <field name="title">
                        <!-- just take <h2> text -->
                        <xsl:value-of select="h2"/>
                    </field>
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

                    <!-- Recurse deeper sections/articles -->
                    <xsl:apply-templates select="section|article">
                        <xsl:with-param name="parentId" select="$currentId"/>
                    </xsl:apply-templates>
                </doc>
            </xsl:when>

            <!-- Detect "underdel" -->
            <xsl:when test="contains($dnClean, 'underdel')">
                <xsl:variable name="suffix" select="substring-after($dnClean, 'underdel')"/>
                <xsl:variable name="currentId"
                              select="concat($parentId, '/underdel-', $suffix)"/>

                <doc>
                    <field name="id">
                        <xsl:value-of select="$currentId"/>
                    </field>
                    <field name="title">
                        <xsl:value-of select="h2"/>
                    </field>
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

            <!-- Detect "kap" => "chapter," exclude "underkap" -->
            <xsl:when test="contains($dnClean, 'kap')
                            and not(contains($dnClean, 'underkap'))">
                <xsl:variable name="suffix" select="substring-after($dnClean, 'kap')"/>
                <xsl:variable name="currentId"
                              select="concat($parentId, '/kapittel-', $suffix)"/>

                <doc>
                    <field name="id">
                        <xsl:value-of select="$currentId"/>
                    </field>
                    <field name="title">
                        <xsl:value-of select="h2"/>
                    </field>
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

            <!-- Detect "underkap" => subchapter -->
            <xsl:when test="contains($dnClean, 'underkap')">
                <xsl:variable name="suffix" select="substring-after($dnClean, 'underkap')"/>
                <xsl:variable name="currentId"
                              select="concat($parentId, '/underkapittel-', $suffix)"/>

                <doc>
                    <field name="id">
                        <xsl:value-of select="$currentId"/>
                    </field>
                    <field name="title">
                        <xsl:value-of select="h2"/>
                    </field>
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

                    <xsl:apply-templates select="section|article">
                        <xsl:with-param name="parentId" select="$currentId"/>
                    </xsl:apply-templates>
                </doc>
            </xsl:when>

            <!-- Otherwise pass through children without generating a doc -->
            <xsl:otherwise>
                <xsl:apply-templates select="section|article">
                    <xsl:with-param name="parentId" select="$parentId"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!--=====================================
         3) PARAGRAF: <article class="legalArticle">
        =====================================-->
    <xsl:template match="article[@class='legalArticle']">
        <xsl:param name="parentId"/>

        <!-- For the ID, we check @data-partID (like §2-40 => /paragraf-2-40). -->
        <doc>
            <field name="id">
                <xsl:choose>
                    <xsl:when test="@data-partID">
                        <xsl:value-of select="
                          concat(
                            $parentId,
                            '/paragraf-',
                            translate( substring-after(@data-partID, '§'), '_', '-')
                          )
                        "/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- fallback if no data-partID -->
                        <xsl:value-of
                                select="concat($parentId, '/paragraf-', generate-id())"/>
                    </xsl:otherwise>
                </xsl:choose>
            </field>

            <field name="title">
                <!-- XSLT 1.0 approach: we gather "Value" text and "Title" text
                     from h1..h4 separately and then concatenate them.
                -->
                <xsl:variable name="valText">
                    <!-- Use the first matching 'legalArticleValue' if multiple -->
                    <xsl:for-each select="
                      (.//h1/span[@class='legalArticleValue'] |
                       .//h2/span[@class='legalArticleValue'] |
                       .//h3/span[@class='legalArticleValue'] |
                       .//h4/span[@class='legalArticleValue'])[1]
                    ">
                        <xsl:value-of select="."/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="ttlText">
                    <!-- The first matching 'legalArticleTitle' if multiple -->
                    <xsl:for-each select="
                      (.//h1/span[@class='legalArticleTitle'] |
                       .//h2/span[@class='legalArticleTitle'] |
                       .//h3/span[@class='legalArticleTitle'] |
                       .//h4/span[@class='legalArticleTitle'])[1]
                    ">
                        <xsl:value-of select="."/>
                    </xsl:for-each>
                </xsl:variable>
                <!-- Then just output valText + space + ttlText -->
                <xsl:if test="$valText">
                    <xsl:value-of select="$valText"/>
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:value-of select="$ttlText"/>
            </field>

            <field name="nodeType">section</field>
            <field name="_nest_parent_">
                <xsl:value-of select="$parentId"/>
            </field>

            <field name="bodytext">
                <!-- plain text of the entire article -->
                <xsl:value-of select="."/>
            </field>
            <field name="bodytext_html">
                <!-- copy the entire subtree in HTML -->
                <xsl:copy-of select="node()"/>
            </field>
            <field name="text_ngram">
                <xsl:value-of select="."/>
            </field>

            <!-- Recurse to <article class="legalP"> for "ledd" -->
            <xsl:apply-templates select="article[@class='legalP']">
                <xsl:with-param name="parentId">
                    <xsl:choose>
                        <xsl:when test="@data-partID">
                            <xsl:value-of select="
                              concat(
                                $parentId,
                                '/paragraf-',
                                translate( substring-after(@data-partID, '§'), '_', '-')
                              )
                            "/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of
                                    select="concat($parentId, '/paragraf-', generate-id())"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:apply-templates>

            <!-- Optionally skip <article class="changesToParent"> or store it. -->
            <xsl:apply-templates select="article[@class='changesToParent']">
                <xsl:with-param name="parentId" select="$parentId"/>
            </xsl:apply-templates>
        </doc>
    </xsl:template>


    <!--===================================
         4) LEDD: <article class="legalP">
        ===================================-->
    <xsl:template match="article[@class='legalP']">
        <xsl:param name="parentId"/>

        <doc>
            <field name="id">
                <!-- position() among sibling <article class="legalP"> -->
                <xsl:value-of
                        select="concat($parentId, '/ledd-', position())"/>
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


    <!--=============================================
         5) CHANGESTOPARENT: <article class="changesToParent">
        =============================================-->
    <xsl:template match="article[@class='changesToParent']" priority="2">
        <xsl:param name="parentId"/>

        <!--
           By default, we skip these editorial notes.
           If you do want them, produce a doc or
           store them inside the paragraf doc, etc.
        -->
        <!-- e.g., skip entirely -->
    </xsl:template>


    <!--====================================
         6) DEFAULT: ignore other nodes
        ====================================-->
    <xsl:template match="node()">
        <!-- do nothing -->
    </xsl:template>

</xsl:stylesheet>
