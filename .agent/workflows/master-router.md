---
description: Master routing workflow - automatically determines which skills and workflows to apply based on the task
---

# Master Task Router

Use this workflow at the start of any new task to ensure the right skills and workflows are applied.

## Step 1: Identify Task Type

Read the user's request and classify it into one or more categories:

| Task Type | Trigger Keywords | Workflow / Skill to Load |
|---|---|---|
| **Alteryx → Fabric Migration** | alteryx, migration, pyspark, notebook, eclipse, eglobal, fabric silver | Read `.agent/workflows/alteryx-migration.md` |
| **Power BI Measures / DAX** | DAX, measure, KPI, scorecard, HTML card, Power BI | Read `.agent/skills/wtw-powerbi/SKILL.md` |
| **Excel / Spreadsheet** | xlsx, spreadsheet, excel, csv | Read `.agent/skills/xlsx/SKILL.md` |
| **PowerPoint** | pptx, presentation, slides, deck | Read `.agent/skills/pptx/SKILL.md` |
| **Word Document** | docx, document, report, proposal | Read `.agent/skills/docx/SKILL.md` |
| **PDF** | pdf, form, extract | Read `.agent/skills/pdf/SKILL.md` |
| **Web App / Frontend** | website, dashboard, landing page, UI, frontend | Read `.agent/skills/frontend-design/SKILL.md` |
| **Internal Comms** | status report, update, newsletter, FAQ | Read `.agent/skills/internal-comms/SKILL.md` |

## Step 2: Load Relevant Context

// turbo-all

1. Read the identified workflow/skill file(s) using `view_file`
2. Check Knowledge Items (KIs) for relevant past work
3. Check recent conversation summaries for continuity

## Step 3: Apply Core Rules (Always)

Regardless of task type, always follow these rules:

### Code Authority

- **When the user provides exact code, apply it EXACTLY** — replace, don't merge
- **Never reinterpret** user-provided code blocks
- **Ask before assuming** column names, table names, join keys, or filter logic
- **Always create `.ipynb` (Jupyter notebook) files** for Fabric notebooks — never `.py` files

### Communication

- Build incrementally — show progress, check in at decision points
- When unsure, present **options** instead of guessing
- Be direct and concise — no unnecessary jargon

### Quality

- Use robust patterns (TRIM/UPPER on joins, backticks for special column names)
- Handle errors gracefully (try/except for missing tables)
- Validate outputs match expectations before moving on
