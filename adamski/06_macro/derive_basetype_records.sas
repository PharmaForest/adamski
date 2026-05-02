/*** HELP START ***//*

### Macro:
    %derive_basetype_records

### Purpose:
    Adds the `BASETYPE` variable to a dataset and duplicates records based upon the provided conditions.

### Parameters:  

 - `dataset` (required)	: Input dataset (with original observations)

 - `basetypes` (required) : Pipe-delimited list: RUN-IN|DOUBLE-BLIND|OPEN-LABEL.
 							 
 - `conditions` (required)	: Pipe-delimited list of conditions

 - `outdata` (optional, default=&dataset._basetype): Output dataset with `BASETYPE` variable


### Sample code:

~~~sas


****Test1;

data bds;
  length USUBJID $3 EPOCH $15 PARAMCD $8;
  input USUBJID $ EPOCH $ PARAMCD $ ASEQ AVAL;
  datalines;
P01 RUN-IN PARAM01 1 10.0
P01 RUN-IN PARAM01 2 9.8
P01 DOUBLE-BLIND PARAM01 3 9.2
P01 DOUBLE-BLIND PARAM01 4 10.1
P01 OPEN-LABEL PARAM01 5 10.4
P01 OPEN-LABEL PARAM01 6 9.9
P02 RUN-IN PARAM01 1 12.1
P02 DOUBLE-BLIND PARAM01 2 10.2
P02 DOUBLE-BLIND PARAM01 3 10.8
P02 OPEN-LABEL PARAM01 4 11.4
P02 OPEN-LABEL PARAM01 5 10.8
;
run;


%derive_basetype_records(
  dataset=bds,
  basetypes=RUN-IN|DOUBLE-BLIND|OPEN-LABEL,
  conditions=
    EPOCH in ("RUN-IN","STABILIZATION","DOUBLE-BLIND","OPEN-LABEL") |
    EPOCH in ("DOUBLE-BLIND","OPEN-LABEL") |
    EPOCH = "OPEN-LABEL",
    outdata=bds_with_basetype    
);


****Test2;

data bds;
  length USUBJID $3 EPOCH $15 PARAMCD $8;
  input USUBJID $ EPOCH $ PARAMCD $ ASEQ AVAL;
  datalines;
   P01    SCREENING    PARAM01     1  10.2
   P01    RUN-IN       PARAM01     2  10.0
   P01    RUN-IN       PARAM01     3   9.8
   P01    DOUBLE-BLIND PARAM01     4   9.2
   P01    DOUBLE-BLIND PARAM01     5  10.1
   P02    SCREENING    PARAM01     1  12.2
   P02    RUN-IN       PARAM01     2  12.1
   P02    DOUBLE-BLIND PARAM01     3  10.2
;
run;

%derive_basetype_records(
  dataset=bds,
  basetypes=RUN-IN,
  conditions=
    EPOCH in ("RUN-IN","DOUBLE-BLIND")
);



****Test3;

data bds;
  length USUBJID $3 EPOCH $15 PARAMCD $8;
  input USUBJID $ EPOCH $ PARAMCD $ ASEQ AVAL;
  datalines;
   P01    RUN-IN       PARAM01     1  10.0
   P01    RUN-IN       PARAM01     2   9.8
   P01    DOUBLE-BLIND PARAM01     3   9.2
   P01    DOUBLE-BLIND PARAM01     4  10.1
;
run;


%derive_basetype_records(
  dataset=bds,
  basetypes=LAST|WORST,
  conditions=1 | 1,
  outdata=bds_with_basetype
);


~~~

### Note:

  - Baseline Type `BASETYPE` is needed when there is more than one definition of baseline for a given 
    Analysis Parameter `PARAM` in the same dataset.  For a given parameter, if Baseline Value `BASE` or `BASEC`
    are derived and there is more than one definition of baseline, then `BASETYPE` must be non-null on
    all records of any type for that parameter where either `BASE` or `BASEC` are also non-null. 
    Each value of `BASETYPE` refers to a definition of baseline that characterizes the value of `BASE` on that row.  
    Please see section 4.2.1.6 of the ADaM Implementation Guide, version 1.3 for further details.
 
  - For each element of `basetypes` the input dataset is subset based upon the provided expression in `conditions` and the 
    `BASETYPE` variable is set to the name of the expression. Here each name becomes a value of `BASETYPE` 
    and each expression defines which records receive that value. A record can match multiple expressions 
    and will be duplicated once for each matching `BASETYPE`. Then, all the subsets are stacked. 
    Records which do not match any condition are kept and `BASETYPE` is set to null.

  - Set values of `conditions` to 1 if no subset for `basetypes` is needed.
  
  - Parameter `outdata` is an additional (optional) parameter in adamski (not exists in admiral) for the output dataset. 
    It returns the input dataset with the new basetype variable added 
  
### URL:

https://github.com/PharmaForest/adamski

---

Author:          	    Sharad Chhetri
Latest udpate Date: 	2026-04-19

---

*//*** HELP END ***/


%macro derive_basetype_records(
    dataset=,
    basetypes=,   /* pipe-delimited list: RUN-IN|DOUBLE-BLIND|OPEN-LABEL */
    conditions=,   /* pipe-delimited list of conditions */
    outdata=
);

  %local i n bt cond;

  /* check required parameters */
  %if %superq(dataset)= or %superq(basetypes)= or %superq(conditions)= %then %do;
    %put ERROR: Required parameters missing. dataset=, basetypes=, conditions= are required.;
    %abort cancel;
  %end;


  /* check if output datset name is provided - default to &dataset._basetype, if not provided */
  %if %superq(outdata) = %then %do;
    %let outdata=&dataset._basetype;
  %end;


  /* Count number of basetypes */
  %let n = %sysfunc(countw(&basetypes, |));



  /***************************************************************/
  /* Step 1: Create subset datasets dynamically                  */
  /***************************************************************/
  %do i = 1 %to &n;

    %let bt   = %scan(&basetypes, &i, |);
    %let cond = %scan(&conditions, &i, |);

    data _bt_&i;
      set &dataset;
      length BASETYPE $200;
      if &cond;
      BASETYPE = "&bt";
    run;

  %end;


  /***************************************************************/
  /* Step 2: Stack all BASETYPE datasets                         */
  /***************************************************************/
  data _records_with_basetype;
    set
    %do i = 1 %to &n;
      _bt_&i
    %end;
    ;
  run;


  /***************************************************************/
  /* Step 3: Complementary condition                             */
  /***************************************************************/
  data _records_without_basetype;
    set &dataset;

    if not (
      %do i = 1 %to &n;
        %scan(&conditions, &i, |)
        %if &i < &n %then or;
      %end;
    );
  run;


  /***************************************************************/
  /* Step 4: Combine                                             */
  /***************************************************************/
  data &outdata;
    set _records_without_basetype
        _records_with_basetype;
  run;

%mend derive_basetype_records;
