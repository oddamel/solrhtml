<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <!-- Start hoveddokument -->
  <xsl:template match="/">
    <add>
      <xsl:apply-templates select="//main[@class='documentBody']/section"/>
    </add>
  </xsl:template>

  <!-- Transformasjon for lov (toppnivå) -->
  <xsl:template match="section">
    <doc>
      <field name="id">
        <xsl:value-of select="@data-lovdata-URL"/>
      </field>
      <field name="title">
        <xsl:value-of select="h2"/>
      </field>
      <field name="nodeType">chapter</field>
      <xsl:apply-templates select="article"/>
    </doc>
  </xsl:template>

  <!-- Transformasjon for paragraf -->
  <xsl:template match="article[@class='legalArticle']">
    <doc>
      <field name="id">
        <xsl:value-of select="concat(@data-lovdata-URL, @data-absoluteaddress)"/>
      </field>
      <field name="title">
        <xsl:value-of select="h3/span[@class='legalArticleTitle']"/>
      </field>
      <field name="nodeType">section</field>
      <xsl:apply-templates select="article[@class='legalP']"/>
    </doc>
  </xsl:template>

  <!-- Transformasjon for ledd (subsection) -->
  <xsl:template match="article[@class='legalP']">
    <doc>
      <field name="id">
        <xsl:value-of select="concat(ancestor::article[@class='legalArticle']/@data-lovdata-URL, @data-absoluteaddress)"/>
      </field>
      <field name="nodeType">subsection</field>
      <field name="bodytext">
        <xsl:value-of select="."/>
      </field>
    </doc>
  </xsl:template>
</xsl:stylesheet>
