/*** HELP START ***//*

### Macro:
    %derive_vars_dtm_to_tm

### Purpose:
    Derive Time Variables from Datetime Variables.

### Parameters:
 - `dataset` (required) : Input dataset.
 - `source_vars` (required) : Space-separated source variable names.
 - `outdata` (optional) : Output dataset. Default: &dataset.

### Sample code:

~~~sas
data adcm;
    input TRTSDTM :datetime20. ASTDTM :datetime20. AENDTM :datetime20.;
    format TRTSDTM ASTDTM AENDTM datetime20.;
    datalines;
25FEB2012:23:41:10 28FEB2012:19:03:00 25FEB2013:23:32:16
. 28FEB2012:19:00:00 .
;
run;

%derive_vars_dtm_to_tm(dataset=adcm,
    source_vars=TRTSDTM ASTDTM AENDTM, outdata=adcm_out);
~~~

### Note:
- Numeric sources are SAS datetime seconds unless a recognized SAS time
  format is assigned, in which case their values are preserved.
- Character sources are interpreted using ANYDTDTM32.
- The first occurrence of DTM is replaced with TM, case-insensitively.
- If DTM is absent, _new is appended.
- Duplicate source specifications are processed once.
- Duplicate targets and targets conflicting with sources are rejected.
- Existing targets are overwritten with a warning.
- Existing intermediate variables are preserved; no intermediate _new
  variables are needed for derivation.
- Missing values remain missing. Invalid character values prevent publication.
- Output times use tod8. format; fractional seconds remain numeric.
- No time-zone conversion or imputation is performed.

### URL:

https://github.com/PharmaForest/adamski

Author:              Manivannan Mathialagan
Latest update Date:  2026-11-25

*//*** HELP END ***/

