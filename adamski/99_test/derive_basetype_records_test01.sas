/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_basetype_records() macro 

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
P01 RUN-IN PARAM01 1 10.0
P01 RUN-IN PARAM01 2 9.8
P01 DOUBLE-BLIND PARAM01 3 9.2
P01 DOUBLE-BLIND PARAM01 4 10.1
P01 OPEN-LABEL PARAM01 5 10.4
P01 OPEN-LABEL PARAM01 6 9.9
P02 RUN-IN PARAM01 1 12.1
P02 DOUBLE-BLIND PARAM01 2 10.2
P02 DOUBLE-BLIND PARAM01 3 10.8
P02 OPEN-LABEL PARAM01 4 11.4
P02 OPEN-LABEL PARAM01 5 10.8
;
run;

/*Expected result dataset*/
data bds_expected;
  length USUBJID $3 EPOCH $15 PARAMCD $8 BASETYPE $200;
  input USUBJID $ EPOCH $ PARAMCD $ ASEQ AVAL BASETYPE $;
  datalines;
P01 RUN-IN PARAM01 1 10.0 RUN-IN
P01 RUN-IN PARAM01 2 9.8 RUN-IN
P01 DOUBLE-BLIND PARAM01 3 9.2 RUN-IN
P01 DOUBLE-BLIND PARAM01 4 10.1 RUN-IN
P01 OPEN-LABEL PARAM01 5 10.4 RUN-IN
P01 OPEN-LABEL PARAM01 6 9.9 RUN-IN
P02 RUN-IN PARAM01 1 12.1 RUN-IN
P02 DOUBLE-BLIND PARAM01 2 10.2 RUN-IN
P02 DOUBLE-BLIND PARAM01 3 10.8 RUN-IN
P02 OPEN-LABEL PARAM01 4 11.4 RUN-IN
P02 OPEN-LABEL PARAM01 5 10.8 RUN-IN

P01 DOUBLE-BLIND PARAM01 3 9.2 DOUBLE-BLIND
P01 DOUBLE-BLIND PARAM01 4 10.1 DOUBLE-BLIND
P01 OPEN-LABEL PARAM01 5 10.4 DOUBLE-BLIND
P01 OPEN-LABEL PARAM01 6 9.9 DOUBLE-BLIND
P02 DOUBLE-BLIND PARAM01 2 10.2 DOUBLE-BLIND
P02 DOUBLE-BLIND PARAM01 3 10.8 DOUBLE-BLIND
P02 OPEN-LABEL PARAM01 4 11.4 DOUBLE-BLIND
P02 OPEN-LABEL PARAM01 5 10.8 DOUBLE-BLIND

P01 OPEN-LABEL PARAM01 5 10.4 OPEN-LABEL
P01 OPEN-LABEL PARAM01 6 9.9 OPEN-LABEL
P02 OPEN-LABEL PARAM01 4 11.4 OPEN-LABEL
P02 OPEN-LABEL PARAM01 5 10.8 OPEN-LABEL

;
run;

/*Test dataset*/
%derive_basetype_records(
  dataset=bds,
  basetypes=RUN-IN|DOUBLE-BLIND|OPEN-LABEL,
  conditions=
    EPOCH in ("RUN-IN","STABILIZATION","DOUBLE-BLIND","OPEN-LABEL") |
    EPOCH in ("DOUBLE-BLIND","OPEN-LABEL") |
    EPOCH = "OPEN-LABEL",
    outdata=bds_with_basetype    
)

/*Compare*/
%mp_assertdataset(
  base=bds_expected,				/* parameter in proc compare */
  compare=bds_with_basetype,				/* parameter in proc compare */
  desc=(%nrstr(%derive_basetype_records))[test01] Compare expected and test results, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion=0,       		/* parameter in proc compare */
  method=absolute,    /* parameter in proc compare */
  outds=TEMP.adamski_test
);
