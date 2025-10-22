/*** HELP START ***//*

### Macro:
    %derive_var_age_years

### Purpose:
    Converts a set of age values from the specified time unit to years.  

### Parameters:  

 - `age_var` (required)	: The ages to convert.  

 - `age_unit` (required) : Age unit. Note that permitted values are cases insensitive (e.g. "YEARS" is treated the same as "years" and "Years").
 							Permitted values "years", "months", "weeks", "days", "hours", "minutes", "seconds"
 - `new_var`  (required) : New age variable to be created in years.

 - 'digits' (optional) : Allows rounding of "new_var" variable based on the parameter value passed. No rounding is applied, if left blank.  

### Sample code:

~~~sas

data data1;
  input age age_unit $;
  datalines;
  240 MONTHS
  360 MONTHS
  480 MONTHS
  ;  
run;

data test1;
  set data1;  
   %derive_var_age_years(age_var=age, age_unit=age_unit, new_var=aage);
run;

data test1;
  set data1;  
  %derive_var_age_years(age_var=age, age_unit="MONTHS", new_var=aage);
run;

data data2;
  input age age_unit $;
  datalines;
  10 YEARS
  520 WEEKS
  3650 DAYS
  1000 .
  ;
run;

data test2;
  set data2;  
  %derive_var_age_years(age_var=age, age_unit=age_unit, new_var=aage);
run;


data data3;
  input AGE AGEU $;
  datalines;
  27 days
  24 months
  3 years
  4 weeks
  1 years
  ;
run;

data test3;
  set data3;  
  %derive_var_age_years(age_var=age, age_unit=ageu, new_var=aage);
run;

data test4;
  set data3;
  %derive_var_age_years(age_var=age, age_unit=ageu, new_var=aage, digits=);
run;

data test5;
  set data3;
  %derive_var_age_years(age_var=age, age_unit=ageu, new_var=aage, digits=3);
run;
  
~~~

### Note:

- Parameter `dataset` in {admiral} is not defined taking into account how the macro in SAS is used.  


### URL:

https://github.com/PharmaForest/adamski

---

Author:          	    Sharad Chhetri
Latest udpate Date: 	2025-10-21

---

*//*** HELP END ***/


%macro derive_var_age_years(age_var=, age_unit=, new_var=, digits=);

    length &new_var 8.;
    
    /* use lowercase of age_unit for comparison */
    age_unit_lc = lowcase(&age_unit);

    select (age_unit_lc);
      when ('years')   &new_var = &age_var;
      when ('months')  &new_var = &age_var / 12;
      when ('weeks')   &new_var = &age_var / (365.25/7);
      when ('days')    &new_var = &age_var / 365.25;
      when ('hours')   &new_var = &age_var / (365.25*24);
      when ('minutes') &new_var = &age_var / (365.25*24*60);
      when ('seconds') &new_var = &age_var / (365.25*24*60*60);
      when ('')        &new_var = .; /* missing unit → missing result */
      otherwise        &new_var = .; /* invalid unit */
    end;

	/* Compute rounding factor (e.g., 0.01 for 2 decimals, 0.0001 for 4) */
	%if &digits ge 1 %then %do;
  		%let round_val = %sysevalf(1 / (10 ** &digits.)); 
  		&new_var=round(&new_var, &round_val); 
	%end;
	 
    drop age_unit_lc;  
%mend derive_var_age_years;


