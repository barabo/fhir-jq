[//]: # ( COMMENT: URL references used in this README)
[Coherent]: https://doi.org/10.3390/electronics11081199
[demo project]: https://github.com/barabo/fhir-to-omop-demo
[exercism]: https://exercism.org/tracks/jq
[installation notes]: https://github.com/jqlang/jq?tab=readme-ov-file#installation
[jq module]: https://github.com/jqlang/jq?tab=readme-ov-file#installation
[SNOMED CT Editions]: https://confluence.ihtsdotools.org/display/DOCEXTPG/4.4.2+Edition+URI+Examples
[Using SNOMED CT]: https://terminology.hl7.org/SNOMEDCT.html

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
include "fhir/common";  # for: dereference


##
# Returns the dereferenced id of the primary performer.
#
def primary_performer_id:
  .participant[]
  | select(.type[].coding[].code == "PPRF")
  | .individual
  | dereference
;


##
# OMOPCDM requires only Encounters having a concept_code in the "Visit"
# domain be included in the visit_occurrence table.
#
def visit_coding:
  .type[].coding[] |
  if .concept.domain_id != "Visit" then
    # 'empty' is like a 'continue' statement in other languages.  It
    # causes this whole Encounter to not be included in output.
    empty
  end
;


# An alias for the concept of a qualifying Visit coding.
def visit: visit_coding.concept;
#
# NOTE: the helper functions above could probably be refactored into
#       a separate omopcdm jq module if they are useful elsewhere.
#


Encounter
| {
#   OMOPCDM visit_occurrence column   FHIR Encounter data mapping
    visit_occurrence_id:              .id | tonumber,
    person_id:                        .subject | dereference,
    visit_concept_id:                 visit.concept_id,
    visit_start_date:                 .period.start,
    visit_start_datetime:             .period.start,
    visit_end_date:                   .period.end,
    visit_end_datetime:               .period.end,
    visit_type_concept_id:            32827,  # OMOP4976900 - EHR encounter record
    provider_id:                      primary_performer_id,
    care_site_id:                     .serviceProvider | dereference,

# The SNOMED (or whatever terminology code system) code and concept_id.
# This can be used to review the appropriateness of the mapping later.
    visit_source_value:               visit_coding.code,
    visit_source_concept_id:          visit_coding.source.concept_id,

# The following are TODO, and can either be updated in later ETL, or mapped from
# available fields in the Encounter resource.  These are not required columns.
    admitted_from_concept_id:         null,
    admitted_from_source_value:       null,
    discharged_to_concept_id:         null,
    discharged_to_source_value:       null,
    preceding_visit_occurrence_id:    null
  }
'
```

<details><summary>Click to see the contents of the input Encounter...</summary>

```json
{
  "resourceType": "Encounter",
  "id": "4218",
  "meta": {
    "versionId": "1",
    "lastUpdated": "2024-06-01T20:19:17.304+00:00",
    "source": "#8IRCgpLiSxJLv3VD",
    "profile": [
      "http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter"
    ]
  },
  "identifier": [
    {
      "use": "official",
      "system": "https://github.com/synthetichealth/synthea",
      "value": "fe6a5bc3-6637-e625-daff-07fbd65c6b81"
    }
  ],
  "status": "finished",
  "class": {
    "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
    "code": "AMB"
  },
  "type": [
    {
      "coding": [
        {
          "system": "http://snomed.info/sct",
          "code": "185349003",
          "display": "Encounter for check up (procedure)"
        }
      ],
      "text": "Encounter for check up (procedure)"
    }
  ],
  "subject": {
    "reference": "Patient/4217",
    "display": "Mr. Humberto482 Koss676"
  },
  "participant": [
    {
      "type": [
        {
          "coding": [
            {
              "system": "http://terminology.hl7.org/CodeSystem/v3-ParticipationType",
              "code": "PPRF",
              "display": "primary performer"
            }
          ],
          "text": "primary performer"
        }
      ],
      "period": {
        "start": "1959-02-22T06:37:53-05:00",
        "end": "1959-02-22T06:52:53-05:00"
      },
      "individual": {
        "reference": "Practitioner/2187",
        "display": "Dr. Douglass930 Windler79"
      }
    }
  ],
  "period": {
    "start": "1959-02-22T06:37:53-05:00",
    "end": "1959-02-22T06:52:53-05:00"
  },
  "location": [
    {
      "location": {
        "reference": "Location/54",
        "display": "MERCY MEDICAL CTR"
      }
    }
  ],
  "serviceProvider": {
    "reference": "Organization/53",
    "display": "MERCY MEDICAL CTR"
  }
}
```

<details><summary>Click to see the expected results...</summary>

---
This is the correct answer:
```json
```

Trick question!  Remember, this encounter did *not* qualify as a `Visit`, so we emitted
an `empty` and the entire record was skipped.

However, if we *invert* the criteria to *exclude* all visit encounters, it would result in
json that looks like this:

```json
{
  "visit_occurrence_id": 4218,
  "person_id": 4217,
  "visit_concept_id": 4085799,
  "visit_start_date": "1959-02-22T06:37:53-05:00",
  "visit_start_datetime": "1959-02-22T06:37:53-05:00",
  "visit_end_date": "1959-02-22T06:52:53-05:00",
  "visit_end_datetime": "1959-02-22T06:52:53-05:00",
  "visit_type_concept_id": 32827,
  "provider_id": 2187,
  "care_site_id": 53,
  "visit_source_value": "185349003",
  "visit_source_concept_id": null,
  "admitted_from_concept_id": null,
  "admitted_from_source_value": null,
  "discharged_to_concept_id": null,
  "discharged_to_source_value": null,
  "preceding_visit_occurrence_id": null
}
```

</details>

</details>

---
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
export PATH="${PATH}:${FHIR_JQ}/../fhir-jq/bin"
mkdir -p "${FHIR_JQ}"
```

From the directory where you downloaded the sources, copy the module files
into the destination directory:

```bash
cp -a ./module/* "${FHIR_JQ}/"
cp -a ./fhir-jq "${FHIR_JQ}/../"
```

| Tip |
|:--- |
| If you set `FHIR_JQ="${HOME}/.jq/fhir"` and copy the module there, `jq` should be able to discover it automatically, since `${HOME}/.jq` is included in the default module search path.  This means you won't need to use `fhir-jq` to `include` the module in your `jq` filters. |

| Warning(s) |
|:---------- |
| This module is still in _very early_ development **and is subject to sudden changes**. |
| If you already have custom logic in a `~/.jq` **file** (_not a directory_), you can put your `~/.jq` file into `~/.jq/jq.jq` (yep, really) and put `module/*` into `~/.jq/`. |

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

The recommended place for the scripts provided in `fhir-jq/bin` is `/usr/local/bin`.

</details>

## Terminology
<details><summary>Click to read about loading terminology...</summary>

---
This tool gives you the ability to inject code `concept` values into your documents
as they are being scanned by `jq`.  This can be useful if you need to then change the
way you handle documents based on the 'type' of codings they contain.  One example of
this is when translating FHIR to OMOP - in many cases the OMOP CDM requires that
data in certain tables be sourced only from qualifying encounters, observations,
measurements, etc.  To categorize the source data, the domain of the resource code 
can be used, which can be discovered from the code concept.

This tool does not include terminology sets, since many of them are proprietary or
require end user agreements that would be between yourself and the code set provider.

However, you are free to download terminology sets and make them available to this
tool using the helpers provided.

The main thing to know is that when `fhir-jq` encounters a terminology-coded code in
your source documents, it maps the code `"system"` value to a cached set of codes
which are prepared in advance by you (via the provided helper scripts).

The cached terminology data modules are to be stored in your module `terminology`
directory, under the `code-system` directory.  The URI of the code system determines
where to place the cached terminology set.

Note: Value systems are not yet supported, but will follow an analogous structure.

For example, the SNOMED code system uri `https://snomed.info/sct` maps to
`terminology/code-system/snomed.info/sct.json`.  If you wanted to use a specific
SNOMED CT code system such as `https://snomed.info/sct/900000000000207008/version/20130731`,
the codes for that system would be cached in
`terminology/code-system/snomed.info/sct/900000000000207008/version/20130731.json`.

Your cached codes must map the value of the coding `"code"` value to the code
concept values you want to inject into your document.

For example, if you wish to inject the concept for SNOMED code `1234` into an
`Encounter.type[].coding`, the `terminology/code-system/snomed.info/sct.json` file
must contain an entry such as:

```json
{
  "1234": {
    "concept_id": 4567,
    "concept_code": "1234"
  }
}
```

To enable this terminology data module, there must be a mapping in the 
`terminology/terminology.jq` module from the `"system"` value to the imported
data module.

```jq
# NOTE: Some example terminology system imports are as follows:
import "loinc.org"                       as $loinc           { search: "./code-system" };
import "nucc.org/provider-taxonomy"      as $nucc_p          { search: "./code-system" };
import "snomed.info/sct"                 as $sct             { search: "./code-system" };  # <---- IMPORTED DATA MODULE
import "urn:ietf:bcp:47"                 as $urn_ietf_bcp_47 { search: "./code-system" };
import "allergyintolerance-clinical"     as $hl7_cs_aic      { search: "./code-system/terminology.hl7.org/CodeSystem" };
import "allergyintolerance-verification" as $hl7_cs_aiv      { search: "./code-system/terminology.hl7.org/CodeSystem" };

##
# Maps a code system URI as found in a FHIR document to the imported
# terminology data module cache.
#
def code_system:
{
  "http://loinc.org":                                                      $loinc            [],
  "http://nucc.org/provider-taxonomy":                                     $nucc_p           [],
  "http://snomed.info/sct":                                                $sct              [],
# ^^^^^^^^^^^^^^^^^^^^^^^^ <---- MAPPED "system" URI to imported data module
  "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical":     $hl7_cs_aic       [],
  "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification": $hl7_cs_aiv       [],
  "urn:ietf:bcp:47":                                                       $urn_ietf_bcp_47  []
};
```

The `fhir-jq/bin/terminology.sh` helper script (which is a work in progress) is designed
to make it easy to add terminology systems to `fhir-jq` through a set of CLI commands, which
update the `terminology/terminology.jq` module.  Since this is still being built, you may
have to manually add your code systems to enable them.

The `terminology/terminology.jq` module provides some helper functions to
allow you to inject concepts more eaily.

In your own filters, you can use them like this:

```jq
include "fhir";
FHIR_Resource("Encounter")
| .type |= injectConcepts
```

The provided `fhir/r4` module already provides an `Encounter` helper which injects concepts for you,
but only if your `fhir/config` data module is configured to do so (the default is to inject concepts).

</details>

## Contributing
<details><summary>Click to see contribution details...</summary>

### Learning `jq`.

If this project excites you but you don't know `jq` - check out the `jq` [exercism] track.

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

#### `fhir-jq/`
The `fhir-jq/bin` directory contains the `fhir-jq.sh` script, and a `fhir-jq`
symlink that points to it.  So, you can substitute `fhir-jq.sh` wherever you
see `fhir-jq` in examples.

There is a new `terminology.sh` helper script here, too.  With that, you can
control the loaded terminology sets available to `fhir-jq`.

#### `module/`
The `module` directory contains all the files that `jq` needs.  `jq` will
ignore any files here that do not end with either `.json` or `.jq`, so the
presence of `.gitignore` files (or whatever) will not affect how `jq`
behaves.

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
export FHIR_JQ="${HOME}/code/fhir-jq/module"
```

#### `terminology/`
FHIR resources include coded terminology, which are used to categorize and
add context to resources.  In the top example in this README an `Encounter`
resource contains a SNOMED coding which looks like this.

```json
{
  "system": "http://snomed.info/sct",
  "code": "185349003",
  "display": "Encounter for check up (procedure)"
}
```

The terminology for the SNOMED code system is stored in `terminology/code-system/snomed.info/sct.json`
and contains an entry like this:

```json
{
...
  "185349003": {
    "concept_id": 4085799,
    "concept_name": "Encounter for check up",
    "domain_id": "Observation",
    "vocabulary_id": "SNOMED",
    "concept_class_id": "Procedure",
    "standard_concept": "S",
    "concept_code": "185349003",
    "valid_start_date": 20020131,
    "valid_end_date": 20991231,
    "invalid_reason": ""
  }
...
}
```

The `snomed.info/sct` submodule is imported into the `terminology` module in `terminology.jq` like this:

```jq
import "loinc.org"                  as $loinc            { search: "./code-system" };
import "nucc.org/provider-taxonomy" as $nucc_p           { search: "./code-system" };
import "snomed.info/sct"            as $sct              { search: "./code-system" };  # <----
import "urn:ietf:bcp:47"            as $urn_ietf_bcp_47  { search: "./code-system" };


##
# Maps a code system URI to the imported terminology cache.
#
def code_system:
{
# Here are some examples.  Uncomment these are you need them.
  "http://loinc.org":                  $loinc            [],
  "http://nucc.org/provider-taxonomy": $nucc_p           [],
  "http://snomed.info/sct":            $sct              [],  # <----
  "urn:ietf:bcp:47":                   $urn_ietf_bcp_47  []
};
```

This allows us to load any number of terminology code systems, and use any subset of the
codes that we want.  We do not need to load codes that we will never use!

<details><summary>Click for a deeper dive into how this works...</summary>

The logic injects the mapped code system objects into the document while it is processing
them.

```jq
##
# Returns the concept mapped to the current .code and .system,
# which has been cached in a data file imported by this module.
#
def concept:
  if .code == null then
    "ERROR: . has no 'code' key! . = \(.)\n"
    | halt_error(1)
  elif .system == null then
    "ERROR: . has no 'system' key! . = \(.)\n"
    | halt_error(1)
  elif code_system[.system] == null then
    "ERROR: not a known code-system: '\(.system)'\n"
    | halt_error(32)
  elif code_system[.system][.code] == null then
    debug("ERROR: concept_code '\(.code)' not in '\(.system)' terminology file.")
  else
    code_system[.system][.code]
  end
;


##
# Injects concepts into an array of objects with a system and code key.
#
def injectConcept:
  map(.concept = concept)
;


##
# Injects concepts into an array of objects with a coding array.
#
def injectConcepts:
  map(.coding |= injectConcept)
;
```

In other words, the transformed codable goes from this:

```json
{
  "system": "http://snomed.info/sct",
  "code": "185349003",
  "display": "Encounter for check up (procedure)"
}
```

to this:

```json
{
  "system": "http://snomed.info/sct",
  "code": "185349003",
  "display": "Encounter for check up (procedure)",
  "concept": {
    "concept_id": 4085799,
    "concept_name": "Encounter for check up",
    "domain_id": "Observation",
    "vocabulary_id": "SNOMED",
    "concept_class_id": "Procedure",
    "standard_concept": "S",
    "concept_code": "185349003",
    "valid_start_date": 20020131,
    "valid_end_date": 20991231,
    "invalid_reason": ""
  }
}
```

Having the concept included in the object allows us to categorize this
Encounter as an observation while it is being read.

</details>

---
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
