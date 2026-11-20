/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : gs_derive_param_bsa.sas
  SAS Version                 : 9.4
  Purpose (short description) : Golden-subject checks for derive_param_bsa
  Author                      : Cursor
  Date                        : 31OCT2026
  Input Datasets or Metadata  : Small VS rows built in this program
  Modification Log            :

  These checks use WORK data only. They do not call the ODA libname setup.
  PFDIR defaults to HOME/Adamski/SAS.
  Macros are in macro. These checks are in TestThat.

  Mosteller: sqrt(HEIGHT cm * WEIGHT kg / 3600).
  180 cm and 80 kg is 2. 120 cm and 30 kg is 1.

  These cases are expected to print ERROR from the macro and still PASS:
  GS-BSA-04 weight unit lb
  GS-BSA-05 blank height unit
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%if %symexist(PFDIR) = 0 %then %do;
    %let PFDIR = %sysfunc(strip(%sysget(HOME)))/Adamski/SAS;
%end;

%include "&PFDIR/macro/derive_param_computed.sas";
%include "&PFDIR/macro/cmp2_check_unit.sas";
%include "&PFDIR/macro/derive_param_bsa.sas";
%include "&PFDIR/TestThat/gs_pf_harness.sas";

%let gs_pass = 0;
%let gs_fail = 0;
%let gs_policy = 0;
%let gs_suite = derive_param_bsa;


data work.bsa_const;
     length usubjid $4
            visit   $8
            vstpt   $8
            vstestcd $8
            vsstresu $8;
     input usubjid $ visit $ vstpt $ vstestcd $ vsstresn vsstresu $;
datalines;
S1 WEEK2 T1 WEIGHT 80 kg
S1 WEEK4 T1 WEIGHT 80 kg
S1 SCREEN T1 HEIGHT 180 cm
;
run;

%derive_param_bsa(
          dataset = work.bsa_const
,             out = work.bsa_const_out
);

%gs_aval(GS-BSA-01, work.bsa_const_out, %str(paramcd='BSA' and visit='WEEK2'), 2);
%gs_aval(GS-BSA-02, work.bsa_const_out, %str(paramcd='BSA' and visit='WEEK4'), 2);


data work.bsa_visit;
     length usubjid $4
            visit   $8
            vstpt   $8
            vstestcd $8
            vsstresu $8;
     input usubjid $ visit $ vstpt $ vstestcd $ vsstresn vsstresu $;
datalines;
S1 WEEK2 T1 WEIGHT 30 kg
S1 WEEK2 T1 HEIGHT 120 cm
S1 WEEK4 T1 WEIGHT 30 kg
;
run;

%derive_param_bsa(
          dataset = work.bsa_visit
,             out = work.bsa_visit_out
, height_constant = N
);

%gs_aval(GS-BSA-03, work.bsa_visit_out, %str(paramcd='BSA' and visit='WEEK2'), 1);
%gs_n(GS-BSA-03N, work.bsa_visit_out, %str(paramcd='BSA'), 1);


data work.bsa_lb;
     length usubjid $4
            visit   $8
            vstpt   $8
            vstestcd $8
            vsstresu $8;
     input usubjid $ visit $ vstpt $ vstestcd $ vsstresn vsstresu $;
datalines;
S1 WEEK2 T1 WEIGHT 80 lb
S1 WEEK2 T1 HEIGHT 180 cm
;
run;

%gs_drop(work.bsa_lb_out);

%derive_param_bsa(
          dataset = work.bsa_lb
,             out = work.bsa_lb_out
);

%gs_no_ds(GS-BSA-04, work.bsa_lb_out);
%gs_unit(GS-BSA-04U, 1);


data work.bsa_blank;
     length usubjid $4
            visit   $8
            vstpt   $8
            vstestcd $8
            vsstresu $8;
     usubjid='S1'; visit='WEEK2'; vstpt='T1'; vstestcd='WEIGHT'; vsstresn=80;  vsstresu='kg'; output;
     usubjid='S1'; visit='WEEK2'; vstpt='T1'; vstestcd='HEIGHT'; vsstresn=180; vsstresu=' ';  output;
run;

%gs_drop(work.bsa_blank_out);

%derive_param_bsa(
          dataset = work.bsa_blank
,             out = work.bsa_blank_out
);

%gs_no_ds(GS-BSA-05, work.bsa_blank_out);

%gs_done(derive_param_bsa);
