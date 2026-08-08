/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_var_extreme_flag() macro  

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data adae;
    length USUBJID $10 AEBODSYS $30 AEDECOD $20 AESEV $10 STUDYID $10;
    infile datalines dsd dlm=',' truncover;
    input USUBJID $ AEBODSYS :$30. AEDECOD :$20. AESEV $ AESTDY AESEQ;
    STUDYID = "AB123";
datalines;
1015,GENERAL DISORDERS,ERYTHEMA,MILD,2,1
1015,GENERAL DISORDERS,PRURITUS,MILD,2,2
1015,GI DISORDERS,DIARRHOEA,MILD,8,3
1023,CARDIAC DISORDERS,AV BLOCK,MILD,22,4
1023,SKIN DISORDERS,ERYTHEMA,MILD,3,1
1023,SKIN DISORDERS,ERYTHEMA,SEVERE,5,2
1023,SKIN DISORDERS,ERYTHEMA,MILD,8,3
;
run;



/*expected output*/
data adae_exp;
    length STUDYID $10
           USUBJID  $10
           AEDECOD  $20
           AESEV    $10
           AOCCIFL  $1;

    infile datalines dsd dlm='|' truncover;

    input STUDYID :$10.
          USUBJID  :$10.
          AEDECOD  :$20.
          AESEV    :$10.
          AESTDY
          AESEQ
          AOCCIFL  :$1.;

datalines;
AB123|1015|ERYTHEMA|MILD|2|1|Y
AB123|1015|PRURITUS|MILD|2|2|Y
AB123|1015|DIARRHOEA|MILD|8|3|
AB123|1023|ERYTHEMA|MILD|3|1|
AB123|1023|ERYTHEMA|SEVERE|5|2|Y
AB123|1023|ERYTHEMA|MILD|8|3|
AB123|1023|AV BLOCK|MILD|22|4|
;
run;


/*output by the macro*/	
data adae;
    set adae;

    **Convert AESEV into numeric severity ranking:SEVERE=1, MODERATE=2, MILD=3; 
    if upcase(AESEV) = "SEVERE" then TEMP_AESEVN = 1;
    else if upcase(AESEV) = "MODERATE" then TEMP_AESEVN = 2;
    else if upcase(AESEV) = "MILD" then TEMP_AESEVN = 3;
run;

%derive_var_extreme_flag(
    dataset=adae,
    by_vars=STUDYID USUBJID,
    order=TEMP_AESEVN AESTDY,
    new_var=AOCCIFL,
    mode=first,
    flag_all=1,
    true_value=Y,
    false_value=,
    check_type=warning,
    outdata=adae_out
);


/*Compare*/
%mp_assertdataset(
  base			= adae_exp,					/* parameter in proc compare */
  compare	= adae_out,					/* parameter in proc compare */
  desc		= (%nrstr(%derive_var_extreme_flag))[test01] Compare expected and test results, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion	= 1e-8,       		/* parameter in proc compare */
  method		= absolute,    /* parameter in proc compare */
  outds		= TEMP.adamski_test
);


