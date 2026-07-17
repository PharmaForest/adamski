# 🛸{adamski} and 🦋{admiral}

{adamski} is under development to support ADaM creation.
Let's build the spaceship {adamski} together! 🛰️

Inspired by {admiral} package in R, adamski aims to bring similar functionality — along with original functions and macros — to the SAS environment.

We are looking for collaborators and contributors to join us on this exciting journey.
If you’re passionate about ADaM programming or want to help shape tools for the clinical data community, we’d love to have you onboard! 🚀

---

# 🦋{admiral} Functions List

This list summarizes derivation-related functions available in the R `{admiral}` package, based on the official **cran-release** reference checked on **2026-07-17**.  
These functions serve as a reference for creating equivalent SAS macros in the **adamski** package family.

---

## 🗂️ Summary by Category

| Category | # Functions |
|---------------------|-------------|
| All ADaMs (General) | 20 |
| ADSL-specific | 4 |
| BDS-specific | 11 |
| OCCDS-specific | 4 |
| Adding Parameters / Records | 19 |
| **Core Derivation-related Total** | **58** |
| Deprecated (all function types) | 9 |
| Experimental (all function types) | 2 |

---

## 🌐 All ADaMs (General) Status (🔧In construction / ✅ Completed!)

| Function | Description | Development in Adamski |
|-----------|-------------|-------------|
| `derive_var_extreme_flag()` | Create extreme value flag | 🔧In construction |
| `derive_var_joined_exist_flag()` | Create flag for joined existence |  |
| `derive_var_merged_ef_msrc()` | Merge and derive event flag by source |  |
| `derive_var_merged_exist_flag()` | Merge and derive existence flag | ✅ Completed! |
| `derive_var_obs_number()` | Derive observation sequence number | ✅ Completed! |
| `derive_var_relative_flag()` | Derive relative flag | 🔧In construction |
| `derive_var_trtdurd()` | Derive treatment duration (days) | 🔧In construction |
| `derive_vars_cat()` | Derive categorical variables | ✅ Completed! |
| `derive_vars_computed()` | Compute derived variables |  |
| `derive_vars_dt()` | Derive date components |  |
| `derive_vars_dtm()` | Derive datetime variables |  |
| `derive_vars_dtm_to_dt()` | Convert datetime to date |  |
| `derive_vars_dtm_to_tm()` | Convert datetime to time |  |
| `derive_vars_duration()` | Derive duration variables | ✅ Completed! |
| `derive_vars_dy()` | Derive study day variables | ✅ Completed! |
| `derive_vars_joined()` | Derive joined variables | ✅ Completed! |
| `derive_vars_joined_summary()` | Derive joined variables with summary logic |  |
| `derive_vars_merged()` | Derive merged variables |  |
| `derive_vars_merged_lookup()` | Lookup and merge derived variables |  |
| `derive_vars_transposed()` | Derive transposed variables |  |

---

## 🧍 ADSL-specific

| Function | Description | Development in Adamski |
|-----------|-------------|-------------|
| `derive_var_age_years()` | Derive age in years | ✅ Completed! |
| `derive_vars_aage()` | Derive analysis age | ✅ Completed! |
| `derive_vars_extreme_event()` | Derive worst/best extreme event |  |
| `derive_vars_period()` | Derive period or phase variables |  |

---

## 📊 BDS-specific

| Function | Description | Development in Adamski |
|-----------|-------------|-------------|
| `derive_var_analysis_ratio()` | Derive analysis ratios | 🔧In construction |
| `derive_var_anrind()` | Derive reference range indicator |  |
| `derive_var_atoxgr()` | Derive adverse event toxicity grade |  |
| `derive_var_atoxgr_dir()` | Derive directional adverse event toxicity grade |  |
| `derive_var_base()` | Derive baseline values | ✅ Completed! |
| `derive_var_chg()` | Derive change from baseline | ✅ Completed! |
| `derive_var_nfrlt()` | Derive normal/reference result indicator |  |
| `derive_var_ontrtfl()` | Derive on-treatment flag |  |
| `derive_var_pchg()` | Derive percent change | 🔧In construction |
| `derive_var_shift()` | Derive shift table variables |  |
| `derive_vars_crit_flag()` | Derive criteria flags |  |

