# Design 1 — „Pro Dark"

| Eigenschaft | Wert |
|-------------|------|
| **Name** | Pro Dark |
| **Stimmung** | Professionelles Power-Tool, Developer-Werkzeug, Terminal-Nähe |
| **Farbpalette** | Fast monochromes Dunkelgrau (`#0E1018` Oberflächen), einziger Akzent: leuchtendes Mint/Cyan (`#29F7BD`) |
| **Typografie** | SF Mono für Dateinamen, Pfade & Größen; SF Pro nur für „Kind"-Labels |
| **Sidebar** | Sehr dunkles, fast opakes Glas (`.opaque`) mit dunkel getöntem `glassEffect` |
| **Corner Radius** | 6 pt (kantig, technisch) |
| **Row Height** | 30 pt |
| **Zielgruppe** | Entwickler:innen, Power-User, Terminal-affine Nutzer:innen |

## Besonderheit
Dateigrößen und Pfade werden **monospaced wie im Terminal** dargestellt, inklusive
einer Spaltenüberschrift im `NAME · SIZE · MODIFIED`-Stil und einer `rw-r--r--`
Permissions-Zeile im Detail-Panel. Die aktive Auswahl wird durch einen vertikalen
Akzent-Balken links + dezente Akzent-Fläche markiert.

> Reine Design-Shell. Vorschau über das `#Preview` „Design 1 — Pro Dark" (1200 × 800).
