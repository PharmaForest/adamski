/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_var_merged_exist_flag() macro

*//*** HELP END ***/

/*Compare macro*/
%macro mp_assertdataset(
  base=,					/* parameter in proc compare */
  compare=,				/* parameter in proc compare */
  desc=,					/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion=0,       		/* parameter in proc compare */
  method=absolute,    /* parameter in proc compare */
  outds=work.test_results /* output dataset */
);

  %local _ne _equal test_result;

  proc compare base=&base. compare=&compare.
    out=_out outnoequal
    criterion=&criterion. method=&method.
    noprint;
  %if %length(&by.) %then %do; by &by.; %end;
  %if %length(&id.) %then %do; id &id.; %end;
  run;

  data _null_;
    if 0 then set _out nobs=n;
    call symputx('_ne', n, 'L');
  run;

  %let _equal = %sysfunc(ifc(&_ne=0, 1, 0));

  %if &_equal %then %do;
    %put NOTE: MP_ASSERTDATASET: PASS (no differences). NE=&_ne;
    %let test_result=PASS;
  %end;
  %else %do;
    %put ERROR: MP_ASSERTDATASET: FAIL (differences found). NE=&_ne;
    %let test_result=FAIL;
  %end;

  %if %length(&outds.) %then %do;

    %if not %sysfunc(exist(&outds.)) %then %do;
      data &outds.;
        length test_description $256 test_result $4 test_comments $256;
        stop;
      run;
    %end;

    data _assert_row;
      length test_description $256 test_result $4 test_comments $256;
      test_description = coalescec(symget('desc'),'');
      test_result      = symget('test_result');
      test_comments = catx(" ", "MP_ASSERTDATASET: proc compare",
			cats("base=", symget('base')),
			cats("compare=", symget('compare'))
		);
    run;

    proc append base=&outds. data=_assert_row force; run;
    proc datasets lib=work nolist; delete _assert_row; quit;
  %end;
%mend ;

/*Expected Dataset*/
data e_derive_var_merged_exist_flag;
do SEX ="F","M";
  do AGE= 12 to 17;
    if monotonic() = 1 then do;   
     AGE01FL ="Y";
     AGE02FL ="Y";
     AGE03FL ="Y";
     AGE04FL ="Yes";
     AGE05FL ="Y";
     output;
    end;
    if monotonic() = 2 then do;   
     AGE01FL ="Y";
     AGE02FL ="Y";
     AGE03FL ="Y";
     AGE04FL ="Yes";
     AGE05FL ="Y";
     output;
    end;
    if monotonic() = 3 then do;   
     AGE01FL ="Y";
     AGE02FL ="Y";
     AGE03FL ="Y";
     AGE04FL ="Yes";
     AGE05FL ="Y";
     output;
    end;
    if monotonic() = 4 then do;   
     AGE01FL ="Y";
     AGE02FL ="Y";
     AGE03FL ="Y";
     AGE04FL ="Yes";
     AGE05FL ="Y";
     output;
    end;
    if monotonic() = 5 then do;   
     AGE01FL ="Y";
     AGE02FL ="";
     AGE03FL ="Y";
     AGE04FL ="Yes";
     AGE05FL ="N";
     output;
    end;
    if monotonic() = 6 then do;   
     AGE01FL ="";
     AGE02FL ="";
     AGE03FL ="N";
     AGE04FL ="No";
     AGE05FL ="N";
     output;
    end;
    if monotonic() = 7 then do;   
     AGE01FL ="Y";
     AGE02FL ="Y";
     AGE03FL ="Y";
     AGE04FL ="Yes";
     AGE05FL ="Y";
     output;
    end;
    if monotonic() = 8 then do;   
     AGE01FL ="Y";
     AGE02FL ="Y";
     AGE03FL ="Y";
     AGE04FL ="Yes";
     AGE05FL ="Y";
     output;
    end;
    if monotonic() = 9 then do;   
     AGE01FL ="Y";
     AGE02FL ="Y";
     AGE03FL ="Y";
     AGE04FL ="Yes";
     AGE05FL ="Y";
     output;
    end;
    if monotonic() = 10 then do;   
     AGE01FL ="Y";
     AGE02FL ="Y";
     AGE03FL ="Y";
     AGE04FL ="Yes";
     AGE05FL ="Y";
     output;
    end;
    if monotonic() = 11 then do;   
     AGE01FL ="Y";
     AGE02FL ="Y";
     AGE03FL ="Y";
     AGE04FL ="Yes";
     AGE05FL ="N";
     output;
    end;
    if monotonic() = 12 then do;   
     AGE01FL ="";
     AGE02FL ="";
     AGE03FL ="N";
     AGE04FL ="No";
     AGE05FL ="N";
     output;
    end;
  end;
end;
run;
/*Test dataset*/
data t_derive_var_merged_exist_flag;
do SEX ="F","M";
  do AGE= 12 to 17;
    output;
  end;
end;
run;

/*Output dataset*/
data o_derive_var_merged_exist_flag;
 set t_derive_var_merged_exist_flag;
 /*key=AGE*/
 %derive_var_merged_exist_flag(dataset_add=SASHELP.CLASS,by_vars=AGE, new_var=AGE01FL);
 /*key=AGE & SEX*/
 %derive_var_merged_exist_flag(dataset_add=SASHELP.CLASS,by_vars=AGE SEX, new_var=AGE02FL);
 /*key=AGE , type=YN*/
 %derive_var_merged_exist_flag(dataset_add=SASHELP.CLASS,by_vars=AGE, new_var=AGE03FL,false_value=N);
 /*key=AGE , type=Yes/No*/
 %derive_var_merged_exist_flag(dataset_add=SASHELP.CLASS,by_vars=AGE, new_var=AGE04FL,true_value=Yes,false_value=No);
 /*key=AGE , conditon:SEX=F*/
 %derive_var_merged_exist_flag(dataset_add=SASHELP.CLASS,by_vars=AGE, condition=%nrbquote(SEX="F"),new_var=AGE05FL,true_value=Y,false_value=N);
run;

/*Compare*/
%mp_assertdataset(
  base=e_derive_var_merged_exist_flag,					/* parameter in proc compare */
  compare=o_derive_var_merged_exist_flag,				/* parameter in proc compare */
  desc=[mp_assertdataset] Compare expected and test results, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion=0,       		/* parameter in proc compare */
  method=absolute    /* parameter in proc compare */
);

/*delete temporary datasets*/
proc datasets ;
	delete e_derive_var_merged_exist_flag o_derive_var_merged_exist_flag t_derive_var_merged_exist_flag _out ;
run ; quit ;
