# macOS and Windows checks

[Run history](https://github.com/geowhk/ml-sas-r/actions/workflows/R-CMD-check.yaml)

GitHub Actions runs R CMD check on macOS and Windows with the current R release.
Checks include package installation, examples, regression tests (including two-worker
PSOCK execution), vignette rebuilding and PDF manual generation. Errors or warnings
fail the job; notes remain visible in the check report.

Changes pushed to main trigger both jobs. Documentation-only changes under docs/,
downloads/ or README.md do not trigger checks. Pull requests are checked as well.
To run manually, open the run history above, choose **Run workflow**, select main,
and confirm **Run workflow**. No Windows computer or local virtual machine is needed.

Open a completed run to inspect each operating system. Download its check artifact
for the complete logs. These hosted checks do not establish compatibility with every
R version or every Windows/macOS configuration, and do not constitute CRAN acceptance.

## Recorded runs

On 2026-10-02, [this run](https://github.com/geowhk/ml-sas-r/actions/runs/36951866766)
checked commit `9b0a283` with R 4.6.1 on macOS arm64 and Windows x64. Both
completed with **0 errors, 0 warnings and 0 notes**, including PDF manual checks.
The macOS job succeeded on retry after an external download returned HTTP 403.

For version 0.1.2, [run 38126951443](https://github.com/geowhk/ml-sas-r/actions/runs/38126951443)
passed on Windows. The macOS job stopped before R CMD check because TinyTeX's
package manager required `tlmgr update --self`. The workflow now updates that
manager before installing PDF fonts; the run history above records subsequent results.

## Publishing local check logs

`R-CMD-check.txt` preserves the local check results, with the machine-specific
log directory replaced by `<CHECK_DIR>`. Before publishing a new report, inspect
it for local user paths, temporary directories and credentials. This redaction
changes no check outcomes. Older Git commits can retain previously published paths.
