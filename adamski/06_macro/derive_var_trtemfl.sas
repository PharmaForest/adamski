/*--------------------------------------------------------------
  Original Reporting Effort   : PharmaForest
  Program Name                : derive_var_trtemfl.sas
  SAS Version                 : 9.4
  Purpose (short description) : Treatment-emergent flag for date or datetime
  Author                      : Cursor 4.7 edited by P. Robertson
  Date                        : 12NOV2026
  Input Datasets or Metadata  : AE or CM analysis dataset, one row per event
  Modification Log            : 13NOV2026 - day_impute_teae and pre-treatment grade.
                                15NOV2026 - Split into check, classify, pre-max,
                                and assign. SCR01-SCR04 keep the path.
                                15NOV2026 - A missing onset day and an in-window
                                onset both still use the pre-treatment grade.
                                15NOV2026 - The rule priority is in the header.
                                15NOV2026 - A missing day is not a known pre-treatment onset.
                                16NOV2026 - Public name is derive_var_trtemfl.

  %derive_var_trtemfl

  The driver calls four macros.

  1. _trtemfl_check_args
     Reads the macro arguments and the columns on dataset=.
     An illegal argument writes ERROR and the driver stops.
     A dataset with no onset, or no treatment start, writes WARNING
     and the driver stops without creating out=. That is GS-TE-00.
     A term variable that starts with CM is a concomitant-medication
     call. Pre-treatment severity is not used for CM.

  2. _trtemfl_classify
     Reads xxDTM, then xxDT, then xxDTC. Builds the timing path.
     SCR01 is the onset source. SCR02 is the timing path.
     This step also marks rows that started before treatment.
     The severity step uses that mark, so classify runs before it.

  3. _trtemfl_pre_max
     AE only. Maximum ATOXGR on pre-treatment rows for one
     USUBJID and AEDECOD. SCR03 holds NONE, MISS, NA, or the maximum.
     A missing grade on any pre-treatment row sets SCR03 to MISS so a
     later in-window row cannot be cleared. CM sets SCR03 to NA.

  4. _trtemfl_assign
     One timing path is chosen. Ended-before, onset-before, and
     after-window stop there. An in-window onset and a missing day
     whose month meets the window both continue into the same
     pre-treatment grade check. SCR04 is the rule that wrote the flag.

  One SELECT runs and the first match wins. SCR02 is the timing path.
  SCR04 is the single rule that wrote the flag.

  Rule priority
    1. Missing treatment start sets the flag to Y.
    2. An event that ended before treatment stays blank. Later rules do not change that.
    3. A missing day in AESTDTC (start_dtc) whose month meets the window is a candidate.
       With day_impute_teae=YES, the imputed day is not trusted, so this comes before
       onset before treatment.
    4. A partial date that overlaps the window is Y. A partial date outside the window stays blank.
    5. A missing onset that is not a partial date is Y.
    6. An onset before treatment, with a known day, stays blank.
    7. An onset after the window stays blank.
    8. An onset after treatment start and on or before the window end is only a candidate.
  Steps 3 and 8 then use the same grade check for that USUBJID and AEDECOD.
  The flag stays blank when the grade is not greater than a known pre-treatment maximum.
  A missing pre-treatment grade cannot clear the flag.
  No pre-treatment event for that term sets the flag to Y.

  SCR01 onset source
    DTM      numeric datetime was on the row
    DT       numeric date was on the row
    DTC_DTM  datetime parsed from xxDTC
    DTC_DT   date parsed from xxDTC
    PART     year-month or year only
    MISS     no onset

  SCR02 timing path, first match
    NO_TRT_START   treatment start is missing
    ENDED_BEFORE   the event ended before treatment
    DAY_IMPUTE_IN  imputed day, and that month meets the window
    PARTIAL_IN     partial onset overlaps the window
    PARTIAL_OUT    partial onset is outside the window
    ONSET_MISSING  onset is missing and is not a partial date
    ONSET_BEFORE   onset is before treatment
    IN_WINDOW      onset is inside the window, including the end date
    AFTER_WINDOW   onset is after the window end
    UNCLASSIFIED   no timing rule matched

  SCR04 rule
    MISS_TRT         missing treatment start, flag Y
    END_BEFORE       ended before treatment, flag blank
    DAY_IMPUTE       missing day, month meets the window, severity not used, flag Y
    DAY_IMP_NEW      missing day, month meets the window, no pre-treatment event, flag Y
    DAY_IMP_MISSGR   missing day, month meets the window, a compared grade is missing, flag Y
    DAY_IMP_WORSE    missing day, month meets the window, grade is higher than SCR03, flag Y
    DAY_IMP_NOTWORSE missing day, month meets the window, grade is not higher, flag blank
    PART_IN          partial onset overlaps the window, flag Y
    PART_OUT         partial onset is outside the window, flag blank
    ONSET_MISS       onset missing, flag Y
    ONSET_BEFORE     onset before treatment, flag blank
    AFTER_WINDOW     onset after the window, flag blank
    IN_WINDOW        in the window, severity not used, flag Y
    IN_WIN_NEW       in the window, no pre-treatment event, flag Y
    IN_WIN_MISSGR    in the window, a compared grade is missing, flag Y
    IN_WIN_WORSE     in the window, grade is higher than SCR03, flag Y
    IN_WIN_NOTWORSE  in the window, grade is not higher, flag blank
    UNCLASSIFIED     no rule matched, flag Y

  Window. half_life=6 and n_half_lives=5 give 30 days. end_window= is
  that interval in days. The window ends on TRTEDT plus the interval,
  or on TRTSDT plus the interval when TRTEDT is missing. The end date
  is included. Onset and treatment start are compared as datetimes when
  both are present, so an earlier time on the treatment start day is
  not treatment-emergent. The window end uses the date only.

  day_impute_teae=YES is the default. A populated ASTDTM means the day
  is known. When the onset xxDTC has a month and year and no day, the
  imputed ASTDT is not trusted. If that month meets the window, the row
  is a candidate and the pre-treatment grade check still runs. A grade
  that is not higher than the pre-treatment maximum stays blank. A month
  that ends before treatment, or starts after the window, does not take
  this path. day_impute_teae=NO keeps the populated date.

  An event that ended before treatment is not treatment-emergent.
  Missing treatment start, a missing onset that is not a partial date,
  a missing in-window grade, and a missing pre-treatment grade are
  treatment-emergent.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%macro _trtemfl_strip(name);
  %local _value;

  %let _value = %superq(&name);
  %if %length(&_value) > 0 %then %let &name = %qsysfunc(strip(&_value));
%mend _trtemfl_strip;


%macro _trtemfl_suffix(var, nkeep, expect, what);
  %local _sfx
         _value
         _pos;

  %let _value = %superq(&var);
  %if %length(&_value) > &nkeep %then %do;
      %let _pos = %eval(%length(&_value) - &nkeep + 1);
      %let _sfx = %upcase(%substr(&_value, &_pos));
      %if &_sfx ne &expect %then %do;
          %put WARNING: derive_var_trtemfl &var=&_value is read as &what.;
      %end;
  %end;
%mend _trtemfl_suffix;


%macro _trtemfl_check_args;
  %local _dsid
         _rc
         _hl_unit
         _term_up;

  /* Shared flags belong to derive_var_trtemfl. Do not declare them local here. */

  %if %length(&dataset) = 0 or %length(&out) = 0 %then %do;
      %put ERROR: derive_var_trtemfl requires dataset= and out=.;
      %let _trtemfl_stop = 1;
      %return;
  %end;

  %let _day_imp_te = %upcase(&day_impute_teae);
  %if &_day_imp_te ne YES and &_day_imp_te ne NO %then %do;
      %put ERROR: derive_var_trtemfl day_impute_teae must be YES or NO.;
      %let _trtemfl_stop = 1;
      %return;
  %end;

  %let _dsid = %sysfunc(open(&dataset, i));
  %if &_dsid = 0 %then %do;
      %put WARNING: derive_var_trtemfl could not open &dataset..;
      %let _trtemfl_stop = 1;
      %return;
  %end;

  %let _has_stdtm = 0;
  %let _has_sdt   = 0;
  %let _has_sdtc  = 0;
  %let _has_edtm  = 0;
  %let _has_edt   = 0;
  %let _has_edtc  = 0;
  %let _has_tsdtm = 0;
  %let _has_tsdt  = 0;
  %let _has_tedt  = 0;
  %let _has_grade = 0;
  %let _has_term  = 0;
  %let _has_subj  = 0;
  %let _gtype     = C;

  %if %length(&start_dtm)      > 0 %then %let _has_stdtm = %sysfunc(varnum(&_dsid, &start_dtm));
  %if %length(&start_date)     > 0 %then %let _has_sdt   = %sysfunc(varnum(&_dsid, &start_date));
  %if %length(&start_dtc)      > 0 %then %let _has_sdtc  = %sysfunc(varnum(&_dsid, &start_dtc));
  %if %length(&end_dtm)        > 0 %then %let _has_edtm  = %sysfunc(varnum(&_dsid, &end_dtm));
  %if %length(&end_date)       > 0 %then %let _has_edt   = %sysfunc(varnum(&_dsid, &end_date));
  %if %length(&end_dtc)        > 0 %then %let _has_edtc  = %sysfunc(varnum(&_dsid, &end_dtc));
  %if %length(&trt_start_dtm)  > 0 %then %let _has_tsdtm = %sysfunc(varnum(&_dsid, &trt_start_dtm));
  %if %length(&trt_start_date) > 0 %then %let _has_tsdt  = %sysfunc(varnum(&_dsid, &trt_start_date));
  %if %length(&trt_end_date)   > 0 %then %let _has_tedt  = %sysfunc(varnum(&_dsid, &trt_end_date));
  %if %length(&intensity)      > 0 %then %let _has_grade = %sysfunc(varnum(&_dsid, &intensity));
  %if %length(&AE_term_var)    > 0 %then %let _has_term  = %sysfunc(varnum(&_dsid, &AE_term_var));
  %if %length(&subject_var)    > 0 %then %let _has_subj  = %sysfunc(varnum(&_dsid, &subject_var));
  %if &_has_grade > 0 %then %let _gtype = %sysfunc(vartype(&_dsid, &_has_grade));
  %let _rc = %sysfunc(close(&_dsid));

  %_trtemfl_suffix(start_dtm, 3, DTM, %str(a SAS datetime));
  %_trtemfl_suffix(trt_start_dtm, 3, DTM, %str(a SAS datetime));
  %_trtemfl_suffix(end_dtm, 3, DTM, %str(a SAS datetime));
  %_trtemfl_suffix(start_date, 2, DT, %str(a SAS date));
  %_trtemfl_suffix(end_date, 2, DT, %str(a SAS date));
  %_trtemfl_suffix(trt_start_date, 2, DT, %str(a SAS date));
  %_trtemfl_suffix(trt_end_date, 2, DT, %str(a SAS date));
  %_trtemfl_suffix(start_dtc, 3, DTC, %str(an ISO8601 value));
  %_trtemfl_suffix(end_dtc, 3, DTC, %str(an ISO8601 value));

  %let _term_up = %upcase(&AE_term_var);
  %let _domain = AE;
  %if %length(&_term_up) >= 2 %then %do;
      %if %substr(&_term_up, 1, 2) = CM %then %let _domain = CM;
  %end;

  %put NOTE: derive_var_trtemfl domain=&_domain day_impute=&_day_imp_te.;
  %put NOTE: derive_var_trtemfl columns onset dtm=&_has_stdtm dt=&_has_sdt dtc=&_has_sdtc treatment dtm=&_has_tsdtm dt=&_has_tsdt end=&_has_tedt grade=&_has_grade.;

  %if (&_has_stdtm = 0 and &_has_sdt = 0 and &_has_sdtc = 0) or
      (&_has_tsdtm = 0 and &_has_tsdt = 0) %then %do;
      %put WARNING: derive_var_trtemfl did not find an onset (xxDTM, xxDT, or xxDTC) or a treatment start on &dataset.. out= was not created.;
      %let _trtemfl_stop = 1;
      %return;
  %end;

  %if &_has_edt = 0 and &_has_edtm = 0 and &_has_edtc = 0 %then %do;
      %put NOTE: derive_var_trtemfl did not find an event end. An event end cannot clear the flag.;
  %end;
  %if &_has_tedt = 0 %then %do;
      %put NOTE: derive_var_trtemfl did not find &trt_end_date.. The window ends at treatment start plus the follow-up interval.;
  %end;
  %if &_has_sdtc = 0 and %length(&start_dtc) > 0 %then %do;
      %put NOTE: derive_var_trtemfl did not find &start_dtc.. Partial dates are not used.;
  %end;

  %if &_domain = CM %then %do;
      %let _has_grade = 0;
      %put NOTE: derive_var_trtemfl term &AE_term_var is CM. Pre-treatment severity is not used.;
  %end;
  %else %if %length(&intensity) > 0 and
            (&_has_grade = 0 or &_has_term = 0 or &_has_subj = 0) %then %do;
      %put WARNING: derive_var_trtemfl did not find &intensity, &AE_term_var, or &subject_var.. Grade comparison was skipped.;
      %let _has_grade = 0;
  %end;

  %let _has_win = 0;
  %let _window  = 0;
  %if %length(&end_window) > 0 %then %do;
      %if %datatyp(&end_window) ne NUMERIC %then %do;
          %put ERROR: derive_var_trtemfl end_window must be a number of days.;
          %let _trtemfl_stop = 1;
          %return;
      %end;
      %let _window = %sysevalf(&end_window);
      %let _has_win = 1;
  %end;
  %else %if %length(&half_life) > 0 %then %do;
      %if %datatyp(&half_life) ne NUMERIC or %datatyp(&n_half_lives) ne NUMERIC %then %do;
          %put ERROR: derive_var_trtemfl half_life and n_half_lives must be numeric.;
          %let _trtemfl_stop = 1;
          %return;
      %end;
      %let _hl_unit = %upcase(&half_life_unit);
      %if &_hl_unit = HOURS or &_hl_unit = HOUR or &_hl_unit = H %then %do;
          %let _window = %sysevalf(&n_half_lives * &half_life / 24);
          %let _has_win = 1;
      %end;
      %else %if &_hl_unit = DAYS or &_hl_unit = DAY or &_hl_unit = D %then %do;
          %let _window = %sysevalf(&n_half_lives * &half_life);
          %let _has_win = 1;
      %end;
      %else %do;
          %put ERROR: derive_var_trtemfl half_life_unit must be DAYS or HOURS.;
          %let _trtemfl_stop = 1;
          %return;
      %end;
  %end;

  %if &_has_win = 1 %then %do;
      %put NOTE: derive_var_trtemfl follow-up interval is &_window days.;
  %end;
