/*** HELP START ***//*

### Macro:
    %derive_locf_records

### Purpose:
    Add LOCF records (Last Observation Carried Forward) to a dataset based on an "expected observations" reference dataset.  

### Parameters:  

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


### Sample code:

~~~sas
	
****Test1;
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

****Test2;	
data input2;
  length STUDYID $6 USUBJID $12 PARAMCD $5 PARAM $40 AVISIT $20;      
  infile datalines dlm='|' truncover;
  input STUDYID $ USUBJID $ PARAMCD $ PARAM $ AVAL AVISITN AVISIT $;
datalines;
TEST01|01-701-1015|DIABP|Diastolic Blood Pressure (mmHg)|51|0|BASELINE
TEST01|01-701-1015|DIABP|Diastolic Blood Pressure (mmHg)|50|2|WEEK 2
TEST01|01-701-1015|SYSBP|Systolic Blood Pressure (mmHg)|121|0|BASELINE
TEST01|01-701-1015|SYSBP|Systolic Blood Pressure (mmHg)|121|2|WEEK 2
TEST01|01-701-1028|DIABP|Diastolic Blood Pressure (mmHg)|79|0|BASELINE
TEST01|01-701-1028|DIABP|Diastolic Blood Pressure (mmHg)|.|2|WEEK 2
TEST01|01-701-1028|SYSBP|Systolic Blood Pressure (mmHg)|130|0|BASELINE
TEST01|01-701-1028|SYSBP|Systolic Blood Pressure (mmHg)|.|2|WEEK 2
;
run;


data expected_obsv2;
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
  dataset=input2,
  dataset_ref=expected_obsv2,
  by_vars=STUDYID USUBJID PARAM PARAMCD,  
  id_vars_ref=PARAMCD PARAM AVISITN AVISIT,
  analysis_var=, 
  imputation=, 
  order=AVISITN AVISIT,
  keep_vars=,  
  outdata=output_test2
);


****Test3;
data input3;
  length STUDYID $6 USUBJID $10 PARAMCD $10 PARAM $40 AVISIT $20 DTYPE $10;
  infile datalines dlm='|' truncover;
  input STUDYID $ USUBJID $ PARAMCD $ PARAM $ AVAL AVISITN AVISIT $ DTYPE $;
datalines;
TEST01|1015|DIABP|Diastolic Blood Pressure|51|0|BASELINE|
TEST01|1015|DIABP|Diastolic Blood Pressure|50|2|WEEK 2|
TEST01|1015|SYSBP|Systolic Blood Pressure|121|0|BASELINE|
TEST01|1015|SYSBP|Systolic Blood Pressure|121|2|WEEK 2|
TEST01|1015|LTDIABP|Log(Diastolic Blood Pressure)|1.71|0|BASELINE|LOG
TEST01|1015|LTDIABP|Log(Diastolic Blood Pressure)|1.69|2|WEEK 2|LOG
TEST01|1015|LTSYSBP|Log(Systolic Blood Pressure)|2.08|0|BASELINE|LOG
TEST01|1015|LTSYSBP|Log(Systolic Blood Pressure)|2.08|2|WEEK 2|LOG
TEST01|1028|DIABP|Diastolic Blood Pressure|79|0|BASELINE|
TEST01|1028|SYSBP|Systolic Blood Pressure|130|0|BASELINE|
TEST01|1028|LTDIABP|Log(Diastolic Blood Pressure)|1.89|0|BASELINE|LOG
TEST01|1028|LTSYSBP|Log(Systolic Blood Pressure)|2.11|0|BASELINE|LOG
;
run;


data expected_obsv3;
  length PARAMCD $10 PARAM $40 AVISIT $20;
  infile datalines dlm='|' truncover;
  input PARAMCD $ PARAM $ AVISITN AVISIT ;

datalines;
DIABP|Diastolic Blood Pressure|0|BASELINE
DIABP|Diastolic Blood Pressure|2|WEEK 2
LTDIABP|Log(Diastolic Blood Pressure)|0|BASELINE
LTDIABP|Log(Diastolic Blood Pressure)|2|WEEK 2
SYSBP|Systolic Blood Pressure|0|BASELINE
SYSBP|Systolic Blood Pressure|2|WEEK 2
LTSYSBP|Log(Systolic Blood Pressure)|0|BASELINE
LTSYSBP|Log(Systolic Blood Pressure)|2|WEEK 2
;
run;


%derive_locf_records(
  dataset=input3,
  dataset_ref=expected_obsv3,
  by_vars=STUDYID USUBJID PARAM PARAMCD,  
  id_vars_ref=,  
  analysis_var=, 
  imputation=, 
  order=AVISITN AVISIT,
  keep_vars=,  
  outdata=output_test3
);


****Test4;
data input4;
  length STUDYID $10 USUBJID $12 PARAMCD $10 PARAM $50 AVISIT $20;
  infile datalines dlm=',' truncover;
  input STUDYID $ USUBJID $ PARAMCD $ PARAM $ AVAL AVISITN AVISIT $;
datalines;
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),51,0,BASELINE 
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),50,2,WEEK 2 
TEST01,01-701-1015,SYSBP,Systolic Blood Pressure (mmHg),121,0,BASELINE 
TEST01,01-701-1015,SYSBP,Systolic Blood Pressure (mmHg),121,2,WEEK 2 
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),79,0,BASELINE 
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),.,2,WEEK 2 
TEST01,01-701-1028,SYSBP,Systolic Blood Pressure (mmHg),130,0,BASELINE 
TEST01,01-701-1028,SYSBP,Systolic Blood Pressure (mmHg),.,2,WEEK 2 
;
run;

data expected_obsv4;
  length AVISIT $20;
  infile datalines dlm=',' truncover;
  input AVISITN AVISIT $;
datalines;
0, BASELINE
2, WEEK 2
;
run;

%derive_locf_records(
  dataset=input4,
  dataset_ref=expected_obsv4,
  by_vars=STUDYID USUBJID PARAM PARAMCD,  
  id_vars_ref=,  
  analysis_var=, 
  imputation=, 
  order=AVISITN AVISIT,
  keep_vars=,  
  outdata=output_test4
);

****Test5;
data input5;
  length STUDYID $10 USUBJID $12 PARAMCD $10 PARAM $50 AVISIT $20;
  infile datalines dlm=',' truncover;    
  input STUDYID $ USUBJID $ PARAMCD $ PARAM $ AVAL AVISITN AVISIT $;
    
datalines;
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),51,0,BASELINE
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),50,2,WEEK 2
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),52,4,WEEK 4
TEST01,01-701-1015,DIABP,Diastolic Blood Pressure (mmHg),54,6,WEEK 6
TEST01,01-701-1015,SYSBP,Systolic Blood Pressure (mmHg),121,0,BASELINE
TEST01,01-701-1015,SYSBP,Systolic Blood Pressure (mmHg),121,2,WEEK 2
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),79,0,BASELINE
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),80,2,WEEK 2
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),.,4,WEEK 4
TEST01,01-701-1028,DIABP,Diastolic Blood Pressure (mmHg),.,6,WEEK 6
TEST01,01-701-1028,SYSBP,Systolic Blood Pressure (mmHg),130,0,BASELINE
;
run;


data expected_obsv5;
  length PARAMCD $10 PARAM $50 AVISIT $20;
  infile datalines dlm=',' truncover;    
  input PARAMCD $ PARAM $ AVISITN AVISIT $;
    
datalines;
DIABP,Diastolic Blood Pressure (mmHg),0,BASELINE
DIABP,Diastolic Blood Pressure (mmHg),2,WEEK 2
DIABP,Diastolic Blood Pressure (mmHg),4,WEEK 4
DIABP,Diastolic Blood Pressure (mmHg),6,WEEK 6
SYSBP,Systolic Blood Pressure (mmHg),0,BASELINE
SYSBP,Systolic Blood Pressure (mmHg),2,WEEK 2
;
run;

%derive_locf_records(
  dataset=input5,
  dataset_ref=expected_obsv5,
  by_vars=STUDYID USUBJID PARAM PARAMCD,  
  id_vars_ref=,  
  analysis_var=, 
  imputation=, 
  order=AVISITN AVISIT,
  keep_vars=,  
  outdata=output_test5
);

****Test6;
data input6;
  length USUBJID $5 PARAMCD $10 AVISIT $20;
  infile datalines dlm=',' truncover;  
  input USUBJID $ PARAMCD $ AVAL AVISITN AVISIT $ ADY;
datalines;
1, DIABP, 51, 0, BASELINE, 0
1, DIABP, 50, 2, WEEK 2, 14
1, DIABP, 52, 4, WEEK 4, 28
1, DIABP, 54, 6, WEEK 6, 42
1, SYSBP, 21, 0, BASELINE, 0
1, SYSBP, 121, 2, WEEK 2, 14
2, DIABP, 79, 0, BASELINE, 0
2, DIABP, 80, 2, WEEK 2, 12
2, DIABP, ., 4, WEEK 4, 26
2, DIABP, ., 6, WEEK 6, 44
2, SYSBP, 130, 0, BASELINE, 0
;
run;

data expected_obsv6;
  length PARAMCD $10 AVISIT $20;
  infile datalines dlm=',' truncover; 
  input PARAMCD $ AVISITN AVISIT $ ADY;
datalines;
DIABP, 0, BASELINE, 0
DIABP, 2, WEEK 2, 14
DIABP, 4, WEEK 4, 28
DIABP, 6, WEEK 6, 42
SYSBP, 0, BASELINE, 0
SYSBP, 2, WEEK 2, 14
;
run;


%derive_locf_records(
  dataset=input6,
  dataset_ref=expected_obsv6,
  by_vars=USUBJID PARAMCD,  
  id_vars_ref=USUBJID PARAMCD AVISITN AVISIT,  
  analysis_var=AVAL,
  imputation=, 
  order=AVISITN AVISIT ADY,
  keep_vars=,  
  outdata=output_test6
);


****Test7;
data input7;
  length USUBJID $5 PARAMCD $10 AVISIT $20;
  infile datalines dlm=',' truncover;   
  input USUBJID $ PARAMCD $ AVAL AVISITN AVISIT $ ADY;
  
datalines;
1, DIABP, 51, 0, BASELINE, 0
1, DIABP, 50, 2, WEEK2, 14
1, DIABP, 52, 4, WEEK4, 28
1, DIABP, 54, 6, WEEK6, 42
1, SYSBP, 121, 0, BASELINE, 0
1, SYSBP, 121, 2, WEEK2, 14
2, DIABP, 79, 0, BASELINE, 0
2, DIABP, 80, 2, WEEK2, 12
2, DIABP, ., 4, WEEK4, 28
2, DIABP, ., 6, WEEK6, 44
2, SYSBP, 130, 0, BASELINE, 0
;
run;


data expected_obsv7;
  length PARAMCD $10 AVISIT $20;
  infile datalines dlm=',' truncover; 
  input PARAMCD $ AVISITN AVISIT $ ADY;
  
datalines;
DIABP, 0, BASELINE, 0
DIABP, 2, WEEK2, 14
DIABP, 4, WEEK4, 28
DIABP, 6, WEEK6, 42
SYSBP, 0, BASELINE, 0
SYSBP, 2, WEEK2, 14
;
run;


%derive_locf_records(
  dataset=input7,
  dataset_ref=expected_obsv7,
  by_vars=USUBJID PARAMCD,  
  id_vars_ref=USUBJID PARAMCD AVISITN AVISIT,
  analysis_var=AVAL,
  imputation=update,
  order=AVISITN AVISIT ADY,
  keep_vars=,
  outdata=output_test7
);

****Test8;
data input8;
  length USUBJID $5 PARAMCD $10 PARAMN 8 AVISIT $20;
  infile datalines dlm=',' truncover;
  input USUBJID $ PARAMN PARAMCD $ AVAL AVISITN AVISIT $ ADY;
datalines;
1,1,DIABP,51,0,BASELINE,0
1,1,DIABP,50,2,WEEK 2,14
1,1,DIABP,52,4,WEEK 4,28
1,1,DIABP,54,6,WEEK 6,42
1,2,SYSBP,121,0,BASELINE,0
1,2,SYSBP,121,2,WEEK 2,14
2,1,DIABP,79,0,BASELINE,0
2,1,DIABP,80,2,WEEK 2,12
2,1,DIABP,.,4,WEEK 4,28
2,1,DIABP,.,6,WEEK 6,44
2,2,SYSBP,130,0,BASELINE,0
;
run;

data expected_obsv8;
  length PARAMCD $10 AVISIT $20;
  infile datalines dlm=',' truncover;  
  input PARAMCD $ AVISITN AVISIT $ ADY;
datalines;
DIABP,0,BASELINE,0
DIABP,2,WEEK 2,14
DIABP,4,WEEK 4,28
DIABP,6,WEEK 6,42
SYSBP,0,BASELINE,0
SYSBP,2,WEEK 2,14
;
run;


%derive_locf_records(
  dataset=input8,
  dataset_ref=expected_obsv8,
  by_vars=USUBJID PARAMCD,  
  id_vars_ref=USUBJID PARAMCD AVISITN AVISIT,
  analysis_var=AVAL,
  imputation=update_add, 
  order=AVISITN AVISIT ADY,
  keep_vars=PARAMN,
  outdata=output_test8
);

****Test9;
data input9;
  length USUBJID $5 PARAMCD $10 PARAMN 8 AVISIT $20 DATEC $10 DAY $10;
  infile datalines dlm=',' truncover;  
  input USUBJID $ PARAMCD $ PARAMN AVAL AVISITN AVISIT $ DATEC $ DAY $;
  
datalines;
1,DIABP,2,85,0,BASELINE,February,day a
1,DIABP,2,50,4,VISIT 4,April,day c
1,DIABP,2,20,6,VISIT 6,May,day d
1,DIABP,2,35,8,VISIT 8,June,day e
1,DIABP,2,.,10,VISIT 10,July,day f
1,DIABP,2,20,12,VISIT 12,August,day g
1,DIABP,2,.,14,VISIT 14,September,day h
;
run;

data expected_obsv9;
  length PARAMCD $10 AVISIT $20;
  infile datalines dlm=',' truncover;  
  input PARAMN PARAMCD $ AVISITN AVISIT $;
  
datalines;
2,DIABP,0,BASELINE
2,DIABP,2,VISIT 2
2,DIABP,4,VISIT 4
2,DIABP,6,VISIT 6
2,DIABP,8,VISIT 8
2,DIABP,10,VISIT 10
2,DIABP,12,VISIT 12
2,DIABP,14,VISIT 14
;
run;

%derive_locf_records(
  dataset=input9,
  dataset_ref=expected_obsv9,
  by_vars=USUBJID PARAMCD,  
  id_vars_ref=,  
  analysis_var=aval, 
  imputation=update_add,
  order=AVISITN AVISIT,
  keep_vars=PARAMN DATEC DAY,
  outdata=output_test9
);





~~~

### Note:

- Parameter `outdata` is an additional (optional) parameter in adamski (not exists in admiral) for the output dataset. 
  It returns the input dataset with the new "LOCF" observations added for each`by_vars`, based on the value passed to the `imputation` argument.
  

### URL:

https://github.com/PharmaForest/adamski

---

Author:          	    Sharad Chhetri
Latest udpate Date: 	2025-12-21

---

*//*** HELP END ***/


