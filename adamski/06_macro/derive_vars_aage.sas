/*** HELP START ***//*

### Macro:

    %derive_vars_aage

### Purpose:

    Derives analysis age variables `AAGE` (numeric) and `AAGEU` (unit) from a start and end date/datetime.
    Supports two calculation modes:
    - `INTERVAL`: uses calendar interval counting for YEARS/MONTHS/WEEKS.
    - `DURATION`: uses exact elapsed time converted to the requested unit (with average year/month lengths).

### Parameters:

 - `start_date` (required) :
    Start date/datetime variable (default: `BRTHDT`).
 - `end_date` (required) :
    End date/datetime variable (default: `RANDDT`).
 - `age_unit` (required) :
    Unit for age calculation. Supported (case-insensitive synonyms):
    YEARS (YEAR/YEARS/Y/YR/YRS),
    MONTHS (MONTH/MONTHS/MO/MOS),
    WEEKS (WEEK/WEEKS/WK/WKS/W),
    DAYS (DAY/DAYS/D),
    HOURS (HOUR/HOURS/H/HR/HRS),
    MINUTES (MINUTE/MINUTES/MIN/MINS),
    SECONDS (SECOND/SECONDS/SEC/SECS/S).
 - `type` (required) :
    Calculation type: `INTERVAL` or `DURATION` (default: `INTERVAL`).
 - `digits` (optional) :
    If provided and >= 1, rounds `AAGE` to the given number of decimal places.

### Output variables (created in the DATA step scope):

 - `AAGE`	: numeric derived age value
 - `AAGEU`	: character unit label (for records with AAGE ne null)

### Notes:

- The macro auto-detects whether inputs are DATE or DATETIME by checking if absolute values exceed 100,000.

### Sample code:

~~~sas
data test_aage;
  length USUBJID $10;
  format BRTHDT RANDDT yymmdd10.
         BRTHDTM RANDDTM datetime19.;
  
  * 1. Standard setting ;
  USUBJID = "SUBJ01";
  BRTHDT  = '06SEP1984'd;
  RANDDT  = '24FEB2020'd;
  BRTHDTM = dhms(BRTHDT, 0, 0, 0);
  RANDDTM = dhms(RANDDT, 0, 0, 0);
  output;

  * 2. Leap year ;
  USUBJID = "SUBJ02";
  BRTHDT  = '01FEB2000'd;
  RANDDT  = '01MAR2000'd;
  BRTHDTM = dhms(BRTHDT, 0, 0, 0);
  RANDDTM = dhms(RANDDT, 0, 0, 0);
  output;

  * 3. End of month - Start of month ;
  USUBJID = "SUBJ03";
  BRTHDT  = '31JAN2021'd;
  RANDDT  = '28FEB2021'd;
  BRTHDTM = dhms(BRTHDT, 0, 0, 0);
  RANDDTM = dhms(RANDDT, 0, 0, 0);
  output;

  * 4. end < start (negative age) ;
  USUBJID = "SUBJ04";
  BRTHDT  = '01JAN2020'd;
  RANDDT  = '01JAN2019'd;
  BRTHDTM = dhms(BRTHDT, 0, 0, 0);
  RANDDTM = dhms(RANDDT, 0, 0, 0);
  output;

  * 5. Same date ;
  USUBJID = "SUBJ05";
  BRTHDT  = '15JUN2010'd;
  RANDDT  = '15JUN2010'd;
  BRTHDTM = dhms(BRTHDT, 0, 0, 0);
  RANDDTM = dhms(RANDDT, 0, 0, 0);
  output;

  * 6. Different time ;
  USUBJID = "SUBJ06";
  BRTHDT  = '01JAN2000'd;
  RANDDT  = '02JAN2000'd;
  BRTHDTM = dhms('01JAN2000'd, 12, 0, 0);
  RANDDTM = dhms('02JAN2000'd,  6, 0, 0);
  output;

  * 7. start missing ;
  USUBJID = "SUBJ07";
  BRTHDT  = .;
  RANDDT  = '01JAN2020'd;
  BRTHDTM = .;
  RANDDTM = dhms(RANDDT, 0, 0, 0);
  output;

  * 8. end missing ;
  USUBJID = "SUBJ08";
  BRTHDT  = '01JAN1980'd;
  RANDDT  = .;
  BRTHDTM = dhms(BRTHDT, 0, 0, 0);
  RANDDTM = .;
  output;
run;

data adsl;
  set test_aage;
  %derive_vars_aage(
    start_date = BRTHDTM,
    end_date   = RANDDTM,
    age_unit   = weeks,
    type       = duration,
    digits     = 2
  )
run;

~~~
### URL:
https://github.com/PharmaForest/adamski

---
Author:                 	  Ryo Nakaya
Latest update Date:     2026-02-07
---

*//*** HELP END ***/

