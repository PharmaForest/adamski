/*** HELP START ***//*

### Macro:
    %derive_var_merged_exist_flag

### Purpose:
    Creates a character flag variable indicating whether the current DATA step row's key(s) exist in another dataset. 

### Parameters:

 - `dataset_add` (required) : Dataset to check for existence (e.g., `SDTM.AE`).

 - `by_vars`     (required) : Space-separated list of key variables used for the lookup.

 - `new_var`     (required) : Name of the output flag variable to create (character).

 - `condition`   (optional) : WHERE clause (as text) applied to `dataset_add` before building  the hash (e.g., `%nrbquote(SEX="F")`). If omitted, all rows are used.

 - `true_value`  (optional) : Value assigned to `new_var` when a match is found.
                              Default: `Y`.

 - `false_value` (optional) : Value assigned to `new_var` when no match is found.
                              Default: (blank).

### Sample code

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

### Note:

- Parameter `dataset` in {admiral} is not defined taking into account how the macro in SAS is used.  

- Parameter `filter_add' is omitted because SAS's mechanism makes it difficult to differentiate it from the condition parameter. Records filtered by condition are the subject of evaluation.

- Parameter  `missing_value` parameter has not been implemented at this time, as there are currently few practical use cases that come to mind.

### URL:

https://github.com/PharmaForest/adamski

Author:                 Yutaka Morioka
Latest update Date:     2025-10-15

*//*** HELP END ***/

%macro derive_var_merged_exist_flag(
dataset_add=,
by_vars=,
new_var=,
condition=,
true_value = Y,
false_value = 
);
%local name qkey _tlen _flen _len;
%let name  = &sysindex;
%let qkey  = %sysfunc( tranwrd( %str("&by_vars.") , %str( ) , %str(",") ) );
%let _tlen=%length(%superq(true_value));
%let _flen=%length(%superq(false_value));
%let _len=%sysfunc(max(%sysfunc(max(&_tlen,1)),&_flen));

if 0 then set &dataset_add(keep= &by_vars.);
if _N_=1 then do;
%if %length(&condition) ne 0 %then %do;
 rc&name.=dosubl("proc sql noprint;  create view h&name.(label=%unquote(%bquote('master=&dataset_add'))) as
 select * from &dataset_add
 where &condition;
 quit;");
 drop  rc&name;
%end;
%if %length(&condition) ne 0 %then %do;
 declare hash h&name.(dataset:"h&name.(keep= &by_vars)" ,  multidata:'Y');
  call execute("proc sql noprint;
 drop view h&name. ;
 quit;");
%end;
%else %do;
 declare hash h&name.(dataset:"&dataset_add(keep= &by_vars)", multidata:'Y');
%end;
 h&name..definekey(&qkey.);
 h&name..definedone();
end;
length &new_var $ &_len;
&new_var = ifc(h&name..check()=0,"&true_value","&false_value");
%mend derive_var_merged_exist_flag;
