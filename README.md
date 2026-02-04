# WTW Data Solutions System

The ultimate hub for all data engineering, transformation, and visualization solutions at Willis Towers Watson. This workspace centralizes Alteryx workflows, Microsoft Fabric development, and Power BI reporting standards.

## Project Structure

This workspace is organized to track the full lifecycle of data from source to insight:

### 🛠️ Transformers
- **Purpose**: Home for all data movement and transformation logic.
- **What to put here**: Alteryx workflows (.yxmd), SQL transformation scripts, PySpark/Fabric Notebooks.

### 📊 Semantic-Models
- **Purpose**: Storage for Power BI model definitions and logic.
- **What to put here**: DAX measure libraries, `.tmdl` or `.bim` model exports, and calculation group definitions.

### 🎨 Design-System
- **Purpose**: The UI/UX engine for high-end reporting.
- **What to put here**: HTML/CSS for custom card visuals, SVG icon sets, branding assets, and shared reporting templates.

### 📖 Mapping-Documentation
- **Purpose**: The "Brain" of the data logic.
- **What to put here**: Name mapping Excel/CSV files, data dictionaries, lineage documentation, and business requirements.

### 🤖 .agent
- **Purpose**: AI Agent configuration.
- **Contents**: Specialized skills (like `wtw-powerbi`) that guide the agent in following company standards.

---

## Agent Guidelines
Refer to `AGENT_GUIDELINES.md` (renamed from CLAUDE.md) for coding preferences, naming conventions, and specific instructions for the AI assistant.

## Design Philosophy
This workspace follows the **WTW Power BI Design System**, which emphasizes:
- **Typography**: Focused hierarchy for readability.
- **Color**: Performance-based semantic coloring using the WTW Purple system.
- **Visuals**: Clean, grid-aligned custom HTML cards and premium visual depth.

---
Internal use only - Willis Towers Watson
