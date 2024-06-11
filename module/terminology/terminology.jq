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
import "loinc.org"       as $loinc            { search: "./code-system" };
import "snomed.info/sct" as $sct              { search: "./code-system" };
import "urn:ietf:bcp:47" as $urn_ietf_bcp_47  { search: "./code-system" };


##
# Maps a code system URI to the imported terminology cache.
#
def code_system:
{
# Here are some examples.  Uncomment these are you need them.
  "http://loinc.org":       $loinc            [],
  "http://snomed.info/sct": $sct              [],
  "urn:ietf:bcp:47":        $urn_ietf_bcp_47  []
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
    "ERROR: concept_code '\(.code)' not in '\(.system)' terminology file."
    | halt_error(42)
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