---

## 🧾 OCCDS-specific

| Function | Description | Development in Adamski |
|-----------|-------------|-------------|
| `derive_var_trtemfl()` | Derive treatment-emergent flag |  |
| `derive_vars_atc()` | Derive ATC classification variables |  |
| `derive_vars_merged_summary()` | Merge and summarize derived variables |  |
| `derive_vars_query()` | Derive query-based variables (e.g., MedDRA) |  |

---

## ➕ Derivations for Adding Parameters / Records

| Function | Description | Development in Adamski |
|-----------|-------------|-------------|
| `default_qtc_paramcd()` | Default QTc parameter code |  |
| `derive_basetype_records()` | Create baseline type records | ✅ Completed! |
| `derive_expected_records()` | Derive expected record structure |  |
| `derive_extreme_event()` | Derive extreme events |  |
| `derive_extreme_records()` | Derive extreme records |  |
| `derive_locf_records()` | Last Observation Carried Forward (LOCF) | ✅ Completed! |
| `derive_param_bmi()` | Add BMI parameter |  |
| `derive_param_bsa()` | Add Body Surface Area parameter |  |
| `derive_param_computed()` | Add computed parameter |  |
| `derive_param_doseint()` | Add dose interval parameter |  |
| `derive_param_exist_flag()` | Add parameter for existence flag |  |
| `derive_param_exposure()` | Add exposure parameter |  |
| `derive_param_framingham()` | Add Framingham risk score parameter |  |
| `derive_param_map()` | Add parameter mapping |  |
| `derive_param_qtc()` | Add QTc parameter |  |
| `derive_param_rr()` | Add risk ratio parameter |  |
| `derive_param_tte()` | Add Time-to-Event parameter |  |
| `derive_param_wbc_abs()` | Add absolute WBC parameter |  |
| `derive_summary_records()` | Add summary records |  |

---

## ⚠️ Deprecated / Experimental Notes

| Function | Status | Note |
|-----------|--------|------|
| `call_user_fun()` | Deprecated | Deprecated in current reference. |
| `date_source()` | Deprecated | Deprecated in current reference. |
| `derive_param_extreme_record()` | Deprecated | Deprecated in current reference. |
| `derive_var_dthcaus()` | Deprecated | Deprecated in current reference. |
| `derive_var_extreme_dt()` | Deprecated | Deprecated in current reference. |
| `derive_var_extreme_dtm()` | Deprecated | Deprecated in current reference. |
| `derive_var_merged_summary()` | Deprecated | Use `derive_vars_merged_summary()` instead. |
| `dthcaus_source()` | Deprecated | Deprecated in current reference. |
| `get_summary_records()` | Deprecated | Deprecated in current reference. |
| `convert_xxtpt_to_hours()` | Experimental | Marked as experimental in current reference. |
| `derive_var_nfrlt()` | Experimental | Marked as experimental in current reference. |

---

## adamski original

| Function | Description | Development in Adamski |
|-----------|-------------|-------------|
| `coming soon` | special macro(or function) | |

---

## 📝 Usage Notes
- This list reflects `{admiral}` **cran-release** reference as checked on 2026-07-17.
- Scope is derivation-related functions from the official "Derivations for Adding Variables" and "Derivations for Adding Parameters/Records" sections, plus current deprecation/experimental notes.
- Additional advanced/utility functions like `call_derivation()` or `restrict_derivation()` are intentionally excluded from the core list.

---
## Acknowledgment
Adamski is inspired by the R `{admiral}` package and draws on some of their ideas and functions.

---

##  FAQ

**Q. When will adamski be finished?**  
**A.** adamski is always under construction 🏗️  
> Like a never-ending construction site — always improving, never truly "done".

**Q. How much are macros/functions in adamski consistent with functions in admiral?**  
**A.** In general, macros/functions in adamski are consistent with those in admiral in names and parameters. However, some differences would exist based on the differences between how we use macros/functions in SAS and how functions in admiral are used in R.

---

## 🔗 Reference
- [Admiral Official Documentation (cran-release)](https://pharmaverse.github.io/admiral/cran-release/reference/index.html)
- [Admiral GitHub Repository](https://github.com/pharmaverse/admiral)

---
