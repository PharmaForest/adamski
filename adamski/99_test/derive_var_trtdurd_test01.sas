/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_var_trtdurd() macro  

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data duration;
    length usubjid $10;
    usubjid = '01-001';
    trtsdt = '02JAN2014'd;
    trtedt = '02JUL2014'd;
    output;
    usubjid = '01-002';
    trtsdt = '05AUG2012'd;
    trtedt = '01SEP2012'd;
    output;
    format trtsdt trtedt date9.;
run;

/*expected output*/
data duration_exp;
    length usubjid $10;
    usubjid = '01-001';
    trtsdt = '02JAN2014'd;
    trtedt = '02JUL2014'd;
    trtdurd = 182;
    output;
    usubjid = '01-002';
    trtsdt = '05AUG2012'd;
    trtedt = '01SEP2012'd;
    trtdurd = 28;
    output;
    format trtsdt trtedt date9.;
run;

%derive_var_trtdurd(duration);

/*Compare*/
%mp_assertdataset(
  base		= duration_exp,					/* parameter in proc compare */
  compare	= duration,					/* parameter in proc compare */
  desc		= (%nrstr(%derive_var_trtdurd))[test01] Compare expected and test results, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion	= 1e-8,       		/* parameter in proc compare */
  method		= absolute,    /* parameter in proc compare */
  outds		= TEMP.adamski_test
);
