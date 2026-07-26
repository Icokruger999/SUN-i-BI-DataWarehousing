/*
====================================================================================================================================
    NAME:       ICO Kruger
    DATE:       2026-07-26
    TICKET:     SUNIKAN-1257
    CHANGE:     Removed leftover AND PRE.[StudentID] = b.[StudentID] predicate from Hostel subquery.
                DIM_PersonStudent_Bio has no StudentID column — only USNumber. Match on USNumber alone is sufficient.
                Also documented SUNIKAN-1253 table repoint in changelog header below.
====================================================================================================================================
*/
USE [ODS]
GO
/****** Object:  StoredProcedure [rpt].[proc_HealthOne]    Script Date: 2026/07/26 10:43:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROC [rpt].[proc_HealthOne]

/***********************************************************************************************************************************

	SYNOPSIS:    Replaces [rpt].[VW_HealthOne], for consumption by the HEALTHOne system

	=======================================================================================================================
	WHEN        WHO                     WHAT
	=======================================================================================================================
	2021/04/08	IP Williams(iOCO)		Created
	2024/02/18	IP Williams(ND)			Adhoc - Updated to include IDS sourced data
	2024/06/07	IP Williams(ND)			Adhoc - Add TRY_CAST(b.[USNumber] AS INT) to exclude missing invalid [USNumber]
	2026/06/08	IP Williams(ND)			Adhoc - Extended IDS/DWH UNION branch to resolve 8 previously NULL fields
											(Campus, Hostel, HistoricalYear, EmailAddress, CellNr, PostalAddress,
											HomeAddress, Faculty) via additional joins to DWH, IDS and STAGING
	2026/07/26	ICO Kruger				SUNIKAN-1253 - Repointed Hostel subquery from S_ProgIntakePerEnrolment_HIST_SS
										to IDS.sis.S_ProgIntakePerEnrolment_LEG
	2026/07/26	ICO Kruger				SUNIKAN-1257 - Removed leftover AND PRE.[StudentID] = b.[StudentID] predicate
										from Hostel subquery (DIM_PersonStudent_Bio has no StudentID column)

	=======================================================================================================================

***********************************************************************************************************************************/
AS

