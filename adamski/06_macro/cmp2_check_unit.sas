/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : cmp2_check_unit.sas
  SAS Version                 : 9.4
  Purpose (short description) : Unit check used by the computed parameter wrappers
  Author                      : Cursor edited by P. Robertson
  Date                        : 30OCT2026
  Input Datasets or Metadata  : One findings dataset, one row per test
  Modification Log            : 30OCT2026 - Split out of the combined wrapper file.

  %cmp2_check_unit

  Looks at rows for one test where the result is not missing.
  expected= is one unit, or several units separated by spaces.
  Comparison is not case sensitive. Kg matches kg.

  A blank unit or any other unit sets the global flag cmp2_unit_fail to 1
  and writes a warning. The message does not begin with ERROR, so SAS
  does not enter syntax-check mode and later steps still run.
  No rows for that test is not a failure.
  The calling wrapper stops and does not create its output dataset.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%macro cmp2_check_unit(
     dataset =
,   test_var = VSTESTCD
, result_var = VSSTRESN
,   unit_var = VSSTRESU
,       test =
,   expected =
);

  %global cmp2_unit_fail;

  %local _bad
         _test;

  /* expected= may be    unit or several separated by spaces, such as msec ms. */
  %let _bad  = 0;
  %let _test = %upcase(%superq(test));

  data work._cmp2_units;
       set &dataset;
       where upcase(strip(&test_var)) = "&_test"
             and not missing(&result_var);
       length unit $40;
       unit = upcase(strip(&unit_var));
       keep unit;
  run;

  proc sort data=work._cmp2_units nodupkey;
       by unit;
  run;

  data _null_;
       set work._cmp2_units;
       length _expect $200
              _list   $200
              _word   $40;
       _expect = upcase(strip(symget('expected')));
       /* PCT stands for the percent sign. The sign is not put in macro text. */
       if _expect = 'PCT' then _expect = byte(37);
       _list = tranwrd(_expect, ' ', '|');
       _ok = 0;
       if unit = _expect then _ok = 1;
       do _k = 1 to countw(_list, '|');
          _word = scan(_list, _k, '|');
          if unit = _word then _ok = 1;
       end;
       if missing(unit) or _ok = 0 then do;
          put "WARNING: &_test has unit " unit "and the required unit is " _expect;
          call symputx('_bad', '1', 'F');
       end;
  run;

  %if &_bad = 1 %then %let cmp2_unit_fail = 1;

  proc datasets lib=work nolist;
       delete _cmp2_units;
  quit;

%mend cmp2_check_unit;
