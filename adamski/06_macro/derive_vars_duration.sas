/*** HELP START ***//*

### Macro:
    %derive_vars_duration

### Purpose:
    Derives duration between two dates, specified by the variables present in the input dataset (e.g., duration of adverse events, relative day, age, etc.).  

### Parameters:  

 - `new_var` (required) : Name of the new variable to created.
 
 - `new_var_unit` (optional) : Name of the unit variable
 
 - `start_date` (required) : Start date/datetime variable

 - `end_date` (required) : End date/datetime variable

 - `in_unit` (required, default=days) : Name of the input unit
 
 - `out_unit` (required, default=days) : Name of the output unit
 
 - `floor_in` (required, default=Y) : If Y, floor datetime values to date before computing
  
 - `add_one` (required, default=Y) : Add 1 to duration if Y 
  
 - `trunc_out` (required, default=N) : Truncate output duration to integer value if Y
  
 - `type` (required, default=duration) : Type of calculation
 


### Sample code:

~~~sas

data test1;
  input USUBJID $ BRTHDT :yymmdd10. RANDDT :yymmdd10.;
  format BRTHDT RANDDT yymmdd10.;
datalines;
P01 1984-09-06 2020-02-24
P02 1985-01-01 .
P03 . 2021-03-10
P04 . .
P05 1971-10-10 2025-10-30
;
run;

data test1_op;
set test1;

	%derive_vars_duration(
	  new_var=AAGE,
	  new_var_unit=AAGEU,
	  start_date=BRTHDT,
	  end_date=RANDDT,
	  out_unit=years,
	  add_one=N,
	  trunc_out=Y
	);

run;



data test2;
  input USUBJID $ BRTHDT :yymmdd10. RANDDT :yymmdd10.;
  format BRTHDT RANDDT yymmdd10.;
datalines;
P01 1984-09-06 2020-02-24
P02 1985-01-01 .
P03 . 2021-03-10
P04 . .
P05 1971-10-10 2025-10-30
;
run;


data test2_op;
set test2;

	%derive_vars_duration(
	  new_var=AAGE,
	  new_var_unit=AAGEU,
	  start_date=BRTHDT,
	  end_date=RANDDT,
	  out_unit=years,
	  add_one=N,
	  trunc_out=Y
	);

run;

data test3;
  length USUBJID $3;
  format ASTDTM LDOSEDTM datetime20.;

  input USUBJID $ ASTDTM :anydtdtm. LDOSEDTM :anydtdtm.;
  datalines;
P01 2019-08-09T04:30:56 2019-08-08T10:05:00
P02 2019-11-11T23:59:59 2019-10-11T11:37:00
P03 2019-11-11T00:00:00 2019-11-10T23:59:59
P04 2019-11-11T12:34:56 .
P05 . 2019-09-28T12:34:56
;
run;

data test3_op;
set test3;

	%derive_vars_duration(
	  new_var = LDRELTM,
	  new_var_unit = LDRELTMU,
	  start_date = LDOSEDTM,
	  end_date = ASTDTM,
	  in_unit = hours,
	  out_unit = hours,
	  add_one = N
	);
run;	

  
~~~

### Note:

- The duration is derived as the time from start to end date in the specified output unit. If the end date is before the start date, the duration is negative.
- When FLOOR_IN=Y, any datetime variables are converted to date values, effectively dropping the time component. 
- When FLOOR_IN=N, fractional days are retained to reflect exact time differences.
- The macro supports time units such as years, months, weeks, days, hours, minutes, and seconds.


### URL:

https://github.com/PharmaForest/adamski

---

Author:          	    Sharad Chhetri
Latest udpate Date: 	2025-11-17

---

*//*** HELP END ***/



%macro derive_vars_duration(
    new_var=,
    new_var_unit=,
    start_date=,
    end_date=,
    in_unit=days,
    out_unit=DAYS,
    floor_in=Y,
    add_one=Y,
    trunc_out=N,
    type=duration
);


   length &new_var 8. &new_var_unit $15.;

   /* Handle missing values */
   if missing(&start_date) or missing(&end_date) then &new_var = .;
   else do;
      /* Create internal working copies */
      start_dt = &start_date;
      end_dt   = &end_date;
      
      /* Get the format */
      st_fmt = vformatx("&start_date");
      en_fmt = vformatx("&end_date");
      
      /* Apply FLOOR_IN logic for datetime variables - Use date if FLOOR_IN=Y */
      %if %upcase(&floor_in) = Y %then %do;
 		 if index(upcase(st_fmt), "DATETIME") then start_dt = datepart(&start_date);
    	 if index(upcase(en_fmt), "DATETIME") then end_dt = datepart(&end_date);
      %end;
      %else %do;
      	 if index(upcase(st_fmt), "DATETIME") then start_dt = &start_date / (24*60*60);
      	 if index(upcase(en_fmt), "DATETIME") then end_dt = &end_date / (24*60*60);
      %end;	  
      
      /* Compute difference (days base) */
      dur_in_days = end_dt - start_dt;

      /* Convert to desired output unit */
      select (lowcase("&out_unit"));
        when ("years","year","y")    &new_var = dur_in_days / 365.25;
        when ("months","month","mo") &new_var = dur_in_days / 30.4375;
        when ("weeks","week","wk","w") &new_var = dur_in_days / 7;
        when ("days","day","d")      &new_var = dur_in_days;
        when ("hours","hour","h")    &new_var = dur_in_days * 24;
        when ("minutes","minute","min") &new_var = dur_in_days * 24*60;
        when ("seconds","second","s") &new_var = dur_in_days * 24*60*60;
        otherwise &new_var = .;
      end;

      /* Add 1 if requested */
      %if %upcase(&add_one) = Y %then %do;
        if not missing(&new_var) then &new_var = &new_var + 1;
      %end;

      /* Truncate if requested */
      %if %upcase(&trunc_out) = Y %then %do;
        if not missing(&new_var) then &new_var = floor(&new_var);
      %end;

      /* Add optional unit variable */
      %if %length(&new_var_unit) > 0 %then %do;
        if missing(&new_var) then &new_var_unit = '';
        else &new_var_unit = upcase("&out_unit");
      %end;

      drop 
      	dur_in_days
       	start_dt
       	end_dt
       	st_fmt
       	en_fmt;  
    end;

%mend derive_vars_duration;

