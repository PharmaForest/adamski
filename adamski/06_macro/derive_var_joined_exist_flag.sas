/*** HELP START ***/
/*
Macro:
    %derive_var_joined_exist_flag
Purpose:
    Derives a flag variable for an observation based on whether another
    qualifying observation exists within the same BY group.
    The macro compares observations from an input dataset with observations
    from an additional dataset. The additional dataset may be the same as
    the input dataset.
    FILTER_ADD restricts additional observations before joining.
    FILTER_JOIN evaluates the current and joined observations together
    after joining, including variables referenced using the .join suffix.
    The macro can search:
        - observations before the current observation
        - observations after the current observation
        - all other observations within the same BY group
    When the input dataset and additional dataset are the same dataset,
    an observation is not allowed to match itself.
    This macro is conceptually based on the functionality provided by
    admiral::derive_var_joined_exist_flag().
Parameters:
    - `dataset` (required) :
        Input dataset containing the observations for which the flag
        is to be derived.
    - `dataset_add` (optional) :
        Dataset containing observations to be searched for a qualifying
        record.
        If not specified, `dataset` is used.
    - `by_vars` (required) :
        Space-separated list of variables used to match observations
        between `dataset` and `dataset_add`.
        Variables must exist in both datasets and must have the same
        variable type.
        Example:
            by_vars = USUBJID PARAMCD
        generates matching conditions equivalent to:
            a.USUBJID = b.USUBJID
            and
            a.PARAMCD = b.PARAMCD
    - `order` (optional) :
        Space-separated list of variables used to determine whether an
        observation occurs before or after the current observation.
        Required when:
            join_type = before
            join_type = after
        Variables must exist in both datasets and must have the same
        variable type.
        Example:
            order = AVISITN
        Multiple ordering variables are supported.
        Example:
            order = ADT ATM
        Multiple variables are compared lexicographically.
        For:
            order = ADT ATM
        an observation is considered after another observation when:
            b.ADT > a.ADT
        or:
            b.ADT = a.ADT and b.ATM > a.ATM
    - `new_var` (required) :
        Name of the flag variable to be created.
        Example:
            new_var = CONFFL
        If the variable already exists in the input dataset, it is
        overwritten with a warning.
    - `join_type` (optional) :
        Specifies which observations from `dataset_add` are considered.
        Permitted values:
            before
            after
            all
        Default:
            all
        `before`:
            Only observations ordered before the current observation
            are considered.
        `after`:
            Only observations ordered after the current observation
            are considered.
        `all`:
            All other observations in the same BY group are considered.
    - `filter_join` (optional) :
        SAS SQL condition evaluated on each current/joined observation pair.
        Current-record variables use their ordinary names; joined-record
        variables listed in JOIN_VARS use the .join suffix.
        Example:
            filter_join = ADURN > 30 and ACOVFL.join = "Y"
                          and ADY.join <= ADY + 7
    - `join_vars` (optional) :
        Space-separated list of variables from DATASET_ADD that FILTER_JOIN
        references using the .join suffix. These variables must exist in
        DATASET_ADD. Example:
            join_vars = ACOVFL ADY
    - `first_cond_lower` / `first_cond_upper` (optional) :
        SAS condition defining the nearest inclusive boundary for BEFORE/AFTER joins.
        References to JOIN_VARS use the .join suffix.
    - `filter_add` (optional) :
        SAS SQL condition applied to observations from `dataset_add`
        before the join is performed.
        Variable names should be specified normally without table aliases.
        Example:
            filter_add = AVALC = "Y" and ANL01FL = "Y"
    - `true_value` (optional) :
        Value assigned to `new_var` when at least one qualifying joined
        observation exists.
        Character values should be supplied without quotation marks.
        Default:
            Y
    - `false_value` (optional) :
        Value assigned to `new_var` when no qualifying joined observation
        exists.
        Character values should be supplied without quotation marks.
        Default:
            Missing
    - `value_type` (optional) :
        Type of the derived flag variable.
        Permitted values:
            C = Character
            N = Numeric
        Default:
            C
    - `new_var_length` (optional) :
        Length of a character flag variable.
        Default:
            1
        Ignored when `value_type = N`.
    - `outdata` (optional) :
        Output dataset.
        If not specified, the input dataset is overwritten.
R alignment:
    - The following Admiral R parameters are not implemented:
        tmp_obs_nr_var, check_type.
    - tmp_obs_nr_var: R supports order-based temporary observation numbers
      for conditions; SAS currently creates internal row identifiers only.
    - join_vars: Joined-record variables can be referenced with the .join
      suffix in FILTER_JOIN, as in Admiral R. This SAS macro translates
      those references to temporary SAS variable names.
    - first_cond_lower / first_cond_upper: Restrict BEFORE/AFTER joins to
      the nearest qualifying boundary (inclusive).
    - check_type: R controls duplicate BY/ORDER diagnostics; configurable
      duplicate checks are not implemented in this SAS macro.
    - filter_add filters DATASET_ADD before joining; filter_join evaluates
      the current and joined records together. R-specific grouped summary
      functions other than a single ALL(expression) are not implemented.
    - value_type (SAS-specific parameter): This parameter was introduced 
      in the SAS implementation to explicitly control whether the derived 
      flag variable is character (C) or numeric (N). Unlike R, where the 
      output variable type can be inferred from the supplied values, SAS 
      requires the variable type to be established during DATA step 
      compilation. The parameter ensures that true_value and false_value 
      are assigned using the intended SAS variable type, avoiding 
      unintended type conversion or mismatches. This is an 
      implementation-specific addition and does not change the derivation 
      logic or intended alignment with the R function.
    - new_var_length: Sets the SAS character flag length.
    - outdata: Allows the output to be written to a separate SAS dataset.
Notes:
    - FILTER_ADD is applied before joining; FILTER_JOIN is evaluated
      after the join, against each current/joined observation pair.
    - `by_vars` are used only to determine which observations belong to
      the same group.
    - `filter_join` can reference current observations and JOIN_VARS from
      `dataset_add` using the .join suffix.
    - `filter_add` applies only to observations from `dataset_add`.
    - `join_type=before` and `join_type=after` require `order`.
    - When `dataset_add` is the same dataset as `dataset`, the current
      physical observation cannot match itself.
    - One-level dataset names are treated as WORK datasets when determining
      whether `dataset` and `dataset_add` refer to the same dataset.
        Example:
            ADRS
        and:
            WORK.ADRS
        are treated as the same dataset.
    - Other observations having identical BY and ORDER values may still
      qualify because they are physically separate observations.
    - The macro retains only the observation numbers of input records for
      which at least one qualifying joined observation exists.
    - The potentially expanded joined dataset is not returned.
    - For `join_type=all`, all other observations from the matching BY
      group are considered.
    - BY and ORDER variables must have matching character/numeric types
      between `dataset` and `dataset_add`.
    - If `new_var` already exists, it is overwritten in the output dataset.
    - Macro quoting may be required when `filter_join` or `filter_add`
      contains commas.
    - JOIN_VARS must be simple SAS variable names of at most 27 characters
      so the temporary _join suffix fits the SAS 32-character name limit.
    - Do not use input variable names ending in _join for JOIN_VARS, or
      reference joined variables without the .join suffix.
Sample code:
~~~sas
* Test 1: AFTER + self join + character flag ;
data adrs;
    length USUBJID $3 PARAMCD $8 AVALC $2 ANL01FL $1;
    input
        USUBJID $
        PARAMCD $
        AVISITN
        AVALC $
        ANL01FL $
    ;
    datalines;
01 RESP 1 Y Y
01 RESP 2 N Y
01 RESP 3 Y Y
01 RESP 4 N Y
02 RESP 1 Y Y
02 RESP 2 N Y
03 RESP 1 Y N
03 RESP 2 Y Y
;
run;
%derive_var_joined_exist_flag(
    dataset      = adrs,
    by_vars      = USUBJID PARAMCD,
    order        = AVISITN,
    new_var      = CONFFL,
    join_type    = after,
    filter_join = AVALC = "Y" and ANL01FL = "Y",
    filter_add  = AVALC = "Y" and ANL01FL = "Y",
    true_value   = Y,
    false_value  = ,
    outdata      = adrs_out
);
* Test 2: BEFORE + self join + numeric flag ;
data adex;
    length USUBJID $3 ANL01FL $1;
    input
        USUBJID $
        AVISITN
        EXDOSE
        ANL01FL $
    ;
    datalines;
01 1 10 Y
01 2 20 Y
01 3 30 Y
02 1 15 Y
02 2 25 N
03 1 40 Y
;
run;
%derive_var_joined_exist_flag(
    dataset      = adex,
    by_vars      = USUBJID,
    order        = AVISITN,
    new_var      = PREVFL,
    join_type    = before,
    filter_join = ANL01FL = "Y",
    filter_add    = ANL01FL = "Y",
    true_value   = 1,
    false_value  = 0,
    value_type   = N,
    outdata      = adex_out
);
* Test 3: ALL + separate dataset + multiple BY variables ;
data adrs_base;
    length USUBJID $3 PARAMCD $8 AVALC $2;
    input
        USUBJID $
        PARAMCD $
        AVISITN
        AVALC $
    ;
    datalines;
01 RESP 1 PR
01 RESP 2 CR
02 RESP 1 PR
02 RESP 2 SD
03 RESP 1 CR
;
run;
data confirm;
    length USUBJID $3 PARAMCD $8 CONFVAL $2;
    input
        USUBJID $
        PARAMCD $
        CONFVIS
        CONFVAL $
    ;
    datalines;
01 RESP 3 CR
01 RESP 4 CR
02 RESP 3 PR
04 RESP 2 CR
;
run;
%derive_var_joined_exist_flag(
    dataset      = adrs_base,
    dataset_add  = confirm,
    by_vars      = USUBJID PARAMCD,
    new_var      = EXTCONFL,
    join_type    = all,
    filter_join = AVALC = "CR",
    filter_add    = CONFVAL = "CR",
    true_value   = Y,
    false_value  = ,
    outdata      = adrs_confirm
);
* Test 4: Multiple ORDER variables ;
data adtest;
    length USUBJID $3 ANL01FL $1;
    input
        USUBJID $
        ADT :date9.
        ATM :time5.
        ANL01FL $
    ;
    format
        ADT date9.
        ATM time5.
    ;
    datalines;
01 01JAN2025 08:00 Y
01 01JAN2025 10:00 Y
01 02JAN2025 07:00 Y
02 01JAN2025 09:00 Y
;
run;
%derive_var_joined_exist_flag(
    dataset      = adtest,
    by_vars      = USUBJID,
    order        = ADT ATM,
    new_var      = NEXTFL,
    join_type    = after,
    filter_join = ANL01FL = "Y",
    filter_add    = ANL01FL = "Y",
    true_value   = Y,
    false_value  = ,
    outdata      = adtest_out
);
* Test 5: ALL self join - current observation must not match itself ;
data selftest;
    length USUBJID $3 AVALC $2;
    input
        USUBJID $
        AVISITN
        AVALC $
    ;
    datalines;
01 1 CR
02 1 CR
02 2 CR
;
run;
%derive_var_joined_exist_flag(
    dataset      = selftest,
    by_vars      = USUBJID,
    new_var      = CONFFL,
    join_type    = all,
    filter_join = AVALC = "CR",
    filter_add    = AVALC = "CR",
    true_value   = Y,
    false_value  = ,
    outdata      = selftest_out
);

URL:
https://github.com/PharmaForest/adamski
---
Author:                     Manivannan Mathialagan
Latest update Date:         2026-10-18
---
*/
/*** HELP END ***/
%macro derive_var_joined_exist_flag(
    dataset          = ,
    dataset_add      = ,
    by_vars          = ,
    order            = ,
    new_var          = ,
    join_type        = all,
    join_vars        = ,
    filter_add       = ,
    filter_join      = ,
    first_cond_lower = ,
    first_cond_upper = ,
    true_value       = Y,
    false_value      = ,
    value_type       = C,
    new_var_length   = 1,
    outdata          =
);
%local _error _dsid_a _dsid_b _rc _join_type _value_type _nby _norder _i _j _var _varnum_a _varnum_b _vartype_a _vartype_b _by_condition _order_condition _prefix_equal _src _add _src_filtered _add_filtered _src_final _matched _result _new_var_num _lib_a _lib_b _mem_a _mem_b _same_dataset _njoin _join_var _join_filter _join_select _joined _join_name _join_num _src_join_num _boundary_cond _boundary_select _sort_order _all_expr _row_expr _has_all _has_boundary _boundary_mode _all_start _all_end _depth _pos _flen _chr _prefix _suffix _all_text _agg_n _agg_select _agg_columns _parse_error _check_type;
    %let _error = 0;
    /* Temporary dataset names */
    %let _src = work._adsk_jef_src;
    %let _add = work._adsk_jef_add;
    %let _src_filtered = work._adsk_jef_srcf;
    %let _add_filtered = work._adsk_jef_addf;
    %let _src_final = work._adsk_jef_srcfinal;
    %let _matched = work._adsk_jef_match;
    %let _joined = work._adsk_jef_joined;
    %let _result = work._adsk_jef_result;
    /* Check required parameters */
    %if %superq(dataset) = %then
    %do;
        %put ERROR: derive_var_joined_exist_flag: Required parameter dataset is missing.;
        %let _error = 1;
    %end;
    %if %superq(by_vars) = %then
    %do;
        %put ERROR: derive_var_joined_exist_flag: Required parameter by_vars is missing.;
        %let _error = 1;
    %end;
    %if %superq(new_var) = %then
    %do;
        %put ERROR: derive_var_joined_exist_flag: Required parameter new_var is missing.;
        %let _error = 1;
    %end;
    %if &_error = 1 %then
    %do;
        %put ERROR: derive_var_joined_exist_flag: Macro execution stopped due to missing required parameter(s).;
        %return;
    %end;
    /* Default DATASET_ADD */
    %if %superq(dataset_add) = %then
    %do;
        %let dataset_add = &dataset;
    %end;
    /* Default OUTDATA */
    %if %superq(outdata) = %then
    %do;
        %let outdata = &dataset;
    %end;
    /* Standardize parameter values */
    %let _join_type = %lowcase(%superq(join_type));
    %let _value_type = %upcase(%superq(value_type));
    /* Validate JOIN_TYPE */
    %if &_join_type ne before and
        &_join_type ne after and
        &_join_type ne all
    %then
    %do;
        %put ERROR: derive_var_joined_exist_flag: join_type must be BEFORE, AFTER, or ALL.;
        %let _error = 1;
    %end;
    /* Validate VALUE_TYPE */
    %if &_value_type ne C and &_value_type ne N %then
    %do;
        %put ERROR: derive_var_joined_exist_flag: value_type must be C or N.;
        %let _error = 1;
    %end;
    /* Validate character flag length */
    %if &_value_type = C %then
    %do;
        %if %sysevalf(%superq(new_var_length) = , boolean) %then
        %do;
            %put ERROR: derive_var_joined_exist_flag: new_var_length must be specified for a character flag.;
            %let _error = 1;
        %end;
    %end;
    /* ORDER required for BEFORE / AFTER */
    %if (&_join_type = before or
         &_join_type = after)
        and
        %superq(order) =
    %then
    %do;
        %put ERROR: derive_var_joined_exist_flag: ORDER is required when join_type=&join_type..;
        %let _error = 1;
    %end;
    %if &_error = 1 %then
    %do;
        %put ERROR: derive_var_joined_exist_flag: Macro execution stopped due to invalid parameter value(s).;
        %return;
    %end;
    /* Check datasets exist */
    %if not %sysfunc(exist(&dataset)) %then
    %do;
        %put ERROR: derive_var_joined_exist_flag: Input dataset &dataset does not exist.;
        %return;
    %end;
    %if not %sysfunc(exist(&dataset_add)) %then
    %do;
        %put ERROR: derive_var_joined_exist_flag: Additional dataset &dataset_add does not exist.;
        %return;
    %end;
    /* Open datasets */
    %let _dsid_a = %sysfunc(open(&dataset));
    %let _dsid_b = %sysfunc(open(&dataset_add));
    %if &_dsid_a = 0 %then
    %do;
        %put ERROR: derive_var_joined_exist_flag: Unable to open dataset &dataset..;
        %if &_dsid_b > 0 %then
            %let _rc = %sysfunc(close(&_dsid_b));
        %return;
    %end;
    %if &_dsid_b = 0 %then
    %do;
        %put ERROR: derive_var_joined_exist_flag: Unable to open dataset &dataset_add..;
        %let _rc = %sysfunc(close(&_dsid_a));
        %return;
    %end;
    /*------------------------------------------------------------------*/
    /* Determine whether DATASET and DATASET_ADD refer to the same      */
    /* dataset.                                                         */
    /* One-level names are treated as WORK datasets.                    */
    /* Examples:                                                        */
    /* ADRS                                                             */
    /* and                                                              */
    /* WORK.ADRS                                                        */
    /* are treated as the same dataset.                                 */
    /*------------------------------------------------------------------*/
    %let _lib_a = ;
    %let _mem_a = ;
    %let _lib_b = ;
    %let _mem_b = ;
    %if %index(%superq(dataset), .) > 0 %then
    %do;
        %let _lib_a = %upcase( %scan( %superq(dataset), 1, . ) );
        %let _mem_a = %upcase( %scan( %superq(dataset), 2, . ) );
    %end;
    %else
    %do;
        %let _lib_a = WORK;
        %let _mem_a = %upcase(%superq(dataset));
    %end;
    %if %index(%superq(dataset_add), .) > 0 %then
    %do;
        %let _lib_b = %upcase( %scan( %superq(dataset_add), 1, . ) );
        %let _mem_b = %upcase( %scan( %superq(dataset_add), 2, . ) );
    %end;
    %else
    %do;
        %let _lib_b = WORK;
        %let _mem_b = %upcase(%superq(dataset_add));
    %end;
    %let _same_dataset = 0;
    %if &_lib_a = &_lib_b and &_mem_a = &_mem_b %then
    %do;
        %let _same_dataset = 1;
    %end;
    /* Validate BY variables */
    %let _nby = %sysfunc( countw( %superq(by_vars), %str( ) ) );
    %do _i = 1 %to &_nby;
        %let _var = %scan( %superq(by_vars), &_i, %str( ) );
        %let _varnum_a = %sysfunc( varnum( &_dsid_a, &_var ) );
        %let _varnum_b = %sysfunc( varnum( &_dsid_b, &_var ) );
        %if &_varnum_a = 0 %then
        %do;
            %put ERROR: derive_var_joined_exist_flag: BY variable &_var not found in &dataset..;
            %let _error = 1;
        %end;
        %if &_varnum_b = 0 %then
        %do;
            %put ERROR: derive_var_joined_exist_flag: BY variable &_var not found in &dataset_add..;
            %let _error = 1;
        %end;
        /* Verify that BY variable types match. */
        %if &_varnum_a > 0 and &_varnum_b > 0 %then
        %do;
            %let _vartype_a = %sysfunc( vartype( &_dsid_a, &_varnum_a ) );
            %let _vartype_b = %sysfunc( vartype( &_dsid_b, &_varnum_b ) );
            %if &_vartype_a ne &_vartype_b %then
            %do;
                %put ERROR: derive_var_joined_exist_flag: BY variable &_var has different types in &dataset and &dataset_add..;
                %let _error = 1;
            %end;
        %end;
    %end;
    /* Validate ORDER variables */
    %if %superq(order) ne %then
    %do;
        %let _norder = %sysfunc( countw( %superq(order), %str( ) ) );
        %do _i = 1 %to &_norder;
            %let _var = %scan( %superq(order), &_i, %str( ) );
            %let _varnum_a = %sysfunc( varnum( &_dsid_a, &_var ) );
            %let _varnum_b = %sysfunc( varnum( &_dsid_b, &_var ) );
            %if &_varnum_a = 0 %then
            %do;
                %put ERROR: derive_var_joined_exist_flag: ORDER variable &_var not found in &dataset..;
                %let _error = 1;
            %end;
            %if &_varnum_b = 0 %then
            %do;
                %put ERROR: derive_var_joined_exist_flag: ORDER variable &_var not found in &dataset_add..;
                %let _error = 1;
            %end;
            /* Verify that ORDER variable types match. */
            %if &_varnum_a > 0 and &_varnum_b > 0 %then
            %do;
                %let _vartype_a = %sysfunc( vartype( &_dsid_a, &_varnum_a ) );
                %let _vartype_b = %sysfunc( vartype( &_dsid_b, &_varnum_b ) );
                %if &_vartype_a ne &_vartype_b %then
                %do;
                    %put ERROR: derive_var_joined_exist_flag: ORDER variable &_var has different types in &dataset and &dataset_add..;
                    %let _error = 1;
                %end;
            %end;
        %end;
    %end;
    /* Validate JOIN_VARS and protect temporary joined variable names. */
    %let _njoin = %sysfunc(countw(%superq(join_vars), %str( )));
    %do _i = 1 %to &_njoin;
        %let _join_var = %scan(%superq(join_vars), &_i, %str( ));
        %let _join_name = &_join_var._join;
        %let _join_num = %sysfunc(varnum(&_dsid_b, &_join_var));
        %let _src_join_num = %sysfunc(varnum(&_dsid_a, &_join_name));

        %if %length(&_join_var) > 27 or
            %sysfunc(nvalid(&_join_var, V7)) = 0 %then %do;
            %put ERROR: derive_var_joined_exist_flag: Invalid JOIN_VARS name &_join_var..;
            %let _error = 1;
        %end;
        %if &_join_num = 0 %then %do;
            %put ERROR: derive_var_joined_exist_flag: JOIN_VARS variable &_join_var not found in &dataset_add..;
            %let _error = 1;
        %end;
        %if &_src_join_num > 0 %then %do;
            %put ERROR: derive_var_joined_exist_flag: Temporary joined name &_join_name conflicts with an input variable.;
            %let _error = 1;
        %end;
    %end;

    /* Check whether NEW_VAR already exists */
    %let _new_var_num = %sysfunc( varnum( &_dsid_a, &new_var ) );
    %if &_new_var_num > 0 %then
    %do;
        %put WARNING: derive_var_joined_exist_flag: Variable &new_var already exists in &dataset and will be overwritten.;
    %end;
    /* Close datasets */
    %let _rc = %sysfunc( close( &_dsid_a ) );
    %let _rc = %sysfunc( close( &_dsid_b ) );
    %if &_error = 1 %then
    %do;
        %put ERROR: derive_var_joined_exist_flag: Macro execution stopped due to invalid input variable(s).;
        %return;
    %end;
    /* -----------------------------------------------------------------*/
    /* Create working copy of CURRENT dataset.                          */
    /* The existing NEW_VAR, if present, is retained at this point      */
    /* because FILTER_JOIN may reference it.                            */
    /* _adsk_obs_id uniquely identifies each original observation.      */
    /* -----------------------------------------------------------------*/
    data &_src;
        set &dataset;
        _adsk_obs_id = _n_;
    run;
    /* -----------------------------------------------------------------*/
    /* Create working copy of additional dataset.                       */
    /* _adsk_add_obs_id is used to prevent an observation from          */
    /* matching itself when DATASET_ADD is the same dataset.            */
    /* -----------------------------------------------------------------*/
    data &_add;
        set &dataset_add;
        _adsk_add_obs_id = _n_;
    run;
    /* All current records remain eligible until the pairwise join filter. */
    data &_src_filtered;
        set &_src;
    run;

    /* Filter JOINED observations before joining */
    proc sql;
        create table &_add_filtered as
        select *
        from &_add
        %if %superq(filter_add) ne %then
        %do;
            where &filter_add
        %end;
        ;
    quit;
    /* Build BY matching condition */
    %let _by_condition = ;
    %do _i = 1 %to &_nby;
        %let _var = %scan( %superq(by_vars), &_i, %str( ) );
        %if &_i = 1 %then
        %do;
            %let _by_condition = a.&_var = b.&_var;
        %end;
        %else
        %do;
            %let _by_condition = &_by_condition and a.&_var = b.&_var;
        %end;
    %end;
    /* -----------------------------------------------------------------*/
    /* Build ordering condition.                                        */
    /* Multiple ORDER variables are compared lexicographically.         */
    /* Example:                                                         */
    /* ORDER = ADT ATM                                                  */
    /* AFTER:                                                           */
    /* b.ADT > a.ADT                                                    */
    /* OR                                                               */
    /* (                                                                */
    /* b.ADT = a.ADT                                                    */
    /* AND                                                              */
    /* b.ATM > a.ATM                                                    */
    /* )                                                                */
    /* BEFORE is constructed using the corresponding < comparisons.     */
    /*------------------------------------------------------------------*/
    %let _order_condition = ;
    %if &_join_type = before or &_join_type = after %then
    %do;
        %do _i = 1 %to &_norder;
            %let _prefix_equal = ;
            /* All preceding ORDER variables must be equal. */
            %if &_i > 1 %then
            %do;
                %do _j = 1 %to %eval(&_i - 1);
                    %let _var = %scan( %superq(order), &_j, %str( ) );
                    %if &_j = 1 %then
                    %do;
                        %let _prefix_equal = b.&_var = a.&_var;
                    %end;
                    %else
                    %do;
                        %let _prefix_equal = &_prefix_equal and b.&_var = a.&_var;
                    %end;
                %end;
            %end;
            %let _var = %scan( %superq(order), &_i, %str( ) );
            /* AFTER */
            %if &_join_type = after %then
            %do;
                %if &_i = 1 %then
                %do;
                    %let _order_condition = (b.&_var > a.&_var);
                %end;
                %else
                %do;
                    %let _order_condition = &_order_condition or ( &_prefix_equal and b.&_var > a.&_var );
                %end;
            %end;
            /* BEFORE */
            %if &_join_type = before %then
            %do;
                %if &_i = 1 %then
                %do;
                    %let _order_condition = (b.&_var < a.&_var);
                %end;
                %else
                %do;
                    %let _order_condition = &_order_condition or ( &_prefix_equal and b.&_var < a.&_var );
                %end;
            %end;
        %end;
    %end;
    /* Translate joined-variable references into SAS column names. */
    %let _join_filter = %superq(filter_join);
    %let _join_select = ;
    %do _i = 1 %to &_njoin;
        %let _join_var = %scan(%superq(join_vars), &_i, %str( ));
        %let _join_select = &_join_select, b.&_join_var as &_join_var._join;
        %let _join_filter = %sysfunc(tranwrd(%superq(_join_filter), &_join_var..join, &_join_var._join));
        %let _join_filter = %sysfunc(tranwrd(%superq(_join_filter), &_join_var..JOIN, &_join_var._join));
    %end;

    /* Translate boundary conditions and include joined ORDER columns. */
    %let _boundary_cond = ;
    %let _boundary_mode = ;
    %if %superq(first_cond_lower) ne %then %do;
        %if &_join_type ne before %then %do;
            %put ERROR: first_cond_lower requires join_type=before.;
            %return;
        %end;
        %let _boundary_cond = %superq(first_cond_lower);
        %let _boundary_mode = lower;
    %end;
    %if %superq(first_cond_upper) ne %then %do;
        %if &_join_type ne after or %superq(_boundary_mode) ne %then %do;
            %put ERROR: first_cond_upper requires join_type=after and cannot be combined with first_cond_lower.;
            %return;
        %end;
        %let _boundary_cond = %superq(first_cond_upper);
        %let _boundary_mode = upper;
    %end;
    %if %superq(_boundary_mode) ne %then %do;
        %do _i = 1 %to &_njoin;
            %let _join_var = %scan(%superq(join_vars), &_i, %str( ));
            %let _boundary_cond = %sysfunc(tranwrd(%superq(_boundary_cond), &_join_var..join, &_join_var._join));
            %let _boundary_cond = %sysfunc(tranwrd(%superq(_boundary_cond), &_join_var..JOIN, &_join_var._join));
        %end;
    %end;
    %let _boundary_select = , b._adsk_add_obs_id;
    %let _sort_order = _adsk_obs_id;
    %if %superq(_boundary_mode) ne %then %do;
        %do _i = 1 %to &_norder;
            %let _var = %scan(%superq(order), &_i, %str( ));
            %let _boundary_select = &_boundary_select, b.&_var as _adsk_ord&_i;
            %if &_boundary_mode = lower %then %let _sort_order = &_sort_order descending _adsk_ord&_i;
            %else %let _sort_order = &_sort_order _adsk_ord&_i;
        %end;
    %end;
    /* Parse grouped predicates in FILTER_JOIN, preserving nested arguments. */
    %let _agg_n = 0;
    %let _agg_select = ;
    %let _agg_columns = ;
    %let _parse_error = 0;
    %let _row_expr = %superq(_join_filter);
    data _null_;
        length src rewritten func args part var cond val expression selection prefix suffix $32767;
        length ch quote $1;
        src = symget('_join_filter');
        n = 0;
        do until (done);
            done = 1;
            start = 0;
            /* Locate the leftmost supported grouped function. */
            rx = prxparse('/\b(all|any|count_vals|min_cond|max_cond)\s*\(/i');
            if prxmatch(rx,src) then do;
                call prxsubstr(rx,src,start,matched_length);
                func = lowcase(strip(scan(substr(src,start,matched_length),1,' (')));
                openpos = start + matched_length - 1;
                depth = 1;
                quote = ' ';
                finish = 0;
                do i = openpos + 1 to lengthn(src);
                    ch = substr(src,i,1);
                    if quote ne ' ' then do;
                        if ch = quote then quote = ' ';
                    end;
                    else if ch in ('"',"'") then quote = ch;
                    else if ch = '(' then depth + 1;
                    else if ch = ')' then do;
                        depth + (-1);
                        if depth = 0 then do;
                            finish = i;
                            leave;
                        end;
                    end;
                end;
                if finish = 0 then do;
                    put 'ERROR: [derive_var_joined_exist_flag] Unbalanced grouped function: ' func;
                    call symputx('_parse_error',1,'L');
                    stop;
                end;
                args = strip(substr(src,openpos+1,finish-openpos-1));
                n + 1;
                var = ''; cond = ''; val = '';
                if func in ('all','any') then do;
                    if func = 'all' then expression = cats('min(case when (',args,') then 1 else 0 end)');
                    else expression = cats('max(case when (',args,') then 1 else 0 end)');
                end;
                else do;
                    /* Named arguments are split at top-level commas only. */
                    depth = 0; quote = ' '; piece_start = 1;
                    do i = 1 to lengthn(args)+1;
                        if i > lengthn(args) then ch = ',';
                        else ch = substr(args,i,1);
                        if quote ne ' ' then do;
                            if ch = quote then quote = ' ';
                        end;
                        else if ch in ('"',"'") then quote = ch;
                        else if ch = '(' then depth + 1;
                        else if ch = ')' then depth + (-1);
                        else if ch = ',' and depth = 0 then do;
                            part = strip(substr(args,piece_start,i-piece_start));
                            eq = index(part,'=');
                            if eq > 0 then do;
                                selection = lowcase(strip(substr(part,1,eq-1)));
                                if selection = 'var' then var = strip(substr(part,eq+1));
                                else if selection = 'val' then val = strip(substr(part,eq+1));
                                else if selection = 'cond' then cond = strip(substr(part,eq+1));
                            end;
                            piece_start = i + 1;
                        end;
                    end;
                    if missing(var) or (func = 'count_vals' and missing(val)) or (func ne 'count_vals' and missing(cond)) then do;
                        put 'ERROR: [derive_var_joined_exist_flag] Missing named argument for ' func;
                        call symputx('_parse_error',1,'L');
                        stop;
                    end;
                    if func = 'count_vals' then expression = cats('sum(case when (',var,' = ',val,') then 1 else 0 end)');
                    else if func = 'min_cond' then expression = catx(' ',cats('min(case when (',cond,')'),'then',var,'else . end)');
                    else expression = catx(' ',cats('max(case when (',cond,')'),'then',var,'else . end)');
                end;
                call symputx(cats('_adsk_ag_expr',n),expression,'L');
                prefix = ''; suffix = '';
                if start > 1 then prefix = substr(src,1,start-1);
                if finish < lengthn(src) then suffix = substr(src,finish+1);
                rewritten = catx(' ',trimn(prefix),cats('_adsk_ag',n),strip(suffix));
                if rewritten = src or n > 100 then do;
                    put 'ERROR: [derive_var_joined_exist_flag] Grouped predicate parser made no progress.';
                    call symputx('_parse_error',1,'L');
                    stop;
                end;
                src = rewritten;
                done = 0;
            end;
            call prxfree(rx);
        end;
        /* R parity: missing grouped extrema must not satisfy SAS numeric comparisons.
           Guard comparisons between grouped results before SQL WHERE evaluation.
           In SAS, 12 > . is true; in R, 12 > NA is NA and filter() drops it. */
        rx_compare = prxparse('/\b(_adsk_ag\d+)\s*(>=|<=|<>|!=|~=|=|>|<)\s*(_adsk_ag\d+)\b/i');
        if prxmatch(rx_compare,src) then
            src = prxchange('s/\b(_adsk_ag\d+)\s*(>=|<=|<>|!=|~=|=|>|<)\s*(_adsk_ag\d+)\b/((not missing($1)) and (not missing($3)) and ($1 $2 $3))/i',-1,src);
        call prxfree(rx_compare);
        call symputx('_row_expr',src,'L');
        call symputx('_agg_n',n,'L');
    run;
    %if &_parse_error %then %return;
    %do _i = 1 %to &_agg_n;
        %let _agg_select = &_agg_select, &&_adsk_ag_expr&_i as _adsk_ag&_i;
        %let _agg_columns = &_agg_columns, b._adsk_ag&_i;
    %end;
    /* Join current and additional observations within the BY group. */
    proc sql;
        create table &_joined as
        select a.* &_join_select &_boundary_select
        from &_src_filtered as a
        inner join &_add_filtered as b
            on &_by_condition
            %if &_same_dataset = 1 %then %do;
                and a._adsk_obs_id ne b._adsk_add_obs_id
            %end;
            %if &_join_type = before or &_join_type = after %then %do;
                and (&_order_condition)
            %end;
        ;
    quit;

    /* Limit the joined window to the nearest qualifying boundary, inclusive. */
    %if %superq(_boundary_mode) ne %then %do;
        proc sort data=&_joined;
            by &_sort_order;
        run;
        data work._adsk_jef_window;
            set &_joined;
            by _adsk_obs_id;
            retain _adsk_stopped;
            if first._adsk_obs_id then _adsk_stopped = 0;
            if not _adsk_stopped then do;
                _adsk_boundary_hit = (&_boundary_cond);
                output;
                if _adsk_boundary_hit then _adsk_stopped = 1;
            end;
        run;
        /* A window without a boundary does not qualify. */
        proc sql;
            create table work._adsk_jef_valid as
            select _adsk_obs_id
            from work._adsk_jef_window
            group by _adsk_obs_id
            having max(_adsk_boundary_hit) = 1;
            create table work._adsk_jef_eval as
            select a.* from work._adsk_jef_window as a
            inner join work._adsk_jef_valid as b
                on a._adsk_obs_id = b._adsk_obs_id;
        quit;
    %end;
    %else %do;
        data work._adsk_jef_eval;
            set &_joined;
        run;
    %end;
    /* Aggregate grouped helpers over the entire bounded window. */
    %if &_agg_n > 0 %then %do;
        proc sql;
            create table work._adsk_jef_agg as
            select _adsk_obs_id &_agg_select
            from work._adsk_jef_eval
            group by _adsk_obs_id;
            create table work._adsk_jef_eval2 as
            select a.* &_agg_columns
            from work._adsk_jef_eval as a
            inner join work._adsk_jef_agg as b
            on a._adsk_obs_id = b._adsk_obs_id;
        quit;
    %end;
    %else %do;
        data work._adsk_jef_eval2;
            set work._adsk_jef_eval;
        run;
    %end;
    proc sql;
        create table &_matched as
        select distinct _adsk_obs_id
        from work._adsk_jef_eval2
        %if %superq(_row_expr) ne %then %do;
            where %unquote(&_row_expr)
        %end;
        ;
    quit;
    /* -----------------------------------------------------------------*/
    /* Create source used for final output.                             */
    /*                                                                  */          
    /* Remove existing NEW_VAR only after FILTER_JOIN and FILTER_ADD    */
    /* have already been evaluated.                                     */
    /*------------------------------------------------------------------*/
    data &_src_final;
        set &_src
            %if &_new_var_num > 0 %then
            %do;
                (drop=&new_var)
            %end;
        ;
    run;
    /* -----------------------------------------------------------------*/
    /* Merge existence result back to complete original dataset and     */
    /* derive NEW_VAR.                                                  */
    /*------------------------------------------------------------------*/
    proc sql;
        create table &_result as
        select
            a.*
            /* Character flag */
            %if &_value_type = C %then
            %do;
                ,
                case
                    when not missing(b._adsk_obs_id)
                    then
                        "&true_value"
                    else
                        "&false_value"
                end
                as &new_var
                length=&new_var_length
            %end;
            /* Numeric flag */
            %else
            %if &_value_type = N %then
            %do;
                ,
                case
                    when not missing(b._adsk_obs_id)
                    then
                        &true_value
                    else
                        %if %superq(false_value) = %then
                        %do;
                            .
                        %end;
                        %else
                        %do;
                            &false_value
                        %end;
                end
                as &new_var
            %end;
        from &_src_final as a
        left join &_matched as b
            on
                a._adsk_obs_id = b._adsk_obs_id
        order by
            a._adsk_obs_id
        ;
    quit;
    /* Create final output and remove temporary observation ID. */
    data &outdata;
        set &_result;
        drop _adsk_obs_id ;
    run;
    /* Clean temporary datasets */
    proc datasets library = work nolist nowarn ;
        delete _adsk_jef_src _adsk_jef_add _adsk_jef_srcf _adsk_jef_addf
               _adsk_jef_srcfinal  _adsk_jef_match  _adsk_jef_result
               _adsk_jef_joined _adsk_jef_window _adsk_jef_valid _adsk_jef_eval _adsk_jef_agg _adsk_jef_eval2
        ;
    quit;
    /* Completion message */
    %if %sysfunc(exist(&outdata)) %then %do;
        %put NOTE: derive_var_joined_exist_flag: Output dataset &outdata was created.;
    %end;
    %else %do;
        %put ERROR: derive_var_joined_exist_flag: Output dataset &outdata was not created.;
    %end;
%mend derive_var_joined_exist_flag;
