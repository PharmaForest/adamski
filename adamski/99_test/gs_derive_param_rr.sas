/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : gs_derive_param_rr.sas
  SAS Version                 : 9.4
  Purpose (short description) : Golden-subject checks for derive_param_rr
  Author                      : Cursor
  Date                        : 31OCT2026
  Input Datasets or Metadata  : Small EG rows built in this program
  Modification Log            :

  These checks use WORK data only. They do not call the ODA libname setup.
  PFDIR defaults to HOME/Adamski/SAS.
  Macros are in macro. These checks are in TestThat.

  Heart rate 60 is RR 1000 ms. Heart rate 75 is RR 800 ms.
  The macro default PARAMCD is RR.

  These cases are expected to print ERROR from the macro and still PASS:
  GS-RR-04 heart rate unit bpm
  GS-RR-05 blank heart-rate unit
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%if %symexist(PFDIR) = 0 %then %do;
    %let PFDIR = %sysfunc(strip(%sysget(HOME)))/Adamski/SAS;
%end;

%include "&PFDIR/macro/derive_param_computed.sas";
%include "&PFDIR/macro/cmp2_check_unit.sas";
%include "&PFDIR/macro/derive_param_rr.sas";
%include "&PFDIR/TestThat/gs_pf_harness.sas";

%let gs_pass = 0;
%let gs_fail = 0;
%let gs_policy = 0;
%let gs_suite = derive_param_rr;


data work.rr_in;
     length usubjid $4
            visit   $8
            egtpt   $8
            egtestcd $8
            egstresu $12;
     input usubjid $ visit $ egtpt $ egtestcd $ egstresn egstresu $;
datalines;
S1 WEEK2 T1 HR 60 beats/min
S1 WEEK2 T2 HR 75 beats/min
S1 WEEK4 T1 HR . beats/min
;
run;

%derive_param_rr(
     dataset = work.rr_in
,        out = work.rr_out
);

%gs_aval(GS-RR-01, work.rr_out, %str(paramcd='RR' and egtpt='T1' and visit='WEEK2'), 1000);
%gs_aval(GS-RR-02, work.rr_out, %str(paramcd='RR' and egtpt='T2'), 800);
%gs_n(GS-RR-03, work.rr_out, %str(paramcd='RR' and visit='WEEK4'), 0);
%gs_char(GS-RR-03P, work.rr_out, %str(paramcd='RR' and egtpt='T1'), paramcd, RR);


data work.rr_bpm;
     length usubjid $4
            visit   $8
            egtpt   $8
            egtestcd $8
            egstresu $12;
     input usubjid $ visit $ egtpt $ egtestcd $ egstresn egstresu $;
datalines;
S1 WEEK2 T1 HR 60 bpm
;
run;

%gs_drop(work.rr_bpm_out);

%derive_param_rr(
     dataset = work.rr_bpm
,        out = work.rr_bpm_out
);

%gs_no_ds(GS-RR-04, work.rr_bpm_out);
%gs_unit(GS-RR-04U, 1);


data work.rr_blank;
     length usubjid $4
            visit   $8
            egtpt   $8
            egtestcd $8
            egstresu $12;
     usubjid='S1'; visit='WEEK2'; egtpt='T1'; egtestcd='HR'; egstresn=60; egstresu=' '; output;
run;

%gs_drop(work.rr_blank_out);

%derive_param_rr(
     dataset = work.rr_blank
,        out = work.rr_blank_out
);

%gs_no_ds(GS-RR-05, work.rr_blank_out);

%gs_done(derive_param_rr);
