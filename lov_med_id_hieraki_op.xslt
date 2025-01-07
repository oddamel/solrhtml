<xsl:stylesheet
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        version="1.0"
>
    <!--
      XSLT Explanation (no double-hyphens):
      This XSLT transforms Lovdata HTML into <doc> elements for Solr with hierarchical IDs.
      We rely on @data-name to check if it includes 'del', 'underdel', 'kap', 'underkap'.
      If it's not found, we simply pass it down to children.
      Paragraphs <article class='legalArticle'> => nodeType="section"
      Ledd <article class='legalP'> => nodeType="subsection"
      No consecutive hyphens in comments!
    -->

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

    <!-- (1) ROOT TEMPLATE -->
    <xsl:template match="/">
        <add>
            <doc>
                <!-- ID for entire law -->
                <field name="id">
                    <xsl:value-of select="concat('lov-', substring-after(//dd[@class='legacyID'], 'LOV-'))"/>
                </field>
                <field name="title">
                    <xsl:value-of select="//dd[@class='title']"/>
                </field>
                <field name="nodeType">law</field>
                <field name="source">Lovdata</field>
                <field name="timestamp">
                    <xsl:value-of select="substring-before(//dd[@class='xmlGenerated'],' ')"/>
                </field>

                <!-- Recurse on all <section> top-level, passing parent = entire-lov ID -->
                <xsl:apply-templates select="//section">
                    <xsl:with-param name="parentId"
                                    select="concat('lov-', substring-after(//dd[@class='legacyID'], 'LOV-'))"/>
                </xsl:apply-templates>
            </doc>
        </add>
    </xsl:template>

    <!-- (2) SECTION => might be del, underdel, kapittel, underkapittel -->
    <xsl:template match="section">
        <xsl:param name="parentId"/>

        <xsl:variable name="dnRaw" select="@data-name"/>
        <!-- remove underscores so "kap_II" => "kap-II" -->
        <xsl:variable name="dnClean" select="translate($dnRaw, '_', '-')"/>

        <xsl:choose>
            <!-- DEL -->
            <xsl:when test="contains($dnClean, 'del')">
                <xsl:variable name="suffix" select="substring-after($dnClean, 'del')"/>
                <xsl:variable name="currentId" select="concat($parentId, '/del-', $suffix)"/>

                <doc>
                    <field name="id"><xsl:value-of select="$currentId"/></field>
                    <field name="title">
                        <xsl:value-of select="(h1|h2|h3|h4|h5|h6)[1]"/>
                    </field>
                    <field name="nodeType">part</field>
                    <field name="_nest_parent_"><xsl:value-of select="$parentId"/></field>
                    <field name="bodytext"><xsl:value-of select="."/></field>
                    <field name="bodytext_html">
                        <xsl:copy-of select="node()"/>
                    </field>
                    <field name="text_ngram"><xsl:value-of select="."/></field>

                    <!-- Recurse to child sections/articles -->
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
                    <field name="title">
                        <xsl:value-of select="(h1|h2|h3|h4|h5|h6)[1]"/>
                    </field>
                    <field name="nodeType">subpart</field>
                    <field name="_nest_parent_"><xsl:value-of select="$parentId"/></field>
                    <field name="bodytext"><xsl:value-of select="."/></field>
                    <field name="bodytext_html">
                        <xsl:copy-of select="node()"/>
                    </field>
                    <field name="text_ngram"><xsl:value-of select="."/></field>

                    <xsl:apply-templates select="section|article">
                        <xsl:with-param name="parentId" select="$currentId"/>
                    </xsl:apply-templates>
                </doc>
            </xsl:when>

            <!-- KAPITTEL (not underkap) -->
            <xsl:when test="contains($dnClean, 'kap') and not(contains($dnClean, 'underkap'))">
                <xsl:variable name="suffix" select="substring-after($dnClean, 'kap')"/>
                <xsl:variable name="currentId" select="concat($parentId, '/kapittel-', $suffix)"/>

                <doc>
                    <field name="id"><xsl:value-of select="$currentId"/></field>
                    <field name="title">
                        <xsl:value-of select="(h1|h2|h3|h4|h5|h6)[1]"/>
                    </field>
                    <field name="nodeType">chapter</field>
                    <field name="_nest_parent_"><xsl:value-of select="$parentId"/></field>
                    <field name="bodytext"><xsl:value-of select="."/></field>
                    <field name="bodytext_html">
                        <xsl:copy-of select="node()"/>
                    </field>
                    <field name="text_ngram"><xsl:value-of select="."/></field>

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
                    <field name="title">
                        <xsl:value-of select="(h1|h2|h3|h4|h5|h6)[1]"/>
                    </field>
                    <field name="nodeType">subchapter</field>
                    <field name="_nest_parent_"><xsl:value-of select="$parentId"/></field>
                    <field name="bodytext"><xsl:value-of select="."/></field>
                    <field name="bodytext_html">
                        <xsl:copy-of select="node()"/>
                    </field>
                    <field name="text_ngram"><xsl:value-of select="."/></field>

                    <xsl:apply-templates select="section|article">
                        <xsl:with-param name="parentId" select="$currentId"/>
                    </xsl:apply-templates>
                </doc>
            </xsl:when>

            <!-- Otherwise: pass children with same parentId -->
            <xsl:otherwise>
                <xsl:apply-templates select="section|article">
                    <xsl:with-param name="parentId" select="$parentId"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- (3) article.legalArticle => paragraf (nodeType=section) -->
    <xsl:template match="article[@class='legalArticle']">
        <xsl:param name="parentId"/>

        <doc>
            <field name="id">
                <xsl:value-of select="
          concat(
            $parentId,
            '/paragraf-',
            translate(substring-after(@data-partID, '§'), '_', '-')
          )
        "/>
            </field>
            <field name="title">
                <xsl:value-of select="
          concat(
            h3/span[@class='legalArticleValue'],
            ' ',
            h3/span[@class='legalArticleTitle']
          )
        "/>
            </field>
            <field name="nodeType">section</field>
            <field name="_nest_parent_">
                <xsl:value-of select="$parentId"/>
            </field>

            <field name="bodytext"><xsl:value-of select="."/></field>
            <field name="bodytext_html">
                <xsl:copy-of select="node()"/>
            </field>
            <field name="text_ngram"><xsl:value-of select="."/></field>

            <!-- Next level: <article class="legalP"> => ledd -->
            <xsl:apply-templates select=".//article[@class='legalP']">
                <xsl:with-param name="parentId" select="
          concat(
            $parentId,
            '/paragraf-',
            translate(substring-after(@data-partID, '§'), '_', '-')
          )
        "/>
            </xsl:apply-templates>
        </doc>
    </xsl:template>

    <!-- (4) article.legalP => nodeType=subsection -->
    <xsl:template match="article[@class='legalP']">
        <xsl:param name="parentId"/>

        <doc>
            <field name="id">
                <xsl:value-of select="concat($parentId, '/ledd-', position())"/>
            </field>
            <field name="nodeType">subsection</field>
            <field name="_nest_parent_"><xsl:value-of select="$parentId"/></field>

            <field name="bodytext"><xsl:value-of select="."/></field>
            <field name="bodytext_html">
                <xsl:copy-of select="node()"/>
            </field>
            <field name="text_ngram"><xsl:value-of select="."/></field>
        </doc>
    </xsl:template>

    <!-- (5) Default pass: ignore all other nodes that don't match above -->
    <xsl:template match="node()"/>
</xsl:stylesheet>
