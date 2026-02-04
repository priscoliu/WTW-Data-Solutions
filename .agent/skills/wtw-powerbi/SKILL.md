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

A comprehensive design system for creating professional, consistent, and user-friendly Power BI reports. This guide covers layout, spacing, typography, styling, and best practices for Power BI development.

---

## Canvas & Grid System

### Standard Canvas Sizes
- **Presentations & Dashboards:** `1280 x 720px`
- **Complex Reports:** `1440 x 1080px`

### 12-Column Grid System

| Canvas Width | Columns | Side Margins | Gutter | Content Area | Column Width |
|--------------|---------|--------------|--------|--------------|--------------|
| **1440px**   | 12      | 80px         | 26px   | 1280px       | ~83px        |
| **1280px**   | 12      | 60px         | 24px   | 1160px       | ~75px        |

**Key Principle:** All visuals should align to the grid for clean, professional layouts.

---

## Spacing & Padding Standards

Use **4px or 8px base units** for all spacing to maintain consistency.

| Setting                    | Value | Usage                                                      |
|----------------------------|-------|------------------------------------------------------------|
| **Vertical Page Margin**   | 54px  | Empty space at top/bottom of report page                   |
| **Section Padding**        | 32px  | Vertical gap between major visual groups                   |
| **Visual Padding**         | 16px  | Internal padding for all native visuals (charts, tables)   |

---

## Typography System

### Font Size Scale

Use **pixels (px)** for consistency with Power BI settings.

| Variable      | Pixels | Points | Use Case                                              |
|---------------|--------|--------|-------------------------------------------------------|
| `text-xs`     | 12px   | 8.25pt | Axis labels, footer text, captions                    |
| `text-sm`     | 14px   | 10.5pt | Body text, descriptions, secondary KPI labels         |
| `text-md`     | 16px   | 12pt   | Visual titles, subtitles, paragraph text              |
| `text-lg`     | 18px   | 13.5pt | Sub-headings, larger visual titles, card values       |
| `display-sm`  | 24px   | 18pt   | Main KPI values, small display headings               |
| `display-md`  | 30px   | 22.5pt | Medium display headings, key metrics                  |
| `display-lg`  | 36px   | 27pt   | Large dashboard titles, primary headings              |
| `display-xl`  | 54px   | 40.5pt | High-impact numbers on dedicated cards                |
| `display-2xl` | 72px   | 54pt   | Hero titles on large overview dashboards              |

### Accessibility Guidelines
- **Default body text:** 16px (12pt)
- **Minimum readable size:** 12px (9pt) - use sparingly

---

## Shadows & Visual Styling

### Multi-Layer Shadow System (Preferred)

**Outer Container Shadow (Premium Look):**
```css
box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 
            0 4px 6px -2px rgba(0, 0, 0, 0.05);
```

**Inner Card Shadow (Subtle Depth):**
```css
box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 
            0 1px 2px 0 rgba(0, 0, 0, 0.06);
```

**Alternative: Single Soft Shadow**

| Property        | Default (Harsh) | Recommended (Soft) |
|-----------------|-----------------|---------------------|
| **Color**       | Black           | Light Gray          |
| **Angle**       | 45°             | 90°                 |
| **Distance**    | 10px            | 4px                 |
| **Size**        | 3px             | 1px                 |
| **Blur**        | 10px            | 8px                 |
| **Transparency**| 70%             | 70%                 |

**Pro Tips:**
- Use multi-layer shadows for premium cards and containers
- Use single soft shadow for simple visuals
- For colored backgrounds, match shadow color to visual's theme for a "glow" effect

---

## Best Practices

### 1. Visual Organization
- **Group related visuals** in Selection pane with clear labels
- Use consistent naming: `[Section] - [Visual Type] - [Description]`
- Example: `Header - Card - Total Revenue`

### 2. Modals for Context
- Use modal pop-ups for:
  - Business logic explanations
  - Data refresh schedules
  - Methodology notes
- Keep main canvas clean and focused

### 3. Date Range Visibility
- Always display active date filter on canvas
- Use text box or card visual
- Position prominently (top-right or header area)

