<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

    <!-- ===== ROOT: Samme som før ===== -->
    <xsl:template match="/">
        <add>
            <doc>
                <!-- Rot ID (law ID) -->
                <field name="id">
                    <xsl:value-of select="concat('lov-', substring-after(//dd[@class='legacyID'], 'LOV-'))"/>
                </field>
                <field name="title">
                    <xsl:value-of select="//dd[@class='title']"/>
                </field>
                <field name="nodeType">law</field>
                <field name="source">Lovdata</field>

                <!-- Starte å prosessere <section> for del/kapittel osv.
                     ... men send med parentId = selve lov-ID-en -->
                <xsl:apply-templates select="//section">
                    <xsl:with-param name="parentId"
                                    select="concat('lov-', substring-after(//dd[@class='legacyID'], 'LOV-'))"/>
                </xsl:apply-templates>

            </doc>
        </add>
    </xsl:template>


    <!--
      ===== NY "Template for Section" =====
      Oppdager om dette er "del", "underdel", "kapittel" eller "underkapittel".
      Du kan utvide/endre logikken basert på data du ser i HTML:
        - data-name="delIII"
        - data-name="kapI"
        - data-name="underkap2"
        - ...
      Hver gang vi matcher en <section>, lag en <doc> for dette nivået
      og kall rekursivt for child <section> + <article>.
    -->
    <xsl:template match="section">
        <xsl:param name="parentId"/>

        <!-- Les ut data-name for å se hva slags type. -->
        <xsl:variable name="dn" select="@data-name"/>
        <!-- Erstatt underscore -> bindestrek,
             men her gjøres ingen store/små-bokstavkonvertering. Tilpass ved behov. -->
        <xsl:variable name="dnClean" select="translate($dn, '_', '-')"/>

        <!-- Bestem om det er "del", "underdel", "kapittel", "underkapittel", etc. -->
        <xsl:choose>
            <xsl:when test="contains($dnClean, 'del')">
                <!-- f.eks. data-name="delIII" -> /del-III  -->
                <xsl:variable name="suffix" select="substring-after($dnClean, 'del')"/>
                <xsl:variable name="currentId" select="concat($parentId, '/del-', $suffix)"/>

                <doc>
                    <field name="id"><xsl:value-of select="$currentId"/></field>
                    <field name="title"><xsl:value-of select="h2"/></field>
                    <field name="nodeType">del</field>
                    <field name="_nest_parent_"><xsl:value-of select="$parentId"/></field>

                    <!-- Underordnede seksjoner (underdel, kapittel, paragraf) -->
                    <xsl:apply-templates select="section|article">
                        <xsl:with-param name="parentId" select="$currentId"/>
                    </xsl:apply-templates>
                </doc>
            </xsl:when>

            <xsl:when test="contains($dnClean, 'underdel')">
                <!-- data-name="underdel2" -> /underdel-2 -->
                <xsl:variable name="suffix" select="substring-after($dnClean, 'underdel')"/>
                <xsl:variable name="currentId" select="concat($parentId, '/underdel-', $suffix)"/>

                <doc>
                    <field name="id"><xsl:value-of select="$currentId"/></field>
                    <field name="title"><xsl:value-of select="h2"/></field>
                    <field name="nodeType">underdel</field>
                    <field name="_nest_parent_"><xsl:value-of select="$parentId"/></field>

                    <!-- Videre ned: kapittel, paragraf -->
                    <xsl:apply-templates select="section|article">
                        <xsl:with-param name="parentId" select="$currentId"/>
                    </xsl:apply-templates>
                </doc>
            </xsl:when>

            <xsl:when test="contains($dnClean, 'kap')">
                <!-- data-name="kapI" -> /kapittel-I -->
                <xsl:variable name="suffix" select="substring-after($dnClean, 'kap')"/>
                <xsl:variable name="currentId" select="concat($parentId, '/kapittel-', $suffix)"/>

                <doc>
                    <field name="id"><xsl:value-of select="$currentId"/></field>
                    <field name="title"><xsl:value-of select="h2"/></field>
                    <field name="nodeType">chapter</field>
                    <field name="_nest_parent_"><xsl:value-of select="$parentId"/></field>

                    <!-- Rekursivt kall for nye <section> og <article> -->
                    <xsl:apply-templates select="section|article">
                        <xsl:with-param name="parentId" select="$currentId"/>
                    </xsl:apply-templates>
                </doc>
            </xsl:when>

            <xsl:otherwise>
                <!-- Hvis den IKKE inneholder 'del', 'kap', 'underdel' osv.
                     f.eks. data-name="annex1" eller noe.
                     Du kan la det passere, eller bare re-apply til children. -->
                <xsl:apply-templates select="section|article">
                    <xsl:with-param name="parentId" select="$parentId"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!--
      ===== Template for "article" with class="legalArticle" (Paragraf) =====
      Her tar du imot parentId (som kan være kapittel-ID, del-ID osv.),
      og bygger "/paragraf-X" i ID-en.
    -->
    <xsl:template match="article[@class='legalArticle']">
        <xsl:param name="parentId"/>

        <!-- f.eks. data-partID="§4-b" => /paragraf-4-b -->
        <doc>
            <field name="id">
                <xsl:value-of select="concat($parentId, '/paragraf-',
          translate(substring-after(@data-partID, '§'), '_', '-'))"/>
            </field>
            <field name="title">
                <xsl:value-of
                        select="concat(h3/span[@class='legalArticleValue'], ' ', h3/span[@class='legalArticleTitle'])"/>
            </field>
            <field name="nodeType">section</field>
            <field name="_nest_parent_">
                <xsl:value-of select="$parentId"/>
            </field>

            <!-- Apply templates for ledd (subsections) -->
            <xsl:apply-templates select="article[@class='legalP']">
                <xsl:with-param name="parentId" select="concat($parentId, '/paragraf-',
          translate(substring-after(@data-partID, '§'), '_', '-'))"/>
            </xsl:apply-templates>
        </doc>
    </xsl:template>


    <!--
      ===== Template for Subsections (Ledd) =====
      Teller posisjon eller bruker data-name/data-partID
    -->
    <xsl:template match="article[@class='legalP']">
        <xsl:param name="parentId"/>

        <doc>
            <field name="id">
                <!-- Basert på parent paragraf + /ledd-N -->
                <xsl:value-of select="concat($parentId, '/ledd-', position())"/>
            </field>
            <field name="nodeType">subsection</field>
            <field name="bodytext">
                <xsl:value-of select="."/>
            </field>
            <field name="_nest_parent_">
                <xsl:value-of select="$parentId"/>
            </field>
        </doc>
    </xsl:template>

</xsl:stylesheet>
