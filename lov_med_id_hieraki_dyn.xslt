<xsl:stylesheet
        version="2.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:xs="http://www.w3.org/2001/XMLSchema"
        xmlns:my="http://example.com/myfun"
        exclude-result-prefixes="xs my xsl"
>

    <!--
      ===============
      1) GLOBAL FUNCTIONS
      ===============
    -->

    <!--
      my:normalize($val)
      - If $val is empty or an empty sequence, treat it as "".
      - Remove leading "NL/" if present.
      - Replace underscores "_" with hyphens "-".
      - Trim whitespace.
    -->
    <xsl:function name="my:normalize" as="xs:string">
        <xsl:param name="val" as="xs:string?" />
        <!-- Ensure empty sequence => empty string -->
        <xsl:variable name="safeVal" select="if ($val) then $val else ''" />
        <xsl:variable name="trim" select="normalize-space($safeVal)" />
        <xsl:choose>
            <xsl:when test="string-length($trim) > 0">
                <!-- Remove leading 'NL/' -->
                <xsl:variable name="noNL" select="replace($trim, '^NL/', '')" />
                <!-- Replace underscores with hyphens -->
                <xsl:value-of select="replace($noNL, '_', '-')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text></xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!--
      my:get-chapter-num($pid)
      - E.g. parentId="/kapittel-2" => returns "2".
      - We do substring-after(…,"/kapittel-") then tokenize on "/".
    -->
    <xsl:function name="my:get-chapter-num" as="xs:string">
        <xsl:param name="pid" as="xs:string" />
        <xsl:variable name="afterKap" select="substring-after($pid, '/kapittel-')" />
        <xsl:value-of select="tokenize($afterKap, '/')[1]" />
    </xsl:function>

    <!--
      ===============
      2) TOP LEVEL MATCH => <add><doc> for the LAW
      ===============
    -->
    <xsl:template match="/">
        <add>
            <doc>
                <!-- Hard-coded or from <dd class="legacyID"> etc. -->
                <field name="id">lov-1999-03-26-14</field>
                <field name="nodeType">law</field>
                <field name="title">Skatteloven (example)</field>
                <field name="source">Lovdata</field>
                <field name="timestamp">
                    <xsl:text>2025-01-12T10:00:00Z</xsl:text>
                </field>

                <!-- Recurse top-level <section> in <main class='documentBody'> -->
                <xsl:apply-templates select="//main[@class='documentBody']/section"
                                     mode="handleSection">
                    <xsl:with-param name="parentId" select="'lov-1999-03-26-14'"/>
                    <xsl:with-param name="parentNodeType" select="'law'"/>
                </xsl:apply-templates>
            </doc>
        </add>
    </xsl:template>

    <!--
      ===============
      3) SECTION => part/subpart/chapter/subchapter
      ===============
    -->
    <xsl:template match="section" mode="handleSection">
        <xsl:param name="parentId"/>
        <xsl:param name="parentNodeType"/>

        <!-- Safely convert @data-name to string -->
        <xsl:variable name="rawName" select="string(@data-name)" as="xs:string" />
        <xsl:variable name="dn" select="my:normalize($rawName)" as="xs:string"/>

        <xsl:choose>
            <!-- "del" => part, ignoring "underdel" -->
            <xsl:when test="contains($dn,'del') and not(contains($dn,'underdel'))">
                <!-- part logic here if needed -->
            </xsl:when>

            <!-- "underdel" => subpart -->
            <xsl:when test="contains($dn,'underdel')">
                <!-- subpart logic here if needed -->
            </xsl:when>

            <!-- "kap" => CHAPTER or SUBCHAPTER -->
            <xsl:when test="contains($dn,'kap')">
                <xsl:variable name="thisNodeType">
                    <xsl:choose>
                        <xsl:when test="$parentNodeType='chapter' or $parentNodeType='subchapter'">
                            <xsl:text>subchapter</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>chapter</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <!-- parse suffix from substring-after($dn,'kap') => "2" e.g. -->
                <xsl:variable name="suffix" select="substring-after($dn,'kap')" />

                <xsl:variable name="newId">
                    <xsl:choose>
                        <xsl:when test="$thisNodeType='subchapter'">
                            <xsl:value-of select="concat($parentId, '/underkapittel-', $suffix)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat($parentId, '/kapittel-', $suffix)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <doc>
                    <field name="id">
                        <xsl:value-of select="$newId"/>
                    </field>
                    <field name="nodeType">
                        <xsl:value-of select="$thisNodeType"/>
                    </field>
                    <field name="_nest_parent_">
                        <xsl:value-of select="$parentId"/>
                    </field>
                    <field name="title">
                        <!-- e.g. "Kapittel 2. Skattesubjektene og skattepliktens omfang" -->
                        <xsl:value-of select="normalize-space(h2)"/>
                    </field>

                    <!-- Recurse deeper: child sections and articles -->
                    <xsl:apply-templates select="section|article" mode="handleSection">
                        <xsl:with-param name="parentId" select="$newId"/>
                        <xsl:with-param name="parentNodeType" select="$thisNodeType"/>
                    </xsl:apply-templates>
                </doc>
            </xsl:when>

            <!-- If parent is already a chapter or subchapter but child doesn’t have 'kap': fallback subchapter logic. -->
            <xsl:when test="$parentNodeType='chapter' or $parentNodeType='subchapter'">
                <!-- e.g. data-partID="k2-1" => suffix=substring-after("k2-1","-") => "1" -->
                <xsl:variable name="parID" select="string(@data-partID)" as="xs:string" />

                <xsl:variable name="childSuffix">
                    <xsl:choose>
                        <xsl:when test="$parID and contains($parID,'-')">
                            <xsl:value-of select="substring-after($parID,'-')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- fallback => position() -->
                            <xsl:value-of select="position()"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <xsl:variable name="newId" select="concat($parentId, '/underkapittel-', $childSuffix)" />

                <doc>
                    <field name="id">
                        <xsl:value-of select="$newId"/>
                    </field>
                    <field name="nodeType">subchapter</field>
                    <field name="_nest_parent_">
                        <xsl:value-of select="$parentId"/>
                    </field>
                    <field name="title">
                        <!-- might be h2/h3: "Hvem som har skatteplikt" etc. -->
                        <xsl:value-of select="normalize-space(h2|h3)"/>
                    </field>

                    <!-- Recurse deeper -->
                    <xsl:apply-templates select="section|article" mode="handleSection">
                        <xsl:with-param name="parentId" select="$newId"/>
                        <xsl:with-param name="parentNodeType" select="'subchapter'"/>
                    </xsl:apply-templates>
                </doc>
            </xsl:when>

            <!-- Otherwise pass-through child sections/articles with same parent. -->
            <xsl:otherwise>
                <xsl:apply-templates select="section|article" mode="handleSection">
                    <xsl:with-param name="parentId" select="$parentId"/>
                    <xsl:with-param name="parentNodeType" select="$parentNodeType"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--
      ===============
      4) ARTICLE => PARAGRAF (section)
      ===============
    -->
    <xsl:template match="article[@class='legalArticle']" mode="handleSection">
        <xsl:param name="parentId"/>
        <xsl:param name="parentNodeType"/>

        <!-- e.g. @data-partID="§2-1" => "2-1" => /paragraf-2-1 -->
        <xsl:variable name="rawPid" select="string(@data-partID)" as="xs:string" />
        <xsl:variable name="pid">
            <xsl:choose>
                <xsl:when test="$rawPid">
                    <xsl:value-of select="replace(
                        replace($rawPid, '^§', ''),
                        '_',
                        '-'
                    )"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- fallback ID -->
                    <xsl:value-of select="concat('auto-', generate-id())"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="newId" select="concat($parentId, '/paragraf-', $pid)" />

        <doc>
            <field name="id">
                <xsl:value-of select="$newId"/>
            </field>
            <field name="nodeType">section</field>
            <field name="_nest_parent_">
                <xsl:value-of select="$parentId"/>
            </field>

            <!-- Build a title from <h3> or similar -->
            <field name="title">
                <xsl:value-of select="
                    normalize-space(
                        concat(
                           .//h3/span[@class='legalArticleValue'], ' ',
                           .//h3/span[@class='legalArticleTitle']
                        )
                    )
                "/>
            </field>

            <!-- Plain text fields -->
            <field name="bodytext">
                <xsl:value-of select="."/>
            </field>
            <field name="bodytext_html">
                <xsl:copy-of select="node()"/>
            </field>
            <field name="text_ngram">
                <xsl:value-of select="."/>
            </field>

            <!-- Recurse <article class='legalP'> => ledd (subsection) -->
            <xsl:apply-templates select="article[@class='legalP']" mode="handleSection">
                <xsl:with-param name="parentId" select="$newId"/>
                <xsl:with-param name="parentNodeType" select="'section'"/>
            </xsl:apply-templates>
        </doc>
    </xsl:template>

    <!--
      ===============
      5) <article class='legalP'> => ledd (subsection)
      ===============
    -->
    <xsl:template match="article[@class='legalP']" mode="handleSection">
        <xsl:param name="parentId"/>
        <xsl:param name="parentNodeType"/>

        <!-- If @data-numerator is present, use it; else fallback to position() -->
        <xsl:variable name="num">
            <xsl:choose>
                <xsl:when test="@data-numerator">
                    <xsl:value-of select="@data-numerator"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="position()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="newId" select="concat($parentId, '/ledd-', $num)" />

        <doc>
            <field name="id">
                <xsl:value-of select="$newId"/>
            </field>
            <field name="nodeType">subsection</field>
            <field name="_nest_parent_">
                <xsl:value-of select="$parentId"/>
            </field>

            <field name="bodytext">
                <xsl:value-of select="."/>
            </field>
            <field name="bodytext_html">
                <xsl:copy-of select="node()"/>
            </field>
            <field name="text_ngram">
                <xsl:value-of select="."/>
            </field>
        </doc>
    </xsl:template>

    <!--
      ===============
      6) Fallback: ignore anything else
      ===============
    -->
    <xsl:template match="node()" priority="-1">
        <!-- Do nothing by default -->
    </xsl:template>

</xsl:stylesheet>
