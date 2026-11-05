/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : derive_param_qtc.sas
  SAS Version                 : 9.4
  Purpose (short description) : Corrected QT by Bazett, Fridericia, or Sagie
  Author                      : Cursor edited by P. Robertson
  Date                        : 30OCT2026
  Input Datasets or Metadata  : A work SAS dataset with pertinent ADSL vars plus vars from EG needed 
                                to derive the new parameter, having one record per component variable. 
  Modification Log            : 

  %derive_param_qtc

  This macro calls cmp2_check_unit.sas and derive_param_computed.sas. 

  Corrected QT (QTc) methods that can be estimated with this macro: 
  Bazett:     QT / sqrt(RR/1000)
  Fridericia: QT / (RR/1000)**(1/3)
  Sagie:      1000 * (QT/1000 + 0.154 * (1 - RR/1000))

  EG.QT and EG.RR input variables must each have "ms" or "msec" units. Either spelling is accepted
  and case-sensitivity is not requied.
  
  A blank unit or any other unit triggers issuing an ERROR message and stopping execution and
  not creating an output dataset. 

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%macro derive_param_qtc(
      dataset =
,         out =
,    test_var = EGTESTCD
,  result_var = EGSTRESN
,    unit_var = EGSTRESU
,     usubjid = USUBJID
,       visit = VISIT
,         tpt = EGTPT
,       carry =
,      method =
,     qt_code = QT
,     rr_code = RR
,     paramcd =
,       param =
);

  %global cmp2_unit_fail;
  %local _method 
         _paramcd 
         _param 
         _formula;

  %if %length(&dataset) = 0 or 
      %length(&out)     = 0 or 
      %length(&method)  = 0 %then %do;
      %put WARNING: derive_param_qtc requires dataset=, out=, and method=.;
      %return;
  %end;

  %let _method = %upcase(&method);

  %if &_method = BAZETT %then %do;
      %let _formula = %str(&qt_code / sqrt(&rr_code / 1000));
      %if %length(&paramcd) = 0 %then %let _paramcd = QTCBR;
      %if %length(&param)   = 0 %then %let _param   = QTcB - Bazett Correction Formula Rederived (ms);
  %end;
  %else %if &_method = FRIDERICIA %then %do;
      %let _formula = %str(&qt_code / ((&rr_code / 1000)**(1/3)));
      %if %length(&paramcd) = 0 %then %let _paramcd = QTCFR;
      %if %length(&param)   = 0 %then %let _param = QTcF - Fridericia Correction Formula Rederived (ms);
  %end;
  %else %if &_method = SAGIE %then %do;
      %let _formula = %str(1000 * (&qt_code / 1000 + 0.154 * (1 - &rr_code / 1000)));
      %if %length(&paramcd) = 0 %then %let _paramcd = QTLCR;
      %if %length(&param)   = 0 %then %let _param = QTlc - Sagie Correction Formula Rederived (ms);
  %end;
  %else %do;
      %put WARNING: derive_param_qtc method= must be Bazett, Fridericia, or Sagie.;
      %return;
  %end;

  %if %length(&paramcd) %then %let _paramcd = &paramcd;
  %if %length(&param)   %then %let _param   = &param;

  %let cmp2_unit_fail = 0;

  %cmp2_check_unit(
       dataset = &dataset
  ,   test_var = &test_var
  , result_var = &result_var
  ,   unit_var = &unit_var
  ,       test = &qt_code
  ,   expected = msec ms
  );

  %cmp2_check_unit(
       dataset = &dataset
  ,   test_var = &test_var
  , result_var = &result_var
  ,   unit_var = &unit_var
  ,       test = &rr_code
  ,   expected = msec ms
  );

  %if &cmp2_unit_fail = 1 %then %do;
      %put WARNING: derive_param_qtc stopped because QT or RR is not ms or msec.;
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
  ,      tests = &qt_code &rr_code
  ,    formula = &_formula
  ,    paramcd = &_paramcd
  ,      param = %superq(_param)
  );

%mend derive_param_qtc;
