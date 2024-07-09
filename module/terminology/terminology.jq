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
import "id.loc.gov/vocabulary/iso639-1"       as $iso639_1          { search: "./code-system" };
import "loinc.org"                            as $loinc             { search: "./code-system" };
import "nucc.org/provider-taxonomy"           as $nucc_p            { search: "./code-system" };
import "www.nlm.nih.gov/research/umls/rxnorm" as $rxnorm            { search: "./code-system" };
import "snomed.info/sct"                      as $sct               { search: "./code-system" };
import "unitsofmeasure.org"                   as $units_of_measure  { search: "./code-system" };
import "urn:ietf:bcp:47"                      as $urn_ietf_bcp_47   { search: "./code-system" };
import "urn:oid:2.16.840.1.113883.6.238"      as $urn_oid_2_16_840  { search: "./code-system" };
import "allergyintolerance-clinical"          as $hl7_cs_aic        { search: "./code-system/terminology.hl7.org/CodeSystem" };
import "allergyintolerance-verification"      as $hl7_cs_aiv        { search: "./code-system/terminology.hl7.org/CodeSystem" };
import "dose-rate-type"                       as $hl7_cs_drt        { search: "./code-system/terminology.hl7.org/CodeSystem" };
import "observation-category"                 as $hl7_cs_oc         { search: "./code-system/terminology.hl7.org/CodeSystem" };
import "v2-0203"                              as $hl7_cs_v20203     { search: "./code-system/terminology.hl7.org/CodeSystem" };
import "v3-ActCode"                           as $hl7_cs_v3act      { search: "./code-system/terminology.hl7.org/CodeSystem" };
import "v3-MaritalStatus"                     as $hl7_cs_v3marital  { search: "./code-system/terminology.hl7.org/CodeSystem" };
import "v3-ParticipationType"                 as $hl7_cs_v3particip { search: "./code-system/terminology.hl7.org/CodeSystem" };

##
# Maps a code system URI as found in a FHIR document to the imported
# terminology data module cache.
#
def code_system:
{
# Here are some examples.  Uncomment these as you need them.
  "http://id.loc.gov/vocabulary/iso639-1":                                 $iso639_1          [],
  "http://loinc.org":                                                      $loinc             [],
  "http://nucc.org/provider-taxonomy":                                     $nucc_p            [],
  "http://snomed.info/sct":                                                $sct               [],
  "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical":     $hl7_cs_aic        [],
  "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification": $hl7_cs_aiv        [],
  "http://terminology.hl7.org/CodeSystem/dose-rate-type":                  $hl7_cs_drt        [],
  "http://terminology.hl7.org/CodeSystem/observation-category":            $hl7_cs_oc         [],
  "http://terminology.hl7.org/CodeSystem/v2-0203":                         $hl7_cs_v20203     [],
  "http://terminology.hl7.org/CodeSystem/v3-ActCode":                      $hl7_cs_v3act      [],
  "http://terminology.hl7.org/CodeSystem/v3-MaritalStatus":                $hl7_cs_v3marital  [],
  "http://terminology.hl7.org/CodeSystem/v3-ParticipationType":            $hl7_cs_v3particip [],
  "http://unitsofmeasure.org":                                             $units_of_measure  [],
  "http://www.nlm.nih.gov/research/umls/rxnorm":                           $rxnorm            [],
  "urn:ietf:bcp:47":                                                       $urn_ietf_bcp_47   [],
  "urn:oid:2.16.840.1.113883.6.238":                                       $urn_oid_2_16_840  []
};


##
# Returns the concept mapped to the current .code and .system,
# which has been cached in a data file imported by this module.
#
def concept:
  if .code == null then
    debug("ERROR: . has no 'code' key! . = \(.)\n")
    | {
        "error": "no code provided!"
      }
  elif .system == null then
    debug("ERROR: . has no 'system' key! . = \(.)\n")
    | {
        "error": "no system provided!"
      }
  elif code_system[.system] == null then
    debug("ERROR: not a known code-system: '\(.system)'\n")
    | {
        "error": "unknown code system!"
      }
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