%macro derive_locf_records(
    dataset=,
    dataset_ref=,
    by_vars=,
    id_vars_ref=,
    analysis_var=AVAL,
    imputation=add,
    order=,
    keep_vars=,
    outdata=
);

%local _impu _ds_exist _dref_exist _refvars _tmpname _new_by_vars _exp_obs_by_vars
       _nref _tmp_missing_avar _tmp_dtype _tmp_new_records _dtype_exists
       _keeplist _allvars_stmt _i _cnt_kvars _kvar;

/* --------------------------- 1. Basic validations ------------------------------------ */

/* check required parameters */
%if %superq(dataset)= or %superq(dataset_ref)= or %superq(by_vars)= or %superq(order)= %then %do;
  %put ERROR: Required parameters missing. dataset=, dataset_ref=, by_vars=, order= are required.;
  %abort cancel;
%end;

/* default analysis var to AVAL if not provided */
%if %superq(analysis_var) = %then %do;
  %let analysis_var=AVAL;
%end;


/* check if analysis varaible exists in dataset */
%local dsid varnum rc;

%let dsid = %sysfunc(open(&dataset, i)); /* open dataset in read only mode */ 
%if &dsid = 0 %then %do;
  %put ERROR: Cannot open dataset &dataset..;
  %abort cancel;
