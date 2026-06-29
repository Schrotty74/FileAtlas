# FileIndexer — Design Explorations Overview

5 visuell klar unterschiedliche Design-Vorschläge für die macOS-App **FileIndexer**.
Jeder Vorschlag ist eine vollständig eigenständige, reine Design-Shell mit statischen
Demo-Daten und eigenem `#Preview` (1200 × 800). Es gibt **keinen geteilten Code**
zwischen den Designs — jedes Paar `ContentView_*` + `Theme_*` steht für sich.

## Vergleichstabelle

| # | Name | Stimmung | Akzentfarbe | Sidebar-Glas | Font | Corner | Row | Besonderheit |
|---|------|----------|-------------|--------------|------|--------|-----|--------------|
| 1 | **Pro Dark** | Developer / Terminal | Mint-Cyan `#29F7BD` | `.opaque` (sehr dunkel) | SF Mono | 6 | 30 | Monospaced Pfade & Größen, Terminal-Tabelle |
| 2 | **Clean Light** | Minimalistisch, paperlike | Indigo `#5C66C7` | `.ultraThin` (`.clear`) | SF Pro | 12 | 46 | Keine Trennlinien, nur Abstände |
| 3 | **Warm Studio** | Kreativ, Foto/Design | Orange `#F2851F` | `.regular` (warm getönt) | SF Pro Rounded | 16 | 64 | Große Thumbnails in Liste & Detail |
| 4 | **Midnight Teal** | Edel, Finanz/Analyse | Teal `#21A89E` + Gold | `.thin` (Teal-Tint) | SF Pro (tight) | 8 | 28 | Dichteste 5-Spalten-Tabelle, Gold-Badges |
| 5 | **Frosted Vivid** | Modern, App-Store | Purple `#8C4DF5` + Blue | `.ultraThin` (max. Frosted) | SF Pro (heavy) | 18 | 52 | Glow-Auswahl, Wallpaper hinter Glas |

## Gemeinsame Rahmenbedingungen

- macOS 26, **Liquid Glass** nativ — `.glassEffect()` in jeder Sidebar, aber unterschiedlich stark ausgeprägt (von `.clear`/minimal bis getönt/prominent)
- Dark- **und** Light-Mode-tauglich (1 & 4 & 5 dunkel, 2 & 3 hell — jeweils via `.preferredColorScheme`)
- Alle nutzen `NavigationSplitView` mit **drei Spalten** (Sidebar · Dateiliste · Detail-Panel)
- Toolbar mit Suchfeld über `.searchable(placement: .toolbar)`
- Nur System-Fonts: **SF Pro**, **SF Mono**, **SF Pro Rounded** via `.fontDesign()`
- Echte, realistische Demo-Dateinamen (keine „File 1"-Platzhalter)

## Ordnerstruktur

```
FileIndexer_Designs/
├── Design1_ProDark/        ContentView_ProDark.swift      · Theme_ProDark.swift      · README.md
├── Design2_CleanLight/     ContentView_CleanLight.swift   · Theme_CleanLight.swift   · README.md
├── Design3_WarmStudio/     ContentView_WarmStudio.swift   · Theme_WarmStudio.swift   · README.md
├── Design4_MidnightTeal/   ContentView_MidnightTeal.swift · Theme_MidnightTeal.swift · README.md
├── Design5_FrostedVivid/   ContentView_FrostedVivid.swift · Theme_FrostedVivid.swift · README.md
└── DesignOverview.md
```

## Hinweise

- Jedes Design wird über sein eigenes **`#Preview`** in Xcode beurteilt — keine laufende App nötig.
- Die `Theme_*`-Structs entsprechen der `ThemeDefinition` aus dem Briefing; sie sind nur
  eindeutig benannt (`ProDarkTheme`, `CleanLightTheme`, …) mit verschachtelten
  `SidebarStyle`/`FontStyle`-Enums, damit es im selben Build-Target keine Namenskollision gibt.
- Noch **nicht** in die echte App eingebunden — `FileAtlasApp` zeigt weiterhin die originale `ContentView`.
