# WTW Power BI Color System

Complete color palette, thresholds, gradients, and accessibility guidelines for WTW-branded Power BI reports.

## WTW Brand Colors

### Primary Brand Color: WTW Corporate Purple

**Main Purple**: `#7C3AED`

**Variations**:
- Light Purple: `#8B5CF6`
- Dark Purple: `#6D28D9`

**Usage**:
- Primary CTAs and buttons
- Outstanding performance indicators
- Brand highlights and accents
- Hero metrics and key values

**Background Tints**:
- Subtle background: `#F5F3FF` (5% opacity)
- Neutral background: `#F3F4F6` (gray, when purple is too strong)

### Purple Gradient (WTW Signature)

```css
background: linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%);
```

**Usage**: Progress bars, performance cards, hero banners

## Performance Color System

### Color Thresholds (Standard)

| Performance Level | Achievement | Primary Color | Color Name | RGB | Background Tint |
|-------------------|-------------|---------------|------------|-----|-----------------|
| **Outstanding** | ≥115% | `#7C3AED` | WTW Purple | 124, 58, 237 | `#F3F4F6` |
| **Target Met** | 100-114% | `#059669` | Green | 5, 150, 105 | `#ECFDF5` |
| **Near Target** | 90-99% | `#0891B2` | Cyan | 8, 145, 178 | `#F0F9FF` |
| **Below Target** | 80-89% | `#F59E0B` | Amber | 245, 158, 11 | `#FFFBEB` |
| **Critical** | <80% | `#DC2626` | Red | 220, 38, 38 | `#FEF2F2` |

### DAX Implementation

```dax
VAR _achievementRatio = DIVIDE([Actual], [Target], 0)

VAR _performanceLevel =
    SWITCH(
        TRUE(),
        _achievementRatio >= 1.15, "outstanding",
        _achievementRatio >= 1.0, "target_met",
        _achievementRatio >= 0.9, "near_target",
        _achievementRatio >= 0.8, "below_target",
        "critical"
    )

VAR _primaryColor =
    SWITCH(
        _performanceLevel,
        "outstanding", "#7C3AED",
        "target_met", "#059669",
        "near_target", "#0891B2",
        "below_target", "#F59E0B",
        "#DC2626"
    )
```

### Performance Color Gradients

All performance colors have gradient variants for progress bars and fill areas:

**Outstanding (WTW Purple)**:
```css
background: linear-gradient(135deg, #8B5CF6 0%, #7C3AED 100%);
```

**Target Met (Green)**:
```css
background: linear-gradient(135deg, #10B981 0%, #059669 100%);
```

**Near Target (Cyan)**:
```css
background: linear-gradient(135deg, #06B6D4 0%, #0891B2 100%);
```

**Below Target (Amber)**:
```css
background: linear-gradient(135deg, #FBBF24 0%, #F59E0B 100%);
```

**Critical (Red)**:
```css
background: linear-gradient(135deg, #F87171 0%, #DC2626 100%);
```

## Neutral Colors (Text & UI)

### Text Color Hierarchy

Use neutral colors for text hierarchy — reserve brand/performance colors for data and accents.

| Level | Hex Color | RGB | Use Case |
|-------|-----------|-----|----------|
| **Primary Text** | `#1E293B` | 30, 41, 59 | Headings, important text, main values |
| **Secondary Text** | `#6B7280` | 107, 114, 128 | Labels, descriptions, axis text |
| **Tertiary Text** | `#334155` | 51, 65, 85 | Sub-headings, secondary values |
| **Body Text** | `#4B5563` | 75, 85, 99 | Paragraph text, detailed descriptions |
| **Muted Text** | `#9CA3AF` | 156, 163, 175 | Captions, hints, footnotes |

### UI Element Colors

| Element | Hex Color | RGB | Use Case |
|---------|-----------|-----|----------|
| **Border Light** | `#F3F4F6` | 243, 244, 246 | Subtle dividers, card borders |
| **Border Medium** | `#E5E7EB` | 229, 231, 235 | Standard borders, table lines |
| **Border Dark** | `#374151` | 55, 65, 81 | Emphasis borders, benchmark lines |
| **Background** | `#FFFFFF` | 255, 255, 255 | Card backgrounds, main surface |
| **Background Alt** | `#F9FAFB` | 249, 250, 251 | Alternate rows, secondary surfaces |
| **Background Gray** | `#F3F4F6` | 243, 244, 246 | Disabled states, placeholder areas |

## Background Patterns

### Gradient Backgrounds

**Container Background** (subtle depth):
```css
background: linear-gradient(145deg, #FFFFFF 0%, #F9FAFB 100%);
```
**Usage**: Outer card containers, main panels