%end;

%let varnum = %sysfunc(varnum(&dsid, &analysis_var));
%let rc = %sysfunc(close(&dsid));

%if &varnum = 0 %then %do;
  %put ERROR: analysis_var=&analysis_var not found in &dataset..;
  %abort cancel;
%end;


/* check if output datset name is provided - default to &dataset._locf, if not provided */
%if %superq(outdata) = %then %do;
  %let outdata=&dataset._locf;
%end;


/* Normalise imputation */
%let _impu = %upcase(&imputation);
%if &_impu ne ADD and &_impu ne UPDATE and &_impu ne UPDATE_ADD %then %do; 
  /* if missing, default to add */
  %let _impu = ADD;
%end;


/*-----------------------------------------------------------------------*/
/* Collect full variable list from dataset_ref                    */
/*   - Needed for validation                                             */
/*-----------------------------------------------------------------------*/
proc contents data=&dataset_ref out=_refvars_tmp(keep=name) noprint;
run;

data _null_;
  length s $32767;
  retain s '';
  set _refvars_tmp end=eof;
  s = catx(' ', s, strip(name));

  /* create a macro variable containing ALL dataset_ref variables */
  if eof then call symputx('_refvars', strip(s));
run;

proc datasets lib=work nolist; delete _refvars_tmp; quit;

