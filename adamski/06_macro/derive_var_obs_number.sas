

/*** HELP START ***//*

### Macro:
    %derive_var_obs_number

### Purpose:
    Adds a sequence number variable to a dataset based on grouping keys and sort order. Useful for creating sequence numbers like `ASEQ`, `AESEQ`, or `CMSEQ`.

### Parameters:

 - `data`        (required) : Input dataset name.

 - `dataset_out` (optional) : Output dataset name. Default: Same as data.

 - `by_vars`     (required) : Space-separated list of grouping variables. The sequence number resets for each new group defined here.

 - `order`       (optional) : Space-separated list of variables to sort by within the group. Determines the order of the sequence.

 - `new_var`     (optional) : Name of the output sequence variable. 
                              Default: ASEQ.

 - `check_type`  (optional) : Specifies the log message type if duplicates are found based on by_vars and order. 
                              Values: none, warning, error. If warning or error, a message is written to the log if the combination of by_vars and order is not unique (which implies non-deterministic sequencing). 
                              Default: none.



### Sample code

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

### Note:

- Parameter `dataset_out` specific to this SAS macro (not present in the admiral R package). 
            It allows specifying a separate output name. If omitted, the input dataset (&data) will be overwritten.

- The output dataset will be sorted by &by_vars and &order.

- Temporary datasets (e.g., __temp1) are deleted at the end.

### URL:

https://github.com/PharmaForest/adamski

Author:                 Hiroki Yamanobe
Latest update Date:     2026-02-03

*//*** HELP END ***/

%macro derive_var_obs_number(
data 
, dataset_out=&data.
, by_vars=
, order=
, new_var=ASEQ
, check_type=none
);


%***************************;
%** Step 1: sort ;
%***************************;
proc sort data=&data. out=__temp1;
  by &by_vars. &order.;
run;

%***************************;
%** Step 2: Check duplicate;
%****************************;
proc sort data=__temp1 out=__check1 nouniquekey uniqueout=_null_;
  by &by_vars. &order.;
run;

data _null_;
  set __check1;
  if "&check_type." ne "none" and _n_ eq 1 then put "%upcase(&check_type.): Duplicate records found for key variables. KEY=&by_vars. &order.." ;
run;

%***************************;
%** Step 3: --SEQ & output;
%***************************;
data &dataset_out.;
  set __temp1;
  by &by_vars. &order.;

  if first.&by_vars. then &new_var.=0;
  &new_var.+1;
run;


%***************************;
%** Step 4: delete temporary datasets;
%***************************;
proc datasets lib=work nolist;
  delete __temp1 __check1;
quit;


%mend derive_var_obs_number;
