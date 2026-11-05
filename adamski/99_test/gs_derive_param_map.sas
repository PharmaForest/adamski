/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : gs_derive_param_map.sas
  SAS Version                 : 9.4
  Purpose (short description) : Golden-subject checks for derive_param_map
  Author                      : Cursor
  Date                        : 31OCT2026
  Input Datasets or Metadata  : Small VS rows built in this program
  Modification Log            :

  These checks use WORK data only. They do not call the ODA libname setup.
  PFDIR defaults to HOME/Adamski/SAS.
  Macros are in macro. These checks are in TestThat.

  Without heart rate, SYSBP 120 and DIABP 60 is 80.
  A second time point, SYSBP 90 and DIABP 90, is 90.
  With heart rate, the expected value is the published expression
  evaluated in this program.

  These cases are expected to print ERROR from the macro and still PASS:
  GS-MAP-05 unit mm Hg
  GS-MAP-06 heart rate unit bpm when hr_code is supplied
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%if %symexist(PFDIR) = 0 %then %do;
    %let PFDIR = %sysfunc(strip(%sysget(HOME)))/Adamski/SAS;
%end;

%include "&PFDIR/macro/derive_param_computed.sas";
%include "&PFDIR/macro/cmp2_check_unit.sas";
%include "&PFDIR/macro/derive_param_map.sas";
%include "&PFDIR/TestThat/gs_pf_harness.sas";

%let gs_pass = 0;
%let gs_fail = 0;
%let gs_policy = 0;
%let gs_suite = derive_param_map;


data work.map_tpt;
     length usubjid $4
            visit   $8
            vstpt   $8
            vstestcd $8
            vsstresu $12;
     usubjid='S1'; visit='WEEK2'; vstpt='STAND';  vstestcd='SYSBP'; vsstresn=120; vsstresu='MMHG'; output;
     usubjid='S1'; visit='WEEK2'; vstpt='STAND';  vstestcd='DIABP'; vsstresn=60;  vsstresu='MMHG'; output;
     usubjid='S1'; visit='WEEK2'; vstpt='SUPINE'; vstestcd='SYSBP'; vsstresn=90;  vsstresu='mmHg'; output;
     usubjid='S1'; visit='WEEK2'; vstpt='SUPINE'; vstestcd='DIABP'; vsstresn=90;  vsstresu='mmHg'; output;
     usubjid='S1'; visit='WEEK2'; vstpt='STAND';  vstestcd='HR';    vsstresn=60;  vsstresu='beats/min'; output;
run;

%gs_drop(work.map_tpt_out);

%derive_param_map(
       dataset = work.map_tpt
,          out = work.map_tpt_out
);

%gs_aval(GS-MAP-01, work.map_tpt_out, %str(paramcd='MAP' and vstpt='STAND'), 80);
%gs_aval(GS-MAP-02, work.map_tpt_out, %str(paramcd='MAP' and vstpt='SUPINE'), 90);


data _null_;
     map_hr_exp = 60 + 0.01 * exp(4.14 - 40.74/60) * (120 - 60);
     call symputx('map_hr_exp', map_hr_exp, 'G');
run;

%gs_drop(work.map_hr_out);

%derive_param_map(
       dataset = work.map_tpt
,          out = work.map_hr_out
,      hr_code = HR
);

%gs_aval(GS-MAP-03, work.map_hr_out, %str(paramcd='MAP' and vstpt='STAND'), &map_hr_exp);
%gs_n(GS-MAP-04, work.map_hr_out, %str(paramcd='MAP' and vstpt='SUPINE'), 0);


data work.map_space;
     length usubjid $4
            visit   $8
            vstpt   $8
            vstestcd $8
            vsstresu $8;
     usubjid='S1'; visit='WEEK2'; vstpt='STAND'; vstestcd='SYSBP'; vsstresn=120; vsstresu='mm Hg'; output;
     usubjid='S1'; visit='WEEK2'; vstpt='STAND'; vstestcd='DIABP'; vsstresn=60;  vsstresu='mmHg';  output;
run;

%gs_drop(work.map_space_out);

%derive_param_map(
       dataset = work.map_space
,          out = work.map_space_out
);

%gs_no_ds(GS-MAP-05, work.map_space_out);
%gs_unit(GS-MAP-05U, 1);


data work.map_bpm;
     length usubjid $4
            visit   $8
            vstpt   $8
            vstestcd $8
            vsstresu $12;
     input usubjid $ visit $ vstpt $ vstestcd $ vsstresn vsstresu $;
datalines;
S1 WEEK2 STAND SYSBP 120 mmHg
S1 WEEK2 STAND DIABP 80 mmHg
S1 WEEK2 STAND HR 60 bpm
;
run;

%gs_drop(work.map_bpm_out);

%derive_param_map(
       dataset = work.map_bpm
,          out = work.map_bpm_out
,      hr_code = HR
);

%gs_no_ds(GS-MAP-06, work.map_bpm_out);

%gs_done(derive_param_map);