/*-----------------------------------------------------------------------*/
/* If id_vars_ref not provided, default to ALL variables from dataset_ref*/
/*-----------------------------------------------------------------------*/
%if %superq(id_vars_ref) = %then %do;
  %let id_vars_ref = &_refvars;
%end;

/* check ID Vars */
%put "Id vars:" &id_vars_ref;


/* ------------------------------------------------------------------------------- */
/* Build exp_obs_by_vars = union(by_vars, id_vars_ref)                             */
/* ------------------------------------------------------------------------------- */
%let _exp_obs_by_vars = &by_vars &id_vars_ref;

/* ------------------------------------------------------------------------------- */
/* Determine which by_vars are NOT in dataset_ref */
/* We will create new_by_vars = those by_vars not present in dataset_ref.          */
/* ------------------------------------------------------------------------------- */
%let _new_by_vars=;
%if %superq(by_vars) ne %then %do;
  %let _bcount = 0;
  %let _i = 1;
  %let _tok = %scan(&by_vars, &_i, %str( ));
  %do %while(%superq(_tok) ne );
    /* test whether _tok appears in dataset_ref varlist &_refvars */
    %if %sysfunc(indexw(%upcase(&_refvars), %upcase(&_tok))) = 0 %then %do;
      %let _new_by_vars = &_new_by_vars &_tok;
    %end;
    %let _i = %eval(&_i + 1);
    %let _tok = %scan(&by_vars, &_i, %str( ));
  %end;
