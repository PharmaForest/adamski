
/*** HELP START ***/
/*

### Macro:
    %any

### Purpose:
    Reusable SQL aggregate helper macro that evaluates a
    specified condition across observations within a group.

    Returns 1 when AT LEAST ONE observation in the group
    satisfies the condition; otherwise returns 0.

    This is a GROUP-LEVEL evaluation, not a record-level
    flag derivation. For example, when PROC SQL groups
    observations by USUBJID, the macro returns one result
    per subject rather than a separate flag for each visit.

    The macro generates a SAS PROC SQL aggregate expression.
    It does not independently execute PROC SQL or create
    an output dataset.

### Parameters:

 - 'cond' (required) :
     SAS SQL condition evaluated for each observation.
     Multiple conditions may be combined using AND or OR.

### Sample code:

~~~sas

data adrs;
    length USUBJID $3 AVALC $2 ANL01FL $1;
    input USUBJID $ AVISITN AVALC $ ANL01FL $ AVAL;
    datalines;
001 1 PR Y 60
001 2 CR Y 80
001 3 SD N 40
002 1 SD Y 40
002 2 PD N 20
003 1 PR Y 70
003 2 CR Y 90
;
run;


**Example1: Check whether any observation has AVALC = "CR";

proc sql;
    create table work.result1 as
    select USUBJID,
           %any(cond=AVALC = "CR") as ANY_CR
    from adrs
    group by USUBJID;
quit;


**Example2: Check whether any observation satisfies
           both conditions;

proc sql;
    create table work.result2 as
    select USUBJID,
           %any(cond=AVALC = "CR" and ANL01FL = "Y")
               as ANY_VALID_CR
    from adrs
    group by USUBJID;
quit;


**Example3: Check whether any observation has AVAL > 75;

proc sql;
    create table work.result3 as
    select USUBJID,
           %any(cond=AVAL > 75) as ANY_HIGH
    from adrs
    group by USUBJID;
quit;


**Example4: Select subjects with at least one CR record;

proc sql;
    create table work.result4 as
    select USUBJID,
           count(*) as N
    from adrs
    group by USUBJID
    having %any(cond=AVALC = "CR") = 1;
quit;

~~~

### Notes:

 - This is a reusable SQL aggregate helper macro.
 - The evaluation level is determined by the calling PROC SQL query and its GROUP BY variables.
 - GROUP BY USUBJID evaluates observations per subject.
 - GROUP BY USUBJID PARAMCD evaluates observations per subject and parameter combination.
 - Without GROUP BY, the aggregate evaluates all observations in the query result.
 - Returns 1 if any observation satisfies the condition; otherwise returns 0 for a nonempty group.
 - The macro does not perform joins or BY processing.
 - The macro is intended for PROC SQL expressions, not row-wise DATA step execution.
 - To assign a group-level result to individual records, the calling program must explicitly merge or join the result back to the original dataset.
 - Empty groups do not automatically produce a result.
 - SAS missing-value comparisons follow SAS SQL semantics, which may differ from R NA behavior.
 - Explicit missing-value guards may be required when reproducing R behavior.

### URL:

https://github.com/PharmaForest/adamski

---

Author:                 Manivannan Mathialagan
Latest update Date:     2026-11-22

---

*/
/*** HELP END ***/

%macro any(cond=);
    %if %superq(cond) = %then %do;
        %put ERROR: any: Required parameter cond is missing.;
        %return;
    %end;
    max(ifn((&cond), 1, 0))
%mend any;