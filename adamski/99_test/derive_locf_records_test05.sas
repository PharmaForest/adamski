/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_locf_records() macro  
- Case of imputation=update_add

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data input5;
  length STUDYID $10 USUBJID $12 PARAMCD $10 PARAM $50 AVISIT $20;
  infile datalines dlm=',' truncover;    
  input STUDYID $ USUBJID $ PARAMCD $ PARAM $ AVAL AVISITN AVISIT $;
    
datalines;
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),51,0,BASELINE
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),50,2,WEEK 2
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),52,4,WEEK 4
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),54,6,WEEK 6
TEST01,01-701-1015,SYSBP,Systolic Blood Pressure (mmHg),121,0,BASELINE
TEST01,01-701-1015,SYSBP,Systolic Blood Pressure (mmHg),121,2,WEEK 2
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),79,0,BASELINE
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),80,2,WEEK 2
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),.,4,WEEK 4
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),.,6,WEEK 6
TEST01,01-701-1028,SYSBP,Systolic Blood Pressure (mmHg),130,0,BASELINE
;
run;

data expected_obsv5;
  length PARAMCD $10 PARAM $50 AVISIT $20;
  infile datalines dlm=',' truncover;    
  input PARAMCD $ PARAM $ AVISITN AVISIT $;
    
datalines;
DIABP,Diastolic Blood Pressure (mmHg),0,BASELINE
DIABP,Diastolic Blood Pressure (mmHg),2,WEEK 2
DIABP,Diastolic Blood Pressure (mmHg),4,WEEK 4
DIABP,Diastolic Blood Pressure (mmHg),6,WEEK 6
SYSBP,Systolic Blood Pressure (mmHg),0,BASELINE
SYSBP,Systolic Blood Pressure (mmHg),2,WEEK 2
;
run;

/*expected output*/
data out_expected;
  length STUDYID $10 USUBJID $12 PARAMCD $10 PARAM $50 AVISIT $20 DTYPE $4;
  infile datalines dlm=',' truncover;    
  input STUDYID $ USUBJID $ PARAMCD $ PARAM $ AVAL AVISITN AVISIT $ DTYPE $;
    
datalines;
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),51,0,BASELINE,
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),50,2,WEEK 2,
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),52,4,WEEK 4,
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),54,6,WEEK 6,
TEST01,01-701-1015,SYSBP,Systolic Blood Pressure (mmHg),121,0,BASELINE,
TEST01,01-701-1015,SYSBP,Systolic Blood Pressure (mmHg),121,2,WEEK 2,
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),79,0,BASELINE,
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),80,2,WEEK 2,
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),80,4,WEEK 4,LOCF
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),.,4,WEEK 4,
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),80,6,WEEK 6,LOCF
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),.,6,WEEK 6,
TEST01,01-701-1028,SYSBP,Systolic Blood Pressure (mmHg),130,0,BASELINE,
TEST01,01-701-1028,SYSBP,Systolic Blood Pressure (mmHg),130,2,WEEK 2,LOCF
;
run;

/*output by the macro*/
%derive_locf_records(
  dataset=input5,
  dataset_ref=expected_obsv5,
  by_vars=STUDYID USUBJID PARAM PARAMCD,  
  id_vars_ref=,  
  analysis_var=, 
  imputation=update_add, 
  order=AVISITN AVISIT,
  keep_vars=,  
  outdata=out_test
);


/*Compare*/
%mp_assertdataset(
  base			= out_expected,					/* parameter in proc compare */
  compare	= out_test,					/* parameter in proc compare */
  desc		= (%nrstr(%derive_locf_records))[test05] Compare expected and test results for case of imputation=update_add, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion	= 0,       		/* parameter in proc compare */
  method		= absolute,    /* parameter in proc compare */
  outds		= TEMP.adamski_test
);
