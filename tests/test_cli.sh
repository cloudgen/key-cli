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
    assert_contains "TP-CLI-04 help auth-keys request" "$_out" "request [user]"
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
    assert_contains "TP-CLI-14 keys request row 15" "$_out" "15."
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

    # TP-KEY-10 request writes JSON into inbound (A may name B)
    ci_isolated_env
    _user=$(id -un 2>/dev/null || echo unknown)
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}/${_user}" "${_store}/auth-key-request" "${_store}/auth-key-accepted" "${_store}/auth-key-declined"
    chmod 1777 "${_store}/auth-key-request"
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyMaterialOnly alice-laptop\n' > "${CI_HOME}/alice.pub"
    _out=$(HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" auth-keys request bob "${CI_HOME}/alice.pub" 2>&1)
    _ec=$?
    assert_eq "TP-KEY-10 request exit 0" 0 "$_ec"
    assert_contains "TP-KEY-10 queued" "$_out" "Queued auth-key request"
    _day=$(date +%Y%m%d)
    _req="${_store}/auth-key-request/authkey-${_day}-bob-${_user}-add-1.json"
    assert_file_exists "TP-KEY-10 inbound json" "${_req}"
    assert_contains "TP-KEY-10 json username bob" "$(cat "${_req}")" '"username":"bob"'
    assert_contains "TP-KEY-10 json submitter" "$(cat "${_req}")" "\"submitter\":\"${_user}\""
    assert_contains "TP-KEY-10 json public_key" "$(cat "${_req}")" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyMaterialOnly alice-laptop"
    assert_contains "TP-KEY-10 json kind" "$(cat "${_req}")" '"kind":"auth-key"'
    assert_contains "TP-KEY-10 json submit_app" "$(cat "${_req}")" '"submit_app":"key-cli"'
    assert_contains "TP-KEY-10 json submit_version" "$(cat "${_req}")" '"submit_version":"'
    ci_cleanup_env

    # TP-KEY-11 missing inbound fail-closed + Next setup
    ci_isolated_env
    _store="${CI_HOME}/store"
    mkdir -p "${_store}"
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyMaterialOnly alice-laptop\n' > "${CI_HOME}/alice.pub"
    _err=$(HOME="${CI_HOME}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" auth-keys request bob "${CI_HOME}/alice.pub" 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-KEY-11 missing inbound exit 1" 1 "$_ec"
    assert_contains "TP-KEY-11 Next setup" "$_err" "setup"
    ci_cleanup_env

    # TP-KEY-12 request does not refuse A naming B (not dest self-scope)
    ci_isolated_env
    _user=$(id -un 2>/dev/null || echo unknown)
    _store="${CI_HOME}/store"
    mkdir -p "${_store}/auth-key-request"
    chmod 1777 "${_store}/auth-key-request"
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyMaterialOnly alice-laptop\n' > "${CI_HOME}/alice.pub"
    _err=$(HOME="${CI_HOME}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" auth-keys request bob "${CI_HOME}/alice.pub" 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-KEY-12 A-for-B request exit 0" 0 "$_ec"
    assert_not_contains "TP-KEY-12 no on-behalf refuse" "$_err" "Cannot act on behalf"
    ci_cleanup_env

    # TP-KEY-13 pending lists basename when this login is KEY_ADM_USER
    ci_isolated_env
    _user=$(id -un 2>/dev/null || echo unknown)
    _store="${CI_HOME}/store"
    mkdir -p "${_store}/auth-key-request" "${_store}/auth-key-accepted" "${_store}/auth-key-declined"
    chmod 1777 "${_store}/auth-key-request"
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyMaterialOnly alice-laptop\n' > "${CI_HOME}/alice.pub"
    HOME="${CI_HOME}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" auth-keys request bob "${CI_HOME}/alice.pub" >/dev/null 2>&1
    _day=$(date +%Y%m%d)
    _base="authkey-${_day}-bob-${_user}-add-1.json"
    _out=$(HOME="${CI_HOME}" KEY_CLI_ROOT="${_store}" KEY_ADM_USER="${_user}" sh "${SCRIPT}" auth-keys pending 2>&1)
    _ec=$?
    assert_eq "TP-KEY-13 pending exit 0" 0 "$_ec"
    assert_contains "TP-KEY-13 pending names basename" "$_out" "${_base}"
    ci_cleanup_env

    # TP-KEY-14 approve appends B authorized_keys and moves to accepted
    ci_isolated_env
    _user=$(id -un 2>/dev/null || echo unknown)
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}/bob/.ssh" "${_store}/auth-key-request" "${_store}/auth-key-accepted" "${_store}/auth-key-declined"
    chmod 700 "${_homes}/bob/.ssh"
    chmod 1777 "${_store}/auth-key-request"
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyMaterialOnly alice-laptop\n' > "${CI_HOME}/alice.pub"
    HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" auth-keys request bob "${CI_HOME}/alice.pub" >/dev/null 2>&1
    _day=$(date +%Y%m%d)
    _base="authkey-${_day}-bob-${_user}-add-1.json"
    _out=$(HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" KEY_ADM_USER="${_user}" sh "${SCRIPT}" auth-keys approve "${_base}" 2>&1)
    _ec=$?
    assert_eq "TP-KEY-14 approve exit 0" 0 "$_ec"
    assert_contains "TP-KEY-14 approved" "$_out" "Approved"
    assert_file_missing "TP-KEY-14 inbound moved" "${_store}/auth-key-request/${_base}"
    assert_file_exists "TP-KEY-14 accepted" "${_store}/auth-key-accepted/${_base}"
    assert_file_exists "TP-KEY-14 bob authorized_keys" "${_homes}/bob/.ssh/authorized_keys"
    assert_contains "TP-KEY-14 key appended" "$(cat "${_homes}/bob/.ssh/authorized_keys")" "alice-laptop"
    ci_cleanup_env

    # TP-KEY-15 reject moves to declined without appending
    ci_isolated_env
    _user=$(id -un 2>/dev/null || echo unknown)
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}/bob/.ssh" "${_store}/auth-key-request" "${_store}/auth-key-accepted" "${_store}/auth-key-declined"
    chmod 700 "${_homes}/bob/.ssh"
    chmod 1777 "${_store}/auth-key-request"
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyMaterialOnly alice-laptop\n' > "${CI_HOME}/alice.pub"
    HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" auth-keys request bob "${CI_HOME}/alice.pub" >/dev/null 2>&1
    _day=$(date +%Y%m%d)
    _base="authkey-${_day}-bob-${_user}-add-1.json"
    _out=$(HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" KEY_ADM_USER="${_user}" sh "${SCRIPT}" auth-keys reject "${_base}" 2>&1)
    _ec=$?
    assert_eq "TP-KEY-15 reject exit 0" 0 "$_ec"
    assert_contains "TP-KEY-15 rejected" "$_out" "Rejected"
    assert_file_missing "TP-KEY-15 inbound moved" "${_store}/auth-key-request/${_base}"
    assert_file_exists "TP-KEY-15 declined" "${_store}/auth-key-declined/${_base}"
    assert_file_missing "TP-KEY-15 no authorized_keys" "${_homes}/bob/.ssh/authorized_keys"
    ci_cleanup_env

    # TP-KEY-17 Termux request fail-closed
    ci_isolated_env
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyMaterialOnly alice-laptop\n' > "${CI_HOME}/alice.pub"
    _err=$(HOME="${CI_HOME}" TERMUX_VERSION=1 sh "${SCRIPT}" auth-keys request bob "${CI_HOME}/alice.pub" 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-KEY-17 Termux request exit 1" 1 "$_ec"
    assert_contains "TP-KEY-17 Termux not available" "$_err" "not available for termux"
    ci_cleanup_env

    # TP-KEY-18 quote in public key refused
    ci_isolated_env
    _store="${CI_HOME}/store"
    mkdir -p "${_store}/auth-key-request"
    chmod 1777 "${_store}/auth-key-request"
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITest"Quote alice\n' > "${CI_HOME}/bad.pub"
    _err=$(HOME="${CI_HOME}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" auth-keys request bob "${CI_HOME}/bad.pub" 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-KEY-18 quoted key exit 1" 1 "$_ec"
    assert_contains "TP-KEY-18 quoted key message" "$_err" "quote"
    ci_cleanup_env

    # TP-KEY-20 TTY keys 15 on POSIX; hidden on Termux
    ci_isolated_env
    _out=$(printf '%s\n' '1' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    assert_contains "TP-KEY-20 POSIX request row 15" "$_out" "15."
    _out=$(printf '%s\n' '1' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 TERMUX_VERSION=1 sh "${SCRIPT}" 2>&1)
    assert_not_contains "TP-KEY-20 Termux hides 15" "$_out" "15."
    ci_cleanup_env

    # TP-KEY-21 n walks accepted: second request gets add-2
    ci_isolated_env
    _user=$(id -un 2>/dev/null || echo unknown)
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}/bob/.ssh" "${_store}/auth-key-request" "${_store}/auth-key-accepted" "${_store}/auth-key-declined"
    chmod 700 "${_homes}/bob/.ssh"
    chmod 1777 "${_store}/auth-key-request"
    chmod 0751 "${_store}/auth-key-accepted" "${_store}/auth-key-declined"
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyMaterialOnly alice-laptop\n' > "${CI_HOME}/alice.pub"
    HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" auth-keys request bob "${CI_HOME}/alice.pub" >/dev/null 2>&1
    _day=$(date +%Y%m%d)
    _base="authkey-${_day}-bob-${_user}-add-1.json"
    HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" KEY_ADM_USER="${_user}" sh "${SCRIPT}" auth-keys approve "${_base}" >/dev/null 2>&1
    HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" auth-keys request bob "${CI_HOME}/alice.pub" >/dev/null 2>&1
    assert_file_exists "TP-KEY-21 second request is add-2" "${_store}/auth-key-request/authkey-${_day}-bob-${_user}-add-2.json"
    ci_cleanup_env

    # TP-KEY-22 approve of incorrect JSON fail-closed (file stays inbound)
    ci_isolated_env
    _user=$(id -un 2>/dev/null || echo unknown)
    _store="${CI_HOME}/store"
    mkdir -p "${_store}/auth-key-request" "${_store}/auth-key-accepted" "${_store}/auth-key-declined"
    chmod 1777 "${_store}/auth-key-request"
    _day=$(date +%Y%m%d)
    _base="authkey-${_day}-bob-${_user}-add-1.json"
    printf '%s\n' '{"schema_version":1,"purpose":"bad","username":"bob","submitter":"alice"}' > "${_store}/auth-key-request/${_base}"
    _err=$(HOME="${CI_HOME}" KEY_CLI_ROOT="${_store}" KEY_ADM_USER="${_user}" sh "${SCRIPT}" auth-keys approve "${_base}" 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-KEY-22 bad json approve exit 1" 1 "$_ec"
    assert_contains "TP-KEY-22 re-validation named" "$_err" "re-validation"
    assert_file_exists "TP-KEY-22 inbound kept" "${_store}/auth-key-request/${_base}"
    ci_cleanup_env

    # TP-KEY-23 interactive skips incorrect JSON and does not ask yes/no
    ci_isolated_env
    _user=$(id -un 2>/dev/null || echo unknown)
    _store="${CI_HOME}/store"
    mkdir -p "${_store}/auth-key-request" "${_store}/auth-key-accepted" "${_store}/auth-key-declined"
    chmod 1777 "${_store}/auth-key-request"
    _day=$(date +%Y%m%d)
    _base="authkey-${_day}-bob-${_user}-add-1.json"
    printf '%s\n' 'not-json' > "${_store}/auth-key-request/${_base}"
    _out=$(printf '%s\n' 'y' | HOME="${CI_HOME}" KEY_CLI_ROOT="${_store}" KEY_ADM_USER="${_user}" TTY=1 sh "${SCRIPT}" auth-keys interactive 2>&1)
    _ec=$?
    assert_eq "TP-KEY-23 interactive bad json exit 0" 0 "$_ec"
    assert_contains "TP-KEY-23 incorrect JSON format named" "$_out" "Incorrect JSON format"
    assert_not_contains "TP-KEY-23 no approval question" "$_out" "Approve this request"
    ci_cleanup_env

    # TP-HOOK-01 plant snippet via rc-test --file hook
    ci_isolated_env
    _rcroot=$(mktemp -d "${TMPDIR:-/tmp}/rc-hook.XXXXXX")
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" rc-test --root "${_rcroot}" --file hook --case create 2>&1)
    _ec=$?
    assert_eq "TP-HOOK-01 hook create exit 0" 0 "$_ec"
    assert_file_exists "TP-HOOK-01 bashrc" "${_rcroot}/.bashrc"
    assert_contains "TP-HOOK-01 begin marker" "$(cat "${_rcroot}/.bashrc")" "BEGIN key-cli login hook"
    assert_contains "TP-HOOK-01 doorbell" "$(cat "${_rcroot}/.bashrc")" "/usr/local/bin/key-review-hook auth-keys interactive"
    assert_not_contains "TP-HOOK-01 not product-binary doorbell" "$(cat "${_rcroot}/.bashrc")" "/usr/local/bin/key-cli auth-keys interactive"
    ci_cleanup_env

    # TP-HOOK-02 missing .profile created
    ci_isolated_env
    _rcroot=$(mktemp -d "${TMPDIR:-/tmp}/rc-hook.XXXXXX")
    HOME="${CI_HOME}" sh "${SCRIPT}" rc-test --root "${_rcroot}" --file hook --case create >/dev/null 2>&1
    assert_file_exists "TP-HOOK-02 profile created" "${_rcroot}/.profile"
    assert_contains "TP-HOOK-02 profile sources bashrc" "$(cat "${_rcroot}/.profile")" '. "${HOME}/.bashrc"'
    ci_cleanup_env

    # TP-HOOK-03 existing .profile unchanged
    ci_isolated_env
    _rcroot=$(mktemp -d "${TMPDIR:-/tmp}/rc-hook.XXXXXX")
    printf 'KEEP-PROFILE-BODY\n' > "${_rcroot}/.profile"
    HOME="${CI_HOME}" sh "${SCRIPT}" rc-test --root "${_rcroot}" --file hook --case create >/dev/null 2>&1
    assert_contains "TP-HOOK-03 profile body kept" "$(cat "${_rcroot}/.profile")" "KEEP-PROFILE-BODY"
    ci_cleanup_env

    # TP-HOOK-04 static: non-approver identity skip
    _src=$(sed -n '/^key_heal_login_rc()/,/^key_review_approver_login_rc()/p' "${SCRIPT}")
    assert_contains "TP-HOOK-04 identity skip" "${_src}" 'if [ "${_who}" != "${KEY_ADM_USER}" ]; then'
    unset _src

    # TP-HOOK-05 static: JSON skip unless setup heal
    _src=$(sed -n '/^key_heal_login_rc()/,/^key_review_approver_login_rc()/p' "${SCRIPT}")
    assert_contains "TP-HOOK-05 json skip" "${_src}" 'if [ "${JSON}" -eq 1 ]'
    unset _src

    # TP-HOOK-06 second heal noop
    ci_isolated_env
    _rcroot=$(mktemp -d "${TMPDIR:-/tmp}/rc-hook.XXXXXX")
    HOME="${CI_HOME}" sh "${SCRIPT}" rc-test --root "${_rcroot}" --file hook --case create >/dev/null 2>&1
    HOME="${CI_HOME}" sh "${SCRIPT}" rc-test --root "${_rcroot}" --file hook --case noop >/dev/null 2>&1
    _ec=$?
    assert_eq "TP-HOOK-06 hook noop exit 0" 0 "$_ec"
    ci_cleanup_env

    # TP-HOOK-07 chown helper present
    _src=$(cat "${SCRIPT}")
    assert_contains "TP-HOOK-07 util_align_rc_owner" "${_src}" 'util_align_rc_owner()'
    unset _src

    # TP-HOOK-08 symlink key-review-hook -> key-cli; no reverse; rewrite old doorbell
    ci_isolated_env
    _rcroot=$(mktemp -d "${TMPDIR:-/tmp}/rc-hook.XXXXXX")
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" rc-test --root "${_rcroot}" --file symlink --case create 2>&1)
    _ec=$?
    assert_eq "TP-HOOK-08 symlink create exit 0" 0 "$_ec"
    assert_file_exists "TP-HOOK-08 hook name exists" "${_rcroot}/bin/key-review-hook"
    if [ -L "${_rcroot}/bin/key-review-hook" ]; then
        t_pass "TP-HOOK-08 hook is a symlink"
    else
        t_fail "TP-HOOK-08 hook is a symlink"
    fi
    _tgt=$(readlink "${_rcroot}/bin/key-review-hook")
    case "${_tgt}" in
        *key-cli) t_pass "TP-HOOK-08 target is key-cli" ;;
        *) t_fail "TP-HOOK-08 target is key-cli (got ${_tgt})" ;;
    esac
    if [ -L "${_rcroot}/bin/key-cli" ]; then
        t_fail "TP-HOOK-08 no reverse-symlink of key-cli"
    else
        t_pass "TP-HOOK-08 no reverse-symlink of key-cli"
    fi
    HOME="${CI_HOME}" sh "${SCRIPT}" rc-test --root "${_rcroot}" --file hook --case rewrite >/dev/null 2>&1
    assert_contains "TP-HOOK-08 rewrite to key-review-hook" "$(cat "${_rcroot}/.bashrc")" "/usr/local/bin/key-review-hook auth-keys interactive"
    assert_not_contains "TP-HOOK-08 old key-cli doorbell gone" "$(cat "${_rcroot}/.bashrc")" "/usr/local/bin/key-cli auth-keys interactive"
    ci_cleanup_env

    # TP-HOOK-09 interactive rewrites old product-binary doorbell in KEY_ADM_HOME
    ci_isolated_env
    _user=$(id -un 2>/dev/null || echo unknown)
    _store="${CI_HOME}/store"
    _adm="${CI_HOME}/adm"
    mkdir -p "${_store}/auth-key-request" "${_store}/auth-key-accepted" "${_store}/auth-key-declined" "${_adm}"
    chmod 1777 "${_store}/auth-key-request"
    {
        printf '%s\n' "# BEGIN key-cli login hook"
        printf '%s\n' 'sudo -n /usr/local/bin/key-cli auth-keys interactive'
        printf '%s\n' "# END key-cli login hook"
    } > "${_adm}/.bashrc"
    _out=$(printf '%s\n' | HOME="${CI_HOME}" KEY_CLI_ROOT="${_store}" KEY_ADM_HOME="${_adm}" KEY_ADM_USER="${_user}" TTY=1 sh "${SCRIPT}" auth-keys interactive 2>&1)
    _ec=$?
    assert_eq "TP-HOOK-09 interactive exit 0" 0 "$_ec"
    assert_contains "TP-HOOK-09 rewritten doorbell" "$(cat "${_adm}/.bashrc")" "/usr/local/bin/key-review-hook auth-keys interactive"
    assert_not_contains "TP-HOOK-09 old doorbell gone" "$(cat "${_adm}/.bashrc")" "/usr/local/bin/key-cli auth-keys interactive"
    ci_cleanup_env
}