%mend _trtemfl_check_args;


%macro _trtemfl_classify;
  /* Build one row per event. SCR01 and SCR02 are kept. Working variables are dropped later. */

  data work._trtem_row;
       set &dataset;
       length _term_key _gchar _sdtc _edtc _iso _isod _isot _idtc $200
              scr01 $8
              scr02 $16;
       retain _trtem_seq 0;
       _trtem_seq + 1;

       _sdtm = .;
       _sdt = .;
       _edtm = .;
       _edt = .;
       _tsdtm = .;
       _tsdt = .;
       _tedt = .;
       _spart = 0;
       _epart = 0;
       _splo = .;
       _sphi = .;
       _eplo = .;
       _ephi = .;
       _before = 0;
       _on_after = 0;
       _ended_before = 0;
       _overlap = 0;
       _date_in = 0;
       _imp_teae = 0;
       _grade = .;
       _pre_max = .;
       _iy2 = .;
       _im2 = .;
       _imp_has_d = 0;
       _implo = .;
       _imphi = .;
       _from_dtm = 0;
       _from_dt = 0;
       _from_dtc = 0;
       _term_key = cats('#', put(_trtem_seq, best12.));
       _gchar = '';
       _sdtc = '';
       _edtc = '';
       _idtc = '';
       scr01 = 'MISS';
       scr02 = 'UNCLASSIFIED';

       /* xxDTM wins. xxDT is next. xxDTC is kept either way so a missing day can be seen. */
       %if &_has_stdtm > 0 %then %do;
           if not missing(&start_dtm) then do;
                _sdtm = &start_dtm;
                _from_dtm = 1;
           end;
       %end;
       %if &_has_sdt > 0 %then %do;
           if _from_dtm = 0 and not missing(&start_date) then do;
                _sdt = &start_date;
                _from_dt = 1;
           end;
       %end;
       %if &_has_sdtc > 0 %then %do;
           if not missing(&start_dtc) then _sdtc = strip(&start_dtc);
           if _from_dtm = 0 and _from_dt = 0 and not missing(_sdtc) then _from_dtc = 1;
       %end;

       %if &_has_edtm > 0 %then %do;
           if not missing(&end_dtm) then _edtm = &end_dtm;
       %end;
       %if &_has_edt > 0 %then %do;
           if missing(_edtm) and not missing(&end_date) then _edt = &end_date;
       %end;
       %if &_has_edtc > 0 %then %do;
           if not missing(&end_dtc) then _edtc = strip(&end_dtc);
       %end;

       %if &_has_tsdtm > 0 %then %do;
           if not missing(&trt_start_dtm) then _tsdtm = &trt_start_dtm;
       %end;
       %if &_has_tsdt > 0 %then %do;
           if missing(_tsdtm) and not missing(&trt_start_date) then _tsdt = &trt_start_date;
       %end;
       %if &_has_tedt > 0 %then %do;
           if not missing(&trt_end_date) then _tedt = &trt_end_date;
       %end;

       /* Parse xxDTC only when the numeric onset or end is still missing. */
       array _iso_src{2} $ _sdtc _edtc;
       array _iso_dt{2}    _sdt  _edt;
       array _iso_dtm{2}   _sdtm _edtm;
       array _iso_part{2}  _spart _epart;
       array _iso_lo{2}    _splo _eplo;
       array _iso_hi{2}    _sphi _ephi;

       do _k = 1 to 2;
            if missing(_iso_dtm{_k}) and missing(_iso_dt{_k}) and not missing(_iso_src{_k}) then do;
                 _iso = strip(_iso_src{_k});
                 _isod = _iso;
                 _isot = '';
                 if index(_iso, 'T') then do;
                      _isod = scan(_iso, 1, 'T');
                      _isot = scan(_iso, 2, 'T');
                 end;

                 _iy = .;
                 _im = .;
                 _id = .;
                 if length(_isod) >= 4 and notdigit(substr(_isod, 1, 4)) = 0 then _iy = input(substr(_isod, 1, 4), ?? 4.);
                 if length(_isod) >= 7 and substr(_isod, 5, 1) = '-' and substr(_isod, 6, 2) ne '--' and
                    notdigit(substr(_isod, 6, 2)) = 0 then _im = input(substr(_isod, 6, 2), ?? 2.);
                 if length(_isod) >= 10 and substr(_isod, 8, 1) = '-' and
                    notdigit(substr(_isod, 9, 2)) = 0 then _id = input(substr(_isod, 9, 2), ?? 2.);

                 _ih = .;
                 _in = .;
                 _is = .;
                 if _isot ne '' then do;
                      if length(_isot) >= 2 and notdigit(substr(_isot, 1, 2)) = 0 then _ih = input(substr(_isot, 1, 2), ?? 2.);
                      if length(_isot) >= 5 and substr(_isot, 3, 1) = ':' and
                         notdigit(substr(_isot, 4, 2)) = 0 then _in = input(substr(_isot, 4, 2), ?? 2.);
                      if length(_isot) >= 8 and substr(_isot, 6, 1) = ':' and
                         notdigit(substr(_isot, 7, 2)) = 0 then _is = input(substr(_isot, 7, 2), ?? 2.);
                 end;

                 if not missing(_iy) and not missing(_im) and not missing(_id) then do;
                      _tmpdt = mdy(_im, _id, _iy);
                      if not missing(_tmpdt) then do;
                           _iso_dt{_k} = _tmpdt;
                           if not missing(_ih) and not missing(_in) and _ih < 24 and _in < 60 then do;
                                if missing(_is) or _is >= 60 then _is = 0;
                                if _is < 60 then _iso_dtm{_k} = dhms(_tmpdt, _ih, _in, _is);
                           end;
                      end;
                 end;
                 else if not missing(_iy) and not missing(_im) and _im >= 1 and _im <= 12 then do;
                      _iso_part{_k} = 1;
                      _iso_lo{_k} = mdy(_im, 1, _iy);
                      if not missing(_iso_lo{_k}) then _iso_hi{_k} = intnx('month', _iso_lo{_k}, 0, 'E');
                 end;
                 else if not missing(_iy) and _iy >= 1582 then do;
                      _iso_part{_k} = 1;
                      _iso_lo{_k} = mdy(1, 1, _iy);
                      _iso_hi{_k} = mdy(12, 31, _iy);
                 end;
            end;
       end;

       if not missing(_sdtm) then _sdt = datepart(_sdtm);
       if not missing(_edtm) then _edt = datepart(_edtm);
       if not missing(_tsdtm) then _tsdt = datepart(_tsdtm);

       if not missing(_sdtm) and not missing(_tsdtm) then do;
            if _sdtm < _tsdtm then _before = 1;
            else _on_after = 1;
       end;
       else if not missing(_sdt) and not missing(_tsdt) then do;
            if _sdt < _tsdt then _before = 1;
            else _on_after = 1;
       end;
       else if _spart = 1 and not missing(_sphi) and not missing(_tsdt) and _sphi < _tsdt then _before = 1;

       if not missing(_edtm) and not missing(_tsdtm) then do;
            if _edtm < _tsdtm then _ended_before = 1;
       end;
       else if not missing(_edt) and not missing(_tsdt) then do;
            if _edt < _tsdt then _ended_before = 1;
       end;
       else if _epart = 1 and not missing(_ephi) and not missing(_tsdt) and _ephi < _tsdt then _ended_before = 1;

       _whi = .;
       %if &_has_win = 1 %then %do;
           if not missing(_tedt) then _whi = _tedt + &_window;
           else if not missing(_tsdt) then _whi = _tsdt + &_window;
       %end;

       /* Partial overlap is used only when both numeric onset values are missing. */
       %if &_has_win = 1 %then %do;
           if missing(_sdt) and missing(_sdtm) and _spart = 1 and _before = 0 and
              not missing(_splo) and not missing(_sphi) and not missing(_tsdt) and
              _sphi >= _tsdt and (missing(_whi) or _splo <= _whi) then _overlap = 1;
       %end;
       %else %do;
           if missing(_sdt) and missing(_sdtm) and _spart = 1 and _before = 0 and
              not missing(_splo) and not missing(_sphi) and not missing(_tsdt) and
              _sphi >= _tsdt then _overlap = 1;
       %end;

       /* A populated datetime means the day is known, so the month is not reused. */
       %if &_day_imp_te = YES and &_has_sdtc > 0 %then %do;
           if not missing(_sdt) and missing(_sdtm) and not missing(_sdtc) and not missing(_tsdt) then do;
                _idtc = strip(_sdtc);
                if index(_idtc, 'T') then _idtc = scan(_idtc, 1, 'T');
                if length(_idtc) >= 4 and notdigit(substr(_idtc, 1, 4)) = 0 then _iy2 = input(substr(_idtc, 1, 4), ?? 4.);
                if length(_idtc) >= 7 and substr(_idtc, 5, 1) = '-' and substr(_idtc, 6, 2) ne '--' and
                   notdigit(substr(_idtc, 6, 2)) = 0 then _im2 = input(substr(_idtc, 6, 2), ?? 2.);
                if length(_idtc) >= 10 and substr(_idtc, 8, 1) = '-' and substr(_idtc, 9, 2) ne '--' and
                   notdigit(substr(_idtc, 9, 2)) = 0 then _imp_has_d = 1;

                if not missing(_iy2) and not missing(_im2) and _im2 >= 1 and _im2 <= 12 and _imp_has_d = 0 then do;
                     _implo = mdy(_im2, 1, _iy2);
                     if not missing(_implo) then _imphi = intnx('month', _implo, 0, 'E');
                     %if &_has_win = 1 %then %do;
                         if not missing(_implo) and not missing(_imphi) and _imphi >= _tsdt and
                            (missing(_whi) or _implo <= _whi) then _imp_teae = 1;
                     %end;
                     %else %do;
                         if not missing(_implo) and not missing(_imphi) and _imphi >= _tsdt then _imp_teae = 1;
                     %end;
                end;
           end;
       %end;

       /* The imputed day is not a known start before treatment, so it is not its own pre-treatment grade. */
       if _imp_teae = 1 then _before = 0;

       %if &_has_win = 1 %then %do;
           if _on_after = 1 and not missing(_sdt) and not missing(_whi) and _sdt <= _whi then _date_in = 1;
       %end;
       %else %do;
           if _on_after = 1 and not missing(_sdt) then _date_in = 1;
       %end;

       %if &_domain = AE and &_has_grade > 0 %then %do;
           %if &_gtype = N %then %do;
               _grade = &intensity;
           %end;
           %else %do;
               _gchar = strip(&intensity);
               _grade = input(_gchar, ?? best32.);
               if missing(_grade) and _gchar ne '' then _grade = input(compress(_gchar, '', 'kd'), ?? best32.);
           %end;
           if not missing(&subject_var) and not missing(&AE_term_var) then _term_key = upcase(strip(&AE_term_var));
       %end;

       if _from_dtm = 1 then scr01 = 'DTM';
       else if _from_dt = 1 then scr01 = 'DT';
       else if _from_dtc = 1 and not missing(_sdtm) then scr01 = 'DTC_DTM';
       else if _from_dtc = 1 and not missing(_sdt) then scr01 = 'DTC_DT';
       else if _spart = 1 then scr01 = 'PART';
       else scr01 = 'MISS';

       /* Same first-match order as the flag SELECT. */
       if missing(_tsdt) and missing(_tsdtm) then scr02 = 'NO_TRT_START';
       else if _ended_before = 1 then scr02 = 'ENDED_BEFORE';
       else if _imp_teae = 1 then scr02 = 'DAY_IMPUTE_IN';
       else if _overlap = 1 then scr02 = 'PARTIAL_IN';
       else if _spart = 1 and missing(_sdt) and missing(_sdtm) then scr02 = 'PARTIAL_OUT';
       else if missing(_sdt) and missing(_sdtm) then scr02 = 'ONSET_MISSING';
       else if _before = 1 then scr02 = 'ONSET_BEFORE';
       else if _date_in = 1 then scr02 = 'IN_WINDOW';
       else if _on_after = 1 then scr02 = 'AFTER_WINDOW';
       else scr02 = 'UNCLASSIFIED';

       drop _sdtc _edtc _iso _isod _isot _iy _im _id _ih _in _is _tmpdt _k _gchar _idtc
            _iy2 _im2 _imp_has_d _implo _imphi
            _from_dtm _from_dt _from_dtc;
  run;
