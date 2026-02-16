# Adamski (Latest version 0.0.6 on 26Feb2026)
Adamski is a SAS package inspired by the R package {admiral}. It aims to bring the same flexible and modular ADaM derivation framework to the SAS environment. The package follows the {admiral} design principles while adapting to SAS syntax and workflows. It enables consistent, reproducible ADaM dataset creation in compliance with CDISC standards.  
Adamski serves as a bridge between open-source R implementations and traditional SAS programming.  

![adamski](./adamski_logo_small.png)  

Please see more detailed concepts and construction map in [Adamski and Admiral](./Adamski_and_Admiral.md).

---

## %derive_vars_dy() 

### Purpose:
   Generates study day (`DY`) variables from given date variables using a specified reference date(e.g., `TRTSDT`). 
   
### Parameters:
~~~sas
 reference_date   = Reference date variable (e.g. TRTSDT) used as Day 1  
 source_vars      = Space-separated list of source date variables(--DT) for which DY variables will be derived.
~~~

### Example usage: 
~~~sas
data ADAE;
  merge SDTM.AE ADSL;
  by USUBJID;
  %derive_vars_dy(
       reference_date = TRTSDT,  
       source_vars    = AESTDT AEENDT  
   );
run;
~~~

 Author:             Ryo Nakaya  
 Latest update Date: 2025-10-14  

## %derive_var_merged_exist_flag()  

### Purpose:  
   Creates a character flag variable indicating whether the current DATA step row's key(s) exist in another dataset.   

### Parameters:
~~~sas
 - `dataset_add` (required) : Dataset to check for existence (e.g., `SDTM.AE`).
 - `by_vars`     (required) : Space-separated list of key variables used for the lookup.
 - `new_var`     (required) : Name of the output flag variable to create (character).
 - `condition`   (optional) : WHERE clause (as text) applied to `dataset_add` before building  the hash (e.g., `%nrbquote(SEX="F")`). If omitted, all rows are used.
 - `true_value`  (optional) : Value assigned to `new_var` when a match is found.
                              Default: `Y`.
 - `false_value` (optional) : Value assigned to `new_var` when no match is found.
                              Default: (blank).
~~~
### Example Usage:
~~~sas
data have;
  do SEX="F","M"; do AGE=12 to 17; output; end; end;
run;

data want;
  set have;
  *Single key;
  %derive_var_merged_exist_flag(
    dataset_add = SASHELP.CLASS,
    by_vars     = AGE,
    new_var     = AGE_IN_CLASS,
    true_value  = Y,
    false_value = N
  );

  * Multiple keys;
  %derive_var_merged_exist_flag(
    dataset_add = SASHELP.CLASS,
    by_vars     = AGE SEX,
    new_var     = AGE_SEX_IN_CLASS
  );

  * With condition ;
  %derive_var_merged_exist_flag(
    dataset_add = SASHELP.CLASS,
    by_vars     = AGE,
    condition   = %nrbquote(SEX="F"),
    new_var     = AGE_IN_CLASS_F_ONLY,
    true_value  = Yes,
    false_value = No
  );
run;
~~~
 Author:             Yutaka Morioka  
 Latest update Date: 2025-10-15  

## %derive_var_age_years() 

### Purpose:
   Converts a set of age values from the specified time unit to years.   
   
### Parameters:
~~~sas
 - `age_var` (required)	: The ages to convert.  
 - `age_unit` (required) : Age unit. Note that permitted values are cases insensitive (e.g. "YEARS" is treated the same as "years" and "Years").
 							Permitted values "years", "months", "weeks", "days", "hours", "minutes", "seconds"
 - `new_var`  (required) : New age variable to be created in years.
 - `digits` (optional, default=blank) : Allows rounding of "new_var" variable based on the parameter value passed. No rounding is applied, if left blank.  
~~~

### Example usage: 
~~~sas
data data1;
  input age ageu $;
  datalines;
  240 MONTHS
  350 MONTHS
  490 MONTHS
  ;  
