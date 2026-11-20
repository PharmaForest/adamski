/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : derive_param_rr.sas
  SAS Version                 : 9.4
  Purpose (short description) : RR interval from heart rate, with a unit check
  Author                      : Cursor edited by P. Robertson
  Date                        : 30OCT2026
  Input Datasets or Metadata  : A work dataset with pertinent ADSL vars plus EG vars 
                                needed to derive the new parameter, having one record per EG var
  Modification Log            : 

  %derive_param_rr

  This macro calls cmp2_check_unit.sas and derive_param_computed.sas macros 

  RR interval in milliseconds = 60000 / heart rate.
  Heart rate must have units = beats/min.
  A blank unit or any other unit triggers an ERROR message and halting execution and output generation. 

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%macro derive_param_rr(
     dataset =
,        out =
,   test_var = EGTESTCD
, result_var = EGSTRESN
,   unit_var = EGSTRESU
,    usubjid = USUBJID
,      visit = VISIT
,        tpt = EGTPT
,      carry =
,    hr_code = HR
,    paramcd = RR
,      param = %str(RR Interval (ms))
);

  %global cmp2_unit_fail;

  %if %length(&dataset) = 0 or 
      %length(&out)     = 0 %then %do;
      %put WARNING: derive_param_rr requires dataset= and out=.;
      %return;
  %end;

  %let cmp2_unit_fail = 0;

  %cmp2_check_unit(
       dataset = &dataset
  ,   test_var = &test_var
  , result_var = &result_var
  ,   unit_var = &unit_var
  ,       test = &hr_code
  ,   expected = beats/min
  );

  %if &cmp2_unit_fail = 1 %then %do;
      %put WARNING: derive_param_rr stopped because heart rate is not beats/min.;
      %return;
  %end;

  %derive_param_computed(
       dataset = &dataset
  ,        out = &out
  ,   test_var = &test_var
  , result_var = &result_var
  ,    usubjid = &usubjid
  ,      visit = &visit
  ,        tpt = &tpt
  ,      carry = &carry
  ,      tests = &hr_code
  ,    formula = %str(60000 / &hr_code)
  ,    paramcd = &paramcd
  ,      param = %superq(param)
  );

%mend derive_param_rr;
