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
