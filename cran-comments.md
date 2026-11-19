## Update

This is an update of openlineage, from 0.1.0 to 0.2.0. It adds column-level
lineage and a `close()` method, fixes number and time serialization, and
hardens the HTTP transport. Some invalid inputs that 0.1.0 accepted are now
errors; `NEWS.md` lists them.

## Test environments

`R CMD check --as-cran` on GitHub Actions (pedrobtz/r-actions):

- ubuntu-latest, R release
- ubuntu-latest, R oldrel-1
- macos-latest, R release
- windows-latest, R release
- windows-latest, R devel

## R CMD check results

0 errors | 0 warnings | 0 notes

## Reverse dependencies

There are no reverse dependencies on CRAN.

Locally, `R CMD check --as-cran` with the remote CRAN incoming checks on
macOS (aarch64), R 4.6.2: Status OK.

## Additional notes

- Tests, examples, and vignettes run fully offline. HTTP behavior is tested
  with mocked responses and does not contact an OpenLineage server.
- The package implements the public OpenLineage specification; there are no
  published method references beyond the specification linked in DESCRIPTION.
