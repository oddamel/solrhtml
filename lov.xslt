<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:template match="/html/head/title">
    <xsl:text/>
  </xsl:template>
  <xsl:template match="/html/body">
    <add>
      <doc>
        <field name="id">lov/2009-06-19-97</field>
        <field name="title">
          <xsl:value-of select="main/h1"/>
        </field>
        <field name="nodeType">law</field>
        <field name="chapters">
          <xsl:for-each select="main/section">
            <doc>
              <field name="id">
                <xsl:value-of select="@data-lovdata-URL"/>
              </field>
              <field name="title">
                <xsl:value-of select="h2"/>
              </field>
              <field name="nodeType">chapter</field>
              <field name="sections">
                <xsl:for-each select="article">
                  <doc>
                    <field name="id">
                      <xsl:value-of select="@data-lovdata-URL"/>
                    </field>
                    <field name="title">
                      <xsl:value-of select="h3"/>
                    </field>
                    <field name="nodeType">section</field>
                    <field name="subsections">
                      <xsl:for-each select="article">
                        <doc>
                          <field name="id">
                            <xsl:value-of select="@data-lovdata-URL"/>
                          </field>
                          <field name="nodeType">subsection</field>
                          <field name="bodytext">
                            <xsl:value-of select="."/>
                          </field>
                        </doc>
                      </xsl:for-each>
                    </field>
                  </doc>
                </xsl:for-each>
              </field>
            </doc>
          </xsl:for-each>
        </field>
      </doc>
    </add>
  </xsl:template>
</xsl:stylesheet>
