#
# REPO: https://github.com/barabo/fhir-jq
# FILE: module/fhir/r4/r4.jq
#
module {
  name: "fhir/r4",
  desc: "Provides a collection of helpers for R4 Resource types.",
  repo: "https://github.com/barabo/fhir-jq",
  file: "module/fhir/r4/r4.jq"
};


include "fhir/common";
include "terminology";

import "fhir/config" as $cfg;


##
# A FHIR Encounter with a reference to the fhir-jq config.
#
def FHIR_R4_Encounter(config):
    FHIR_Resource("Encounter"; config)

  # Convert the id to a number, or leave it as is.
  | if config.resource.tryNumericalId then
      .id |= (tonumber? // .)
    end

  # Inject the concept for the type codings, if enabled.
  | if config.coding.concepts.value then
      .type |= injectConcepts
    end
;


# 0-arity aliases to inject the fhir-jq config.
def FHIR_R4_Encounter: FHIR_R4_Encounter($cfg[0]);


# Aliases to allow not specifying the revision for each Resource type.
def Encounter: FHIR_R4_Encounter;
