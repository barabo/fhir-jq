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

  # Inject the patient ID.
  | .patient.id = (.patient | dereference)
;


##
# A FHIR Encounter with a reference to the fhir-jq config.
#
def FHIR_R4_Encounter(config):
    FHIR_Resource("Encounter"; config)

  | (.subject.id = (.subject | dereference))
  | (.participant |= map(.individual.id = (.individual | dereference)))
  | (.location |= map(.location.id = (.location | dereference)))
  | (.serviceProvider.id = (.serviceProvider | dereference))
;


##
# A FHIR Location with a reference to the fhir-jq config.
#
def FHIR_R4_Location(config):
    FHIR_Resource("Location"; config)
;


##
# A FHIR Medication with a reference to the fhir-jq config.
#
def FHIR_R4_Medication(config):
    FHIR_Resource("Medication"; config)
;


##
# A FHIR MedicationAdministration with a reference to the fhir-jq config.
#
def FHIR_R4_MedicationAdministration(config):
    FHIR_Resource("MedicationAdministration"; config)

  # Dereference IDs to numbers.
  | .subject.id = (.subject | dereference)
  | .context.id = (.context | dereference)
  | if has("reasonReference") then
      .reasonReference |= map(.id = dereference)
    end
;


##
# A FHIR MedicationRequest with a reference to the fhir-jq config.
#
def FHIR_R4_MedicationRequest(config):
    FHIR_Resource("MedicationRequest"; config)

  # Dereference IDs to numbers.
  | .subject.id = (.subject | dereference)
  | .encounter.id = (.encounter | dereference)
  | if has("medicationReference") then
      .medicationReference.id = (.medicationReference | dereference)
    end
  | if has("requester") then
      .requester.id = (.requester | dereference)
    end
  | if has("reasonReference") then
      .reasonReference |= map(.id = dereference)
    end
;

##
# A FHIR Observation with a reference to the fhir-jq config.
#
def FHIR_R4_Observation(config):
    FHIR_Resource("Observation"; config)

  # Dereference IDs to numbers.
  | .subject.id = (.subject | dereference)
  | .encounter.id = (.encounter | dereference)
;


##
# A FHIR Organization with a reference to the fhir-jq config.
#
def FHIR_R4_Organization(config):
    FHIR_Resource("Organization"; config)
;


##
# A FHIR Patient with a reference to the fhir-jq config.
#
def FHIR_R4_Patient(config):
    FHIR_Resource("Patient"; config)

  # Combine the name parts into a full name.
  | .full_name = (.name[0] | "\(.prefix[0]) \(.given[0]) \(.family)")

  # Inject the concept codings, if enabled.
  | if config.coding.concepts.value then
      .gender_concept_id = if has("gender") then
        if .gender == "male" then 8507 elif .gender == "female" then 8532 end
      end
    end
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
      .gender_concept_id = if has("gender") then
        if .gender == "male" then 8507 elif .gender == "female" then 8532 end
      end
    end
;


##
# A FHIR PractitionerRole with a reference to the fhir-jq config.
#
def FHIR_R4_PractitionerRole(config):
    FHIR_Resource("PractitionerRole"; config)

  # Dereference any useful ids.
  | .location_ids = [.location[] | dereference]
  | .organizaton_id = (.organization | dereference)
  | .practitioner_id = (.practitioner | dereference)
;


# 0-arity aliases to inject the fhir-jq config.
def FHIR_R4_AllergyIntolerance: FHIR_R4_AllergyIntolerance($cfg[0]);
def FHIR_R4_Encounter: FHIR_R4_Encounter($cfg[0]);
def FHIR_R4_Location: FHIR_R4_Location($cfg[0]);
def FHIR_R4_Medication: FHIR_R4_Medication($cfg[0]);
def FHIR_R4_MedicationAdministration: FHIR_R4_MedicationAdministration($cfg[0]);
def FHIR_R4_MedicationRequest: FHIR_R4_MedicationRequest($cfg[0]);
def FHIR_R4_Observation: FHIR_R4_Observation($cfg[0]);
def FHIR_R4_Organization: FHIR_R4_Organization($cfg[0]);
def FHIR_R4_Patient: FHIR_R4_Patient($cfg[0]);
def FHIR_R4_Practitioner: FHIR_R4_Practitioner($cfg[0]);
def FHIR_R4_PractitionerRole: FHIR_R4_PractitionerRole($cfg[0]);


# Aliases to allow not specifying the revision for each Resource type.
def AllergyIntolerance: FHIR_R4_AllergyIntolerance;
def Encounter: FHIR_R4_Encounter;
def Location: FHIR_R4_Location;
def Medication: FHIR_R4_Medication;
def MedicationAdministration: FHIR_R4_MedicationAdministration;
def MedicationRequest: FHIR_R4_MedicationRequest;
def Observation: FHIR_R4_Observation;
def Organization: FHIR_R4_Organization;
def Patient: FHIR_R4_Patient;
def Practitioner: FHIR_R4_Practitioner;
def PractitionerRole: FHIR_R4_PractitionerRole;
