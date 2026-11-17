/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : gs_derive_var_trtemfl.sas
  SAS Version                 : 9.4
  Purpose (short description) : Golden-subject checks for derive_var_trtemfl
  Author                      : Cursor
  Date                        : 15NOV2026
  Input Datasets or Metadata  : AE rows that already carry ADSL treatment dates
  Modification Log            : 15NOV2026 - Checks for derive_var_trtemfl.
                                16NOV2026 - Calls %derive_var_trtemfl.
                                16NOV2026 - Program name is gs_derive_var_trtemfl.

  These checks use WORK data only. They do not call the ODA libname setup.
  PFDIR defaults to HOME/Adamski/SAS.
  The macro is in macro. These checks are in TestThat.
  This script checks %derive_var_trtemfl.
  The suite name is derive_param_trtemfl so the shared harness can name
  the result file gs_trtemfl.

  Each input row is an AE record with ADSL TRTSDT, TRTSDTM, and TRTEDT
  already merged onto it. The macro reads those dates. It does not create
  them. That keeps the treatment dates on the flag output the same as ADSL.
  A call with no treatment-date variables does not write an output dataset.
  That case is GS-TE-00, and the macro WARNING for it is expected.

  Common window, unless a case says otherwise:
  TRTSDT 01JUN2020, TRTSDTM 01JUN2020:12:00, TRTEDT 15JUN2020.
  The default follow-up is 30 days, so the window end is 15JUL2020.

  GS-TE-00 no ADSL treatment variables on the input
  GS-TE-01 onset datetime before the treatment clock time
  GS-TE-02 onset date only, same calendar day as the treatment datetime
  GS-TE-03 onset date only, the calendar day before the treatment datetime
  GS-TE-04 onset datetime after the treatment clock time
  GS-TE-05 onset on the window end date
  GS-TE-06 onset the day after the window end
  GS-TE-07 event end before treatment, onset missing
  GS-TE-08 onset missing and no xxDTC
  GS-TE-09 treatment start missing
  GS-TE-10 month and year overlap the window, numeric onset missing
  GS-TE-11 month and year end before treatment
  GS-TE-12 year only, after the window
  GS-TE-13 year only, overlaps the window
  GS-TE-14 full xxDTC date, numeric onset missing
  GS-TE-15 xxDTC datetime before treatment, numeric onset missing
  GS-TE-16 TRTEDT missing, onset on treatment start plus 30 days
  GS-TE-17 TRTEDT missing, onset the day after that
  GS-TE-18 day imputed to the first of a month that meets the window
  GS-TE-19 same imputed day with day_impute_teae=NO
  GS-TE-20 pre-treatment grade 2, then 2, then 3
  GS-TE-21 pre-treatment grade missing, then an in-window grade
  GS-TE-22 and GS-TE-23 datetimes on 01JAN1960, before and after 08:00
  GS-TE-24 populated ASTDT is before treatment and xxDTC has a full day
  GS-TE-25 only AEENDTC, and that end is before treatment

  The result line is NOTE: [GOLDEN SUMMARY] or WARNING: [GOLDEN SUMMARY].
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%if %symexist(PFDIR) = 0 %then %do;
    %let PFDIR = %sysfunc(strip(%sysget(HOME)))/Adamski/SAS;
%end;

%include "&PFDIR/macro/derive_var_trtemfl.sas";
%include "&PFDIR/TestThat/gs_pf_harness.sas";

%let gs_pass = 0;
%let gs_fail = 0;
%let gs_policy = 0;
%let gs_suite = derive_param_trtemfl;


%macro gs_te_blank;
  astdt = .;
  astdtm = .;
  aendt = .;
  aendtm = .;
  aestdtc = ' ';
  aeendtc = ' ';
  atoxgr = '1';
  aedecod = 'HEADACHE';
  aeseq = 1;
  trtsdt = '01JUN2020'd;
  trtsdtm = '01JUN2020:12:00:00'dt;
  trtedt = '15JUN2020'd;
%mend gs_te_blank;


