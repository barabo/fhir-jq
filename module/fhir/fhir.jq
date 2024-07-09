#
#  0/ - A jq module for playing with FHIR!
# <Y  
# / \
module {
  name: "fhir",
  desc: "A module for working with FHIR Resources in jq.",
  repo: "https://github.com/barabo/fhir-jq",
  file: "module/fhir/fhir.jq"
};


#
# Import the fhir-jq config.
#
import "fhir/config" as $cfg;


#
# Specify a default revision of FHIR to work with.
#
include "fhir/r4";


###############################################################################
# Declare default versioned resource aliases.
#
# NOTE: These should all be from the same revision.
#
# Allows filters like: 'import "fhir"; Encounter'
###############################################################################
def AllergyIntolerance: FHIR_R4_AllergyIntolerance($cfg[0]);
def Encounter: FHIR_R4_Encounter($cfg[0]);
def Location: FHIR_R4_Location($cfg[0]);
def Medication: FHIR_R4_Medication($cfg[0]);
def MedicationAdministration: FHIR_R4_MedicationAdministration($cfg[0]);
def MedicationRequest: FHIR_R4_MedicationRequest($cfg[0]);
def Observation: FHIR_R4_Observation($cfg[0]);
def Organization: FHIR_R4_Organization($cfg[0]);
def Practitioner: FHIR_R4_Practitioner($cfg[0]);
def PractitionerRole: FHIR_R4_PractitionerRole($cfg[0]);