%end;

/* If new_by_vars is empty, we'll create a 1-row IDS dataset (so crossing yields dataset_ref only) */
%put NOTE: new_by_vars = (&_new_by_vars);

/* ---------------------------- 2. Create IDS dataset -------------------------------- */
/* ids = distinct rows of dataset[ new_by_vars ] (or single-row dataset if no new_by_vars) */
%if %superq(_new_by_vars) = %then %do;
  data ids;
    /* empty single-row dataset used to perform a pure crossing with dataset_ref */
    _one = 1;
    output;
  run;
%end;
%else %do;
  proc sort data=&dataset(keep=&_new_by_vars) out=ids nodupkey; 
    by &_new_by_vars; 
  run;
%end;

/* ---------------------------- 3. Cartesian product ids x dataset_ref ------------- */
/* We will use DATA step point= to replicate the classical crossing                  */
data _null_;
  if 0 then set &dataset_ref nobs=_nref;
  call symputx('_nref', _nref);
  stop;
run;

%put NOTE: Number of rows in dataset_ref (nref) = &_nref;

/* create dataset with all expected variables and records */
proc sql;
  create table exp_obsv as
  select a.*, b.*
  from ids as a, &dataset_ref as b;
quit;


/* ---------------------------- 4. Flag original missing analysis_var ---------------- */
/* Create a temporary variable to mark rows that originally had missing analysis_var   */
%let _tmp_missing_avar = tmp_missing_avar;
data dataset_flag;
  set &dataset;
  length &_tmp_missing_avar $8;
  if missing(&analysis_var) then &_tmp_missing_avar = "missing";
  else &_tmp_missing_avar = "";
