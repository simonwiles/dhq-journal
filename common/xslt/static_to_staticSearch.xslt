<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:dhq="http://www.digitalhumanities.org/ns/dhq"
  exclude-result-prefixes="#all"
  version="3.0">
  <!--
    This is my 2nd crack at preparing a DHQ article HTML file to be served by
    the UVic Endings Project Static Search system.
    (See, e.g. https://endings.uvic.ca/staticSearch/docs/howDoIUseIt.html.)

    Input file: none, run the initial template (for Saxon, it’s the
      -it switch); or, if you really want to provide an input document,
      it will be ignored.
    
    Input directory: Specified as the $dhq_dir parameter, should be a
      absolute path (a relative path will fail) to a directory which
      contains both the XML and HTML versions of each article in the
      corpus to be processed. I.e., any ".html" file in the directory
      tree should be valid HTML5 that you want to have indexed for
      searching, and should have a corresponding ".xml" file from which
      to extract extra metadata. It does not matter whether an ultimate
      slash is present in the directory path or not.

    Output: A copy of each input HTML with extra metadata inserted is
      placed in a file in the same directory with the same path as the
      input HTML except with in a sibling directory called dhq_evepss/.

    Thus a typical invocation on Syd’s home desktop might look like:
    $ saxon -it ~/Documents/dhq-journal/common/xslt/static_to_staticSearch.xslt dhq_dir=/home/syd/Documents/dhq-static/dhq/
    This produces the output directory
    /home/syd/Documents/dhq-static/dhq_uvepss/
    Sigh.
  -->

  <xsl:mode on-no-match="shallow-copy"/>
  <xsl:output method="text"/>

  <xsl:param name="dhq_dir" select="/home/syd/Documents/dhq-static/dhq" as="xs:string"/>
  <!-- Strip ultimate slash (if there is one) off supplied directory -->
  <xsl:variable name="input_path" select="replace( $dhq_dir, '/$','')" as="xs:string"/>
  <xsl:variable name="config" select="$input_path||'/'||'uvepss_config.xml'" as="xs:string"/>
  <xsl:variable name="output_path" select="$input_path||'_uvepss'" as="xs:string"/>
  <xsl:variable name="primary_inputs" select="$input_path||'?match=00[0-9]{4}.html;recurse=yes;on-error=warning;xinclude=yes;'"/>
  <xsl:variable name="input_collection" select="collection( $primary_inputs )" as="document-node()+"/>
  
  <xsl:template match="/" name="xsl:initial-template">
    <!-- <xsl:if test="not( matches( $dhq_dir, '^(file://?)?/') )"> -->
    <!--   <xsl:message terminate="yes" -->
    <!--                select="'FATAL ERROR: supplied path ('||$dhq_dir||') seems to be a relative path (use absolute path)'"/> -->
    <!-- </xsl:if> -->
    <xsl:message select="  'debug: ip='
                         ||$input_path
                         ||', pi='
                         ||$primary_inputs
                         ||' (has '
                         ||count($input_collection)
                         ||'), op='
                         ||$output_path
                         ||', c='
                         ||$config"/>
    <xsl:apply-templates select="$input_collection/html"/>
  </xsl:template>
  
  <xsl:template match="html">
    <xsl:variable name="input_path_init" select="replace( $input_path, '/[^/]+$', '/')" as="xs:string"/>
    <xsl:variable name="input_path_last" select="replace( $input_path, '^.*/', '')" as="xs:string"/>
    <xsl:variable name="output_file" select="replace( base-uri(.), $input_path_init||$input_path_last, $input_path_init||$input_path_last||'_uvepss')"/>
    <!-- Get path to source XML file by taking complete path to input file and changing extension to ".xml" -->
    <xsl:variable name="src_file" select="base-uri(.) => replace('\.html$','.xml')"/>
    <!-- <xsl:message select="'-\-\-\-\-\-\-\-\-'"/> -->
    <!-- <xsl:message select="'debug: ip ='||$input_path"/> -->
    <!-- <xsl:message select="'debug: ipl='||$input_path_last"/> -->
    <!-- <xsl:message select="'debug: ipi='||$input_path_init"/> -->
    <!-- <xsl:message select="'debug: op ='||$output_file"/> -->
    <!-- <xsl:message select="'debug: src='||$src_file"/> -->
    <xsl:if test="doc-available( $src_file )">
      <xsl:variable name="src" select="document( $src_file )" as="document-node()"/>
      <xsl:result-document href="{$output_file}" method="xhtml" version="5" indent="yes">
        <html>
          <xsl:apply-templates select="@*"/>
          <xsl:apply-templates select="node()">
            <xsl:with-param name="src" tunnel="yes" as="element(tei:teiHeader)" select="$src/*/tei:teiHeader"/>
          </xsl:apply-templates>
        </html>
      </xsl:result-document>
    </xsl:if>
  </xsl:template>

  <!-- Ignore (and then re-create) <meta> tags previously inserted by this routine -->
  <xsl:template match="html:meta[ starts-with( @class, 'staticSearch') ]"/>
  <!-- When we match the one and only one <meta> tag that is in the
       HTML generated by Ash’s ant generateIssues (I think it uses
       generate_static_issues.xsl), reproduce it and generate extra
       staticSearch-specific metadata. -->
  <xsl:template match="html:meta">
    <xsl:param name="src" as="element(tei:teiHeader)" tunnel="yes"/>
    <xsl:copy-of select="."/>
    <meta name="article type" class="staticSearch_desc" content="{$src//dhq:articleType}"/>
    <meta name="date of publication" class="staticSearch_date" content="{$src/tei:fileDesc/tei:publicationStmt/tei:date/@when}"/>
    <meta name="volume" class="staticSearch_num" content="{$src//tei:idno[@type eq 'volume']}"/>
    <meta name="issue"  class="staticSearch_num" content="{$src//tei:idno[@type eq 'issue']}"/>
  </xsl:template>

  <!-- Trim excess off title. (I think it is inserted by head.xsl, but
       we do not need the extra verbiage here) -->
  <xsl:template match="html:title">
    <!-- Right now this just takes the 1st, which means (at least
         currently), that for the 25 cases that have > 1 <title>, we
         are taking the non-English title.  -->
    <xsl:param name="src" as="element(tei:teiHeader)" tunnel="yes"/>
    <xsl:apply-templates select="$src/tei:fileDesc/tei:titleStmt/tei:title[1]"/>
  </xsl:template>
  
</xsl:stylesheet>
