/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_vars_duration() macro  
- Case of type=interval  

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data test4;
  length USUBJID $3;
  format ASTDTM LDOSEDTM datetime20.;

  input USUBJID $ ASTDTM :anydtdtm. LDOSEDTM :anydtdtm.;
  datalines;
P01 2019-08-09T04:30:56 2019-08-08T10:05:00
P02 2019-11-11T23:59:59 2019-10-11T11:37:00
P03 2019-11-11T00:00:00 2019-11-10T23:59:59
P04 2019-11-11T12:34:56 .
P05 . 2019-09-28T12:34:56
P06 2000-03-01T23:59:59 2000-02-01T00:00:00 
;
run;

/*expected output*/
data test4_exp;
  length USUBJID $3;
  format ASTDTM LDOSEDTM datetime20.;

  input USUBJID $ ASTDTM :anydtdtm. LDOSEDTM :anydtdtm. LDRELTM LDRELTMU $15.;
  datalines;
P01 2019-08-09T04:30:56 2019-08-08T10:05:00 0 MONTHS
P02 2019-11-11T23:59:59 2019-10-11T11:37:00 1 MONTHS
P03 2019-11-11T00:00:00 2019-11-10T23:59:59 0 MONTHS
P04 2019-11-11T12:34:56 . .
P05 . 2019-09-28T12:34:56 .
P06 2000-03-01T23:59:59 2000-02-01T00:00:00 1 MONTHS
;
run;

/*output by the macro*/
data test4_op;
set test4;

	%derive_vars_duration(
	  new_var = LDRELTM,
	  new_var_unit = LDRELTMU,
	  start_date = LDOSEDTM,
	  end_date = ASTDTM,
	  in_unit = hours,
	  out_unit = months,
	  floor_in=Y,
	  add_one = N,
	  trunc_out=N,
	  type=interval
	);
run;

/*Compare*/
%mp_assertdataset(
  base			= test4_exp,					/* parameter in proc compare */
  compare	= test4_op,					/* parameter in proc compare */
  desc		= (%nrstr(%derive_vars_duration))[test04] Compare expected and test results for case of type=interval, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion	= 0,       		/* parameter in proc compare */
  method		= absolute,    /* parameter in proc compare */
  outds		= TEMP.adamski_test
);
