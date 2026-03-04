---
name: wtw-powerbi
description: WTW-branded Power BI design standards including purple color system, multi-layer shadows, typography scale, grid layouts, and DAX patterns for creating professional reports and HTML card components.
allowed-tools:
  - Read
  - Write
  - Edit
  - mcp__powerbi-modeling__measure_operations
  - mcp__powerbi-modeling__dax_query_operations
  - mcp__powerbi-modeling__table_operations
  - mcp__powerbi-modeling__column_operations
---

# Power BI Design System & Best Practices

Comprehensive design system for creating professional, WTW-branded Power BI reports with consistent visual standards and DAX patterns.

## WTW Brand Essentials

**Primary Brand Color**: WTW Corporate Purple `#7C3AED`

**Standard Canvas Sizes**:

- Presentations & Dashboards: `1280 x 720px`
- Complex Reports: `1440 x 1080px`

**Core Principles**:

- 12-column grid system for alignment
- Multi-layer shadow system for depth
- Performance-based color coding
- PascalCase for measures: `[Measure Name]`
- Underscore prefix for DAX variables: `_variableName`

## Quick Start

### Typography Scale

| Size | Pixels | Use Case |
|------|--------|----------|
| `text-xs` | 12px | Axis labels, captions |
| `text-sm` | 14px | Body text, secondary labels |
| `text-md` | 16px | Visual titles, paragraphs |
| `text-lg` | 18px | Sub-headings, card values |
| `display-sm` | 24px | Main KPI values |
| `display-md` | 30px | Medium headings |
| `display-lg` | 36px | Large dashboard titles |
| `display-xl` | 54px | High-impact numbers |

### Performance Color System

| Level | Threshold | Primary Color | Background | Use Case |
|-------|-----------|---------------|------------|----------|
| **Outstanding** | ≥115% | `#7C3AED` (WTW Purple) | `#F3F4F6` | Exceptional performance |
| **Target Met** | 100-114% | `#059669` (Green) | `#ECFDF5` | Goal achieved |
| **Near Target** | 90-99% | `#0891B2` (Cyan) | `#F0F9FF` | Approaching goal |
| **Below Target** | 80-89% | `#F59E0B` (Amber) | `#FFFBEB` | Needs attention |
| **Critical** | <80% | `#DC2626` (Red) | `#FEF2F2` | Urgent action |

### Shadows (Multi-Layer)

**Outer container (premium)**:

```css
box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
```

**Inner cards (subtle)**:

```css
box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
```

## Reference Guides

### Design Standards

- **Grid & Spacing**: See [references/design-standards.md](references/design-standards.md)
  - 12-column grid calculations
  - Spacing system (4px/8px base units)
  - Standard card widths
  - Visual padding guidelines

### DAX Patterns

- **Measures & Variables**: See [references/dax-patterns.md](references/dax-patterns.md)
  - Performance level detection logic
  - Color palette variables
  - Standard measure patterns (YTD, YoY, vs Target)
  - Text hierarchy colors

### HTML Cards

- **Components & Layouts**: See [references/html-cards.md](references/html-cards.md)
  - Container structures
  - Grid layouts (3-column, 4-column)
  - Progress bars with benchmarks
  - Status badges
  - Summary panels

### Color System

- **Complete Palette**: See [references/color-system.md](references/color-system.md)
  - WTW purple variations
  - Performance color thresholds
  - Gradient definitions
  - Neutral text hierarchy
  - Accessibility guidelines

### Data Modeling

- **Semantic Model Design**: See [references/data-modeling.md](references/data-modeling.md)
  - Star schema decision tree
  - Fact/dimension table patterns
  - Dim_Date calendar table template (Australian FY)
  - Relationship design (DateKey, role-playing, multi-fact)
  - Rollup row handling
  - Validation checklist

### Power Query (M Code)

