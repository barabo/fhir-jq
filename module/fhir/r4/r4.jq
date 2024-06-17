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


# Include helper modules.
include "fhir/common";
include "terminology";


# Import data modules.
import "fhir/config" as $cfg;


##
# A FHIR AllergyIntolerance with a reference to the fhir-jq config.
#
def FHIR_R4_AllergyIntolerance(config):
    FHIR_Resource("AllergyIntolerance"; config)

  # Inject the concept codings, if enabled.
  | if config.coding.concepts.value then
      .code.coding |= map(.concept = concept)
    | .clinicalStatus.coding |= map(.concept = concept)
    | .verificationStatus.coding |= map(.concept = concept)
    end

  # Inject the patient ID.
  | .patient.id = (.patient | dereference)
;


##
# A FHIR Encounter with a reference to the fhir-jq config.
#
def FHIR_R4_Encounter(config):
    FHIR_Resource("Encounter"; config)

  # Inject the concept codings, if enabled.
  | if config.coding.concepts.value then
      .type |= injectConcepts
    end
;


##
# A FHIR Location with a reference to the fhir-jq config.
#
def FHIR_R4_Location(config):
    FHIR_Resource("Location"; config)
;


##
# A FHIR Organization with a reference to the fhir-jq config.
#
def FHIR_R4_Organization(config):
    FHIR_Resource("Organization"; config)
;


##
# A FHIR Practitioner with a reference to the fhir-jq config.
#
def FHIR_R4_Practitioner(config):
    FHIR_Resource("Practitioner"; config)

  # Insert the NPI, if present.
  | .npi = (.identifier[0].value | tonumber? // .)

  # Combine the name parts into a full name.
  | .full_name = (.name[0] | "\(.prefix[0]) \(.given[0]) \(.family)")

  # Inject the concept codings, if enabled.
  | if config.coding.concepts.value then
      .gender_concept_id = if .gender = "male" then 8507 else 8532 end
    end
;


##
# A FHIR PractitionerRole with a reference to the fhir-jq config.
#
def FHIR_R4_PractitionerRole(config):
    FHIR_Resource("PractitionerRole"; config)

  # Inject concepts for the specialty and code.
  | if config.coding.concepts.value then
      .code |= injectConcepts
    | .specialty |= injectConcepts
    end

  # Dereference any useful ids.
  | .location_ids = [.location[] | dereference]
  | .organizaton_id = (.organization | dereference)
  | .practitioner_id = (.practitioner | dereference)
;


# 0-arity aliases to inject the fhir-jq config.
def FHIR_R4_AllergyIntolerance: FHIR_R4_AllergyIntolerance($cfg[0]);
def FHIR_R4_Encounter: FHIR_R4_Encounter($cfg[0]);
def FHIR_R4_Location: FHIR_R4_Location($cfg[0]);
def FHIR_R4_Organization: FHIR_R4_Organization($cfg[0]);
def FHIR_R4_Practitioner: FHIR_R4_Practitioner($cfg[0]);
def FHIR_R4_PractitionerRole: FHIR_R4_PractitionerRole($cfg[0]);


# Aliases to allow not specifying the revision for each Resource type.
def AllergyIntolerance: FHIR_R4_AllergyIntolerance;
def Encounter: FHIR_R4_Encounter;
def Location: FHIR_R4_Location;
def Organization: FHIR_R4_Organization;
def Practitioner: FHIR_R4_Practitioner;
def Practitioner: FHIR_R4_PractitionerRole;
