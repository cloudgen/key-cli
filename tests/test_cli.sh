# =============================================================================
# tests/test_cli.sh — CLI surface (local-only; no network)
# =============================================================================
# Primary REQs: requirement-shell-cli-interface, requirement-shell-cli-zero-arguments,
# requirement-shell-cli-default-interaction, requirement-shell-output-requirements,
# requirement-shell-cli-storage, requirement-domain-key
# TP family: TP-CLI-* · TP-KEY-*
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

run_test_cli() {
    t_header "CLI surface (TP-CLI)"

    require_cmd sh
    require_cmd grep

    sh -n "${SCRIPT}"
    assert_eq "TP-CLI-01 sh -n ship unit" 0 "$?"

    _out=$(sh "${SCRIPT}" version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-02 version exit 0" 0 "$_ec"
    assert_contains "TP-CLI-02 version mentions app" "$_out" "${APP_NAME}"
    assert_contains "TP-CLI-02 version mentions VERSION" "$_out" "${PRODUCT_VERSION}"

    _out=$(sh "${SCRIPT}" --json version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-03 version --json exit 0" 0 "$_ec"
    assert_contains "TP-CLI-03 type version" "$_out" '"type":"version"'
    assert_contains "TP-CLI-03 app field" "$_out" "\"app\":\"${APP_NAME}\""
    assert_contains "TP-CLI-03 version field" "$_out" "\"version\":\"${PRODUCT_VERSION}\""

    _out=$(sh "${SCRIPT}" help 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-04 help exit 0" 0 "$_ec"
    assert_contains "TP-CLI-04 help install" "$_out" "install"
    assert_contains "TP-CLI-04 help self-update" "$_out" "self-update"
    assert_contains "TP-CLI-04 help self-uninstall" "$_out" "self-uninstall"
    assert_contains "TP-CLI-04 help version-check" "$_out" "version-check"
    assert_contains "TP-CLI-04 help backup" "$_out" "backup [user]"
    assert_contains "TP-CLI-04 help restore" "$_out" "restore"
    assert_contains "TP-CLI-04 help auth-keys" "$_out" "auth-keys"
    assert_contains "TP-CLI-04 help setup" "$_out" "setup"
    assert_contains "TP-KEY-02 help remove-lpu" "$_out" "remove-lpu"
    assert_contains "TP-CLI-04 help print-sudoers" "$_out" "print-sudoers"
    assert_contains "TP-CLI-04 help generate-sudoer-request" "$_out" "generate-sudoer-request"
    assert_contains "TP-CLI-04 help menu" "$_out" "menu"
    assert_contains "TP-CLI-04 help --json" "$_out" "--json"
    assert_not_contains "TP-CLI-04 no sshd start" "$_out" "Start sshd"
    assert_not_contains "TP-CLI-04 no backup-config" "$_out" "backup-config"
    assert_not_contains "TP-CLI-04 no wake-lock" "$_out" "wake-lock"
    assert_not_contains "TP-CLI-04 no CHECKSUM" "$_out" "CHECKSUM"
    assert_contains "TP-CLI-04 help lists BASHRC" "$_out" "BASHRC"
    assert_contains "TP-CLI-18 help testers heading" "$_out" "Tests (local folder; not install):"
    assert_contains "TP-CLI-18 help lists rc-test" "$_out" "rc-test"

    _out=$(sh "${SCRIPT}" --json help 2>/dev/null)
    assert_eq "TP-CLI-05 help --json exit 0" 0 "$?"
    assert_contains "TP-CLI-05 help json success" "$_out" '"type":"success"'

    _out=$(sh "${SCRIPT}" --json about 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-06 about --json exit 0" 0 "$_ec"
    assert_contains "TP-CLI-06 type about" "$_out" '"type":"about"'
    assert_contains "TP-CLI-06 effective_storage" "$_out" '"effective_storage"'
    assert_contains "TP-CLI-06 key_cli_root" "$_out" '"key_cli_root"'
    assert_contains "TP-CLI-06 key_adm" "$_out" '"key_adm"'
    assert_contains "TP-KEY-03 key_adm_present" "$_out" '"key_adm_present"'
    assert_not_contains "TP-CLI-06 no sshd_platform" "$_out" '"sshd_platform"'
    assert_not_contains "TP-CLI-06 no CHECKSUM" "$_out" "CHECKSUM"

    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-07 empty argv exit 0" 0 "$_ec"
    assert_file_exists "TP-CLI-07 empty argv installed binary" "${CI_USER_BIN}/${APP_NAME}"
    assert_not_contains "TP-CLI-07 empty argv is not help" "$_out" "Usage:"
    assert_not_contains "TP-CLI-07 empty argv is not menu" "$_out" "Choose a number"
    ci_cleanup_env

    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" </dev/null 2>&1)
    _ec=$?
    assert_eq "TP-CLI-14 interactive empty argv exit 0" 0 "$_ec"
    assert_contains "TP-CLI-14 interactive empty argv shows menu" "$_out" "Choose a number"
    assert_contains "TP-CLI-14 interactive empty argv keys" "$_out" "keys"
    assert_contains "TP-CLI-14 interactive empty argv self-management" "$_out" "self-management"
    assert_contains "TP-CLI-14 interactive empty argv Exit 9" "$_out" "9. Exit"
    assert_not_contains "TP-CLI-14 no client-side" "$_out" "client-side"
    assert_not_contains "TP-CLI-14 no server-side" "$_out" "server-side"
    _out=$(printf '%s\n' '1' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    assert_contains "TP-CLI-14 keys backup row 11" "$_out" "11."
    assert_contains "TP-CLI-14 keys restore row 12" "$_out" "12."
    assert_contains "TP-CLI-14 keys auth-keys row 13" "$_out" "13."
    assert_contains "TP-CLI-14 keys sudoers row 14" "$_out" "14."
    assert_contains "TP-CLI-14 keys Back 0" "$_out" "0. Back"
    assert_file_missing "TP-CLI-14 interactive empty argv does not install" "${CI_USER_BIN}/${APP_NAME}"
    ci_cleanup_env

    ci_isolated_env
    _out=$(printf '%s\n' '8' '82' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-21 TTY 82 exit 0" 0 "$_ec"
    assert_contains "TP-CLI-21 TTY 82 about title" "$_out" "About / Diagnostics"
    assert_contains "TP-CLI-21 TTY 82 current user" "$_out" "Current user:"
    _out=$(sh "${SCRIPT}" version 2>/dev/null)
    assert_contains "TP-CLI-21 argv version mentions VERSION" "$_out" "${PRODUCT_VERSION}"
    assert_not_contains "TP-CLI-21 argv version is not about title" "$_out" "About / Diagnostics"
    _src=$(cat "${SCRIPT}")
    assert_contains "TP-CLI-21 menu 82 routes about" "${_src}" '82|version) app_about'
    unset _src
    ci_cleanup_env

    _err=$(sh "${SCRIPT}" no-such-command 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CLI-08 unknown exit 1" 1 "$_ec"
    assert_contains "TP-CLI-08 unknown error text" "$_err" "Unknown command"

    _out=$(sh "${SCRIPT}" --quiet version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-09 quiet version exit 0" 0 "$_ec"
    _trim=$(printf '%s' "$_out" | tr -d ' \t\n\r')
    if [ -z "$_trim" ]; then
        t_pass "TP-CLI-09 quiet suppresses human version"
    else
        t_fail "TP-CLI-09 quiet expected empty stdout, got '$(_trunc "$_out")'"
    fi

    _err=$(sh "${SCRIPT}" self-update 2>&1 >/dev/null)
    _ec=$?
    if printf '%s' "$_err" | grep -q "Unknown command"; then
        t_fail "TP-CLI-10 self-update must be a known command"
    else
        t_pass "TP-CLI-10 self-update is a known command (exit ${_ec})"
    fi

    _out=$(env -u HOME sh "${SCRIPT}" version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-11 env -u HOME version exit 0" 0 "$_ec"

    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" --json about 2>/dev/null)
    assert_contains "TP-CLI-12 isolated about has app in storage" "$_out" "${APP_NAME}"
    _eff=$(printf '%s' "$_out" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
    if [ -n "$_eff" ] && [ -d "$_eff" ]; then
        t_pass "TP-CLI-12 effective_storage directory exists"
    else
        t_fail "TP-CLI-12 effective_storage missing: '${_eff:-empty}'"
    fi
    ci_cleanup_env

    # TP-CLI-19 Git Bash: /dev/shm mkdir fail-soft → AppData Local Temp/cache; no ERROR
    _shm_leaf="/dev/shm/${APP_NAME}-$(id -un 2>/dev/null || echo unknown)"
    if [ -d "${_shm_leaf}" ]; then
        rm -rf "${_shm_leaf}"
    fi
    ci_isolated_env
    mkdir -p "${CI_HOME}/AppData/Local/Temp"
    _stub="${CI_HOME}/stubbin"
    mkdir -p "${_stub}"
    _real_mkdir=$(command -v mkdir)
    printf '%s\n' '#!/bin/sh' \
        "REAL_MKDIR='${_real_mkdir}'" \
        'for _a in "$@"; do' \
        '  case "${_a}" in' \
        '    /dev/shm/*) exit 1 ;;' \
        '  esac' \
        'done' \
        'exec "${REAL_MKDIR}" "$@"' > "${_stub}/mkdir"
    chmod +x "${_stub}/mkdir"
    _combined=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${_stub}:${PATH}" MSYSTEM=MINGW64 env -u TERMUX_VERSION sh "${SCRIPT}" --json about 2>&1)
    _ec=$?
    assert_eq "TP-CLI-19 git-bash shm fail-soft exit 0" 0 "$_ec"
    assert_not_contains "TP-CLI-19 no storage ERROR" "${_combined}" "Cannot create storage"
    assert_contains "TP-CLI-19 uses AppData Local Temp cache" "${_combined}" "AppData/Local/Temp/cache"
    _eff=$(printf '%s' "${_combined}" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
    if [ -n "${_eff}" ] && [ -d "${_eff}" ]; then
        t_pass "TP-CLI-19 git-bash effective_storage directory exists"
    else
        t_fail "TP-CLI-19 git-bash effective_storage missing: '${_eff:-empty}'"
    fi
    case "${_eff}" in
        *"${APP_NAME}"*) t_pass "TP-CLI-19 git-bash storage isolates APP_NAME" ;;
        *) t_fail "TP-CLI-19 git-bash storage isolates APP_NAME (got '${_eff:-empty}')" ;;
    esac
    unset _stub _real_mkdir _combined _ec _eff _shm_leaf
    ci_cleanup_env

    # TP-CLI-20 static: resolver names Git Bash Temp; no mid-chain mkdir die
    _src=$(cat "${SCRIPT}")
    assert_contains "TP-CLI-20 resolver names Git Bash Temp" "${_src}" 'AppData/Local/Temp'
    assert_contains "TP-CLI-20 fail-soft helper present" "${_src}" 'util_try_mkdir_storage'
    assert_not_contains "TP-CLI-20 no mid-chain mkdir die" "${_src}" 'out_die "Cannot create storage directory ${_storage_candidate}"'
    unset _src

    # Removed OpenSSH client/server verbs fail closed
    for _verb in start stop restart dns ssh download upload backup-config sync-config wake-lock; do
        _err=$(sh "${SCRIPT}" "${_verb}" 2>&1 >/dev/null)
        _ec=$?
        assert_eq "TP-KEY-01 ${_verb} exit 1" 1 "$_ec"
        assert_contains "TP-KEY-01 ${_verb} unknown" "$_err" "Unknown command"
    done

    # TP-KEY-16 TTY unknown token warns and redisplays
    ci_isolated_env
    _out=$(printf '%s\n' 'xyz' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u TERMUX_VERSION -u MSYSTEM sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-KEY-16 unknown then Exit 9 exit 0" 0 "$_ec"
    assert_contains "TP-KEY-16 unknown token named" "$_out" "Unknown menu choice 'xyz'"
    _n=$(t_count_substr "$_out" "Choose a number, or type the command name:")
    assert_eq "TP-KEY-16 redisplays menu" "2" "$_n"
    assert_contains "TP-KEY-16 still lists keys" "$_out" "keys"
    ci_cleanup_env

    # Termux: backup rows hidden
    ci_isolated_env
    _out=$(printf '%s\n' '1' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 TERMUX_VERSION=1 sh "${SCRIPT}" 2>&1)
    assert_contains "TP-KEY-04 Termux backup INFO" "$_out" "backup and restore not available for termux"
    assert_not_contains "TP-KEY-04 Termux no backup row 11" "$_out" "11."
    assert_contains "TP-KEY-04 Termux auth-keys row 13" "$_out" "13."
    ci_cleanup_env

    # Git Bash / Windows cmd: same hide + INFO
    ci_isolated_env
    _out=$(printf '%s\n' '1' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 MSYSTEM=MINGW64 env -u TERMUX_VERSION sh "${SCRIPT}" 2>&1)
    assert_contains "TP-KEY-05 Git Bash backup INFO" "$_out" "backup and restore not available for gitbash"
    assert_not_contains "TP-KEY-05 Git Bash no backup row 11" "$_out" "11."
    assert_contains "TP-KEY-05 Git Bash auth-keys row 13" "$_out" "13."
    ci_cleanup_env

    ci_isolated_env
    _out=$(printf '%s\n' '1' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u TERMUX_VERSION -u MSYSTEM -u WSL_DISTRO_NAME OS=Windows_NT COMSPEC='C:\\Windows\\system32\\cmd.exe' sh "${SCRIPT}" 2>&1)
    assert_contains "TP-KEY-06 Windows cmd backup INFO" "$_out" "backup and restore not available for windows-cmd"
    assert_not_contains "TP-KEY-06 Windows cmd no backup row 11" "$_out" "11."
    ci_cleanup_env

    # On-behalf is hidden for a normal login (INFO, not a live row 2 dispatch)
    ci_isolated_env
    _uid=$(id -u 2>/dev/null || echo 1)
    _out=$(printf '%s\n' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u TERMUX_VERSION -u MSYSTEM sh "${SCRIPT}" 2>&1)
    if [ "${_uid}" -eq 0 ]; then
        t_skip "TP-KEY-07 on-behalf hide (suite running as root)"
    else
        assert_contains "TP-KEY-07 on-behalf INFO" "$_out" "on-behalf features are not available except as"
        assert_not_contains "TP-KEY-07 no on-behalf short on front" "$_out" "as key-adm: backup/restore/auth-keys for other users"
    fi
    unset _uid
    ci_cleanup_env

    # menu --json / non-TTY fail closed
    _err=$(sh "${SCRIPT}" --json menu 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-KEY-08 menu --json exit 1" 1 "$_ec"
    assert_contains "TP-KEY-08 menu --json Next named command" "$_err" "named command"
    _err=$(sh "${SCRIPT}" menu 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-KEY-08 menu non-TTY exit 1" 1 "$_ec"
    assert_contains "TP-KEY-08 menu non-TTY needs a terminal" "$_err" "needs a terminal"

    # Static: do not capture prompt/read helpers (PROMPT_ASK_VALUE / do-not-capture-read)
    _src=$(cat "${SCRIPT}")
    assert_not_contains "TP-KEY-09 no capture of prompt_ask" "${_src}" '=$(prompt_ask'
    assert_not_contains "TP-KEY-09 no capture of prompt_yes_no" "${_src}" '=$(prompt_yes_no'
    assert_contains "TP-KEY-09 menu reads TTY SSOT" "${_src}" 'if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ] || [ "${TTY}" -ne 1 ]; then'
    unset _src
}
