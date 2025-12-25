/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_locf_records() macro  
- Case with keep_vars

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data input9;
  length USUBJID $5 PARAMCD $10 PARAMN 8 AVISIT $20 DATEC $10 DAY $10;
  infile datalines dlm=',' truncover;  
  input USUBJID $ PARAMCD $ PARAMN AVAL AVISITN AVISIT $ DATEC $ DAY $;
  
datalines;
1,DIABP,2,85,0,BASELINE,February,day a
1,DIABP,2,50,4,VISIT 4,April,day c
1,DIABP,2,20,6,VISIT 6,May,day d
1,DIABP,2,35,8,VISIT 8,June,day e
1,DIABP,2,.,10,VISIT 10,July,day f
1,DIABP,2,20,12,VISIT 12,August,day g
1,DIABP,2,.,14,VISIT 14,September,day h
;
run;

data expected_obsv9;
  length PARAMCD $10 AVISIT $20;
  infile datalines dlm=',' truncover;  
  input PARAMN PARAMCD $ AVISITN AVISIT $;
  
datalines;
2,DIABP,0,BASELINE
2,DIABP,2,VISIT 2
2,DIABP,4,VISIT 4
2,DIABP,6,VISIT 6
2,DIABP,8,VISIT 8
2,DIABP,10,VISIT 10
2,DIABP,12,VISIT 12
2,DIABP,14,VISIT 14
;
run;

/*expected output*/
data out_expected;
  length USUBJID $5 PARAMCD $10 PARAMN 8 AVISIT $20 DATEC $10 DAY $10 DTYPE $4;
  infile datalines dlm=',' truncover;  
  input USUBJID $ PARAMCD $ PARAMN AVAL AVISITN AVISIT $ DATEC $ DAY $ DTYPE $;
  
datalines;
1,DIABP,2,85,0,BASELINE,February,day a,
1,DIABP,2,85,2,VISIT 2,February,day a,LOCF
1,DIABP,2,50,4,VISIT 4,April,day c,
1,DIABP,2,20,6,VISIT 6,May,day d,
1,DIABP,2,35,8,VISIT 8,June,day e,
1,DIABP,2,35,10,VISIT 10,July,day f,LOCF
1,DIABP,2,.,10,VISIT 10,July,day f,
1,DIABP,2,20,12,VISIT 12,August,day g,
1,DIABP,2,20,14,VISIT 14,September,day h,LOCF
1,DIABP,2,.,14,VISIT 14,September,day h,
;
run;

/*output by the macro*/
%derive_locf_records(
  dataset=input9,
  dataset_ref=expected_obsv9,
  by_vars=USUBJID PARAMCD,  
  id_vars_ref=,  
  analysis_var=aval, 
  imputation=update_add,
  order=AVISITN AVISIT,
  keep_vars=PARAMN DATEC DAY,
  outdata=out_test
);

/*Compare*/
%mp_assertdataset(
  base			= out_expected,					/* parameter in proc compare */
  compare	= out_test,					/* parameter in proc compare */
  desc		= (%nrstr(%derive_locf_records))[test09] Compare expected and test results for case with keep_vars, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion	= 0,       		/* parameter in proc compare */
  method		= absolute,    /* parameter in proc compare */
  outds		= TEMP.adamski_test
);
