/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : derive_param_bmi.sas
  SAS Version                 : 9.4
  Purpose (short description) : BMI from weight and height, with unit checks
  Author                      : Cursor edited by P. Robertson
  Date                        : 30OCT2026
  Input Datasets or Metadata  : SAS work dataset with pertinent ADSL vars plus VS vars needed
                                to estimate the new parameter, having one record per vS test
  Modification Log            : 

  %derive_param_bmi

  This macro calls two macros: 
  1) cmp2_check_unit (which checks units required for the derived parameter)
  2) derive_param_computed.sas (which computes newly derived parameter)

  BMI estimated as WEIGHT / (HEIGHT in meters)**2
  WEIGHT must be kg. 
  HEIGHT must be cm. and is processed as one record per subject unless height_constant=N
 
  A blank unit or any other unit writes ERROR and this macro stops.
  This causes the output dataset to not be created.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%macro derive_param_bmi(
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
,         paramcd = BMI
,           param = %str(Body Mass Index (kg/m^2))
);

  %global cmp2_unit_fail;
  %local _hc;

  %if %length(&dataset)=0 or %length(&out)=0 %then %do;
      %put WARNING: derive_param_bmi requires dataset= and out=.;
      %return;
  %end;

  %let cmp2_unit_fail = 0;
  %let _hc            = %upcase(&height_constant);
  %if &_hc ne Y and 
      &_hc ne N %then %do;
           %put WARNING: derive_param_bmi height_constant= must be Y or N.;
      %return;
  %end;

  %cmp2_check_unit(
        dataset = &dataset
  ,    test_var = &test_var
  ,  result_var = &result_var
  ,    unit_var = &unit_var
  ,        test = &weight_code
  ,    expected = kg
  );
  %cmp2_check_unit(
        dataset = &dataset
  ,    test_var = &test_var
  ,  result_var = &result_var
  ,    unit_var = &unit_var
  ,        test = &height_code
  ,    expected = cm
  );

  %if &cmp2_unit_fail = 1 %then %do;
      %put WARNING: derive_param_bmi stopped because a vital-sign unit is not kg or cm.;
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
    ,        formula = %str(&weight_code / ((&height_code/100)**2))
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
    ,        formula = %str(&weight_code / ((&height_code/100)**2))
    ,        paramcd = &paramcd
    ,          param = %superq(param)
    );
  %end;

%mend derive_param_bmi;
