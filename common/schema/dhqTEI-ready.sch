<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  queryBinding="xslt2">

  <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
  <ns prefix="dhq" uri="http://www.digitalhumanities.org/ns/dhq"/>
  <ns prefix="cc"  uri="http://web.resource.org/cc/"/>
  <ns prefix="rdf" uri="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>
  <ns prefix="xs"  uri="http://www.w3.org/2001/XMLSchema"/>
  
  <p>Authorial readiness check for DHQ articles.</p>

  <p>This checks a number of constraints on DHQauthor articles that we can't or
    don't want to check in the main schema, either because they interrogate
    attribute values (for example to check cross-referencing), or because they
    are not absolute rules, or they entail complex dependencies of one kind or
    another.</p>

  <!-- to do: migrate the old dhq-ready Schematron code into this -->
  <!-- Also check DHQ-TEI-diagnostic.sch for rules that should be
       in here -->

  <pattern id="top-level">
<!-- Cannot put up with hrefs to http: in
      <?oxygen RNGSchema="../../common/schema/DHQauthor-TEI.rng" type="xml"?>
      <?oxygen SCHSchema="../../common/schema/dhqTEI-ready.sch"?>
      <?xml-model href="../../toc/toc-xml.sch" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"?>
    
    -->
    <!--<?oxygen RNGSchema="../../common/schema/DHQauthor-TEI.rng" type="xml"?>
    <?oxygen SCHSchema="../../common/schema/dhqTEI-ready.sch"?>-->
    <rule context="/processing-instruction()">
      <report test="matches(.,'(RNGSchema|SCHSchema|href)=&quot;http')" role="warning">
        Processing instruction points to the Internet - this file will not be portable.
      </report>
      
    </rule>
  </pattern>

  <pattern id="id-check">
    <p>Element IDs must be unique</p>
    <rule context="*[exists(@xml:id)]">
      <assert test="empty(//*[@xml:id eq current()/@xml:id]
        except .)">Element appears with a duplicate @xml:id</assert>
    </rule>
  </pattern>
  
  <pattern id="header-check">
    <p>Content checks in header</p>
    
    <rule
      context="tei:availability |
                   cc:License |
                   tei:profileDesc |
                   tei:profileDesc//* |
                   tei:revisionDesc"
      >
      <assert test="true()"> matching these to create exceptions for the following rules </assert>
    </rule>

    <rule context="tei:publicationStmt/tei:idno[@type = ('volume','issue')][. castable as xs:integer]">
      <let name="me" value="normalize-space(.)"/>
      <let name="min" value="1"/>
      <let name="max" value="if (@type eq 'issue') then 4 else 899"/> <!-- rule only works for ~900 years -->
      <assert test="$me eq .">There should be no spaces in the <value-of select="@type"/> number</assert>
      <assert test="$me castable as xs:positiveInteger">The <value-of select="@type"/> number should be a positive integer</assert>
      <assert test="$max ge xs:integer($me)  and  xs:integer($me) ge $min">The <value-of select="@type"/> number is out of range</assert>
      <assert test="if (@type eq 'volume') then string-length($me) eq 3 else true()">The volume number should be 3 digits long (with leading zeroes as needed)</assert>
      <assert test="if (@type eq 'issue') then string-length($me) eq 1 else true()">The issue number should be only 1 digit long (no leading zeroes allowed)</assert>
    </rule>
    <!--
      Yes, the preceding and following rules are very similar, but are separate because comparing the
      content as a number will cause a run-time crash if the value is not castable to a number.
    -->
    <rule context="tei:publicationStmt/tei:idno[@type = ('volume','issue')][not( . castable as xs:integer )]">
      <let name="me" value="normalize-space(.)"/>
      <assert test="false()">The <value-of select="@type"/> number should be a positive integer</assert>
      <assert test="$me eq .">There should be no spaces in the <value-of select="@type"/> number</assert>
      <assert test="if (@type eq 'volume') then string-length($me) eq 3 else true()">The volume number should be 3 digits long (with leading zeroes as needed)</assert>
      <assert test="if (@type eq 'issue') then string-length($me) eq 1 else true()">The issue number should be only 1 digit long (no leading zeroes allowed)</assert>
    </rule>
    
    <rule context="tei:teiHeader//*">
      <assert test="normalize-space(.)">
        <value-of select="name(..)"/>/<name/> has no text content</assert>
    </rule>
    
    <rule context="tei:teiHeader//tei:date[ @when eq ''  or  not( @when ) ]">
      <assert test="@when">Publication date is missing its @when attribute</assert>
      <assert test="not(@when)">Publication date is missing its @when attribute value</assert>
    </rule>
    <rule context="tei:teiHeader//tei:date[ @when  and  @when ne '']">
      <let name="date-str" value="@when/format-date(.,'[D] [MNn] [Y]')"/>
      <assert test="@when castable as xs:date"><value-of select="name(..)"/><name/>/@when is not an ISO date</assert>
      <assert test=". eq $date-str">date value is not @when in 'D Month YYYY' format (expecting '<value-of select="$date-str"/>')</assert>
    </rule>
    
    <rule context="tei:classDecl">
      <assert test="exists(tei:taxonomy[@xml:id='dhq_keywords'])"><name/> is
        missing a 'dhq_keywords' taxonomy declaration</assert>
      <assert test="exists(tei:taxonomy[@xml:id='authorial_keywords'])"><name/>
        is missing an 'authorial_keywords' taxonomy declaration</assert>
    </rule>

    <rule context="tei:taxonomy[@xml:id='dhq_keywords']">
      <assert test="true()"> could put a test for contents here; previous attempt commented out, below </assert>
      <!--
        <let name="contents" value="*|text()[normalize-space(.)]"/>
        <assert test="exists(bibl[1]) and not($contents except tei:bibl[1])"><name/> contains unexpected content (should have a single bibl)</assert>
        <assert test="normalize-space(.) = normalize-space('DHQ classification scheme; full list available in the DHQ keyword taxonomy')">
          text content of <name/> is incorrect: should be "DHQ classification scheme; full list available in the DHQ keyword taxonomy"
        </assert>
      -->
    </rule>
    <rule context="tei:taxonomy[@xml:id='authorial_keywords']">
      <assert test="true()"/>
    </rule>
    <rule context="tei:classDecl/*">
      <report test="true()"><name/> unexpected here</report>
    </rule>
    <rule context="tei:front//dhq:*">
      <assert test="normalize-space(.)"><name/> is empty</assert>
    </rule>
  </pattern>

  <pattern>
    <p>Specialized cross-referencing checks</p>
    <rule context="tei:keywords">
      <assert test="@scheme = ../../../tei:encodingDesc/tei:classDecl/
        tei:taxonomy/@xml:id/concat('#',.)"><name/>/@scheme is unrecognized
      (should be on a classDecl/taxonomy in encodingDesc)</assert>
    </rule>
  </pattern>
  

  <pattern id="soft-modeling">
    <p>Miscellaneous soft modeling constraints and warnings</p>
    <rule role="warning" context="tei:div">
      <report test="empty(tei:head)">A div has no head.</report>
    </rule>
        
        <!-- Checks new  <change> template (implemented 2022-08)
                to verify the article number was replaced in the gitHub url -->
        <rule role="error" context="tei:change/tei:ref">
                <extends rule="target-uri-constraints"/>
                <report role="error" test="matches(@target,'NNNNNN')">
                        Revision description appears suspect: does not contain proper article id.
                </report>
        </rule>
        
    <rule role="warning" context="tei:head">
      <assert test="empty(preceding-sibling::tei:head)">This is not the first head in this element; please check (is this a new div or caption)?</assert>
    </rule>
    <rule role="warning" context="tei:floatingText">
      <report test="exists(ancestor::tei:floatingText)"><name/> appears inside
        floatingText</report>
    </rule>
    <rule role="warning" context="tei:note">
      <report test="exists(ancestor::tei:note)"><name/> appears inside
        note.</report>
    </rule>
    <rule role="warning" context="tei:example">
      <report test="exists(ancestor::tei:example)"><name/> appears inside
        example.</report>
    </rule>
  </pattern>

  <pattern>
    <title>constraints on ptr and ref</title>

    <rule abstract="true" id="target-uri-constraints">
      <assert test="normalize-space(@target)"><name/>/@target is empty</assert>
      <assert test="@target castable as xs:anyURI"><name/>/@target is not a URI</assert>
      <assert role="warning" test="matches(@target,'#|/')"><name/>/@target appears suspect: it has neither '#' nor '/'</assert>
    </rule>
        
    <!--checks to see when @target begins with a '#' AND does not point to an @xml:id-->
    <rule context="tei:ref[starts-with(normalize-space(@target),'#')]">
      <assert role="warning" test="substring(normalize-space(@target), 2) = //@xml:id">
        The @target of <name/> ("<value-of select="@target"/>") does not reference an @xml:id in this document
      </assert>
    </rule>
    
    <!-- warns if @target seems to point externally and is missing a protocol or is missing a # -->
    <rule context="*[ @target  and  not( starts-with( normalize-space(@target), '#') ) ]">
      <assert role="warning"
              test="starts-with( normalize-space(@target), 'http://') or
                    starts-with( normalize-space(@target), 'https://')" >
        @target should begin with 'http://' or 'https://' if it points to an external source.
      </assert>
    </rule>

    <rule context="tei:ptr[ starts-with( normalize-space(@target), '#')]">
      <extends rule="target-uri-constraints"/>
      <assert test="substring(normalize-space(@target), 2) = //tei:bibl/@xml:id" role="warning">
        The @target of <name/> ("<value-of select="@target"/>") does not reference a bibl in this document
      </assert>
        <!-- Removing the checks on @loc; actual values are too complex to model/constrain with Schematron. 
                Retaining the code in case we want it later.
      <!- $d is an arabic natural number (one or more digits not starting with 0) 
      <let name="d" value="'[1-9]\d*'"/>
      <!- $r is a lower-case roman numeral 
      <let name="r" value="'m{0,4}(cm|cd|d?c{0,3})(xc|xl|l?x{0,3})(ix|iv|v?i{0,3})'"/>
      <!- $dr is either a single $d or a hyphen-delimited pair 
      <let name="dr" value="concat($d,'(&#x2013;',$d,')?')"/>
      <!- $rr is the same as $dr, for roman numerals 
      <let name="rr" value="concat($r,'(&#x2013;',$r,')?')"/>
      <!- $drrr is a choice between $dr and $rr 
      <let name="drrr" value="concat('(',$dr,'|',$rr,')')"/>
      <!- $s is one of a set of special characters      
      <let name="s" value="'[§¶]*'"></let>      
      <!- $seq is a sequence of one or more $drrr, comma-delimited, with optional special-character prefix $s 
      <let name="seq" value="concat('^',$s,$drrr,'(, ',$drrr,')*$')"/>
      
      <assert test="not(@loc) or matches(@loc,$seq)" role="warning"
        ><name/>/@loc '<value-of select="@loc"/>' is unusual: please
        check</assert>
         -->
      <report test="contains(@loc,'-')" role="warning"><name/>/@loc contains
        '-' (hyphen): try '&#x2013;' (en-dash)</report>
      <!-- elsewhere we check bibl elements to which we have ptr cross-references,
           to ensure they also have @label -->
       
      <!--
        old code doesn't support sequences 
      <let name="d" value="'\d+'"/>
      <let name="r" value="'m{0,4}(cm|cd|d?c{0,3})(xc|xl|l?x{0,3})(ix|iv|v?i{0,3})'"/>
      <let name="page-range-regex"
        value="concat('^',$d,'(-',$d,')?$|^',$r,'(-',$r,')?','$')"/>
      <!-\-<report test="true()" role="info">page-range-regex is <value-of select="$page-range-regex"/></report>-\->
      <assert test="not(@loc) or matches(@loc,$page-range-regex)" role="warning"
        ><name/>/@loc '<value-of select="@loc"/>' is unusual: please
        check</assert>-->
    </rule>

    <rule context="tei:ptr">
      <!-- testing tei:ptr linking externally -->
      <extends rule="target-uri-constraints"/>
      <assert test="exists(parent::tei:bibl) or exists(@type='dhq-annex-embed')"><value-of select="name(..)"
        />/<name/>/@target points externally, but is not inside bibl</assert>
      <assert test="empty(@loc)"><name/> pointing externally should not have @loc</assert>
    </rule>
    <rule context="tei:ref[exists(@target)]">
      <extends rule="target-uri-constraints"/>
      <assert test="normalize-space(.)"><name/> has no text</assert>
      <report test="@type='offline'"><name/> with @target should not have @type='offline'</report>
      <report test="@type='auto'"><name/> has @type='auto': please check</report>
    </rule>
    <rule context="tei:ref">
      <assert test="@type='offline'" role="warning"><name/> has no @target, but is
      also not @type='offline'</assert>
      <assert test="normalize-space(.)"><name/> has no text</assert>
    </rule>
  </pattern>

  <pattern>
    <p>bibl checks</p>
    <rule context="tei:bibl">
      <let name="ptrs-exist" value="@xml:id = //tei:ptr/replace(@target,'^#','')"/>
      <assert test="not($ptrs-exist) or normalize-space(@label)">
        <name/> is cross-referenced by a ptr, so it requires a @label</assert>
      <report test="@label = (//tei:bibl except .)/@label" role="warning">
        <name/>/@label is not unique</report>
    </rule>
    
    <rule context="tei:biblScope[@type='pages']">
      <assert test="matches(.,'\d+(-\d+)?')"><name/>[@type='pages'] doesn't
        appear to be a page or page range</assert>
    </rule>
  </pattern>
  
  
  <pattern>
    <title>checks of code, eg and formula (math notation)</title>
    <rule context="tei:eg">
      <assert test="contains(.,'&#xA;')" role="warning"><name/> has no carriage
        return</assert>
      <assert test="string-length(.) gt 40" role="warning"><name/> is 40 chars or less</assert>
    </rule>
    <rule context="tei:code">
      <report test="string-length(.) gt 40" role="warning"><name/> is more than 40
        chars</report>
    </rule>
    <rule context="tei:formula">
      <let name="notation-type" value="string-join((@rend,@notation),'-')"/>
      <assert test="@notation=('tex','asciimath', 'mathml')">Unknown @notation on formula</assert>
      <!-- 's' flag for dot-all or the test fails when \n is present     -->
      <assert test="not($notation-type='inline-tex') or matches(string(.),'^\\\(.*\\\)$','s')">inline-tex math is expected to present wrapped escaped parentheses \( ... \)</assert>
      <assert test="not($notation-type='block-tex') or matches(string(.),'^\$\$.*\$\$$','s')">block-tex math is expected to present '$$' delimiters at start and end</assert>
      <assert test="not(@notation='asciimath') or matches(string(.),'^`.*`$','s')">asciimath formula is expected to have back-tick ` delimiters at start and end</assert>
    </rule>
  </pattern>

  <pattern>
    <title>flagging markup content</title>
    <rule context="tei:code | tei:eg | tei:formula">
      <assert test="true()"> the exceptions to the following rule </assert>
    </rule>
    <rule context="*[exists(text()[normalize-space(.)])]">
      <!-- matches any elements that don't match the first rule -->
      <report role="warning" test="exists(text()[matches(.,'&lt;|&gt;')])">
      text contains markup characters</report>
    </rule>
  </pattern>
  
  <pattern>
    <title>flagging curly quotation marks in code contexts</title>
    <rule context="tei:code | tei:eg | tei:formula">    
      <report role="warning" test="exists(text()[matches(.,'“|”|‘|’')])">
        text contains curly quotation marks
      </report>
    </rule>
  </pattern>



<pattern>
  <title>checking format of ORCID IDs</title>
  <rule context="dhq:authorInfo/tei:idno">
    <assert role="error" test="matches(.,'https://orcid.org/[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9X]')">ORCID ID is malformed. The format should be "https://orcid.org/NNNN-NNNN-NNNN-NNNN" or "https://orcid.org/NNNN-NNNN-NNNN-NNNX" (where N is any digit 0-9, and X is the letter X).</assert>
  </rule>

</pattern>

  <pattern>
    <title>flagging doubtful text content</title>
    <!-- matches any element containing non-whitespace text content
      that has no ancestor with non-whitespace text content
      (so: paragraphs, heads, etc., not inline markup) -->
    <rule role="warning" context="*[text()[normalize-space()]]
      [empty(ancestor::*/text()[normalize-space()])]">
      <report test="matches(.,'\S&#x2014;') or matches(.,'&#2014;\S')">em dash appears
        next to non-space character</report>
    </rule>
  </pattern>

  <properties>
    <property id="placeholder" role="validity">
      This is here only because ISO 19757-3:2016 appendix A requires
      it for validity. We do not actually use properties. (I do not
      even know how to.) —Syd, 2024-01-29
    </property>
  </properties>
  
</schema>
