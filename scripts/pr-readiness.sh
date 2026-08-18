#!/usr/bin/env bash
set -euo pipefail

toon_quote() {
  local LC_ALL=C
  local value="$1"
  local escaped='' char ord
  local index
  for ((index = 0; index < ${#value}; index++)); do
    char="${value:index:1}"
    case "$char" in
      '\\') escaped+='\\\\' ;;
      '"') escaped+='\\"' ;;
      $'\n') escaped+='\\n' ;;
      $'\r') escaped+='\\r' ;;
      $'\t') escaped+='\\t' ;;
      *)
        printf -v ord '%d' "'$char"
        if [ "$ord" -lt 32 ]; then
          printf -v char '\\u%04x' "$ord"
        fi
        escaped+="$char"
        ;;
    esac
  done
  printf '"%s"' "$escaped"
}

emit_error() {
  printf 'error: %s\n' "$(toon_quote "$1")"
  printf 'help: %s\n' "$(toon_quote "$2")"
  exit 2
}

print_help() {
  printf 'command: pr-readiness\n'
  printf 'description: Evaluate normalized PR readiness transitions\n'
  printf 'help[2]: %s,%s\n' \
    '"pr-readiness defaults"' \
    '"pr-readiness transition --help"'
}

print_defaults_help() {
  printf 'command: pr-readiness defaults\n'
  printf 'description: Show readiness timeout settings\n'
  printf 'defaults: timeout_seconds=1800 poll_seconds=30\n'
  printf 'usage: pr-readiness defaults\n'
}

print_transition_help() {
  printf 'command: pr-readiness transition\n'
  printf 'description: Apply one normalized readiness transition\n'
  printf 'arguments[8]: %s\n' \
    '"OUTCOME","CURRENT_SHA","OBSERVED_SHA","REPAIR_CYCLES","DEADLINE_EXPIRED","DETERMINISTIC_FAILURE","REQUIRED_CHECKS","EVIDENCE"'
  printf 'usage: pr-readiness transition pending abc abc 0 false false check,test pending\n'
}

validate_settings() {
  case "$timeout_seconds" in
    ''|*[!0-9]*) emit_error 'invalid PR_READINESS_TIMEOUT_SECONDS' 'pr-readiness defaults --help' ;;
  esac
  case "$poll_seconds" in
    ''|*[!0-9]*) emit_error 'invalid PR_READINESS_POLL_SECONDS' 'pr-readiness defaults --help' ;;
  esac
}

timeout_seconds="${PR_READINESS_TIMEOUT_SECONDS:-1800}"
poll_seconds="${PR_READINESS_POLL_SECONDS:-30}"

case "${1:-}" in
  ''|--help|-h)
    print_help
    ;;
  defaults)
    if [ "$#" -eq 2 ] && [ "$2" = --help ]; then
      print_defaults_help
      exit 0
    fi
    [ "$#" -eq 1 ] || emit_error 'unexpected argument for defaults' 'pr-readiness defaults --help'
    validate_settings
    printf 'timeout_seconds: %s\n' "$timeout_seconds"
    printf 'poll_seconds: %s\n' "$poll_seconds"
    ;;
  transition)
    if [ "$#" -eq 2 ] && [ "$2" = --help ]; then
      print_transition_help
      exit 0
    fi
    [ "$#" -eq 9 ] || emit_error 'wrong number of transition arguments' 'pr-readiness transition --help'
    validate_settings

    outcome="$2"
    current_sha="$3"
    observed_sha="$4"
    repair_cycles="$5"
    deadline_expired="$6"
    deterministic_failure="$7"
    required_checks="$8"
    evidence="$9"

    case "$repair_cycles" in
      ''|*[!0-9]*) emit_error 'invalid repair cycle count' 'pr-readiness transition --help' ;;
    esac
    case "$deadline_expired:$deterministic_failure" in
      true:true|true:false|false:true|false:false) ;;
      *) emit_error 'transition flags must be true or false' 'pr-readiness transition --help' ;;
    esac
    [ -n "$required_checks" ] || emit_error 'required checks are required' 'pr-readiness transition --help'
    [ -n "$evidence" ] || emit_error 'evidence is required' 'pr-readiness transition --help'
    [ -n "$current_sha" ] || emit_error 'current SHA is required' 'pr-readiness transition --help'
    [ -n "$observed_sha" ] || emit_error 'observed SHA is required' 'pr-readiness transition --help'
    if [ "$outcome" = success ] && [ "$required_checks" = none ]; then
      emit_error 'success requires at least one required check' 'pr-readiness transition --help'
    fi

    if [ "$current_sha" != "$observed_sha" ]; then
      decision=stale
    else
      case "$outcome" in
        pending)
          if [ "$deadline_expired" = true ]; then decision=timeout; else decision=pending; fi
          ;;
        success|cancelled|stale|timeout|configuration-gap)
          decision="$outcome"
          ;;
        failure)
          if [ "$deterministic_failure" = true ] && [ "$repair_cycles" -lt 2 ]; then
            decision=repair
          else
            decision=failure
          fi
          ;;
        *) emit_error "unknown normalized outcome: $outcome" 'pr-readiness transition --help' ;;
      esac
    fi
    printf 'decision: %s\n' "$decision"
    printf 'evidence: %s\n' "$(toon_quote "$evidence")"
    ;;
  *)
    emit_error "unknown command: ${1:-}" 'pr-readiness --help'
    ;;
esac