%mend _trtemfl_classify;


%macro _trtemfl_pre_max;
  %if &_domain = CM or &_has_grade = 0 %then %do;
      data work._trtem_mrg;
           set work._trtem_row;
           length scr03 $12;
           scr03 = 'NA';
           _pre_max = .;
           _pre_gap = 0;
           _pre_n = 0;
      run;
      %return;
  %end;

  %put NOTE: derive_var_trtemfl pre-treatment maximum uses &subject_var and &AE_term_var.;

  proc sort data=work._trtem_row;
       by &subject_var _term_key _trtem_seq;
  run;

  data work._trtem_pre;
       set work._trtem_row;
       by &subject_var _term_key;
       retain _pre_hold _pre_gap _pre_n;
       if first._term_key then do;
            _pre_hold = .;
            _pre_gap = 0;
            _pre_n = 0;
       end;
       if _before = 1 then do;
            _pre_n + 1;
            if missing(_grade) then _pre_gap = 1;
            else if missing(_pre_hold) then _pre_hold = _grade;
            else _pre_hold = max(_pre_hold, _grade);
       end;
       if last._term_key;
       _pre_max = _pre_hold;
       if _pre_gap = 1 then _pre_max = .;
       keep &subject_var _term_key _pre_max _pre_gap _pre_n;
  run;

  data work._trtem_mrg;
       merge work._trtem_row (drop=_pre_max)
             work._trtem_pre;
       by &subject_var _term_key;
       length scr03 $12;
       if _pre_n = 0 then scr03 = 'NONE';
       else if _pre_gap = 1 or missing(_pre_max) then scr03 = 'MISS';
       else scr03 = strip(put(_pre_max, best12.));
  run;

  proc sort data=work._trtem_mrg;
       by _trtem_seq;
  run;
