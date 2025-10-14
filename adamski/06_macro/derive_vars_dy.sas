/*** HELP START ***//*

### Macro:
    %derive_vars_dy  

### Purpose:
    Generates study day (`DY`) variables from given date variables using a specified reference date (e.g., `TRTSDT`).  

### Parameters:  

 - `reference_date` (required)	: Reference date variable (e.g., `TRTSDT`) used as Day 1  

 - `source_vars` (required)		: Space-separated list of source date variables(--DT) for which DY variables will be derived.

### Sample code:

~~~sas
%derive_vars_dy(  
  reference_date = TRTSDT,  
  source_vars     = AESTDT AEENDT  
)
~~~

### Note:

- Parameter `dataset` in {admiral} is not defined taking into account how the macro in SAS is used.  

- Parameter `source_vars` only accepts date variable while {admiral} accepts datetime variable as well.  
  In general, it is thought date variables are created before creating day variables.

### URL:

https://github.com/PharmaForest/adamski

---

Author:                 Ryo Nakaya
Latest udpate Date: 2025-10-14

---

*//*** HELP END ***/

%macro derive_vars_dy(reference_date, source_vars);
  %local i var newvar;
  %let i = 1;
  %let var = %scan(&source_vars, &i);

  %do %while(%length(&var) > 0);
  %let newvar = %substr(&var, 1, %eval(%length(&var)-1))Y;
    if &var. >= &reference_date. > . then do;
	  &newvar. = (&var. - &reference_date.) + 1;
	end ;
	else if . < &var. < &reference_date. then do;
	  &newvar. = (&var. - &reference_date.) ;
	end ;
	else &newvar. = . ;
    %let i = %eval(&i + 1);
    %let var = %scan(&source_vars, &i);
  %end;
%mend;