run;
data test1;
  set data1;  
   %derive_var_age_years(age_var=age, age_unit=ageu, new_var=aage1);
   %derive_var_age_years(age_var=age, age_unit="MONTHS", new_var=aage2);
   %derive_var_age_years(age_var=age, age_unit=ageu, new_var=aage3, digits=3);
run;
~~~

 Author:             Sharad Chhetri  
 Latest update Date: 2025-10-21  

## %derive_vars_duration() 

### Purpose:
   Derives duration between two dates, specified by the variables present in the input dataset (e.g., duration of adverse events, relative day, age, etc.).    
   
### Parameters:
~~~sas
 - `new_var` (required) : Name of the new variable to created.
 - `new_var_unit` (optional) : Name of the unit variable 
 - `start_date` (required) : Start date/datetime variable
 - `end_date` (required) : End date/datetime variable
 - `in_unit` (required, default=days) : Name of the input unit
 - `out_unit` (required, default=days) : Name of the output unit
 - `floor_in` (required, default=Y) : If Y, floor datetime values to date before computing
 - `add_one` (required, default=Y) : Add 1 to duration if Y 
 - `trunc_out` (required, default=N) : Truncate output duration to integer value if Y
 - `type` (required, default=duration) : Type of calculation
~~~

### Example usage: 
~~~sas
data test1;
  input USUBJID $ BRTHDT :yymmdd10. RANDDT :yymmdd10.;
  format BRTHDT RANDDT yymmdd10.;
  datalines;
  P01 1984-09-06 2020-02-24
  P02 1985-01-01 .
  P03 . 2021-03-10
  P04 . .
  P05 1971-10-10 2025-10-30
  ;
run;

data test1_op;
set test1;
	%derive_vars_duration(
	  new_var=AAGE,
	  new_var_unit=AAGEU,
	  start_date=BRTHDT,
	  end_date=RANDDT,
	  out_unit=years,
	  add_one=N,
	  trunc_out=Y
	);
run;
~~~

 Author:             Sharad Chhetri  
 Latest update Date: 2025-11-17  

## %derive_locf_records() 

### Purpose:
   Add LOCF records (Last Observation Carried Forward) to a dataset based on an "expected observations" reference dataset.    
   
### Parameters:
~~~sas
 - `dataset` (required)	: Input dataset (with original observations)  
 - `dataset_ref` (required)	: Expected-observations dataset (combinations of PARAMCD/AVISIT/etc)  
 - `by_vars` (required)	: Space-separated list of grouping variables (e.g. STUDYID USUBJID PARAMCD)  
 - `id_vars_ref` (optional, default=blank) : Space-separated list of id variables present in data_ref (optional). If blank, ALL vars from data_ref will be used as id_vars_ref.  
 - `analysis_var` (required, default=aval) : Analysis variable to LOCF  
 - `imputation` (required, default=add) : One of add | update | update_add   
                                   `add`: Keep all original records and add imputed records for missing timepoints and missing `analysis_var` values from `dataset_ref`.  
								`update`: Update records with missing `analysis_var` and add imputed records for missing timepoints from `dataset_ref`.  
					        `update_add`: Keep all original records, update records with missing `analysis_var` and add imputed records for missing timepoints from `dataset_ref`.  
 - `order` (required) : Space-separated variables to sort by within by_vars (e.g. AVISITN AVISIT)  
 - `keep_vars` (optional) : Space-separated vars to carry forward in addition to analysis_var (optional)  
 - `outdata` (optional, default=&dataset._locf): Output dataset with LOCF  
~~~

### Example usage: 
~~~sas
data input1;
  length STUDYID $6 USUBJID $12 PARAMCD $5 PARAM $40 AVISIT $20;       
  infile datalines dlm='|' truncover;
  input STUDYID $ USUBJID $ PARAMCD $ PARAM $ AVAL AVISITN AVISIT $;
