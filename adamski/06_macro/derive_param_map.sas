/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : derive_param_map.sas
  SAS Version                 : 9.4
  Purpose (short description) : Mean arterial pressure, with unit checks
  Author                      : Cursor edited by P. Robertson
  Date                        : 30OCT2026
  Input Datasets or Metadata  : SAS work dataset with pertinent ADSL vars plus VS vars needed
                                to derive the new parameter, having one record per VS test
  Modification Log            : 

  %derive_param_map

  This macro calls cmp2_check_unit.sas and derive_param_computed.sas macros.

  MAP Estimation Without heart rate: (2*DIABP + SYSBP) / 3
  MAP Estimation With heart rate:    DIABP + 0.01 * exp(4.14 - 40.74/HR) * (SYSBP - DIABP)

  Rows are paired on USUBJID, VISIT, and VSTPT, so two positions stay apart.

  SYSBP and DIABP must have units of mmHg. 
  HR, when hr_code= is supplied, must be beats/min.
 
  A blank unit or any other unit writes ERROR and this macro stops.
  The output dataset is not created.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%macro derive_param_map(
       dataset =
,          out =
,     test_var = VSTESTCD
,   result_var = VSSTRESN
,     unit_var = VSSTRESU
,      usubjid = USUBJID
,        visit = VISIT
,          tpt = VSTPT
,        carry =
,   sysbp_code = SYSBP
,   diabp_code = DIABP
,      hr_code =
,      paramcd = MAP
,        param = %str(Mean Arterial Pressure (mmHg))
);

  %global cmp2_unit_fail;
  %local _formula
         _opt_mprint
         _opt_symbolgen
         _opt_mprintnest;

  %if %length(&dataset) = 0 or 
      %length(&out)     = 0 %then %do;
         %put WARNING: derive_param_map requires dataset= and out=.;
         %return;
  %end;

  %let _opt_mprint = %sysfunc(getoption(mprint));
  %let _opt_symbolgen = %sysfunc(getoption(symbolgen));
  %let _opt_mprintnest = %sysfunc(getoption(mprintnest));

  %let cmp2_unit_fail = 0;

  %cmp2_check_unit(
       dataset = &dataset
  ,   test_var = &test_var
  , result_var = &result_var
  ,   unit_var = &unit_var
  ,       test = &sysbp_code
  ,   expected = mmHg
  );

  %cmp2_check_unit(
       dataset = &dataset
  ,   test_var = &test_var
  , result_var = &result_var
  ,   unit_var = &unit_var
  ,       test = &diabp_code
  ,   expected = mmHg
  );

  %if %length(&hr_code) %then %do;
    %cmp2_check_unit(
         dataset = &dataset
    ,   test_var = &test_var
    , result_var = &result_var
    ,   unit_var = &unit_var
    ,       test = &hr_code
    ,   expected = beats/min
    );
  %end;

  %if &cmp2_unit_fail = 1 %then %do;
      %put WARNING: derive_param_map stopped because a vital-sign unit is not mmHg or beats/min.;
      options &_opt_mprint;
      options &_opt_symbolgen;
      options &_opt_mprintnest;
      %return;
  %end;

  %if %length(&hr_code) %then %do;
      %let _formula = &diabp_code + 0.01 * exp(4.14 - 40.74 / &hr_code) * (&sysbp_code - &diabp_code);
  %end;
  %else %do;
      %let _formula = (2 * &diabp_code + &sysbp_code) / 3;
  %end;

  %if %length(&hr_code) %then %do;
    %derive_param_computed(
         dataset = &dataset
    ,        out = &out
    ,   test_var = &test_var
    , result_var = &result_var
    ,    usubjid = &usubjid
    ,      visit = &visit
    ,        tpt = &tpt
    ,      carry = &carry
    ,      tests = &sysbp_code &diabp_code &hr_code
    ,    formula = %superq(_formula)
    ,    paramcd = &paramcd
    ,      param = %superq(param)
    );
  %end;
  %else %do;
    %derive_param_computed(
         dataset = &dataset
    ,        out = &out
    ,   test_var = &test_var
    , result_var = &result_var
    ,    usubjid = &usubjid
    ,      visit = &visit
    ,        tpt = &tpt
    ,      carry = &carry
    ,      tests = &sysbp_code &diabp_code
    ,    formula = %superq(_formula)
    ,    paramcd = &paramcd
    ,      param = %superq(param)
    );
  %end;

  options &_opt_mprint;
  options &_opt_symbolgen;
  options &_opt_mprintnest;

%mend derive_param_map;
