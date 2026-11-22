
/*** HELP START ***/
/*

### Macro:
    %all


### Purpose:
    Reusable SQL aggregate helper macro that evaluates a
    specified condition across all observations within a group.

    Returns 1 only when EVERY observation in the group
    satisfies the condition; otherwise returns 0.

    This is a GROUP-LEVEL evaluation, not a record-level
    flag derivation. For example, when PROC SQL groups
    observations by USUBJID, the macro returns one result
    per subject, rather than a separate flag for each visit.

    The macro generates a SAS PROC SQL aggregate expression.
    It does not independently create or modify datasets.


### Parameters:

 - 'cond' (required) :
     SAS SQL condition to evaluate for each observation.

### Sample code:

~~~sas

**Example1: Check whether all observations have AVALC = "Y";

proc sql;
    create table work.result1 as
    select USUBJID,
           %all(cond=AVALC = "Y") as ALL_Y
    from work.adrs
    group by USUBJID;
quit;


**Example2: Check whether all observations belong to
           either CR or PR response categories;

proc sql;
    create table work.result2 as
    select USUBJID,
           %all(cond=AVALC in ("CR", "PR")) as ALL_RESP
    from work.adrs
    group by USUBJID;
quit;


**Example3: Check whether all observations satisfy
           multiple conditions;

proc sql;
    create table work.result3 as
    select USUBJID,
           %all(cond=AVAL > 0 and ANL01FL = "Y") as ALL_VALID
    from work.adrs
    group by USUBJID;
quit;


**Example4: Use the helper in a HAVING clause;

proc sql;
    create table work.result4 as
    select USUBJID,
           count(*) as N
    from work.adrs
    group by USUBJID
    having %all(cond=ANL01FL = "Y") = 1;
quit;

~~~

### Notes:

 - The evaluation level is determined by the calling PROC SQL query and its GROUP BY variables.
 - GROUP BY USUBJID evaluates observations within each subject.
 - GROUP BY USUBJID PARAMCD evaluates observations within each subject and parameter combination.
 - Without GROUP BY, the aggregate evaluates all observations in the query result.
 - To assign the group-level result to individual records, the calling program must explicitly merge or join it back.
 - Empty groups do not automatically produce a result.

### URL:

https://github.com/PharmaForest/adamski

---

Author:                 Manivannan Mathialagan
Latest update Date:     2026-11-22

---

*/
/*** HELP END ***/

%macro all(cond=);
    %if %superq(cond) = %then %do;
        %put ERROR: all: Required parameter cond is missing.;
        %return;
    %end;
    min(ifn((&cond), 1, 0))
%mend all;