datalines;
TEST01|01-701-1015|DIABP|Diastolic Blood Pressure (mmHg)|51|0|BASELINE
TEST01|01-701-1015|DIABP|Diastolic Blood Pressure (mmHg)|50|2|WEEK 2
TEST01|01-701-1015|SYSBP|Systolic Blood Pressure (mmHg)|121|0|BASELINE
TEST01|01-701-1015|SYSBP|Systolic Blood Pressure (mmHg)|121|2|WEEK 2
TEST01|01-701-1028|DIABP|Diastolic Blood Pressure (mmHg)|79|0|BASELINE
TEST01|01-701-1028|SYSBP|Systolic Blood Pressure (mmHg)|130|0|BASELINE
;
run;

data expected_obsv1;
  length PARAMCD $5 PARAM $40 AVISIT $20;
  infile datalines dlm='|' truncover;
  input PARAMCD $ PARAM $ AVISITN AVISIT $;
datalines;
DIABP|Diastolic Blood Pressure (mmHg)|0|BASELINE
DIABP|Diastolic Blood Pressure (mmHg)|2|WEEK 2
SYSBP|Systolic Blood Pressure (mmHg)|0|BASELINE
SYSBP|Systolic Blood Pressure (mmHg)|2|WEEK 2
;
run;

%derive_locf_records(
  dataset=input1,
  dataset_ref=expected_obsv1,
  by_vars=STUDYID USUBJID PARAM PARAMCD,
  id_vars_ref=PARAMCD PARAM AVISITN AVISIT,  
  analysis_var=aval, 
  imputation=add, 
  order=AVISITN AVISIT,
  keep_vars=,  
  outdata=output_test1
);
~~~  

 Author:             Sharad Chhetri  
 Latest update Date: 2025-12-21  

## %derive_var_base()

### Purpose:
  Derive baseline variables (e.g. BASE, BASEC, BNRIND) in a BDS dataset.  

### Parameters:  
~~~sas
 - `dataset` (required) : Name of the input daset
 - `by_vars` (required) : Space-separated list of BY variables (e.g. USUBJID PARAMCD)
 - `source_var` (required, default=AVAL) : Variable from which baseline value is taken
 - `new_var` (required, default=BASE) : Name of the new variable to created.
 - `filter` (required, default= ABLFL = "Y") : Baseline filter condition
 - `outdata` (optional, default=&dataset._base): Output dataset with new baseline variable 
~~~

### Example usage:  
~~~sas
data adlb1 adlb2 adlb3;
  length
    STUDYID  $6
    USUBJID  $6
    PARAMCD  $7
    AVISIT   $9
    ABLFL    $1
    ANRIND   $6
    AVALC    $6
  ;

  input
    STUDYID $
    USUBJID $
    PARAMCD $
    AVAL
    AVALC $
    AVISIT $
    ABLFL $
    ANRIND $
  ;

datalines;
TEST01 PAT01 PARAM01 10.12 .     Baseline Y NORMAL
TEST01 PAT01 PARAM01  9.70 .     Day7     . LOW
TEST01 PAT01 PARAM01 15.01 .     Day14    . HIGH
TEST01 PAT01 PARAM02  8.35 .     Baseline Y LOW
TEST01 PAT01 PARAM02  .    .     Day7     . .
TEST01 PAT01 PARAM02  8.35 .     Day14    . LOW
TEST01 PAT01 PARAM03  .    LOW   Baseline Y .
TEST01 PAT01 PARAM03  .    LOW   Day7     . .
TEST01 PAT01 PARAM03  .    MEDIUM Day14   . .
TEST01 PAT01 PARAM04  .    HIGH  Baseline Y .
TEST01 PAT01 PARAM04  .    HIGH  Day7     . .
TEST01 PAT01 PARAM04  .    MEDIUM Day14   . .
;
run;

**Derive BASE from AVAL;
%derive_var_base(
  dataset=adlb1,
  by_vars=USUBJID PARAMCD,
  source_var=AVAL,
  new_var=BASE
);

** Derive BASEC from AVALC;
%derive_var_base(
  dataset=adlb2,
  by_vars=USUBJID PARAMCD,
  source_var=AVALC,
  new_var=BASEC
);

