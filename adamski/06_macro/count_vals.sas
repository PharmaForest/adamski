
/*** HELP START ***/
/*

### Macro:
    %count_vals

### Purpose:
    Reusable SQL aggregate helper macro that counts observations
    where a specified variable equals a specified value.

    Returns the number of matching observations within each group,
    rather than a separate count or flag for each input record.

    This is a GROUP-LEVEL evaluation, not a record-level flag
    derivation. The grouping is determined by the calling
    PROC SQL query and its GROUP BY variables.

    The macro generates a SAS PROC SQL aggregate expression.
    It does not independently execute PROC SQL or create
    an output dataset.

### Parameters:

 - 'var' (required) : variable or SQL expression to evaluate
 - 'val' (required) : value to compare against VAR;
                      character literals must be quoted

### Sample code:

~~~sas

**Example1: count observations with complete response per subject;

data adrs;
    length USUBJID $10 AVALC $2;
    input USUBJID $ AVISITN AVALC $;
datalines;
101 1 PR
101 2 CR
101 3 CR
102 1 SD
102 2 PR
103 1 CR
103 2 SD
;
run;

proc sql;
    create table result1 as
    select USUBJID,
           %count_vals(var=AVALC, val="CR") as N_CR
    from adrs
    group by USUBJID;
quit;


**Example2: count analysis records per subject and parameter;

data adqs;
    length USUBJID $10 PARAMCD $8 ANL01FL $1;
    input USUBJID $ PARAMCD $ AVISITN ANL01FL $;
datalines;
101 FIQLTOT 0 Y
101 FIQLTOT 6 Y
101 FIQLTOT 12 N
101 SMIS108 0 Y
101 SMIS108 6 Y
102 FIQLTOT 0 N
102 FIQLTOT 6 Y
;
run;

proc sql;
    create table result2 as
    select USUBJID,
           PARAMCD,
           %count_vals(var=ANL01FL, val="Y") as N_ANALYSIS
    from adqs
    group by USUBJID, PARAMCD;
quit;


**Example3: count observations matching a numeric value;

data adae;
    length USUBJID $10;
    input USUBJID $ AESEQ AESER;
datalines;
101 1 1
101 2 0
101 3 1
102 1 0
102 2 0
103 1 1
;
run;

proc sql;
    create table result3 as
    select USUBJID,
           %count_vals(var=AESER, val=1) as N_SERIOUS
    from adae
    group by USUBJID;
quit;


**Example4: select subjects with at least two CR observations;

data adrs_repeat;
    length USUBJID $10 AVALC $2;
    input USUBJID $ AVISITN AVALC $;
datalines;
101 1 CR
101 2 CR
101 3 PR
102 1 CR
102 2 SD
103 1 CR
103 2 CR
103 3 CR
;
run;

proc sql;
    create table result4 as
    select USUBJID,
           %count_vals(var=AVALC, val="CR") as N_CR
    from adrs_repeat
    group by USUBJID
    having %count_vals(var=AVALC, val="CR") >= 2;
quit;

~~~

### Notes:

 - This is a reusable SQL aggregate expression helper.
 - Returns the number of observations satisfying VAR = VAL.
 - Returns 0 when no observations match within a nonempty group.
 - The evaluation level is determined by the GROUP BY variables.
 - GROUP BY USUBJID produces a count per subject.
 - GROUP BY USUBJID PARAMCD produces a count per subject
   and parameter combination.
 - Without GROUP BY, the aggregate evaluates all observations
   in the query result.
 - The macro does not independently read datasets, perform
   joins, or execute PROC SQL.
 - This is not a row-wise DATA step function.
 - Empty groups do not automatically produce a result.
 - Character values supplied through VAL must be quoted.
 - SAS missing-value comparisons may differ from R NA
   comparison behavior.
 - Explicit missing-value guards may be required when
   reproducing R behavior.

### URL:

https://github.com/PharmaForest/adamski

---

Author:                 Manivannan Mathialagan
Latest update Date:     2026-11-22

---

*/
/*** HELP END ***/

%macro count_vals(var=, val=);
    %if %superq(var) = %then %do;
        %put ERROR: count_vals: Required parameter var is missing.;
        %return;
    %end;
    %if %superq(val) = %then %do;
        %put ERROR: count_vals: Required parameter val is missing.;
        %return;
    %end;
    sum(ifn(((&var) = (&val)), 1, 0))
%mend count_vals;
