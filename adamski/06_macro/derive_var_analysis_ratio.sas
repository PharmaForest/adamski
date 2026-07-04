/*** HELP START ***//*

### Macro:

    %derive_var_analysis_ratio

### Purpose:

    Derives an analysis ratio variable for a BDS dataset using a numerator and denominator variable.

    This macro is called as a standalone macro. It checks that the input dataset and required variables exist, then creates an output dataset with the derived ratio variable appended.

    Example:
    - Ratio to Baseline              : AVAL / BASE  -> R2BASE
    - Ratio to Analysis Range Lower  : AVAL / ANRLO -> R2ANRLO
    - Ratio to Analysis Range Upper  : AVAL / ANRHI -> R2ANRHI

### Parameters:

    - `dataset` (required) :
        Name of the input dataset.

    - `numer_var` (required) :
        Numeric variable containing values to be used as the numerator.

    - `denom_var` (required) :
        Numeric variable containing values to be used as the denominator.

    - `new_var` (optional) :
        Name of the derived ratio variable to be created.
        If not provided, the macro creates the variable by prefixing the denominator variable with `R2`.

    - `outdata` (optional) :
        Name of the output dataset.
        If not provided, the input dataset will be overwritten.

### Output:

    - Output dataset with the derived ratio variable appended.

### Notes:

    - If the denominator is missing or zero, the derived ratio variable is set to missing.
    - If the numerator is missing, the derived ratio variable is set to missing.
    - No intermediate variables are created by this macro.
    - Parameter `outdata` is an additional optional parameter in Adamski.

### Sample code:

~~~sas
%derive_var_analysis_ratio(
    dataset   = adlb,
    numer_var = AVAL,
    denom_var = BASE
    );

%derive_var_analysis_ratio(
    dataset   = adlb,
    numer_var = AVAL,
    denom_var = ANRLO
    );

%derive_var_analysis_ratio(
    dataset   = adlb,
    numer_var = AVAL,
    denom_var = ANRHI
    );

%derive_var_analysis_ratio(
    dataset   = adlb,
    numer_var = AVAL,
    denom_var = BASE,
    new_var   = R01BASE,
    outdata   = adlb_ratio
    );
~~~

### URL:
https://github.com/PharmaForest/adamski

---
Author:                 	  Manivannan Mathialagan
Latest update Date:    	      2026-07-04
---

*//*** HELP END ***/

%macro derive_var_analysis_ratio(
    dataset   = ,
    numer_var = ,
    denom_var = ,
    new_var   = ,
    outdata   =
    );

    %local _new_var _error _dsid _num_numer _num_denom _rc;

    %let _error = 0;

    /* Check required parameters */
    %if %superq(dataset) = %then 
        %do;
            %put ERROR: derive_var_analysis_ratio: Required parameter dataset is missing.;
            %let _error = 1;
        %end;

    %if %superq(numer_var) = %then 
        %do;
            %put ERROR: derive_var_analysis_ratio: Required parameter numer_var is missing.;
            %let _error = 1;
        %end;

    %if %superq(denom_var) = %then 
        %do;
            %put ERROR: derive_var_analysis_ratio: Required parameter denom_var is missing.;
            %let _error = 1;
        %end;

    %if &_error = 1 %then 
        %do;
            %put ERROR: derive_var_analysis_ratio: Macro execution stopped due to missing required parameter(s).;
            %return;
        %end;

    /* Default output dataset */
    %if %superq(outdata) = %then 
        %do;
            %let outdata = &dataset;
        %end;

    /* Default new variable name */
    %if %superq(new_var) = %then 
        %do;
            %let _new_var = R2&denom_var;
        %end;
    %else 
        %do;
            %let _new_var = &new_var;
        %end;

    /* Check input dataset exists */
    %if not %sysfunc(exist(&dataset)) %then 
        %do;
            %put ERROR: derive_var_analysis_ratio: Input dataset &dataset does not exist.;
            %return;
        %end;

    /* Check input variables exist */
    %let _dsid = %sysfunc(open(&dataset));

    %if &_dsid = 0 %then 
        %do;
            %put ERROR: derive_var_analysis_ratio: Unable to open input dataset &dataset..;
            %return;
        %end;

    %let _num_numer = %sysfunc(varnum(&_dsid, &numer_var));
    %let _num_denom = %sysfunc(varnum(&_dsid, &denom_var));
    %let _rc = %sysfunc(close(&_dsid));

    %if &_num_numer = 0 %then 
        %do;
            %put ERROR: derive_var_analysis_ratio: Variable &numer_var not found in input dataset &dataset..;
            %let _error = 1;
        %end;

    %if &_num_denom = 0 %then 
        %do;
            %put ERROR: derive_var_analysis_ratio: Variable &denom_var not found in input dataset &dataset..;
            %let _error = 1;
        %end;

    %if &_error = 1 %then 
        %do;
            %put ERROR: derive_var_analysis_ratio: Macro execution stopped due to invalid input variable(s).;
            %abort cancel;
        %end;

    /* Derive ratio variable */
    data &outdata;
		length &_new_var 8;
        set &dataset;

        if missing(&numer_var) or missing(&denom_var) or &denom_var = 0 then &_new_var = .;
        else &_new_var = &numer_var / &denom_var;
    run;

%mend derive_var_analysis_ratio;
