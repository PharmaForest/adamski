/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_var_base() macro  

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data adlb;
  length
    STUDYID  $6
    USUBJID  $6
    PARAMCD  $7
    AVISIT   $9
    ABLFL    $1
    ANRIND   $6
    AVALC    $6
  ;

  input
    STUDYID $
    USUBJID $
    PARAMCD $
    AVAL
    AVALC $
    AVISIT $
    ABLFL $
    ANRIND $
  ;

datalines;
TEST01 PAT01 PARAM01 10.12 .     Baseline Y NORMAL
TEST01 PAT01 PARAM01  9.70 .     Day7     . LOW
TEST01 PAT01 PARAM01 15.01 .     Day14    . HIGH
TEST01 PAT01 PARAM02  8.35 .     Baseline Y LOW
TEST01 PAT01 PARAM02  .    .     Day7     . .
TEST01 PAT01 PARAM02  8.35 .     Day14    . LOW
TEST01 PAT01 PARAM03  .    LOW   Baseline Y .
TEST01 PAT01 PARAM03  .    LOW   Day7     . .
TEST01 PAT01 PARAM03  .    MEDIUM Day14   . .
TEST01 PAT01 PARAM04  .    HIGH  Baseline Y .
TEST01 PAT01 PARAM04  .    HIGH  Day7     . .
TEST01 PAT01 PARAM04  .    MEDIUM Day14   . .
;
run;

/*expected output*/
data adlb_exp;
  length
    STUDYID  $6
    USUBJID  $6
    PARAMCD  $7
    AVISIT   $9
    ABLFL    $1
    ANRIND   $6
    AVALC    $6
	BASEC    $6
	BNRIND  $6
  ;

  input
    STUDYID $
    USUBJID $
    PARAMCD $
    AVAL
    AVALC $
    AVISIT $
    ABLFL $
    ANRIND $
	BASE
	BASEC $
	BNRIND $
  ;

datalines;
TEST01 PAT01 PARAM01 10.12 .     Baseline Y NORMAL 10.12 . NORMAL
TEST01 PAT01 PARAM01  9.70 .     Day7     . LOW 10.12 . NORMAL
TEST01 PAT01 PARAM01 15.01 .     Day14    . HIGH 10.12 . NORMAL
TEST01 PAT01 PARAM02  8.35 .     Baseline Y LOW 8.35 . LOW
TEST01 PAT01 PARAM02  .    .     Day7     . . 8.35 . LOW
TEST01 PAT01 PARAM02  8.35 .     Day14    . LOW 8.35 . LOW
TEST01 PAT01 PARAM03  .    LOW   Baseline Y . . LOW .
TEST01 PAT01 PARAM03  .    LOW   Day7     . . . LOW .
TEST01 PAT01 PARAM03  .    MEDIUM Day14   . . . LOW .
TEST01 PAT01 PARAM04  .    HIGH  Baseline Y . . HIGH .
TEST01 PAT01 PARAM04  .    HIGH  Day7     . . . HIGH .
TEST01 PAT01 PARAM04  .    MEDIUM Day14   . . . HIGH .
;
run;

/*output by the macro*/
%derive_var_base(
  dataset=adlb,
  by_vars=USUBJID PARAMCD,
  source_var=AVAL,
  new_var=BASE,
  filter=ABLFL = "Y",
  outdata=adlb1
);
%derive_var_base(
  dataset=adlb1,
  by_vars=USUBJID PARAMCD,
  source_var=AVALC,
  new_var=BASEC,
  filter=ABLFL = "Y",
  outdata=adlb2
);
%derive_var_base(
  dataset=adlb2,
  by_vars=USUBJID PARAMCD,
  source_var=ANRIND,
  new_var=BNRIND,
  filter=ABLFL = "Y",
  outdata=adlb_out
);


/*Compare*/
%mp_assertdataset(
  base			= adlb_exp,					/* parameter in proc compare */
  compare	= adlb_out,					/* parameter in proc compare */
  desc		= (%nrstr(%derive_var_base))[test01] Compare expected and test results, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion	= 0,       		/* parameter in proc compare */
  method		= absolute,    /* parameter in proc compare */
  outds		= TEMP.adamski_test
);
