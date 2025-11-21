/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_vars_duration() macro  
- Case of datetime data with floor_in=Y   

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data test2;
  length USUBJID $3;
  format ASTDTM LDOSEDTM datetime20.;

  input USUBJID $ ASTDTM :anydtdtm. LDOSEDTM :anydtdtm.;
  datalines;
P01 2019-08-09T04:30:56 2019-08-08T10:05:00
P02 2019-11-11T23:59:59 2019-10-11T11:37:00
P03 2019-11-11T00:00:00 2019-11-10T23:59:59
P04 2019-11-11T12:34:56 .
P05 . 2019-09-28T12:34:56
;
run;

/*expected output*/
data test2_exp;
  length USUBJID $3;
  format ASTDTM LDOSEDTM datetime20.;

  input USUBJID $ ASTDTM :anydtdtm. LDOSEDTM :anydtdtm. LDRELTM LDRELTMU $15.;
  datalines;
P01 2019-08-09T04:30:56 2019-08-08T10:05:00 24 HOURS
P02 2019-11-11T23:59:59 2019-10-11T11:37:00 744 HOURS
P03 2019-11-11T00:00:00 2019-11-10T23:59:59 24 HOURS
P04 2019-11-11T12:34:56 . . 
P05 . 2019-09-28T12:34:56 . . 
;
run;

/*output by the macro*/
data test2_op;
set test2;

	%derive_vars_duration(
	  new_var = LDRELTM,
	  new_var_unit = LDRELTMU,
	  start_date = LDOSEDTM,
	  end_date = ASTDTM,
	  out_unit = hours,
	  floor_in=Y,
	  add_one = N,
	  trunc_out=N,
	  type = duration
	);
run;	

/*Compare*/
%mp_assertdataset(
  base			= test2_exp,					/* parameter in proc compare */
  compare	= test2_op,					/* parameter in proc compare */
  desc		= (%nrstr(%derive_vars_duration))[test02] Compare expected and test results for case of datetime data with floor_in=Y, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion	= 0,       		/* parameter in proc compare */
  method		= absolute,    /* parameter in proc compare */
  outds		= TEMP.adamski_test
);
