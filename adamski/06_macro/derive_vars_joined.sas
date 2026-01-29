/*** HELP START ***//*
%derive_vars_joined(
  dataset_add=,
  by_vars=,
  new_vars=,
  condition=,
  exist_flag=,
  true_value=Y,
  false_value=
)

### Macro:
    %derive_vars_joined

### Purpose:
    Performs a hash-based lookup (left-join style) from the current DATA step row to an external dataset.
    If key(s) match, values of `new_vars` are populated from `dataset_add`.
    Optionally creates a character flag `exist_flag` indicating whether a match exists.

### Parameters:

 - `dataset_add` (required)
      Source dataset used for the lookup (e.g., `SDTM.AE`).

 - `by_vars` (required)
      Space-separated list of key variables used to find matches (e.g., `USUBJID`).

 - `new_vars` (required)
      Space-separated list of variables to bring from `dataset_add` into the current DATA step.
      These variables must exist in `dataset_add`. When no match is found, they are set to missing.

 - `condition` (optional)
      WHERE clause (text) applied to `dataset_add` before building the hash.
      If provided, only records satisfying the condition are used for lookup.
      Example: `%nrbquote(SEX="F" and AGE>=18)`

 - `exist_flag` (optional)
      Name of an output character variable indicating existence of a match for the current rowÅfs key(s).
      If omitted, no flag is created.

 - `true_value` (optional)
      Value assigned to `exist_flag` when a match is found.
      Default: `Y`.

 - `false_value` (optional)
      Value assigned to `exist_flag` when no match is found.
      Default: (blank).

### How it works:
 - A hash object is created once (first iteration) from `dataset_add` (optionally filtered by `condition`).
 - `by_vars` define the key(s). `new_vars` are the data fields returned by `find()`.
 - On each DATA step row, `find()` is executed:
     - if not found: `new_vars` are set to missing
     - if found: `new_vars` are retained from the hash entry
 - If `exist_flag` is specified, it is set to `true_value`/`false_value` based on match status.

### Sample code

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
data want1;
  set have;
  %derive_vars_joined(
    dataset_add = add,
    by_vars     = USUBJID,
    new_vars    = AGE SEX
  );
run;
data want2;
  set have;
  %derive_vars_joined(
    dataset_add = add,
    by_vars     = USUBJID,
    new_vars    = AGE SEX,
    condition= %nrbquote(SEX="F"),
    exist_flag= EXFL ,
    true_value = Y,
    false_value = N
  );
run;

~~~

### Notes:
 - This macro is intended to be called *inside a DATA step*.
 - `by_vars` and `new_vars` must exist in `dataset_add`.

### Author:
    Yutaka Morioka

### Latest update Date:
    2026-01-29
*//*** HELP END ***/

%macro derive_vars_joined(
dataset_add=,
by_vars=,
new_vars=,
condition=,
exist_flag= ,
true_value = Y,
false_value = 
);
%local name qkey _tlen _flen _len;
%let name  = &sysindex;
%let qkey  = %sysfunc( tranwrd( %str("&by_vars.") , %str( ) , %str(",") ) );
%let _tlen=%length(%superq(true_value));
%let _flen=%length(%superq(false_value));
%let _len=%sysfunc(max(%sysfunc(max(&_tlen,1)),&_flen));

if 0 then set &dataset_add(keep= &by_vars. &new_vars.);
%let name  = &sysindex;
retain _N_&name 1;
if _N_&name = 1 then do;
%if %length(&condition) ne 0 %then %do;
 rc&name.=dosubl("proc sql noprint;  create view h&name.(label=%unquote(%bquote('master=&dataset_add'))) as
 select * from &dataset_add 
 where &condition;
 quit;");
 drop  rc&name;
%end;
%if %length(&condition) ne 0 %then %do;
 declare hash h&name.(dataset:"h&name.(keep= &by_vars &new_vars.)" ,  duplicate:'E');
  call execute("proc sql noprint;
 drop view h&name. ;
 quit;");
%end;
%else %do;
 declare hash h&name.(dataset:"&dataset_add(keep= &by_vars &new_vars.)", duplicate:'E');
%end;
 h&name..definekey(&qkey.);
 h&name..definedata(all:'Y');
 h&name..definedone();
 _N_&name = 0 ;
end;
drop _N_&name ;
if h&name..find() ne  0 then do;
call missing(of &new_vars. );
end;
%if %length(&exist_flag) ne 0 %then %do;
  length &exist_flag $ &_len;
  &exist_flag = ifc(h&name..check()=0,"&true_value","&false_value");
%end;
%mend derive_vars_joined;