**Tinted Summary Panel**:
```css
background: linear-gradient(135deg, #F3F4F6 0%, rgba(255,255,255,0.8) 100%);
```
**Usage**: Summary panels, informational sections

**Performance-Tinted Background**:
```dax
VAR _backgroundGradient = "linear-gradient(135deg, " & _backgroundTint & " 0%, rgba(255,255,255,0.8) 100%)"
```
**Usage**: Summary panels with performance-based coloring

### Themed Borders with Opacity

Add subtle themed borders by combining performance color with opacity:

```dax
VAR _themedBorder = "1px solid " & _primaryColor & "20"  -- 20 = ~12% opacity
VAR _themedBorder = "1px solid " & _primaryColor & "25"  -- 25 = ~15% opacity
```

**Opacity Suffixes**:
- `10` = ~6% opacity (very subtle)
- `20` = ~12% opacity (subtle) ✓ recommended
- `25` = ~15% opacity (moderate)
- `40` = ~25% opacity (visible)

## Data Visualization Color Palettes

### Primary Data Palette (Multi-Category)

For bar charts, line charts, and other data visualizations with multiple categories:

| Order | Hex Color | Color Name | Use Case |
|-------|-----------|------------|----------|
| 1 | `#7C3AED` | WTW Purple | Primary series, most important category |
| 2 | `#059669` | Green | Secondary series, positive indicators |
| 3 | `#0891B2` | Cyan | Tertiary series, neutral data |
| 4 | `#F59E0B` | Amber | Quaternary series, caution indicators |
| 5 | `#EC4899` | Pink | Additional series |
| 6 | `#8B5CF6` | Light Purple | Additional series |

