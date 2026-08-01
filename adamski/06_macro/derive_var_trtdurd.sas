/*** HELP START ***/
/*
### Macro:
    %derive_var_trtdurd

### Purpose:
    Derives total treatment duration in days(TRTDURD) for each subject.

### Parameters:
 - `dataset` (required) : The input dataset containing treatment start and end date variables.

 - `start_date` (optional,default=TRTSDT):The treatment start date variable.

 - `end_date` (optional,default=TRTEDT):The treatment end date variable.

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

%derive_var_trtdurd(dataset=duration);
~~~

### Note:
    TRTDURD is calculated as intck('day',start_date,end_date)+ 1. The difference between start_date 
    and end_date plus one day ensures inclusive day counting following CDISC ADaM implementation standards.

### URL:
    https://github.com/PharmaForest/adamski

Author: Uma Balasubramanian
Latest update Date: 21Jul2026
*/
/*** HELP END ***/

%macro derive_var_trtdurd(dataset=,
start_date=TRTSDT,
end_date=TRTEDT
);
/* check required parameters */
%if %superq(dataset)= %then %do;
%put ERROR: Required parameter missing. dataset= is required.;
%abort cancel;
%end;

data &dataset;
set &dataset;
/* Derive total treatment duration in days: number of days from treatment start to end plus one */
TRTDURD = intck('day',&start_date,&end_date) + 1;
run;

%mend derive_var_trtdurd;
