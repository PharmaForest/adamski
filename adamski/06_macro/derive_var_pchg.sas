/*** HELP START ***//*

### Macro:
    %derive_var_pchg

### Purpose:
    Derive Percent Change from Baseline (PCHG) in a BDS-style dataset.

### Parameters:

 - `aval_var` (required, default=AVAL) : Analysis variable.
 - `base_var` (required, default=BASE) : Baseline variable.
 - `pchg_var` (required, default=PCHG) : Percent change from baseline variable.
   ((&aval_var - &base_var) / &base_var) * 100

### Sample code:

~~~sas

data advs;
  length USUBJID $3 PARAMCD $6 ABLFL $1;
  infile datalines truncover;
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
  %derive_var_pchg();
run;

~~~

### Notes:

- Percent change from baseline is calculated as

      PCHG = ((AVAL - BASE) / BASE) * 100

- PCHG is only derived when both AVAL and BASE are non-missing and BASE is not zero.

### URL:

https://github.com/PharmaForest/adamski

---

Author:                 Manivannan Mathialagan
Latest update Date:     2026-07-07

---

*//*** HELP END ***/


%macro derive_var_pchg(
    aval_var=AVAL,
    base_var=BASE,
    pchg_var=PCHG
    );

    /*--------------------------------------------------------------------*
    * Basic parameter checks
    *--------------------------------------------------------------------*/
    %if %superq(aval_var)= or %superq(base_var)= or %superq(pchg_var)= %then 
        %do;
            %put ERROR: Required parameters missing. aval_var=, base_var=, pchg_var= are required.;
            %abort cancel;
        %end;

    /*--------------------------------------------------------------------*
    * New percent change from baseline variable
    *--------------------------------------------------------------------*/
    length &pchg_var 8.;

    /*--------------------------------------------------------------------*
    * Derive Percent Change from Baseline
    *--------------------------------------------------------------------*/

    /* Percent change from baseline = ((Analysis value - Baseline value) / Baseline value) * 100 */
    if not missing(&aval_var) and not missing(&base_var) and &base_var ne 0 then 
        do;
            &pchg_var = ((&aval_var - &base_var) / &base_var) * 100 ;
        end;
    else &pchg_var = .;

%mend derive_var_pchg;