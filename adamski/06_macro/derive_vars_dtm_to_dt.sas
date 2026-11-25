
/*** HELP START ***//*

### Macro:
    %derive_vars_dtm_to_dt

### Purpose:
    Derive Date Variables from Datetime Variables

### Parameters:
 - `dataset` (required) : Input dataset (with original observations)
 - `source_vars` (required) : Space-separated list of source variable names
 - `outdata` (optional, default=&dataset) : Output dataset with derived date variables

### Sample code:

~~~sas
data adcm;
    input TRTSDTM :datetime20. ASTDTM :datetime20. AENDTM :datetime20.;
    format TRTSDTM ASTDTM AENDTM datetime20.;
    datalines;
25FEB2012:23:00:00 28FEB2012:19:00:00 25FEB2012:23:00:00
. 28FEB2012:19:00:00 .
;
run;

%derive_vars_dtm_to_dt(
    dataset=adcm,
    source_vars=TRTSDTM ASTDTM AENDTM,
    outdata=adcm_out
);
~~~

### Note:
- Numeric sources are SAS datetime seconds unless a recognized
  SAS date format is assigned.
- Character sources are interpreted using SAS ANYDTDTM informat.
- SAS variable names and DTM matching are case-insensitive.
- Derived variable naming is consistent for single and multiple
  source variables.
- The first occurrence of DTM in the source variable name is
  replaced with DT, irrespective of its position.
- If DTM is not present, the suffix _new is appended.
- Original source variables are preserved.
- Existing target variables are overwritten with a warning.
- Existing intermediate variables in multiple-source derivations
  are replaced and removed with a warning.
- Duplicate source specifications are processed only once.
- Duplicate derived target names from different source variables
  are rejected.
- Derived target names that collide with source variables are
  rejected to preserve the original source values.
- No date or time imputation is performed.
- SAS datetime values have no per-variable time-zone attribute.
- R numeric epoch values must be converted to SAS datetime
  values before use.

### URL:

https://github.com/PharmaForest/adamski

---

Author:              Manivannan Mathialagan
Latest update Date:  2026-11-25

---

*//*** HELP END ***/

