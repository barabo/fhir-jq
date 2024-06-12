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
def Encounter: FHIR_R4_Encounter($cfg[0]);
def Practitioner: FHIR_R4_Practitioner($cfg[0]);
def PractitionerRole: FHIR_R4_PractitionerRole($cfg[0]);
