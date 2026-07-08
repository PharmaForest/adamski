/*** HELP START ***/
/*
### Macro:
    %derive_var_trtdurd

### Purpose:
Derives total treatment duration in days (TRTDURD) for each subject
by calculating the difference between TRTSDT and TRTEDT plus one day.
   
### Parameters:
 - dataset (required): The input dataset containing TRTSDT and TRTEDT variables.
                       TRTDURD will be added to this dataset as output.
### Sample code:
~~~sas
data duration;
    length usubjid $10;
    usubjid = '01-001';
    trtsdt = '02JAN2014'd;
    trtedt = '02JUL2014'd;
    output;
    usubjid = '01-002';
    trtsdt = '05AUG2012'd;
    trtedt = '01SEP2012'd;
    output;
    format trtsdt trtedt date9.;
run;

%derive_var_trtdurd(duration);
~~~

### Note:
    TRTDURD = intck('day', TRTSDT, TRTEDT) + 1. The plus one ensures
    inclusive day counting following CDISC ADaM implementation standards.
Author: Uma Balasubramanian
Latest update Date: 25Jun2026
*/
/*** HELP END ***/

%macro derive_var_trtdurd(dataset);
    data &dataset;
        set &dataset;
        TRTDURD = intck('day',
                         TRTSDT,
                         TRTEDT) + 1;
    run;
%mend derive_var_trtdurd;
