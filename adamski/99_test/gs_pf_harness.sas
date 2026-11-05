/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : gs_pf_harness.sas
  SAS Version                 : 9.4
  Purpose (short description) : Shared checks for PharmaForest golden-subject scripts
  Author                      : Cursor
  Date                        : 31OCT2026
  Input Datasets or Metadata  : Work datasets built by each golden-subject script
  Modification Log            :

  Include this after the macros under test.
  Each script sets gs_pass, gs_fail, and gs_policy to 0 before the first check.
  A passing run can still print WARNING lines from the macros under test.
  Those lines are expected for the unit-failure cases named in each script.
  The messages do not begin with ERROR, so SAS does not stop later steps.
  A check result is PASS, FAIL, or POLICY.
  POLICY is an accepted difference, such as trailing precision on an
  unrounded and unformatted AVAL. It is not a failure.
  WARNING: [GOLDEN FAIL] is the line that means a check failed.
  %gs_done writes that script's rows to &PFDIR/output as soon as it finishes.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%macro gs_record(id, result, obtained, expected);
  data work._gs_one;
       length suite $32
              test_id $16
              result $8
              obtained $80
              expected $80;
       suite = symget('gs_suite');
       test_id = symget('id');
       result = symget('result');
       obtained = symget('obtained');
       expected = symget('expected');
  run;

  proc append base=work.gs_result
              data=work._gs_one force;
  run;
%mend gs_record;


%macro gs_pass(id, obtained, expected);
  %put NOTE: [GOLDEN PASS] &id obtained=&obtained expected=&expected;
  %let gs_pass = %eval(&gs_pass + 1);
  %gs_record(&id, PASS, %superq(obtained), %superq(expected));
%mend gs_pass;


%macro gs_fail(id, obtained, expected);
  %put WARNING: [GOLDEN FAIL] &id obtained=&obtained expected=&expected;
  %let gs_fail = %eval(&gs_fail + 1);
  %gs_record(&id, FAIL, %superq(obtained), %superq(expected));
%mend gs_fail;


%macro gs_policy(id, obtained, expected);
  %if %symexist(gs_policy) = 0 %then %let gs_policy = 0;
  %put WARNING: [GOLDEN POLICY] &id obtained=&obtained expected=&expected;
  %let gs_policy = %eval(&gs_policy + 1);
  %gs_record(&id, POLICY, %superq(obtained), %superq(expected));
%mend gs_policy;


%macro gs_drop(data);
  %local _mem;

  %if %sysfunc(exist(&data)) %then %do;
      %let _mem = %scan(&data, 2, .);
      proc datasets lib=work nolist;
           delete &_mem;
      quit;
  %end;
%mend gs_drop;


%macro gs_no_ds(id, data);
  %if %sysfunc(exist(&data)) %then %do;
      %gs_fail(&id, %str(created), %str(not created));
  %end;
  %else %do;
      %gs_pass(&id, %str(not created), %str(not created));
  %end;
%mend gs_no_ds;


%macro gs_unit(id, expect);
  %if &cmp2_unit_fail = &expect %then %do;
      %gs_pass(&id, &cmp2_unit_fail, &expect);
  %end;
  %else %do;
      %gs_fail(&id, &cmp2_unit_fail, &expect);
  %end;
%mend gs_unit;


%macro gs_n(id, data, wh, n);
  %local _n;

  %if %sysfunc(exist(&data)) = 0 %then %do;
      %gs_fail(&id, %str(not created), &n);
      %return;
  %end;

  %let _n = 0;

  proc sql noprint;
       reset exec;
       select count(*)
       into :_n
       from &data
       where &wh;
  quit;

  %let _n = %sysfunc(strip(&_n));

  %if %sysevalf(&_n = &n, boolean) %then %do;
      %gs_pass(&id, &_n, &n);
  %end;
  %else %do;
      %gs_fail(&id, &_n, &n);
  %end;
%mend gs_n;