### 4. KPI Context
**Never show isolated metrics**. Always include:
- Target comparison
- Previous period comparison
- Variance indicators (%, Δ)

**Example Format:**
```
$12.5M
Target: $15M (-17%)
vs LY: $10M (+25%)
```

### 5. Data Labels Strategy
- **Dense charts:** Use tooltips, avoid all data labels
- **Simple charts:** Show key data labels only
- **Alternative:** Add summary table below chart for exact values

### 6. Minimize Redundancy
- Hide unnecessary axis titles if visual title is descriptive
- Remove axis values when data labels are shown
- Simplify legends when colors are self-explanatory

### 7. Decimal Precision
- **General KPIs:** 0-1 decimal places
- **Financial:** 0 decimals for large amounts, 2 for rates
- **Percentages:** 1 decimal place
- Set in DAX measure format strings, not just visual formatting

---

## DAX Naming Conventions

### Measures
```dax
-- Format: [Metric Name] or [Metric Name Type]
[Sales Total]
[Sales YoY %]
[Sales vs Target]
```

### Calculated Columns
```dax
-- Format: Column Name (no brackets)
Sales Year
Customer Segment
```

### Variables
```dax
-- Format: _DescriptiveName (underscore prefix)
VAR _CurrentYearSales = ...
VAR _PriorYearSales = ...
```

### Standard Color & Style Variables (HTML Cards)

**Performance Level Detection:**
```dax
VAR _performanceLevel = 
    SWITCH(
        TRUE(),
        _achievementRatio >= 1.15, "outstanding",
        _achievementRatio >= 1.0, "target_met",
        _achievementRatio >= 0.9, "near_target",
        _achievementRatio >= 0.8, "below_target",
        "critical"
    )
```

**WTW Color Palette:**
```dax
-- Primary colors by performance
VAR _primaryColor = SWITCH(
    _performanceLevel,
    "outstanding", "#7C3AED",  -- WTW Purple
    "target_met", "#059669",   -- Green
    "near_target", "#0891B2",  -- Cyan
    "below_target", "#F59E0B", -- Amber
    "#DC2626"                  -- Red (critical)
)

-- Background tints (subtle)
VAR _backgroundTint = SWITCH(
    _performanceLevel,
    "outstanding", "#F3F4F6",
    "target_met", "#ECFDF5",
    "near_target", "#F0F9FF",
    "below_target", "#FFFBEB",
    "#FEF2F2"
)

-- Gradient fills for bars/cards
VAR _gradientFill = SWITCH(
    _performanceLevel,
    "outstanding", "linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%)",
    "target_met", "linear-gradient(135deg, #10B981 0%, #059669 100%)",
    "near_target", "linear-gradient(135deg, #06B6D4 0%, #0891B2 100%)",
    "below_target", "linear-gradient(135deg, #FBBF24 0%, #F59E0B 100%)",
    "linear-gradient(135deg, #F87171 0%, #DC2626 100%)"
)
```

**Text Colors (Neutral Hierarchy):**
```dax
VAR _textPrimary = "#1E293B"    -- Headings
VAR _textSecondary = "#6B7280"  -- Labels
VAR _textTertiary = "#334155"   -- Sub-headings
VAR _textBody = "#4B5563"       -- Body text
VAR _textMuted = "#9CA3AF"      -- Captions
```

**Shadow System:**
```dax
-- Outer container (premium depth)
VAR _outerShadow = "0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)"

-- Inner cards (subtle)
VAR _innerShadow = "0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)"
```

**Border System:**
```dax
VAR _borderLight = "1px solid #F3F4F6"
VAR _borderMedium = "1px solid #E5E7EB"
VAR _borderThemed = "1px solid " & _primaryColor & "20"  -- 20 = ~12% opacity
```

---

## HTML Card Components (DAX-Generated)

### Standard Container Structure

