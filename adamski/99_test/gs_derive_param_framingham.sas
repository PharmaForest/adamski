/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : gs_derive_param_framingham.sas
  SAS Version                 : 9.4
  Purpose (short description) : Golden-subject checks for derive_param_framingham
  Author                      : Cursor
  Date                        : 09NOV2026
  Input Datasets or Metadata  : Small stacked BDS rows built in this program
  Modification Log            : 09NOV2026 - Add scores for one flag at a time, a carried
                                study id, a caller label, a close age, and two
                                time points.

  These checks use WORK data only. They do not call the ODA libname setup.
  PFDIR defaults to HOME/Adamski/SAS.
  Macros are in macro. These checks are in TestThat.

  Scores follow compute_framingham. Treated men use systolic coefficient
  1.99881. The inputs are the admiral examples.

  These cases are expected to print WARNING from the macro and still PASS:
  GS-FCVD-13 cholesterol unit mmol/L
  GS-FCVD-14 two SYSBP rows at one key
  GS-FCVD-15 sex U
  GS-FCVD-16 blank HDL unit
  GS-FCVD-17 cholesterol of -1, which drops that key only

  These cases are expected to add score rows:
  GS-FCVD-18 through GS-FCVD-23 one smoking or diabetes term at a time
  GS-FCVD-24 a carried study id and a caller parameter label
  GS-FCVD-25 ages that differ by less than the match tolerance
  GS-FCVD-26 two time points at the same visit

  The result line is NOTE: [GOLDEN SUMMARY] or WARNING: [GOLDEN SUMMARY].
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%if %symexist(PFDIR) = 0 %then %do;
    %let PFDIR = %sysfunc(strip(%sysget(HOME)))/Adamski/SAS;
%end;

%include "&PFDIR/macro/cmp2_check_unit.sas";
%include "&PFDIR/macro/derive_param_framingham.sas";
%include "&PFDIR/TestThat/gs_pf_harness.sas";

%let gs_pass = 0;
%let gs_fail = 0;
%let gs_policy = 0;
%let gs_suite = derive_param_framingham;


data work.fcvd_main;
     length usubjid $12
            paramcd $8
            param   $60
            avalu   $8
            visit   $10
            sex     $1
            smokefl $1
            diabetfl $1
            trthypfl $1;
     input usubjid $
           paramcd $
           aval
           avalu $
           visit $
           age
           sex $
           smokefl $
           diabetfl $
           trthypfl $;
     param = catx(' ', paramcd, avalu);
datalines;
F1015 SYSBP 121 mmHg BASELINE 44 F N N N
F1015 CHOL 216.16 mg/dL BASELINE 44 F N N N
F1015 CHOLHDL 54.91 mg/dL BASELINE 44 F N N N
F1015 SYSBP 115 mmHg WEEK2 44 F N N Y
F1015 CHOL 210.78 mg/dL WEEK2 44 F N N Y
F1015 CHOLHDL 26.72 mg/dL WEEK2 44 F N N Y
M1028 SYSBP 119 MMHG BASELINE 55 M Y Y Y
M1028 CHOL 292.01 MG/DL BASELINE 55 M Y Y Y
M1028 CHOLHDL 65.55 MG/DL BASELINE 55 M Y Y Y
M1028 SYSBP 101 MMHG WEEK2 55 M Y Y Y
M1028 CHOL 246.73 MG/DL WEEK2 55 M Y Y Y
M1028 CHOLHDL 44.62 MG/DL WEEK2 55 M Y Y Y
M53 SYSBP 133 mmHg BASELINE 53 M N N N
M53 CHOL 216.16 mg/dL BASELINE 53 M N N N
M53 CHOLHDL 54.91 mg/dL BASELINE 53 M N N N
M53 SYSBP 133 mmHg WEEK2 53 M N N Y
M53 CHOL 216.16 mg/dL WEEK2 53 M N N Y
M53 CHOLHDL 54.91 mg/dL WEEK2 53 M N N Y
F52 SYSBP 161 mmHg BASELINE 52 f y n y
F52 CHOL 186.39 mg/dL BASELINE 52 f y n y
F52 CHOLHDL 64.19 mg/dL BASELINE 52 f y n y
;
run;

%derive_param_framingham(
     dataset = work.fcvd_main
,        out = work.fcvd_main_out
);

