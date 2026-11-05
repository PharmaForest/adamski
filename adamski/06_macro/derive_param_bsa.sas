/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : derive_param_bsa.sas
  SAS Version                 : 9.4
  Purpose (short description) : Mosteller BSA from height and weight
  Author                      : Cursor edited by Paul Robertson
  Date                        : 30OCT2026
  Input Datasets or Metadata  : SAS work dataset with pertinent ADSL vars plus VS vars neeed to
                                estimate the new parameter, having separate VS records per test
  Modification Log            : 

  %derive_param_bsa

  This macro calls cmp2_check_unit.sas and derive_param_computed.sas.

  Mosteller BSA estimated as sqrt(HEIGHT in cm * WEIGHT in kg / 3600)

  WEIGHT must have kg units.
  HEIGHT must have cm units. Height is one record per subject unless height_constant=N.

  A blank unit or any other unit writes ERROR and this macro stops.
  The output dataset is not created.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%macro derive_param_bsa(
          dataset =
,             out =
,        test_var = VSTESTCD
,      result_var = VSSTRESN
,        unit_var = VSSTRESU
,         usubjid = USUBJID
,           visit = VISIT
,             tpt = VSTPT
,           carry =
,     weight_code = WEIGHT
,     height_code = HEIGHT
, height_constant = Y
,         paramcd = BSA
,           param = %str(Body Surface Area (m^2))
);

  %global cmp2_unit_fail;
  %local _hc;

  %if %length(&dataset)=0 or
      %length(&out)    =0 %then %do;
      %put WARNING: derive_param_bsa requires dataset= and out=.;
      %return;
  %end;

  %let cmp2_unit_fail = 0;
  %let _hc = %upcase(&height_constant);
  %if &_hc ne Y and 
      &_hc ne N %then %do;
           %put WARNING: derive_param_bsa height_constant= must be Y or N.;
           %return;
  %end;

  %cmp2_check_unit(
       dataset = &dataset
  ,   test_var = &test_var
  , result_var = &result_var
  ,   unit_var = &unit_var
  ,       test = &weight_code
  ,   expected = kg
  );

  %cmp2_check_unit(
       dataset = &dataset
  ,   test_var = &test_var
  , result_var = &result_var
  ,   unit_var = &unit_var
  ,       test = &height_code
  ,   expected = cm
  );

  %if &cmp2_unit_fail = 1 %then %do;
      %put WARNING: derive_param_bsa stopped because a vital-sign unit is not kg or cm.;
      %return;
  %end;

  %if &_hc = Y %then %do;
    %derive_param_computed(
             dataset = &dataset
    ,            out = &out
    ,       test_var = &test_var
    ,     result_var = &result_var
    ,        usubjid = &usubjid
    ,          visit = &visit
    ,            tpt = &tpt
    ,          carry = &carry
    ,          tests = &weight_code
    , constant_tests = &height_code
    ,        formula = %str(sqrt(&height_code * &weight_code / 3600))
    ,        paramcd = &paramcd
    ,          param = %superq(param)
    );
  %end;
  %else %do;
    %derive_param_computed(
             dataset = &dataset
    ,            out = &out
    ,       test_var = &test_var
    ,     result_var = &result_var
    ,        usubjid = &usubjid
    ,          visit = &visit
    ,            tpt = &tpt
    ,          carry = &carry
    ,          tests = &weight_code &height_code
    ,        formula = %str(sqrt(&height_code * &weight_code / 3600))
    ,        paramcd = &paramcd
    ,          param = %superq(param)
    );
  %end;

%mend derive_param_bsa;