```dax
-- Container wrapper (outer box with premium shadow)
"<div style='
    width: " & _containerWidth & ";
    height: " & _containerHeight & ";
    padding: 20px;
    background: linear-gradient(145deg, #FFFFFF 0%, #F9FAFB 100%);
    border-radius: 12px;
    font-family: Segoe UI, Inter, system-ui, sans-serif;
    color: #111827;
    border: 1px solid #E5E7EB;
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
    box-sizing: border-box;
'>"
```

### Inner Card Structure

```dax
-- Individual metric card (inner subtle shadow)
"<div style='
    background: #FFFFFF;
    padding: 12px;
    border-radius: 8px;
    border: 1px solid #F3F4F6;
    box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
    text-align: center;
'>"
```

### Grid Layouts

**4-Column Metrics Grid:**
```dax
"<div style='
    display: grid;
    grid-template-columns: 1fr 1fr 1fr 1fr;
    gap: 12px;
    margin-bottom: 20px;
'>"
```

**3-Column Metrics Grid:**
```dax
"<div style='
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 12px;
    margin-bottom: 20px;
'>"
```

### Progress Bar with Benchmark

```dax
-- Background track
"<div style='
    width: 100%;
    height: 10px;
    background: #F1F5F9;
    border-radius: 5px;
    position: relative;
    overflow: hidden;
'>"

-- Filled portion (with gradient)
"<div style='
    width: " & _progressWidthCSS & ";
    height: 100%;
    background: " & _gradientFill & ";
    border-radius: 5px;
    transition: width 1.2s ease-out;
'></div>"

-- Benchmark line
"<div style='
    position: absolute;
    left: 100%;
    top: -1px;
    bottom: -1px;
    width: 2px;
    background: #374151;
    border-radius: 2px;
    box-shadow: 0 0 4px rgba(55, 65, 81, 0.4);
'></div>"
```

### Status Badge (Top-Right Corner)

```dax
"<div style='
    background: " & _backgroundTint & ";
    color: " & _primaryColor & ";
    padding: 6px 12px;
    border-radius: 8px;
    font-size: 8px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border: 1px solid " & _primaryColor & "20;
'>" & _statusIcon & " " & _statusText & "</div>"
```

### Summary Panel (Bottom Section)

```dax
"<div style='
    background: linear-gradient(135deg, " & _backgroundTint & " 0%, rgba(255,255,255,0.8) 100%);
    border: 1px solid " & _primaryColor & "25;
    border-radius: 8px;
    padding: 12px 16px;
'>"
```

### Standard Card Widths (Grid-Aligned)

Based on 1280px canvas with 12-column grid:

| Columns | Width  | Use Case                    |
|---------|--------|-----------------------------|
| 3 cols  | 268px  | Single KPI card             |
| 4 cols  | 364px  | Compact scorecard           |
| 6 cols  | 580px  | Executive summary card ✓    |
| 8 cols  | 796px  | Wide analytical card        |
| 12 cols | 1160px | Full-width dashboard banner |

**Height Recommendations:**
- KPI Cards: `320-400px`
- Scorecards: `300-350px`
- Executive Summary: `350-450px`

---

## Visual Selection Guidelines

### When to Use Each Visual Type

**KPI Cards:**
- Single high-level metrics
- Always with comparison context
- Use `display-sm` to `display-xl` fonts

**Bar/Column Charts:**
- Comparing categories (≤20 categories)
- Time series with clear patterns
- Use horizontal bars for long category names

**Line Charts:**
- Continuous time series
- Multiple metrics comparison over time
- Show trends and patterns

**Tables/Matrix:**
- Detailed data drill-down
- Multi-dimensional analysis
- Use sparingly on overview pages

**Avoid:**
- 3D charts (distort perception)
- Pie charts with >5 slices
- Dual-axis charts (can mislead)

---

## Color Usage Guidelines

### WTW Brand Colors

**Primary Purple (Brand):**
- Main: `#7C3AED`
- Light tint: `#8B5CF6`
- Background: `#F3F4F6` or `#F5F3FF`
- Gradient: `linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%)`

**Use for:** Primary CTAs, outstanding performance, brand elements

### Performance Color System

Based on achievement thresholds with semantic meaning:

