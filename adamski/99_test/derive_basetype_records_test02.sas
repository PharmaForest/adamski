/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_basetype_records() macro for case without subset condition

### Expected result:  
- dataset test bds_with_basetype with `BASETYPE` will be created  

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
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

/*Expected result dataset*/
data bds_expected;
  length USUBJID $3 EPOCH $15 PARAMCD $8 BASETYPE $200;
  input USUBJID $ EPOCH $ PARAMCD $ ASEQ AVAL BASETYPE $;
  datalines;
   P01    RUN-IN       PARAM01     1  10.0 LAST
   P01    RUN-IN       PARAM01     2   9.8 LAST
   P01    DOUBLE-BLIND PARAM01     3   9.2 LAST
   P01    DOUBLE-BLIND PARAM01     4  10.1 LAST

   P01    RUN-IN       PARAM01     1  10.0 WORST
   P01    RUN-IN       PARAM01     2   9.8 WORST
   P01    DOUBLE-BLIND PARAM01     3   9.2 WORST
   P01    DOUBLE-BLIND PARAM01     4  10.1 WORST

;
run;

/*Test dataset*/
%derive_basetype_records(
  dataset=bds,
  basetypes=LAST|WORST,
  conditions=1 | 1,
  outdata=bds_with_basetype
);

/*Compare*/
%mp_assertdataset(
  base=bds_expected,				/* parameter in proc compare */
  compare=bds_with_basetype,				/* parameter in proc compare */
  desc=(%nrstr(%derive_basetype_records))[test02] Compare expected and test results for case without subset conditions, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion=0,       		/* parameter in proc compare */
  method=absolute,    /* parameter in proc compare */
  outds=TEMP.adamski_test
);
