# ODS Database — Complete Metadata Reference

**Generated:** 2026-07-23  
**Source:** STBBIDEV03\BIDEV03 — IDS database  
**Note:** Full table/column/constraint dump for query planning

---

## Schema Overview

| Schema | Domain | Key Tables | Row Count Range |
|--------|--------|------------|-----------------|
| **acc** | Accommodation | Hostel, HostelPreference, StudAccommodationApplication | 6 – 1.3M |
| **apl** | Applications | StudentApplication, StudentApplicationProgress, SunStudentApplication | 4 – 54M |
| **com** | Common / Person | Person, Contact, Address, OrgUnit, Language, Race | 0 – 8.5M |
| **csr** | Recruitment / Schools | School, Campaign | 0 – 4.6K |
| **dbl** | Bursaries / Loans | BursaryLoan, BursaryLoanTrans | 3 – 1.4M |
| **fin** | Finance | CostCentre, Account, CCAccYearBalance | 300 – 1.9M |
| **hem** | HEMIS Reporting | 114STUD, 114CREG, StudValidation_SS, ProgrammeFactor | 0 – 5.9M |
| **hra** | HR Active | Staff, JobCodes, Remuneration | 3 – 1.2M |
| **hrh** | HR HEMIS | Staff_HEMIS, Staff_FTE_Hist | 327K – 531K |
| **mds** | MDS | EnrolmentTargets, RaceGroup, StudentType | 3 – 1.6K |
| **sco** | Short Courses | Shortcourse, ShortCourseEnrollment, FinSection | 14 – 132K |
| **sis** | Core SIS | Module, ProgramEnrolments, Programme, ModuleEnrolment | 0 – 6.4M |
| **spc** | Space | Building, BuildingRoomSpace | 82 – 34K |
| **stf** | Student Fees | StudentFees, StudentFeesMonthly | 206K – 215M |

---

## Key Table Relationships

### Person-Centric Core

```
com.Person (1.8M)
  ├── USNumber → apl.StudentApplication
  ├── USNumber → apl.StudentApplicationProgress
  ├── PersonID → sis.ProgramEnrolments
  ├── PersonID → sis.ModuleEnrolment
  ├── PersonID → dbl.BursaryLoanTrans
  ├── PersonID → hra.Staff
  ├── PersonID → com.Contact
  ├── PersonID → com.Address
  └── PersonID → sis.SocioEconomic
```

### Application Pipeline

```
apl.StudentApplication (2M)
  ├── StudentApplicationID → apl.StudentApplicationProgress
  ├── StudentApplicationID → apl.StudentApplicationProgressDenormDelta
  ├── ProgrammeCode → sis.Programme
  ├── USNumber → com.Person
  └── ApplicationYear → (dimension)
```

### Programme / Enrolment

```
sis.Programme (5.8K)
  ├── ProgrammeID → sis.ProgramEnrolments
  ├── ProgrammeID → sis.ProgrammePacket
  ├── ProgrammeID → sis.ProgrammeCredits
  ├── ProgrammeID → sis.ProgrammeFactor
  ├── ProgrammeID → dbl.BursaryLoan
  └── ProgrammeCode → apl.StudentApplication

sis.ProgramEnrolments (1.3M)
  ├── PersonID → com.Person
  ├── ProgrammeID → sis.Programme
  ├── EnrolmentStatusID → sis.EnrolmentStatus
  ├── ModeOfInstructionID → sis.ModeOfInstruction
  └── HostelID → acc.Hostel
```

### Finance

```
stf.StudentFees (11.2M)
  ├── PersonID → com.Person
  ├── ModuleID → sis.Module
  └── AcadYear → (dimension)

dbl.BursaryLoanTrans (1.2M)
  ├── PersonID → com.Person
  ├── BursaryLoanID → dbl.BursaryLoan
  └── BLAwardStatusID → dbl.BLAwardStatus
```

### HR

```
hra.Staff (1.2M)
  ├── PersonID → com.Person
  ├── OUCodeID → com.OrgUnit
  ├── PostLevelID → hra.PostLevel
  ├── EmployCategoryID → hra.EmployCategory
  └── PersonnelCategoryID → hra.PersonnelCategory
```

### Accommodation

```
acc.StudAccommodationApplication (630K)
  ├── USNumber → com.Person
  └── (references acc.Hostel via HostelPreference)

acc.HostelPreference (1.3M)
  ├── StudAccommodationApplicationID → acc.StudAccommodationApplication
  └── HostelID → acc.Hostel
```

### Short Courses

```
sco.Shortcourse (4.5K)
  ├── SCNR → sco.ShortcourseYear
  ├── ProgrammeID → sis.Programme
  └── OUCode → com.OrgUnit

sco.ShortCourseEnrollment (132K)
  ├── PersonID → com.Person
  └── SCOfferingIDODS → sco.ShortCourseOffering
```

---

## Key Lookup / Dimension Tables

| Table | Schema | Rows | Used By |
|-------|--------|------|---------|
| OrgUnit | com | 838 | Every fact table with OU/faculty |
| OUHierarchy | com | 822 | OrgUnit rollup (Faculty → Dept → SubDept) |
| Programme | sis | 5.8K | Enrolments, applications |
| Module | sis | 262K | Module enrolments |
| Hostel | acc | 147 | Accommodation, programme enrolments |
| EnrolmentStatus | sis | 5 | ProgramEnrolments |
| ModeOfInstruction | sis | 12 | ProgramEnrolments, ModuleEnrolment |
| BursaryLoan | dbl | 64K | BursaryLoanTrans |
| Person | com | 1.8M | Central person reference |
| Race | com | 7 | Demographics |
| Gender | com | 4 | Demographics |
| Language | com | 62 | Demographics |
| Nationality | com | 248 | Demographics |
| School | csr | 4.6K | Applications, school marks |

---

## Notes for Query Planning

1. **USNumber vs PersonID**: Some tables join on USNumber (int), others on PersonID (int). `com.Person` has both — always check which key the target table uses.

2. **_SS suffix tables**: These are SunStudent (online application system) sources. They overlap with main sis tables but have different grain/columns.

3. **_Delta / _PreLoad suffix**: Staging/CDC tables — same structure, different data windows.

4. **DenormDelta tables** (apl): Pre-joined application progress data — large (27M–54M rows). Use for performance but verify grain.

5. **HEMIS tables** (hem/sis 114*): Raw HEMIS submissions. Separate grain from operational tables.

6. **EnrolmentTargets** (mds): Small table (1.6K) used by the Faculty Lookup ODS ID component in SUNIKAN-1267.

7. **HealthOne** (dbo): Denormalised student view used by proc_HealthOne (SUNIKAN-1257 fix). Derived from multiple sis/com/acc tables.

