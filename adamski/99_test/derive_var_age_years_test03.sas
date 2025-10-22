/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_var_age_years() macro  
- Case of digits=2 to round new_var value   

*//*** HELP END ***/


%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp)

/*Expected Dataset*/
data e_data;
  input age age_unit $ aage;
  datalines;
  10 YEARS 10
  520 WEEKS 9.97
  3650 DAYS 9.99
  1000 . .
  ;
run;

/*Test dataset*/
data t_data;
  input age age_unit $;
  datalines;
  10 YEARS
  520 WEEKS
  3650 DAYS
  1000 .
  ;
run;
data o_data;
  set t_data;  
  %derive_var_age_years(age_var=age, age_unit=age_unit, new_var=aage ,digits=2);
run;

/*Compare*/
%mp_assertdataset(
  base=e_data,					/* parameter in proc compare */
  compare=o_data,				/* parameter in proc compare */
  desc=[mp_assertdataset]  (%nrstr(%derive_var_age_years)) Compare expected and test results for case of digits=2, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion=0,       		/* parameter in proc compare */
  method=absolute,    /* parameter in proc compare */
  outds=TEMP.adamski_test
);
