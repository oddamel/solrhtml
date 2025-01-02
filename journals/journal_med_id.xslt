<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

    <!-- Main Template -->
    <xsl:template match="/">
        <add>
            <!-- Journal Document -->
            <doc>
                <field name="id">
                    <xsl:value-of select="concat(
                        //journal-meta/journal-id[@journal-id-type='publisher-id'],
                        '/volum-', substring-before(substring-after(//article-meta/article-id[@pub-id-type='doi'], 'fab.'), '.'),
                        '/utgave-', substring-before(substring-after(substring-after(//article-meta/article-id[@pub-id-type='doi'], 'fab.'), '.'), '.'))"/>
                </field>
                <field name="nodeType">journal</field>
                <field name="journal_id">
                    <xsl:value-of select="//journal-meta/journal-id[@journal-id-type='publisher-id']"/>
                </field>
                <field name="volume">
                    <xsl:value-of select="substring-before(substring-after(//article-meta/article-id[@pub-id-type='doi'], 'fab.'), '.')"/>
                </field>
                <field name="issue">
                    <xsl:value-of select="substring-before(substring-after(substring-after(//article-meta/article-id[@pub-id-type='doi'], 'fab.'), '.'), '.')"/>
                </field>
                <field name="title">
                    <xsl:value-of select="//journal-title-group/journal-title"/>
                </field>
                <field name="_text_ngram_">
                    <xsl:value-of select="//journal-title-group/journal-title"/>
                </field>
            </doc>

            <!-- Journal Article Document -->
            <doc>
                <field name="id">
                    <xsl:value-of select="concat(
                        //journal-meta/journal-id[@journal-id-type='publisher-id'],
                        '/volum-', substring-before(substring-after(//article-meta/article-id[@pub-id-type='doi'], 'fab.'), '.'),
                        '/utgave-', substring-before(substring-after(substring-after(//article-meta/article-id[@pub-id-type='doi'], 'fab.'), '.'), '.'),
                        '/artikkel-', substring-after(substring-after(substring-after(//article-meta/article-id[@pub-id-type='doi'], 'fab.'), '.'), '.'))"/>
                </field>
                <field name="doi">
                    <xsl:value-of select="//article-meta/article-id[@pub-id-type='doi']"/>
                </field>
                <field name="journal_id">
                    <xsl:value-of select="//journal-meta/journal-id[@journal-id-type='publisher-id']"/>
                </field>
                <field name="nodeType">journal-article</field>
                <!-- Nest Parent ID pointing to the journal -->
                <field name="_nest_parent_">
                    <xsl:value-of select="concat(
                        //journal-meta/journal-id[@journal-id-type='publisher-id'],
                        '/volum-', substring-before(substring-after(//article-meta/article-id[@pub-id-type='doi'], 'fab.'), '.'),
                        '/utgave-', substring-before(substring-after(substring-after(//article-meta/article-id[@pub-id-type='doi'], 'fab.'), '.'), '.'))"/>
                </field>
                <!-- Title -->
                <field name="title">
                    <xsl:value-of select="//title-group/article-title"/>
                </field>

                <!-- Author(s) -->
                <field name="author_name">
                    <xsl:for-each select="//contrib-group/contrib/string-name">
                        <xsl:value-of select="concat(given-names, ' ', surname)"/>
                        <xsl:if test="position() != last()">; </xsl:if>
                    </xsl:for-each>
                </field>

                <!-- Issue Info -->
                <field name="issue">
                    <xsl:value-of select="substring-before(substring-after(substring-after(//article-meta/article-id[@pub-id-type='doi'], 'fab.'), '.'), '.')"/>
                </field>

                <!-- Open Access Status -->
                <field name="open_access">
                    <xsl:choose>
                        <xsl:when test="//permissions/copyright-statement[contains(., 'Open Access')]">Ja</xsl:when>
                        <xsl:otherwise>Nei</xsl:otherwise>
                    </xsl:choose>
                </field>

                <!-- Publication Date -->
                <field name="publication_date">
                    <xsl:value-of select="//pub-date[@date-type='pub']/@iso-8601-date"/>
                </field>

                <!-- Start and End Page -->
                <field name="start_page">
                    <xsl:value-of select="//fpage"/>
                </field>
                <field name="end_page">
                    <xsl:value-of select="//lpage"/>
                </field>

                <!-- Language -->
                <field name="language">
                    <xsl:value-of select="/article/@xml:lang"/>
                </field>

                <!-- Body Content -->
                <field name="body">
                    <xsl:apply-templates select="//body"/>
                </field>

                <!-- Footnotes -->
                <field name="footnotes">
                    <xsl:apply-templates select="//back/fn-group/fn"/>
                </field>
            </doc>
        </add>
    </xsl:template>

    <!-- Template for Body Text -->
    <xsl:template match="body">
        <xsl:for-each select="sec/p">
            <xsl:value-of select="."/>
            <xsl:text> </xsl:text>
        </xsl:for-each>
        <xsl:for-each select="p">
            <xsl:value-of select="."/>
            <xsl:text> </xsl:text>
        </xsl:for-each>
    </xsl:template>

    <!-- Template for Footnotes -->
    <xsl:template match="fn">
        <xsl:value-of select="label"/>
        <xsl:text>: </xsl:text>
        <xsl:apply-templates select="p"/>
        <xsl:text> </xsl:text>
    </xsl:template>
</xsl:stylesheet>
