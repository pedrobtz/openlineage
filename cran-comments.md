## First submission

This is the first CRAN submission of openlineage.

## Test environments

- Local: macOS 26.5.1 (arm64), R 4.6.1

## R CMD check results

0 errors | 0 warnings | 1 note

- This is a new submission.

## Additional notes

- Tests, examples, and vignettes run fully offline. HTTP behavior is tested
  with mocked responses and does not contact an OpenLineage server.
- The package installs, loads, and serializes events in an isolated library
  without any packages from `Suggests` available.
- The package implements the public OpenLineage specification; there are no
  published method references beyond the specification linked in DESCRIPTION.
