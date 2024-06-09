[//]: # ( COMMENT: URL references used in this README)
[Coherent]: https://doi.org/10.3390/electronics11081199
[demo project]: https://github.com/barabo/fhir-to-omop-demo
[installation notes]: https://github.com/jqlang/jq?tab=readme-ov-file#installation
[jq module]: https://github.com/jqlang/jq?tab=readme-ov-file#installation


# fhir-jq
A [jq module] to make it easier to work with FHIR resources in `jq`!

## Example

An example goes a long way.  Here's one that shows how you might extract
the data needed for an OMOPCDM `visit_occurrence` from a FHIR Encounter
resource.

As long as you have the module installed on the default `jq` module import
path, this should work.

```jq
cat Encounter.json | fhir-jq '

#
# Convert a FHIR R4 Encounter into an OMOPCDM 5.4 visit_occurrence record.
#
include "fhir";         # for: Encounter
include "fhir/common";  # for: primary_participant, reference_id

Encounter
| {
#   OMOPCDM visit_occurrence column   FHIR Encounter data mapping
    visit_occurrence_id:              .id | tonumber,
    person_id:                        .subject | reference_id,

    # OMOPCDM requires only Encounters having a concept_code in the
    # "Visit" domain be included in the visit_occurrence table.
    visit_concept_id: (
      .type[].coding[].concept
      | if .domain_id == "Visit" then
          .concept_id
         else
           # 'empty' is like a 'continue' statement in other
           # languages.  It causes this whole Encounter to not be
           # included in output.
           empty
         end
    ),

    visit_start_date:                .period.start,
    visit_start_datetime:            .period.start,
    visit_end_date:                  .period.end,
    visit_end_datetime:              .period.end,
    visit_type_concept_id:           32827,  # OMOP4976900 - EHR encounter record
    provider_id:                     primary_participant | .id,
    care_site_id:                    .serviceProvider | reference_id,

# The following are TODO, and can either be updated in later ETL, or mapped from
# available fields in the Encounter resource.
    visit_source_value:              null,
    visit_source_concept_id:         null,
    admitted_from_concept_id:        null,
    admitted_from_source_value:      null,
    discharged_to_concept_id:        null,
    discharged_to_source_value:      null,
    preceding_visit_occurrence_id:   null
  }
'
```

## Installation
<details><summary>Click to see installation details...</summary>

---
### Prerequisites
To use this `jq` module, you must first have `jq` installed.  Refer to the
source project for their [installation notes].

### Instructions
Instructions for 'Single User' and 'System Wide' are provided.

#### Single User
Place the contents of the `module` directory somewhere (anywhere) on your
system and define the following alias in your `.bashrc` (or `.zshrc`, or 
`.fishrc`, etc) file in your home directory.

As always, remember to source the file after you have made changes to it.

```bash
# The fhir-jq installation directory.
export FHIR_JQ="${HOME}/.jq/fhir"
mkdir -p "${FHIR_JQ}"

##
# fhir-jq is used just like jq, but it injects the path to the fhir-jq
# module when invoked.  All other `jq` args are passed along to jq.
#
function fhir-jq() {
  jq -L "${FHIR_JQ}" "${@}"
}
```

From the directory where you downloaded the sources, copy the module files
into the destination directory:

```bash
cp -a "./module/fhir/*" "${FHIR_JQ}/"
```

| Tip |
| --- |
| If you set `FHIR_JQ="~/.jq/fhir"` and copy the module there, `jq` should be able to discover the it automatically, since `~/.jq` is included in the default module search path.  This means you won't need to use the `fhir-jq` shell function to `include` the module in your `jq` filters. |

| Warning(s) |
| ---------- |
| This module is still in _very early_ development **and is subject to change**. |
| If you already have custom logic in a `~/.jq` **file** (_not a directory_), you will have to put `fhir-jq` into a folder and use the `fhir-jq` shell function. |

#### System Wide

The default `jq` module search path is defined as:

```json
["~/.jq", "$ORIGIN/../lib/jq", "$ORIGIN/../lib"]
```
_Note: in this example, `${ORIGIN}` refers to the directory where `jq` is
installed.  Check `which jq` to see where that might be._

If you can place the `module` contents into any of these directories, `jq`
should be able to use the custom `fhir-jq` module functions without you
having to specify the `-L` flag when you invoke `jq`.

</details>

## Contributing
<details><summary>Click to see contribution details...</summary>

---
### Feedback
Thank you for giving this module a try - contributions are welcome!

#### Bugs
If you have found a bug, please submit an issue with the output of the
following command.

```bash
cat <<BUG_REPORT
<pre>
  uname -v: '$( uname -v )'
     SHELL: '${SHELL}'
  which jq: '$( which jq )'
     jq -V: '$( jq -V )'
   FHIR_JQ: '${FHIR_JQ}'
</pre>
BUG_REPORT
```

#### Submitting Issues
If you would like to request a feature to be implemented, please check the
existing issues before making a new request.

I am currently focusing on implementing functions to support working with
FHIR R4 input, but I welcome ideas about how to support other FHIR releases.

#### Submitting Pull Requests
Please fork this repository and create your pull request against the main
branch.  If there is an open issue that is addressed by your PR, please link
it in your PR.

### Prerequisites
There are no extra required packages or tools to be able to contribute to this project as `jq` has no installation dependencies!

### Project Layout
This section provides an overview of the project directory layout.  More
details may be found within `README.md` documents within each directory.

#### `module/`
The `module` directory contains all the files that are installed onto a users
system.

So, you can set your `${FHIR_JQ}` environment variable to resolve to a
`module` directory within a clone of this repo.  Then, by switching `git`
branches in your repo, you can test changes to the module dynamically.

```bash
# Example: cloning this repo into ~/code/fhir-jq/
mkdir -p ~/code/
cd ~/code/

# Clone via gh (or ssh / https, whatever works for you)
gh repo clone barabo/fhir-jq

# Update the env-var you specified in your shell .rc file.
export FHIR_JQ="~/code/fhir-jq/module"
```


#### `tests/`
`jq` natively supports running a series of simple tests which are read from
a file, which is passed to the `--run-tests` flag.  This module uses that
mechanism to test the provided code, so new features should include tests,
too.

```bash
./tests/run-all.sh
```

</details>

## Background
<details><summary>Click to read the origin story...</summary>

---

I was working on a [demo project] to convert FHIR resources formatted in
`.ndjson` from FHIR `R4` to an OMOPCDM tabular format.  I discovered the power
and flexibility of `jq` filters, and began writing lots of very
similar-looking and complex filter expressions to correctly select fields from
FHIR resources.  Then I discovered that `jq` supports custom functions, and
even loadable modules.  I started refactoring, and decided to move the logic
into a separate repo, since I think this part can stand on its own merit.

</details>

## Citations
<details><summary>Click to see citations...</summary>

---
### MITRE Health

This repo includes example FHIR resources that have been taken from the MITRE
Health [Coherent] data set, and should be cited according to their wishes.

🎉 Thank you, MITRE Health! 😘

If you download and use their data, remember to cite them!

```citation
Walonoski J, Hall D, Bates KM, Farris MH, Dagher J, Downs ME, Sivek RT,
Wellner B, Gregorowicz A, Hadley M, Campion FX, Levine L, Wacome K,
Emmer G, Kemmer A, Malik M, Hughes J, Granger E, Russell S.

The “Coherent Data Set”: Combining Patient Data and Imaging in a
Comprehensive, Synthetic Health Record.

Electronics. 2022; 11(8):1199.
```

https://doi.org/10.3390/electronics11081199

</details>
