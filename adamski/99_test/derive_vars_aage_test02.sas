/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_vars_aage() macro wtih type=interval

### Expected result:  
- dataset test with AAGE calculated by type=interval will be created  

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*Expected result dataset*/
data base;
  length USUBJID $10;
  format BRTHDT RANDDT yymmdd10.
         BRTHDTM RANDDTM datetime19.;
  
  * 1. Standard setting ;
  USUBJID = "SUBJ01";
  BRTHDT  = '06SEP1984'd;
  RANDDT  = '24FEB2020'd;
  BRTHDTM = dhms(BRTHDT, 0, 0, 0);
  RANDDTM = dhms(RANDDT, 0, 0, 0);
  output;

  * 2. Leap year ;
  USUBJID = "SUBJ02";
  BRTHDT  = '01FEB2000'd;
  RANDDT  = '01MAR2000'd;
  BRTHDTM = dhms(BRTHDT, 0, 0, 0);
  RANDDTM = dhms(RANDDT, 0, 0, 0);
  output;

  * 3. End of month - Start of month ;
  USUBJID = "SUBJ03";
  BRTHDT  = '31JAN2021'd;
  RANDDT  = '28FEB2021'd;
  BRTHDTM = dhms(BRTHDT, 0, 0, 0);
  RANDDTM = dhms(RANDDT, 0, 0, 0);
  output;

  * 4. end < start (negative age) ;
  USUBJID = "SUBJ04";
  BRTHDT  = '01JAN2020'd;
  RANDDT  = '01JAN2019'd;
  BRTHDTM = dhms(BRTHDT, 0, 0, 0);
  RANDDTM = dhms(RANDDT, 0, 0, 0);
  output;

  * 5. Same date ;
  USUBJID = "SUBJ05";
  BRTHDT  = '15JUN2010'd;
  RANDDT  = '15JUN2010'd;
  BRTHDTM = dhms(BRTHDT, 0, 0, 0);
  RANDDTM = dhms(RANDDT, 0, 0, 0);
  output;

  * 6. Different time ;
  USUBJID = "SUBJ06";
  BRTHDT  = '01JAN2000'd;
  RANDDT  = '02JAN2000'd;
  BRTHDTM = dhms('01JAN2000'd, 12, 0, 0);
  RANDDTM = dhms('02JAN2000'd,  6, 0, 0);
  output;

  * 7. start missing ;
  USUBJID = "SUBJ07";
  BRTHDT  = .;
  RANDDT  = '01JAN2020'd;
  BRTHDTM = .;
  RANDDTM = dhms(RANDDT, 0, 0, 0);
  output;

  * 8. end missing ;
  USUBJID = "SUBJ08";
  BRTHDT  = '01JAN1980'd;
  RANDDT  = .;
  BRTHDTM = dhms(BRTHDT, 0, 0, 0);
  RANDDTM = .;
  output;
run;
data adsl_expected ;
	set base ;
	select (_N_);
	    when (1) AAGE = 1850;
	    when (2) AAGE = 4;
	    when (3) AAGE = 4;
		when (4) AAGE = -53;
		when (5) AAGE = 0;
		when (6) AAGE = 0;
	    otherwise AAGE = .;
	end;
	if AAGE ne . then AAGEU="WEEKS" ;
run ;

/*Test dataset*/
data adsl_test;
  set base;
  %derive_vars_aage(
    start_date = BRTHDTM,
    end_date   = RANDDTM,
    age_unit   = weeks,
    type       = interval,
    digits     = 2
  )
run;


/*Compare*/
%mp_assertdataset(
  base=adsl_expected,				/* parameter in proc compare */
  compare=adsl_test,				/* parameter in proc compare */
  desc=(%nrstr(%derive_vars_aage))[test02] Compare expected and test results for case with type=interval, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion=0,       		/* parameter in proc compare */
  method=absolute,    /* parameter in proc compare */
  outds=TEMP.adamski_test
);