**Usage Guidelines**:
- Limit to **5-6 colors maximum** per chart for readability
- Use WTW Purple for the most important series
- Reserve red (#DC2626) for negative/critical data only
- Maintain sufficient contrast between adjacent colors

### Sequential Palette (Single Hue Progression)

For heatmaps, choropleth maps, or graduated scales:

**Purple Sequential** (Light → Dark):
1. `#F5F3FF` (lightest)
2. `#E9D5FF`
3. `#C4B5FD`
4. `#A78BFA`
5. `#8B5CF6`
6. `#7C3AED`
7. `#6D28D9` (darkest)

**Green Sequential** (Light → Dark):
1. `#ECFDF5`
2. `#D1FAE5`
3. `#A7F3D0`
4. `#6EE7B7`
5. `#34D399`
6. `#10B981`
7. `#059669`

### Diverging Palette (Negative ← Neutral → Positive)

For variance, growth, or performance spread:

**Red ← Gray → Green**:
- Critical: `#DC2626` (red, <-15%)
- Below: `#F59E0B` (amber, -5% to -15%)
- Neutral: `#E5E7EB` (gray, -5% to +5%)
- Above: `#0891B2` (cyan, +5% to +15%)
- Excellent: `#059669` (green, >+15%)

**DAX Example**:
```dax
VAR _variance = [Actual] - [Target]
VAR _variancePct = DIVIDE(_variance, [Target], 0)
VAR _color =
    SWITCH(
        TRUE(),
        _variancePct < -0.15, "#DC2626",
        _variancePct < -0.05, "#F59E0B",
        _variancePct <= 0.05, "#E5E7EB",
        _variancePct <= 0.15, "#0891B2",
        "#059669"
    )
RETURN _color
```

## Accessibility Guidelines

### WCAG AA Contrast Requirements

**Normal Text** (body text, <18pt):
- Minimum contrast ratio: **4.5:1**

**Large Text** (≥18pt or ≥14pt bold):
- Minimum contrast ratio: **3:1**

### Color Contrast Checker

Test all color combinations using [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

### Pre-Validated Combinations

These combinations meet WCAG AA standards:

**Text on White Background**:
- ✅ `#1E293B` (Primary Text) → 14.7:1 contrast
- ✅ `#334155` (Tertiary Text) → 10.3:1 contrast
- ✅ `#4B5563` (Body Text) → 7.7:1 contrast
- ✅ `#6B7280` (Secondary Text) → 5.1:1 contrast
- ⚠️ `#9CA3AF` (Muted Text) → 3.2:1 contrast (large text only)

**White Text on Colored Backgrounds**:
- ✅ `#FFFFFF` on `#7C3AED` (WTW Purple) → 5.2:1 contrast
- ✅ `#FFFFFF` on `#059669` (Green) → 4.7:1 contrast
- ✅ `#FFFFFF` on `#0891B2` (Cyan) → 3.5:1 contrast (large text only)
- ✅ `#FFFFFF` on `#DC2626` (Red) → 5.5:1 contrast

**Colored Text on White Background**:
- ✅ `#7C3AED` (WTW Purple) on `#FFFFFF` → 5.2:1 contrast
- ✅ `#059669` (Green) on `#FFFFFF` → 4.7:1 contrast
- ⚠️ `#0891B2` (Cyan) on `#FFFFFF` → 3.5:1 contrast (large text only)
- ✅ `#DC2626` (Red) on `#FFFFFF` → 5.5:1 contrast

### Accessibility Best Practices

1. **Never rely solely on color** to convey information
   - ❌ BAD: Red/green coloring alone
   - ✅ GOOD: Red/green + "Above Target" / "Below Target" text + ↑/↓ icons

2. **Include text labels with colored indicators**
   - Status badges: Icon + Text + Color
   - Performance levels: Label + Value + Color-coded bar

3. **Use patterns in addition to colors**
   - Hatching or texture for chart series
   - Icons for status indicators

4. **Test in grayscale**
   - Ensure information is still distinguishable without color
   - Use different brightness levels and patterns

## Color Application Rules

### KPI Cards

- **Main value**: Use performance color for the primary metric
- **Labels**: Use neutral secondary text (`#6B7280`)
- **Context text**: Use neutral body text (`#4B5563`)
- **Variance indicators**: Use performance color with bold font

### Status Badges

- **Background**: Performance background tint
- **Text**: Performance primary color
- **Border**: Performance primary color with 20% opacity

### Progress Bars

- **Track (empty)**: `#F1F5F9` (light gray)
- **Fill (progress)**: Performance gradient
- **Benchmark line**: `#374151` (dark gray)

### Charts (Native Visuals)

- **Primary series**: WTW Purple (`#7C3AED`)
- **Secondary series**: Green, Cyan, Amber (avoid red unless critical)
- **Axis lines**: `#E5E7EB` (light gray)
- **Grid lines**: `#F3F4F6` (very light gray)
- **Data labels**: `#1E293B` (primary text)

### Tables

- **Header background**: `#F9FAFB` (light gray)
- **Header text**: `#1E293B` (primary text, bold)
- **Body text**: `#4B5563` (body text)
- **Alternate rows**: `#F9FAFB` (light gray) or none
- **Borders**: `#E5E7EB` (medium border)

## Hover States & Interactive Elements

### Button/Interactive Hover

**Primary Button (WTW Purple)**:
- Default: `#7C3AED`
- Hover: `#6D28D9` (10% darker)
- Active: `#5B21B6` (20% darker)

**Secondary Button (Neutral)**:
- Default: `#E5E7EB` (light gray)
- Hover: `#D1D5DB` (10% darker)
- Active: `#9CA3AF` (20% darker)

### Hover Overlay Pattern

Add a semi-transparent overlay on hover:

```css
/* Darken effect */
background: rgba(0, 0, 0, 0.05);  /* 5% black overlay */

/* Lighten effect */
background: rgba(255, 255, 255, 0.1);  /* 10% white overlay */
```

## Quick Reference: Color Variables (DAX)

Copy this block into your DAX measures for consistent coloring:

```dax
-- WTW Brand
VAR _wtwPurple = "#7C3AED"
VAR _wtwPurpleLight = "#8B5CF6"
VAR _wtwPurpleDark = "#6D28D9"

-- Performance Colors
VAR _colorOutstanding = "#7C3AED"
VAR _colorTargetMet = "#059669"
VAR _colorNearTarget = "#0891B2"
VAR _colorBelowTarget = "#F59E0B"
VAR _colorCritical = "#DC2626"

-- Text Hierarchy
VAR _textPrimary = "#1E293B"
VAR _textSecondary = "#6B7280"
VAR _textBody = "#4B5563"
VAR _textMuted = "#9CA3AF"

-- Borders & UI
VAR _borderLight = "#F3F4F6"
VAR _borderMedium = "#E5E7EB"
VAR _borderDark = "#374151"
VAR _backgroundAlt = "#F9FAFB"
```

## Checklist: Color System Compliance

Before publishing, verify:
- [ ] WTW Purple (`#7C3AED`) used for primary brand elements
- [ ] Performance colors follow standard thresholds (115%, 100%, 90%, 80%)
- [ ] Neutral text hierarchy used (avoid colored text for labels)
- [ ] All text meets WCAG AA contrast (4.5:1 for normal, 3:1 for large)
- [ ] Color never used alone to convey information (always + text/icon)
- [ ] Charts limited to 5-6 colors maximum
- [ ] Gradients used for progress bars and performance indicators
- [ ] Background tints subtle (5-15% opacity)
- [ ] Tested in grayscale for accessibility
- [ ] Hover states defined for interactive elements
