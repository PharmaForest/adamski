/*** HELP START ***//*
### Purpose:
- Unit test for the %derive_var_relative_flag() macro
  - flag records after the LAST record meeting the condition
*//*** HELP END ***/
%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data adae;
    length USUBJID $10 ACOVFL $1;
    infile datalines dsd dlm=',' truncover;
    input USUBJID $ ASTDY ACOVFL $ AESEQ;
datalines;
1,2,,1
1,5,Y,2
1,5,,3
1,17,,4
1,27,Y,5
1,32,,6
2,8,,1
2,11,,2
;
run;

/*expected output*/
data adae_exp;
    length USUBJID $10 ACOVFL $1 PSTCOVFL $1;
    infile datalines dsd dlm='|' truncover;
    input USUBJID  :$10.
          ACOVFL   :$1.
          ASTDY
          AESEQ
          PSTCOVFL :$1.;
datalines;
1||2|1|
1|Y|5|2|
1||5|3|
1||17|4|
1|Y|27|5|
1||32|6|Y
2||8|1|
2||11|2|
;
run;

/*output by the macro*/
%derive_var_relative_flag(
    dataset=adae,
    by_vars=USUBJID,
    order=ASTDY AESEQ,
    new_var=PSTCOVFL,
    condition=ACOVFL = "Y",
    mode=last,
    selection=after,
    inclusive=0,
    flag_no_ref_groups=0,
    outdata=adae_out
);

/*Compare*/
%mp_assertdataset(
  base      = adae_exp,                 /* parameter in proc compare */
  compare   = adae_out,                 /* parameter in proc compare */
  desc      = (%nrstr(%derive_var_relative_flag))[test03] Compare expected and test results,
  id=,                                  /* parameter in proc compare(e.g. id=USUBJID) */
  by=,                                  /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion = 1e-8,                     /* parameter in proc compare */
  method    = absolute,                 /* parameter in proc compare */
  outds     = TEMP.adamski_test
);