run;

/* ---------------------------- 5. unique_original: excludes rows with missing analysis_var ----- */
/* Only keep non-missing analysis_var rows and distinct on exp_obs_by_vars                        */
proc sort data=dataset_flag(where=(not missing(&analysis_var))) out=unique_original nodupkey;
  by &_exp_obs_by_vars;
run;

/* ---------------------------- 6. Prepare tmp var names ---------------------------- */
%let _tmp_dtype       = tmp_dtype;
%let _tmp_new_records = tmp_new_records;

/* ---------------------------- 7. aval_missing (records with missing analysis_var) --- */
/* Only created when imputation in (ADD, UPDATE_ADD)                                    */
%if &_impu = ADD or &_impu = UPDATE_ADD %then %do;
  data aval_missing;
    set dataset_flag;
    where missing(&analysis_var);
  run;
%end;
%else %do;
  /* no aval_missing dataset */
%end;


/* ---------------------------- 8. Determine data_fill and exp_obsv_to_add --------------- */
/* Two branches depending on imputation:                                                   */
/* CASE A: UPDATE or UPDATE_ADD  -> data_fill = dataset_flag (all rows)                    */
/*       exp_obsv_to_add = exp_obsv anti-join dataset (by exp_obs_by_vars)                 */

/* CASE B: ADD                 -> data_fill = dataset_flag where analysis_var not missing  */
/*       exp_obsv_to_add = exp_obsv anti-join unique_original                              */

%if &_impu = UPDATE or &_impu = UPDATE_ADD %then %do;

  /* data_fill = all dataset rows */
  data data_fill; 
  	set dataset_flag; 
  run;

  /* exp_obsv not present in dataset_flag (by &_exp_obs_by_vars) */
  proc sort data=exp_obsv; 
  	by &_exp_obs_by_vars; 
  run;
  
  proc sort data=dataset_flag(keep=&_exp_obs_by_vars) nodupkey out=_tmp_dskeys; 
  	by &_exp_obs_by_vars; 
  run;

  data exp_obsv_to_add;
    merge exp_obsv(in=a) _tmp_dskeys(in=b);
    by &_exp_obs_by_vars;
    if a and not b then do;
      length &_tmp_new_records $4;
      &_tmp_new_records = "new";
      output;
    end;
  run;

  proc datasets lib=work nolist; 
    delete _tmp_dskeys; 
  quit;

%end;
%else %do; /* imputation = ADD */

  /* data_fill = use only records with non-missing analysis_var */
  data data_fill; 
  	set dataset_flag; 
  	where not missing(&analysis_var); 
  run;

  /* if any expected record is missing in the original dataset, get it from the exp_obsv dataset 
  	 Note - if any record has missing analysis variable value, that is also considered a missing record
  */
  proc sort data=exp_obsv; 
  	by &_exp_obs_by_vars; 
  run;
  
  proc sort data=unique_original; 
  	by &_exp_obs_by_vars; 
  run;

  /* create dataset with all new records to be added - that were missing in the original dataset */
  data exp_obsv_to_add;
    merge exp_obsv(in=a) unique_original(in=b);
    by &_exp_obs_by_vars;
    
    if a and not b then do;
      length &_tmp_new_records $4;
      &_tmp_new_records = "new";
      output;
    end;
  run;

%end;


/* ---------------------------- 9. Combine data_fill + exp_obsv_to_add --------------- */
/* Create aval_locf and flag rows where analysis_var is missing as tmp_dtype = LOCF    */
data aval_locf;
  set data_fill exp_obsv_to_add;
  length &_tmp_dtype $4;
  
  if missing(&analysis_var) then &_tmp_dtype = "LOCF";
  else &_tmp_dtype = "";
