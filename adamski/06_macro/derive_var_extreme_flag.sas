/*** HELP START ***//*

### Macro:
    %derive_var_extreme_flag

### Purpose:
    Derive a flag for the first or last observation within each
    BY group based on the specified ORDER variables.  

### Parameters:  

 - 'dataset' (required) : input dataset 	
 - 'by_vars' (required) : grouping variables
 - 'order' (required) : sorting variables
 - 'new_var' (required) : output flag variable
 - 'mode' (required) : FIRST or LAST 	
 - 'true_value' (required, default=Y) : value assigned to flagged record(s)
 - 'false_value' (optional) : value assigned to non-flagged records
 - 'flag_all' (optional, default=0) : 1 to flag all tied extreme records
 - 'check_type' (optional) : NONE | WARNING | ERROR	
 - 'outdata' (optional, default=&dataset._extreme) : output dataset name

### Sample code:

~~~sas


data advs;
    length USUBJID $10 PARAMCD $10 AVISIT $20 STUDYID $10;
    informat ADT yymmdd10.;
    format ADT yymmdd10.;

    infile datalines dsd dlm=',' truncover;
    input USUBJID $ PARAMCD $ AVISIT $ ADT :yymmdd10. AVAL;
    STUDYID = "AB123";
datalines;
1015,TEMP,BASELINE,2021-04-27,38.0
1015,TEMP,BASELINE,2021-04-25,39.0
1015,TEMP,WEEK 2,2021-05-10,37.5
1015,WEIGHT,SCREENING,2021-04-19,81.2
1015,WEIGHT,BASELINE,2021-04-25,82.7
1015,WEIGHT,BASELINE,2021-04-27,84.0
1015,WEIGHT,WEEK 2,2021-05-09,82.5
1023,TEMP,SCREENING,2021-04-27,38.0
1023,TEMP,BASELINE,2021-04-28,37.5
1023,TEMP,BASELINE,2021-04-29,37.5
1023,TEMP,WEEK 1,2021-05-03,37.0
1023,WEIGHT,SCREENING,2021-04-27,69.6
1023,WEIGHT,BASELINE,2021-04-29,67.2
1023,WEIGHT,WEEK 1,2021-05-02,65.9
;
run;


data adae;
    length USUBJID $10 AEBODSYS $30 AEDECOD $20 AESEV $10 STUDYID $10;
    infile datalines dsd dlm=',' truncover;
    input USUBJID $ AEBODSYS :$30. AEDECOD :$20. AESEV $ AESTDY AESEQ;
    STUDYID = "AB123";
datalines;
1015,GENERAL DISORDERS,ERYTHEMA,MILD,2,1
1015,GENERAL DISORDERS,PRURITUS,MILD,2,2
1015,GI DISORDERS,DIARRHOEA,MILD,8,3
1023,CARDIAC DISORDERS,AV BLOCK,MILD,22,4
1023,SKIN DISORDERS,ERYTHEMA,MILD,3,1
1023,SKIN DISORDERS,ERYTHEMA,SEVERE,5,2
1023,SKIN DISORDERS,ERYTHEMA,MILD,8,3
;
run;


**Example1: flag last observation within each group;	
%derive_var_extreme_flag(
	    dataset=advs,
	    by_vars=STUDYID USUBJID PARAMCD,
	    order=ADT,
	    new_var=LASTFL,
	    mode=last,
	    true_value=Y,
	    false_value=,
	    flag_all=0,
	    check_type=warning,
	    outdata=advs_lastfl
);


**Example2: flag first observation;
%derive_var_extreme_flag(
	    dataset=advs,
	    by_vars=STUDYID USUBJID PARAMCD,
	    order=ADT,
	    new_var=FIRSTFL,
	    mode=first,
	    true_value=Y,
	    false_value=,
	    flag_all=0,
	    check_type=warning,
	    outdata=advs_firstfl
);


**Example3: custom flag values;	
%derive_var_extreme_flag(
	    dataset=advs,
	    by_vars=STUDYID USUBJID PARAMCD,
	    order=ADT,
	    new_var=LASTFL,
	    mode=last,
	    true_value=Yes,
	    false_value=No,
	    flag_all=0,
	    check_type=warning,
	    outdata=advs_lastfl_custom
);


**Example4: AOCCIFL derivation with severity ordering;
data adae2;
    set adae;

    **Convert AESEV into numeric severity ranking:SEVERE=1, MODERATE=2, MILD=3; 
    if upcase(AESEV) = "SEVERE" then TEMP_AESEVN = 1;
    else if upcase(AESEV) = "MODERATE" then TEMP_AESEVN = 2;
    else if upcase(AESEV) = "MILD" then TEMP_AESEVN = 3;
run;
	
%derive_var_extreme_flag(
	    dataset=adae2,
	    by_vars=STUDYID USUBJID,
	    order=TEMP_AESEVN AESTDY AESEQ,
	    new_var=AOCCIFL,
	    mode=first,
	    true_value=Y,
	    false_value=,
	    flag_all=0,
	    check_type=warning,
	    outdata=adae_aoccifl
);



**Example5: flag_all = 1 - This corresponds to flagging all tied records at the extreme. ;
data adae3;
    set adae;
    if upcase(AESEV) = "SEVERE" then TEMP_AESEVN = 1;
    else if upcase(AESEV) = "MODERATE" then TEMP_AESEVN = 2;
    else if upcase(AESEV) = "MILD" then TEMP_AESEVN = 3;
run;
	
	
%derive_var_extreme_flag(
	    dataset=adae3,
	    by_vars=STUDYID USUBJID,
	    order=TEMP_AESEVN AESTDY,
	    new_var=AOCCIFL,
	    mode=first,
	    flag_all=1,
	    true_value=Y,
	    false_value=,
	    check_type=warning,
	    outdata=adae_aoccifl_all
);
	

**Example6: baseline flag for baseline visits only.;
data advs_base;
    set advs;
    if AVISIT = "BASELINE";
run;
	
	
%derive_var_extreme_flag(
	    dataset=advs_base,
	    by_vars=STUDYID USUBJID PARAMCD,
	    order=ADT,
	    new_var=ABLFL,
	    mode=last,
	    true_value=Y,
	    false_value=,
	    flag_all=0,
	    check_type=warning,
	    outdata=advs_ablfl
);


**Example7: parameter-specific baseline logic.;
data advs_temp advs_weight;
    set advs;
    if AVISIT = "BASELINE" and PARAMCD = "TEMP" then output advs_temp;
    else if AVISIT = "BASELINE" and PARAMCD = "WEIGHT" then output advs_weight;
run;
	
**TEMP: lowest value, latest if tied;
%derive_var_extreme_flag(
	    dataset=advs_temp,
	    by_vars=STUDYID USUBJID PARAMCD,
	    order=descending AVAL ADT,
	    new_var=ABLFL,
	    mode=last,
	    true_value=Y,
	    false_value=,
	    flag_all=0,
	    check_type=warning,
	    outdata=advs_temp_ablfl
);


**WEIGHT: highest value, latest if tied;
%derive_var_extreme_flag(
	    dataset=advs_weight,
	    by_vars=STUDYID USUBJID PARAMCD,
	    order=AVAL ADT,
	    new_var=ABLFL,
	    mode=last,
	    true_value=Y,
	    false_value=,
	    flag_all=0,
	    check_type=warning,
	    outdata=advs_weight_ablfl
);

  
~~~

### Notes:


### URL:

https://github.com/PharmaForest/adamski

---

Author:          	    Sharad Chhetri
Latest udpate Date: 	2026-06-25

---

*//*** HELP END ***/


