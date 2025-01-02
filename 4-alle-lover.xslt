<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="urn:no:example:lov"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="xhtml"
                version="1.0">

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

    <!-- Root template -->
    <xsl:template match="/">
        <lov>
            <!-- Process metadata -->
            <xsl:apply-templates select="//xhtml:head"/>

            <!-- Process body content -->
            <xsl:apply-templates select="//xhtml:body"/>
        </lov>
    </xsl:template>

    <!-- Metadata extraction -->
    <xsl:template match="xhtml:head">
        <metadata>
            <lovnavn>
                <xsl:value-of select="xhtml:title"/>
            </lovnavn>
            <!-- Additional metadata fields can be extracted if available -->
        </metadata>
    </xsl:template>

    <!-- Body content processing -->
    <xsl:template match="xhtml:body">
        <!-- Iterate through top-level sections -->
        <xsl:apply-templates select="xhtml:section[@data-name]"/>
    </xsl:template>

    <!-- Handle top-level sections (Del) -->
    <xsl:template match="xhtml:section[@data-name]">
        <del>
            <xsl:attribute name="id">
                <xsl:value-of select="@data-name"/>
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:value-of select="xhtml:h2"/>
            </xsl:attribute>

            <!-- Process nested chapters or paragraphs -->
            <xsl:apply-templates select="xhtml:section[@data-section-type='kapittel']"/>
        </del>
    </xsl:template>

    <!-- Handle chapters (Kapittel) -->
    <xsl:template match="xhtml:section[@data-section-type='kapittel']">
        <kapittel>
            <xsl:attribute name="id">
                <xsl:value-of select="@id"/>
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:value-of select="xhtml:h2"/>
            </xsl:attribute>

            <!-- Process nested paragraphs -->
            <xsl:apply-templates select="xhtml:section[@data-section-type='paragraf']"/>
        </kapittel>
    </xsl:template>

    <!-- Handle paragraphs (Paragraf) -->
    <xsl:template match="xhtml:section[@data-section-type='paragraf']">
        <paragraf>
            <xsl:attribute name="id">
                <xsl:value-of select="@id"/>
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:value-of select="xhtml:h3"/>
            </xsl:attribute>

            <!-- Extract content -->
            <tekst>
                <xsl:apply-templates select="xhtml:p"/>
            </tekst>
        </paragraf>
    </xsl:template>

    <!-- Handle plain text paragraphs -->
    <xsl:template match="xhtml:p">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>

    <!-- Ignore other elements by default -->
    <xsl:template match="*"/>
</xsl:stylesheet>
