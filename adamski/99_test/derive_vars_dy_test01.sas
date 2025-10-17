/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_vars_dy() macro

### Expected result:  
- ICDY, TRTSDY, TRTEDY variables are created with TRTEDY overwritten

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TMP, winpath=C:\Temp, otherpath=/tmp)

/*Expected result dataset*/
data _adsl_expected;
  length USUBJID $10.;
  format RANDDT ICDT TRTSDT TRTEDT date9.;
  input USUBJID $ RANDDT :date9. ICDT :date9. TRTSDT :date9. TRTEDT :date9. TRTEDY ICDY TRTSDY ; 
  datalines;
	SUBJ001 01JAN2024 31DEC2023 01JAN2024 02JAN2024 2 -1 1
	SUBJ002 03JAN2024 03DEC2023 02FEB2024 . . -31 31 
  ;
run;

/*Test dataset*/
data _adsl_test;
  length USUBJID $10.;
  format RANDDT ICDT TRTSDT TRTEDT date9.;
  input USUBJID $ RANDDT :date9. ICDT :date9. TRTSDT :date9. TRTEDT :date9. TRTEDY ; /*TRTEDY to be overwritten*/
  datalines;
	SUBJ001 01JAN2024 31DEC2023 01JAN2024 02JAN2024 1
	SUBJ002 03JAN2024 03DEC2023 02FEB2024 . 2
  ;
run;

data _adsl_test;
	set _adsl_test ;
	%derive_vars_dy(
	reference_date=RANDDT,
	source_vars=ICDT TRTSDT TRTEDT)
run ;

/*Compare*/
%mp_assertdataset(
  base=_adsl_expected,					/* parameter in proc compare */
  compare=_adsl_test,				/* parameter in proc compare */
  desc=[mp_assertdataset] (%nrstr(%derive_vars_dy)) Compare expected and test results, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion=0,       		/* parameter in proc compare */
  method=absolute,    /* parameter in proc compare */
  outds=TMP.adamski_test
);