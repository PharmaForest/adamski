/*** HELP START ***//*
### Purpose:
- Unit test for the %derive_var_relative_flag() macro
  - flag records up to and including the first record meeting the condition
  - BY groups with no reference record are flagged (flag_no_ref_groups default)
*//*** HELP END ***/
%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data response;
    length USUBJID $10 AVALC $2;
    infile datalines dsd dlm=',' truncover;
    input USUBJID $ AVISITN AVALC $;
datalines;
1,0,PR
1,1,CR
1,2,CR
1,3,SD
1,4,NE
2,0,SD
2,1,PD
2,2,PD
3,0,SD
4,0,SD
4,1,PR
4,2,PD
4,3,SD
4,4,PR
;
run;

/*expected output*/
data response_exp;
    length USUBJID $10 AVALC $2 ANL02FL $1;
    infile datalines dsd dlm='|' truncover;
    input USUBJID :$10.
          AVALC   :$2.
          AVISITN
          ANL02FL :$1.;
datalines;
1|PR|0|Y
1|CR|1|Y
1|CR|2|Y
1|SD|3|Y
1|NE|4|Y
2|SD|0|Y
2|PD|1|Y
2|PD|2|
3|SD|0|Y
4|SD|0|Y
4|PR|1|Y
4|PD|2|Y
4|SD|3|
4|PR|4|
;
run;

/*output by the macro*/
%derive_var_relative_flag(
    dataset=response,
    by_vars=USUBJID,
    order=AVISITN,
    new_var=ANL02FL,
    condition=AVALC = "PD",
    mode=first,
    selection=before,
    inclusive=1,
    outdata=response_out
);

/*Compare*/
%mp_assertdataset(
  base      = response_exp,             /* parameter in proc compare */
  compare   = response_out,             /* parameter in proc compare */
  desc      = (%nrstr(%derive_var_relative_flag))[test02] Compare expected and test results,
  id=,                                  /* parameter in proc compare(e.g. id=USUBJID) */
  by=,                                  /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion = 1e-8,                     /* parameter in proc compare */
  method    = absolute,                 /* parameter in proc compare */
  outds     = TEMP.adamski_test
);
