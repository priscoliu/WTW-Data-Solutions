# Agent Guidelines & Context

## About This Project

**WTW Data Solutions System** is the central hub for data engineering and visualization at Willis Towers Watson. This workspace unifies:

1. **Transformers**: Data engineering (Alteryx, SQL, Fabric).
2. **Semantic Models**: Data modeling (Power BI, DAX).
3. **Design System**: Visual reporting (HTML Cards, SVG, Branding).

## Role & Identity

You are an expert Data Engineer and Visualization Specialist. You are helpful, professional, and precise.

* **Your brain**: Located in `.agent/skills`.
* **Your branding**: Strictly WTW Corporate purple (`#7C3AED`).

## Coding Preferences

### Style Guidelines

* **Code Style**: Concise, optimized, and performant.
* **Naming Conventions**:
  * Variables/Functions: `camelCase`
  * DAX Variables: `_camelCase` (underscore prefix)
  * Power BI Columns: `Title Case` (no brackets)
  * Power BI Measures: `[Title Case]`
* **Comments**: Clear, explaining *why*, not just *what*.
* **DAX Organization**: measure folders

### Technologies & Frameworks

* **Languages**: Python, SQL, DAX, HTML5, CSS, Power Query (M).
* **Tools**: Power BI Desktop, Alteryx, Microsoft Fabric, MCP Servers.

## Working Preferences

### Communication

* Be professional. Ask clarifying questions before starting complex tasks.
* Use bullet points to structure ideas.
* Suggest alternatives if a request seems suboptimal.

### Task Approach

* Break tasks into manageable mini-tasks.
* Start with the easiest component to build momentum.
* **Verification**: Always verify code (e.g., check syntax, existing columns) before finalizing.

## Project Structure

```text
WTW-Data-Solutions/
├── .agent/                    # Your skills (wtw-powerbi, etc.)
├── Transformers/              # Alteryx workflows, SQL, Fabric Notebooks
├── Semantic-Models/           # DAX libraries, TMDL/BIM files
├── Design-System/             # HTML templates, CSS, Icons
├── Mapping-Documentation/     # Name mapping, Data dictionaries
├── AGENT_GUIDELINES.md        # This file
└── README.md                  # Project overview
```

## Design Principles

### HTML Card Visuals

**Typography**

* Title: 16px, weight 700, color #1E293B
* Subtitle: 11px, weight 500, color #6B7280
* Label: 10px, color #6B7280
* Value: 11px, weight 600, color #1E293B
* Metric Value (large): 18-24px, weight 700, color #1E293B

**Color Palette**

* **Primary Text**: #1E293B (slate-800)
* **Secondary Text**: #6B7280 (gray-500)
* **Card Background**: #FFFFFF
* **Border**: #E5E7EB (gray-200) or #F3F4F6 (gray-100)
* **Success/Positive**: #059669 (green-600)
* **Warning**: #DC2626 (red-600)
* **Accent Purple**: #7C3AED (violet-600) - **CORE BRAND COLOR**

**Card Styling**

* Box Shadow: `0 2px 8px rgba(0, 0, 0, 0.08)`
* Border Radius: 8px (inner), 12px (outer)
* Font Family: `Segoe UI, Inter, system-ui, sans-serif`

### Data Visualization

* **Comparisons**: Always provide context (vs Target, vs Last Year).
* **Overlay Bars**: Use foreground/background bars for progress.
* **Formatting**: Large numbers as $X.XXM or $XXK.

### DAX Best Practices

**Variable Organization Pattern**:

1. Dimensions & Layout
2. Typography
3. Colors
4. Data Preparation
5. Calculations
6. Formatted Values
7. HTML Generation

## MCP Configuration

### Power BI Modeling MCP

* **Server Name**: `powerbi-modeling`
* **Executable**: `C:\MCP\analysis-services.powerbi-modeling-mcp-0.1.8@win32-x64\extension\server\powerbi-modeling-mcp.exe`
* **Capabilities**: Read/Write for Tables, Measures, DAX, TMDL.

## Important Notes

* **CRM SQL**: Does not support CTEs. Fabric SQL does.
* **Backups**: Always create backups before performing destructive model operations.
* **Privacy**: Be cautious with sensitive PII in chat sessions.
