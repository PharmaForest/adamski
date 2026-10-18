/*** HELP START ***//*
### Macro:
    %derive_vars_dtm

### Purpose:
    Derive numeric SAS datetime *DTM from ISO 8601 character --DTC, with optional
    date/time imputation flags *DTF and *TMF. Standalone dataset-in/dataset-out
    macro for ADAMSKI. This is a SAS implementation requiring QC against Admiral.

### Parameters:
- dataset (required): Input SAS dataset.
- new_vars_prefix (required): E.g. AST -> ASTDTM, ASTDTF, ASTTMF.
- dtc (required): Character ISO 8601 date/datetime variable.
- highest_imputation: n, s, m, h, D, M, Y (default h; case-sensitive for m/M).
- date_imputation: first, mid, last, or MM-DD (default first).
- time_imputation: first, last, or HH:MM:SS (default first).
- flag_imputation: auto, both, date, time, none (default auto).
- min_dates, min_dates_strict, max_dates, max_dates_strict:
    Space-separated lists of numeric SAS date/datetime variables. Date-only
    minimum boundaries use 00:00:00, maximum boundaries use 23:59:59.
    Strict boundaries narrow the eligible interval for ordinary boundaries.
- preserve: Y/N (default N). Preserve known lower components below a missing
    higher component when Y; otherwise propagate missing components downward.
- ignore_seconds_flag: Y/N (default Y). If Y, seconds must not be present in
    any nonblank DTC input; S-only TMF is suppressed.
- outdata: Output dataset (default: dataset, overwritten).

### Notes:
- Invalid/unsupported row-level DTC values result in missing *DTM and a log warning.
- Invalid macro parameters, missing dataset/variables, and wrong variable types
  stop macro execution before output creation using %RETURN.
- All macro parameter values are displayed in the SAS log at invocation.
- Existing *DTF is retained, as in Admiral. Existing *DTM/*TMF are overwritten.
- Date/time components are parsed without timezone conversion. ISO timezone
  offsets, fractional seconds, and nonstandard compact ISO strings are not supported.
- When year is missing, highest_imputation=Y can use an applicable minimum
  (date_imputation=first) or maximum (date_imputation=last) boundary.
- Strict bounds restrict eligibility of other bounds; they do not unconditionally
  force the final datetime to be within the strict range.
- To avoid changing known DTC components, boundaries are considered only within
  the possible datetime range represented by the original DTC.
- If bounds conflict, the later-applied maximum bound takes precedence.
- Compare expected outputs with Admiral before production use.

### Sample code:
~~~sas
%derive_vars_dtm(
  dataset=ae, outdata=adae, new_vars_prefix=AST, dtc=AESTDTC,
  highest_imputation=M, date_imputation=first, time_imputation=first,
  min_dates=TRTSDTM, flag_imputation=auto
);
~~~
### URL:
https://github.com/PharmaForest/adamski

---
Author: Manivannan Mathialagan
Latest update Date: 2026-10-18
---
*//*** HELP END ***/

