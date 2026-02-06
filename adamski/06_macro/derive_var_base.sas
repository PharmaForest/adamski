/*** HELP START ***//*

### Macro:
    %derive_var_base

### Purpose:
    Derive baseline variables (e.g. BASE, BASEC, BNRIND) in a BDS dataset.  

### Parameters:  
 - `dataset` (required) : Name of the input daset
 - `by_vars` (required) : Space-separated list of BY variables (e.g. USUBJID PARAMCD)
 - `source_var` (required, default=AVAL) : Variable from which baseline value is taken
 - `new_var` (required, default=BASE) : Name of the new variable to created.
 - `filter` (required, default= ABLFL = "Y") : Baseline filter condition
 - `outdata` (optional, default=&dataset._base): Output dataset with new baseline variable 

### Sample code:

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

### Notes:

-   For each BY group, identifies the baseline record using a filter
    condition (default: ABLFL = "Y"). The value of SOURCE_VAR from the
    baseline record is then propagated to all records within the BY group
    as NEW_VAR.

-   If multiple baseline records are found within a BY group, the macro
    issues an error and stops.

-   Parameter `outdata` is an additional (optional) parameter in adamski (not exists in admiral) for the output dataset. 
    It returns the input dataset with the new "baseline" variable. 

-   The sort order of the output dataset will be based on the "by_vars" sort order.


### URL:

https://github.com/PharmaForest/adamski

---

Author:          	    Sharad Chhetri
Latest udpate Date: 	2026-01-20

---

*//*** HELP END ***/


%macro derive_var_base(
    dataset=,
    by_vars=,
    source_var=AVAL,
    new_var=BASE,
    filter=ABLFL = "Y",
    outdata=
);

  %local _dsid _rc _msg;

  /* check required parameters */
  %if %superq(dataset)= or %superq(by_vars)= or %superq(source_var)= or %superq(new_var)= %then %do;
    %put ERROR: Required parameters missing. dataset=, by_vars=, source_var=, new_var= are required.;
    %abort cancel;
  %end;

  /* check if output datset name is provided - default to &dataset._base, if not provided */
  %if %superq(outdata) = %then %do;
    %let outdata=&dataset._base;
  %end;


  /*--------------------------------------------------------------------------*
   * Step 1: Check that input dataset exists
   *--------------------------------------------------------------------------*/
  %if not %sysfunc(exist(&dataset)) %then %do;
    %put ERROR: Input dataset &dataset does not exist.;
    %return;
  %end;


  /*--------------------------------------------------------------------------*
   * Step 2: Sort dataset by BY variables (required for BY-group processing)
   *--------------------------------------------------------------------------*/
  proc sort data=&dataset out=_base_sorted;
    by &by_vars;
  run;

  /*--------------------------------------------------------------------------*
   * Step 3: Extract baseline records based on filter condition
   *--------------------------------------------------------------------------*/
  data _base_records;
    set _base_sorted;
    where &filter;
    keep &by_vars &source_var;
  run;

  /*--------------------------------------------------------------------------*
   * Step 4: Check for multiple baseline records per BY group
   *--------------------------------------------------------------------------*/

	/* Ensure baseline records are sorted by BY variables */
	proc sort data=_base_records;
	  by &by_vars;
	run;
	
	/* Identify BY groups with more than one baseline record */
	data _dup_check;
	  set _base_records;
	  by &by_vars;
	
	  retain _cnt;
	  if first.%scan(&by_vars, -1) then _cnt = 0;
	  _cnt + 1;
	
	  /* Flag duplicate baseline records within a BY group */
	  if _cnt > 1 then output;
	run;
	
	/* Count number of BY groups with duplicates */
	data _null_;
	  if 0 then set _dup_check nobs=_nobs;
	  call symputx('_msg', _nobs);
	  stop;
	run;


  %if &_msg > 0 %then %do;
    %put ERROR: Input dataset contains multiple baseline records with respect to &by_vars.;
    %return;
  %end;

  /*--------------------------------------------------------------------------*
   * Step 5: Merge baseline value back to all records
   *         - Baseline value is propagated within BY groups
   *         - All original records are retained with sort order of the by variables
   *--------------------------------------------------------------------------*/
  data &outdata;
    merge
      _base_sorted (in=a)
      _base_records (rename=(&source_var=&new_var));
    by &by_vars;
    if a;
    
    label &new_var="&new_var";
  run;

  proc sort data=&outdata;
    by &by_vars;
  quit;

  /*--------------------------------------------------------------------------*
   * Step 6: Cleanup temporary datasets
   *--------------------------------------------------------------------------*/
  proc datasets lib=work nolist;
    delete _base_sorted _base_records;
  quit;

%mend derive_var_base;

