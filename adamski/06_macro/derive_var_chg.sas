/*** HELP START ***//*

### Macro:
    %derive_var_chg

### Purpose:
    Derive Change from Baseline (CHG) in a BDS-style dataset.  

### Parameters:  
 
 - `aval_var` (required, default=AVAL) : Analysis variable from which baseline value is taken out 
 - `base_var` (required, default=BASE) : Baseline variable
 - `chg_var` (required, default=CHG) : Change from baseline variable. (&aval_var - &base_var)

### Sample code:

~~~sas

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


data advs;
  set advs;
  %derive_var_chg();
run;
  
~~~

### Notes:

-   Change from baseline is calculated as
    CHG = AVAL - BASE

    
### URL:

https://github.com/PharmaForest/adamski

---

Author:          	    Sharad Chhetri
Latest udpate Date: 	2026-01-25

---

*//*** HELP END ***/


%macro derive_var_chg(
    aval_var=AVAL, 
    base_var=BASE,
    chg_var=CHG
);


  /*--------------------------------------------------------------------*
   * Basic parameter checks
   *--------------------------------------------------------------------*/
  %if %superq(aval_var)= or %superq(base_var)= or %superq(chg_var)= %then %do;
    %put ERROR: Required parameters missing. aval_var=, base_var=, chg_var are required.;
    %abort cancel;
  %end;

  %local dsid varnum returncd;

  %let dsid = %sysfunc(open(&syslast,i));

  %if &dsid > 0 %then %do;
    %let varnum = %sysfunc(varnum(&dsid,&chg_var));
    %let returncd = %sysfunc(close(&dsid));

    %if &varnum > 0 %then %do;
      %put WARNING: Variable &chg_var already exists in &syslast.. Values will be overwritten.;
    %end;
  %end;
  %else %do;
    /*--------------------------------------------------------------------*
     * New change from baseline variable
     *--------------------------------------------------------------------*/
    length &chg_var 8.;
  %end;	

  /*--------------------------------------------------------------------*
   * Derive Change from Baseline
   *--------------------------------------------------------------------*/
  
  /* Change from baseline = Analysis value - Baseline value */
  if not missing(&aval_var) and not missing(&base_var) then do;
    &chg_var = &aval_var - &base_var;    
  end;
%mend derive_var_chg;
