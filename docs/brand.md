# FlumenData Brand Guidelines

This document defines the visual identity and brand guidelines for FlumenData.

## Color Palette

### Primary Colors

| Token | Hex | Usage |
|-------|-----|-------|
| **FD Dark** | `#14171C` | Highlight backgrounds, dark mode snippets |
| **FD Cyan (Trino)** | `#20EFFD` | Trino references, query highlights |
| **FD Orange (JupyterLab)** | `#FDA931` | JupyterLab badges and experimentation |
| **FD Blue / Teal (Superset)** | `#0082C8` | BI / Superset elements |
| **FD Lime** | `#B8E762` | "Healthy/running" states |
| **FD Teal Deep** | `#157983` | Foundation services (PostgreSQL/MinIO) and navigation |
| **FD Light** | `#F5F7FB` | Neutral backgrounds, cards |
| **FD Gray / Dark** | `#9CA3AF` / `#4B5563` | Secondary text and neutral states |

### Service Color Mapping

Respect the service-specific color mapping:
- **JupyterLab** → Orange (`#FDA931`)
- **Trino** → Cyan (`#20EFFD`)
- **Superset** → Blue/Teal (`#0082C8`)
- **Foundation** (PostgreSQL, MinIO) → Teal Deep (`#157983`) with Lime accents
- **Healthy/Running** → Lime (`#B8E762`)
- **Neutral/Inactive** → Gray

### Usage Guidelines

- Use lime for "healthy/running" status indicators
- Use gray for neutral/inactive states
- Limit diagrams to 2-3 vibrant colors to maintain clarity
- Maintain consistency across documentation, badges, and UI elements

## Typography

### Font Families

| Context | Font | Notes |
|---------|------|-------|
| **Headings / Logo** | Space Grotesk (700 for H1, 600 for H2/H3) | Identity font used in README and MkDocs |
| **Body Text** | Inter (400/500) | Applied via `docs/assets/styles/brand.css` |
| **Code & Config** | JetBrains Mono (fallback: Fira Code) | Commands, SQL, YAML, docker-compose |

### Font Loading

- Documentation loads these fonts and the color palette via `docs/assets/styles/brand.css`
- Ensure consistent font usage across all documentation pages
- Use monospace fonts for all technical content (commands, code blocks, file paths)

## Logo Assets

### Available Files

Logo files are available in `docs/assets/images/`:
- `flumendata-logowithname.png` - Full logo with name (primary usage)
- `flumendata-logoonly.png` - Icon-only version
- `flumendata.ico` - Favicon for web pages

### Logo Usage

- Use `flumendata-logowithname.png` for:
  - README hero sections
  - Documentation headers
  - Social media banners
  - Presentation covers

- Use `flumendata-logoonly.png` for:
  - Small icons
  - Favicons
  - Badge components
  - Where space is limited

- Use `flumendata.ico` for:
  - Website favicons
  - Browser tabs
  - Bookmarks

### Logo Specifications

- Primary logo width: 360px in README hero
- Maintain aspect ratio when resizing
- Ensure adequate white space around logo
- Do not distort or modify logo colors

## Badge Styling

FlumenData uses shields.io badges with brand colors:

```markdown
![Docker](https://img.shields.io/badge/Docker-20.10%2B-157983.svg)
![Python](https://img.shields.io/badge/Python-3.6%2B-3776AB.svg)
![Spark](https://img.shields.io/badge/Spark-4.0.1-FDA931.svg)
![Delta Lake](https://img.shields.io/badge/Delta%20Lake-4.0.0-20EFFD.svg)
```

### Badge Color Usage

- **Docker** → Teal Deep (`157983`)
- **Python** → Python Blue (`3776AB`)
- **Spark** → Orange (`FDA931`)
- **Delta Lake** → Cyan (`20EFFD`)

Maintain this color scheme for consistency across repository badges.

## Documentation Theme

FlumenData uses MkDocs Material with the following theme configuration:

```yaml
theme:
  name: material
  palette:
    - scheme: default
      primary: custom
      accent: custom
  font:
    text: Inter
    code: JetBrains Mono
```

Custom CSS in `docs/assets/styles/brand.css` applies the FlumenData color palette to the documentation site.

## Visual Identity Principles

1. **Consistency** - Use defined colors and fonts consistently across all materials
2. **Clarity** - Limit color usage in diagrams (2-3 colors max) for readability
3. **Service-Specific Colors** - Map colors to services for instant recognition
4. **Professional** - Maintain clean, modern aesthetic with adequate whitespace
5. **Accessible** - Ensure sufficient contrast for readability

## Diagram Guidelines

### Mermaid Diagrams

When creating architecture diagrams:
- Use service-specific colors for nodes
- Use Teal Deep for foundation services
- Use Orange for analytics tier
- Use Cyan for SQL tier
- Use Blue for BI tier
- Keep color palette limited (2-3 colors per diagram)

### Architecture Diagrams

- Show clear tier separation (Tier 0 → Tier 3)
- Use directional arrows to show data flow
- Label each component with name and version
- Include brief descriptions (e.g., "1 Master + 2 Workers")

## Brand Voice

FlumenData's brand voice is:
- **Technical** - Precise, accurate technical terminology
- **Approachable** - Clear explanations without jargon overload
- **Professional** - Production-ready, enterprise-focused messaging
- **Practical** - Focus on real-world usage and benefits

## Documentation Style

- Use emojis sparingly for section headers (e.g., 🎯, ✨, 🏗️)
- Keep paragraphs concise (2-3 sentences max)
- Use bullet points for lists
- Include code examples with proper syntax highlighting
- Link to detailed guides for complex topics

## Contributing to Brand Guidelines

When proposing changes to brand guidelines:
1. Open an issue describing the proposed change
2. Provide rationale and examples
3. Ensure consistency with existing materials
4. Update all affected documentation and assets

---

**Maintained by:** [Luciano Mauda Junior](https://github.com/lucianomauda)
**Last Updated:** 2025-01-19