| Level            | Threshold    | Primary Color | Background   | Gradient                                          | Use Case                    |
|------------------|--------------|---------------|--------------|---------------------------------------------------|-----------------------------|
| **Outstanding**  | ≥115%        | `#7C3AED`     | `#F3F4F6`    | `linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%)` | Exceptional performance     |
| **Target Met**   | 100-114%     | `#059669`     | `#ECFDF5`    | `linear-gradient(135deg, #10B981 0%, #059669 100%)` | Goal achieved               |
| **Near Target**  | 90-99%       | `#0891B2`     | `#F0F9FF`    | `linear-gradient(135deg, #06B6D4 0%, #0891B2 100%)` | Approaching goal            |
| **Below Target** | 80-89%       | `#F59E0B`     | `#FFFBEB`    | `linear-gradient(135deg, #FBBF24 0%, #F59E0B 100%)` | Needs attention             |
| **Critical**     | <80%         | `#DC2626`     | `#FEF2F2`    | `linear-gradient(135deg, #F87171 0%, #DC2626 100%)` | Urgent action required      |

### Neutral & Supporting Colors

**Text Hierarchy:**
- Primary: `#1E293B` (headings, important text)
- Secondary: `#6B7280` (labels, descriptions)
- Tertiary: `#334155` (sub-headings)
- Body: `#4B5563` (paragraph text)
- Muted: `#9CA3AF` (hints, captions)

**UI Elements:**
- Border light: `#F3F4F6`
- Border medium: `#E5E7EB`
- Border dark: `#374151`
- Background: `#FFFFFF`
- Background alt: `#F9FAFB`

### Gradient Best Practices

**Container Backgrounds:**
```css
background: linear-gradient(145deg, #FFFFFF 0%, #F9FAFB 100%);
```

**Performance Bars/Cards:**
```css
/* Use corresponding gradient from performance table */
background: linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%);
```

**Subtle Tinted Backgrounds:**
```css
/* Combine background tint + gradient overlay */
background: linear-gradient(135deg, #F3F4F6 0%, rgba(255,255,255,0.8) 100%);
border: 1px solid #7C3AED25; /* 25 = ~15% opacity */
```

### Accessibility Requirements

- **WCAG AA contrast:** 4.5:1 for normal text, 3:1 for large text
- **Test tools:** Use WebAIM Contrast Checker
- **Color alone:** Never rely solely on color to convey information
- **Status indicators:** Always include icons + text + color

### Color Application Rules

1. **KPI Cards:** Use performance color for value, neutral for context
2. **Status Badges:** Match background tint to primary color with 15-25% opacity
3. **Progress Bars:** Use gradient fill, benchmark line in `#374151`
4. **Charts:** Max 5-6 colors per chart, use WTW purple as primary
5. **Hover States:** Darken by 10% or add 10% opacity overlay

---

## Performance Best Practices

### Visual Optimization
- Limit visuals per page: ≤15 for optimal performance
- Use bookmarks for multiple view states instead of multiple pages
- Minimize use of custom visuals

### Data Model
- Use star schema architecture
- Implement proper relationships (avoid bi-directional unless necessary)
- Create date table with calendar hierarchy

### DAX Optimization
- Use variables to avoid recalculation
- Filter early in calculation context
- Use SELECTEDVALUE() instead of VALUES() for single value checks

---

## Report Navigation Pattern

### Standard Layout Structure
```
┌─────────────────────────────────────┐
│  Logo | Report Title | Date Filter  │ <- Header (54px margin)
├─────────────────────────────────────┤
│                                     │
│  [KPI Cards Section - 32px gap]     │ <- display-sm text
│                                     │
├─────────────────────────────────────┤
│                                     │
│  [Main Visual Section]              │ <- 16px padding per visual
│                                     │
│                                     │
├─────────────────────────────────────┤
│  [Detail Tables/Drill-down]         │
│                                     │
└─────────────────────────────────────┘
```

### Page Types
1. **Executive Overview:** High-level KPIs only
2. **Operational Dashboard:** Mix of KPIs and trend charts
3. **Detailed Analysis:** Tables, drill-through enabled
4. **Documentation:** Data dictionary, refresh schedule