** Derive BNRIND from ANRIND;
%derive_var_base(
  dataset=adlb3,
  by_vars=USUBJID PARAMCD,
  source_var=ANRIND,
  new_var=BNRIND
);
~~~

Author:          	    Sharad Chhetri  
Latest udpate Date: 	2026-01-20

## %derive_var_chg()

### Purpose:
  Derive Change from Baseline (CHG) in a BDS-style dataset.  

### Parameters:  
~~~sas 
 - `aval_var` (required, default=AVAL) : Analysis variable from which baseline value is taken out 
 - `base_var` (required, default=BASE) : Baseline variable
 - `chg_var` (required, default=CHG) : Change from baseline variable. (&aval_var - &base_var)
~~~

### Example usage:
~~~sas
data advs;
  length USUBJID $3 PARAMCD $6 ABLFL $1;
  infile datalines truncover;
  input USUBJID $ PARAMCD $ AVAL ABLFL $ BASE;
datalines;
P01 WEIGHT 80.0  Y  80.0
P01 WEIGHT 80.8  .  80.0
P01 WEIGHT 81.4  .  80.0
P02 WEIGHT 75.3  Y  75.3
P02 WEIGHT 76.0  .  75.3
;
run;

data advs;
  set advs;
  %derive_var_chg();
run;  
~~~

Author:          	    Sharad Chhetri  
Latest udpate Date: 	2026-01-25

## %derive_var_obs_number()

### Purpose:
  Adds a sequence number variable to a dataset based on grouping keys and sort order. Useful for creating sequence numbers like `ASEQ`, `AESEQ`, or `CMSEQ`.

### Parameters:
~~~sas
 - `data`        (required) : Input dataset name.
 - `dataset_out` (optional) : Output dataset name. Default: Same as data.
 - `by_vars`     (required) : Space-separated list of grouping variables. The sequence number resets for each new group defined here.
 - `order`       (optional) : Space-separated list of variables to sort by within the group. Determines the order of the sequence.
 - `new_var`     (optional) : Name of the output sequence variable. 
                              Default: ASEQ.
 - `check_type`  (optional) : Specifies the log message type if duplicates are found based on by_vars and order. 
                              Values: none, warning, error. If warning or error, a message is written to the log if the combination of by_vars and order is not unique (which implies non-deterministic sequencing). 
                              Default: none.
~~~

### Example usage:

~~~sas
* Create sample data;
data adae;
  input USUBJID $ AESTDTC $ AETERM $;
  datalines;
001 2024-01-01 Headache
001 2024-01-05 Fever
001 2024-01-01 Nausea
002 2024-02-01 Rash
;
run;

* Derive ASEQ;
%derive_var_obs_number(
  data        = adae,
  dataset_out = adae_seq,
  by_vars     = USUBJID,
  order       = AESTDTC,
  new_var     = ASEQ,
  check_type  = warning
);
~~~

Author:                 Hiroki Yamanobe  
Latest update Date:     2026-02-03

## %derive_vars_aage()

### Purpose:
  Derives analysis age variables `AAGE` (numeric) and `AAGEU` (unit) from a start and end date/datetime.
  Supports two calculation modes:
    - `INTERVAL`: uses calendar interval counting for YEARS/MONTHS/WEEKS.
    - `DURATION`: uses exact elapsed time converted to the requested unit (with average year/month lengths).

### Parameters:
~~~sas
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
~~~
### Example usage:
~~~sas
data test_aage;
  length USUBJID $10;
  format BRTHDT RANDDT yymmdd10.
         BRTHDTM RANDDTM datetime19.;
  
  USUBJID = "SUBJ01";
  BRTHDT  = '06SEP1984'd;
  RANDDT  = '24FEB2020'd;
  BRTHDTM = dhms(BRTHDT, 0, 0, 0);
  RANDDTM = dhms(RANDDT, 0, 0, 0);
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

Author:                 Ryo Nakaya  
Latest update Date:     2026-02-07

## %derive_vars_joined()

