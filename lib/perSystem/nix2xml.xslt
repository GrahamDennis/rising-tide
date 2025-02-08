<?xml version='1.0' encoding='UTF-8'?>
<xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' version='1.0'>
    <xsl:output method="xml" indent="yes" encoding="UTF-8" />
    <xsl:template match="text()"/>
    <xsl:template match="attrs[attr/@name='name']">
        <xsl:element name="{attr/string/@value}">
            <xsl:apply-templates select="attr[@name='attrs']"/>
            <xsl:apply-templates select="attr[@name='children']"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="attr[@name='attrs']">
        <xsl:for-each select="attrs/attr">
            <xsl:attribute name="{@name}">
                <xsl:value-of select="string/@value"></xsl:value-of>
            </xsl:attribute>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>