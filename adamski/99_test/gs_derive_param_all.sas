/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : gs_derive_param_all.sas
  SAS Version                 : 9.4
  Purpose (short description) : Run every derived-parameter golden-subject script
  Author                      : Cursor
  Date                        : 03NOV2026
  Input Datasets or Metadata  : The gs_derive_param scripts in this folder
  Modification Log            :

  These checks use WORK data only. They do not call the ODA libname setup.
  PFDIR defaults to HOME/Adamski/SAS.
  Macros are in macro. These checks are in TestThat.

  Each script prints its own NOTE: [GOLDEN SUMMARY] or WARNING: [GOLDEN SUMMARY].

  Resolved macro code is not written to the log. That trace made the log
  too long for ODA to finish the steps that write the output folder.
  The checks are the present edge cases in the gs_derive_param scripts.
  The summary write follows last summer. One small dataset has PASS, FAIL,
  POLICY, and TOTAL. The detail dataset is one row per present edge case.
  The input golden-subject datasets are written to &PFDIR/validation.
  gs_summary has one row per derived parameter, with PASS, FAIL, and POLICY counts.
  gs_detail has one row per edge case. The test id is BMI-01 and the like.
  Each detail row has the edge-case text, the obtained value, and the correct value.
  POLICY is an accepted difference. It is not counted as a failure.

  WARNING lines from derive_param_bmi, derive_param_bsa, derive_param_map,
  derive_param_wbc_abs, derive_param_rr, and derive_param_qtc are expected
  when the golden-subject input is the bad-unit or bad-key case. A PASS
  on that check means the macro stopped and did not create the output.
  WARNING: [GOLDEN FAIL] means a check did not get the expected result.
  Those messages are not SAS errors. A log line that begins with ERROR
  puts ODA into syntax-check mode, and later steps write no datasets.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%if %symexist(PFDIR) = 0 %then %do;
    %let PFDIR = %sysfunc(strip(%sysget(HOME)))/Adamski/SAS;
%end;

%if %sysfunc(fileexist(&PFDIR/logs)) = 0 %then %do;
    %let _gs_dir = %sysfunc(dcreate(logs, &PFDIR/));
%end;

%if %sysfunc(fileexist(&PFDIR/validation)) = 0 %then %do;
    %let _gs_dir = %sysfunc(dcreate(validation, &PFDIR/));
%end;

%if %sysfunc(fileexist(&PFDIR/output)) = 0 %then %do;
    %let _gs_dir = %sysfunc(dcreate(output, &PFDIR/));
%end;

options errorcheck=normal nosyntaxcheck obs=max replace
        notes nosource nomprint nosymbolgen nomprintnest;

%let gs_all_pass = 0;
%let gs_all_fail = 0;
%let gs_all_policy = 0;


%macro gs_add;
  %if %symexist(gs_pass) %then %do;
      %let gs_all_pass = %eval(&gs_all_pass + &gs_pass);
  %end;
  %if %symexist(gs_fail) %then %do;
      %let gs_all_fail = %eval(&gs_all_fail + &gs_fail);
  %end;
  %if %symexist(gs_policy) %then %do;
      %let gs_all_policy = %eval(&gs_all_policy + &gs_policy);
  %end;
%mend gs_add;


%macro gs_include(name);
  %global gs_pass gs_fail gs_policy gs_suite;
  %include "&PFDIR/TestThat/&name";
%mend gs_include;


%macro gs_save(mem);
  %if %sysfunc(exist(work.&mem)) %then %do;
      data gsval.&mem;
           set work.&mem;
      run;
  %end;
%mend gs_save;


%if %sysfunc(exist(work.gs_result)) %then %do;
    proc datasets lib=work nolist;
         delete gs_result gs_summary gs_detail gs_tests gs_edge gs_fail;
    quit;
%end;

%let gs_keep_result = 1;


%global gs_pass gs_fail gs_policy gs_suite;

%let gs_pass = 0;
%let gs_fail = 0;
%let gs_policy = 0;
%put NOTE: Starting derive_param_bmi;
%include "&PFDIR/TestThat/gs_derive_param_bmi.sas";
%gs_add;
%put NOTE: Finished derive_param_bmi pass=&gs_pass fail=&gs_fail policy=&gs_policy;

%let gs_pass = 0;
%let gs_fail = 0;
%let gs_policy = 0;
%put NOTE: Starting derive_param_bsa;
%include "&PFDIR/TestThat/gs_derive_param_bsa.sas";
%gs_add;
%put NOTE: Finished derive_param_bsa pass=&gs_pass fail=&gs_fail policy=&gs_policy;

