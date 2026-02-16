/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_var_obs_number() macro

### Expected result:  
- dataset adae_seq with ASEQ variable will be created  

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*Expected result dataset*/
data adae_seq_expected;
  input USUBJID $ AESTDTC $10. AETERM $ ASEQ;
  datalines;
001 2024-01-01 Headache 1
001 2024-01-01 Nausea 2
001 2024-01-05 Fever 3
002 2024-02-01 Rash 1
;
run;

/*Test dataset*/
data adae;
  input USUBJID $ AESTDTC $10. AETERM $;
  datalines;
001 2024-01-01 Headache
001 2024-01-05 Fever
001 2024-01-01 Nausea
002 2024-02-01 Rash
;
run;

%derive_var_obs_number(
  data        = adae,
  dataset_out = adae_seq,
  by_vars     = USUBJID,
  order       = AESTDTC,
  new_var     = ASEQ,
  check_type  = none
);

/*Compare*/
%mp_assertdataset(
  base=adae_seq_expected,				/* parameter in proc compare */
  compare=adae_seq,				/* parameter in proc compare */
  desc=(%nrstr(%derive_var_obs_number))[test01] Compare expected and test results, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion=0,       		/* parameter in proc compare */
  method=absolute,    /* parameter in proc compare */
  outds=TEMP.adamski_test
);
