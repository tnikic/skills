# Color Palette

Central color tokens for skills that produce visual output — Mermaid diagrams, badges, HTML reports, issue labels.

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#f28482` | Headings, emphasis, primary badges |
| `secondary` | `#84a59d` | Subheadings, links, secondary elements |
| `accent` | `#f6bd60` | Highlights, callouts, warnings |
| `surface` | `#f7ede2` | Backgrounds, fills, diagram regions |
| `muted` | `#f5cac3` | Borders, dividers, subtle separators |

## Label scope mapping

Label scope→color assignments are the single source of truth in [`label-taxonomy.md`](label-taxonomy.md). This file defines only the color tokens.

## Usage in Mermaid

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#f28482', 'secondaryColor': '#84a59d', 'tertiaryColor': '#f7ede2'}}}%%
```

Reference tokens by hex value. Mermaid `init` directives go at the top of every diagram that uses color.