%let gs_pass = 0;
%let gs_fail = 0;
%let gs_policy = 0;
%put NOTE: Starting derive_param_map;
%include "&PFDIR/TestThat/gs_derive_param_map.sas";
%gs_add;
%put NOTE: Finished derive_param_map pass=&gs_pass fail=&gs_fail policy=&gs_policy;

%let gs_pass = 0;
%let gs_fail = 0;
%let gs_policy = 0;
%put NOTE: Starting derive_param_wbc_abs;
%include "&PFDIR/TestThat/gs_derive_param_wbc_abs.sas";
%gs_add;
%put NOTE: Finished derive_param_wbc_abs pass=&gs_pass fail=&gs_fail policy=&gs_policy;

%let gs_pass = 0;
%let gs_fail = 0;
%let gs_policy = 0;
options errorcheck=normal nosyntaxcheck obs=max;
%put NOTE: Starting derive_param_rr;
%include "&PFDIR/TestThat/gs_derive_param_rr.sas";
%gs_add;
%put NOTE: Finished derive_param_rr pass=&gs_pass fail=&gs_fail policy=&gs_policy;

%let gs_pass = 0;
%let gs_fail = 0;
%let gs_policy = 0;
options errorcheck=normal nosyntaxcheck obs=max;
%put NOTE: Starting derive_param_qtc;
%include "&PFDIR/TestThat/gs_derive_param_qtc.sas";
%gs_add;
%put NOTE: Finished derive_param_qtc pass=&gs_pass fail=&gs_fail policy=&gs_policy;


libname gsval "&PFDIR/validation";

%gs_save(bmi_const);
%gs_save(bmi_case);
%gs_save(bmi_visit);
%gs_save(bmi_miss);
%gs_save(bmi_lb);
%gs_save(bmi_blank);
%gs_save(bmi_dup);
%gs_save(bsa_const);
%gs_save(bsa_visit);
%gs_save(bsa_lb);
%gs_save(bsa_blank);
%gs_save(map_tpt);
%gs_save(map_space);
%gs_save(map_bpm);
%gs_save(wbc_frac);
%gs_save(wbc_bad);
%gs_save(wbc_pct);
%gs_save(wbc_pct_ok);
%gs_save(rr_in);
%gs_save(rr_bpm);
%gs_save(rr_blank);
%gs_save(qtc_baz);
%gs_save(qtc_fri);
%gs_save(qtc_sag);
%gs_save(qtc_sec);

libname gsval clear;


options nosyntaxcheck obs=max notes source;

%if %sysfunc(exist(work.gs_result)) = 0 %then %do;
    data work.gs_result;
         length suite $32
                test_id $16
                result $8
                obtained $80
                expected $80;
         stop;
    run;
%end;

data work.gs_result;
     set work.gs_result;
     seq = _n_;
run;