%macro derive_vars_aage(
    start_date	= BRTHDT,
    end_date		= RANDDT,
    age_unit		= YEARS,
    type			= INTERVAL,
	digits			=
);

options MINOPERATOR ; /* enable macro in operator */
  %local _unit _type _aageu_len round_val;

  %let _unit = %upcase(&age_unit) ;
  %let _type = %upcase(&type);

  %if &_unit in (YEAR YEARS Y YR YRS)						%then %let _unit = YEARS;
  %else %if &_unit in (MONTH MONTHS MO MOS)			%then %let _unit = MONTHS;
  %else %if &_unit in (WEEK WEEKS WK WKS W)			%then %let _unit = WEEKS;
  %else %if &_unit in (DAY DAYS D)							%then %let _unit = DAYS;
  %else %if &_unit in (HOUR HOURS H HR HRS)			%then %let _unit = HOURS;
  %else %if &_unit in (MINUTE MINUTES MIN MINS)		%then %let _unit = MINUTES;
  %else %if &_unit in (SECOND SECONDS SEC SECS S) %then %let _unit = SECONDS;
  %else %do;
    %put ERROR: Unsupported age_unit=&age_unit;
    %return;
  %end;

  %let _aageu_len = %length(&_unit); /* length of unit */

  %if not( &_type in (INTERVAL DURATION) ) %then %do ;
    %put ERROR: derive_vars_aage: type must be INTERVAL or DURATION. Got type=&type;
    %return;
  %end;

    length AAGE 8 AAGEU $&_aageu_len ;
    AAGE = .;
	AAGEU = "";

	/* Decide DATE(1) vs DATETIME(0) : Date should not exceed 100,000 */
    if abs(&start_date) > 100000 or abs(&end_date) > 100000 then _is_date = 0;
    else _is_date = 1; 

    if missing(&start_date) or missing(&end_date) then do;
      AAGE = .;
	  goto end_derive_vars_aage;
    end;
    else do;
      /* type = INTERVAL */
      if "&_type" = "INTERVAL" then do;
        if _is_date = 0 then do; /* Datetime */
          select ("&_unit");
            when ("YEARS")		AAGE = intck('year' , &start_date, &end_date, 'c');
            when ("MONTHS")	AAGE = intck('month', &start_date, &end_date, 'c');
            when ("WEEKS")		AAGE = intck('week' , &start_date, &end_date, 'c');
            when ("DAYS")		AAGE = (&end_date - &start_date) / 86400; /* 24*60*60 */
            when ("HOURS")		AAGE = (&end_date - &start_date) / 3600;
            when ("MINUTES")	AAGE = (&end_date - &start_date) / 60;
            when ("SECONDS")	AAGE = (&end_date - &start_date);
            otherwise				AAGE = .;
          end;
        end;
        else do; /* Date */
          select ("&_unit");
            when ("YEARS")		AAGE = intck('year' , &start_date, &end_date, 'c');
            when ("MONTHS")	AAGE = intck('month', &start_date, &end_date, 'c');
            when ("WEEKS")		AAGE = intck('week' , &start_date, &end_date, 'c');
            when ("DAYS")		AAGE = (&end_date - &start_date);
            when ("HOURS")		AAGE = ((&end_date - &start_date) * 86400) / 3600;
            when ("MINUTES")	AAGE = ((&end_date - &start_date) * 86400) / 60;
            when ("SECONDS")	AAGE = ((&end_date - &start_date) * 86400);
            otherwise				AAGE = .;
          end;
        end;
      end;

      /* type = DURATION */
      else if "&_type" = "DURATION" then do;
        if _is_date = 0 then do;
          _delta_sec = (&end_date - &start_date);
        end;
        else do;
          _delta_sec = (&end_date - &start_date) * 86400; /* 24*60*60 */
        end;

        select ("&_unit");
          when ("YEARS")			AAGE = _delta_sec / (365.25 * 86400);
          when ("MONTHS")		AAGE = _delta_sec / (30.4375 * 86400);
          when ("WEEKS")		AAGE = _delta_sec / (7 * 86400);
          when ("DAYS")			AAGE = _delta_sec / 86400;
          when ("HOURS")		AAGE = _delta_sec / 3600;
          when ("MINUTES")		AAGE = _delta_sec / 60;
          when ("SECONDS")	AAGE = _delta_sec;
          otherwise					AAGE = .;
        end;
      end;
    end;

	/* Compute rounding factor (e.g., 0.01 for 2 decimals, 0.0001 for 4) */
	%if &digits ge 1 %then %do;
  		%let round_val = %sysevalf(1 / (10 ** &digits.)); 
  		AAGE=round(AAGE, &round_val); 
	%end;

	if AAGE ne . then AAGEU = "&_unit"; /* if AAGE is not missing then map AAGEU */

    drop _is_date _delta_sec;

  end_derive_vars_aage:

%mend derive_vars_aage;