%macro derive_var_extreme_flag(
    dataset=,
    by_vars=,
    order=,
    new_var=,
    mode=,
    true_value=Y,
    false_value=,
    flag_all=0,
    check_type=warning,
    outdata=
);


    %local _mode _check_type _flag_all;
    %let _mode = %upcase(&mode);
    %let _check_type = %upcase(&check_type);
    %let _flag_all = %upcase(&flag_all);

    /* check required parameters */
    %if %superq(dataset)= or %superq(by_vars)= or %superq(order)= or %superq(new_var)= or %superq(mode)= %then %do;
      %put ERROR: Required parameters missing. dataset=, by_vars=, order=, new_var=, mode= are required.;
      %abort cancel;
    %end;


    /* If OUTDATA not provided, set new dataset name */
    %if %superq(outdata)= %then %let outdata = &dataset._extreme;


    /*------------------------------------------------------------
      Step 1: Create a temporary observation number within each BY group
      according to the requested ORDER variables.
      This mimics derive_var_obs_number().
    ------------------------------------------------------------*/
    proc sort data=&dataset out=_tmp_sorted;
        by &by_vars &order;
    run;

    data _tmp_obs;
        set _tmp_sorted;
        by &by_vars &order;

        /* Temporary observation number within BY group */
        retain tmp_obs_nr;

        if first.%scan(&by_vars, -1) then tmp_obs_nr = 0;
        tmp_obs_nr + 1;
    run;

    /*------------------------------------------------------------
      Step 2: Flag the first or last observation.
      - mode = FIRST: flag tmp_obs_nr = 1
      - mode = LAST : flag last record within BY group
    ------------------------------------------------------------*/
    data _tmp_flag;
        set _tmp_obs;
        by &by_vars;

        length &new_var $20;

        /* Default value for non-flagged records */
        if missing("&false_value") then &new_var = "";
        else &new_var = "&false_value";

        if upcase("&_mode") = "FIRST" then do;
            if tmp_obs_nr = 1 then &new_var = "&true_value";
        end;
        else if upcase("&_mode") = "LAST" then do;
            /* Need total count per BY group for last-observation logic */
            /* This is handled in a second pass below */
        end;
    run;

    /*------------------------------------------------------------
      Step 3: If mode=LAST, determine last observation in each BY group.
      We use a two-pass approach to avoid relying on descending logic.
    ------------------------------------------------------------*/
    %if &_mode = LAST %then %do;
		
		/* Create group counts - number of records in the group */
		data _tmp_counts;
		    set _tmp_flag;
		    by &by_vars;
		
		    retain _n_in_group;
		
		    /* Start count at 1 for the first record in each BY group */
		    if first.%scan(&by_vars, -1) then _n_in_group = 0;
		    _n_in_group + 1;
		
		    /* Output only the last record in each BY group with the final count */
		    if last.%scan(&by_vars, -1) then output;
		run;

        proc sort data=_tmp_flag;
            by &by_vars;
        run;

        proc sort data=_tmp_counts;
            by &by_vars;
        run;

        data _tmp_flag;
            merge _tmp_flag(in=a) _tmp_counts;
            by &by_vars;
            if a;

            if tmp_obs_nr = _n_in_group then &new_var = "&true_value";
        run;
    %end;

    /*------------------------------------------------------------
      Step 4: If flag_all=1, flag all tied extreme records.
      Ties are propagated across records sharing the same BY + ORDER values.
    ------------------------------------------------------------*/
    %if %eval(&flag_all=1) %then %do;

        proc sort data=_tmp_flag;
            by &by_vars &order;
        run;

        data _tmp_flag;
            set _tmp_flag;
            by &by_vars &order;

            retain _last_flag;
            length _last_flag $20;

            if first.%scan(&order, 1) then _last_flag = &new_var;

            /* Propagate flag across tied records */
            if missing(&new_var) or &new_var = "" then &new_var = _last_flag;
            else _last_flag = &new_var;
        run;
    %end;

    /*------------------------------------------------------------
      Step 5: Optional uniqueness check.
      Detect duplicates across BY + ORDER.
      If check_type = WARNING or ERROR, issue a message when duplicates exist.
    ------------------------------------------------------------*/
    %if %upcase(&check_type) ne NONE %then %do;

        proc sort data=_tmp_flag out=_dupcheck nodupkey dupout=_dups;
            by &by_vars &order;
        run;

        data _null_;
            if 0 then set _dups nobs=n;
            call symputx('n_dups', n);
            stop;
        run;

        %if %sysevalf(&n_dups > 0) %then %do;
            %if &_check_type = WARNING %then %do;
                %put WARNING: Duplicate records found for BY variables and ORDER variables.;
            %end;
            %else %if &_check_type = ERROR %then %do;
                %put ERROR: Duplicate records found for BY variables and ORDER variables.;
                %abort cancel;
            %end;
        %end;

    %end;

    /*------------------------------------------------------------
      Step 6: Remove temporary variables and write final output
    ------------------------------------------------------------*/
    data &outdata;
        set _tmp_flag;
        drop tmp_obs_nr 
        %if &_mode = LAST %then %do;
          _n_in_group 
        %end;
        %if %eval(&flag_all=1) %then %do;
          _last_flag
        %end;
        ;
    run;

    proc datasets library=work nolist;
        delete _tmp_sorted _tmp_obs _tmp_flag _tmp_counts _dupcheck _dups;
    quit;

%mend derive_var_extreme_flag;
