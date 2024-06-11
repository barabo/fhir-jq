#!/bin/bash
#
# Invokes jq with FHIR modules loaded.
#
# As jq runs, it may emit errors and debug messages to stderr.  This script
# monitors the stderr output stream and reacts when certain messages are seen.
#
# If configured, this script can detect when unknown terminology codes are
# seen while processing input and automatically include them in the loadable
# data modules to handle terminology.  This behavior requires access to a
# terminology database so the concept records can be transformed into a format
# that this jq module can use.
#
# TODO: integrate with the new terminology.sh
#

set -e
set -o pipefail
set -u


TERMINOLOGY_DB="${FHIR_JQ}/terminology/concepts.db"
export FHIR_JQ_LOG="${FHIR_JQ}/terminology/logs"
mkdir -p "${FHIR_JQ_LOG}"


##
# Reads stderr looking for errors about missing codes.
#
function missing-code-reader() {
  cat \
  | grep -a "ERROR: concept_code .* not in .* terminology file" \
  | awk '{ print $3, $6 }' \
  | tr -d "'"
}


##
# Reads stderr looking for errors about missing code systems.
#
function missing-code-system-reader() {
  cat \
  | grep -a "ERROR: not a known code-system: .*" \
  | awk '{ print $6 }' \
  | tr -d "'" \
  | while read -r system; do
      local code_system="${system##*//}"
      local term_dir="${FHIR_JQ}/terminology"
      local data_file="${term_dir}/code-system/${code_system}.json"
      local cs_dir="$( dirname "${data_file}" )"
      local var_name="\$$( basename "${code_system}" )"

      # Create the empty data module.
      mkdir -p "${cs_dir}"
      echo '{}' > "${data_file}"

      # TODO: invoke fhir-jq --add-terminology code-system (or something)

      # Display instructions for inserting terminology.
      cat <<EOM

\\0/
 Y
/ \\
Detected a missing terminology:
  FHIR coding.system: "${system}"
  terminology/code-system: ${code_system}
  data: ${data_file}

In ${term_dir}/terminology.js
you must import this terminology module for the data to be useable.

Add the following to the import list:
  import "${code_system}" as ${var_name} { search: "./code-system" };

And include a reference to the data in the "code_system" filter:

  def code_system:
  {
    "${system}":   ${var_name}    [],
  ...
  };

EOM
    done
}


# Export functions that are needed by the stderr readers.
export -f missing-code-reader
export -f missing-code-system-reader


##
# Reads concept_codes piped to the function and uses that to query the
# terminology database, producing a json-encoded list of concept table
# entries for the input concept_codes.
#
# Ex: echo 123 456 | get_missing_concepts
# => [
#      {"concept_code": "123", "concept_id": 345},
#      {"concept_code": "456", "concept_id": 789}
#    ]
#
function get_missing_concepts() {
  sqlite3 "${TERMINOLOGY_DB}" <<SQL
.mode json
SELECT
  *
FROM
  concept
WHERE
  concept_code IN (
    '$(cut -d' ' -f1 | xargs | sed -e "s: :', ':g" )'
  )
;
SQL
}


##
# Transforms a list of concept objects into a dictionary where the
# concept_code is used to map to the concept object.
#
# Ex: [{"concept_code": "123", "concept_id": 345}]
#  => {"123": {"concept_code": "123", "concept_id": 345}}
#
function format_for_data_module() {
  jq '
    to_entries
    | map_values(.key = .value.concept_code)
    | from_entries
  '
}


##
# Execute jq with FHIR modules loaded.
#
function fhir-jq() {
  local logdir="${FHIR_JQ_LOG}"
  local code_log="${logdir}/missing-code-reader.log"
  local system_log="${logdir}/missing-code-system-reader.log"

  # Clear logs from previous runs.
  rm -f "${code_log}" "${system_log}"

  # Start jq with stderr stream readers.
  2> >(missing-code-system-reader | tee -a "${system_log}" >&2) \
  2> >(missing-code-reader | tee -a "${code_log}" >&2) \
  jq -L "${FHIR_JQ}" "${@}"
  local rc=${?}

  # Prompt the user to insert missing code systems.
  if [ ! -s "${system_log}" ]; then
    rm -f "${system_log}"
  else
    echo "Missing code systems.  Add them to the terminology module!"
    # TODO: terminology.sh --add code-system
  fi

  # Nothing to do if no missing codes were found.
  if [ ! -s "${code_log}" ]; then
    rm -f "${code_log}"
    return ${rc}
  fi

  # Get the distinct, unknown concept systems from each logged code.
  cut -d' ' -f2 "${code_log}" | sort -u | \
  while read system; do
    local code_system="${system##*//}"
    local term_dir="${FHIR_JQ}/terminology"
    local data_file="${term_dir}/code-system/${code_system}.json"
    local temp="${data_file}.tmp"

    # Count the new concepts for this system.
    local new_concept_count=$(
      grep " ${system}$" "${code_log}" | sort -u | wc -l | awk '{print $1}'
    )

    echo "Adding ${new_concept_count} new ${system} concepts!"

    # Create the un-slurped, updated, data module.
    cp "${data_file}" "${temp}"
    grep " ${system}$" "${code_log}" \
      | get_missing_concepts \
      | format_for_data_module \
      >> "${temp}"

    # Slurp the data module!
    jq --slurp 'add' "${temp}" > "${data_file}"
  done

  return ${rc}
}


fhir-jq "${@:-}"
