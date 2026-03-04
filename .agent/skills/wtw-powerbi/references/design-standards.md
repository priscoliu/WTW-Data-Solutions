# Power BI Design Standards

Complete guide to grid system, spacing, typography, and visual styling for WTW Power BI reports.

## Canvas & Grid System

### Standard Canvas Sizes

| Canvas Type | Dimensions | Use Case |
|-------------|------------|----------|
| **Presentations & Dashboards** | 1280 x 720px | Standard presentations, executive dashboards |
| **Complex Reports** | 1440 x 1080px | Detailed analytical reports with many visuals |

### 12-Column Grid System

Power BI reports should align to a 12-column grid for clean, professional layouts.

**1440px Canvas**:
- **Total Width**: 1440px
- **Side Margins**: 80px each side
- **Content Area**: 1280px (1440 - 160)
- **Gutter**: 26px between columns
- **Column Width**: ~83px

**1280px Canvas**:
- **Total Width**: 1280px
- **Side Margins**: 60px each side
- **Content Area**: 1160px (1280 - 120)
- **Gutter**: 24px between columns
- **Column Width**: ~75px

**Key Principle**: All visuals should align to grid columns for clean, professional layouts.

### Standard Card Widths (Grid-Aligned)

Based on 1280px canvas with 12-column grid:

| Columns Span | Width | Use Case | Example |
|--------------|-------|----------|---------|
| 3 columns | 268px | Single KPI card | Revenue KPI |
| 4 columns | 364px | Compact scorecard | 3-metric card |
| 6 columns | 580px | Executive summary card ✓ | Performance scorecard |
| 8 columns | 796px | Wide analytical card | Trend analysis |
| 12 columns | 1160px | Full-width dashboard banner | Page header |

**Height Recommendations**:
- KPI Cards: `320-400px`
- Scorecards: `300-350px`
- Executive Summary: `350-450px`
- Full-width banners: `200-250px`

## Spacing & Padding Standards

Use **4px or 8px base units** for all spacing to maintain consistency.

### Vertical Spacing

| Setting | Value | Usage |
|---------|-------|-------|
| **Vertical Page Margin** | 54px | Empty space at top/bottom of report page |
| **Section Padding** | 32px | Vertical gap between major visual groups |
| **Visual Padding** | 16px | Internal padding for all native visuals (charts, tables) |
| **Card Padding** | 20px | Internal padding for HTML card containers |

### Horizontal Spacing

| Setting | Value | Usage |
|---------|-------|-------|
| **Side Margins** | 60-80px | Left/right page margins |
| **Visual Gutter** | 24-26px | Space between adjacent visuals |
| **Grid Gap (HTML)** | 12px | Gap between grid items in HTML cards |

## Typography System

### Font Size Scale

Use **pixels (px)** for consistency with Power BI settings.

| Variable | Pixels | Points | Use Case |
|----------|--------|--------|----------|
| `text-xs` | 12px | 8.25pt | Axis labels, footer text, captions |
| `text-sm` | 14px | 10.5pt | Body text, descriptions, secondary KPI labels |
| `text-md` | 16px | 12pt | Visual titles, subtitles, paragraph text |
| `text-lg` | 18px | 13.5pt | Sub-headings, larger visual titles, card values |
| `display-sm` | 24px | 18pt | Main KPI values, small display headings |
| `display-md` | 30px | 22.5pt | Medium display headings, key metrics |
| `display-lg` | 36px | 27pt | Large dashboard titles, primary headings |
| `display-xl` | 54px | 40.5pt | High-impact numbers on dedicated cards |
| `display-2xl` | 72px | 54pt | Hero titles on large overview dashboards |

### Typography Guidelines

**Accessibility**:
- Default body text: **16px (12pt)** minimum
- Minimum readable size: **12px (9pt)** — use sparingly
- High-contrast text: Use `#1E293B` on white backgrounds

**Font Families**:
- Primary: **Segoe UI** (Power BI default)
- Web/HTML cards: **Segoe UI, Inter, system-ui, sans-serif**

**Font Weights**:
- Regular (400): Body text, labels
- Semibold (600): Visual titles, sub-headings
- Bold (700): KPI values, headings, status badges

## Shadows & Visual Styling

### Multi-Layer Shadow System (Recommended)

**Outer Container Shadow** (premium, elevated look):
```css
box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1),
            0 4px 6px -2px rgba(0, 0, 0, 0.05);
```

**Use for**: Main card containers, HTML scorecard wrappers, elevated panels

**Inner Card Shadow** (subtle depth):
```css
box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1),
            0 1px 2px 0 rgba(0, 0, 0, 0.06);
```

**Use for**: Individual metric cards within containers, nested elements

### Single Soft Shadow (Alternative)

For native Power BI visuals, use these settings:

