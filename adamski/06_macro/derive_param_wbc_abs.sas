/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : derive_param_wbc_abs.sas
  SAS Version                 : 9.4
  Purpose (short description) : Absolute differential from WBC, with unit checks
  Author                      : Cursor edited by P. Robertson
  Date                        : 30OCT2026
  Input Datasets or Metadata  : SAS Work dataset with pertinent ADSL vars plus LB vars needed to
                                estimate the new parameter, having one record per LB test
  Modification Log            :

  %derive_param_wbc_abs

  This macro calls cmp2_check_unit.sas and derive_param_computed.sas macros.

  fraction: absolute = differential * WBC
  percent:  absolute = differential * WBC / 100

  WBC values must be in wbc_unit, by default 10^9/L.
  A percent differential must use the percent unit.
  A fraction differential is not checked for its own unit.

  A key that already has the absolute test is left unchanged.

  A blank unit or any other unit writes a warning and this macro stops.
  The output dataset is not created.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%macro derive_param_wbc_abs(
       dataset =
,          out =
,     test_var = LBTESTCD
,   result_var = LBSTRESN
,     unit_var = LBSTRESU
,      usubjid = USUBJID
,        visit = VISIT
,          tpt =
,        carry =
,     wbc_code = WBC
,    diff_code =
,    diff_type = fraction
,     wbc_unit = 10^9/L
,      paramcd =
,        param =
);

  %global cmp2_unit_fail;

  options nosyntaxcheck obs=max;
  %local _type
         keys
         _formula
         _opt_mprint
         _opt_symbolgen
         _opt_mprintnest;

  %if %length(&dataset)   = 0 or 
      %length(&out)       = 0 or
      %length(&diff_code) = 0 or 
      %length(&paramcd)   = 0 %then %do;
         %put WARNING: derive_param_wbc_abs requires dataset=, out=, diff_code=, and paramcd=.;
         %return;
  %end;

  %let _type = %upcase(&diff_type);
  %if &_type ne FRACTION and 
      &_type ne PERCENT %then %do;
         %put WARNING: derive_param_wbc_abs diff_type= must be fraction or percent.;
         %return;
  %end;

  %let _opt_mprint = %sysfunc(getoption(mprint));
  %let _opt_symbolgen = %sysfunc(getoption(symbolgen));
  %let _opt_mprintnest = %sysfunc(getoption(mprintnest));

  %let cmp2_unit_fail = 0;
  %let keys = &usubjid &visit &tpt;

  %cmp2_check_unit(
       dataset = &dataset
  ,   test_var = &test_var
  , result_var = &result_var
  ,   unit_var = &unit_var
  ,       test = &wbc_code
  ,   expected = &wbc_unit
  );

  %if &_type = PERCENT %then %do;
      %cmp2_check_unit(
         dataset = &dataset
    ,   test_var = &test_var
    , result_var = &result_var
    ,   unit_var = &unit_var
    ,       test = &diff_code
    ,   expected = PCT
    );
  %end;

  %if &cmp2_unit_fail = 1 %then %do;
      %put WARNING: derive_param_wbc_abs stopped because a lab unit is not the expected unit.;
      options &_opt_mprint;
      options &_opt_symbolgen;
      options &_opt_mprintnest;
      %return;
  %end;

  %put NOTE: derive_param_wbc_abs reads existing keys with a data step.;

  data work._wbc_have;
       set &dataset;
       where upcase(strip(&test_var)) = "%upcase(&paramcd)";
       keep &keys;
  run;

  proc sort data=work._wbc_have nodupkey;
       by &keys;
  run;

  %if &_type = PERCENT %then %do;
      %let _formula = &diff_code * &wbc_code * 0.01;
  %end;
  %else %do;
      %let _formula = &diff_code * &wbc_code;
  %end;

  %derive_param_computed(
       dataset = &dataset
  ,        out = work._wbc_calc
  ,   test_var = &test_var
  , result_var = &result_var
  ,    usubjid = &usubjid
  ,      visit = &visit
  ,        tpt = &tpt
  ,      carry = &carry
  ,      tests = &wbc_code &diff_code
  ,    formula = %superq(_formula)
  ,    paramcd = &paramcd
  ,      param = %superq(param)
  );

  /* A missing calc set must not be read. That read is a SAS error and
     puts the rest of the program into syntax-check mode. */
  %if %sysfunc(exist(work._wbc_calc)) = 0 %then %do;
      %put WARNING: derive_param_wbc_abs stopped because the calculated rows were not created.;
      options &_opt_mprint;
      options &_opt_symbolgen;
      options &_opt_mprintnest;
      %return;
  %end;

  data work._wbc_add;
       set work._wbc_calc;
       where missing(&test_var)
             and upcase(strip(paramcd)) = "%upcase(&paramcd)";
  run;

  proc sort data=work._wbc_add;
       by &keys;
  run;
  proc sort data=work._wbc_have;
       by &keys;
  run;

  data work._wbc_add;
       merge work._wbc_add (in=in_new)
             work._wbc_have (in=in_have);
       by &keys;
       if in_new and not in_have;
  run;

  data &out;
       set &dataset
           work._wbc_add;
  run;

  proc datasets lib=work nolist;
       delete _wbc_have
              _wbc_calc
              _wbc_add;
  quit;

  options &_opt_mprint;
  options &_opt_symbolgen;
  options &_opt_mprintnest;

%mend derive_param_wbc_abs;
