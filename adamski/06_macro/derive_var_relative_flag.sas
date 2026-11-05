/*** HELP START ***//*

### Macro:
    %derive_var_relative_flag

### Purpose:
    Derive a flag for observations before or after a reference record
    within each BY group. The reference record is the first or last
    observation meeting the specified condition.

### Parameters:

 - 'dataset' (required) : input dataset
 - 'by_vars' (required) : grouping variables
 - 'order' (required) : sorting variables
 - 'new_var' (required) : output flag variable
 - 'condition' (required) : condition identifying the reference record
 - 'mode' (required) : FIRST or LAST. Which record meeting the condition
   is used as the reference
 - 'selection' (required) : BEFORE or AFTER. Which side of the reference
   record is flagged
 - 'inclusive' (required) : 1 to flag the reference record itself,
   0 to leave it unflagged
 - 'flag_no_ref_groups' (optional, default=1) : 1 to flag all records in
   BY groups where no record meets the condition, 0 to leave them unflagged
 - 'check_type' (optional, default=warning) : NONE | WARNING | ERROR
 - 'outdata' (optional, default=&dataset._relative) : output dataset name

### Sample code:

~~~sas

data adae;
    length USUBJID $10 ACOVFL $1;
    infile datalines dsd dlm=',' truncover;
    input USUBJID $ ASTDY ACOVFL $ AESEQ;
datalines;
1,2,,1
1,5,Y,2
1,5,,3
1,17,,4
1,27,Y,5
1,32,,6
2,8,,1
2,11,,2
;
run;


data response;
    length USUBJID $10 AVALC $2;
    infile datalines dsd dlm=',' truncover;
    input USUBJID $ AVISITN AVALC $;
datalines;
1,0,PR
1,1,CR
1,2,CR
1,3,SD
1,4,NE
2,0,SD
2,1,PD
2,2,PD
3,0,SD
4,0,SD
4,1,PR
4,2,PD
4,3,SD
4,4,PR
;
run;


**Example1: flag all adverse events after the first COVID adverse event;
%derive_var_relative_flag(
    dataset=adae,
    by_vars=USUBJID,
    order=ASTDY AESEQ,
    new_var=PSTCOVFL,
    condition=ACOVFL = "Y",
    mode=first,
    selection=after,
    inclusive=0,
    flag_no_ref_groups=0,
    outdata=adae_pstcovfl
);


**Example2: flag observations up to and including first PD for each patient;
%derive_var_relative_flag(
    dataset=response,
    by_vars=USUBJID,
    order=AVISITN,
    new_var=ANL02FL,
    condition=AVALC = "PD",
    mode=first,
    selection=before,
    inclusive=1,
    outdata=response_anl02fl
);


**Example3: flag observations after the last COVID adverse event;
%derive_var_relative_flag(
    dataset=adae,
    by_vars=USUBJID,
    order=ASTDY AESEQ,
    new_var=PSTCOVFL,
    condition=ACOVFL = "Y",
    mode=last,
    selection=after,
    inclusive=0,
    flag_no_ref_groups=0,
    outdata=adae_lastcov
);

~~~

### Notes:

    Records in BY groups where no observation meets the condition have the
    flag controlled by 'flag_no_ref_groups'. The default of 1 matches the
    admiral default of flag_no_ref_groups = TRUE.

### URL:

https://github.com/PharmaForest/adamski

---

Author:                 Uma Balasubramanian
Latest update Date:     29Sep2026

---

*//*** HELP END ***/

