/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_vars_duration() macro  
- Case of trunc_out=Y  

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data test1;
  input USUBJID $ BRTHDT :yymmdd10. RANDDT :yymmdd10.;
  format BRTHDT RANDDT yymmdd10.;
  datalines;
  P01 1984-09-06 2020-02-24
  P02 1985-01-01 .
  P03 . 2021-03-10
  P04 . .
  P05 1971-10-10 2025-10-30
  ;
run;

/*expected output*/
data test1_exp;
  input USUBJID $ BRTHDT :yymmdd10. RANDDT :yymmdd10. AAGE AAGEU $15. ;
  format BRTHDT RANDDT yymmdd10.;
  datalines;
  P01 1984-09-06 2020-02-24 35 YEARS
  P02 1985-01-01 . . 
  P03 . 2021-03-10 . 
  P04 . . . 
  P05 1971-10-10 2025-10-30 54 YEARS
  ;
run;

/*output by the macro*/
data test1_op;
set test1;

	%derive_vars_duration(
	  new_var=AAGE,
	  new_var_unit=AAGEU,
	  start_date=BRTHDT,
	  end_date=RANDDT,
	  out_unit=years,
	  add_one=N,
	  trunc_out=Y
	);

run;

/*Compare*/
%mp_assertdataset(
  base			= test1_exp,					/* parameter in proc compare */
  compare	= test1_op,					/* parameter in proc compare */
  desc		= (%nrstr(%derive_vars_duration))[test01] Compare expected and test results for case of trunc_out=Y, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion	= 0,       		/* parameter in proc compare */
  method		= absolute,    /* parameter in proc compare */
  outds		= TEMP.adamski_test
);
