#
#  0/ - A jq module helper for fhir-jq to make it easy to convert healthcare
# <Y    terminology into concepts.
# / \
module {
  name: "terminology",
  desc: "A jq module for using healthcare terminology code systems.",
  repo: "https://github.org/barabo/fhir-jq",
  file: "module/terminology/terminology.jq"
};


#
# NOTE: This module would need to import all the known code systems, which is
# not ideal, but I haven't thought of a better way yet.
#
# NOTE: Some example terminology system imports are as follows:
import "loinc.org"                       as $loinc           { search: "./code-system" };
import "nucc.org/provider-taxonomy"      as $nucc_p          { search: "./code-system" };
import "snomed.info/sct"                 as $sct             { search: "./code-system" };
import "urn:ietf:bcp:47"                 as $urn_ietf_bcp_47 { search: "./code-system" };
import "allergyintolerance-clinical"     as $hl7_cs_aic      { search: "./code-system/terminology.hl7.org/CodeSystem" };
import "allergyintolerance-verification" as $hl7_cs_aiv      { search: "./code-system/terminology.hl7.org/CodeSystem" };


##
# Maps a code system URI as found in a FHIR document to the imported
# terminology data module cache.
#
def code_system:
{
# Here are some examples.  Uncomment these as you need them.
  "http://loinc.org":                                                      $loinc            [],
  "http://nucc.org/provider-taxonomy":                                     $nucc_p           [],
  "http://snomed.info/sct":                                                $sct              [],
  "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical":     $hl7_cs_aic       [],
  "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification": $hl7_cs_aiv       [],
  "urn:ietf:bcp:47":                                                       $urn_ietf_bcp_47  []
};


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
# For collecting missing codes, use debug, otherwise its fine to halt on error.
#    "ERROR: concept_code '\(.code)' not in '\(.system)' terminology file."
#    | halt_error(42)
# TODO: this should be configurable
    debug("ERROR: concept_code '\(.code)' not in '\(.system)' terminology file.")
    | {
        "unknown_concept_code": .code,
        "concept_id": null
      }
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
