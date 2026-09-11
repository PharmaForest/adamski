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
- %derive_basetype_records() : ^{newline}
  Add `BASETYPE` variable to a dataset and duplicates records based upon the provided conditions. ^{newline}
^{newline}
- %derive_locf_records : ^{newline}
  Adds LOCF records (Last Observation Carried Forward) to a dataset based on an `expected observations` reference dataset. ^{newline}
^{newline}
- %derive_var_age_years : ^{newline}
  Converts a set of age values from the specified time unit to years. ^{newline}
^{newline}
- %derive_var_analysis_ratio() : ^{newline}
  Derives an analysis ratio variable for a BDS dataset using a numerator and denominator variable. ^{newline}
^{newline}
- %derive_var_base() : ^{newline}
  Derive baseline variables (e.g. BASE, BASEC, BNRIND) in a BDS dataset. ^{newline}
^{newline}
- %derive_var_chg() : ^{newline}
  Derive Change from Baseline (CHG) in a BDS-style dataset. ^{newline}
^{newline}
- %derive_var_extreme_flag() : ^{newline}
  Derives a flag for the first or last observation within each BY group based on the specified ORDER variables. ^{newline}
^{newline}
- %derive_var_merged_exist_flag : ^{newline}
  Creates a character flag variable indicating whether the current DATA step row`s keys exist in another dataset. ^{newline}
^{newline}
- %derive_var_obs_number() : ^{newline}
  Adds a sequence number variable to a dataset based on grouping keys and sort order. Useful for creating sequence numbers like `ASEQ`, `AESEQ`, or `CMSEQ`. ^{newline}
^{newline}
- %derive_var_pchg() : ^{newline}
  Derives Percent Change from Baseline (PCHG) in a BDS-style dataset. ^{newline}
^{newline}
- %derive_var_trtdurd() : ^{newline}
  Derives total treatment duration in days (`TRTDURD`) from treatment start and end dates using inclusive day counting. ^{newline}
^{newline}
- %derive_vars_aage() : ^{newline}
  Derives analysis age variables `AAGE` (numeric) and `AAGEU` (unit) from a start and end date/datetime. ^{newline}
^{newline}
- %derive_vars_cat() : ^{newline}
  Derive Categorization Variables Like `AVALCATy` and `AVALCAyN` ^{newline}
^{newline}
- %derive_vars_duration : ^{newline}
  Derives duration between two dates, specified by the variables present in the input dataset, for example duration of adverse events, relative day, age, etc.. ^{newline}
^{newline}
- %derive_vars_dy : ^{newline}
  Generates study day (DY) variables from given date variables using a specified reference date, for example TRTSDT. ^{newline}
^{newline}
- %derive_vars_joined() : ^{newline}
  Performs a hash-based lookup (left-join style) from the current DATA step row to an external dataset. ^{newline}

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
