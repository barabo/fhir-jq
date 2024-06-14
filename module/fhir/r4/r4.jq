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
# A FHIR AllergyIntolerance with a reference to the fhir-jq config.
#
def FHIR_R4_AllergyIntolerance(config):
    FHIR_Resource("AllergyIntolerance"; config)

  # Convert the id to a number, or leave it as is.
  | if config.resource.tryNumericalId then
      .id |= (tonumber? // .)
    end

  # Inject the concept codings, if enabled.
  | if config.coding.concepts.value then
      .code |= injectConcepts
      .clinicalStatus |= injectConcepts
      .verificationStatus |= injectConcepts
    end
;


##
# A FHIR Encounter with a reference to the fhir-jq config.
#
def FHIR_R4_Encounter(config):
    FHIR_Resource("Encounter"; config)

  # Convert the id to a number, or leave it as is.
  | if config.resource.tryNumericalId then
      .id |= (tonumber? // .)
    end

  # Inject the concept codings, if enabled.
  | if config.coding.concepts.value then
      .type |= injectConcepts
    end
;


##
# A FHIR Practitioner with a reference to the fhir-jq config.
#
def FHIR_R4_Practitioner(config):
    FHIR_Resource("Practitioner"; config)

  # Convert the id to a number, or leave it as is.
  | .id |= (tonumber? // .)

  # Insert the NPI, if present.
  | .npi = (.identifier[0].value | tonumber? // .)

  # Combine the name parts into a full name.
  | .full_name = (.name[0] | "\(.prefix[0]) \(.given[0]) \(.family)")

  # Inject the concept_id for gender.
  | .gender_concept_id = if .gender = "male" then 8507 else 8532 end
;


##
# A FHIR Practitioner with a reference to the fhir-jq config.
#
def FHIR_R4_PractitionerRole(config):
    FHIR_Resource("PractitionerRole"; config)

  # Convert the id to a number, or leave it as is.
  | .id |= (tonumber? // .)

  # Inject concepts for the specialty and code.
  | .code |= injectConcepts
  | .specialty |= injectConcepts

  # Dereference any useful ids.
  | .location_ids = [.location[] | dereference]
  | .organizaton_id = (.organization | dereference)
  | .practitioner_id = (.practitioner | dereference)
;


# 0-arity aliases to inject the fhir-jq config.
def FHIR_R4_AllergyIntolerance: FHIR_R4_AllergyIntolerance($cfg[0]);
def FHIR_R4_Encounter: FHIR_R4_Encounter($cfg[0]);
def FHIR_R4_Practitioner: FHIR_R4_Practitioner($cfg[0]);
def FHIR_R4_PractitionerRole: FHIR_R4_PractitionerRole($cfg[0]);


# Aliases to allow not specifying the revision for each Resource type.
def AllergyIntolerance: FHIR_R4_AllergyIntolerance;
def Encounter: FHIR_R4_Encounter;
def Practitioner: FHIR_R4_Practitioner;
def Practitioner: FHIR_R4_PractitionerRole;
