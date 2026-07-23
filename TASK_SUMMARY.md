# SUN-i BI & Data Warehousing — Consolidated Task Summary

**Generated:** 2026-07-23  
**Author:** ICO Kruger  
**Jira Project:** [SUNIKAN](https://servicedesk.sun.ac.za/jira/browse/SUNIKAN)

---

## Active / In Progress

| Ticket | Type | Summary | Status | Est. Effort |
|--------|------|---------|--------|-------------|
| [SUNIKAN-1267](https://servicedesk.sun.ac.za/jira/browse/SUNIKAN-1267) | Bug | DEV ETL failure — OrgUnit drift (2 rows vs 838). Monitoring fix. | Mitigated, monitoring | ~1h |
| [SUNIKAN-1263](https://servicedesk.sun.ac.za/jira/browse/SUNIKAN-1263) | Task | Confirm ProgrammeYear >7 legitimacy; document sentinel (50) with business owner | In progress | ~2h |

## To Do (v2026.07)

| Ticket | Type | Summary | Est. Effort |
|--------|------|---------|-------------|
| [SUNIKAN-1268](https://servicedesk.sun.ac.za/jira/browse/SUNIKAN-1268) | Enhancement | Add 4 sunshine tables (`add_transfer_credit_details`, `examination_deans_merit`, `evaluation_student_remark`, `grade`) to SS_Bronze ingestion | ~4h |
| [SUNIKAN-1264](https://servicedesk.sun.ac.za/jira/browse/SUNIKAN-1264) | Tech Debt | Drop or populate 8 always-NULL columns across `sis.S_ProgrammeIntake`, `sis.S_Module_LEG`, `sis.S_ProgIntakePerEnrolment_SS`, `rcs.S_ResearchBudget` | ~3h |
| [SUNIKAN-1257](https://servicedesk.sun.ac.za/jira/browse/SUNIKAN-1257) | Bug | Remove leftover `StudentID` predicate in `proc_HealthOne` (regression from SUNIKAN-1253). Unblocks PROD HealthOne job. | ~1h |

## Data Quality Bugs (v2026.07)

| Ticket | Type | Summary | Est. Effort |
|--------|------|---------|-------------|
| [SUNIKAN-1262](https://servicedesk.sun.ac.za/jira/browse/SUNIKAN-1262) | Bug | Age=0 on 2 rows in `sis.S_ProgIntakePerEnrolment_SS` | ~2h |
| [SUNIKAN-1261](https://servicedesk.sun.ac.za/jira/browse/SUNIKAN-1261) | Bug | NQFLevel=43 (1 row) in `sis.S_Module_LEG` (valid range 1-10) | ~1h |
| [SUNIKAN-1260](https://servicedesk.sun.ac.za/jira/browse/SUNIKAN-1260) | Bug | Negative marks (-90 to -1) in `sis.S_ModVariantEnrolment_LEG` | ~2h |
| [SUNIKAN-1259](https://servicedesk.sun.ac.za/jira/browse/SUNIKAN-1259) | Bug | ~11,317 garbage DOBs (1051–9000) in `com.S_Person` / `com.S_Person_Bio` | ~3h |

## Recommended Execution Order

1. **SUNIKAN-1257** (~1h) — quick fix, unblocks PROD HealthOne job
2. **SUNIKAN-1268** (~4h) — Ernst's request, clearly scoped
3. **SUNIKAN-1264** (~3h) — housekeeping, decision-driven
4. Data quality bugs (~8h total) — lower urgency, source-side fixes
5. **SUNIKAN-1263** (~2h) — depends on business owner availability
6. **SUNIKAN-1267** (~1h) — already mitigated, just confirm stable

**Total estimated remaining effort: ~19h (~2.5 days)**