%mend _trtemfl_pre_max;


%macro _trtemfl_assign;
  /* Timing chooses one path. In-window and missing-day candidates then use the grade. */

  data &out;
       set work._trtem_mrg;
       length &teae_var $1 scr04 $16;
       &teae_var = ' ';
       scr04 = 'UNCLASSIFIED';

       select (scr02);
            when ('NO_TRT_START') do;
                 &teae_var = 'Y';
                 scr04 = 'MISS_TRT';
            end;
            when ('ENDED_BEFORE') do;
                 &teae_var = ' ';
                 scr04 = 'END_BEFORE';
            end;
            when ('PARTIAL_IN') do;
                 &teae_var = 'Y';
                 scr04 = 'PART_IN';
            end;
            when ('PARTIAL_OUT') do;
                 &teae_var = ' ';
                 scr04 = 'PART_OUT';
            end;
            when ('ONSET_MISSING') do;
                 &teae_var = 'Y';
                 scr04 = 'ONSET_MISS';
            end;
            when ('ONSET_BEFORE') do;
                 &teae_var = ' ';
                 scr04 = 'ONSET_BEFORE';
            end;
            when ('AFTER_WINDOW') do;
                 &teae_var = ' ';
                 scr04 = 'AFTER_WINDOW';
            end;
            /* Both candidates: the month or the date met the window, then the grade is applied. */
            when ('DAY_IMPUTE_IN', 'IN_WINDOW') do;
                 if scr03 = 'NA' then do;
                      &teae_var = 'Y';
                      if scr02 = 'DAY_IMPUTE_IN' then scr04 = 'DAY_IMPUTE';
                      else scr04 = 'IN_WINDOW';
                 end;
                 else if scr03 = 'NONE' then do;
                      &teae_var = 'Y';
                      if scr02 = 'DAY_IMPUTE_IN' then scr04 = 'DAY_IMP_NEW';
                      else scr04 = 'IN_WIN_NEW';
                 end;
                 else if scr03 = 'MISS' or missing(_grade) then do;
                      &teae_var = 'Y';
                      if scr02 = 'DAY_IMPUTE_IN' then scr04 = 'DAY_IMP_MISSGR';
                      else scr04 = 'IN_WIN_MISSGR';
                 end;
                 else if _grade > _pre_max then do;
                      &teae_var = 'Y';
                      if scr02 = 'DAY_IMPUTE_IN' then scr04 = 'DAY_IMP_WORSE';
                      else scr04 = 'IN_WIN_WORSE';
                 end;
                 else do;
                      &teae_var = ' ';
                      if scr02 = 'DAY_IMPUTE_IN' then scr04 = 'DAY_IMP_NOTWORSE';
                      else scr04 = 'IN_WIN_NOTWORSE';
                 end;
            end;
            otherwise do;
                 &teae_var = 'Y';
                 scr04 = 'UNCLASSIFIED';
            end;
       end;

       label scr01 = "Onset source"
             scr02 = "Timing path"
             scr03 = "Pre-treatment max grade"
             scr04 = "Rule that set the flag";

       drop _trtem_seq _term_key _grade _pre_max _imp_teae
            _before _on_after _ended_before _overlap _date_in _spart _epart
            _sdt _sdtm _edt _edtm _tsdt _tsdtm _tedt _whi
            _splo _sphi _eplo _ephi _pre_gap _pre_n;
  run;