%macro derive_vars_dtm_to_dt(dataset=, source_vars=, outdata=);

    %local _dsid _rc _n _i _j _k _src _tgt _mid _pos
           _vn _typ _fmt _seen _sources _targets _mids
           _types _dates _bad _tmp _drop _rename
           _existing _uid _helper _mid_drop _target_keys
           _read_sources _read_src _source_pos;

    /*----------------------------------------------------------*/
    /* 1. Validate parameters and open input metadata.          */
    /*----------------------------------------------------------*/

    %if %superq(dataset)= %then %do;
        %put ERROR: derive_vars_dtm_to_dt: dataset is required.;
        %return;
    %end;

    %if %superq(source_vars)= %then %do;
        %put ERROR: derive_vars_dtm_to_dt: source_vars is required.;
        %return;
    %end;

    %if %superq(outdata)= %then %let outdata=&dataset;

    %let _n=%sysfunc(countw(%superq(source_vars),%str( )));

    %if &_n=0 %then %do;
        %put ERROR: derive_vars_dtm_to_dt: source_vars is required.;
        %return;
    %end;

    %let _dsid=%sysfunc(open(%superq(dataset),i));

    %if &_dsid=0 %then %do;
        %put ERROR: derive_vars_dtm_to_dt: Cannot open input dataset %superq(dataset).;
        %return;
    %end;

    %let _sources=;
    %let _targets=;
    %let _mids=;
    %let _types=;
    %let _dates=;
    %let _seen=|;
    %let _target_keys=|;
    %let _bad=0;

    /*----------------------------------------------------------*/
    /* 2. Resolve unique source names and source metadata.      */
    /*----------------------------------------------------------*/

    %do _i=1 %to &_n;

        %let _src=%scan(%superq(source_vars),&_i,%str( ));

        %if not %sysfunc(nvalid(%superq(_src),V7)) %then %do;

            %put ERROR: derive_vars_dtm_to_dt: Invalid source variable %superq(_src).;
            %let _bad=1;

        %end;
        %else %do;

            %let _vn=%sysfunc(varnum(&_dsid,&_src));

            %if &_vn=0 %then %do;

                %put ERROR: derive_vars_dtm_to_dt: Required source variable &_src is missing.;
                %let _bad=1;

            %end;
            %else %if %sysfunc(
                index(%superq(_seen),|%upcase(&_src)|)
            )=0 %then %do;

                %let _src=%sysfunc(varname(&_dsid,&_vn));

                %let _seen=&_seen%upcase(&_src)|;
                %let _sources=&_sources &_src;

                %let _typ=%sysfunc(vartype(&_dsid,&_vn));
                %let _types=&_types &_typ;

                %let _fmt=%sysfunc(varfmt(&_dsid,&_vn));

                %if %length(%superq(_fmt))>0 %then
                    %let _fmt=%upcase(%superq(_fmt));

                %let _pos=0;

                /* Identify numeric variables with date formats. */

                %if %length(%superq(_fmt))>0 %then %do;

                    %if %sysfunc(index(%superq(_fmt),DATE))=1 or
                        %sysfunc(index(%superq(_fmt),DDMMYY))=1 or
                        %sysfunc(index(%superq(_fmt),MMDDYY))=1 or
                        %sysfunc(index(%superq(_fmt),YYMMDD))=1 or
                        %sysfunc(index(%superq(_fmt),E8601DA))=1 or
                        %sysfunc(index(%superq(_fmt),B8601DA))=1 or
                        %sysfunc(index(%superq(_fmt),IS8601DA))=1 or
                        %sysfunc(index(%superq(_fmt),WORDDATE))=1 or
                        %sysfunc(index(%superq(_fmt),WEEKDATE))=1 or
                        %sysfunc(index(%superq(_fmt),MONYY))=1 or
                        %sysfunc(index(%superq(_fmt),JULIAN))=1 or
                        %sysfunc(index(%superq(_fmt),NLDATE))=1
                    %then %let _pos=1;

                    %if %sysfunc(index(%superq(_fmt),DATETIME))=1 or
                        %sysfunc(index(%superq(_fmt),DATEAMPM))=1
                    %then %let _pos=0;

                %end;

                %let _dates=&_dates &_pos;

            %end;

        %end;

    %end;

    %if &_bad %then %goto close_error;

    %let _k=%sysfunc(countw(&_sources,%str( )));

    %let _drop=;
    %let _mid_drop=;
    %let _rename=;
    %let _read_sources=;

    %let _uid=%substr(
        %sysfunc(compress(%sysfunc(uuidgen()),-)),1,12
    );

    %let _tmp=_ddt&_uid;

    /*----------------------------------------------------------*/
    /* 3. Resolve derived variable names and target metadata.   */
    /*----------------------------------------------------------*/

    %do _i=1 %to &_k;

        %let _src=%scan(&_sources,&_i);
        %let _mid=&_src._new;

        /* Consistent naming for single and multiple sources. */

        %if %sysfunc(index(%upcase(&_src),DTM))>0 %then %do;

            %let _tgt=%sysfunc(
                prxchange(%str(s/DTM/DT/i),1,&_src)
            );

        %end;
        %else %do;

            %let _tgt=&_mid;

        %end;

        /* Validate the derived variable name. */

        %if not %sysfunc(nvalid(&_tgt,V7)) %then %do;

            %put ERROR: derive_vars_dtm_to_dt: Invalid derived variable name &_tgt.;
            %goto close_error;

        %end;

        /* Prevent different sources generating the same target. */

        %if %sysfunc(
            index(%superq(_target_keys),|%upcase(&_tgt)|)
        )>0 %then %do;

            %put ERROR: derive_vars_dtm_to_dt: Duplicate target variable &_tgt.;
            %goto close_error;

        %end;

        /* Protect original source variables from overwrite. */

        %if %sysfunc(
            index(%superq(_seen),|%upcase(&_tgt)|)
        )>0 %then %do;

            %put ERROR: derive_vars_dtm_to_dt: Derived target &_tgt conflicts with a source variable.;
            %goto close_error;

        %end;

        %let _existing=%sysfunc(varnum(&_dsid,&_tgt));

        /* Warn whenever the derived target already exists. */

        %if &_existing>0 %then %do;

            %put WARNING: derive_vars_dtm_to_dt: Variable &_tgt already exists in the dataset.;

        %end;

        /* Handle existing intermediate variables. */

        %if &_k>1 and
            %upcase(&_mid) ne %upcase(&_tgt)
        %then %do;

            %if %sysfunc(nvalid(&_mid,V7)) %then %do;

                %if %sysfunc(varnum(&_dsid,&_mid))>0 %then %do;

                    /* Do not remove an explicitly requested source. */

                    %if %sysfunc(
                        index(%superq(_seen),|%upcase(&_mid)|)
                    )>0 %then %do;

                        %put ERROR: derive_vars_dtm_to_dt: Intermediate variable &_mid conflicts with a source variable.;
                        %goto close_error;

                    %end;

                    %put WARNING: derive_vars_dtm_to_dt: Existing intermediate variable &_mid will be replaced by &_tgt.;

                    %let _mid_drop=&_mid_drop &_mid;

                %end;

            %end;

        %end;

        %let _targets=&_targets &_tgt;
        %let _target_keys=&_target_keys%upcase(&_tgt)|;
        %let _mids=&_mids &_mid;

        /* Rename existing character targets on input so that
           the derived output variable can be numeric. */

        %if &_existing>0 %then %do;

            %if %sysfunc(vartype(&_dsid,&_existing))=C %then %do;

                %let _helper=_ddc&_uid._&_i;

                %let _rename=&_rename &_tgt=&_helper;
                %let _drop=&_drop &_helper;

            %end;

        %end;

    %end;

    /* Prevent an intermediate variable from being removed
       when it is also a final derived target. */

    %do _i=1 %to %sysfunc(countw(%superq(_mid_drop),%str( )));

        %let _mid=%scan(&_mid_drop,&_i);

        %if %sysfunc(
            index(%superq(_target_keys),|%upcase(&_mid)|)
        )>0 %then %do;

            %put ERROR: derive_vars_dtm_to_dt: Intermediate variable &_mid conflicts with a derived target.;
            %goto close_error;

        %end;

    %end;

    %let _rc=%sysfunc(close(&_dsid));

    /*----------------------------------------------------------*/
    /* 4. Calculate dates in a temporary dataset.               */
    /*----------------------------------------------------------*/

    %let _bad=0;

    data work.&_tmp;

        set &dataset

        %if %length(%superq(_rename))>0 %then %do;
            (rename=(&_rename))
        %end;

        ;

        %do _i=1 %to &_k;

            %let _src=%scan(&_sources,&_i);
            %let _tgt=%scan(&_targets,&_i);
            %let _typ=%scan(&_types,&_i);
            %let _pos=%scan(&_dates,&_i);

            %let _helper=_ddv&_uid._&_i;
            %let _drop=&_drop &_helper;

            /* Character datetime source. */

            %if &_typ=C %then %do;

                &_helper=.;

                if not missing(&_src) then do;

                    &_helper=input(
                        strip(&_src), ?? anydtdtm32.
                    );

                    if missing(&_helper) then do;

                        put 'ERROR: derive_vars_dtm_to_dt: Invalid character datetime. '
                            &_src=;

                        call symputx('_bad',1,'L');

                    end;
                    else &_helper=datepart(&_helper);

                end;

            %end;

            /* Numeric source already representing a SAS date. */

            %else %if &_pos=1 %then %do;

                &_helper=&_src;

            %end;

            /* Numeric SAS datetime source. */

            %else %do;

                if not missing(&_src) then
                    &_helper=datepart(&_src);
                else
                    &_helper=.;

            %end;

        %end;

        /*------------------------------------------------------*/
        /* 5. Assign dates after all source values are read.    */
        /*------------------------------------------------------*/

        %do _i=1 %to &_k;

            %let _tgt=%scan(&_targets,&_i);
            %let _helper=_ddv&_uid._&_i;

            &_tgt=&_helper;

            format &_tgt date9.;

        %end;

        drop &_drop &_mid_drop;

    run;

    %if &syserr>4 %then %let _bad=1;

    /*----------------------------------------------------------*/
    /* 6. Publish output only after successful derivation.      */
    /*----------------------------------------------------------*/

    %if &_bad=0 %then %do;

        data &outdata;
            set work.&_tmp;
        run;

    %end;

    /*----------------------------------------------------------*/
    /* 7. Remove temporary dataset.                             */
    /*----------------------------------------------------------*/

    proc datasets library=work nolist nowarn;
        delete &_tmp;
    quit;

    %return;

    %close_error:

    %let _rc=%sysfunc(close(&_dsid));

%mend derive_vars_dtm_to_dt;
