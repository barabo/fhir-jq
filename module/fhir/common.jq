#
#  0> - A jq module containing common filters and helpers for various other
# <y    modules.
# / >
module {
  name: "fhir/common",
  desc: "Provides common functionality to all included jq fhir modules.",
  repo: "https://github.com/barabo/fhir-jq",
  file: "module/fhir/common.jq"
};


##
# A base filter for all FHIR Resource filters.
#
def FHIR_Resource(type; config):
  # TODO: sanity-check config
  if .resourceType != type then
    "ERROR: \( $__loc__ ): type \(type) <> resourceType = '\(.resourceType)'\n"
    | halt_error(1)
  end
;


##
# Returns a numerical reference id.
#
def dereference:
  .reference
    | split("/").[1]
    | tonumber
;

##
# Returns a numerical subject.reference id.
#
def subject_id: .subject | dereference;
