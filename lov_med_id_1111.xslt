<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" encoding="UTF-8" indent="yes" />

  <!-- Root Template -->
  <xsl:template match="/">
    <add>
      <doc>
        <!-- Root ID (law ID) -->
        <field name="id">
          <xsl:value-of select="concat('lov-', substring-after(//dd[@class='legacyID'], 'LOV-'))" />
        </field>
        <field name="title">
          <xsl:value-of select="//dd[@class='title']" />
        </field>
        <field name="nodeType">law</field>
        <field name="source">Lovdata</field>
        <!-- Apply templates for chapters -->
        <xsl:apply-templates select="//section" />
      </doc>
    </add>
  </xsl:template>

  <!-- Template for Chapters -->
  <xsl:template match="section">
    <xsl:variable name="chapterId">
      <xsl:value-of select="translate(substring-after(@data-name, 'kap'), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
    </xsl:variable>

    <doc>
      <field name="id">
        <xsl:value-of select="concat('lov-', substring-after(//dd[@class='legacyID'], 'LOV-'), '/kapittel-', $chapterId)" />
      </field>
      <field name="title">
        <xsl:value-of select="h2" />
      </field>
      <field name="nodeType">chapter</field>
      <field name="_nest_parent_">
        <xsl:value-of select="concat('lov-', substring-after(//dd[@class='legacyID'], 'LOV-'))" />
      </field>
      <!-- Apply templates for articles -->
      <xsl:apply-templates select="article">
        <xsl:with-param name="chapterId" select="$chapterId" />
      </xsl:apply-templates>
    </doc>
  </xsl:template>

  <!-- Template for Sections (Articles) -->
  <xsl:template match="article[@class='legalArticle']">
    <xsl:param name="chapterId" />

    <doc>
      <field name="id">
        <xsl:value-of select="concat('lov-', substring-after(//dd[@class='legacyID'], 'LOV-'), '/kapittel-', $chapterId,
                                     '/paragraf-', translate(substring-after(@data-partID, '§'), '_', '-'))" />
      </field>
      <field name="title">
        <xsl:value-of select="concat(h3/span[@class='legalArticleValue'], ' ', h3/span[@class='legalArticleTitle'])" />
      </field>
      <field name="nodeType">section</field>
      <field name="_nest_parent_">
        <xsl:value-of select="concat('lov-', substring-after(//dd[@class='legacyID'], 'LOV-'), '/kapittel-', $chapterId)" />
      </field>
      <!-- Apply templates for subsections -->
      <xsl:apply-templates select="article[@class='legalP']">
        <xsl:with-param name="chapterId" select="$chapterId" />
      </xsl:apply-templates>
    </doc>
  </xsl:template>

  <!-- Template for Subsections -->
  <xsl:template match="article[@class='legalP']">
    <xsl:param name="chapterId" />

    <doc>
      <field name="id">
        <xsl:value-of select="concat('lov-', substring-after(//dd[@class='legacyID'], 'LOV-'), '/kapittel-', $chapterId,
                                     '/paragraf-', translate(substring-after(../@data-partID, '§'), '_', '-'),
                                     '/ledd-', position())" />
      </field>
        <field name="nodeType">subsection</field>
      <field name="bodytext">
        <xsl:value-of select="." />
      </field>
      <field name="_nest_parent_">
        <xsl:value-of select="concat('lov-', substring-after(//dd[@class='legacyID'], 'LOV-'), '/kapittel-', $chapterId,
                                     '/paragraf-', translate(substring-after(../@data-partID, '§'), '_', '-'))" />
      </field>
    </doc>
  </xsl:template>
</xsl:stylesheet>
