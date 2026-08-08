/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_var_extreme_flag() macro  

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*base dataset*/
data advs;
    length USUBJID $10 PARAMCD $10 AVISIT $20 STUDYID $10;
    informat ADT yymmdd10.;
    format ADT yymmdd10.;

    infile datalines dsd dlm=',' truncover;
    input USUBJID $ PARAMCD $ AVISIT $ ADT :yymmdd10. AVAL;
    STUDYID = "AB123";
datalines;
1015,TEMP,BASELINE,2021-04-27,38.0
1015,TEMP,BASELINE,2021-04-25,39.0
1015,TEMP,WEEK 2,2021-05-10,37.5
1015,WEIGHT,SCREENING,2021-04-19,81.2
1015,WEIGHT,BASELINE,2021-04-25,82.7
1015,WEIGHT,BASELINE,2021-04-27,84.0
1015,WEIGHT,WEEK 2,2021-05-09,82.5
1023,TEMP,SCREENING,2021-04-27,38.0
1023,TEMP,BASELINE,2021-04-28,37.5
1023,TEMP,BASELINE,2021-04-29,37.5
1023,TEMP,WEEK 1,2021-05-03,37.0
1023,WEIGHT,SCREENING,2021-04-27,69.6
1023,WEIGHT,BASELINE,2021-04-29,67.2
1023,WEIGHT,WEEK 1,2021-05-02,65.9
;
run;



/*expected output*/
data advs_exp;
    length STUDYID $10
           USUBJID  $10
           PARAMCD  $10
           AVISIT   $20
           ABLFL    $1;

    informat ADT yymmdd10.;
    format ADT yymmdd10.;

    infile datalines dsd dlm='|' truncover;

    input STUDYID :$10.
          USUBJID  :$10.
          PARAMCD  :$10.
          AVISIT   :$20.
          ADT      :yymmdd10.
          AVAL
          ABLFL    :$1.;

datalines;
AB123|1015|TEMP|BASELINE|2021-04-25|39|
AB123|1015|TEMP|BASELINE|2021-04-27|38|Y
AB123|1015|TEMP|WEEK 2|2021-05-10|37.5|
AB123|1015|WEIGHT|SCREENING|2021-04-19|81.2|
AB123|1015|WEIGHT|BASELINE|2021-04-25|82.7|
AB123|1015|WEIGHT|BASELINE|2021-04-27|84|Y
AB123|1015|WEIGHT|WEEK 2|2021-05-09|82.5|
AB123|1023|TEMP|SCREENING|2021-04-27|38|
AB123|1023|TEMP|BASELINE|2021-04-28|37.5|
AB123|1023|TEMP|BASELINE|2021-04-29|37.5|Y
AB123|1023|TEMP|WEEK 1|2021-05-03|37|
AB123|1023|WEIGHT|SCREENING|2021-04-27|69.6|
AB123|1023|WEIGHT|BASELINE|2021-04-29|67.2|Y
AB123|1023|WEIGHT|WEEK 1|2021-05-02|65.9|
;
run;


/*output by the macro*/	
data advs_base advs_others;
    set advs;
    if AVISIT = "BASELINE" then output advs_base;
    else output advs_others;
run;


%derive_var_extreme_flag(
    dataset=advs_base,
    by_vars=STUDYID USUBJID PARAMCD,
    order=ADT,
    new_var=ABLFL,
    mode=last,
    true_value=Y,
    false_value=,
    flag_all=0,
    check_type=warning,
    outdata=advs_out
);

/* set baseline and rest of the records */
data advs_out;
	set advs_out advs_others;
run;	

proc sort data=advs_out;
    by STUDYID USUBJID PARAMCD ADT;
run;


/*Compare*/
%mp_assertdataset(
  base			= advs_exp,					/* parameter in proc compare */
  compare	= advs_out,					/* parameter in proc compare */
  desc		= (%nrstr(%derive_var_extreme_flag))[test01] Compare expected and test results, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion	= 1e-8,       		/* parameter in proc compare */
  method		= absolute,    /* parameter in proc compare */
  outds		= TEMP.adamski_test
);


