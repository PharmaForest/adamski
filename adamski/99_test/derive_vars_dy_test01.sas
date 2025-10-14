/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_vars_dy() macro

### Expected result:  
- ICDY, TRTSDY, TRTEDY variables are created with TRTEDY overwritten

*//*** HELP END ***/

/*Compare macro*/
%macro mp_assertdataset(
  base=,					/* parameter in proc compare */
  compare=,				/* parameter in proc compare */
  desc=,					/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion=0,       		/* parameter in proc compare */
  method=absolute,    /* parameter in proc compare */
  outds=work.test_results /* output dataset */
);

  %local _ne _equal test_result;

  proc compare base=&base. compare=&compare.
    out=_out outnoequal
    criterion=&criterion. method=&method.
    noprint;
  %if %length(&by.) %then %do; by &by.; %end;
  %if %length(&id.) %then %do; id &id.; %end;
  run;

  data _null_;
    if 0 then set _out nobs=n;
    call symputx('_ne', n, 'L');
  run;

  %let _equal = %sysfunc(ifc(&_ne=0, 1, 0));

  %if &_equal %then %do;
    %put NOTE: MP_ASSERTDATASET: PASS (no differences). NE=&_ne;
    %let test_result=PASS;
  %end;
  %else %do;
    %put ERROR: MP_ASSERTDATASET: FAIL (differences found). NE=&_ne;
    %let test_result=FAIL;
  %end;

  %if %length(&outds.) %then %do;

    %if not %sysfunc(exist(&outds.)) %then %do;
      data &outds.;
        length test_description $256 test_result $4 test_comments $256;
        stop;
      run;
    %end;

    data _assert_row;
      length test_description $256 test_result $4 test_comments $256;
      test_description = coalescec(symget('desc'),'');
      test_result      = symget('test_result');
      test_comments = catx(" ", "MP_ASSERTDATASET: proc compare",
			cats("base=", symget('base')),
			cats("compare=", symget('compare'))
		);
    run;

    proc append base=&outds. data=_assert_row force; run;
    proc datasets lib=work nolist; delete _assert_row; quit;
  %end;
%mend ;

/*Expected result dataset*/
data _adsl_expected;
  length USUBJID $10.;
  format RANDDT ICDT TRTSDT TRTEDT date9.;
  input USUBJID $ RANDDT :date9. ICDT :date9. TRTSDT :date9. TRTEDT :date9. TRTEDY ICDY TRTSDY ; 
  datalines;
	SUBJ001 01JAN2024 31DEC2023 01JAN2024 02JAN2024 2 -1 1
	SUBJ002 03JAN2024 03DEC2023 02FEB2024 . . -31 31 
  ;
run;

/*Test dataset*/
data _adsl_test;
  length USUBJID $10.;
  format RANDDT ICDT TRTSDT TRTEDT date9.;
  input USUBJID $ RANDDT :date9. ICDT :date9. TRTSDT :date9. TRTEDT :date9. TRTEDY ; /*TRTEDY to be overwritten*/
  datalines;
	SUBJ001 01JAN2024 31DEC2023 01JAN2024 02JAN2024 1
	SUBJ002 03JAN2024 03DEC2023 02FEB2024 . 2
  ;
run;

data _adsl_test;
	set _adsl_test ;
	%derive_vars_dy(
	reference_date=RANDDT,
	source_vars=ICDT TRTSDT TRTEDT)
run ;

/*Compare*/
%mp_assertdataset(
  base=_adsl_expected,					/* parameter in proc compare */
  compare=_adsl_test,				/* parameter in proc compare */
  desc=Compare expected and test results, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion=0,       		/* parameter in proc compare */
  method=absolute    /* parameter in proc compare */
);

/*delete temporary datasets*/
proc datasets ;
	delete _adsl_expected _adsl_test _out ;
run ; quit ;