- **M Code Patterns**: See [references/power-query.md](references/power-query.md)
  - Lakehouse connection boilerplate
  - Column operations (select, rename, reorder)
  - Type casting and currency cleaning
  - Null handling patterns
  - Filtering and unpivoting
  - Standard fact table recipe

## Best Practices

### Report Organization

- Group related visuals in Selection pane with clear labels
- Use consistent naming: `[Section] - [Visual Type] - [Description]`
- Limit visuals per page: ≤15 for optimal performance
- Always display active date filter prominently

### KPI Cards

- Never show isolated metrics — always include comparison context
- Show target comparison, previous period, and variance
- Use appropriate font size from typography scale
- Apply performance color coding

### Visual Selection

- **KPI Cards**: Single high-level metrics with context
- **Bar/Column**: Comparing ≤20 categories
- **Line Charts**: Continuous time series, trends
- **Tables/Matrix**: Detailed drill-down (use sparingly)
- **Avoid**: 3D charts, pie charts with >5 slices, dual-axis charts

### Report Navigation Pattern

```
┌─────────────────────────────────────┐
│  Logo | Report Title | Date Filter  │ ← Header (54px margin)
├─────────────────────────────────────┤
│  [KPI Cards Section - 32px gap]     │ ← display-sm text
├─────────────────────────────────────┤
│  [Main Visual Section]              │ ← 16px padding per visual
├─────────────────────────────────────┤
│  [Detail Tables/Drill-down]         │
└─────────────────────────────────────┘
```

**Page Types**:

1. **Executive Overview**: High-level KPIs only
2. **Operational Dashboard**: Mix of KPIs and trend charts
3. **Detailed Analysis**: Tables, drill-through enabled
4. **Documentation**: Data dictionary, refresh schedule

### Data Labels Strategy

- Dense charts: Use tooltips, avoid all data labels
- Simple charts: Show key data labels only
- Alternative: Add summary table below for exact values

## Common DAX Patterns

### Performance Detection

```dax
VAR _achievementRatio = DIVIDE([Actual], [Target], 0)
VAR _performanceLevel =
    SWITCH(TRUE(),
        _achievementRatio >= 1.15, "outstanding",
        _achievementRatio >= 1.0, "target_met",
        _achievementRatio >= 0.9, "near_target",
        _achievementRatio >= 0.8, "below_target",
        "critical"
    )
```

### Dynamic Title with Filter Context

```dax
Dynamic Title =
VAR _SelectedPeriod = SELECTEDVALUE('Date'[Year Month])
RETURN
    IF(
        ISFILTERED('Date'[Year Month]),
        "Sales Performance - " & _SelectedPeriod,
        "Sales Performance - All Periods"
    )
```

### Status Badge Logic

```dax
VAR _icon = SWITCH(TRUE(),
    _achievementRatio >= 1.15, "⭐",
    _achievementRatio >= 1.0, "🎯",
    _achievementRatio >= 0.9, "📈",
    _achievementRatio >= 0.8, "⚠️",
    "🚨"
)
```

## Checklist Before Publishing

- [ ] All visuals aligned to 12-column grid
- [ ] Consistent font sizes (typography scale)
- [ ] Multi-layer shadows applied
- [ ] Visual padding set to 16px
- [ ] All visuals labeled in Selection pane
- [ ] Date range visible on canvas
- [ ] KPIs include comparison context
- [ ] Decimal places appropriate for metric type
- [ ] Performance Analyzer run (no visual >3s load)
- [ ] Cross-filtering behavior tested

## Resources

- **Design Standards**: [references/design-standards.md](references/design-standards.md)
- **DAX Patterns**: [references/dax-patterns.md](references/dax-patterns.md)
- **HTML Cards**: [references/html-cards.md](references/html-cards.md)
- **Color System**: [references/color-system.md](references/color-system.md)
- **Data Modeling**: [references/data-modeling.md](references/data-modeling.md)
- **Power Query**: [references/power-query.md](references/power-query.md)
