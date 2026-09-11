Type : Package
Package : Adamski
Title : Adamski -- A SAS package of toolkit for CDISC ADaM creation
Version : 0.0.9
Author : [Yutaka Morioka],[Hiroki Yamanobe],[Ryo Nakaya],[Sharad Chhetri],[Manivannan Mathialagan],[Uma Balasubramanian]
Maintainer : PharmaForest
License : Apache license 2.0
Encoding : UTF8
Required : "Base SAS Software"
ReqPackages :  

DESCRIPTION START:

##  Adamski

**A SAS package of toolkit for CDISC ADaM creation**
Let's build the spaceship [adamski] together!
PharmaForest is looking for collaborators and contributors to join us on this exciting journey. If you're passionate
about ADaM programming or want to help shape tools for the clinical data community, we'd love to have you onboard! ?
Inspired by the {admiral} package in R, Adamski aims to bring similar functionality to the SAS environment, while introducing original functions and macros.
We strive to maintain consistency by keeping function (macro) and option names as close as possible to their R counterparts.
However, some differences are inevitable due to the distinct nature of SAS and R.
In addition, new functions and macros would be developed to extend the capabilities.
**Please see notice.sas in additional contents(addcnt) in addition to license.sas**

### Main Features
- %derive_basetype_records() : Add `BASETYPE` variable to a dataset and duplicates records based upon the provided conditions.  
- %derive_locf_records() : Add LOCF records (Last Observation Carried Forward) to a dataset based on an "expected observations" reference dataset  
- %derive_var_age_years() : Creates age variable with unit of year  
- %derive_var_analysis_ratio() : Derives an analysis ratio variable for a BDS dataset using a numerator and denominator variable.  
- %derive_var_base() : Derive baseline variables (e.g. BASE, BASEC, BNRIND) in a BDS dataset.  
- %derive_var_chg() : Derive Change from Baseline (CHG) in a BDS-style dataset.  
- %derive_var_extreme_flag() : Derives a flag for the first or last observation within each BY group based on the specified ORDER variables.  
- %derive_var_merged_exist_flag() :  Creates a character flag variable indicating whether the current DATA step row's key(s) exist in another dataset.  
- %derive_var_obs_number() : Adds a sequence number variable to a dataset based on grouping keys and sort order. Useful for creating sequence numbers like `ASEQ`, `AESEQ`, or `CMSEQ`.  
- %derive_var_pchg() : Derives Percent Change from Baseline (PCHG) in a BDS-style dataset.  
- %derive_var_trtdurd() : Derives total treatment duration in days (`TRTDURD`) from treatment start and end dates using inclusive day counting.  
- %derive_vars_aage() : Derives analysis age variables `AAGE` (numeric) and `AAGEU` (unit) from a start and end date/datetime.  
- %derive_vars_cat() : Derive Categorization Variables Like `AVALCATy` and `AVALCAyN`.  
- %derive_vars_duration() : Derives duration between two dates, specified by the variables present in the input dataset (e.g., duration of adverse events, relative day, age, etc.).  
- %derive_vars_dy() : Calculates DY variables.  
- %derive_vars_joined() : Performs a hash-based lookup (left-join style) from the current DATA step row to an external dataset.  

### Usage
For more details, please visit https://github.com/PharmaForest/adamski  

---

DESCRIPTION END:
