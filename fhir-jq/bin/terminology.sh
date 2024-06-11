#!/bin/bash
#
# Update fhir-jq terminology module configuration and content.
#
# Examples:
#
#   * Add a new empty code-system.
#
#     terminology.sh code-system add http://example.info/codings
#
#   This creates ${FHIR_JQ}/terminology/code-system/example.info/codings.json
#
#
#   * Add new codes to a code-system.
#
#     terminology.sh concepts add http://example.info/codings 123 456 789
#
#   This selects the concept values from the terminology.db and adds entries
#   to ${FHIR_JQ}/terminology/code-system/example.info/codings.json for each.
#
#
#   * Add all 'vocabulary' concept-codes in terminology.db to a code-system.
#
#     terminology.sh vocabulary load-all EXAMPLE http://example.info/codings
#
#   This selects all records from concept table where vocabulary_id = EXAMPLE,
#   Adding them to the codes in example.info/codings.json.
#
#
# TODO:
#  * updating fhir-jq configuration options.
#


set -e
set -o pipefail
set -u


##
# Display usage.
#
function usage() {
  local this="$( basename "${1}" )"
cat <<USAGE
Usage: ${this} [options] [object] [command] [command-options]

Objects:
  code-system
  concepts
  config
  vocabulary

Commands:
  code-system add [code-system]:
    code-system: str, the "system" of a FHIR "coding" object.

  concepts add [code-system] [concept_codes]:
    code-system: str, the "system" of a FHIR "coding" object.
    concept_codes: list of [concept_code]
      concept_code: str, a concept_code that can be found in a terminology db.

  vocabulary load-all [vocabulary_id] [code-system]
    vocabulary_id: str, concept.vocabulary_id value found in a terminology db.
    code-system: str, the "system" of a FHIR "coding" object.

Options:
  --database terminology.db
    A database containing a 'concept' table for use with concept_codes.

USAGE
}


usage
