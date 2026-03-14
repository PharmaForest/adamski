/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_vars_cat() macro in case without by_vars

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data advs;
  length USUBJID $12 VSTEST $10;
  infile datalines truncover;
  input USUBJID $ VSTEST $ AVAL;
datalines;
01-701-1015 Height 147.32
01-701-1015 Weight 53.98
01-701-1023 Height 162.56
01-701-1023 Weight .
01-701-1028 Height .
01-701-1028 Weight .
01-701-1033 Height 175.26
01-701-1033 Weight 88.45
;
run;

/*expected output*/
data advs_exp;
  length USUBJID $12 VSTEST $10 AVALCAT1 $20;
  infile datalines truncover;
  input USUBJID $ VSTEST $ AVAL AVALCAT1 $ AVALCA1N;
datalines;
01-701-1015 Height 147.32 <=160_cm 2
01-701-1015 Weight 53.98 . .
01-701-1023 Height 162.56 >160_cm 1
01-701-1023 Weight . . .
01-701-1028 Height . . .
01-701-1028 Weight . . .
01-701-1033 Height 175.26 >160_cm 1
01-701-1033 Weight 88.45 . .
;
run;

/*output by the macro*/
data definition;
  length CONDITION $200 AVALCAT1 $20;
  infile datalines dlm='|' truncover;
  input CONDITION $ AVALCAT1 $ AVALCA1N;
datalines;
VSTEST="Height" and AVAL>160|>160_cm|1
VSTEST="Height" and aval ne . and AVAL<=160|<=160_cm|2
;
run;

%derive_vars_cat(
  dataset=advs,
  definition=definition,
  outdata=advs_test
);


/*Compare*/
%mp_assertdataset(
  base			= advs_exp,					/* parameter in proc compare */
  compare	= advs_test,					/* parameter in proc compare */
  desc		= (%nrstr(%derive_vars_cat))[test01] Compare expected and test results in case without by_vars, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion	= 0,       		/* parameter in proc compare */
  method		= absolute,    /* parameter in proc compare */
  outds		= TEMP.adamski_test
);
