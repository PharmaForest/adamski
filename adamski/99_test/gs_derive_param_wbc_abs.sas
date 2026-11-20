/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : gs_derive_param_wbc_abs.sas
  SAS Version                 : 9.4
  Purpose (short description) : Golden-subject checks for derive_param_wbc_abs
  Author                      : Cursor
  Date                        : 31OCT2026
  Input Datasets or Metadata  : Small LB rows built in this program
  Modification Log            :

  These checks use WORK data only. They do not call the ODA libname setup.
  PFDIR defaults to HOME/Adamski/SAS.
  Macros are in macro. These checks are in TestThat.

  Fraction 0.25 times WBC 7.2 is 1.8.
  Percent 40 times WBC 6.5 / 100 is 2.6.
  A key that already has the absolute test keeps that value.

  These cases are expected to print ERROR from the macro and still PASS:
  GS-WBC-04 WBC unit 10^3/uL
  GS-WBC-05 percent differential without a percent unit
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%if %symexist(PFDIR) = 0 %then %do;
    %let PFDIR = %sysfunc(strip(%sysget(HOME)))/Adamski/SAS;
%end;

%include "&PFDIR/macro/derive_param_computed.sas";
%include "&PFDIR/macro/cmp2_check_unit.sas";
%include "&PFDIR/macro/derive_param_wbc_abs.sas";
%include "&PFDIR/TestThat/gs_pf_harness.sas";

%let gs_pass = 0;
%let gs_fail = 0;
%let gs_policy = 0;
%let gs_suite = derive_param_wbc_abs;


data work.wbc_frac;
     length usubjid $4
            visit   $8
            lbtestcd $8
            lbstresu $12;
     usubjid='S1'; visit='WEEK2'; lbtestcd='WBC';   lbstresn=7.2;  lbstresu='10^9/L'; output;
     usubjid='S1'; visit='WEEK2'; lbtestcd='LYMLE'; lbstresn=0.25; lbstresu='1';      output;
     usubjid='S2'; visit='WEEK2'; lbtestcd='WBC';   lbstresn=6;    lbstresu='10^9/l'; output;
     usubjid='S2'; visit='WEEK2'; lbtestcd='LYMLE'; lbstresn=0.30; lbstresu='1';      output;
     usubjid='S2'; visit='WEEK2'; lbtestcd='LYMPH'; lbstresn=9;    lbstresu='10^9/L'; output;
run;

%gs_drop(work.wbc_frac_out);

%derive_param_wbc_abs(
       dataset = work.wbc_frac
,          out = work.wbc_frac_out
,    diff_code = LYMLE
,    diff_type = fraction
,      paramcd = LYMPH
,        param = %str(Lymphocytes Abs)
);

%gs_aval(GS-WBC-01, work.wbc_frac_out, %str(usubjid='S1' and paramcd='LYMPH'), 1.8);
%gs_n(GS-WBC-02, work.wbc_frac_out, %str(usubjid='S2' and paramcd='LYMPH' and missing(lbtestcd)), 0);
%gs_n(GS-WBC-03, work.wbc_frac_out, %str(usubjid='S2' and lbtestcd='LYMPH' and lbstresn=9), 1);


data work.wbc_bad;
     length usubjid $4
            visit   $8
            lbtestcd $8
            lbstresu $12;
     input usubjid $ visit $ lbtestcd $ lbstresn lbstresu $;
datalines;
S1 WEEK2 WBC 7.2 10^3/uL
S1 WEEK2 LYMLE 0.25 1
;
run;

%gs_drop(work.wbc_bad_out);

%derive_param_wbc_abs(
       dataset = work.wbc_bad
,          out = work.wbc_bad_out
,    diff_code = LYMLE
,      paramcd = LYMPH
,        param = %str(Lymphocytes Abs)
);

%gs_no_ds(GS-WBC-04, work.wbc_bad_out);
%gs_unit(GS-WBC-04U, 1);


data work.wbc_pct;
     length usubjid $4
            visit   $8
            lbtestcd $8
            lbstresu $12;
     usubjid='S1'; visit='WEEK2'; lbtestcd='WBC';  lbstresn=6.5; lbstresu='10^9/L'; output;
     usubjid='S1'; visit='WEEK2'; lbtestcd='LYMP'; lbstresn=40;  lbstresu=byte(37);      output;
     usubjid='S3'; visit='WEEK2'; lbtestcd='WBC';  lbstresn=6.5; lbstresu='10^9/L'; output;
     usubjid='S3'; visit='WEEK2'; lbtestcd='LYMP'; lbstresn=40;  lbstresu='1';      output;
run;

%derive_param_wbc_abs(
       dataset = work.wbc_pct
,          out = work.wbc_pct_out
,    diff_code = LYMP
,    diff_type = percent
,      paramcd = LYMPH
,        param = %str(Lymphocytes Abs)
);

%gs_no_ds(GS-WBC-05, work.wbc_pct_out);


data work.wbc_pct_ok;
     length usubjid $4
            visit   $8
            lbtestcd $8
            lbstresu $12;
     usubjid='S1'; visit='WEEK2'; lbtestcd='WBC';  lbstresn=6.5; lbstresu='10^9/L'; output;
     usubjid='S1'; visit='WEEK2'; lbtestcd='LYMP'; lbstresn=40;  lbstresu=byte(37);      output;
run;

%derive_param_wbc_abs(
       dataset = work.wbc_pct_ok
,          out = work.wbc_pct_ok_out
,    diff_code = LYMP
,    diff_type = percent
,      paramcd = LYMPH
,        param = %str(Lymphocytes Abs)
);

%gs_aval(GS-WBC-06, work.wbc_pct_ok_out, %str(paramcd='LYMPH'), 2.6);

%gs_done(derive_param_wbc_abs);
