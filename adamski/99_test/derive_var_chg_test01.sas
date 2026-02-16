/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_var_chg() macro  

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data advs;
  length USUBJID $3 PARAMCD $6 ABLFL $1;
  input USUBJID $ PARAMCD $ AVAL ABLFL $ BASE;
datalines;
P01 WEIGHT 80.0  Y  80.0
P01 WEIGHT 80.8  .  80.0
P01 WEIGHT 81.4  .  80.0
P02 WEIGHT 75.3  Y  75.3
P02 WEIGHT 76.0  .  75.3
;
run;

/*expected output*/
data advs_exp;
  length USUBJID $3 PARAMCD $6 ABLFL $1;
  input USUBJID $ PARAMCD $ AVAL ABLFL $ BASE CHG;
datalines;
P01 WEIGHT 80.0  Y  80.0 0
P01 WEIGHT 80.8  .  80.0 0.8
P01 WEIGHT 81.4  .  80.0 1.4
P02 WEIGHT 75.3  Y  75.3 0
P02 WEIGHT 76.0  .  75.3 0.7
;
run;

/*output by the macro*/
data advs_out;
  set advs;
  %derive_var_chg(
  aval_var=AVAL,
  base_var=BASE,
  chg_var=CHG
);
run;


/*Compare*/
%mp_assertdataset(
  base			= advs_exp,					/* parameter in proc compare */
  compare	= advs_out,					/* parameter in proc compare */
  desc		= (%nrstr(%derive_var_chg))[test01] Compare expected and test results, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion	= 1e-8,       		/* parameter in proc compare */
  method		= absolute,    /* parameter in proc compare */
  outds		= TEMP.adamski_test
);