%macro derive_vars_dtm(
    dataset=,
    new_vars_prefix=,
    dtc=,
    highest_imputation=h,
    date_imputation=first,
    time_imputation=first,
    flag_imputation=auto,
    min_dates=,
    min_dates_strict=,
    max_dates=,
    max_dates_strict=,
    preserve=N,
    ignore_seconds_flag=Y,
    outdata=
);
    %local _error _dsid _rc _dtcnum _vnum _i _j _var _list _n
           _highest _dateimp _timeimp _flagimp _preserve _ignsec
           _dtm _dtf _tmf _make_dtf _make_tmf _existing_dtf
           _date_month _date_day _th _tmin _ts _allowdate
           _target _boundtype _eligible _level_code;
    %let _error=0;
    %put NOTE: ============================================================;
    %put NOTE: derive_vars_dtm - PARAMETER VALUES (case-sensitive level);
    %put NOTE: dataset             = %superq(dataset);
    %put NOTE: new_vars_prefix     = %superq(new_vars_prefix);
    %put NOTE: dtc                 = %superq(dtc);
    %put NOTE: highest_imputation  = %superq(highest_imputation);
    %put NOTE: date_imputation     = %superq(date_imputation);
    %put NOTE: time_imputation     = %superq(time_imputation);
    %put NOTE: flag_imputation     = %superq(flag_imputation);
    %put NOTE: min_dates           = %superq(min_dates);
    %put NOTE: min_dates_strict    = %superq(min_dates_strict);
    %put NOTE: max_dates           = %superq(max_dates);
    %put NOTE: max_dates_strict    = %superq(max_dates_strict);
    %put NOTE: preserve            = %superq(preserve);
    %put NOTE: ignore_seconds_flag = %superq(ignore_seconds_flag);
    %put NOTE: outdata             = %superq(outdata);
    %put NOTE: ============================================================;
    %if %superq(dataset)=%then %do;
        %put ERROR: derive_vars_dtm: dataset is required.;
        %let _error=1;
    %end;
    %if %superq(new_vars_prefix)=%then %do;
        %put ERROR: derive_vars_dtm: new_vars_prefix is required.;
        %let _error=1;
    %end;
    %if %superq(dtc)=%then %do;
        %put ERROR: derive_vars_dtm: dtc is required.;
        %let _error=1;
    %end;
    %if &_error %then %do;
        %put ERROR: derive_vars_dtm: Validation failed. Macro stopped after parameter validation failure.;
        %return;
    %end;

    %let _highest=%superq(highest_imputation);
    %let _dateimp=%lowcase(%superq(date_imputation));
    %let _timeimp=%lowcase(%superq(time_imputation));
    %let _flagimp=%lowcase(%superq(flag_imputation));
    %let _preserve=%upcase(%superq(preserve));
    %let _ignsec=%upcase(%superq(ignore_seconds_flag));
    %if %sysfunc(nvalid(%superq(new_vars_prefix),V7))=0 or
        %length(%superq(new_vars_prefix))>29 %then %do;
        %put ERROR: derive_vars_dtm: new_vars_prefix must be a valid SAS prefix of at most 29 characters.;
        %let _error=1;
    %end;
    %if %sysfunc(nvalid(%superq(dtc),V7))=0 %then %do;
        %put ERROR: derive_vars_dtm: dtc must be a valid SAS variable name.;
        %let _error=1;
    %end;
    %let _dtm=&new_vars_prefix.DTM;
    %let _dtf=&new_vars_prefix.DTF;
    %let _tmf=&new_vars_prefix.TMF;
    %if %superq(outdata)=%then %let outdata=&dataset;

    /* Explicit ASCII code mapping avoids SAS macro case-insensitive comparisons. */
    /* n=110, s=115, m=109, h=104, D=68, M=77, Y=89. */
    /* Levels: n=0, s=2, m=3, h=4, D=5, M=6, Y=7. */
    %let _eligible=-1;
    %if %length(%superq(_highest))=1 %then %do;
        %let _level_code=%sysfunc(rank(%superq(_highest)));
        %if &_level_code=110 %then %let _eligible=0;
        %else %if &_level_code=115 %then %let _eligible=2;
        %else %if &_level_code=109 %then %let _eligible=3;
        %else %if &_level_code=104 %then %let _eligible=4;
        %else %if &_level_code=68 %then %let _eligible=5;
        %else %if &_level_code=77 %then %let _eligible=6;
        %else %if &_level_code=89 %then %let _eligible=7;
    %end;
    %if &_eligible=-1 %then %do;
        %put ERROR: derive_vars_dtm: highest_imputation must be exactly n s m h D M or Y (case sensitive).;
        %let _error=1;
    %end;
    %else %put NOTE: derive_vars_dtm: highest_imputation=%superq(_highest) (ASCII=&_level_code), resolved level=&_eligible..;
    %if &_flagimp ne auto and &_flagimp ne both and &_flagimp ne date and
        &_flagimp ne time and &_flagimp ne none %then %do;
        %put ERROR: derive_vars_dtm: Invalid flag_imputation.;
        %let _error=1;
    %end;
    %if &_preserve ne Y and &_preserve ne N %then %do;
        %put ERROR: derive_vars_dtm: preserve must be Y or N.;
        %let _error=1;
    %end;
    %if &_ignsec ne Y and &_ignsec ne N %then %do;
        %put ERROR: derive_vars_dtm: ignore_seconds_flag must be Y or N.;
        %let _error=1;
    %end;
    %let _date_month=;
    %let _date_day=;
    %if &_dateimp ne first and &_dateimp ne mid and &_dateimp ne last %then %do;
        %if %sysfunc(prxmatch(%str(/^[0-9]{2}-[0-9]{2}$/),%superq(_dateimp)))=0 %then %do;
            %put ERROR: derive_vars_dtm: date_imputation must be first mid last or MM-DD.;
            %let _error=1;
        %end;
        %else %do;
            %let _date_month=%sysfunc(inputn(%substr(&_dateimp,1,2),2.));
            %let _date_day=%sysfunc(inputn(%substr(&_dateimp,4,2),2.));
            %if &_date_month<1 or &_date_month>12 or &_date_day<1 or &_date_day>31 %then %do;
                %put ERROR: derive_vars_dtm: Invalid MM-DD date_imputation.;
                %let _error=1;
            %end;
        %end;
    %end;
    %let _th=;
    %let _tmin=;
    %let _ts=;
    %if &_timeimp ne first and &_timeimp ne last %then %do;
        %if %sysfunc(prxmatch(%str(/^[0-9]{2}:[0-9]{2}:[0-9]{2}$/),%superq(_timeimp)))=0 %then %do;
            %put ERROR: derive_vars_dtm: time_imputation must be first last or HH:MM:SS.;
            %let _error=1;
        %end;
        %else %do;
            %let _th=%sysfunc(inputn(%substr(&_timeimp,1,2),2.));
            %let _tmin=%sysfunc(inputn(%substr(&_timeimp,4,2),2.));
            %let _ts=%sysfunc(inputn(%substr(&_timeimp,7,2),2.));
            %if &_th>23 or &_tmin>59 or &_ts>59 %then %do;
                %put ERROR: derive_vars_dtm: Invalid HH:MM:SS time_imputation.;
                %let _error=1;
            %end;
        %end;
    %end;
    %if &_eligible=7 %then %do;
        %if &_dateimp ne first and &_dateimp ne last %then %do;
            %put ERROR: derive_vars_dtm: Y imputation requires first or last date_imputation.;
            %let _error=1;
        %end;
        %if &_dateimp=first and %superq(min_dates)=%str() and
            %superq(min_dates_strict)=%str() %then %do;
            %put ERROR: derive_vars_dtm: Y/first requires a minimum boundary.;
            %let _error=1;
        %end;
        %if &_dateimp=last and %superq(max_dates)=%str() and
            %superq(max_dates_strict)=%str() %then %do;
            %put ERROR: derive_vars_dtm: Y/last requires a maximum boundary.;
            %let _error=1;
        %end;
    %end;
    %if &_error %then %do;
        %put ERROR: derive_vars_dtm: Validation failed. Macro stopped after parameter validation failure.;
        %return;
    %end;
    %if not %sysfunc(exist(&dataset)) %then %do;
        %put ERROR: derive_vars_dtm: Input dataset &dataset does not exist.;
        %return;
    %end;
    %let _dsid=%sysfunc(open(&dataset,i));
    %if &_dsid=0 %then %do;
        %put ERROR: derive_vars_dtm: Unable to open &dataset..;
        %return;
    %end;
    %let _dtcnum=%sysfunc(varnum(&_dsid,&dtc));
    %if &_dtcnum=0 %then %do;
        %put ERROR: derive_vars_dtm: Variable &dtc does not exist.;
        %let _error=1;
    %end;
    %else %if %sysfunc(vartype(&_dsid,&_dtcnum)) ne C %then %do;
        %put ERROR: derive_vars_dtm: &dtc must be character.;
        %let _error=1;
    %end;
    %do _j=1 %to 4;
        %if &_j=1 %then %let _list=&min_dates;
        %else %if &_j=2 %then %let _list=&min_dates_strict;
        %else %if &_j=3 %then %let _list=&max_dates;
        %else %let _list=&max_dates_strict;
        %let _n=%sysfunc(countw(%superq(_list),%str( )));
        %do _i=1 %to &_n;
            %let _var=%scan(%superq(_list),&_i,%str( ));
            %let _vnum=%sysfunc(varnum(&_dsid,&_var));
            %if &_vnum=0 %then %do;
                %put ERROR: derive_vars_dtm: Boundary variable &_var does not exist.;
                %let _error=1;
            %end;
            %else %if %sysfunc(vartype(&_dsid,&_vnum)) ne N %then %do;
                %put ERROR: derive_vars_dtm: Boundary variable &_var must be numeric.;
                %let _error=1;
            %end;
        %end;
    %end;
    %if %upcase(&dtc)=%upcase(&_dtm) or %upcase(&dtc)=%upcase(&_dtf) or
        %upcase(&dtc)=%upcase(&_tmf) %then %do;
        %put ERROR: derive_vars_dtm: dtc must not be the same as a generated output variable.;
        %let _error=1;
    %end;
    %let _existing_dtf=%sysfunc(varnum(&_dsid,&_dtf));
    %if %sysfunc(varnum(&_dsid,&_dtm))>0 %then
        %put WARNING: derive_vars_dtm: &_dtm exists and will be overwritten.;
    %let _make_dtf=0;
    %let _make_tmf=0;
    %if &_flagimp=both or &_flagimp=date %then %let _make_dtf=1;
    %if &_flagimp=both or &_flagimp=time %then %let _make_tmf=1;
    %if &_flagimp=auto %then %do;
        %if &_eligible>=5 %then %let _make_dtf=1;
        %if &_eligible>0 %then %let _make_tmf=1;
    %end;
    %if &_make_dtf and &_existing_dtf>0 %then %do;
      %if %sysfunc(vartype(&_dsid,&_existing_dtf)) ne C %then %do;
        %put ERROR: derive_vars_dtm: Existing &_dtf must be character.;
        %let _error=1;
      %end;
    %end;
    %if &_make_dtf and &_existing_dtf>0 %then
        %put NOTE: derive_vars_dtm: Existing &_dtf will be retained.;
    %if &_make_tmf and %sysfunc(varnum(&_dsid,&_tmf))>0 %then
        %put WARNING: derive_vars_dtm: &_tmf exists and will be overwritten.;
    %if %sysfunc(varnum(&_dsid,&_dtm))>0 %then %do;
        %let _vnum=%sysfunc(varnum(&_dsid,&_dtm));
        %if %sysfunc(vartype(&_dsid,&_vnum)) ne N %then %do;
            %put ERROR: derive_vars_dtm: Existing &_dtm must be numeric.;
            %let _error=1;
        %end;
    %end;
    %if &_make_tmf and %sysfunc(varnum(&_dsid,&_tmf))>0 %then %do;
        %let _vnum=%sysfunc(varnum(&_dsid,&_tmf));
        %if %sysfunc(vartype(&_dsid,&_vnum)) ne C %then %do;
            %put ERROR: derive_vars_dtm: Existing &_tmf must be character.;
            %let _error=1;
        %end;
    %end;
    %let _rc=%sysfunc(close(&_dsid));
    %if &_error %then %do;
        %put ERROR: derive_vars_dtm: Validation failed. Macro stopped after parameter validation failure.;
        %return;
    %end;

    data &outdata;
        set &dataset;
        length _adsk_dtc $80 _adsk_date $10 _adsk_time $12
               _adsk_token $8 _adsk_dtf $1 _adsk_tmf $1;
        length _adsk_y _adsk_mo _adsk_d _adsk_h _adsk_mi _adsk_s
               _adsk_iy _adsk_imo _adsk_id _adsk_ih _adsk_imi _adsk_is
               _adsk_level _adsk_missing_level _adsk_eligible
               _adsk_dateval _adsk_candidate _adsk_possible_lo _adsk_possible_hi
               _adsk_range_lo _adsk_range_hi _adsk_b _adsk_min _adsk_max
               _adsk_j _adsk_invalid _adsk_seen_seconds 8;
        format &_dtm datetime20.;
        %if &_make_dtf and &_existing_dtf=0 %then %do;
            length &_dtf $1;
        %end;
        %if &_make_tmf %then %do;
            length &_tmf $1;
        %end;
        /* Initialize all scratch variables on each observation. */
        call missing(_adsk_token,_adsk_level,_adsk_eligible,
                     _adsk_j,_adsk_seen_seconds);
        &_dtm=.;
        %if &_make_dtf and &_existing_dtf=0 %then %do;
            &_dtf='';
        %end;
        %if &_make_tmf %then %do;
            &_tmf='';
        %end;
        call missing(_adsk_y,_adsk_mo,_adsk_d,_adsk_h,_adsk_mi,_adsk_s,
                     _adsk_iy,_adsk_imo,_adsk_id,_adsk_ih,_adsk_imi,_adsk_is,
                     _adsk_dateval,_adsk_candidate,_adsk_possible_lo,
                     _adsk_possible_hi,_adsk_range_lo,_adsk_range_hi,
                     _adsk_b,_adsk_min,_adsk_max);
        _adsk_invalid=0;
        _adsk_dtf='';
        _adsk_tmf='';
        _adsk_dtc=strip(&dtc);
        _adsk_date=scan(_adsk_dtc,1,'T');
        _adsk_time='';
        if index(_adsk_dtc,'T') then
            _adsk_time=substr(_adsk_dtc,index(_adsk_dtc,'T')+1);
        if not missing(_adsk_dtc) then do;
            /* Validate standard ISO component layout before parsing. */
            if lengthn(_adsk_date) not in (4,7,9,10) or
               not (prxmatch('/^[0-9-]{4}(-[0-9-]{2}(-[0-9-]{2})?)?$/',strip(_adsk_date)) or
                    prxmatch('/^[0-9]{4}---[0-9]{2}$/',strip(_adsk_date)))
               then _adsk_invalid=1;
            if not missing(_adsk_time) then do;
                if lengthn(_adsk_time) not in (2,5,8) or
                   not prxmatch('/^[0-9-]{2}(:[0-9-]{2}(:[0-9-]{2})?)?$/',strip(_adsk_time))
                   then _adsk_invalid=1;
            end;
            if countc(_adsk_dtc,'T')>1 then _adsk_invalid=1;
            if index(_adsk_dtc,'T') and missing(_adsk_time) then _adsk_invalid=1;
            if lengthn(_adsk_date)>=4 and verify(substr(_adsk_date,1,4),'0123456789')=0 then
                _adsk_y=input(substr(_adsk_date,1,4),4.);
            if lengthn(_adsk_date)>=7 and verify(substr(_adsk_date,6,2),'0123456789')=0 then
                _adsk_mo=input(substr(_adsk_date,6,2),2.);
            if lengthn(_adsk_date)>=10 and verify(substr(_adsk_date,9,2),'0123456789')=0 then
                _adsk_d=input(substr(_adsk_date,9,2),2.);
            else if lengthn(_adsk_date)=9 and substr(_adsk_date,5,3)='---' and
                    verify(substr(_adsk_date,8,2),'0123456789')=0 then
                _adsk_d=input(substr(_adsk_date,8,2),2.);
            if lengthn(_adsk_time)>=2 and verify(substr(_adsk_time,1,2),'0123456789')=0 then
                _adsk_h=input(substr(_adsk_time,1,2),2.);
            if lengthn(_adsk_time)>=5 and verify(substr(_adsk_time,4,2),'0123456789')=0 then
                _adsk_mi=input(substr(_adsk_time,4,2),2.);
            if lengthn(_adsk_time)>=8 and verify(substr(_adsk_time,7,2),'0123456789')=0 then
                _adsk_s=input(substr(_adsk_time,7,2),2.);
            if not missing(_adsk_mo) and (_adsk_mo<1 or _adsk_mo>12) then _adsk_invalid=1;
            if not missing(_adsk_d) and (_adsk_d<1 or _adsk_d>31) then _adsk_invalid=1;
            if not missing(_adsk_h) and (_adsk_h<0 or _adsk_h>23) then _adsk_invalid=1;
            if not missing(_adsk_mi) and (_adsk_mi<0 or _adsk_mi>59) then _adsk_invalid=1;
            if not missing(_adsk_s) and (_adsk_s<0 or _adsk_s>59) then _adsk_invalid=1;
            if not missing(_adsk_y) and (_adsk_y=0 or _adsk_y=9999) then _adsk_invalid=1;
            /* Check month/day using calendar maximum BEFORE calling MDY. */
            if not missing(_adsk_y) and not missing(_adsk_mo) and not missing(_adsk_d)
               and not _adsk_invalid then do;
                if _adsk_d > day(intnx('month',mdy(_adsk_mo,1,_adsk_y),0,'e'))
                    then _adsk_invalid=1;
            end;
            if not missing(_adsk_y) and not missing(_adsk_mo) and not missing(_adsk_d)
               and not _adsk_invalid then do;
                _adsk_dateval=mdy(_adsk_mo,_adsk_d,_adsk_y);
                if missing(_adsk_dateval) or year(_adsk_dateval) ne _adsk_y or
                   month(_adsk_dateval) ne _adsk_mo or day(_adsk_dateval) ne _adsk_d
                   then _adsk_invalid=1;
            end;
            %if &_ignsec=Y %then %do;
                if not missing(_adsk_s) then do;
                    put 'ERROR: derive_vars_dtm: Seconds found while ignore_seconds_flag=Y. ' &dtc=;
                    _adsk_invalid=1;
                end;
            %end;
        end;
        if not _adsk_invalid and not missing(_adsk_dtc) then do;
            _adsk_iy=_adsk_y;
            _adsk_imo=_adsk_mo;
            _adsk_id=_adsk_d;
            _adsk_ih=_adsk_h;
            _adsk_imi=_adsk_mi;
            _adsk_is=_adsk_s;
            /* Missing higher components propagate to lower ones unless preserve=Y. */
            %if &_preserve=N %then %do;
                if missing(_adsk_iy) then call missing(_adsk_imo,_adsk_id,_adsk_ih,_adsk_imi,_adsk_is);
                else if missing(_adsk_imo) then call missing(_adsk_id,_adsk_ih,_adsk_imi,_adsk_is);
                else if missing(_adsk_id) then call missing(_adsk_ih,_adsk_imi,_adsk_is);
                else if missing(_adsk_ih) then call missing(_adsk_imi,_adsk_is);
                else if missing(_adsk_imi) then call missing(_adsk_is);
            %end;
            /* Highest permissible missing component: Y=7,M=6,D=5,h=4,m=3,s=2,n=0. */
            /* &_eligible resolved once, case-sensitively, before DATA step. */
            _adsk_missing_level=0;
            _adsk_level=&_eligible;
            if missing(_adsk_iy) then _adsk_missing_level=max(_adsk_missing_level,7);
            if missing(_adsk_imo) then _adsk_missing_level=max(_adsk_missing_level,6);
            if missing(_adsk_id) then _adsk_missing_level=max(_adsk_missing_level,5);
            if missing(_adsk_ih) then _adsk_missing_level=max(_adsk_missing_level,4);
            if missing(_adsk_imi) then _adsk_missing_level=max(_adsk_missing_level,3);
            if missing(_adsk_is) then _adsk_missing_level=max(_adsk_missing_level,2);
            /* &_eligible is resolved ONCE from the ASCII code. */
            _adsk_eligible=&_eligible;
            if _adsk_missing_level<=_adsk_eligible then do;
                if missing(_adsk_imo) then do;
                    if "&_dateimp"='first' then _adsk_imo=1;
                    else if "&_dateimp"='mid' then _adsk_imo=6;
                    else if "&_dateimp"='last' then _adsk_imo=12;
                    %if %superq(_date_month) ne %then %do;
                        else _adsk_imo=&_date_month;
                    %end;
                end;
                if missing(_adsk_id) then do;
                    if "&_dateimp"='first' then _adsk_id=1;
                    else if "&_dateimp"='mid' then do;
                        if missing(_adsk_mo) then _adsk_id=30;
                        else _adsk_id=15;
                    end;
                    else if "&_dateimp"='last' then do;
                        if not missing(_adsk_iy) and not missing(_adsk_imo) then
                            _adsk_id=day(intnx('month',mdy(_adsk_imo,1,_adsk_iy),0,'e'));
                    end;
                    %if %superq(_date_day) ne %then %do;
                        else _adsk_id=&_date_day;
                    %end;
                end;
                if missing(_adsk_ih) then do;
                    if "&_timeimp"='first' then _adsk_ih=0;
                    else if "&_timeimp"='last' then _adsk_ih=23;
                    %if %superq(_th) ne %then %do;
                        else _adsk_ih=&_th;
                    %end;
                end;
                if missing(_adsk_imi) then do;
                    if "&_timeimp"='first' then _adsk_imi=0;
                    else if "&_timeimp"='last' then _adsk_imi=59;
                    %if %superq(_tmin) ne %then %do;
                        else _adsk_imi=&_tmin;
                    %end;
                end;
                if missing(_adsk_is) then do;
                    if "&_timeimp"='first' then _adsk_is=0;
                    else if "&_timeimp"='last' then _adsk_is=59;
                    %if %superq(_ts) ne %then %do;
                        else _adsk_is=&_ts;
                    %end;
                end;
                if not missing(_adsk_iy) then do;
                    _adsk_dateval=mdy(_adsk_imo,_adsk_id,_adsk_iy);
                    if not missing(_adsk_dateval) and
                       month(_adsk_dateval)=_adsk_imo and day(_adsk_dateval)=_adsk_id then
                        _adsk_candidate=dhms(_adsk_dateval,_adsk_ih,_adsk_imi,_adsk_is);
                end;
            end;
            /* Full possible range from ORIGINAL components. */
            if not missing(_adsk_y) then do;
                if not missing(_adsk_mo) then do;
                    _adsk_possible_lo=dhms(mdy(_adsk_mo,1,_adsk_y),0,0,0);
                    _adsk_possible_hi=dhms(intnx('month',mdy(_adsk_mo,1,_adsk_y),0,'e'),23,59,59);
                end;
                else do;
                    _adsk_possible_lo=dhms(mdy(1,1,_adsk_y),0,0,0);
                    _adsk_possible_hi=dhms(mdy(12,31,_adsk_y),23,59,59);
                end;
                if not missing(_adsk_mo) and not missing(_adsk_d) then do;
                    _adsk_possible_lo=dhms(mdy(_adsk_mo,_adsk_d,_adsk_y),0,0,0);
                    _adsk_possible_hi=dhms(mdy(_adsk_mo,_adsk_d,_adsk_y),23,59,59);
                    if not missing(_adsk_h) then do;
                        _adsk_possible_lo=dhms(mdy(_adsk_mo,_adsk_d,_adsk_y),_adsk_h,0,0);
                        _adsk_possible_hi=dhms(mdy(_adsk_mo,_adsk_d,_adsk_y),_adsk_h,59,59);
                        if not missing(_adsk_mi) then do;
                            _adsk_possible_lo=dhms(mdy(_adsk_mo,_adsk_d,_adsk_y),_adsk_h,_adsk_mi,0);
                            _adsk_possible_hi=dhms(mdy(_adsk_mo,_adsk_d,_adsk_y),_adsk_h,_adsk_mi,59);
                            if not missing(_adsk_s) then do;
                                _adsk_possible_lo=dhms(mdy(_adsk_mo,_adsk_d,_adsk_y),_adsk_h,_adsk_mi,_adsk_s);
                                _adsk_possible_hi=_adsk_possible_lo;
                            end;
                        end;
                    end;
                end;
            end;
            _adsk_range_lo=_adsk_possible_lo;
            _adsk_range_hi=_adsk_possible_hi;
            /* For missing year, use all representable SAS datetime range. */
            if missing(_adsk_y) then do;
                _adsk_range_lo=dhms('01JAN1582'd,0,0,0);
                _adsk_range_hi=dhms('31DEC9998'd,23,59,59);
            end;
            /* First apply strict bounds to the eligibility range. */
            %do _j=1 %to 2;
                %if &_j=1 %then %let _list=&min_dates_strict;
                %else %let _list=&max_dates_strict;
                %let _n=%sysfunc(countw(%superq(_list),%str( )));
                %do _i=1 %to &_n;
                    %let _var=%scan(%superq(_list),&_i,%str( ));
                    if not missing(&_var) then do;
                        _adsk_b=&_var;
                        if index(upcase(vformat(&_var)),'DATE')=0 and
                           index(upcase(vformat(&_var)),'DT')=0 then do;
                            /* No date/datetime format: require explicit format to avoid ambiguity. */
                            put 'WARNING: derive_vars_dtm: Boundary variable &_var has no recognized date/datetime format.';
                        end;
                        if index(upcase(vformat(&_var)),'DATETIME')=0 and
                           index(upcase(vformat(&_var)),'E8601DT')=0 and
                           index(upcase(vformat(&_var)),'B8601DT')=0 then
                            %if &_j=1 %then %do;
                                _adsk_b=dhms(&_var,0,0,0);
                            %end;
                            %else %do;
                                _adsk_b=dhms(&_var,23,59,59);
                            %end;
                        if &_j=1 and _adsk_b>_adsk_range_lo then _adsk_range_lo=_adsk_b;
                        if &_j=2 and _adsk_b<_adsk_range_hi then _adsk_range_hi=_adsk_b;
                    end;
                %end;
            %end;
            /* Choose applicable minimum and maximum boundary in strict-filtered range. */
            %do _j=1 %to 4;
                %if &_j=1 %then %let _list=&min_dates;
                %else %if &_j=2 %then %let _list=&min_dates_strict;
                %else %if &_j=3 %then %let _list=&max_dates;
                %else %let _list=&max_dates_strict;
                %let _n=%sysfunc(countw(%superq(_list),%str( )));
                %do _i=1 %to &_n;
                    %let _var=%scan(%superq(_list),&_i,%str( ));
                    if not missing(&_var) then do;
                        _adsk_b=&_var;
                        if index(upcase(vformat(&_var)),'DATETIME')=0 and
                           index(upcase(vformat(&_var)),'E8601DT')=0 and
                           index(upcase(vformat(&_var)),'B8601DT')=0 then
                            %if &_j<=2 %then %do;
                                _adsk_b=dhms(&_var,0,0,0);
                            %end;
                            %else %do;
                                _adsk_b=dhms(&_var,23,59,59);
                            %end;
                        if _adsk_b>=_adsk_range_lo and _adsk_b<=_adsk_range_hi then do;
                            %if &_j<=2 %then %do;
                                if missing(_adsk_min) or _adsk_b>_adsk_min then _adsk_min=_adsk_b;
                            %end;
                            %else %do;
                                if missing(_adsk_max) or _adsk_b<_adsk_max then _adsk_max=_adsk_b;
                            %end;
                        end;
                    end;
                %end;
            %end;
            /* Missing-year imputation is anchored to min/max boundary. */
            %if &_eligible=7 %then %do;
                if missing(_adsk_y) then do;
                    %if &_dateimp=first %then %do;
                        _adsk_candidate=_adsk_min;
                    %end;
                    %else %do;
                        _adsk_candidate=_adsk_max;
                    %end;
                end;
            %end;
            if not missing(_adsk_candidate) then do;
                if not missing(_adsk_min) then _adsk_candidate=max(_adsk_candidate,_adsk_min);
                if not missing(_adsk_max) then _adsk_candidate=min(_adsk_candidate,_adsk_max);
                &_dtm=_adsk_candidate;
            end;
            /* DTF: highest missing/changed date component. */
            if not missing(&_dtm) then do;
                if missing(_adsk_y) or (not missing(_adsk_y) and year(datepart(&_dtm)) ne _adsk_y) then _adsk_dtf='Y';
                else if missing(_adsk_mo) or month(datepart(&_dtm)) ne _adsk_mo then _adsk_dtf='M';
                else if missing(_adsk_d) or day(datepart(&_dtm)) ne _adsk_d then _adsk_dtf='D';
                if missing(_adsk_h) or hour(&_dtm) ne _adsk_h then _adsk_tmf='H';
                else if missing(_adsk_mi) or minute(&_dtm) ne _adsk_mi then _adsk_tmf='M';
                else if missing(_adsk_s) or second(&_dtm) ne _adsk_s then _adsk_tmf='S';
                %if &_ignsec=Y %then %do;
                    if _adsk_tmf='S' then _adsk_tmf='';
                %end;
            end;
        end;
        else if _adsk_invalid then do;
            _error_=0;
            put 'WARNING: derive_vars_dtm: Invalid/unsupported DTC; output set missing. ' &dtc=;
        end;
        %if &_make_dtf and &_existing_dtf=0 %then %do;
            &_dtf=_adsk_dtf;
        %end;
        %if &_make_tmf %then %do;
            &_tmf=_adsk_tmf;
        %end;
        drop _adsk_:;
    run;
    %if &syserr>4 %then %do;
        %put ERROR: derive_vars_dtm: DATA step failed for &outdata (SYSERR=&syserr).;
        %return;
    %end;
    %put NOTE: derive_vars_dtm: Successfully created &_dtm in &outdata..;
%mend derive_vars_dtm;