data work.gs_desc;
     length test_id $16
            description $200;
     test_id = 'GS-BMI-01';  description = 'Subject-level height is reused. WEEK2 BMI from 80 kg and 200 cm is 20.'; output;
     test_id = 'GS-BMI-02';  description = 'The same subject-level height is reused at WEEK4. BMI is 20.'; output;
     test_id = 'GS-BMI-03';  description = 'The carried SEX value on the WEEK2 BMI row is F.'; output;
     test_id = 'GS-BMI-04';  description = 'Units KG and CM match kg and cm. BMI is 20.'; output;
     test_id = 'GS-BMI-04U'; description = 'The unit check stays clear when the units are kg and cm.'; output;
     test_id = 'GS-BMI-05';  description = 'Height is visit-level. WEEK2 has both tests, so BMI is 20.'; output;
     test_id = 'GS-BMI-05N'; description = 'WEEK4 has weight and no height, so only one BMI row is added.'; output;
     test_id = 'GS-BMI-05M'; description = 'A missing weight does not produce a BMI row.'; output;
     test_id = 'GS-BMI-06';  description = 'Weight in lb is not kg, so the macro stops and writes no output.'; output;
     test_id = 'GS-BMI-07';  description = 'The unit-failure flag is set when weight is in lb.'; output;
     test_id = 'GS-BMI-08';  description = 'A blank height unit stops the macro and writes no output.'; output;
     test_id = 'GS-BMI-09';  description = 'Two weight rows at the same key stop the macro and write no output.'; output;
     test_id = 'GS-BMI-10';  description = 'height_constant other than Y or N stops the macro and writes no output.'; output;
     test_id = 'GS-BSA-01';  description = 'Mosteller BSA from 180 cm and 80 kg is 2 at WEEK2.'; output;
     test_id = 'GS-BSA-02';  description = 'The same subject-level height is reused at WEEK4. BSA is 2.'; output;
     test_id = 'GS-BSA-03';  description = 'Height is visit-level. WEEK2 BSA from 120 cm and 30 kg is 1.'; output;
     test_id = 'GS-BSA-03N'; description = 'WEEK4 has weight and no height, so only one BSA row is added.'; output;
     test_id = 'GS-BSA-04';  description = 'Weight in lb is not kg, so the macro stops and writes no output.'; output;
     test_id = 'GS-BSA-04U'; description = 'The unit-failure flag is set when weight is in lb.'; output;
     test_id = 'GS-BSA-05';  description = 'A blank height unit stops the macro and writes no output.'; output;
     test_id = 'GS-MAP-01';  description = 'Standing MAP from 120 and 60 mmHg is 80. The two time points stay apart.'; output;
     test_id = 'GS-MAP-02';  description = 'Supine MAP from 90 and 90 mmHg is 90.'; output;
     test_id = 'GS-MAP-03';  description = 'Standing MAP uses the unrounded heart-rate formula. A trailing precision difference is policy.'; output;
     test_id = 'GS-MAP-04';  description = 'Supine has no heart rate, so that formula adds no supine MAP row.'; output;
     test_id = 'GS-MAP-05';  description = 'Unit mm Hg is not mmHg, so the macro stops and writes no output.'; output;
     test_id = 'GS-MAP-05U'; description = 'The unit-failure flag is set when systolic pressure is mm Hg.'; output;
     test_id = 'GS-MAP-06';  description = 'Heart rate in bpm is not beats/min, so the macro stops and writes no output.'; output;
     test_id = 'GS-WBC-01';  description = 'Fraction 0.25 times WBC 7.2 gives absolute lymphocytes 1.8.'; output;
     test_id = 'GS-WBC-02';  description = 'S2 already has LYMPH, so no second absolute row is added.'; output;
     test_id = 'GS-WBC-03';  description = 'The original S2 LYMPH row with result 9 is kept.'; output;
     test_id = 'GS-WBC-04';  description = 'WBC unit 10^3/uL is not 10^9/L, so the macro stops and writes no output.'; output;
     test_id = 'GS-WBC-04U'; description = 'The unit-failure flag is set when WBC is 10^3/uL.'; output;
     test_id = 'GS-WBC-05';  description = 'A percent differential stored as 1 stops the macro and writes no output.'; output;
     test_id = 'GS-WBC-06';  description = '40 percent of WBC 6.5 gives absolute lymphocytes 2.6.'; output;
     test_id = 'GS-RR-01';   description = 'WEEK2 T1 heart rate 60 gives RR 1000.'; output;
     test_id = 'GS-RR-02';   description = 'T2 heart rate 75 gives RR 800.'; output;
     test_id = 'GS-RR-03';   description = 'A missing heart rate at WEEK4 adds no RR row.'; output;
     test_id = 'GS-RR-03P';  description = 'The derived parameter code is RR.'; output;
     test_id = 'GS-RR-04';   description = 'Heart rate in bpm is not beats/min, so the macro stops and writes no output.'; output;
     test_id = 'GS-RR-04U';  description = 'The unit-failure flag is set when heart rate is bpm.'; output;
     test_id = 'GS-RR-05';   description = 'A blank heart-rate unit stops the macro and writes no output.'; output;
     test_id = 'GS-QTC-01';  description = 'Bazett from QT 400 and RR 250 msec is 800 for S1.'; output;
     test_id = 'GS-QTC-02';  description = 'The same Bazett inputs in ms rather than msec are 800 for S2.'; output;
     test_id = 'GS-QTC-03';  description = 'A missing QT for S3 adds no Bazett row.'; output;
     test_id = 'GS-QTC-04';  description = 'Fridericia from QT 400 and RR 1000 is 400.'; output;
     test_id = 'GS-QTC-04S'; description = 'Sagie from QT 350 and RR 500 is 427.'; output;
     test_id = 'GS-QTC-05';  description = 'QT in sec is not ms or msec, so the macro stops and writes no output.'; output;
     test_id = 'GS-QTC-05U'; description = 'The unit-failure flag is set when QT is in sec.'; output;
     test_id = 'GS-QTC-06';  description = 'Method Hodges is not accepted, so the macro stops and writes no output.'; output;
