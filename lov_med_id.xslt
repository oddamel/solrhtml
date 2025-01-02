<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <xsl:template match="/">
    <add>
      <!-- Document for Journal Metadata -->
      <doc>
        <field name="id">
          <xsl:value-of select="concat(
                        //journal-meta/journal-id[@journal-id-type='publisher-id'],
                        '/volum-', substring-before(substring-after(//article-meta/article-id[@pub-id-type='doi'], '.'), '.'))"/>
        </field>
        <field name="nodeType">journal</field>
        <field name="journal_id">
          <xsl:value-of select="//journal-meta/journal-id[@journal-id-type='publisher-id']"/>
        </field>
        <!-- Volume -->
        <field name="volume">
          <xsl:value-of select="substring-before(substring-after(//article-meta/article-id[@pub-id-type='doi'], '.'), '.')"/>
        </field>
        <!-- Text N-gram for journal title or main identifier -->
        <field name="_text_ngram_">
          <xsl:value-of select="//journal-meta/journal-title"/>
        </field>
      </doc>

      <!-- Document for Journal Article Metadata -->
      <doc>
        <!-- ID Field with DOI -->
        <field name="id">
          <xsl:value-of select="concat(
                        //journal-meta/journal-id[@journal-id-type='publisher-id'],
                        '/volum-', substring-before(substring-after(//article-meta/article-id[@pub-id-type='doi'], '.'), '.'),
                        '/utgave-', //article-meta/issue,
                        '/artikkel-', //article-meta/article-id[@pub-id-type='doi'])"/>
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
                        '/volum-', substring-before(substring-after(//article-meta/article-id[@pub-id-type='doi'], '.'), '.'))"/>
        </field>

        <!-- Volume -->
        <field name="volume">
          <xsl:value-of select="substring-before(substring-after(//article-meta/article-id[@pub-id-type='doi'], '.'), '.')"/>
        </field>

        <!-- Article Title and Subtitle -->
        <field name="article_title">
          <xsl:value-of select="//title-group/article-title"/>
        </field>

        <field name="subtitle">
          <xsl:value-of select="//title-group/subtitle"/>
        </field>

        <!-- Text N-gram for article title -->
        <field name="_text_ngram_">
          <xsl:value-of select="//title-group/article-title"/>
        </field>

        <!-- Author Name(s) -->
        <field name="author_name">
          <xsl:for-each select="//contrib-group/contrib/string-name">
            <xsl:value-of select="concat(given-names, ' ', surname)"/>
            <xsl:if test="position() != last()">; </xsl:if>
          </xsl:for-each>
        </field>

        <!-- Issue -->
        <field name="issue">
          <xsl:value-of select="concat('Volum ', substring-before(substring-after(//article-meta/article-id[@pub-id-type='doi'], '.'), '.'), ', Utgave ', //article-meta/issue)"/>
        </field>

        <!-- Open Access -->
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

        <!-- Body Text (Extracting Sections for Content) -->
        <field name="bodytext">
          <xsl:apply-templates select="//body/sec/p"/>
        </field>
      </doc>
    </add>
  </xsl:template>

  <!-- Template to handle body text sections -->
  <xsl:template match="p">
    <xsl:value-of select="."/>
    <xsl:text> </xsl:text>
  </xsl:template>
</xsl:stylesheet>
