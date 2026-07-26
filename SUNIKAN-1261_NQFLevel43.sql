/*
====================================================================================================================================
    NAME:       ICO Kruger
    DATE:       2026-07-26
    TICKET:     SUNIKAN-1261
    CHANGE:     Investigation script — NQFLevel=43 on 1 row in sis.S_Module_LEG
                Valid NQF range is 1-10. Need to identify the row, check source, and fix.
====================================================================================================================================
*/

-- STEP 1: Identify the offending row
SELECT  ModuleID
       ,ModuleCode
       ,ModuleName
       ,NQFLevel
       ,Credits
FROM    [IDS].[sis].[S_Module_LEG]
WHERE   NQFLevel = 43
;

-- STEP 2: Compare with current sis.Module — does source have 43 too?
SELECT  LEG.ModuleID
       ,LEG.ModuleCode
       ,LEG.NQFLevel   AS LEG_NQFLevel
       ,MOD.NQFLevel   AS MOD_NQFLevel
       ,LEG.Credits     AS LEG_Credits
       ,MOD.Credits     AS MOD_Credits
FROM    [IDS].[sis].[S_Module_LEG]    LEG
LEFT JOIN [IDS].[sis].[Module]        MOD ON MOD.ModuleCode = LEG.ModuleCode
WHERE   LEG.NQFLevel = 43
;

-- STEP 3: Check distribution of NQFLevel values — is 43 an outlier?
SELECT  NQFLevel
       ,COUNT(*) AS RowCount
FROM    [IDS].[sis].[S_Module_LEG]
GROUP BY NQFLevel
ORDER BY NQFLevel
;

-- STEP 4: Check if NQFLevel=43 exists in other module tables
SELECT 'S_Module_LEG' AS SourceTable, NQFLevel, COUNT(*) AS Cnt
FROM [IDS].[sis].[S_Module_LEG] WHERE NQFLevel = 43
GROUP BY NQFLevel
UNION ALL
SELECT 'Module' AS SourceTable, NQFLevel, COUNT(*) AS Cnt
FROM [IDS].[sis].[Module] WHERE NQFLevel = 43
GROUP BY NQFLevel
UNION ALL
SELECT 'Module_ENR' AS SourceTable, NQFLevel, COUNT(*) AS Cnt
FROM [IDS].[sis].[ModuleEnrolment] WHERE NQFLevel = 43
GROUP BY NQFLevel
;

-- STEP 5: After fix — add CHECK constraint to prevent recurrence
-- Uncomment below after data is corrected:
-- ALTER TABLE [IDS].[sis].[S_Module_LEG]
-- ADD CONSTRAINT CK_S_Module_LEG_NQFLevel CHECK (NQFLevel BETWEEN 1 AND 10);