run;

proc sort data=work.gs_result
          out=work._gs_sum;
     by suite;
run;

data work.gs_summary;
     set work._gs_sum;
     by suite;
     length pass 8
            fail 8
            policy 8
            n 8;
     retain pass fail policy n;
     if first.suite then do;
          pass = 0;
          fail = 0;
          policy = 0;
          n = 0;
     end;
     n + 1;
     if strip(result) = 'PASS' then pass + 1;
     else if strip(result) = 'FAIL' then fail + 1;
     else if strip(result) = 'POLICY' then policy + 1;
     if last.suite then output;
     keep suite pass fail policy n;
run;

proc sort data=work.gs_desc;
     by test_id;
run;

proc sort data=work.gs_result
          out=work._gs_det;
     by test_id;
run;

data work.gs_detail;
     merge work._gs_det (in=in_res)
           work.gs_desc;
     by test_id;
     if in_res;
     length check_id $16;
     check_id = substr(test_id, 4);
     if missing(description) then description = ' ';
     keep seq check_id description obtained expected result;
run;

proc sort data=work.gs_detail;
     by seq;
run;

%if %sysfunc(fileexist(&PFDIR/output)) = 0 %then %do;
    %let _gs_dir = %sysfunc(dcreate(output, &PFDIR/));
%end;

%let gs_npass = 0;
%let gs_nfail = 0;
%let gs_npolicy = 0;
%let gs_ntotal = 0;

options errorcheck=normal nosyntaxcheck obs=max replace;

data work.gs_overall;
     set work.gs_summary end=_last;
     length parameter $8;
     retain _pass _fail _policy _n 0;
     parameter = upcase(substr(suite, 14));
     if parameter = 'WBC_ABS' then parameter = 'WBC';
     else if parameter = 'QTC' then parameter = 'QTc';
     _pass + pass;
     _fail + fail;
     _policy + policy;
     _n + n;
     if _last then do;
          call symputx('gs_npass', _pass, 'G');
          call symputx('gs_nfail', _fail, 'G');
          call symputx('gs_npolicy', _policy, 'G');
          call symputx('gs_ntotal', _n, 'G');
     end;
     keep parameter pass fail policy n;
run;

%put NOTE: Writing golden subject tables to &PFDIR/output;

options errorcheck=normal nosyntaxcheck obs=max replace notes;

libname gsout "&PFDIR/output";

data gsout.gs_overall;
     set work.gs_overall;
run;

data gsout.gs_summary;
     set work.gs_summary;
run;

data gsout.gs_detail;
     set work.gs_detail;
run;

%put NOTE: gs_overall exists=%sysfunc(exist(gsout.gs_overall));
%put NOTE: gs_summary exists=%sysfunc(exist(gsout.gs_summary));
%put NOTE: gs_detail exists=%sysfunc(exist(gsout.gs_detail));

libname gsout clear;

data _null_;
     set work.gs_overall;
     file "&PFDIR/output/gs_write_marker.txt";
     if _n_ = 1 then put "Parameter" @16 "PASS" @24 "FAIL" @32 "POLICY" @42 "Tests";
     put parameter @16 pass @24 fail @32 policy @42 n;
run;

data _null_;
     set work.gs_detail;
     file "&PFDIR/output/gs_listing.txt";
     if _n_ = 1 then put "Test" @12 "Result" @22 "Obtained" @42 "Correct" @62 "Edge case";
     put check_id @12 result @22 obtained @42 expected @62 description;
run;

proc print data=work.gs_overall noobs label;
     title "PharmaForest edge-case summary";
     var parameter pass fail policy n;
     label parameter = 'Derived parameter'
           pass = 'PASS'
           fail = 'FAIL'
           policy = 'POLICY'
           n = 'Tests';
run;
title;

proc print data=work.gs_detail noobs label;
     title "PharmaForest edge-case listing";
     var check_id description obtained expected result;
     label check_id = 'Test'
           description = 'Edge case'
           obtained = 'Obtained'
           expected = 'Correct'
           result = 'Result';
run;
title;

%put NOTE: ===== PharmaForest edge cases: &gs_npass passed, &gs_nfail failed, &gs_npolicy policy =====;
%put NOTE: Edge-case listing is &PFDIR/output/gs_detail.sas7bdat;
%put NOTE: Edge-case text listing is &PFDIR/output/gs_listing.txt;
%put NOTE: gs_derive_param_all end pass=&gs_npass fail=&gs_nfail policy=&gs_npolicy total=&gs_ntotal;