---

## Checklist Before Publishing

- [ ] All visuals aligned to 12-column grid
- [ ] Consistent font sizes (typography scale)
- [ ] Soft shadows applied (90°, 4px distance, 8px blur)
- [ ] Visual padding set to 16px
- [ ] All visuals labeled in Selection pane
- [ ] Date range visible on canvas
- [ ] KPIs include comparison context
- [ ] No unnecessary axis titles or labels
- [ ] Decimal places appropriate for metric type
- [ ] Performance Analyzer run (no visual >3s load time)
- [ ] Tooltips customized with relevant context
- [ ] Cross-filtering behavior tested
- [ ] Mobile layout created (if applicable)

---

## Common Patterns & Templates

### KPI Card with Context
```dax
Sales Total Card = 
VAR _Current = [Sales Total]
VAR _Target = [Sales Target]
VAR _Variance = DIVIDE(_Current - _Target, _Target)
RETURN
    "Current: " & FORMAT(_Current, "$#,##0") & "
" &
    "Target: " & FORMAT(_Target, "$#,##0") & "
" &
    "Variance: " & FORMAT(_Variance, "+0.0%;-0.0%")
```

### Dynamic Title with Filter Context
```dax
Dynamic Title = 
VAR _SelectedPeriod = SELECTEDVALUE('Date'[Year Month])
VAR _DefaultTitle = "Sales Performance"
RETURN
    IF(
        ISFILTERED('Date'[Year Month]),
        _DefaultTitle & " - " & _SelectedPeriod,
        _DefaultTitle & " - All Periods"
    )
```

### Color-Coded Performance Indicator
```dax
Performance Color = 
VAR _Variance = [Sales vs Target %]
RETURN
    SWITCH(
        TRUE(),
        _Variance >= 0.15, "#7C3AED",  -- WTW Purple (outstanding)
        _Variance >= 0.10, "#059669",  -- Green (target met)
        _Variance >= 0, "#0891B2",     -- Cyan (near target)
        _Variance >= -0.10, "#F59E0B", -- Amber (below target)
        "#DC2626"                       -- Red (critical)
    )
```

### Status Badge with Icon
```dax
Status Badge = 
VAR _Achievement = [Achievement Ratio]
VAR _Icon = SWITCH(
    TRUE(),
    _Achievement >= 1.15, "⭐",
    _Achievement >= 1.0, "🎯",
    _Achievement >= 0.9, "📈",
    _Achievement >= 0.8, "⚠️",
    "🚨"
)
VAR _Text = SWITCH(
    TRUE(),
    _Achievement >= 1.15, "OUTSTANDING",
    _Achievement >= 1.0, "TARGET ACHIEVED",
    _Achievement >= 0.9, "APPROACHING TARGET",
    _Achievement >= 0.8, "BELOW EXPECTATION",
    "REQUIRES ATTENTION"
)
VAR _Color = SWITCH(
    TRUE(),
    _Achievement >= 1.15, "#7C3AED",
    _Achievement >= 1.0, "#059669",
    _Achievement >= 0.9, "#0891B2",
    _Achievement >= 0.8, "#F59E0B",
    "#DC2626"
)
RETURN _Icon & " " & _Text
```

---

## Resources & References

### Essential DAX Patterns
- Time intelligence: YTD, QTD, MTD, YoY, MoM
- Ranking: RANKX, TOPN
- Running totals: CALCULATE with FILTER
- Dynamic periods: DATESINPERIOD, DATESBETWEEN

### Power BI Service Settings
- Schedule refresh during off-peak hours
- Enable incremental refresh for large datasets (>1GB)
- Set appropriate data source credentials
- Configure RLS if multi-tenant

### Testing Checklist
- Cross-browser compatibility (Edge, Chrome)
- Mobile rendering (Power BI Mobile app)
- Performance with realistic data volumes
- Filter interactions and drill-through behavior

---

*This design system should be applied consistently across all Power BI reports to maintain professional quality and user experience.*