%gs_aval(GS-FCVD-01, work.fcvd_main_out, %str(paramcd='FCVD101' and usubjid='F1015' and visit='BASELINE'), 3.13561405);
%gs_aval(GS-FCVD-02, work.fcvd_main_out, %str(paramcd='FCVD101' and usubjid='F1015' and visit='WEEK2'), 5.80073036);
%gs_aval(GS-FCVD-03, work.fcvd_main_out, %str(paramcd='FCVD101' and usubjid='M1028' and visit='BASELINE'), 42.30739315);
%gs_aval(GS-FCVD-04, work.fcvd_main_out, %str(paramcd='FCVD101' and usubjid='M1028' and visit='WEEK2'), 37.46547303);
%gs_aval(GS-FCVD-05, work.fcvd_main_out, %str(paramcd='FCVD101' and usubjid='M53' and visit='BASELINE'), 10.37513713);
%gs_aval(GS-FCVD-06, work.fcvd_main_out, %str(paramcd='FCVD101' and usubjid='M53' and visit='WEEK2'), 14.02397752);
%gs_aval(GS-FCVD-07, work.fcvd_main_out, %str(paramcd='FCVD101' and usubjid='F52' and visit='BASELINE'), 16.40353463);
%gs_n(GS-FCVD-08, work.fcvd_main_out, %str(paramcd='FCVD101'), 7);
%gs_unit(GS-FCVD-08U, 0);
%gs_aval(GS-FCVD-09, work.fcvd_main_out, %str(paramcd='SYSBP' and usubjid='F1015' and visit='BASELINE'), 121);
%gs_n(GS-FCVD-10, work.fcvd_main_out, %str(paramcd='FCVD101' and index(param, 'Framingham CVD 10-Year Risk Score') > 0), 7);
%gs_n(GS-FCVD-11, work.fcvd_main_out, %str(paramcd='FCVD101' and missing(avalu)), 7);


data work.fcvd_gap;
     length usubjid $12
            paramcd $8
            avalu   $8
            visit   $10
            sex     $1
            smokefl $1
            diabetfl $1
            trthypfl $1;
     input usubjid $ paramcd $ aval avalu $ visit $ age sex $ smokefl $ diabetfl $ trthypfl $;
datalines;
S5 SYSBP 121 mmHg BASELINE 44 F N N N
S5 CHOL 216.16 mg/dL BASELINE 44 F N N N
S5 CHOLHDL 54.91 mg/dL BASELINE 44 F N N N
S5 SYSBP 115 mmHg WEEK2 44 F N N Y
S5 CHOL 210.78 mg/dL WEEK2 44 F N N Y
;
run;

%derive_param_framingham(
     dataset = work.fcvd_gap
,        out = work.fcvd_gap_out
);

%gs_aval(GS-FCVD-12, work.fcvd_gap_out, %str(paramcd='FCVD101' and visit='BASELINE'), 3.13561405);
%gs_n(GS-FCVD-12N, work.fcvd_gap_out, %str(paramcd='FCVD101'), 1);


data work.fcvd_mmol;
     length usubjid $12
            paramcd $8
            avalu   $8
            visit   $10
            sex     $1
            smokefl $1
            diabetfl $1
            trthypfl $1;
     input usubjid $ paramcd $ aval avalu $ visit $ age sex $ smokefl $ diabetfl $ trthypfl $;
datalines;
S1 SYSBP 121 mmHg BASELINE 44 F N N N
S1 CHOL 5.6 mmol/L BASELINE 44 F N N N
S1 CHOLHDL 54.91 mg/dL BASELINE 44 F N N N
;
run;

%gs_drop(work.fcvd_mmol_out);

%derive_param_framingham(
     dataset = work.fcvd_mmol
,        out = work.fcvd_mmol_out
);

%gs_no_ds(GS-FCVD-13, work.fcvd_mmol_out);
%gs_unit(GS-FCVD-13U, 1);


data work.fcvd_dup;
     length usubjid $12
            paramcd $8
            avalu   $8
            visit   $10
            sex     $1
            smokefl $1
            diabetfl $1
            trthypfl $1;
     input usubjid $ paramcd $ aval avalu $ visit $ age sex $ smokefl $ diabetfl $ trthypfl $;
datalines;
S1 SYSBP 121 mmHg BASELINE 44 F N N N
S1 SYSBP 130 mmHg BASELINE 44 F N N N
S1 CHOL 216.16 mg/dL BASELINE 44 F N N N
S1 CHOLHDL 54.91 mg/dL BASELINE 44 F N N N
;
run;

%gs_drop(work.fcvd_dup_out);

%derive_param_framingham(
     dataset = work.fcvd_dup
,        out = work.fcvd_dup_out
);

%gs_no_ds(GS-FCVD-14, work.fcvd_dup_out);


