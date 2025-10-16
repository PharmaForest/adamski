/*** HELP START ***//*

### Macro:
    %compute_age_years

### Purpose:
    Converts a set of age values from the specified time unit to years.  

### Parameters:  

 - `age` (required)	: The ages to convert.  

 - `age_unit` (required) :  Age unit. Note that permitted values are cases insensitive (e.g. "YEARS" is treated the same as "years" and "Years").
 							Permitted values "years", "months", "weeks", "days", "hours", "minutes", "seconds"


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
  %compute_age_years(age=age, age_unit=age_unit);
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
  %compute_age_years(age=age, age_unit=age_unit);
run;
  
~~~

### Note:

- Parameter `dataset` in {admiral} is not defined taking into account how the macro in SAS is used.  


### URL:

https://github.com/PharmaForest/adamski

---

Author:          	Sharad Chhetri
Latest udpate Date: 2025-10-15

---

*//*** HELP END ***/

%macro compute_age_years(age=, age_unit=);

    length age_years 8.;
    
    /* use lowercase of age_unit for comparison */
    age_unit_lc = lowcase(&age_unit);

    select (age_unit_lc);
      when ('years')   age_years = age;
      when ('months')  age_years = age / 12;
      when ('weeks')   age_years = age / (365.25/7);
      when ('days')    age_years = age / 365.25;
      when ('hours')   age_years = age / (365.25*24);
      when ('minutes') age_years = age / (365.25*24*60);
      when ('seconds') age_years = age / (365.25*24*60*60);
      when ('')        age_years = .; /* missing unit → missing result */
      otherwise        age_years = .; /* invalid unit */
    end;
	 
	drop age_unit_lc; 
	
%mend compute_age_years;