### Purpose:
  Performs a hash-based lookup (left-join style) from the current DATA step row to an external dataset.  
  If key(s) match, values of `new_vars` are populated from `dataset_add`.  
  Optionally creates a character flag `exist_flag` indicating whether a match exists.

### Parameters:
~~~sas
 - `dataset_add` (required)
      Source dataset used for the lookup (e.g., `SDTM.AE`).
 - `by_vars` (required)
      Space-separated list of key variables used to find matches (e.g., `USUBJID`).
 - `new_vars` (required)
      Space-separated list of variables to bring from `dataset_add` into the current DATA step.
      These variables must exist in `dataset_add`. When no match is found, they are set to missing.
 - `filter_add` (optional)
      WHERE clause (text) applied to `dataset_add` before building the hash.
      If provided, only records satisfying the filter_add are used for lookup.
      Example: `%nrbquote(SEX="F" and AGE>=18)`
 - `exist_flag` (optional)
      Name of an output character variable indicating existence of a match for the current row’s key(s).
      If omitted, no flag is created.
 - `true_value` (optional)
      Value assigned to `exist_flag` when a match is found.
      Default: `Y`.
 - `false_value` (optional)
      Value assigned to `exist_flag` when no match is found.
      Default: (blank).
~~~

### Example usage:
~~~sas
data have;
  do USUBJID="010","020","030";
        output;
  end;
run;
data add;
  do USUBJID="010","020","040";
        AGE=input(USUBJID,best.);
        SEX=choosec(whichc(USUBJID,"010","020","040"),"M","F","F");
        output;
  end;
run;
data want;
  set have;
  %derive_vars_joined(
    dataset_add = add,
    by_vars     = USUBJID,
    new_vars    = AGE SEX,
    filter_add= %nrbquote(SEX="F"),
    exist_flag= EXFL ,
    true_value = Y,
    false_value = N
  );
run;
~~~

Author:   Yutaka Morioka  
Latest update Date: 2026-02-01

---
 
## Version history  
0.0.6(16February2026) : Added %derive_var_base(), %derive_var_chg(), %derive_var_obs_number(), %derive_vars_aage(), %derive_vars_joined()  
0.0.5(25December2025) : Added %derive_locf_records()  
0.0.4(21November2025) : Added %derive_vars_duration()  
0.0.3(23October2025) : Added %derive_var_age_years()  
0.0.2(15October2025)	: Add %derive_var_merged_exist_flag()  
0.0.1(14October2025)	: Initial version

## What is SAS Packages?

The package is built on top of **SAS Packages Framework(SPF)** developed by Bartosz Jablonski.

For more information about the framework, see [SAS Packages Framework](https://github.com/yabwon/SAS_PACKAGES).

You can also find more SAS Packages (SASPacs) in the [SAS Packages Archive(SASPAC)](https://github.com/SASPAC).

## How to use SAS Packages? (quick start)

### 1. Set-up SAS Packages Framework

First, create a directory for your packages and assign a `packages` fileref to it.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
filename packages "\path\to\your\packages";
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Secondly, enable the SAS Packages Framework.
(If you don't have SAS Packages Framework installed, follow the instruction in 
[SPF documentation](https://github.com/yabwon/SAS_PACKAGES/tree/main/SPF/Documentation) 
to install SAS Packages Framework.)

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
%include packages(SPFinit.sas)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


### 2. Install SAS package

Install SAS package you want to use with the SPF's `%installPackage()` macro.

- For packages located in **SAS Packages Archive(SASPAC)** run:
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
  %installPackage(packageName)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- For packages located in **PharmaForest** run:
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
  %installPackage(packageName, mirror=PharmaForest)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- For packages located at some network location run:
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
  %installPackage(packageName, sourcePath=https://some/internet/location/for/packages)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  (e.g. `%installPackage(ABC, sourcePath=https://github.com/SomeRepo/ABC/raw/main/)`)


### 3. Load SAS package

Load SAS package you want to use with the SPF's `%loadPackage()` macro.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
%loadPackage(packageName)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


### Enjoy!

---

