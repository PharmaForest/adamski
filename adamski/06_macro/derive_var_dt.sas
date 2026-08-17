/*** HELP START ***//*

### Macro:

    %derive_vars_dt

### Purpose:

    Derives a numeric SAS date variable from a character ISO 8601 date
    or datetime variable.

    The macro supports partial date imputation and can optionally derive
    the corresponding date imputation flag variable.

    The output date variable is created by appending `DT` to the value
    supplied in `new_vars_prefix`.

    If a date imputation flag is requested, the flag variable is created
    by appending `DTF` to `new_vars_prefix`.

    Example:

    new_vars_prefix = AST

    creates:

    ASTDT
    ASTDTF

### Parameters:

    - `dataset` (required) :
        Name of the input dataset.

    - `new_vars_prefix` (required) :
        Prefix used for the derived date and date imputation flag variables.

        Example:

            new_vars_prefix = AST

        creates:

            ASTDT
            ASTDTF

    - `dtc` (required) :
        Character ISO 8601 date or datetime variable used to derive the
        numeric SAS date.

        Examples:

            2019-07-18
            2019-07-18T15:25:40
            2019-07
            2019
            2019---07

    - `highest_imputation` (optional) :
        Highest date component allowed to be imputed.

        Permitted values:

            n = No imputation
            D = Day imputation
            M = Month and day imputation
            Y = Year, month and day imputation

        Default:

            n

    - `date_imputation` (optional) :
        Specifies the date component values used for imputation.

        Permitted values:

            first
            mid
            last
            MM-DD

        Examples:

            first
            mid
            last
            04-06

        Default:

            first

        For `mid`:

            Missing day only:
                Day = 15

            Missing month and day:
                Month = 06
                Day   = 30

        For a user-defined value such as `04-06`:

            Missing day only:
                Day = 06

            Missing month and day:
                Month = 04
                Day   = 06

    - `flag_imputation` (optional) :
        Controls creation of the date imputation flag variable.

        Permitted values:

            auto
            date
            none

        `auto`:
            Creates the DTF variable when `highest_imputation` is not `n`.

        `date`:
            Always creates the DTF variable.

        `none`:
            Does not create the DTF variable.

        Default:

            auto

    - `min_dates` (optional) :
        Space-separated list of numeric SAS date or datetime variables.

        The derived/imputed date will not be moved before an applicable
        minimum date.

        Only minimum dates that fall within the possible date range of
        the original partial DTC value are considered.

        Example:

            min_dates = TRTSDT

        or:

            min_dates = TRTSDT RANDDT

    - `max_dates` (optional) :
        Space-separated list of numeric SAS date or datetime variables.

        The derived/imputed date will not be moved after an applicable
        maximum date.

        Only maximum dates that fall within the possible date range of
        the original partial DTC value are considered.

    - `preserve` (optional) :
        Controls whether lower-level date components are preserved when
        a higher-level component is missing.

        Permitted values:

            Y
            N

        Default:

            N

        Example:

            DTC = 2019---07
            date_imputation = mid

            preserve = N  -> 30JUN2019
            preserve = Y  -> 07JUN2019

    - `outdata` (optional) :
        Name of the output dataset.

        If not provided, the input dataset is overwritten.

        This is an additional optional parameter in Adamski.

### Output:

    - Input dataset with the derived `*DT` variable appended.
    - The `*DTF` variable is also appended when requested.

### Date Imputation Flags:

    D :
        Day was imputed.

    M :
        Month was imputed.

    Y :
        Year was imputed.

    Missing :
        No date imputation was performed.

### Notes:

    - Complete ISO dates are converted directly to numeric SAS dates.
    - The time portion of a complete ISO datetime is ignored.
    - If `highest_imputation = n`, partial dates result in a missing
      derived date.
    - If `highest_imputation = D`, only missing days can be imputed.
    - If `highest_imputation = M`, missing months and days can be imputed.
    - If `highest_imputation = Y`, year imputation requires an applicable
      minimum or maximum date.
    - Existing derived DT or DTF variables are overwritten with a warning.
    - Numeric SAS dates are stored using DATE9. format.
    - `min_dates` and `max_dates` may contain SAS date or datetime variables.
    - No permanent intermediate variables are created by this macro.

### Sample code:

~~~sas

data mhdt;
    length USUBJID $12 MHSTDTC $25;
    input USUBJID $ MHSTDTC $;
    datalines;
SUBJ-001 2019-07-18T15:25:40
SUBJ-002 2019-07-18
SUBJ-003 2019-02
SUBJ-004 2019
SUBJ-005 2019---07
SUBJ-006
;
run;


## No imputation

%derive_vars_dt(
    dataset         = mhdt,
    new_vars_prefix = AST,
    dtc             = MHSTDTC
    );


## Impute missing month/day to first possible date

%derive_vars_dt(
    dataset            = mhdt,
    new_vars_prefix    = AST,
    dtc                = MHSTDTC,
    highest_imputation = M,
    date_imputation    = first,
    outdata            = mhdt_first
    );


## Impute to middle

%derive_vars_dt(
    dataset            = mhdt,
    new_vars_prefix    = AST,
    dtc                = MHSTDTC,
    highest_imputation = M,
    date_imputation    = mid,
    outdata            = mhdt_mid
    );


## Impute to last possible date

%derive_vars_dt(
    dataset            = mhdt,
    new_vars_prefix    = AEN,
    dtc                = MHSTDTC,
    highest_imputation = M,
    date_imputation    = last,
    outdata            = mhdt_last
    );


## User-defined month/day

%derive_vars_dt(
    dataset            = mhdt,
    new_vars_prefix    = AST,
    dtc                = MHSTDTC,
    highest_imputation = M,
    date_imputation    = 04-06,
    outdata            = mhdt_custom
    );


## Suppress date imputation flag

%derive_vars_dt(
    dataset            = mhdt,
    new_vars_prefix    = AST,
    dtc                = MHSTDTC,
    highest_imputation = M,
    date_imputation    = mid,
    flag_imputation    = none,
    outdata            = mhdt_noflag
    );


## Preserve known day when month is missing

%derive_vars_dt(
    dataset            = mhdt,
    new_vars_prefix    = AST,
    dtc                = MHSTDTC,
    highest_imputation = M,
    date_imputation    = mid,
    preserve           = Y,
    outdata            = mhdt_preserve
    );


## Minimum date restriction

data adae;
    length AESTDTC $25;
    input AESTDTC $ TRTSDT :date9.;
    format TRTSDT date9.;
    datalines;
2020-12 06DEC2020
2020-11 06DEC2020
;
run;

%derive_vars_dt(
    dataset            = adae,
    new_vars_prefix    = AST,
    dtc                = AESTDTC,
    highest_imputation = M,
    date_imputation    = first,
    min_dates          = TRTSDT,
    outdata            = adae_dt
    );

~~~

### URL:

https://github.com/PharmaForest/adamski

---
Author:                     Manivannan Mathialagan
Latest update Date:         2026-08-17
---

*//*** HELP END ***/
%macro derive_vars_dt(
    dataset            = ,
    new_vars_prefix    = ,
    dtc                = ,
    highest_imputation = n,
    date_imputation    = first,
    flag_imputation    = auto,
    min_dates          = ,
    max_dates          = ,
    preserve           = N,
    outdata            =
);

    %local
        _error
        _dsid
        _rc
        _dtc_num
        _dtc_type
        _dt_num
        _dtf_num
        _dtvar
        _dtfvar
        _highest
        _dateimp
        _flagimp
        _preserve
        _create_flag
        _custom_month
        _custom_day
        _custom_month_txt
        _custom_day_txt
        _nmin
        _nmax
        _i
        _var
        _varnum
        _vartype
        _allow_day
        _allow_month
        _allow_year
    ;

    %let _error = 0;

    /*--------------------------------------------------------------*
     * Check required parameters
     *--------------------------------------------------------------*/

    %if %superq(dataset) = %then
    %do;
        %put ERROR: derive_vars_dt: Required parameter dataset is missing.;
        %let _error = 1;
    %end;

    %if %superq(new_vars_prefix) = %then
    %do;
        %put ERROR: derive_vars_dt: Required parameter new_vars_prefix is missing.;
        %let _error = 1;
    %end;

    %if %superq(dtc) = %then
    %do;
        %put ERROR: derive_vars_dt: Required parameter dtc is missing.;
        %let _error = 1;
    %end;

    %if &_error = 1 %then
    %do;
        %put ERROR: derive_vars_dt: Macro execution stopped due to missing required parameter(s).;
        %return;
    %end;


    /*--------------------------------------------------------------*
     * Standardize parameter values
     *--------------------------------------------------------------*/

    %let _highest = %upcase(%superq(highest_imputation));
    %let _dateimp = %lowcase(%superq(date_imputation));
    %let _flagimp = %lowcase(%superq(flag_imputation));
    %let _preserve = %upcase(%superq(preserve));

    %let _dtvar  = &new_vars_prefix.DT;
    %let _dtfvar = &new_vars_prefix.DTF;


    /*--------------------------------------------------------------*
     * Default output dataset
     *--------------------------------------------------------------*/

    %if %superq(outdata) = %then
    %do;
        %let outdata = &dataset;
    %end;


    /*--------------------------------------------------------------*
     * Validate highest_imputation
     *--------------------------------------------------------------*/

    %if &_highest ne N and
        &_highest ne D and
        &_highest ne M and
        &_highest ne Y
    %then
    %do;
        %put ERROR: derive_vars_dt: highest_imputation must be n, D, M, or Y.;
        %let _error = 1;
    %end;


    /*--------------------------------------------------------------*
     * Validate flag_imputation
     *--------------------------------------------------------------*/

    %if &_flagimp ne auto and
        &_flagimp ne date and
        &_flagimp ne none
    %then
    %do;
        %put ERROR: derive_vars_dt: flag_imputation must be auto, date, or none.;
        %let _error = 1;
    %end;


    /*--------------------------------------------------------------*
     * Validate preserve
     *--------------------------------------------------------------*/

    %if &_preserve ne Y and &_preserve ne N %then
    %do;
        %put ERROR: derive_vars_dt: preserve must be Y or N.;
        %let _error = 1;
    %end;


    /*--------------------------------------------------------------*
     * Set allowed imputation levels
     *--------------------------------------------------------------*/

    %let _allow_day   = 0;
    %let _allow_month = 0;
    %let _allow_year  = 0;

    %if &_highest = D %then
    %do;
        %let _allow_day = 1;
    %end;

    %if &_highest = M %then
    %do;
        %let _allow_day   = 1;
        %let _allow_month = 1;
    %end;

    %if &_highest = Y %then
    %do;
        %let _allow_day   = 1;
        %let _allow_month = 1;
        %let _allow_year  = 1;
    %end;


    /*--------------------------------------------------------------*
     * Validate date_imputation
     *--------------------------------------------------------------*/

    %let _custom_month     = ;
    %let _custom_day       = ;
    %let _custom_month_txt = ;
    %let _custom_day_txt   = ;

    %if &_dateimp ne first and
        &_dateimp ne mid and
        &_dateimp ne last
    %then
    %do;

        /*
         * User-defined value must be MM-DD.
         */

        %if %sysfunc(
                prxmatch(
                    %str(/^[0-9][0-9]-[0-9][0-9]$/),
                    %superq(_dateimp)
                )
            ) = 0
        %then
        %do;

            %put ERROR: derive_vars_dt: date_imputation must be first, mid, last, or MM-DD.;
            %let _error = 1;

        %end;
        %else
        %do;

            %let _custom_month_txt =
                %qsubstr(%superq(_dateimp), 1, 2);

            %let _custom_day_txt =
                %qsubstr(%superq(_dateimp), 4, 2);

            %let _custom_month =
                %sysfunc(inputn(&_custom_month_txt, 2.));

            %let _custom_day =
                %sysfunc(inputn(&_custom_day_txt, 2.));

            /*
             * Month/day are integers at this point, therefore %EVAL
             * is sufficient.  Do not use %SYSEVALF here.
             */

            %if %eval(
                    &_custom_month < 1 or
                    &_custom_month > 12
                )
            %then
            %do;

                %put ERROR: derive_vars_dt: Invalid month in date_imputation=&date_imputation..;
                %let _error = 1;

            %end;

            %if %eval(
                    &_custom_day < 1 or
                    &_custom_day > 31
                )
            %then
            %do;

                %put ERROR: derive_vars_dt: Invalid day in date_imputation=&date_imputation..;
                %let _error = 1;

            %end;

        %end;

    %end;


    /*--------------------------------------------------------------*
     * Y-level imputation restrictions
     *--------------------------------------------------------------*/

    %if &_highest = Y %then
    %do;

        %if &_dateimp ne first and &_dateimp ne last %then
        %do;

            %put ERROR: derive_vars_dt: When highest_imputation=Y, date_imputation must be first or last.;
            %let _error = 1;

        %end;

        %if &_dateimp = first and %superq(min_dates) = %then
        %do;

            %put ERROR: derive_vars_dt: highest_imputation=Y with date_imputation=first requires min_dates.;
            %let _error = 1;

        %end;

        %if &_dateimp = last and %superq(max_dates) = %then
        %do;

            %put ERROR: derive_vars_dt: highest_imputation=Y with date_imputation=last requires max_dates.;
            %let _error = 1;

        %end;

    %end;


    %if &_error = 1 %then
    %do;

        %put ERROR: derive_vars_dt: Macro execution stopped due to invalid parameter value(s).;
        %return;

    %end;


    /*--------------------------------------------------------------*
     * Check input dataset exists
     *--------------------------------------------------------------*/

    %if not %sysfunc(exist(&dataset)) %then
    %do;

        %put ERROR: derive_vars_dt: Input dataset &dataset does not exist.;
        %return;

    %end;


    /*--------------------------------------------------------------*
     * Open input dataset
     *--------------------------------------------------------------*/

    %let _dsid = %sysfunc(open(&dataset));

    %if &_dsid = 0 %then
    %do;

        %put ERROR: derive_vars_dt: Unable to open input dataset &dataset..;
        %return;

    %end;


    /*--------------------------------------------------------------*
     * Check DTC variable
     *--------------------------------------------------------------*/

    %let _dtc_num = %sysfunc(varnum(&_dsid, &dtc));

    %if &_dtc_num = 0 %then
    %do;

        %put ERROR: derive_vars_dt: Variable &dtc not found in input dataset &dataset..;
        %let _error = 1;

    %end;
    %else
    %do;

        %let _dtc_type =
            %sysfunc(vartype(&_dsid, &_dtc_num));

        %if &_dtc_type ne C %then
        %do;

            %put ERROR: derive_vars_dt: Variable &dtc must be character.;
            %let _error = 1;

        %end;

    %end;


    /*--------------------------------------------------------------*
     * Check min_dates variables
     *--------------------------------------------------------------*/

    %if %superq(min_dates) ne %then
    %do;

        %let _nmin =
            %sysfunc(countw(%superq(min_dates), %str( )));

        %do _i = 1 %to &_nmin;

            %let _var =
                %scan(%superq(min_dates), &_i, %str( ));

            %let _varnum =
                %sysfunc(varnum(&_dsid, &_var));

            %if &_varnum = 0 %then
            %do;

                %put ERROR: derive_vars_dt: min_dates variable &_var not found in &dataset..;
                %let _error = 1;

            %end;
            %else
            %do;

                %let _vartype =
                    %sysfunc(vartype(&_dsid, &_varnum));

                %if &_vartype ne N %then
                %do;

                    %put ERROR: derive_vars_dt: min_dates variable &_var must be numeric SAS date or datetime.;
                    %let _error = 1;

                %end;

            %end;

        %end;

    %end;


    /*--------------------------------------------------------------*
     * Check max_dates variables
     *--------------------------------------------------------------*/

    %if %superq(max_dates) ne %then
    %do;

        %let _nmax =
            %sysfunc(countw(%superq(max_dates), %str( )));

        %do _i = 1 %to &_nmax;

            %let _var =
                %scan(%superq(max_dates), &_i, %str( ));

            %let _varnum =
                %sysfunc(varnum(&_dsid, &_var));

            %if &_varnum = 0 %then
            %do;

                %put ERROR: derive_vars_dt: max_dates variable &_var not found in &dataset..;
                %let _error = 1;

            %end;
            %else
            %do;

                %let _vartype =
                    %sysfunc(vartype(&_dsid, &_varnum));

                %if &_vartype ne N %then
                %do;

                    %put ERROR: derive_vars_dt: max_dates variable &_var must be numeric SAS date or datetime.;
                    %let _error = 1;

                %end;

            %end;

        %end;

    %end;


    /*--------------------------------------------------------------*
     * Check whether output variables already exist
     *--------------------------------------------------------------*/

    %let _dt_num =
        %sysfunc(varnum(&_dsid, &_dtvar));

    %let _dtf_num =
        %sysfunc(varnum(&_dsid, &_dtfvar));

    %if &_dt_num > 0 %then
    %do;

        %put WARNING: derive_vars_dt: Variable &_dtvar already exists in &dataset and will be overwritten.;

    %end;


    /*--------------------------------------------------------------*
     * Determine whether DTF should be created
     *--------------------------------------------------------------*/

    %let _create_flag = 0;

    %if &_flagimp = date %then
        %let _create_flag = 1;

    %if &_flagimp = auto and &_highest ne N %then
        %let _create_flag = 1;

    %if &_create_flag = 1 and &_dtf_num > 0 %then
    %do;

        %put WARNING: derive_vars_dt: Variable &_dtfvar already exists in &dataset and will be overwritten.;

    %end;


    %let _rc = %sysfunc(close(&_dsid));


    %if &_error = 1 %then
    %do;

        %put ERROR: derive_vars_dt: Macro execution stopped due to invalid input variable(s).;
        %return;

    %end;


    /*--------------------------------------------------------------*
     * Derive date
     *--------------------------------------------------------------*/

    data &outdata;

        set &dataset;

        length
            _adsk_dtc       $40
            _adsk_datepart  $20
            _adsk_year_txt  $4
            _adsk_month_txt $2
            _adsk_day_txt   $2
            _adsk_flag      $1
        ;

        length
            _adsk_year
            _adsk_month
            _adsk_day
            _adsk_imp_year
            _adsk_imp_month
            _adsk_imp_day
            _adsk_first_possible
            _adsk_last_possible
            _adsk_min_bound
            _adsk_max_bound
            _adsk_bound
            _adsk_tmp_date
            8
        ;

        format
            &_dtvar
            _adsk_first_possible
            _adsk_last_possible
            _adsk_min_bound
            _adsk_max_bound
            _adsk_bound
            _adsk_tmp_date
            date9.
        ;

        %if &_create_flag = 1 %then
        %do;
            length &_dtfvar $1;
        %end;


        /*----------------------------------------------------------*
         * Initialize all derived and temporary variables
         *
         * This prevents uninitialized-variable notes when min_dates
         * or max_dates are not supplied.
         *----------------------------------------------------------*/

        &_dtvar = .;

        %if &_create_flag = 1 %then
        %do;
            &_dtfvar = "";
        %end;

        _adsk_dtc            = "";
        _adsk_datepart       = "";
        _adsk_year_txt       = "";
        _adsk_month_txt      = "";
        _adsk_day_txt        = "";
        _adsk_flag           = "";

        _adsk_year           = .;
        _adsk_month          = .;
        _adsk_day            = .;
        _adsk_imp_year       = .;
        _adsk_imp_month      = .;
        _adsk_imp_day        = .;
        _adsk_first_possible = .;
        _adsk_last_possible  = .;
        _adsk_min_bound      = .;
        _adsk_max_bound      = .;
        _adsk_bound          = .;
        _adsk_tmp_date       = .;


        /*----------------------------------------------------------*
         * Standardize DTC
         *----------------------------------------------------------*/

        _adsk_dtc = strip(&dtc);

        if index(_adsk_dtc, "T") > 0 then
            _adsk_datepart = scan(_adsk_dtc, 1, "T");
        else
            _adsk_datepart = _adsk_dtc;


        /*----------------------------------------------------------*
         * Parse year
         *----------------------------------------------------------*/

        if lengthn(_adsk_datepart) >= 4 then
        do;

            _adsk_year_txt =
                substr(_adsk_datepart, 1, 4);

            if not missing(_adsk_year_txt) and
               compress(_adsk_year_txt, "0123456789") = ""
            then
                _adsk_year =
                    input(_adsk_year_txt, 4.);

        end;


        /*----------------------------------------------------------*
         * Parse month
         *----------------------------------------------------------*/

        if lengthn(_adsk_datepart) >= 7 then
        do;

            _adsk_month_txt =
                substr(_adsk_datepart, 6, 2);

            if not missing(_adsk_month_txt) and
               compress(_adsk_month_txt, "0123456789") = ""
            then
                _adsk_month =
                    input(_adsk_month_txt, 2.);

        end;


        /*----------------------------------------------------------*
         * Parse day
         *
         * YYYY-MM-DD
         * YYYY---DD
         *----------------------------------------------------------*/

        if not missing(_adsk_month) then
        do;

            if lengthn(_adsk_datepart) >= 10 then
            do;

                _adsk_day_txt =
                    substr(_adsk_datepart, 9, 2);

                if not missing(_adsk_day_txt) and
                   compress(_adsk_day_txt, "0123456789") = ""
                then
                    _adsk_day =
                        input(_adsk_day_txt, 2.);

            end;

        end;
        else
        do;

            if lengthn(_adsk_datepart) >= 9 and
               substr(_adsk_datepart, 5, 3) = "---"
            then
            do;

                _adsk_day_txt =
                    substr(_adsk_datepart, 8, 2);

                if not missing(_adsk_day_txt) and
                   compress(_adsk_day_txt, "0123456789") = ""
                then
                    _adsk_day =
                        input(_adsk_day_txt, 2.);

            end;

        end;


        /*----------------------------------------------------------*
         * Validate parsed components
         *----------------------------------------------------------*/

        if not missing(_adsk_month) and
           (_adsk_month < 1 or _adsk_month > 12)
        then
            _adsk_month = .;

        if not missing(_adsk_day) and
           (_adsk_day < 1 or _adsk_day > 31)
        then
            _adsk_day = .;


        _adsk_imp_year  = _adsk_year;
        _adsk_imp_month = _adsk_month;
        _adsk_imp_day   = _adsk_day;


        /*----------------------------------------------------------*
         * Complete date
         *----------------------------------------------------------*/

        if not missing(_adsk_year) and
           not missing(_adsk_month) and
           not missing(_adsk_day)
        then
        do;

            _adsk_tmp_date =
                mdy(
                    _adsk_month,
                    _adsk_day,
                    _adsk_year
                );

            if not missing(_adsk_tmp_date) and
               year(_adsk_tmp_date)  = _adsk_year and
               month(_adsk_tmp_date) = _adsk_month and
               day(_adsk_tmp_date)   = _adsk_day
            then
                &_dtvar = _adsk_tmp_date;

        end;


        /*----------------------------------------------------------*
         * Missing day only
         *----------------------------------------------------------*/

        else if not missing(_adsk_year) and
                not missing(_adsk_month) and
                missing(_adsk_day)
        then
        do;

            %if &_allow_day = 1 %then
            %do;

                if "&_dateimp" = "first" then
                    _adsk_imp_day = 1;

                else if "&_dateimp" = "mid" then
                    _adsk_imp_day = 15;

                else if "&_dateimp" = "last" then
                    _adsk_imp_day =
                        day(
                            intnx(
                                "month",
                                mdy(
                                    _adsk_month,
                                    1,
                                    _adsk_year
                                ),
                                0,
                                "e"
                            )
                        );

                %if %superq(_custom_day) ne %then
                %do;
                    else
                        _adsk_imp_day = &_custom_day;
                %end;

                _adsk_tmp_date =
                    mdy(
                        _adsk_month,
                        _adsk_imp_day,
                        _adsk_year
                    );

                if not missing(_adsk_tmp_date) and
                   year(_adsk_tmp_date)  = _adsk_year and
                   month(_adsk_tmp_date) = _adsk_month and
                   day(_adsk_tmp_date)   = _adsk_imp_day
                then
                do;

                    &_dtvar = _adsk_tmp_date;
                    _adsk_flag = "D";

                end;

            %end;

        end;


        /*----------------------------------------------------------*
         * Missing month
         *----------------------------------------------------------*/

        else if not missing(_adsk_year) and
                missing(_adsk_month)
        then
        do;

            %if &_allow_month = 1 %then
            %do;

                if "&_dateimp" = "first" then
                do;

                    _adsk_imp_month = 1;
                    _adsk_imp_day   = 1;

                end;

                else if "&_dateimp" = "mid" then
                do;

                    _adsk_imp_month = 6;
                    _adsk_imp_day   = 30;

                end;

                else if "&_dateimp" = "last" then
                do;

                    _adsk_imp_month = 12;
                    _adsk_imp_day   = 31;

                end;

                %if %superq(_custom_month) ne %then
                %do;

                    else
                    do;

                        _adsk_imp_month = &_custom_month;
                        _adsk_imp_day   = &_custom_day;

                    end;

                %end;


                /*
                 * Preserve known lower-order day component.
                 */

                %if &_preserve = Y %then
                %do;

                    if not missing(_adsk_day) then
                        _adsk_imp_day = _adsk_day;

                %end;


                _adsk_tmp_date =
                    mdy(
                        _adsk_imp_month,
                        _adsk_imp_day,
                        _adsk_year
                    );

                if not missing(_adsk_tmp_date) and
                   year(_adsk_tmp_date)  = _adsk_year and
                   month(_adsk_tmp_date) = _adsk_imp_month and
                   day(_adsk_tmp_date)   = _adsk_imp_day
                then
                do;

                    &_dtvar = _adsk_tmp_date;
                    _adsk_flag = "M";

                end;

            %end;

        end;


        /*----------------------------------------------------------*
         * Determine possible date range for known year
         *----------------------------------------------------------*/

        if not missing(_adsk_year) then
        do;

            if not missing(_adsk_month) then
            do;

                _adsk_first_possible =
                    mdy(
                        _adsk_month,
                        1,
                        _adsk_year
                    );

                _adsk_last_possible =
                    intnx(
                        "month",
                        _adsk_first_possible,
                        0,
                        "e"
                    );

            end;
            else
            do;

                _adsk_first_possible =
                    mdy(
                        1,
                        1,
                        _adsk_year
                    );

                _adsk_last_possible =
                    mdy(
                        12,
                        31,
                        _adsk_year
                    );

            end;

        end;


        /*----------------------------------------------------------*
         * Minimum date restrictions
         *----------------------------------------------------------*/

        %if %superq(min_dates) ne %then
        %do;

            _adsk_min_bound = .;

            %let _nmin =
                %sysfunc(
                    countw(
                        %superq(min_dates),
                        %str( )
                    )
                );

            %do _i = 1 %to &_nmin;

                %let _var =
                    %scan(
                        %superq(min_dates),
                        &_i,
                        %str( )
                    );

                if not missing(&_var) then
                do;

                    /*
                     * Convert datetime to date when needed.
                     */

                    if abs(&_var) > 1000000 then
                        _adsk_bound =
                            datepart(&_var);
                    else
                        _adsk_bound =
                            &_var;

                    /*
                     * Only boundaries within the possible range
                     * represented by the original DTC are used.
                     */

                    if not missing(_adsk_first_possible) and
                       not missing(_adsk_last_possible) and
                       _adsk_bound >= _adsk_first_possible and
                       _adsk_bound <= _adsk_last_possible
                    then
                    do;

                        if missing(_adsk_min_bound) or
                           _adsk_bound > _adsk_min_bound
                        then
                            _adsk_min_bound =
                                _adsk_bound;

                    end;

                end;

            %end;


            if not missing(&_dtvar) and
               not missing(_adsk_min_bound) and
               &_dtvar < _adsk_min_bound
            then
                &_dtvar =
                    _adsk_min_bound;

        %end;


        /*----------------------------------------------------------*
         * Maximum date restrictions
         *----------------------------------------------------------*/

        %if %superq(max_dates) ne %then
        %do;

            _adsk_max_bound = .;

            %let _nmax =
                %sysfunc(
                    countw(
                        %superq(max_dates),
                        %str( )
                    )
                );

            %do _i = 1 %to &_nmax;

                %let _var =
                    %scan(
                        %superq(max_dates),
                        &_i,
                        %str( )
                    );

                if not missing(&_var) then
                do;

                    if abs(&_var) > 1000000 then
                        _adsk_bound =
                            datepart(&_var);
                    else
                        _adsk_bound =
                            &_var;

                    if not missing(_adsk_first_possible) and
                       not missing(_adsk_last_possible) and
                       _adsk_bound >= _adsk_first_possible and
                       _adsk_bound <= _adsk_last_possible
                    then
                    do;

                        if missing(_adsk_max_bound) or
                           _adsk_bound < _adsk_max_bound
                        then
                            _adsk_max_bound =
                                _adsk_bound;

                    end;

                end;

            %end;


            if not missing(&_dtvar) and
               not missing(_adsk_max_bound) and
               &_dtvar > _adsk_max_bound
            then
                &_dtvar =
                    _adsk_max_bound;

        %end;


        /*----------------------------------------------------------*
         * Year-level imputation
         *----------------------------------------------------------*/

        %if &_allow_year = 1 %then
        %do;

            if missing(_adsk_year) and
               not missing(_adsk_datepart)
            then
            do;


                /*----------------------------------------------*
                 * FIRST: use latest applicable minimum date
                 *----------------------------------------------*/

                %if &_dateimp = first %then
                %do;

                    _adsk_min_bound = .;

                    %let _nmin =
                        %sysfunc(
                            countw(
                                %superq(min_dates),
                                %str( )
                            )
                        );

                    %do _i = 1 %to &_nmin;

                        %let _var =
                            %scan(
                                %superq(min_dates),
                                &_i,
                                %str( )
                            );

                        if not missing(&_var) then
                        do;

                            if abs(&_var) > 1000000 then
                                _adsk_bound =
                                    datepart(&_var);
                            else
                                _adsk_bound =
                                    &_var;

                            if missing(_adsk_min_bound) or
                               _adsk_bound > _adsk_min_bound
                            then
                                _adsk_min_bound =
                                    _adsk_bound;

                        end;

                    %end;


                    if not missing(_adsk_min_bound) then
                    do;

                        &_dtvar =
                            _adsk_min_bound;

                        _adsk_flag = "Y";

                    end;

                %end;


                /*----------------------------------------------*
                 * LAST: use earliest applicable maximum date
                 *----------------------------------------------*/

                %if &_dateimp = last %then
                %do;

                    _adsk_max_bound = .;

                    %let _nmax =
                        %sysfunc(
                            countw(
                                %superq(max_dates),
                                %str( )
                            )
                        );

                    %do _i = 1 %to &_nmax;

                        %let _var =
                            %scan(
                                %superq(max_dates),
                                &_i,
                                %str( )
                            );

                        if not missing(&_var) then
                        do;

                            if abs(&_var) > 1000000 then
                                _adsk_bound =
                                    datepart(&_var);
                            else
                                _adsk_bound =
                                    &_var;

                            if missing(_adsk_max_bound) or
                               _adsk_bound < _adsk_max_bound
                            then
                                _adsk_max_bound =
                                    _adsk_bound;

                        end;

                    %end;


                    if not missing(_adsk_max_bound) then
                    do;

                        &_dtvar =
                            _adsk_max_bound;

                        _adsk_flag = "Y";

                    end;

                %end;

            end;

        %end;


        /*----------------------------------------------------------*
         * Set date imputation flag
         *----------------------------------------------------------*/

        %if &_create_flag = 1 %then
        %do;
            &_dtfvar = _adsk_flag;
        %end;


        /*----------------------------------------------------------*
         * Remove temporary variables
         *----------------------------------------------------------*/

        drop
            _adsk_:
        ;

    run;


    %put NOTE: derive_vars_dt: Derived variable &_dtvar in &outdata..;

    %if &_create_flag = 1 %then
    %do;

        %put NOTE: derive_vars_dt: Derived date imputation flag &_dtfvar in &outdata..;

    %end;

%mend derive_vars_dt;
