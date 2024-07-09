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


# Include helper module to inject concepts into code system objects.
include "terminology";


##
# A base filter for all FHIR Resource filters.
#
def FHIR_Resource(fhir_type; config):
  # TODO: sanity-check config
  if .resourceType != fhir_type then
    "ERROR: \( $__loc__ ): fhir_type \(fhir_type) <> resourceType = '\(.resourceType)'\n"
    | halt_error(1)
  end

  # If there's an id and it should be numeric, try to convert it.
  | if config.resource.tryNumericalId then
      .id |= (tonumber? // .)
    end

  # Inject codes into the resource, if configured to do so.
  | if config.coding.concepts.value then
      walk(
        if type == "object" and has("code") and has("system") then
          .concept = concept
        end
      )
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