data work.te_in;
     length case_id $16
            usubjid $16
            aedecod $20
            atoxgr $3
            aestdtc aeendtc $20;
     format astdt aendt trtsdt trtedt date9.
            astdtm aendtm trtsdtm datetime20.;

     /* Onset time is before the noon dose. */
     %gs_te_blank;
     case_id = 'GS-TE-01';
     usubjid = 'GS-TE-01';
     astdt = '01JUN2020'd;
     astdtm = '01JUN2020:08:00:00'dt;
     aestdtc = '2020-06-01T08:00';
     atoxgr = '2';
     output;

     /* Date only, on the treatment calendar day. */
     %gs_te_blank;
     case_id = 'GS-TE-02';
     usubjid = 'GS-TE-02';
     astdt = '01JUN2020'd;
     aestdtc = '2020-06-01';
     output;

     /* Date only, the calendar day before treatment. */
     %gs_te_blank;
     case_id = 'GS-TE-03';
     usubjid = 'GS-TE-03';
     astdt = '31MAY2020'd;
     aestdtc = '2020-05-31';
     output;

     /* Onset time is after the noon dose. */
     %gs_te_blank;
     case_id = 'GS-TE-04';
     usubjid = 'GS-TE-04';
     astdt = '01JUN2020'd;
     astdtm = '01JUN2020:14:00:00'dt;
     aestdtc = '2020-06-01T14:00';
     output;

     /* Last day of TRTEDT plus 30 days. */
     %gs_te_blank;
     case_id = 'GS-TE-05';
     usubjid = 'GS-TE-05';
     astdt = '15JUL2020'd;
     astdtm = '15JUL2020:09:00:00'dt;
     aestdtc = '2020-07-15';
     output;

     /* The day after the window end. */
     %gs_te_blank;
     case_id = 'GS-TE-06';
     usubjid = 'GS-TE-06';
     astdt = '16JUL2020'd;
     astdtm = '16JUL2020:09:00:00'dt;
     aestdtc = '2020-07-16';
     output;

     /* The event ended before treatment. The onset is missing. */
     %gs_te_blank;
     case_id = 'GS-TE-07';
     usubjid = 'GS-TE-07';
     aendt = '15MAY2020'd;
     aeendtc = '2020-05-15';
     output;

     /* No onset date and no xxDTC. */
     %gs_te_blank;
     case_id = 'GS-TE-08';
     usubjid = 'GS-TE-08';
     output;

     /* ADSL treatment start was not merged onto this row. */
     %gs_te_blank;
     case_id = 'GS-TE-09';
     usubjid = 'GS-TE-09';
     trtsdt = .;
     trtsdtm = .;
     astdt = '01JUN2020'd;
     aestdtc = '2020-06-01';
     output;

     /* Month overlaps the window. Numeric onset is missing. */
     %gs_te_blank;
     case_id = 'GS-TE-10';
     usubjid = 'GS-TE-10';
     aestdtc = '2020-06';
     output;

     /* Month ends before treatment. */
     %gs_te_blank;
     case_id = 'GS-TE-11';
     usubjid = 'GS-TE-11';
     aestdtc = '2020-03';
     output;

     /* Year is entirely after the window. */
     %gs_te_blank;
     case_id = 'GS-TE-12';
     usubjid = 'GS-TE-12';
     aestdtc = '2021';
     output;

     /* Year overlaps the window. */
     %gs_te_blank;
     case_id = 'GS-TE-13';
     usubjid = 'GS-TE-13';
     aestdtc = '2020';
     output;

     /* Full xxDTC date inside the window. Numeric onset is missing. */
     %gs_te_blank;
     case_id = 'GS-TE-14';
     usubjid = 'GS-TE-14';
     aestdtc = '2020-07-01';
     output;

     /* xxDTC time is before the noon dose. Numeric onset is missing. */
     %gs_te_blank;
     case_id = 'GS-TE-15';
     usubjid = 'GS-TE-15';
     aestdtc = '2020-06-01T08:00';
     output;

     /* No TRTEDT. Onset is treatment start plus 30 days. */
     %gs_te_blank;
     case_id = 'GS-TE-16';
     usubjid = 'GS-TE-16';
     trtedt = .;
     astdt = '01JUL2020'd;
     astdtm = '01JUL2020:09:00:00'dt;
     aestdtc = '2020-07-01';
     output;

     /* No TRTEDT. Onset is one day later. */
     %gs_te_blank;
     case_id = 'GS-TE-17';
     usubjid = 'GS-TE-17';
     trtedt = .;
     astdt = '02JUL2020'd;
     astdtm = '02JUL2020:09:00:00'dt;
     aestdtc = '2020-07-02';
     output;

     /* Imputed day is 01JUN. Treatment starts 15JUN. The month still meets the window. */
     %gs_te_blank;
     case_id = 'GS-TE-18';
     usubjid = 'GS-TE-18';
     trtsdt = '15JUN2020'd;
     trtsdtm = '15JUN2020:12:00:00'dt;
     trtedt = '15JUN2020'd;
     astdt = '01JUN2020'd;
     aestdtc = '2020-06';
     output;

     /* Same term before treatment, then the same grade, then a higher grade. */
     %gs_te_blank;
     case_id = 'GS-TE-20A';
     usubjid = 'GS-TE-20';
     aedecod = 'NAUSEA';
     aeseq = 1;
     astdt = '01JUN2020'd;
     astdtm = '01JUN2020:08:00:00'dt;
     aestdtc = '2020-06-01T08:00';
     atoxgr = '2';
     output;

     %gs_te_blank;
     case_id = 'GS-TE-20B';
     usubjid = 'GS-TE-20';
     aedecod = 'NAUSEA';
     aeseq = 2;
     astdt = '02JUN2020'd;
     astdtm = '02JUN2020:09:00:00'dt;
     aestdtc = '2020-06-02T09:00';
     atoxgr = '2';
     output;

     %gs_te_blank;
     case_id = 'GS-TE-20C';
     usubjid = 'GS-TE-20';
     aedecod = 'NAUSEA';
     aeseq = 3;
     astdt = '03JUN2020'd;
     astdtm = '03JUN2020:09:00:00'dt;
     aestdtc = '2020-06-03T09:00';
     atoxgr = '3';
     output;

     /* Pre-treatment grade is missing, so the later grade cannot be cleared. */
     %gs_te_blank;
     case_id = 'GS-TE-21A';
     usubjid = 'GS-TE-21';
     aedecod = 'RASH';
     aeseq = 1;
     astdt = '01MAY2020'd;
     astdtm = '01MAY2020:09:00:00'dt;
     aestdtc = '2020-05-01T09:00';
     atoxgr = ' ';
     output;

     %gs_te_blank;
     case_id = 'GS-TE-21B';
     usubjid = 'GS-TE-21';
     aedecod = 'RASH';
     aeseq = 2;
     astdt = '05JUN2020'd;
     astdtm = '05JUN2020:09:00:00'dt;
     aestdtc = '2020-06-05T09:00';
     atoxgr = '1';
     output;

     /* Datetime values from 01JAN1960. The clock time is after 08:00. */
     %gs_te_blank;
     case_id = 'GS-TE-22';
     usubjid = 'GS-TE-22';
     trtsdt = '01JAN1960'd;
     trtsdtm = '01JAN1960:08:00:00'dt;
     trtedt = '31JAN1960'd;
     astdt = '01JAN1960'd;
     astdtm = '01JAN1960:10:00:00'dt;
     aestdtc = '1960-01-01T10:00';
     output;

     /* Same treatment datetime. The onset clock time is 07:00. */
     %gs_te_blank;
     case_id = 'GS-TE-23';
     usubjid = 'GS-TE-23';
     trtsdt = '01JAN1960'd;
     trtsdtm = '01JAN1960:08:00:00'dt;
     trtedt = '31JAN1960'd;
     astdt = '01JAN1960'd;
     astdtm = '01JAN1960:07:00:00'dt;
     aestdtc = '1960-01-01T07:00';
     output;

     /* ASTDT is a real earlier date. xxDTC has a day, so the month is not reused. */
     %gs_te_blank;
     case_id = 'GS-TE-24';
     usubjid = 'GS-TE-24';
     astdt = '01MAY2020'd;
     aestdtc = '2020-06-15';
     output;

     /* Only the end xxDTC is known, and it is before treatment. */
     %gs_te_blank;
     case_id = 'GS-TE-25';
     usubjid = 'GS-TE-25';
     aeendtc = '2020-05-01';
     output;
