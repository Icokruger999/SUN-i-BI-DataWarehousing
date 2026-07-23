# SUN-i BI & Data Warehousing — Consolidated Task Summary

**Generated:** 2026-07-23  
**Author:** ICO Kruger  
**Jira Project:** [SUNIKAN](https://servicedesk.sun.ac.za/jira/browse/SUNIKAN)

---

## Active / In Progress

### SUNIKAN-1267 — DEV ETL failure (Faculty Lookup ODS ID)
**Type:** Bug | **Status:** Mitigated, monitoring | **Est.:** ~1h

**Root cause:** OrgUnit table in DEV ODS had 2 rows vs 838 in PROD — environment drift. EnrolmentTargets repopulated.

**Process / Next steps:**
1. Verify next scheduled run completes without no-match errors
2. Document root cause on ticket (already done — ICO comment 22/Jul)
3. Add monitoring check: row-count alert on OrgUnit in DEV compared to PROD baseline
4. If stable for 3 consecutive runs, close

---

### SUNIKAN-1263 — Confirm ProgrammeYear >7 legitimacy
**Type:** Task | **Status:** In progress | **Est.:** ~2h

**Findings so far:**
- ProgrammeYear 8–19: genuine long-tenured students (enrolment gaps). Should not be flagged by CHECK constraints.
- ProgrammeYear 50: sentinel/default for non-formal/short-course programmes (_E1xx/_A10x codes + Semester=99). Not a real year value.

**Process / Next steps:**
1. Confirm with SIS/student records business owner whether _E1xx/_A10x = short-course convention
2. If confirmed, update CHECK constraint to allow (ProgrammeYear <= 20 OR ProgrammeYear = 50)
3. Document sentinel 50 + Semester 99 convention in metadata/reference doc
4. If disputed, follow up with business owner for correction or alternative handling

---

## To Do (v2026.07)

### SUNIKAN-1268 — Add 4 sunshine tables to SS_Bronze
**Type:** Enhancement | **Priority:** P4 | **Est.:** ~4h

**Request from:** Ernst Uys (ISRA), via email to Mark Diamond, 2026-07-21

**Tables to ingest:**
- `sunshine.add_transfer_credit_details`
- `sunshine.examination_deans_merit`
- `sunshine.evaluation_student_remark`
- `sunshine.grade`

**Process / Steps:**
1. Profile each source table in sunshine schema — determine grain, row count, key columns
2. Follow existing SS_Bronze pattern (copy existing ingestion task for a similar table, e.g. another sunshine table)
3. Create SSIS package changes or ADF pipeline updates per current ingestion pattern
4. Deploy to DEV, run test load, verify row counts match source
5. Deploy to QA/PROD
6. Confirm with Ernst that data looks correct
7. Check into source control (sunidatabases project)

---

### SUNIKAN-1264 — Always-NULL columns: drop or populate?
**Type:** Technical Debt | **Priority:** P4 | **Est.:** ~3h

**Columns (100% NULL on PROD):**

| Table | Column(s) |
|-------|-----------|
| `sis.S_ProgrammeIntake` | `AlignedInd`, `EDPSubInd` |
| `sis.S_Module_LEG` | `PracticalModule`, `SubsidyInd` |
| `sis.S_ProgIntakePerEnrolment_SS` | `RegisteredForExam`, `TermInd`, `ResearchPercentage` |
| `rcs.S_ResearchBudget` | `Budget` |

**Process / Steps:**
1. For each column: query source system (not IDS) to confirm whether data exists upstream but ETL isn't capturing it
2. Categorise each column:
   - **Drop** — source also NULL / column retired / no business need
   - **Populate** — source has data, ETL gap
3. For drop candidates: generate ALTER TABLE DROP COLUMN scripts, review impact
4. For populate candidates: fix ETL mapping, test in DEV
5. Document decision per column on ticket
6. Deploy DDL/ETL changes, check in to source control

---

### SUNIKAN-1257 — proc_HealthOne: remove leftover StudentID predicate
**Type:** Bug | **Priority:** P4 | **Est.:** ~1h

**Root cause:** SUNIKAN-1253 repointed Hostel subquery from `sis.S_ProgIntakePerEnrolment_HIST_SS` to `IDS.sis.S_ProgIntakePerEnrolment_LEG` but left `AND PRE.[StudentID] = b.[StudentID]` — `b` (DIM_PersonStudent_Bio) has no StudentID column.

**Process / Steps:**
1. Open `proc_HealthOne` in source control
2. Remove the `AND PRE.[StudentID] = b.[StudentID]` line from the Hostel subquery (match on `USNumber` alone is sufficient)
3. Update the flower-box changelog header documenting both: the SUNIKAN-1253 table repoint AND this predicate removal
4. Deploy to DEV, verify proc compiles and returns Hostel data
5. Deploy to PROD
6. Verify "SUNi ETL - 12 HealthOne" job runs successfully end to end
7. Check in to source control

---

## Data Quality Bugs (v2026.07)

### SUNIKAN-1262 — Age=0 on 2 rows
**Type:** Bug | **Priority:** P4 | **Est.:** ~2h

**Table:** `sis.S_ProgIntakePerEnrolment_SS`

**Process / Steps:**
1. Identify the 2 rows — extract full record (StudentID, ProgrammeCode, IntakeYear, DOB, Age)
2. Determine whether Age=0 is caused by NULL DOB, future DOB, or calculation error
3. If source data issue: log with SIS data owner for correction
4. If ETL calculation issue: fix Age derivation logic
5. Add CHECK constraint or ETL validation to prevent recurrence
6. Document root cause on ticket

---

### SUNIKAN-1261 — NQFLevel=43 on 1 row
**Type:** Bug | **Priority:** P4 | **Est.:** ~1h

**Table:** `sis.S_Module_LEG` (valid NQF range: 1-10)

**Process / Steps:**
1. Identify the single row — extract ModuleCode, NQFLevel, DataSource
2. Query source system — is 43 a real value or a corrupt/default?
3. If source corruption: log with SIS data owner
4. If ETL mapping error: fix transformation
5. Add CHECK constraint (NQFLevel BETWEEN 1 AND 10) to prevent recurrence
6. Document on ticket

---

### SUNIKAN-1260 — Negative marks in ModVariantEnrolment_LEG
**Type:** Bug | **Priority:** P4 | **Est.:** ~2h

**Columns affected:** ClassMark (min -25), FinalMark (min -90), ProgressMark (min -1) — 3 rows each

**Process / Steps:**
1. Extract full rows — identify students, modules, terms
2. Determine whether negative marks are source-system entry errors or ETL sign issues
3. If source errors: log with SIS data owner for correction
4. If ETL sign reversal: fix transformation
5. Add CHECK constraints (ClassMark >= 0, FinalMark >= 0, ProgressMark >= 0) or ETL validation
6. Document on ticket

---

### SUNIKAN-1259 — Garbage DOBs in com.S_Person / com.S_Person_Bio
**Type:** Bug | **Priority:** P4 | **Est.:** ~3h

**Scope:** 3,398 rows in `com.S_Person` + 7,919 rows in `com.S_Person_Bio` (range: 1051-07-29 to 9000-01-01)

**Process / Steps:**
1. Profile distribution of invalid DOBs — how many are pre-1900 vs future vs null-derived defaults?
2. Identify source system patterns — do these come from a specific legacy system batch?
3. Engage SIS data owner for source-side cleanup plan
4. In parallel, add ETL-level validation to reject or flag implausible DOBs (e.g. DOB < 1900 OR DOB > today)
5. Consider adding CHECK constraint with same logic in IDS to prevent future bad data loading
6. Document findings and plan on ticket
7. Any downstream Age calculations must handle NULL/fallback for these rows until corrected

---

## Recommended Execution Order

| Prio | Ticket | Effort | Rationale |
|------|--------|--------|-----------|
| 1 | **SUNIKAN-1257** | ~1h | Blocks PROD HealthOne job — quickest fix, highest impact |
| 2 | **SUNIKAN-1268** | ~4h | Clearly scoped, external stakeholder (Ernst) waiting |
| 3 | **SUNIKAN-1264** | ~3h | Housekeeping — decision-driven, no external dependency |
| 4 | **Data quality bugs** | ~8h | Lower urgency, mostly source-side fixes. Do in ticket order |
| 5 | **SUNIKAN-1263** | ~2h | Depends on business owner availability — schedule meeting first |
| 6 | **SUNIKAN-1267** | ~1h | Already mitigated — confirm stability over a few run cycles |

**Total estimated remaining effort: ~19h (~2.5 days)**

---

## Recurring Principles

- **Source before ETL:** Always verify whether bad data originates in the source system before changing ETL. If source is wrong, escalate to SIS data owner.
- **Document everything:** Each ticket gets a root-cause comment regardless of resolution path.
- **CHECK constraints as safety net:** Add DB-level constraints after cleaning data to prevent regression.
- **Environment parity:** When resolving DEV-specific drift (like 1267), add monitoring to detect recurrence early.
- **Source control discipline:** Every deployed change checked into the sunidatabases project.
