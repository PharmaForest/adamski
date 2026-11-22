
/*** HELP START ***/
/*

### Macro:
    %min_cond

### Purpose:
    Reusable SQL aggregate helper macro that returns the
    minimum nonmissing numeric value among observations
    satisfying a specified condition within a group.

    This is a GROUP-LEVEL evaluation, not a record-level
    flag derivation. The grouping is determined by the
    calling PROC SQL query and its GROUP BY variables.

    Returns a missing numeric value when no qualifying
    nonmissing value exists within the group.

    The macro generates a SAS PROC SQL aggregate expression.
    It does not independently execute PROC SQL or create
    an output dataset.

### Parameters:

 - 'var' (required) : numeric variable or SQL expression
                      for which the minimum is calculated
 - 'cond' (required) : condition used to select observations
                       for the minimum calculation

### Sample code:

~~~sas

**Example1: calculate minimum analysis value per subject;

data adqs;
    length USUBJID $10 ANL01FL $1;
    input USUBJID $ AVISITN AVAL ANL01FL $;
datalines;
101 0  45 Y
101 6  60 Y
101 12 75 N
102 0  30 Y
102 6  50 Y
102 12 65 Y
103 0  40 N
103 6  55 N
;
run;

proc sql;
    create table result1 as
    select USUBJID,
           %min_cond(var=AVAL, cond=ANL01FL = "Y")
               as MIN_AVAL
    from adqs
    group by USUBJID;
quit;


**Example2: calculate minimum post-baseline value per subject and parameter;

data adlb;
    length USUBJID $10 PARAMCD $8;
    input USUBJID $ PARAMCD $ AVISITN AVAL;
datalines;
101 ALT 0  25
101 ALT 1  35
101 ALT 2  48
101 AST 0  20
101 AST 1  30
101 AST 2  42
102 ALT 0  28
102 ALT 1  40
102 ALT 2  36
;
run;

proc sql;
    create table result2 as
    select USUBJID,
           PARAMCD,
           %min_cond(var=AVAL, cond=AVISITN > 0)
               as MIN_POSTBL
    from adlb
    group by USUBJID, PARAMCD;
quit;


**Example3: calculate minimum value meeting multiple conditions;

data advs;
    length USUBJID $10 PARAMCD $8 ANL01FL $1;
    input USUBJID $ PARAMCD $ AVISITN AVAL ANL01FL $;
datalines;
101 TEMP 0  37.0 Y
101 TEMP 1  38.2 Y
101 TEMP 2  39.1 N
101 TEMP 3  38.5 Y
102 TEMP 0  36.8 Y
102 TEMP 1  37.5 N
102 TEMP 2  38.0 Y
;
run;

proc sql;
    create table result3 as
    select USUBJID,
           %min_cond(
               var=AVAL,
               cond=AVISITN > 0 and ANL01FL = "Y"
           ) as MIN_VALID_TEMP
    from advs
    group by USUBJID;
quit;


**Example4: return missing when no qualifying value exists;

data adrs;
    length USUBJID $10 AVALC $2;
    input USUBJID $ AVISITN AVAL AVALC $;
datalines;
101 1 50 PR
101 2 70 CR
101 3 80 CR
102 1 40 SD
102 2 55 PR
103 1 .  CR
103 2 65 PR
;
run;

proc sql;
    create table result4 as
    select USUBJID,
           %min_cond(var=AVAL, cond=AVALC = "CR")
               as MIN_CR_AVAL
    from adrs
    group by USUBJID;
quit;

~~~

### Notes:

 - This is a reusable SQL aggregate expression helper.
 - Returns the minimum nonmissing numeric value among
   observations satisfying COND.
 - Observations not satisfying COND contribute missing
   values to the aggregate expression.
 - Missing numeric values are ignored by the MIN aggregate.
 - Returns numeric missing when no qualifying nonmissing
   value exists within a nonempty group.
 - The evaluation level is determined by the GROUP BY
   variables in the calling PROC SQL query.
 - GROUP BY USUBJID calculates the minimum per subject.
 - GROUP BY USUBJID PARAMCD calculates the minimum per
   subject and parameter combination.
 - Without GROUP BY, the aggregate evaluates all
   observations in the query result.
 - The macro does not independently read datasets,
   perform joins, or execute PROC SQL.
 - This is not a row-wise DATA step function.
 - Empty groups do not automatically produce a result.
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

%macro min_cond(var=, cond=);
    %if %superq(var) = %then %do;
        %put ERROR: min_cond: Required parameter var is missing.;
        %return;
    %end;
    %if %superq(cond) = %then %do;
        %put ERROR: min_cond: Required parameter cond is missing.;
        %return;
    %end;
    min(ifn((&cond), (&var), .))
%mend min_cond;
