/*** HELP START ***//*

### Purpose:
- Unit test for the %derive_var_merged_exist_flag() macro

*//*** HELP END ***/


%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp)

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

data CLASS;
length SEX $1. ;
set SASHELP.CLASS(drop=SEX);
SEX=choosec(_N_,
"M"
,"F"
,"F"
,"F"
,"M"
,"M"
,"F"
,"F"
,"M"
,"M"
,"F"
,"F"
,"F"
,"F"
,"M"
,"M"
,"M"
,"M"
,"M"
);
run;

/*Output dataset*/
data o_derive_var_merged_exist_flag;
 set t_derive_var_merged_exist_flag;
 /*key=AGE*/
 %derive_var_merged_exist_flag(dataset_add=CLASS,by_vars=AGE, new_var=AGE01FL);
 /*key=AGE & SEX*/
 %derive_var_merged_exist_flag(dataset_add=CLASS,by_vars=AGE SEX, new_var=AGE02FL);
 /*key=AGE , type=YN*/
 %derive_var_merged_exist_flag(dataset_add=CLASS,by_vars=AGE, new_var=AGE03FL,false_value=N);
 /*key=AGE , type=Yes/No*/
 %derive_var_merged_exist_flag(dataset_add=CLASS,by_vars=AGE, new_var=AGE04FL,true_value=Yes,false_value=No);
 /*key=AGE , conditon:SEX=F*/
 %derive_var_merged_exist_flag(dataset_add=CLASS,by_vars=AGE, condition=%nrbquote(SEX="F"),new_var=AGE05FL,true_value=Y,false_value=N);
run;

/*Compare*/
%mp_assertdataset(
  base=e_derive_var_merged_exist_flag,					/* parameter in proc compare */
  compare=o_derive_var_merged_exist_flag,				/* parameter in proc compare */
  desc=[mp_assertdataset]  (%nrstr(%derive_var_merged_exist_flag)) Compare expected and test results, 	/* description */
  id=,						/* parameter in proc compare(e.g. id=USUBJID) */
  by=,      	            /* parameter in proc compare(e.g. by=USUBJID VISIT) */
  criterion=0,       		/* parameter in proc compare */
  method=absolute,    /* parameter in proc compare */
  outds=TEMP.adamski_test
);