run;

/* ---------------------------- 10. Ensure DTYPE handling --------------------------- */
/* If dataset has DTYPE already, set DTYPE = LOCF where tmp_dtype = LOCF, otherwise
   rename tmp_dtype to DTYPE.
*/
proc contents data=aval_locf out=_vars_all(keep=name) noprint; 
run;

data _null_;
  set _vars_all end=eof;
  retain found 0;
  if upcase(name) = "DTYPE" then found = 1;
  if eof then call symputx('_dtype_exists', found);
run;

%if &_dtype_exists = 1 %then %do;
  data aval_locf;
    set aval_locf;
    if &_tmp_dtype = "LOCF" then DTYPE = "LOCF";
    drop &_tmp_dtype;
  run;
%end;
%else %do;
  data aval_locf;
    set aval_locf;
    rename &_tmp_dtype = DTYPE;
  run;
%end;

proc datasets lib=work nolist; 
  delete _vars_all; 
quit;



/* ---------------------------- 11. Sort and group-by LOCF fill --------------------- */
/* Sort by by_vars then order, then perform LOCF fill for analysis_var and keep_vars */
proc sort data=aval_locf; 
  by &by_vars &order; 
run;

/* for the keep_vars get the variable types (will be needed later on to define the new variable) - go through each variable */
%if %superq(keep_vars) ne %then %do;
    %let _cnt_kvars = 0;
    %let _i = 1;
    %let _kvar = %scan(&keep_vars, &_i, %str( ));
    %do %while(%superq(_kvar) ne );
       %let _cnt_kvars = %eval(&_cnt_kvars + 1);

		/* get variable types */
		proc sql noprint;
		  select type, length
			into :_kvar_type&_cnt_kvars, :_kvar_len&_cnt_kvars
		  from dictionary.columns
		  where libname = 'WORK'
			and memname = 'AVAL_LOCF'
			and upcase(name) = upcase("&_kvar");
		quit;
		
      %let _i = %eval(&_i + 1);
      %let _kvar = %scan(&keep_vars, &_i, %str( ));
    %end;
%end;


data aval_locf;
  set aval_locf;
  by &by_vars;

  /* Retain last observed analysis_var */
  retain _last_aval;

  /* For keep_vars, create last_<var> retained variables if keep_vars provided */
  %if %superq(keep_vars) ne %then %do;
    /* create retained last_... variables */
    %let _cnt_kvars = 0;
    %let _i = 1;
    %let _kvar = %scan(&keep_vars, &_i, %str( ));
    
    %do %while(%superq(_kvar) ne );
      %let _cnt_kvars = %eval(&_cnt_kvars + 1);
	
	  /* define variable based on type of source variable */	
	  %if &&_kvar_type&_cnt_kvars = char %then %do;
		length last_&_kvar $&&_kvar_len&_cnt_kvars;
	  %end;
	  %else %do;
	    length last_&_kvar 8;
	  %end;
      
      retain last_&_kvar;
      
      /*call missing(last_&_kvar);*/ /* initialize */
      %let _i = %eval(&_i + 1);
      %let _kvar = %scan(&keep_vars, &_i, %str( ));
    %end;
  %end;

  /* reset retained trackers at the start of each group:
     using first.<first_by_var> is sufficient to detect the beginning of a group */
  if first.%scan(&by_vars,1) then do;
    call missing(_last_aval);
    %if %superq(keep_vars) ne %then %do;
      %let _i = 1;
      %let _kvar = %scan(&keep_vars, &_i, %str( ));
      
      %do %while(%superq(_kvar) ne );
        call missing(last_&_kvar);
        %let _i = %eval(&_i + 1);
        %let _kvar = %scan(&keep_vars, &_i, %str( ));
      %end;
    %end;
  end;


  /* Update last trackers if current values are non-missing; otherwise carry forward */
  if not missing(&analysis_var) then _last_aval = &analysis_var;
  else &analysis_var = _last_aval;

  %if %superq(keep_vars) ne %then %do;
    %let _i = 1;
    %let _kvar = %scan(&keep_vars, &_i, %str( ));
    
    %do %while(%superq(_kvar) ne );
      if not missing(&_kvar) then last_&_kvar = &_kvar;      
      /* if keep vars values are missing then retain from last one */
      else &_kvar = last_&_kvar;
      %let _i = %eval(&_i + 1);
      %let _kvar = %scan(&keep_vars, &_i, %str( ));
    %end;
  %end;  