%mend _trtemfl_assign;


%macro derive_var_trtemfl(
    dataset         =
  , out             =
  , subject_var     = USUBJID
  , AE_term_var     = AEDECOD
  , teae_var        = TRTEMFL
  , start_dtm       = ASTDTM
  , start_date      = ASTDT
  , start_dtc       = AESTDTC
  , end_dtm         = AENDTM
  , end_date        = AENDT
  , end_dtc         = AEENDTC
  , trt_start_dtm   = TRTSDTM
  , trt_start_date  = TRTSDT
  , trt_end_date    = TRTEDT
  , end_window      =
  , half_life       = 6
  , half_life_unit  = DAYS
  , n_half_lives    = 5
  , intensity       = ATOXGR
  , day_impute_teae = YES
);

  %local _trtemfl_stop
         _domain
         _day_imp_te
         _has_stdtm _has_sdt _has_sdtc
         _has_edtm _has_edt _has_edtc
         _has_tsdtm _has_tsdt _has_tedt
         _has_grade _has_term _has_subj
         _gtype
         _has_win _window;

  %let _trtemfl_stop = 0;
  %let _domain = AE;
  %let _day_imp_te = YES;
  %let _has_win = 0;
  %let _window = 0;
  %let _has_grade = 0;

  %_trtemfl_strip(dataset);
  %_trtemfl_strip(out);
  %_trtemfl_strip(subject_var);
  %_trtemfl_strip(AE_term_var);
  %_trtemfl_strip(teae_var);
  %_trtemfl_strip(start_dtm);
  %_trtemfl_strip(start_date);
  %_trtemfl_strip(start_dtc);
  %_trtemfl_strip(end_dtm);
  %_trtemfl_strip(end_date);
  %_trtemfl_strip(end_dtc);
  %_trtemfl_strip(trt_start_dtm);
  %_trtemfl_strip(trt_start_date);
  %_trtemfl_strip(trt_end_date);
  %_trtemfl_strip(end_window);
  %_trtemfl_strip(half_life);
  %_trtemfl_strip(half_life_unit);
  %_trtemfl_strip(n_half_lives);
  %_trtemfl_strip(intensity);
  %_trtemfl_strip(day_impute_teae);

  %_trtemfl_check_args;
  %if &_trtemfl_stop = 1 %then %return;

  %_trtemfl_classify;
  %_trtemfl_pre_max;
  %_trtemfl_assign;

  proc datasets lib=work nolist;
       delete _trtem_row
              _trtem_mrg
              %if &_domain = AE and &_has_grade > 0 %then %do;
                  _trtem_pre
              %end;
              ;
  quit;
%mend derive_var_trtemfl;
