/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : gs_derive_param_bmi.sas
  SAS Version                 : 9.4
  Purpose (short description) : Golden-subject checks for derive_param_bmi
  Author                      : Cursor
  Date                        : 31OCT2026
  Input Datasets or Metadata  : Small VS rows built in this program
  Modification Log            :

  These checks use WORK data only. They do not call the ODA libname setup.
  PFDIR defaults to HOME/Adamski/SAS.
  Macros are in macro. These checks are in TestThat.

  These cases are expected to print ERROR from the macro and still PASS:
  GS-BMI-06 weight unit lb
  GS-BMI-08 blank height unit
  GS-BMI-09 two WEIGHT rows at one key
  GS-BMI-10 height_constant is not Y or N

  The result line is NOTE: [GOLDEN SUMMARY] or ERROR: [GOLDEN SUMMARY].
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%if %symexist(PFDIR) = 0 %then %do;
    %let PFDIR = %sysfunc(strip(%sysget(HOME)))/Adamski/SAS;
%end;

%include "&PFDIR/macro/derive_param_computed.sas";
%include "&PFDIR/macro/cmp2_check_unit.sas";
%include "&PFDIR/macro/derive_param_bmi.sas";
%include "&PFDIR/TestThat/gs_pf_harness.sas";

%let gs_pass = 0;
%let gs_fail = 0;
%let gs_policy = 0;
%let gs_suite = derive_param_bmi;


data work.bmi_const;
     length usubjid $4
            visit   $8
            vstpt   $8
            vstestcd $8
            vsstresu $8
            sex     $1;
     input usubjid $
           visit $
           vstpt $
           vstestcd $
           vsstresn
           vsstresu $
           sex $;
datalines;
S1 WEEK2 T1 WEIGHT 80 kg F
S1 WEEK4 T1 WEIGHT 80 kg F
S1 SCREEN T1 HEIGHT 200 cm M
;
run;

%derive_param_bmi(
          dataset = work.bmi_const
,             out = work.bmi_const_out
,           carry = SEX
);

%gs_aval(GS-BMI-01, work.bmi_const_out, %str(paramcd='BMI' and visit='WEEK2'), 20);
%gs_aval(GS-BMI-02, work.bmi_const_out, %str(paramcd='BMI' and visit='WEEK4'), 20);
%gs_char(GS-BMI-03, work.bmi_const_out, %str(paramcd='BMI' and visit='WEEK2'), sex, F);


data work.bmi_case;
     length usubjid $4
            visit   $8
            vstpt   $8
            vstestcd $8
            vsstresu $8;
     input usubjid $ visit $ vstpt $ vstestcd $ vsstresn vsstresu $;
datalines;
S1 WEEK2 T1 WEIGHT 80 KG
S1 WEEK2 T1 HEIGHT 200 CM
;
run;

%derive_param_bmi(
          dataset = work.bmi_case
,             out = work.bmi_case_out
);

%gs_aval(GS-BMI-04, work.bmi_case_out, %str(paramcd='BMI'), 20);
%gs_unit(GS-BMI-04U, 0);


data work.bmi_visit;
     length usubjid $4
            visit   $8
            vstpt   $8
            vstestcd $8
            vsstresu $8;
     input usubjid $ visit $ vstpt $ vstestcd $ vsstresn vsstresu $;
datalines;
S1 WEEK2 T1 WEIGHT 80 kg
S1 WEEK2 T1 HEIGHT 200 cm
S1 WEEK4 T1 WEIGHT 80 kg
;
run;

%derive_param_bmi(
          dataset = work.bmi_visit
,             out = work.bmi_visit_out
, height_constant = N
);

%gs_aval(GS-BMI-05, work.bmi_visit_out, %str(paramcd='BMI' and visit='WEEK2'), 20);
%gs_n(GS-BMI-05N, work.bmi_visit_out, %str(paramcd='BMI'), 1);


data work.bmi_miss;
     length usubjid $4
            visit   $8
            vstpt   $8
            vstestcd $8
            vsstresu $8;
     usubjid='S1'; visit='WEEK2'; vstpt='T1'; vstestcd='WEIGHT'; vsstresn=.;  vsstresu='kg'; output;
     usubjid='S1'; visit='WEEK2'; vstpt='T1'; vstestcd='HEIGHT'; vsstresn=200; vsstresu='cm'; output;
run;

%derive_param_bmi(
          dataset = work.bmi_miss
,             out = work.bmi_miss_out
);

%gs_n(GS-BMI-05M, work.bmi_miss_out, %str(paramcd='BMI'), 0);


data work.bmi_lb;
     length usubjid $4
            visit   $8
            vstpt   $8
            vstestcd $8
            vsstresu $8;
     input usubjid $ visit $ vstpt $ vstestcd $ vsstresn vsstresu $;
datalines;
S1 WEEK2 T1 WEIGHT 80 lb
S1 WEEK2 T1 HEIGHT 200 cm
;
run;

%gs_drop(work.bmi_lb_out);

%derive_param_bmi(
          dataset = work.bmi_lb
,             out = work.bmi_lb_out
);

%gs_no_ds(GS-BMI-06, work.bmi_lb_out);
%gs_unit(GS-BMI-07, 1);


data work.bmi_blank;
     length usubjid $4
            visit   $8
            vstpt   $8
            vstestcd $8
            vsstresu $8;
     usubjid='S1'; visit='WEEK2'; vstpt='T1'; vstestcd='WEIGHT'; vsstresn=80;  vsstresu='kg'; output;
     usubjid='S1'; visit='WEEK2'; vstpt='T1'; vstestcd='HEIGHT'; vsstresn=200; vsstresu=' ';  output;
run;

%gs_drop(work.bmi_blank_out);

%derive_param_bmi(
          dataset = work.bmi_blank
,             out = work.bmi_blank_out
);

%gs_no_ds(GS-BMI-08, work.bmi_blank_out);


data work.bmi_dup;
     set work.bmi_case;
     output;
     if vstestcd = 'WEIGHT' then output;
run;

%gs_drop(work.bmi_dup_out);

%derive_param_bmi(
          dataset = work.bmi_dup
,             out = work.bmi_dup_out
);

%gs_no_ds(GS-BMI-09, work.bmi_dup_out);


%gs_drop(work.bmi_bad_out);

%derive_param_bmi(
          dataset = work.bmi_case
,             out = work.bmi_bad_out
, height_constant = X
);

%gs_no_ds(GS-BMI-10, work.bmi_bad_out);

%gs_done(derive_param_bmi);