run;


/* ---------------------------- 12. Filter out original missing rows that were not imputed ---------------------- */
/* We remove rows that: original record had missing analysis_var & were not newly-created rows & DTYPE is missing */
data aval_locf;
  set aval_locf;
  if not( (not missing(&_tmp_missing_avar)) and missing(&_tmp_new_records) and missing(DTYPE) );
run;



/* ---------------------------- 13. When imputation = ADD: clear non-essential vars in LOCF rows ------------------------------------------------*/
/*		For LOCF rows, set all variables that are not in the keep list (analysis_var, by_vars, order, id_vars_ref, keep_vars, DTYPE) to missing. */
%if &_impu = ADD %then %do;

  /* split into LOCF and non-LOCF rows */
  data locf_rows non_locf_rows;
    set aval_locf;
    if upcase(DTYPE) = "LOCF" then output locf_rows;
    else output non_locf_rows;
  run;

  /* Get full variable list and variable types from aval_locf */
  proc contents data=aval_locf out=_allvars(keep=name type) noprint; 
  run;

  /* Build the clear statement for variables NOT in the keep list */
  %let _keeplist = &analysis_var &by_vars &order &id_vars_ref &keep_vars DTYPE;
  data _null_;
    length stmt $32767;
    retain stmt '';
    
    set _allvars end=eof;
    /* If current variable is NOT in keeplist, generate a clearing expression */
    if indexw(upcase("&_keeplist"), upcase(name)) = 0 then do;
      if type = 1 then stmt = catx(' ', stmt, catx('','/* clear numeric */', name,'=.;')); 
      else stmt = catx(' ', stmt, catx('','/* clear char */', name, '="";'));
    end;
    
    if eof then call symputx('_allvars_stmt', strip(stmt));
  run;

  /* Apply clearing statements to locf_rows */
  data locf_rows;
    set locf_rows;
    
    /* The _allvars_stmt macro variable contains statements like: var1=.; var2=""; ... */
    &_allvars_stmt
  run;

  /* Recombine LOCF (with cleared non-essential vars) + non-LOCF (unchanged) */
  data aval_locf;
    set locf_rows non_locf_rows;
  run;

  proc datasets lib=work nolist; delete locf_rows non_locf_rows _allvars; 
  quit;
%end; /* end of imputation ADD handling */



/* ---------------------------- 14. Final: append aval_missing when required ---------------------- */
/*  only when created (for ADD and UPDATE_ADD). For UPDATE mode aval_missing is not present.        */
%if &_impu = ADD or &_impu = UPDATE_ADD %then %do;
  /* If aval_missing exists, append it */
  %if %sysfunc(exist(aval_missing)) %then %do;
    data aval_locf;
      set aval_locf aval_missing;
    run;
  %end;
%end;

/* sort the final dataset using the by and order variables */
proc sort data=aval_locf; 
  by &by_vars &order; 
run;

/* ---------------------------- 15. Cleanup temporary datasets --------------------------- */
data &outdata;
  set aval_locf;
   
  /* drop temp flags */
  drop &_tmp_missing_avar &_tmp_new_records _last_aval;
  
  /* drop last_ variables */
  %if %superq(keep_vars) ne %then %do;
    %let _i = 1;
    %let _kvar = %scan(&keep_vars, &_i, %str( ));
    %do %while(%superq(_kvar) ne );
      drop last_&_kvar;
      %let _i = %eval(&_i + 1);
      %let _kvar = %scan(&keep_vars, &_i, %str( ));
    %end;
  %end;
run;


proc datasets lib=work noprint;
  delete ids exp_obsv data_fill exp_obsv_to_add aval_locf unique_original dataset_flag exp_obsv_to_add
         exp_obsv _vars_all _allvars _refvars _nobs _tmp_dskeys;
quit;


/* Final message */
%put NOTE: derive_locf_records completed. Output dataset: &outdata;


%mend derive_locf_records;