| Property | Default (Harsh) | Recommended (Soft) |
|----------|-----------------|---------------------|
| **Color** | Black | Light Gray |
| **Angle** | 45° | 90° (straight down) |
| **Distance** | 10px | 4px |
| **Size** | 3px | 1px |
| **Blur** | 10px | 8px |
| **Transparency** | 70% | 70% |

**Pro Tips**:
- Use multi-layer shadows for premium HTML cards
- Use single soft shadow for simple native visuals
- For colored backgrounds, match shadow color to visual's theme for a "glow" effect
- Never use harsh black shadows — always use soft gray

## Borders & Visual Effects

### Border System

**Light Border** (subtle separation):
```css
border: 1px solid #F3F4F6;
```

**Medium Border** (standard separation):
```css
border: 1px solid #E5E7EB;
```

**Themed Border** (performance-colored with opacity):
```css
border: 1px solid #7C3AED20;  /* 20 = ~12% opacity */
```

### Border Radius

| Element | Border Radius | Use Case |
|---------|---------------|----------|
| **Outer Containers** | 12px | Main card containers |
| **Inner Cards** | 8px | Nested metric cards |
| **Progress Bars** | 5px | Progress bar tracks |
| **Status Badges** | 8px | Small status indicators |
| **Buttons** | 6px | Interactive elements |

## Background Patterns

### Gradient Backgrounds

**Container Background** (subtle gradient):
```css
background: linear-gradient(145deg, #FFFFFF 0%, #F9FAFB 100%);
```

**Performance Bar Gradients** (see color-system.md for full palette):
```css
/* Outstanding (WTW Purple) */
background: linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%);

/* Target Met (Green) */
background: linear-gradient(135deg, #10B981 0%, #059669 100%);

/* Near Target (Cyan) */
background: linear-gradient(135deg, #06B6D4 0%, #0891B2 100%);
```

### Tinted Backgrounds

**Subtle Tinted Background** (for summary panels):
```css
background: linear-gradient(135deg, #F3F4F6 0%, rgba(255,255,255,0.8) 100%);
border: 1px solid #7C3AED25;
```

## Visual Organization Best Practices

### Selection Pane Naming

Use consistent naming convention: `[Section] - [Visual Type] - [Description]`

**Examples**:
- `Header - Card - Total Revenue`
- `KPIs - Card - Sales vs Target`
- `Charts - Line Chart - Monthly Trend`
- `Tables - Matrix - Product Details`
- `Filters - Slicer - Date Range`

**Benefits**:
- Easy navigation in Selection pane
- Logical grouping of related visuals
- Clear documentation for maintenance

### Visual Limits per Page

- **Optimal**: ≤10 visuals for best performance
- **Maximum**: ≤15 visuals for acceptable performance
- **If exceeding 15**: Consider using bookmarks for multiple view states instead of separate pages

### Z-Index / Layer Order

Standard layering from back to front:
1. Background shapes/rectangles
2. Main visuals (charts, tables)
3. Overlays (modal popups)
4. Filters/slicers (if floating)

## Accessibility Guidelines

### WCAG AA Contrast Requirements

- **Normal text**: 4.5:1 contrast ratio (minimum)
- **Large text** (18pt+ or 14pt+ bold): 3:1 contrast ratio (minimum)

**Test tools**: WebAIM Contrast Checker, Color Contrast Analyzer

### Color Independence

- **Never rely solely on color** to convey information
- Always include **text labels + icons + color** for status indicators
- Example: Don't just use red/green — add "Above Target" / "Below Target" text

### Keyboard Navigation

- Ensure all interactive elements (slicers, buttons) are keyboard-accessible
- Test tab order flows logically through the report

## Performance Optimization

### Visual Limits

- Limit visuals per page: ≤15 for optimal performance
- Use bookmarks for multiple view states instead of creating many pages
- Minimize use of custom visuals (they're slower than native visuals)

### Data Model

- Use **star schema architecture**
- Implement proper relationships (avoid bi-directional unless necessary)
- Create dedicated **date table with calendar hierarchy**
- Remove unused columns from model

### DAX Optimization

- Use **variables** to avoid recalculation (`VAR _variable = ...`)
- **Filter early** in calculation context
- Use `SELECTEDVALUE()` instead of `VALUES()` for single value checks
- Avoid complex calculated columns (use measures instead)

## Checklist: Design Standards Compliance

Before publishing, verify:
- [ ] Canvas size is standard (1280x720 or 1440x1080)
- [ ] All visuals align to 12-column grid
- [ ] Spacing uses 4px/8px base units
- [ ] Typography uses standard scale (12px → 72px)
- [ ] Shadows applied (multi-layer or soft single)
- [ ] Visual padding set to 16px
- [ ] Selection pane uses consistent naming
- [ ] Visual count per page ≤15
- [ ] WCAG AA contrast ratios met
- [ ] Performance Analyzer shows no visual >3s load time