BEGIN
	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #ProgramEnrolments;
	DROP TABLE IF EXISTS #Person;
	DROP TABLE IF EXISTS #ProgramFaculty;
	DROP TABLE IF EXISTS #Address;

	SELECT	 [PersonID]
			,[ProgrammeID]
			,[CampusID]
			,[HostelID]
			,[AcadYear]
			,AcadYearInt	=	CAST(CONVERT(CHAR(8), DATEFROMPARTS([AcadYear], 12, 31), 112) AS INT)
			,HistoricalYear	=	ROW_NUMBER() OVER (PARTITION BY [PersonID], [ProgrammeID] ORDER BY [AcadYear])

	INTO	#ProgramEnrolments
	FROM	[sis].[ProgramEnrolments] WITH (NOLOCK)
	WHERE	[AcadYear]	>	2010
	;

	SELECT	 [PersonID]
			,[GenderID]
			,[LanguageID]
			,[RaceID]
			,[ContactID]
			,[USNumber]
			,[LastName]
			,[FirstName]
			,[IDNumber]
			,DateOfBirth	=	[DOB]
			,[EmailAddress]
			,[WorkPhoneNr]
			,[CellNr]
			,HomePhone		=	[AfterHoursPhoneNr]

	INTO	#Person	
	FROM	[com].[Person] WITH (NOLOCK)
	;

	SELECT	 [ProgrammeID]
			,[FacultyID]

	INTO	#ProgramFaculty
	FROM	(
			SELECT   Rang = ROW_NUMBER() OVER (PARTITION BY [ProgrammeID] ORDER BY [AcadYear] DESC)
					,[ProgrammeID]
					,[FacultyID]

			FROM	[sis].[ProgramFaculty] WITH (NOLOCK)
			)	pf
	WHERE pf.[Rang] = 1
	;

	SELECT	 [ContactID]
			,[AdrTypeCode]
			,[FromDate]
			,[CalcEndDate]
			,FromDateInt	=	CAST(CONVERT(CHAR(8), [FromDate], 112) AS INT)
			,CalcEndDateInt	=	CAST(CONVERT(CHAR(8), [CalcEndDate], 112) AS INT)
			,[AdrLine1]
			,[AdrLine2]
			,[AdrLine3]
			,[AdrLine4]

	INTO	#Address		
	FROM	[com].[Address] WITH (NOLOCK)
	WHERE	[AdrTypeCode]	IN	('P','S')
	;

	CREATE NONCLUSTERED INDEX ncx_Address
	ON	#Address ([ContactID],[AdrTypeCode],[FromDateInt],[CalcEndDateInt])
	INCLUDE ([AdrLine1],[AdrLine2],[AdrLine3],[AdrLine4])
	;

	WITH CTE_Base
	AS	(
		SELECT	 P.[USNumber]
				,P.[LastName]
				,P.[FirstName]
				,Gender			=	G.[GenderENG]
				,P.[IDNumber]
				,P.[DateOfBirth]
				,ProgrammeName	=	PROG.[ProgramNameEng]
				,Campus			=	CAMP.[CampusENG]
				,[Language]		=	LANG.[LanguageENG]
				,Ethnicity		=	RACE.[RaceENG]
				,Hostel			=	HOST.[HostelEng]
				,AcademicYear	=	PE.[AcadYear]
				,PE.[HistoricalYear]
				,P.[EmailAddress]
				,P.[WorkPhoneNr]
				,P.[CellNr]
				,P.[HomePhone]
				,PostalAddress	=	CASE WHEN AA.[AdrLine1] IS NULL OR AA.[AdrLine1] = '' THEN '' ELSE AA.[AdrLine1] END + 
									CASE WHEN AA.[AdrLine2] IS NULL OR AA.[AdrLine2] = '' THEN '' ELSE ', ' + AA.[AdrLine2] END + 
									CASE WHEN AA.[AdrLine3] IS NULL OR AA.[AdrLine3] = '' THEN '' ELSE ', ' + AA.[AdrLine3] END + 
									CASE WHEN AA.[AdrLine4] IS NULL OR AA.[AdrLine4] = '' THEN '' ELSE ', ' + AA.[AdrLine4] END 

				,HomeAddress	=	CASE WHEN AA2.[AdrLine1] IS NULL OR AA2.[AdrLine1] = '' THEN '' ELSE AA2.[AdrLine1] END + 
									CASE WHEN AA2.[AdrLine2] IS NULL OR AA2.[AdrLine2] = '' THEN '' ELSE ', ' + AA2.[AdrLine2] END + 
									CASE WHEN AA2.[AdrLine3] IS NULL OR AA2.[AdrLine3] = '' THEN '' ELSE ', ' + AA2.[AdrLine3] END + 
									CASE WHEN AA2.[AdrLine4] IS NULL OR AA2.[AdrLine4] = '' THEN '' ELSE ', ' + AA2.[AdrLine4] END 
				,Faculty		=	ORG.OUNameEng

		FROM	#ProgramEnrolments			PE
		LEFT 
		JOIN	#Person						P		ON	P.[PersonID]		=	PE.[PersonID]
		LEFT
		JOIN	[com].[Gender]				G		ON	G.[GenderID]		=	P.[GenderID]
		LEFT 
		JOIN	[sis].[Programme]			PROG	ON	PROG.[ProgrammeID]	=	PE.[ProgrammeID]
		LEFT 
		JOIN	[com].[Campus]				CAMP	ON	CAMP.[CampusID]		=	PE.[CampusID]
		LEFT 
		JOIN	[com].[Languages]			LANG	ON	LANG.[LanguageID]	=	P.[LanguageID]
		LEFT 
		JOIN	[com].[Race]				RACE	ON	RACE.[RaceID]		=	P.[RaceID]
		LEFT 
		JOIN	[acc].[Hostel]				HOST	ON	HOST.[HostelID]		=	PE.[HostelID]
		LEFT 
		JOIN	#Address					AA		ON	AA.[ContactID]		=	P.[ContactID]
													AND AA.[AdrTypeCode]	=	'P'
													AND PE.AcadYearInt BETWEEN AA.[FromDateInt] AND AA.[CalcEndDateInt]
		LEFT 
		JOIN	#Address					AA2		ON	AA2.[ContactID]		=	P.[ContactID]
													AND AA2.[AdrTypeCode]	=	'S'
													AND PE.AcadYearInt BETWEEN AA2.[FromDateInt] AND AA2.[CalcEndDateInt]
		LEFT 
		JOIN	[sis].[ProgramFaculty]		PRF		ON PRF.[ProgrammeID]	=	PROG.[ProgrammeID]
													AND PRF.[AcadYear]		=	PE.[AcadYear]
		LEFT 
		JOIN	#ProgramFaculty				PF		ON  PROG.ProgrammeID	=	PF.ProgrammeID
		LEFT 
		JOIN	[com].[OrgUnit]				ORG		ON  ORG.[OUCodeID]		=	ISNULL(PRF.[FacultyID],PF.[FacultyID])
		)
	SELECT	 [USNumber]
			,[LastName]
			,[FirstName]
			,[Gender]
			,[IDNumber]
			,[DateOfBirth]		
			,[ProgrammeName]		
			,[Campus]				
			,[Language]			
			,[Ethnicity]			
			,[Hostel]				
			,[AcademicYear]		
			,[HistoricalYear]	
			,[EmailAddress]		
			,[WorkPhoneNr]		
			,[CellNr]			
			,[HomePhone]		
			,[PostalAddress]	
			,[HomeAddress]		
			,[Faculty]			

	FROM	CTE_Base

	WHERE	(1=1)
		AND [USNumber] IS NOT NULL

	UNION 

	SELECT	 [USNumber]			=	TRY_CAST(b.[USNumber] AS INT)
			,b.[LastName]
			,b.[FirstName]
			,Gender				=	b.[GenderENG]
			,b.[IDNumber]
			,[DateOfBirth]		=	b.[DOB]
			,ProgrammeName		=	c.[ProgrammeNameEng]
			,Campus				=	f.[CampusName]
			,[Language]			=	d.[LanguageENG]
			,Ethnicity			=	d.[RaceENG]
			,Hostel				=	(
									SELECT	
									TOP (1)	REF.[DescriptionEng]
									FROM	[IDS].[sis].[S_ProgIntakePerEnrolment_LEG]	PRE
									JOIN	[IDS].[com].[Reference]						REF	ON	PRE.[HostelRefID] = REF.[ReferenceID]
									WHERE	(1=1)
										AND PRE.[USNumber] = b.[USNumber]
									)
			,AcademicYear		=	a.[AcademicTerm]
			,[HistoricalYear]	=	ROW_NUMBER() OVER (PARTITION BY b.[USNumber], c.[ProgrammeCode] ORDER BY a.[AcademicTerm])
			,[EmailAddress]		=	e.[EmailAddress]
			,[WorkPhoneNr]		=	NULL
			,[CellNr]			=	e.[MobileNumber]
			,[HomePhone]		=	NULL
			,PostalAddress		=	e.[PostAddress]
			,HomeAddress		=	e.[HomeAddress]
			,Faculty			=	c.[FacultyEng]

	FROM	[DWH].[sis].[FCT_ProgIntakePerEnrolment]	a
	JOIN	[DWH].[sis].[DIM_PersonStudent_Bio]			b	ON	a.[PersonStudent_BioKey] = b.[PersonStudentKey]
	JOIN	[DWH].[sis].[DIM_Programme_SS]				c	ON	a.[ProgrammeKey] = c.[ProgrammeKey]
	JOIN	[DWH].[sis].[DIM_PersonStudentLanguage]		d	ON	a.[PersonStudentLanguageKey] = d.[PersonStudentKey]
	JOIN	[DWH].[sis].[DIM_PersonStudentAddress]		e	ON	a.[PersonStudentAddressKey] = e.[PersonStudentAddressKey]
	--JOIN	[DWH].[sis].[DIM_ProgIntakePerEnrolment]	e	ON	a.[ProgIntakePerEnrolmentKey] = e.[ProgIntakePerEnrolmentKey]
	--JOIN	[IDS].[sis].[S_ProgIntakePerEnrolment_LEG]		
	LEFT
	JOIN	(
			SELECT 
			DISTINCT [Programcode]
					,[CampusName]

			FROM	[STAGING].[ssd].[ST_ProgrammeIntake]
			)											f	ON	f.[Programcode] = c.[ProgrammeCode]

	WHERE	NOT EXISTS (
						SELECT [USNumber]
						FROM	CTE_Base
						WHERE	ISNULL([USNumber],0) = TRY_CAST(b.[USNumber] AS INT)
						)
	;
END
;
