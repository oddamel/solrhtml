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
        <!-- Apply templates for sections directly under the law -->
        <xsl:apply-templates select="//section" />
      </doc>
    </add>
  </xsl:template>

  <!-- Template for Sections -->
  <xsl:template match="section">
    <xsl:variable name="sectionType">
      <xsl:choose>
        <xsl:when test="contains(@data-name, 'del')">del</xsl:when>
        <xsl:when test="contains(@data-name, 'underdel')">underdel</xsl:when>
        <xsl:when test="contains(@data-name, 'kap')">kapittel</xsl:when>
        <xsl:when test="contains(@data-name, 'underkapittel')">underkapittel</xsl:when>
        <xsl:otherwise>unknown</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="parentId">
      <!-- Determine parent ID dynamically -->
      <xsl:value-of select="ancestor::doc/field[@name='id']" />
    </xsl:variable>

    <doc>
      <field name="id">
        <xsl:value-of select="concat($parentId, '/', @data-name)" />
      </field>
      <field name="title">
        <xsl:value-of select="h2 | h3" />
      </field>
      <field name="nodeType">
        <xsl:value-of select="$sectionType" />
      </field>
      <field name="nest_parent">
        <xsl:value-of select="$parentId" />
      </field>
      <!-- Apply templates to child sections or articles -->
      <xsl:apply-templates select="section | article" />
    </doc>
  </xsl:template>

  <!-- Template for Articles (Paragraf) -->
  <xsl:template match="article[@class='legalArticle']">
    <xsl:variable name="parentId">
      <xsl:value-of select="ancestor::doc/field[@name='id']" />
    </xsl:variable>

    <doc>
      <field name="id">
        <xsl:value-of select="concat($parentId, '/paragraf-', translate(@data-partID, '§', ''))" />
      </field>
      <field name="title">
        <xsl:value-of select="h3/span[@class='legalArticleTitle']" />
      </field>
      <field name="nodeType">paragraf</field>
      <field name="nest_parent">
        <xsl:value-of select="$parentId" />
      </field>
      <!-- Apply templates to child legalP elements (ledd) -->
      <xsl:apply-templates select="article[@class='legalP'] | p[@class='leddfortsettelse']" />
    </doc>
  </xsl:template>

  <!-- Template for Subsections (Ledd) -->
  <xsl:template match="article[@class='legalP']">
    <xsl:variable name="parentId">
      <xsl:value-of select="ancestor::doc/field[@name='id']" />
    </xsl:variable>

    <doc>
      <field name="id">
        <xsl:value-of select="concat($parentId, '/ledd-', position())" />
      </field>
      <field name="nodeType">subsection</field>
      <field name="bodytext">
        <xsl:value-of select="normalize-space(.)" />
      </field>
      <field name="nest_parent">
        <xsl:value-of select="$parentId" />
      </field>
    </doc>
  </xsl:template>

  <!-- Template for Leddfortsettelse -->
  <xsl:template match="p[@class='leddfortsettelse']">
    <xsl:variable name="parentId">
      <xsl:value-of select="ancestor::doc/field[@name='id']" />
    </xsl:variable>

    <doc>
      <field name="id">
        <xsl:value-of select="concat($parentId, '/leddfortsettelse-', position())" />
      </field>
      <field name="nodeType">leddfortsettelse</field>
      <field name="bodytext">
        <xsl:value-of select="normalize-space(.)" />
      </field>
      <field name="nest_parent">
        <xsl:value-of select="$parentId" />
      </field>
    </doc>
  </xsl:template>

  <!-- Template for Future Legal Articles -->
  <xsl:template match="article[@class='futureLegalArticle']">
    <xsl:variable name="parentId">
      <xsl:value-of select="ancestor::doc/field[@name='id']" />
    </xsl:variable>

    <doc>
      <field name="id">
        <xsl:value-of select="concat($parentId, '/future-', @data-name)" />
      </field>
      <field name="title">
        <xsl:value-of select="h3/span[@class='futureLegalArticleHeader']" />
      </field>
      <field name="nodeType">futureArticle</field>
      <field name="nest_parent">
        <xsl:value-of select="$parentId" />
      </field>
    </doc>
  </xsl:template>
</xsl:stylesheet>
