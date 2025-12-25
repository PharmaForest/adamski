/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_var_age_years() macro  
- Case of age_unit=character literal  

*//*** HELP END ***/


%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*Expected Dataset*/
data e_data;
  input age age_unit $ aage;
  datalines;
  240 DAYS 20
  360 DAYS 30
  480 DAYS 40
  ;  
run;

/*Test dataset*/
data t_data;
  input age age_unit $;
  datalines;
  240 DAYS
  360 DAYS
  480 DAYS
  ;  
run;
data o_data;
  set t_data;  
  %derive_var_age_years(age_var=age, age_unit="MONTHS", new_var=aage); /*Unit of age is months(not variable age_unit)*/
run;

/*Compare*/
%mp_assertdataset(
  base=e_data,					/* parameter in proc compare */
  compare=o_data,				/* parameter in proc compare */
  desc=[mp_assertdataset]  (%nrstr(%derive_var_age_years)) Compare expected and test results for case of age_unit=character literal, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion=0,       		/* parameter in proc compare */
  method=absolute,    /* parameter in proc compare */
  outds=TEMP.adamski_test
);