data work.fcvd_sex;
     length usubjid $12
            paramcd $8
            avalu   $8
            visit   $10
            sex     $1
            smokefl $1
            diabetfl $1
            trthypfl $1;
     input usubjid $ paramcd $ aval avalu $ visit $ age sex $ smokefl $ diabetfl $ trthypfl $;
datalines;
S1 SYSBP 121 mmHg BASELINE 44 U N N N
S1 CHOL 216.16 mg/dL BASELINE 44 U N N N
S1 CHOLHDL 54.91 mg/dL BASELINE 44 U N N N
;
run;

%gs_drop(work.fcvd_sex_out);

%derive_param_framingham(
     dataset = work.fcvd_sex
,        out = work.fcvd_sex_out
);

%gs_no_ds(GS-FCVD-15, work.fcvd_sex_out);


data work.fcvd_blank;
     length usubjid $12
            paramcd $8
            avalu   $8
            visit   $10
            sex     $1
            smokefl $1
            diabetfl $1
            trthypfl $1;
     usubjid='S1'; visit='BASELINE'; paramcd='SYSBP';   aval=121;   avalu='mmHg';  age=44; sex='F'; smokefl='N'; diabetfl='N'; trthypfl='N'; output;
     usubjid='S1'; visit='BASELINE'; paramcd='CHOL';    aval=216.16; avalu='mg/dL'; age=44; sex='F'; smokefl='N'; diabetfl='N'; trthypfl='N'; output;
     usubjid='S1'; visit='BASELINE'; paramcd='CHOLHDL'; aval=54.91; avalu=' ';     age=44; sex='F'; smokefl='N'; diabetfl='N'; trthypfl='N'; output;
run;

%gs_drop(work.fcvd_blank_out);

%derive_param_framingham(
     dataset = work.fcvd_blank
,        out = work.fcvd_blank_out
);

%gs_no_ds(GS-FCVD-16, work.fcvd_blank_out);


data work.fcvd_neg;
     length usubjid $12
            paramcd $8
            avalu   $8
            visit   $10
            sex     $1
            smokefl $1
            diabetfl $1
            trthypfl $1;
     input usubjid $ paramcd $ aval avalu $ visit $ age sex $ smokefl $ diabetfl $ trthypfl $;
datalines;
SGOOD SYSBP 121 mmHg BASELINE 44 F N N N
SGOOD CHOL 216.16 mg/dL BASELINE 44 F N N N
SGOOD CHOLHDL 54.91 mg/dL BASELINE 44 F N N N
SBAD SYSBP 121 mmHg BASELINE 44 F N N N
SBAD CHOL -1 mg/dL BASELINE 44 F N N N
SBAD CHOLHDL 54.91 mg/dL BASELINE 44 F N N N
;
run;

%derive_param_framingham(
     dataset = work.fcvd_neg
,        out = work.fcvd_neg_out
);

%gs_aval(GS-FCVD-17, work.fcvd_neg_out, %str(paramcd='FCVD101' and usubjid='SGOOD'), 3.13561405);
%gs_n(GS-FCVD-17N, work.fcvd_neg_out, %str(paramcd='FCVD101'), 1);


/* One smoking or diabetes term at a time, from compute_framingham.
   STUDYID is carried. The parameter label is supplied by the caller. */
data work.fcvd_ok;
     length usubjid $12
            studyid $8
            paramcd $8
            avalu   $8
            visit   $10
            sex     $1
            smokefl $1
            diabetfl $1
            trthypfl $1;
     studyid = 'ABC';
     visit = 'BASELINE';
     input usubjid $
           paramcd $
           aval
           avalu $
           age
           sex $
           smokefl $
           diabetfl $
           trthypfl $;
datalines;
MDIAB SYSBP 133 mmHg 53 M N Y N
MDIAB CHOL 216.16 mg/dL 53 M N Y N
MDIAB CHOLHDL 54.91 mg/dL 53 M N Y N
MSMK SYSBP 133 mmHg 53 M Y N N
MSMK CHOL 216.16 mg/dL 53 M Y N N
MSMK CHOLHDL 54.91 mg/dL 53 M Y N N
FUN SYSBP 133 mmHg 53 F N N N
FUN CHOL 216.16 mg/dL 53 F N N N
FUN CHOLHDL 54.91 mg/dL 53 F N N N
FTR SYSBP 133 mmHg 53 F N N Y
FTR CHOL 216.16 mg/dL 53 F N N Y
FTR CHOLHDL 54.91 mg/dL 53 F N N Y
FDIA SYSBP 133 mmHg 53 F N Y N
FDIA CHOL 216.16 mg/dL 53 F N Y N
FDIA CHOLHDL 54.91 mg/dL 53 F N Y N
FSMK SYSBP 133 mmHg 53 F Y N N
FSMK CHOL 216.16 mg/dL 53 F Y N N
FSMK CHOLHDL 54.91 mg/dL 53 F Y N N
;
run;