%macro derive_var_relative_flag(
    dataset=,
    by_vars=,
    order=,
    new_var=,
    condition=,
    mode=,
    selection=,
    inclusive=,
    flag_no_ref_groups=1,
    check_type=warning,
    outdata=
);

    %local n_dups;

    /* check required parameters */
    %if %superq(dataset)= %then %do;
        %put ERROR: Required parameter missing. dataset= is required.;
        %return;
    %end;

    %if %superq(by_vars)= %then %do;
        %put ERROR: Required parameter missing. by_vars= is required.;
        %return;
    %end;

    %if %superq(order)= %then %do;
        %put ERROR: Required parameter missing. order= is required.;
        %return;
    %end;

    %if %superq(new_var)= %then %do;
        %put ERROR: Required parameter missing. new_var= is required.;
        %return;
    %end;

    %if %superq(condition)= %then %do;
        %put ERROR: Required parameter missing. condition= is required.;
        %return;
    %end;

    %if %superq(mode)= %then %do;
        %put ERROR: Required parameter missing. mode= is required.;
        %return;
    %end;

    %if %superq(selection)= %then %do;
        %put ERROR: Required parameter missing. selection= is required.;
        %return;
    %end;

    %if %superq(inclusive)= %then %do;
        %put ERROR: Required parameter missing. inclusive= is required.;
        %return;
    %end;

    /* check parameter values */
    %if %upcase(&mode) ne FIRST and %upcase(&mode) ne LAST %then %do;
        %put ERROR: mode= must be FIRST or LAST.;
        %return;
    %end;

    %if %upcase(&selection) ne BEFORE and %upcase(&selection) ne AFTER %then %do;
        %put ERROR: selection= must be BEFORE or AFTER.;
        %return;
    %end;

    %if &inclusive ne 0 and &inclusive ne 1 %then %do;
        %put ERROR: inclusive= must be 0 or 1.;
        %return;
    %end;

    %if &flag_no_ref_groups ne 0 and &flag_no_ref_groups ne 1 %then %do;
        %put ERROR: flag_no_ref_groups= must be 0 or 1.;
        %return;
    %end;

    %if %upcase(&check_type) ne NONE and %upcase(&check_type) ne WARNING
        and %upcase(&check_type) ne ERROR %then %do;
        %put ERROR: check_type= must be NONE, WARNING or ERROR.;
        %return;
    %end;

    %if not %sysfunc(exist(&dataset))%then %do;
    %put ERROR: input dataset &dataset does not exist. please provide correct dataset name.;
    %return;
    %end;
    
    %local dsid varcheck rc;
    %let dsid = %sysfunc(open(&dataset));
    %let varcheck = %sysfunc(varnum(&dsid, %scan(&condition, 1, %str( ))));
    %let rc = %sysfunc(close(&dsid));
    
    %if &varcheck = 0 %then %do;
    %put ERROR: Variable %scan(&condition, 1, %str( )) referenced in condition does not exist in dataset &dataset.;
    %return;
    %end;

    /* default output dataset name */
    %if %superq(outdata)= %then %let outdata = &dataset._relative;

    /* Step 1: sort by BY and ORDER variables */
    proc sort data=&dataset out=_tmp_sorted;
        by &by_vars &order;
    run;

    /* Step 2: number the rows within each BY group */
    data _tmp_obs;
        set _tmp_sorted;
        by &by_vars &order;
        retain tmp_obs_nr;
        if first.%scan(&by_vars, -1) then tmp_obs_nr = 0;
        tmp_obs_nr + 1;
    run;

    /* Step 3: find the reference record in each BY group.
       WHERE keeps only records meeting the condition, so FIRST. and LAST.
       are evaluated across those records only. */
    data _tmp_ref;
        set _tmp_obs;
        where &condition;
        by &by_vars &order;
        %if %upcase(&mode) = FIRST %then %do;
            if first.%scan(&by_vars, -1);
        %end;
        %else %do;
            if last.%scan(&by_vars, -1);
        %end;
        keep &by_vars tmp_obs_nr;
        rename tmp_obs_nr = ref_obs_nr;
    run;

    /* Step 4: flag each record by its position relative to the reference.
       A BY group with no reference record has REF_OBS_NR missing, and is
       handled first so that missing values never reach the comparisons. */
    data _tmp_flag;
        merge _tmp_obs _tmp_ref;
        by &by_vars;

        length &new_var $1;

        if missing(ref_obs_nr) then do;
        %if &flag_no_ref_groups = 1 %then %do;
            &new_var = "Y";
        %end;
        end;
        %if %upcase(&selection) = AFTER %then %do;
        else if tmp_obs_nr > ref_obs_nr then &new_var = "Y";
        %end;
        %else %do;
        else if tmp_obs_nr < ref_obs_nr then &new_var = "Y";
        %end;
        %if &inclusive = 1 %then %do;
        else if tmp_obs_nr = ref_obs_nr then &new_var = "Y";
        %end;
    run;

    /* Step 5: optional uniqueness check on BY and ORDER variables */
    %if %upcase(&check_type) ne NONE %then %do;

        proc sort data=_tmp_flag out=_dupcheck nodupkey dupout=_dups;
            by &by_vars &order;
        run;

        data _null_;
            if 0 then set _dups nobs=n;
            call symputx('n_dups', n);
            stop;
        run;

        %if &n_dups > 0 %then %do;
            %if %upcase(&check_type) = WARNING %then %do;
                %put WARNING: Duplicate records found for BY variables and ORDER variables.;
            %end;
            %else %do;
                %put ERROR: Duplicate records found for BY variables and ORDER variables.;
                %return;
            %end;
        %end;

    %end;

    /* Step 6: drop temporary variables and write the output */
    data &outdata;
        set _tmp_flag;
        drop tmp_obs_nr ref_obs_nr;
    run;

    proc datasets library=work nolist;
        delete _tmp_sorted _tmp_obs _tmp_ref _tmp_flag
        %if %upcase(&check_type) ne NONE %then %do;
            _dupcheck _dups
        %end;
        ;
    quit;

%mend derive_var_relative_flag;
