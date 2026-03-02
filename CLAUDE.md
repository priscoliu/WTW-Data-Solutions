# WTW Data Solutions — Claude Project Context

## What This Project Is
Central hub for data engineering and visualization at Willis Towers Watson.
Full guidelines: `AGENT_GUIDELINES.md`. Workflows: `.agent/workflows/`.

> **Skills note**: `.agent/skills/` contains skill definitions for other agents (e.g. Agentspace/Antigravity).
> Claude Code skills are installed globally at `C:\Users\LiuPr\.claude\skills\` — no duplication needed.

## Stack
Python · PySpark · SQL · DAX · Power Query (M) · HTML5/CSS · Microsoft Fabric · Power BI

## File Registry (current state)

| Layer | Folder | Files |
|---|---|---|
| Bronze | `Transformers/Alteryx-Migration/Fabric-Bronze/Billing/` | `src_Saiba_crb.m`, `src_arias_crb.m`, `src_eclipse_crb.m`, `src_eclipse_london.m`, `src_eglobal_income_report.m`, `src_eglobal_premium_report.m`, `src_gswin_crb.m` |
| Bronze | `Transformers/Alteryx-Migration/Fabric-Bronze/CRM/` | `01_bronze_pipeline_crm.json` (Fabric Data Pipeline) |
| Silver | `Transformers/Alteryx-Migration/Fabric-Silver/Chloe/` | `02_silver_clean_eglobal.m`, `02_silver_notebook_eclipse.ipynb`, `02_silver_notebook_arias.ipynb`, `02_silver_notebook_gswin.ipynb`, `02_silver_notebook_saiba.ipynb`, `ref_Chloe_eglobal_product_mapping.m` |
| Silver | `Transformers/Alteryx-Migration/Fabric-Silver/Baseline/` | *(not started — ignore)* |
| Silver | `Transformers/Alteryx-Migration/Fabric-Silver/CRM/` | *(not started — ignore)* |
| Source | `Transformers/Alteryx-Migration/Source-Analysis/` | Original Alteryx `.yxmd` |

## Naming Conventions (strict)

- **ETL artifacts**: `[SS]_[layer]_[action]_[subject]` — e.g. `02_silver_notebook_eclipse.ipynb`
- **Bronze tables**: `src_[source]_[content]` — e.g. `src_saiba_policies`
- **Silver tables**: `clean_[content]` or `master_[entity]`
- **Gold tables**: `fact_[process]`, `dim_[context]`
- **Reference tables**: `ref_Chloe_[subject]_[type]`
- **Final Fabric columns**: `PascalCase` (no spaces or special chars)
- **Variables/Functions**: `camelCase` · **DAX vars**: `_camelCase`

## Critical Coding Rules

- Fabric notebooks: **always `.ipynb`**, never `.py`
- Spark SQL: `spark.sql("SELECT * FROM LakehouseName.Table_Name")`
- Join keys: always `F.trim(F.upper())` on **both** sides — no exceptions
- Special-char columns: backtick-quote them — `` F.col("`COL NAME`") ``
- Safe numeric M conversion: `each try Number.From(_) otherwise 0, type nullable number`
- Write pattern: `df.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable("table_name")`
- CRM SQL: **no CTEs**. Fabric SQL: CTEs OK.

## MCP Servers

- `powerbi-modeling` — Read/Write Tables, Measures, DAX, TMDL (exe at `C:\MCP\analysis-services.powerbi-modeling-mcp-0.1.8@win32-x64\...`)

## Task Routing

| Trigger | Load |
|---|---|
| alteryx, migration, pyspark, notebook | `.agent/workflows/alteryx-migration.md` |
| DAX, measure, KPI, HTML card, Power BI | `.agent/skills/wtw-powerbi/SKILL.md` |
| xlsx, excel, csv | `.agent/skills/xlsx/SKILL.md` |
| pptx, slides, deck | `.agent/skills/pptx/SKILL.md` |
| docx, report, proposal | `.agent/skills/docx/SKILL.md` |