%derive_param_framingham(
     dataset = work.fcvd_ok
,        out = work.fcvd_ok_out
,       carry = STUDYID
,       param = CVD risk score
);

%gs_aval(GS-FCVD-18, work.fcvd_ok_out, %str(paramcd='FCVD101' and usubjid='MDIAB'), 17.66744232);
%gs_aval(GS-FCVD-19, work.fcvd_ok_out, %str(paramcd='FCVD101' and usubjid='MSMK'), 19.00411502);
%gs_aval(GS-FCVD-20, work.fcvd_ok_out, %str(paramcd='FCVD101' and usubjid='FUN'), 6.18123965);
%gs_aval(GS-FCVD-21, work.fcvd_ok_out, %str(paramcd='FCVD101' and usubjid='FTR'), 8.24132189);
%gs_aval(GS-FCVD-22, work.fcvd_ok_out, %str(paramcd='FCVD101' and usubjid='FDIA'), 11.96236247);
%gs_aval(GS-FCVD-23, work.fcvd_ok_out, %str(paramcd='FCVD101' and usubjid='FSMK'), 10.26087917);
%gs_n(GS-FCVD-24, work.fcvd_ok_out, %str(paramcd='FCVD101'), 6);
%gs_char(GS-FCVD-24C, work.fcvd_ok_out, %str(paramcd='FCVD101' and usubjid='MDIAB'), studyid, ABC);
%gs_char(GS-FCVD-24P, work.fcvd_ok_out, %str(paramcd='FCVD101' and usubjid='MDIAB'), param, CVD risk score);


/* Cholesterol age is 0.000000001 above the systolic age. That is inside the match tolerance. */
data work.fcvd_age;
     length usubjid $12
            paramcd $8
            avalu   $8
            visit   $10
            sex     $1
            smokefl $1
            diabetfl $1
            trthypfl $1;
     usubjid = 'F1015';
     visit = 'BASELINE';
     sex = 'F';
     smokefl = 'N';
     diabetfl = 'N';
     trthypfl = 'N';
     paramcd = 'SYSBP';
     aval = 121;
     avalu = 'mmHg';
     age = 44;
     output;
     paramcd = 'CHOL';
     aval = 216.16;
     avalu = 'mg/dL';
     age = 44 + 0.000000001;
     output;
     paramcd = 'CHOLHDL';
     aval = 54.91;
     avalu = 'mg/dL';
     age = 44;
     output;
run;

%derive_param_framingham(
     dataset = work.fcvd_age
,        out = work.fcvd_age_out
);

%gs_aval(GS-FCVD-25, work.fcvd_age_out, %str(paramcd='FCVD101' and usubjid='F1015'), 3.13561405);


data work.fcvd_tpt;
     length usubjid $12
            paramcd $8
            avalu   $8
            visit   $10
            atpt    $8
            sex     $1
            smokefl $1
            diabetfl $1
            trthypfl $1;
     usubjid = 'F1015';
     visit = 'BASELINE';
     sex = 'F';
     smokefl = 'N';
     diabetfl = 'N';
     age = 44;
     atpt = 'T1';
     trthypfl = 'N';
     paramcd = 'SYSBP';
     aval = 121;
     avalu = 'mmHg';
     output;
     paramcd = 'CHOL';
     aval = 216.16;
     avalu = 'mg/dL';
     output;
     paramcd = 'CHOLHDL';
     aval = 54.91;
     avalu = 'mg/dL';
     output;
     atpt = 'T2';
     trthypfl = 'Y';
     paramcd = 'SYSBP';
     aval = 115;
     avalu = 'mmHg';
     output;
     paramcd = 'CHOL';
     aval = 210.78;
     avalu = 'mg/dL';
     output;
     paramcd = 'CHOLHDL';
     aval = 26.72;
     avalu = 'mg/dL';
     output;
run;

%derive_param_framingham(
     dataset = work.fcvd_tpt
,        out = work.fcvd_tpt_out
,         tpt = ATPT
);

%gs_aval(GS-FCVD-26, work.fcvd_tpt_out, %str(paramcd='FCVD101' and atpt='T1'), 3.13561405);
%gs_aval(GS-FCVD-26B, work.fcvd_tpt_out, %str(paramcd='FCVD101' and atpt='T2'), 5.80073036);
%gs_n(GS-FCVD-26N, work.fcvd_tpt_out, %str(paramcd='FCVD101'), 2);

%gs_done(derive_param_framingham);
