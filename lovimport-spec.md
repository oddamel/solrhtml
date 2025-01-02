# Lovdata Importspesifikasjon

## Oversikt
Dette dokumentet spesifiserer prosessen for import av lovinnhold fra Lovdata til Solr.

## Kildedata Struktur
Lover fra Lovdata kommer i HTML-format med følgende hovedelementer:

- Lovmetadata (tittel, legacy ID)
- Hierarkisk innholdsstruktur ved bruk av `<section>` og `<article>` elementer
- Seksjonstyper identifisert av `data-name` attributter
- Artikkelinnhold med spesifikke klasser (`legalArticle`, `legalP`)

## Hierarkisk Strukturstøtte

### Grunnleggende Struktur
Den enkleste lovstrukturen følger dette mønsteret:

```
Lov
└── Kapittel
    └── Paragraf
        └── Ledd
```

### Utvidet Struktur
Mer komplekse lover kan inkludere flere nivåer:
```
Lov
├── Del
│   └── Underdel
│       └── Kapittel
│           └── Underkapittel
│               └── Paragraf
│                   └── Ledd
└── Kapittel
    └── Paragraf
        └── Ledd
```

## ID-genereringsregler

### Format Mønster
ID-er genereres hierarkisk etter følgende mønster:
- Lov: `lov-{lovnummer}`
- Del: `lov-{lovnummer}/del-{romersk}`
- Underdel: `lov-{lovnummer}/del-{romersk}/underdel-{nummer}`
- Kapittel: `lov-{lovnummer}/kapittel-{romersk}`
- Paragraf: `lov-{lovnummer}/[.../]paragraf-{nummer}`
- Ledd: `{parent-id}/ledd-{posisjon}`

### Eksempler
```
lov-19670210
lov-19670210/del-I
lov-19670210/del-I/kapittel-1
lov-19670210/del-I/kapittel-1/paragraf-1
lov-19670210/del-I/kapittel-1/paragraf-1/ledd-1
```

## Dokumentstruktur

### Påkrevde Felter
Hvert Solr-dokument må inneholde:
- `id`: Unik identifikator som følger ID-genereringsreglene (Unique identifier)
- `title`: Nodetittel (Node title)
- `nodeType`: Nodetype (Node type: lov, del, kapittel, paragraf, etc.)
- `_nest_parent_`: ID til foreldrenode (Parent node ID)
- `bodytext`: Innholdstekst for ledd (Content text for subsections)
- `source`: Satt til "Lovdata" for lovdokumenter (Set to "Lovdata" for law documents)

### Ekstra Metadatafelter
Valgfrie metadatafelter som kan inkluderes:
- `ikrafttredelse`: Dato for når loven trer i kraft
- `departement`: Ansvarlig departement

### HTML Strukturkartlegging
Importprosessen kartlegger HTML-elementer til Solr-dokumenter som følger:

- `<dd class="legacyID">`: Kilde for lov-ID (Source for law ID, format: LOV-YYYY-MM-DD-nr)
- `<dd class="title">`: Lovtittel (Law title)
- `<section data-name="...">`: Strukturelementer (Structure elements: del, kapittel, etc.)
- `<article class="legalArticle">`: Paragraf (Section)
- `<article class="legalP">`: Ledd (Subsection)
- `<h2>`, `<h3>`: Titler for respektive elementer (Titles for respective elements)
- `<span class="legalArticleValue">`: Paragrafnummer (Section number, f.eks. "§ 3")
- `<span class="legalArticleTitle">`: Paragraftittel (Section title)

### Strengmanipuleringsregler
Importprosessen må håndtere:
- Fjerning av "LOV-" prefiks fra legacy ID-er
- Konvertering av understreker til bindestreker i ID-er
- Korrekt håndtering av romertall i kapittelnumre
- Konsistent formatering av paragrafnumre (fjerne § symbol)

### Nodetyper
- `law`: Rot-lovdokument (Root law document)
- `del`: Del (Part)
- `underdel`: Underdel (Subpart)
- `chapter`: Kapittel (Chapter)
- `section`: Paragraf (Section)
- `subsection`: Ledd (Subsection)

## XSLT Implementasjonsnotater

### Grunnleggende Implementasjon
For lover med enkel kapittel->paragraf hierarki (chapter->section hierarchy), bruk den grunnleggende XSLT-implementasjonen (lov_med_id_1111.xslt). Denne håndterer:
- Grunnleggende lovstruktur (Basic law structure)
- Kapittel- og paragrafkartlegging (Chapter and section mapping)
- Ledd-innholdsuttrekking (Subsection content extraction)

### Dynamisk Implementasjon
For komplekse hierarkiske strukturer, bruk den dynamiske XSLT-implementasjonen som:
- Oppdager strukturnivåer fra data-name attributter
- Håndterer variable nøstingsdybder
- Opprettholder korrekte foreldre-barn-relasjoner
- Støtter fremtidig utvidbarhet

## Valideringskrav

### Strukturvalidering
- Alle noder må ha gyldige foreldrereferanser
- ID-er må følge spesifisert format
- Påkrevde felter må være til stede
- Nodetyper må være gyldige

### Innholdsvalidering
- Tittelfelter skal ikke være tomme
- Ledd må ha bodytext-innhold
- Foreldrereferanser må peke til eksisterende dokumenter

## Feilhåndtering
- Ugyldig struktur skal føre til importfeil
- Manglende påkrevde felter skal føre til importfeil
- Ugyldige foreldrereferanser skal føre til importfeil
- Alle feil skal logges med spesifikke feilmeldinger