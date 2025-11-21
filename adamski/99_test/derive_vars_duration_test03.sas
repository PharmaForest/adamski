/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_vars_duration() macro  
- Case of datetime data with floor_in=N   

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data test3;
  length USUBJID $3;
  format ASTDTM LDOSEDTM E8601DT.;

  input USUBJID $ ASTDTM :anydtdtm. LDOSEDTM :anydtdtm.;
  datalines;
P01 2019-08-09T04:30:56 2019-08-08T10:05:00
P02 2019-11-11T23:59:59 2019-10-11T11:37:00
P03 2019-11-11T00:00:00 2019-11-10T23:59:59
P04 2019-11-11T12:34:56 .
P05 . 2019-09-28T12:34:56
P06 2025-09-28T12:34:56 2025-09-28T12:34:56
;
run;
/*expected output*/
data test3_exp;
  length USUBJID $3;
  format ASTDTM LDOSEDTM E8601DT.;

  input USUBJID $ ASTDTM :anydtdtm. LDOSEDTM :anydtdtm. LDRELTM LDRELTMU $15.;
  datalines;
P01 2019-08-09T04:30:56 2019-08-08T10:05:00 18.4322222221526 HOURS
P02 2019-11-11T23:59:59 2019-10-11T11:37:00 756.383055555605 HOURS
P03 2019-11-11T00:00:00 2019-11-10T23:59:59 0.0002777777554 HOURS
P04 2019-11-11T12:34:56 . .
P05 . 2019-09-28T12:34:56 .
P06 2025-09-28T12:34:56 2025-09-28T12:34:56 0 HOURS
;
run;

/*output by the macro*/
data test3_op;
set test3;

	%derive_vars_duration(
	  new_var = LDRELTM,
	  new_var_unit = LDRELTMU,
	  start_date = LDOSEDTM,
	  end_date = ASTDTM,
	  out_unit = hours,
	  add_one = N,
	  floor_in=N
	);

run;

/*Compare*/
%mp_assertdataset(
  base			= test3_exp,					/* parameter in proc compare */
  compare	= test3_op,					/* parameter in proc compare */
  desc		= (%nrstr(%derive_vars_duration))[test03] Compare expected and test results for case of datetime data with floor_in=N, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion	= 1e-8,       		/* parameter in proc compare */
  method		= absolute,    /* parameter in proc compare */
  outds		= TEMP.adamski_test
);