%macro derive_vars_dtm_to_tm(dataset=, source_vars=, outdata=);
    %local _dsid _rc _n _i _src _tgt _vn _typ _fmt _seen
           _sources _targets _types _times _target_keys _bad _k
           _uid _tmp _helper _rename _drop _existing _is_time;

    /* 1. Validate parameters and input metadata. */
    %if %superq(dataset)= %then %do;
        %put ERROR: derive_vars_dtm_to_tm: dataset is required.;
        %return;
    %end;
    %if %superq(source_vars)= %then %do;
        %put ERROR: derive_vars_dtm_to_tm: source_vars is required.;
        %return;
    %end;
    %if %superq(outdata)= %then %let outdata=&dataset;
    %let _n=%sysfunc(countw(%superq(source_vars),%str( )));
    %if &_n=0 %then %do;
        %put ERROR: derive_vars_dtm_to_tm: source_vars is required.;
        %return;
    %end;
    %let _dsid=%sysfunc(open(%superq(dataset),i));
    %if &_dsid=0 %then %do;
        %put ERROR: derive_vars_dtm_to_tm: Cannot open input dataset %superq(dataset).;
        %return;
    %end;
    %let _seen=|;
    %let _sources=;
    %let _targets=;
    %let _types=;
    %let _times=;
    %let _target_keys=|;
    %let _rename=;
    %let _drop=;
    %let _bad=0;

    /* 2. Resolve unique sources and metadata. */
    %do _i=1 %to &_n;
        %let _src=%scan(%superq(source_vars),&_i,%str( ));
        %if not %sysfunc(nvalid(%superq(_src),V7)) %then %do;
            %put ERROR: derive_vars_dtm_to_tm: Invalid source variable %superq(_src).;
            %goto close_error;
        %end;
        %let _vn=%sysfunc(varnum(&_dsid,&_src));
        %if &_vn=0 %then %do;
            %put ERROR: derive_vars_dtm_to_tm: Required source variable &_src is missing.;
            %goto close_error;
        %end;
        %if %sysfunc(index(%superq(_seen),|%upcase(&_src)|))=0 %then %do;
            %let _src=%sysfunc(varname(&_dsid,&_vn));
            %let _seen=&_seen%upcase(&_src)|;
            %let _sources=&_sources &_src;
            %let _typ=%sysfunc(vartype(&_dsid,&_vn));
            %let _types=&_types &_typ;
            %let _fmt=%sysfunc(varfmt(&_dsid,&_vn));
            %let _is_time=0;
            %if %length(%superq(_fmt)) %then %do;
                %if %sysfunc(prxmatch(%str(/^(TIME|TOD|TIMEAMPM|HHMM|HOUR|MMSS|E8601TM|B8601TM|IS8601TM|NLTIME)[0-9.]*$/i),%superq(_fmt))) %then %let _is_time=1;
            %end;
            %let _times=&_times &_is_time;
        %end;
    %end;
    %let _k=%sysfunc(countw(&_sources,%str( )));
    %let _uid=%substr(%sysfunc(compress(%sysfunc(uuidgen()),-)),1,12);
    %let _tmp=_dtm&_uid;

    /* 3. Resolve targets and protect source variables. */
    %do _i=1 %to &_k;
        %let _src=%scan(&_sources,&_i);
        %if %sysfunc(index(%upcase(&_src),DTM))>0 %then
            %let _tgt=%sysfunc(prxchange(%str(s/DTM/TM/i),1,&_src));
        %else %let _tgt=&_src._new;
        %if not %sysfunc(nvalid(&_tgt,V7)) %then %do;
            %put ERROR: derive_vars_dtm_to_tm: Invalid derived variable name &_tgt.;
            %goto close_error;
        %end;
        %if %sysfunc(index(%superq(_target_keys),|%upcase(&_tgt)|))>0 %then %do;
            %put ERROR: derive_vars_dtm_to_tm: Duplicate target variable &_tgt.;
            %goto close_error;
        %end;
        %if %sysfunc(index(%superq(_seen),|%upcase(&_tgt)|))>0 %then %do;
            %put ERROR: derive_vars_dtm_to_tm: Derived target &_tgt conflicts with a source variable.;
            %goto close_error;
        %end;
        %let _targets=&_targets &_tgt;
        %let _target_keys=&_target_keys%upcase(&_tgt)|;
        %let _existing=%sysfunc(varnum(&_dsid,&_tgt));
        %if &_existing>0 %then %do;
            %put WARNING: derive_vars_dtm_to_tm: Variable &_tgt already exists in the dataset.;
            %let _helper=_dtc&_uid._&_i;
            %let _rename=&_rename &_tgt=&_helper;
            %let _drop=&_drop &_helper;
        %end;
    %end;
    %let _rc=%sysfunc(close(&_dsid));

    /* 4. Derive time values in a temporary dataset. */
    data work.&_tmp;
        set &dataset
        %if %length(%superq(_rename)) %then %do;
            (rename=(&_rename))
        %end;
        ;
        %do _i=1 %to &_k;
            %let _src=%scan(&_sources,&_i);
            %let _tgt=%scan(&_targets,&_i);
            %let _typ=%scan(&_types,&_i);
            %let _is_time=%scan(&_times,&_i);
            length &_tgt 8;
            %if &_typ=C %then %do;
                &_tgt=.;
                if not missing(&_src) then do;
                    &_tgt=input(strip(&_src), ?? anydtdtm32.);
                    if missing(&_tgt) then do;
                        put 'ERROR: derive_vars_dtm_to_tm: Invalid character datetime. ' &_src=;
                        call symputx('_bad',1,'L');
                    end;
                    else &_tgt=timepart(&_tgt);
                end;
            %end;
            %else %if &_is_time=1 %then %do;
                &_tgt=&_src;
            %end;
            %else %do;
                if not missing(&_src) then &_tgt=timepart(&_src);
                else &_tgt=.;
            %end;
            format &_tgt tod8.;
        %end;
        %if %length(%superq(_drop)) %then %do;
            drop &_drop;
        %end;
    run;
    %if &syserr>4 %then %let _bad=1;

    /* 5. Publish only after successful derivation. */
    %if &_bad=0 %then %do;
        data &outdata;
            set work.&_tmp;
        run;
    %end;

    /* 6. Clean up temporary data. */
    proc datasets library=work nolist nowarn;
        delete &_tmp;
    quit;
    %return;

    %close_error:
    %let _rc=%sysfunc(close(&_dsid));
%mend derive_vars_dtm_to_tm;
