/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_vars_joined() macro with only required variables

### Expected result:  
- dataset test with USUBJID, AGE, SEX variables will be created  

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*Expected result dataset*/
data expected;
  length USUBJID $10 SEX $1;
  infile datalines dsd dlm='|' truncover;
  input USUBJID :$10. AGE SEX :$1.;
datalines;
010|10|M
020|20|F
030|.| 
;
run;

/*Test dataset*/
data raw;
  length USUBJID $10.;
  do USUBJID="010","020","030";
        output;
  end;
run;
data add;
  length USUBJID $10. SEX $1.;
  do USUBJID="010","020","040";
        AGE=input(USUBJID,best.);
        SEX=choosec(whichc(USUBJID,"010","020","040"),"M","F","F");
        output;
  end;
run;
data test;
  set raw;
  %derive_vars_joined(
    dataset_add = add,
    by_vars     = USUBJID,
    new_vars    = AGE SEX
  );
run;

/*Compare*/
%mp_assertdataset(
  base=expected,				/* parameter in proc compare */
  compare=test,				/* parameter in proc compare */
  desc=(%nrstr(%derive_vars_joined))[test01] Compare expected and test results for case with only required variables, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion=0,       		/* parameter in proc compare */
  method=absolute,    /* parameter in proc compare */
  outds=TEMP.adamski_test
);
