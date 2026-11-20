/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : gs_derive_param_qtc.sas
  SAS Version                 : 9.4
  Purpose (short description) : Golden-subject checks for derive_param_qtc
  Author                      : Cursor
  Date                        : 31OCT2026
  Input Datasets or Metadata  : Small EG rows built in this program
  Modification Log            :

  These checks use WORK data only. They do not call the ODA libname setup.
  PFDIR defaults to HOME/Adamski/SAS.
  Macros are in macro. These checks are in TestThat.

  Bazett with QT 400 and RR 250 is 800.
  Fridericia with QT 400 and RR 1000 is 400.
  Sagie with QT 350 and RR 500 is 427.
  ms and msec are both accepted.

  These cases are expected to print ERROR from the macro and still PASS:
  GS-QTC-05 unit sec on one subject stops the whole call
  GS-QTC-06 method Hodges
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%if %symexist(PFDIR) = 0 %then %do;
    %let PFDIR = %sysfunc(strip(%sysget(HOME)))/Adamski/SAS;
%end;

%include "&PFDIR/macro/derive_param_computed.sas";
%include "&PFDIR/macro/cmp2_check_unit.sas";
%include "&PFDIR/macro/derive_param_qtc.sas";
%include "&PFDIR/TestThat/gs_pf_harness.sas";

%let gs_pass = 0;
%let gs_fail = 0;
%let gs_policy = 0;
%let gs_suite = derive_param_qtc;


data work.qtc_baz;
     length usubjid $4
            visit   $8
            egtpt   $8
            egtestcd $8
            egstresu $8;
     input usubjid $ visit $ egtpt $ egtestcd $ egstresn egstresu $;
datalines;
S1 WEEK2 T1 QT 400 msec
S1 WEEK2 T1 RR 250 msec
S2 WEEK2 T1 QT 400 ms
S2 WEEK2 T1 RR 250 ms
S3 WEEK2 T1 QT . msec
S3 WEEK2 T1 RR 250 msec
;
run;

%derive_param_qtc(
      dataset = work.qtc_baz
,         out = work.qtc_baz_out
,      method = Bazett
);

%gs_aval(GS-QTC-01, work.qtc_baz_out, %str(paramcd='QTCBR' and usubjid='S1'), 800);
%gs_aval(GS-QTC-02, work.qtc_baz_out, %str(paramcd='QTCBR' and usubjid='S2'), 800);
%gs_n(GS-QTC-03, work.qtc_baz_out, %str(paramcd='QTCBR' and usubjid='S3'), 0);


data work.qtc_fri;
     length usubjid $4
            visit   $8
            egtpt   $8
            egtestcd $8
            egstresu $8;
     input usubjid $ visit $ egtpt $ egtestcd $ egstresn egstresu $;
datalines;
S1 WEEK2 T1 QT 400 ms
S1 WEEK2 T1 RR 1000 ms
;
run;

%derive_param_qtc(
      dataset = work.qtc_fri
,         out = work.qtc_fri_out
,      method = Fridericia
);

%gs_aval(GS-QTC-04, work.qtc_fri_out, %str(paramcd='QTCFR'), 400);


data work.qtc_sag;
     length usubjid $4
            visit   $8
            egtpt   $8
            egtestcd $8
            egstresu $8;
     input usubjid $ visit $ egtpt $ egtestcd $ egstresn egstresu $;
datalines;
S1 WEEK2 T1 QT 350 msec
S1 WEEK2 T1 RR 500 msec
;
run;

%derive_param_qtc(
      dataset = work.qtc_sag
,         out = work.qtc_sag_out
,      method = Sagie
);

%gs_aval(GS-QTC-04S, work.qtc_sag_out, %str(paramcd='QTLCR'), 427);


data work.qtc_sec;
     length usubjid $4
            visit   $8
            egtpt   $8
            egtestcd $8
            egstresu $8;
     input usubjid $ visit $ egtpt $ egtestcd $ egstresn egstresu $;
datalines;
S1 WEEK2 T1 QT 400 msec
S1 WEEK2 T1 RR 250 msec
S2 WEEK2 T1 QT 400 sec
S2 WEEK2 T1 RR 250 msec
;
run;

%gs_drop(work.qtc_sec_out);

%derive_param_qtc(
      dataset = work.qtc_sec
,         out = work.qtc_sec_out
,      method = Bazett
);

%gs_no_ds(GS-QTC-05, work.qtc_sec_out);
%gs_unit(GS-QTC-05U, 1);


%gs_drop(work.qtc_bad_out);

%derive_param_qtc(
      dataset = work.qtc_fri
,         out = work.qtc_bad_out
,      method = Hodges
);

%gs_no_ds(GS-QTC-06, work.qtc_bad_out);

%gs_done(derive_param_qtc);