%macro gs_aval(id, data, wh, expect);
  %local _n
         _got;

  %if %sysfunc(exist(&data)) = 0 %then %do;
      %gs_fail(&id, %str(not created), &expect);
      %return;
  %end;

  %let _n   = 0;
  %let _got = .;

  proc sql noprint;
       reset exec;
       select count(*),
              max(aval)
       into :_n,
            :_got
       from &data
       where &wh;
  quit;

  %let _n = %sysfunc(strip(&_n));
  %let _got = %sysfunc(strip(&_got));

  /* AVAL is stored unrounded. A gap that remains only past five decimals is policy. */
  %if %sysevalf(&_n = 1, boolean) = 0 %then %do;
      %gs_fail(&id, &_n, %str(1));
  %end;
  %else %if %sysevalf(%sysfunc(abs(&_got - (&expect))) <= 1e-6, boolean) %then %do;
      %gs_pass(&id, &_got, &expect);
  %end;
  %else %if %sysevalf(%sysfunc(round(&_got, 1e-5)) = %sysfunc(round(&expect, 1e-5)), boolean) %then %do;
      %gs_policy(&id, &_got, &expect);
  %end;
  %else %do;
      %gs_fail(&id, &_got, &expect);
  %end;
%mend gs_aval;


%macro gs_char(id, data, wh, var, expect);
  %local _n
         _got;

  %if %sysfunc(exist(&data)) = 0 %then %do;
      %gs_fail(&id, %str(not created), &expect);
      %return;
  %end;

  %let _n   = 0;
  %let _got = ;

  proc sql noprint;
       reset exec;
       select count(*),
              max(&var)
       into :_n,
            :_got
       from &data
       where &wh;
  quit;

  %let _got = %sysfunc(strip(&_got));

  %if %sysevalf(&_n = 1, boolean) = 0 %then %do;
      %gs_fail(&id, &_n, %str(1));
  %end;
  %else %if "&_got" ne "&expect" %then %do;
      %gs_fail(&id, &_got, &expect);
  %end;
  %else %do;
      %gs_pass(&id, &_got, &expect);
  %end;
%mend gs_char;


%macro gs_write(name);
  %local _mem;

  %if %symexist(PFDIR) = 0 %then %do;
      %let PFDIR = %sysfunc(strip(%sysget(HOME)))/Adamski/SAS;
  %end;
  %if %sysfunc(fileexist(&PFDIR/output)) = 0 %then %do;
      %let _gs_dir = %sysfunc(dcreate(output, &PFDIR/));
  %end;

  %let _mem = gs_%substr(&name, %eval(%length(derive_param_) + 1));

  options errorcheck=normal nosyntaxcheck obs=max replace;

  %if %sysfunc(exist(work.gs_result)) = 0 %then %do;
      %put NOTE: [GOLDEN FILE] &name did not record any rows.;
      %return;
  %end;

  libname gsout "&PFDIR/output";

  data gsout.&_mem;
       set work.gs_result;
       where suite = "&name";
  run;

  %put NOTE: [GOLDEN FILE] &PFDIR/output/&_mem..sas7bdat exists=%sysfunc(exist(gsout.&_mem));

  data _null_;
       set gsout.&_mem;
       file "&PFDIR/output/&_mem..txt";
       if _n_ = 1 then put "Test" @20 "Result" @30 "Obtained" @50 "Correct";
       put test_id @20 result @30 obtained @50 expected;
  run;

  libname gsout clear;
%mend gs_write;


%macro gs_done(name);
  %if %symexist(gs_policy) = 0 %then %let gs_policy = 0;
  %if &gs_fail = 0 %then %do;
      %put NOTE: [GOLDEN SUMMARY] &name PASS=&gs_pass FAIL=0 POLICY=&gs_policy;
  %end;
  %else %do;
      %put WARNING: [GOLDEN SUMMARY] &name PASS=&gs_pass FAIL=&gs_fail POLICY=&gs_policy;
  %end;
  %gs_write(&name);
%mend gs_done;


%if %symexist(gs_keep_result) = 0 %then %do;
    %let gs_keep_result = 0;
%end;

%if &gs_keep_result = 0 and %sysfunc(exist(work.gs_result)) %then %do;
    proc datasets lib=work nolist;
         delete gs_result;
    quit;
%end;