run;


%derive_var_trtemfl(
          dataset = work.te_in
,             out = work.te_out
);

%gs_n(GS-TE-N, work.te_out, %str(1), 27);

%gs_char(GS-TE-01, work.te_out, %str(case_id='GS-TE-01'), trtemfl, %str());
%gs_n(GS-TE-01D, work.te_out, %str(case_id='GS-TE-01' and trtsdt='01JUN2020'd and trtedt='15JUN2020'd), 1);
%gs_char(GS-TE-02, work.te_out, %str(case_id='GS-TE-02'), trtemfl, Y);
%gs_char(GS-TE-03, work.te_out, %str(case_id='GS-TE-03'), trtemfl, %str());
%gs_char(GS-TE-04, work.te_out, %str(case_id='GS-TE-04'), trtemfl, Y);
%gs_char(GS-TE-05, work.te_out, %str(case_id='GS-TE-05'), trtemfl, Y);
%gs_char(GS-TE-06, work.te_out, %str(case_id='GS-TE-06'), trtemfl, %str());
%gs_char(GS-TE-07, work.te_out, %str(case_id='GS-TE-07'), trtemfl, %str());
%gs_char(GS-TE-08, work.te_out, %str(case_id='GS-TE-08'), trtemfl, Y);
%gs_char(GS-TE-09, work.te_out, %str(case_id='GS-TE-09'), trtemfl, Y);
%gs_char(GS-TE-10, work.te_out, %str(case_id='GS-TE-10'), trtemfl, Y);
%gs_char(GS-TE-11, work.te_out, %str(case_id='GS-TE-11'), trtemfl, %str());
%gs_char(GS-TE-12, work.te_out, %str(case_id='GS-TE-12'), trtemfl, %str());
%gs_char(GS-TE-13, work.te_out, %str(case_id='GS-TE-13'), trtemfl, Y);
%gs_char(GS-TE-14, work.te_out, %str(case_id='GS-TE-14'), trtemfl, Y);
%gs_char(GS-TE-15, work.te_out, %str(case_id='GS-TE-15'), trtemfl, %str());
%gs_char(GS-TE-16, work.te_out, %str(case_id='GS-TE-16'), trtemfl, Y);
%gs_n(GS-TE-16D, work.te_out, %str(case_id='GS-TE-16' and trtsdt='01JUN2020'd and missing(trtedt)), 1);
%gs_char(GS-TE-17, work.te_out, %str(case_id='GS-TE-17'), trtemfl, %str());
%gs_char(GS-TE-18, work.te_out, %str(case_id='GS-TE-18'), trtemfl, Y);
%gs_char(GS-TE-20A, work.te_out, %str(case_id='GS-TE-20A'), trtemfl, %str());
%gs_char(GS-TE-20B, work.te_out, %str(case_id='GS-TE-20B'), trtemfl, %str());
%gs_char(GS-TE-20C, work.te_out, %str(case_id='GS-TE-20C'), trtemfl, Y);
%gs_char(GS-TE-21A, work.te_out, %str(case_id='GS-TE-21A'), trtemfl, %str());
%gs_char(GS-TE-21B, work.te_out, %str(case_id='GS-TE-21B'), trtemfl, Y);
%gs_char(GS-TE-22, work.te_out, %str(case_id='GS-TE-22'), trtemfl, Y);
%gs_char(GS-TE-23, work.te_out, %str(case_id='GS-TE-23'), trtemfl, %str());
%gs_char(GS-TE-24, work.te_out, %str(case_id='GS-TE-24'), trtemfl, %str());
%gs_char(GS-TE-25, work.te_out, %str(case_id='GS-TE-25'), trtemfl, %str());


data work.te_impute;
     set work.te_in;
     where case_id = 'GS-TE-18';
     case_id = 'GS-TE-19';
     usubjid = 'GS-TE-19';
run;

%derive_var_trtemfl(
          dataset = work.te_impute
,             out = work.te_impute_out
, day_impute_teae = NO
);

%gs_char(GS-TE-19, work.te_impute_out, %str(case_id='GS-TE-19'), trtemfl, %str());
%gs_n(GS-TE-19D, work.te_impute_out, %str(case_id='GS-TE-19' and trtsdt='15JUN2020'd and trtedt='15JUN2020'd), 1);


%gs_drop(work.te_noadsl_out);

data work.te_noadsl;
     length usubjid $16
            aedecod $20
            aestdtc $20;
     usubjid = 'GS-TE-00';
     aedecod = 'HEADACHE';
     astdt = '01JUN2020'd;
     aestdtc = '2020-06-01';
     output;
run;

%derive_var_trtemfl(
          dataset = work.te_noadsl
,             out = work.te_noadsl_out
);

%gs_no_ds(GS-TE-00, work.te_noadsl_out);

%gs_done(derive_param_trtemfl);
