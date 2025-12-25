/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_locf_records() macro  
- Case with ADY and id_vars_ref

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data input6;
  length USUBJID $5 PARAMCD $10 AVISIT $20;
  infile datalines dlm=',' truncover;  
  input USUBJID $ PARAMCD $ AVAL AVISITN AVISIT $ ADY;
datalines;
1, DIABP, 51, 0, BASELINE, 0
1, DIABP, 50, 2, WEEK 2, 14
1, DIABP, 52, 4, WEEK 4, 28
1, DIABP, 54, 6, WEEK 6, 42
1, SYSBP, 21, 0, BASELINE, 0
1, SYSBP, 121, 2, WEEK 2, 14
2, DIABP, 79, 0, BASELINE, 0
2, DIABP, 80, 2, WEEK 2, 12
2, DIABP, ., 4, WEEK 4, 26
2, DIABP, ., 6, WEEK 6, 44
2, SYSBP, 130, 0, BASELINE, 0
;
run;

data expected_obsv6;
  length PARAMCD $10 AVISIT $20;
  infile datalines dlm=',' truncover; 
  input PARAMCD $ AVISITN AVISIT $ ADY;
datalines;
DIABP, 0, BASELINE, 0
DIABP, 2, WEEK 2, 14
DIABP, 4, WEEK 4, 28
DIABP, 6, WEEK 6, 42
SYSBP, 0, BASELINE, 0
SYSBP, 2, WEEK 2, 14
;
run;


/*expected output*/
data out_expected;
  length USUBJID $5 PARAMCD $10 AVISIT $20 DTYPE $4;
  infile datalines dlm=',' truncover;  
  input USUBJID $ PARAMCD $ AVAL AVISITN AVISIT $ ADY DTYPE $;
datalines;
1, DIABP, 51, 0, BASELINE, 0,
1, DIABP, 50, 2, WEEK 2, 14,
1, DIABP, 52, 4, WEEK 4, 28,
1, DIABP, 54, 6, WEEK 6, 42,
1, SYSBP, 21, 0, BASELINE, 0,
1, SYSBP, 121, 2, WEEK 2, 14,
2, DIABP, 79, 0, BASELINE, 0,
2, DIABP, 80, 2, WEEK 2, 12,
2, DIABP, ., 4, WEEK 4, 26,
2, DIABP, 80, 4, WEEK 4, 28,LOCF
2, DIABP, 80, 6, WEEK 6, 42,LOCF
2, DIABP, ., 6, WEEK 6, 44,
2, SYSBP, 130, 0, BASELINE, 0,
2, SYSBP, 130, 2, WEEK 2, 14,LOCF
;
run;

/*output by the macro*/
%derive_locf_records(
  dataset=input6,
  dataset_ref=expected_obsv6,
  by_vars=USUBJID PARAMCD,  
  id_vars_ref=USUBJID PARAMCD AVISITN AVISIT,  
  analysis_var=AVAL,
  imputation=, 
  order=AVISITN AVISIT ADY,
  keep_vars=,  
  outdata=out_test
);



/*Compare*/
%mp_assertdataset(
  base			= out_expected,					/* parameter in proc compare */
  compare	= out_test,					/* parameter in proc compare */
  desc		= (%nrstr(%derive_locf_records))[test06] Compare expected and test results for case with ADY and id_vars_ref, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion	= 0,       		/* parameter in proc compare */
  method		= absolute,    /* parameter in proc compare */
  outds		= TEMP.adamski_test
);
