/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_locf_records() macro  
- Case with DTYPE of LOG

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data input3;
  length STUDYID $6 USUBJID $10 PARAMCD $10 PARAM $40 AVISIT $20 DTYPE $10;
  infile datalines dlm='|' truncover;
  input STUDYID $ USUBJID $ PARAMCD $ PARAM $ AVAL AVISITN AVISIT $ DTYPE $;
datalines;
TEST01|1015|DIABP|Diastolic Blood Pressure|51|0|BASELINE|
TEST01|1015|DIABP|Diastolic Blood Pressure|50|2|WEEK 2|
TEST01|1015|SYSBP|Systolic Blood Pressure|121|0|BASELINE|
TEST01|1015|SYSBP|Systolic Blood Pressure|121|2|WEEK 2|
TEST01|1015|LTDIABP|Log(Diastolic Blood Pressure)|1.71|0|BASELINE|LOG
TEST01|1015|LTDIABP|Log(Diastolic Blood Pressure)|1.69|2|WEEK 2|LOG
TEST01|1015|LTSYSBP|Log(Systolic Blood Pressure)|2.08|0|BASELINE|LOG
TEST01|1015|LTSYSBP|Log(Systolic Blood Pressure)|2.08|2|WEEK 2|LOG
TEST01|1028|DIABP|Diastolic Blood Pressure|79|0|BASELINE|
TEST01|1028|SYSBP|Systolic Blood Pressure|130|0|BASELINE|
TEST01|1028|LTDIABP|Log(Diastolic Blood Pressure)|1.89|0|BASELINE|LOG
TEST01|1028|LTSYSBP|Log(Systolic Blood Pressure)|2.11|0|BASELINE|LOG
;
run;

data expected_obsv3;
  length PARAMCD $10 PARAM $40 AVISIT $20;
  infile datalines dlm='|' truncover;
  input PARAMCD $ PARAM $ AVISITN AVISIT ;

datalines;
DIABP|Diastolic Blood Pressure|0|BASELINE
DIABP|Diastolic Blood Pressure|2|WEEK 2
LTDIABP|Log(Diastolic Blood Pressure)|0|BASELINE
LTDIABP|Log(Diastolic Blood Pressure)|2|WEEK 2
SYSBP|Systolic Blood Pressure|0|BASELINE
SYSBP|Systolic Blood Pressure|2|WEEK 2
LTSYSBP|Log(Systolic Blood Pressure)|0|BASELINE
LTSYSBP|Log(Systolic Blood Pressure)|2|WEEK 2
;
run;


/*expected output*/
data out_expected;
  length STUDYID $6 USUBJID $10 PARAMCD $10 PARAM $40 AVISIT $20 DTYPE $10;
  infile datalines dlm='|' truncover;
  input STUDYID $ USUBJID $ PARAMCD $ PARAM $ AVAL AVISITN AVISIT $ DTYPE $;
datalines;
TEST01|1015|DIABP|Diastolic Blood Pressure|51|0|BASELINE|
TEST01|1015|DIABP|Diastolic Blood Pressure|50|2|WEEK 2|
TEST01|1015|LTDIABP|Log(Diastolic Blood Pressure)|1.71|0|BASELINE|LOG
TEST01|1015|LTDIABP|Log(Diastolic Blood Pressure)|1.69|2|WEEK 2|LOG
TEST01|1015|LTSYSBP|Log(Systolic Blood Pressure)|2.08|0|BASELINE|LOG
TEST01|1015|LTSYSBP|Log(Systolic Blood Pressure)|2.08|2|WEEK 2|LOG
TEST01|1015|SYSBP|Systolic Blood Pressure|121|0|BASELINE|
TEST01|1015|SYSBP|Systolic Blood Pressure|121|2|WEEK 2|
TEST01|1028|DIABP|Diastolic Blood Pressure|79|0|BASELINE|
TEST01|1028|DIABP|Diastolic Blood Pressure|79|2|WEEK 2|LOCF
TEST01|1028|LTDIABP|Log(Diastolic Blood Pressure)|1.89|0|BASELINE|LOG
TEST01|1028|LTDIABP|Log(Diastolic Blood Pressure)|1.89|2|WEEK 2|LOCF
TEST01|1028|LTSYSBP|Log(Systolic Blood Pressure)|2.11|0|BASELINE|LOG
TEST01|1028|LTSYSBP|Log(Systolic Blood Pressure)|2.11|2|WEEK 2|LOCF
TEST01|1028|SYSBP|Systolic Blood Pressure|130|0|BASELINE|
TEST01|1028|SYSBP|Systolic Blood Pressure|130|2|WEEK 2|LOCF
;
run;

/*output by the macro*/
%derive_locf_records(
  dataset=input3,
  dataset_ref=expected_obsv3,
  by_vars=STUDYID USUBJID PARAM PARAMCD,  
  id_vars_ref=,  
  analysis_var=, 
  imputation=, 
  order=AVISITN AVISIT,
  keep_vars=,  
  outdata=out_test
);

/*Compare*/
%mp_assertdataset(
  base			= out_expected,					/* parameter in proc compare */
  compare	= out_test,					/* parameter in proc compare */
  desc		= (%nrstr(%derive_locf_records))[test03] Compare expected and test results for case with DTYPE of LOG, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion	= 0,       		/* parameter in proc compare */
  method		= absolute,    /* parameter in proc compare */
  outds		= TEMP.adamski_test
);
