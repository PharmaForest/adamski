/*** HELP START ***//*

### Purpose:
- Create validation report using %create_report()

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/*Create report*/
%create_report(
  sourcelocation = C:\Temp\SAS_PACKAGES\packages\adamski,  /* for package information */
  reporter = Ryo Nakaya,

  general = %nrstr(
Adamski is a SAS package inspired by the R package {admiral}. It aims to bring the same flexible and modular ADaM derivation framework to the SAS environment.
The package follows the {admiral} design principles while adapting to SAS syntax and workflows. 
It enables consistent, reproducible ADaM dataset creation in compliance with CDISC standards. 
Adamski serves as a bridge between open-source R implementations and traditional SAS programming.
  ),  /* for general description of package */

  requirements = %nrstr(
- %derive_vars_dy :  ^{newline}
  Generates study day (DY) variables from given date variables using a specified reference date, for example TRTSDT. ^{newline}

- %derive_var_merged_exist_flag :  ^{newline}
  Creates a character flag variable indicating whether the current DATA step row`s keys exist in another dataset. ^{newline}

- %derive_var_age_years : ^{newline}
  Converts a set of age values from the specified time unit to years. ^{newline}

- %derive_vars_duration : ^{newline}
  Derives duration between two dates, specified by the variables present in the input dataset, for example duration of adverse events, relative day, age, etc..  ^{newline}
  ),

  results = TEMP.adamski_test, /* validation results dataset */
  additional = %nrstr(
	NA
  ),  /* Any additional information */
  references = %nrstr(
	https://github.com/PharmaForest/adamski ^n
	https://github.com/PharmaForest/adamski/blob/main/Adamski_and_Admiral.md
  ),  /* reference information */
  outfilelocation = C:\Temp\SAS_PACKAGES\packages\adamski\validation  /* location for output RTF */
) ;
