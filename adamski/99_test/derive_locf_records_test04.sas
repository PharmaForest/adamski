/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_locf_records() macro  
- Case of imputation=update

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data input4;
  length STUDYID $10 USUBJID $12 PARAMCD $10 PARAM $50 AVISIT $20;
  infile datalines dlm=',' truncover;
  input STUDYID $ USUBJID $ PARAMCD $ PARAM $ AVAL AVISITN AVISIT $;
datalines;
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),51,0,BASELINE 
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),50,2,WEEK 2 
TEST01,01-701-1015,SYSBP,Systolic Blood Pressure (mmHg),121,0,BASELINE 
TEST01,01-701-1015,SYSBP,Systolic Blood Pressure (mmHg),121,2,WEEK 2 
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),79,0,BASELINE 
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),.,2,WEEK 2 
TEST01,01-701-1028,SYSBP,Systolic Blood Pressure (mmHg),130,0,BASELINE 
TEST01,01-701-1028,SYSBP,Systolic Blood Pressure (mmHg),.,2,WEEK 2 
;
run;

data expected_obsv4;
  length AVISIT $20;
  infile datalines dlm=',' truncover;
  input AVISITN AVISIT $;
datalines;
0, BASELINE
2, WEEK 2
;
run;

/*expected output*/
data out_expected;
  length STUDYID $10 USUBJID $12 PARAMCD $10 PARAM $50 AVISIT $20 DTYPE $4;
  infile datalines dlm=',' truncover;
  input STUDYID $ USUBJID $ PARAMCD $ PARAM $ AVAL AVISITN AVISIT $ DTYPE;
datalines;
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),51,0,BASELINE, 
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),50,2,WEEK 2, 
TEST01,01-701-1015,SYSBP,Systolic Blood Pressure (mmHg),121,0,BASELINE, 
TEST01,01-701-1015,SYSBP,Systolic Blood Pressure (mmHg),121,2,WEEK 2, 
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),79,0,BASELINE, 
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),79,2,WEEK 2,LOCF
TEST01,01-701-1028,SYSBP,Systolic Blood Pressure (mmHg),130,0,BASELINE, 
TEST01,01-701-1028,SYSBP,Systolic Blood Pressure (mmHg),130,2,WEEK 2,LOCF
;
run;

/*output by the macro*/
%derive_locf_records(
  dataset=input4,
  dataset_ref=expected_obsv4,
  by_vars=STUDYID USUBJID PARAM PARAMCD,  
  id_vars_ref=,  
  analysis_var=, 
  imputation=update, 
  order=AVISITN AVISIT,
  keep_vars=,  
  outdata=out_test
);

/*Compare*/
%mp_assertdataset(
  base			= out_expected,					/* parameter in proc compare */
  compare	= out_test,					/* parameter in proc compare */
  desc		= (%nrstr(%derive_locf_records))[test04] Compare expected and test results for case of imputation=update, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion	= 0,       		/* parameter in proc compare */
  method		= absolute,    /* parameter in proc compare */
  outds		= TEMP.adamski_test
);
