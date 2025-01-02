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
        <field name="sections">
          <!-- Process each section (h2) -->
          <xsl:for-each select="main//h2">
            <doc>
              <field name="id">
                <xsl:value-of select="@id"/>
              </field>
              <field name="title">
                <xsl:value-of select="."/>
              </field>
              <field name="nodeType">section</field>
              <field name="chapters">
                <!-- Process each chapter within the section (h3) -->
                <xsl:for-each select="following-sibling::h3[preceding-sibling::h2[1][@id=current()/@id]]">
                  <doc>
                    <field name="id">
                      <xsl:value-of select="@id"/>
                    </field>
                    <field name="title">
                      <xsl:value-of select="."/>
                    </field>
                    <field name="nodeType">chapter</field>
                    <field name="paragraphs">
                      <!-- Process each paragraph within the chapter (h4) -->
                      <xsl:for-each select="following-sibling::h4[preceding-sibling::h3[1][@id=current()/@id]]">
                        <doc>
                          <field name="id">
                            <xsl:value-of select="@id"/>
                          </field>
                          <field name="title">
                            <xsl:value-of select="."/>
                          </field>
                          <field name="nodeType">paragraph</field>
                          <field name="bodytext">
                            <xsl:value-of select="following-sibling::p[1]"/>
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
