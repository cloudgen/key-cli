# =============================================================================
# tests/test_cli.sh — CLI surface (local-only; no network)
# =============================================================================
# Primary REQs: requirement-shell-cli-interface, requirement-shell-cli-zero-arguments,
# requirement-shell-output-requirements, requirement-shell-cli-storage,
# requirement-domain-sshd (TP-SSHD-01, TP-SSHD-03..08)
# TP family: TP-CLI-* · TP-SSHD-01 · TP-SSHD-03..08
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

run_test_cli() {
    t_header "CLI surface (TP-CLI)"

    require_cmd sh
    require_cmd grep

    # TP-CLI-01 syntax
    sh -n "${SCRIPT}"
    assert_eq "TP-CLI-01 sh -n ship unit" 0 "$?"

    # TP-CLI-02 version human
    _out=$(sh "${SCRIPT}" version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-02 version exit 0" 0 "$_ec"
    assert_contains "TP-CLI-02 version mentions app" "$_out" "${APP_NAME}"
    assert_contains "TP-CLI-02 version mentions VERSION" "$_out" "${PRODUCT_VERSION}"

    # TP-CLI-03 version json
    _out=$(sh "${SCRIPT}" --json version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-03 version --json exit 0" 0 "$_ec"
    assert_contains "TP-CLI-03 type version" "$_out" '"type":"version"'
    assert_contains "TP-CLI-03 app field" "$_out" "\"app\":\"${APP_NAME}\""
    assert_contains "TP-CLI-03 version field" "$_out" "\"version\":\"${PRODUCT_VERSION}\""

    # TP-CLI-04 help lists this-login lifecycle + sshd domain; not checksum pin; not trimmed parent domain
    _out=$(sh "${SCRIPT}" help 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-04 help exit 0" 0 "$_ec"
    assert_contains "TP-CLI-04 help install" "$_out" "install"
    assert_contains "TP-CLI-04 help self-update" "$_out" "self-update"
    assert_contains "TP-CLI-04 help self-uninstall" "$_out" "self-uninstall"
    assert_contains "TP-CLI-04 help version-check" "$_out" "version-check"
    assert_contains "TP-CLI-04 help status" "$_out" "status"
    assert_contains "TP-CLI-04 help start" "$_out" "start"
    assert_contains "TP-CLI-04 help stop" "$_out" "stop"
    assert_contains "TP-CLI-04 help restart" "$_out" "restart"
    assert_contains "TP-CLI-04 help port" "$_out" "port"
    assert_contains "TP-CLI-04 help config" "$_out" "config"
    assert_contains "TP-CLI-04 help host-keys" "$_out" "host-keys"
    assert_contains "TP-CLI-04 help auth-keys" "$_out" "auth-keys"
    assert_contains "TP-CLI-04 help dns" "$_out" "dns"
    assert_contains "TP-CLI-04 help ssh" "$_out" "ssh ["
    assert_contains "TP-CLI-04 help download" "$_out" "download ["
    assert_contains "TP-CLI-04 help backup-config" "$_out" "backup-config"
    assert_contains "TP-CLI-04 help sync-config" "$_out" "sync-config"
    assert_contains "TP-CLI-04 help sync-from-remote" "$_out" "sync-from-remote"
    assert_contains "TP-CLI-04 help print-sudoers" "$_out" "print-sudoers"
    assert_contains "TP-CLI-04 help generate-sudoer-request" "$_out" "generate-sudoer-request"
    assert_contains "TP-CLI-04 help submit-sudoer-request" "$_out" "submit-sudoer-request"
    assert_contains "TP-CLI-04 help menu" "$_out" "menu"
    assert_contains "TP-CLI-04 help wake-lock" "$_out" "wake-lock"
    assert_contains "TP-CLI-04 help wake-unlock" "$_out" "wake-unlock"
    assert_contains "TP-CLI-04 help --json" "$_out" "--json"
    assert_not_contains "TP-CLI-04 no backup verb" "$_out" "backup <"
    assert_not_contains "TP-CLI-04 no restore verb" "$_out" "restore <"
    assert_not_contains "TP-CLI-04 no CHECKSUM" "$_out" "CHECKSUM"
    assert_contains "TP-CLI-04 help lists BASHRC" "$_out" "BASHRC"
    assert_contains "TP-CLI-18 help testers heading" "$_out" "Tests (local folder; not install):"
    assert_contains "TP-CLI-18 help lists rc-test" "$_out" "rc-test"
    assert_not_contains "TP-CLI-18 rc-test not under Self-management block only" "$_out" "  rc-test              Place"

    # TP-CLI-05 help json
    _out=$(sh "${SCRIPT}" --json help 2>/dev/null)
    assert_eq "TP-CLI-05 help --json exit 0" 0 "$?"
    assert_contains "TP-CLI-05 help json success" "$_out" '"type":"success"'

    # TP-CLI-06 about json storage, no channel, no domain backup fields
    _out=$(sh "${SCRIPT}" --json about 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-06 about --json exit 0" 0 "$_ec"
    assert_contains "TP-CLI-06 type about" "$_out" '"type":"about"'
    assert_contains "TP-CLI-06 effective_storage" "$_out" '"effective_storage"'
    assert_not_contains "TP-CLI-06 no backup_notation" "$_out" '"backup_notation"'
    assert_not_contains "TP-CLI-06 no deposit_dir" "$_out" '"deposit_dir"'
    assert_not_contains "TP-CLI-06 no restore_host_default" "$_out" '"restore_host_default"'
    assert_not_contains "TP-CLI-06 no CHECKSUM" "$_out" "CHECKSUM"
    assert_contains "TP-CLI-06 sshd_platform" "$_out" '"sshd_platform"'

    # TP-CLI-07 empty argv non-interactive = Type O install-ensure (not help, not menu)
    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-07 empty argv exit 0" 0 "$_ec"
    assert_file_exists "TP-CLI-07 empty argv installed binary" "${CI_USER_BIN}/${APP_NAME}"
    assert_not_contains "TP-CLI-07 empty argv is not help" "$_out" "Usage:"
    assert_not_contains "TP-CLI-07 empty argv is not menu" "$_out" "Choose a number"
    ci_cleanup_env

    # TP-CLI-14 empty argv interactive (TTY=1) = domain menu, not install
    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" </dev/null 2>&1)
    _ec=$?
    assert_eq "TP-CLI-14 interactive empty argv exit 0" 0 "$_ec"
    assert_contains "TP-CLI-14 interactive empty argv shows menu" "$_out" "Choose a number"
    assert_contains "TP-CLI-14 interactive empty argv client-side" "$_out" "client-side"
    assert_contains "TP-CLI-14 interactive empty argv server-side" "$_out" "server-side"
    assert_contains "TP-CLI-14 interactive empty argv self-management" "$_out" "self-management"
    assert_contains "TP-CLI-14 interactive empty argv Exit 9" "$_out" "9. Exit"
    assert_not_contains "TP-CLI-14 front board has no dns row 5" "$_out" "5. SSH names"
    assert_not_contains "TP-CLI-14 front board has no backup-config row" "$_out" "backup-config"
    _out=$(printf '%s\n' '1' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    assert_contains "TP-CLI-14 client dns row 11" "$_out" "11."
    assert_contains "TP-CLI-14 client dns short" "$_out" "dns"
    assert_contains "TP-CLI-14 client ssh row 12" "$_out" "12."
    assert_contains "TP-CLI-14 client download row 13" "$_out" "13."
    assert_contains "TP-CLI-14 client backup-config row 15" "$_out" "15."
    assert_contains "TP-CLI-14 client sync-config row 16" "$_out" "16."
    assert_contains "TP-CLI-14 client Back 0" "$_out" "0. Back"
    assert_not_contains "TP-CLI-14 no numbered port row" "$_out" "Show listen port"
    assert_not_contains "TP-CLI-14 no numbered config row" "$_out" "Show sshd config"
    assert_not_contains "TP-CLI-14 no numbered host-keys row" "$_out" "List host keys"
    assert_not_contains "TP-CLI-14 no numbered auth-keys row" "$_out" "List login keys"
    assert_file_missing "TP-CLI-14 interactive empty argv does not install" "${CI_USER_BIN}/${APP_NAME}"
    assert_not_contains "TP-CLI-14 interactive empty argv is not help Usage" "$_out" "Usage:"
    ci_cleanup_env

    # TP-CLI-15 status ends with a recommended ssh connect line
    _out=$(sh "${SCRIPT}" status 2>&1)
    _ec=$?
    assert_eq "TP-CLI-15 status exit 0" 0 "$_ec"
    assert_contains "TP-CLI-15 status Connect line" "$_out" "Connect:"
    assert_contains "TP-CLI-15 status ssh -p" "$_out" "ssh -p"
    assert_not_contains "TP-CLI-15 no placeholder host" "$_out" "<this-host>"
    case "${_out}" in
        *@*.*.*.*) t_pass "TP-CLI-15 connect uses dotted-quad IPv4" ;;
        *) t_fail "TP-CLI-15 connect uses dotted-quad IPv4 (got '$(_trunc "${_out}")')" ;;
    esac
    _json=$(sh "${SCRIPT}" --json status 2>/dev/null)
    assert_contains "TP-CLI-15 json connect field" "$_json" '"connect":"ssh -p'

    # TP-CLI-08 unknown command fail-closed
    _err=$(sh "${SCRIPT}" no-such-command 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CLI-08 unknown exit 1" 1 "$_ec"
    assert_contains "TP-CLI-08 unknown error text" "$_err" "Unknown command"

    _err=$(sh "${SCRIPT}" --json no-such-command 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CLI-08 unknown --json exit 1" 1 "$_ec"
    assert_contains "TP-CLI-08 unknown --json type" "$_err" '"type":"out_error"'

    # TP-CLI-09 quiet suppresses version info
    _out=$(sh "${SCRIPT}" --quiet version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-09 quiet version exit 0" 0 "$_ec"
    _trim=$(printf '%s' "$_out" | tr -d ' \t\n\r')
    if [ -z "$_trim" ]; then
        t_pass "TP-CLI-09 quiet suppresses human version"
    else
        t_fail "TP-CLI-09 quiet expected empty stdout, got '$(_trunc "$_out")'"
    fi

    # TP-CLI-10 self-update / version-check are routed (known commands); skip network
    _err=$(sh "${SCRIPT}" self-update 2>&1 >/dev/null)
    _ec=$?
    if printf '%s' "$_err" | grep -q "Unknown command"; then
        t_fail "TP-CLI-10 self-update must be a known command"
    else
        t_pass "TP-CLI-10 self-update is a known command (exit ${_ec})"
    fi
    _err=$(sh "${SCRIPT}" version-check 2>&1 >/dev/null)
    _ec=$?
    if printf '%s' "$_err" | grep -q "Unknown command"; then
        t_fail "TP-CLI-10 version-check must be a known command"
    else
        t_pass "TP-CLI-10 version-check is a known command (exit ${_ec})"
    fi

    # TP-CLI-11 set -u HOME unset still works for version
    _out=$(env -u HOME sh "${SCRIPT}" version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-11 env -u HOME version exit 0" 0 "$_ec"
    assert_contains "TP-CLI-11 env -u HOME version text" "$_out" "${PRODUCT_VERSION}"

    # TP-CLI-12 storage isolation under temp HOME
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
    # Remove this-login shm leaf so a leftover dir cannot satisfy -d after stub mkdir fails.
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

    # TP-CLI-13 trimmed parent folder-archive / setup verbs fail closed
    for _verb in backup restore setup; do
        _err=$(sh "${SCRIPT}" "${_verb}" 2>&1 >/dev/null)
        _ec=$?
        assert_eq "TP-CLI-13 ${_verb} exit 1" 1 "$_ec"
        assert_contains "TP-CLI-13 ${_verb} unknown" "$_err" "Unknown command"
    done

    # TP-SSHD-01 start is OpenSSH daemonize; no service-manager verbs
    _src=$(cat "${SCRIPT}")
    assert_contains "TP-SSHD-01 launch is sshd -f config" "$_src" '"${SSHD_BIN}" -f "${SSHD_CONFIG}"'
    assert_not_contains "TP-SSHD-01 no foreground -D launch" "$_src" '"${SSHD_BIN}" -D'
    assert_not_contains "TP-SSHD-01 no -f -D launch" "$_src" '"${SSHD_BIN}" -f "${SSHD_CONFIG}" -D'
    _out=$(sh "${SCRIPT}" help 2>&1)
    assert_eq "TP-SSHD-01 help exit 0" 0 "$?"
    assert_contains "TP-SSHD-01 help start is background daemon" "$_out" "background daemon"
    assert_contains "TP-SSHD-01 help names systemctl on Linux unit path" "$_out" "systemctl start"
    assert_not_contains "TP-SSHD-01 help no termux-services" "$_out" "termux-services"
    assert_not_contains "TP-SSHD-01 help no sv-enable" "$_out" "sv-enable"
    assert_not_contains "TP-SSHD-01 help no add-crontab" "$_out" "add-crontab"
    assert_not_contains "TP-SSHD-01 help no enable-service" "$_out" "enable-service"
    unset _src _out
    # TP-SSHD-03 POSIX Linux non-root TTY server submenu hides 22/23/24; INFO names OS; status stays 21
    ci_isolated_env
    _uid=$(id -u 2>/dev/null || echo 1)
    if [ "${_uid}" -eq 0 ]; then
        t_skip "TP-SSHD-03 non-root POSIX hide (suite running as root)"
        t_skip "TP-SSHD-05 hidden choice 2 unknown retry (suite running as root)"
    else
        _out=$(printf '%s\n' '2' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u TERMUX_VERSION -u MSYSTEM -u WSL_DISTRO_NAME sh "${SCRIPT}" 2>&1)
        _ec=$?
        assert_eq "TP-SSHD-03 non-root POSIX menu exit 0" 0 "$_ec"
        assert_contains "TP-SSHD-03 non-root INFO" "$_out" "start/stop/restart sshd features are not available for non-root in "
        assert_contains "TP-SSHD-03 status row 21" "$_out" "21."
        assert_contains "TP-SSHD-03 status short" "$_out" "status"
        assert_not_contains "TP-SSHD-03 no start row 22" "$_out" "22."
        assert_contains "TP-SSHD-03 server Back 0" "$_out" "0. Back"
        _out=$(printf '%s\n' '2' '22' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u TERMUX_VERSION -u MSYSTEM -u WSL_DISTRO_NAME sh "${SCRIPT}" 2>&1)
        _ec=$?
        assert_eq "TP-SSHD-05 hidden 22 then Back then Exit 9 exit 0" 0 "$_ec"
        assert_contains "TP-SSHD-05 hidden 22 unknown" "$_out" "Unknown menu choice '22'"
        _n=$(t_count_substr "$_out" "Choose a number, or type the command name:")
        if [ "${_n}" -ge 2 ]; then
            t_pass "TP-SSHD-05 hidden 22 redisplays menu"
        else
            t_fail "TP-SSHD-05 hidden 22 redisplays menu (prompts=${_n})"
        fi
        assert_not_contains "TP-SSHD-05 hidden 22 did not start" "$_out" "Re-run as root"
    fi
    ci_cleanup_env
    unset _uid _out _ec _n

    # TP-SSHD-16 TTY unknown token warns and redisplays; then Exit
    ci_isolated_env
    _out=$(printf '%s\n' 'xyz' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u TERMUX_VERSION -u MSYSTEM -u WSL_DISTRO_NAME sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-SSHD-16 unknown then Exit 9 exit 0" 0 "$_ec"
    assert_contains "TP-SSHD-16 unknown token named" "$_out" "Unknown menu choice 'xyz'"
    _n=$(t_count_substr "$_out" "Choose a number, or type the command name:")
    assert_eq "TP-SSHD-16 redisplays menu" "2" "$_n"
    assert_contains "TP-SSHD-16 still lists client-side" "$_out" "client-side"
    ci_cleanup_env
    unset _out _ec _n

    # TP-SSHD-04 Termux mock TTY menu still shows 2/3/4; no non-root INFO
    ci_isolated_env
    _out=$(printf '%s\n' '2' '0' '1' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 TERMUX_VERSION=1 sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-SSHD-04 Termux menu exit 0" 0 "$_ec"
    assert_contains "TP-SSHD-04 start row 22" "$_out" "22."
    assert_contains "TP-SSHD-04 stop row 23" "$_out" "23."
    assert_contains "TP-SSHD-04 restart row 24" "$_out" "24."
    assert_contains "TP-SSHD-04 dns row 11" "$_out" "11."
    assert_contains "TP-SSHD-04 backup-config INFO" "$_out" "backup-config and sync-config not available for termux"
    assert_contains "TP-SSHD-04 Termux sync-from-remote row 18" "$_out" "18."
    assert_contains "TP-SSHD-04 Termux Exit 9" "$_out" "9. Exit"
    assert_not_contains "TP-SSHD-04 no non-root INFO" "$_out" "not available for non-root"
    ci_cleanup_env
    unset _out _ec

    for _verb in systemctl sv-enable enable-service add-crontab; do
        _err=$(sh "${SCRIPT}" "${_verb}" 2>&1 >/dev/null)
        _ec=$?
        assert_eq "TP-SSHD-14 ${_verb} exit 1" 1 "$_ec"
        assert_contains "TP-SSHD-14 ${_verb} unknown" "$_err" "Unknown command"
    done
    unset _verb _err _ec

    # TP-SSHD-06 / TP-SSHD-07 INC-20260908-001: Linux fail-closed copy is host-local
    _src=$(cat "${SCRIPT}")
    assert_not_contains "TP-SSHD-07 no use-Termux on start die" "$_src" "use Termux where sshd runs"
    assert_not_contains "TP-SSHD-07 no use-Termux on stop die" "$_src" "use Termux where sshd belongs"
    assert_not_contains "TP-SSHD-07 writable die is not both platforms" "$_src" "On Linux re-run as root. On Termux"
    assert_contains "TP-SSHD-07 start die names re-run as root" "$_src" "Starting system sshd needs a root login on this host. Re-run as root."
    assert_contains "TP-SSHD-07 stop die names re-run as root" "$_src" "Stopping system sshd needs a root login on this host. Re-run as root."
    unset _src
    _uid=$(id -u 2>/dev/null || echo 1)
    if [ "${_uid}" -eq 0 ]; then
        t_skip "TP-SSHD-06 non-root POSIX stop error (suite running as root)"
        t_skip "TP-SSHD-08 POSIX start already-running honesty (suite running as root)"
    else
        _err=$(env -u TERMUX_VERSION -u MSYSTEM sh "${SCRIPT}" stop 2>&1)
        _ec=$?
        case "${_err}" in
            *"already stopped"*)
                t_skip "TP-SSHD-06 stop error (sshd already stopped)"
                ;;
            *)
                assert_eq "TP-SSHD-06 non-root stop exit 1" 1 "$_ec"
                assert_contains "TP-SSHD-06 stop names re-run as root" "$_err" "Re-run as root"
                assert_not_contains "TP-SSHD-06 stop error has no Termux" "$_err" "Termux"
                ;;
        esac
        # TP-SSHD-08 INC-20260908-002: POSIX start must not deny systemd for the live pid
        _out=$(env -u TERMUX_VERSION -u MSYSTEM sh "${SCRIPT}" start 2>&1)
        _ec=$?
        case "${_out}" in
            *"already running"*)
                assert_eq "TP-SSHD-08 already-running start exit 0" 0 "$_ec"
                assert_not_contains "TP-SSHD-08 no not-a-systemd" "$_out" "not a systemd"
                assert_not_contains "TP-SSHD-08 no session-daemon claim" "$_out" "for this session"
                assert_not_contains "TP-SSHD-08 no OpenSSH forks itself" "$_out" "OpenSSH forks itself"
                assert_not_contains "TP-SSHD-08 no reboot sshd-cli start" "$_out" "After a reboot, run:"
                assert_contains "TP-SSHD-08 names systemctl" "$_out" "systemctl"
                assert_contains "TP-SSHD-08 names distro unit" "$_out" ".service"
                ;;
            *"needs a root login"*)
                assert_eq "TP-SSHD-08 start fail-closed exit 1" 1 "$_ec"
                assert_contains "TP-SSHD-08 start names re-run as root" "$_out" "Re-run as root"
                assert_not_contains "TP-SSHD-08 start error has no Termux" "$_out" "Termux"
                ;;
            *)
                t_fail "TP-SSHD-08 expected already-running or root fail-closed (got '$(_trunc "${_out}")')"
                ;;
        esac
        unset _err _out _ec
    fi
    unset _uid

    # TP-SSHD-09 / TP-SSHD-10 systemd detect + unit name (read-only)
    _json=$(sh "${SCRIPT}" --json about 2>/dev/null)
    if [ -d /run/systemd/system ] && command -v systemctl >/dev/null 2>&1; then
        assert_contains "TP-SSHD-09 posix about sshd_systemd true" "$_json" '"sshd_systemd":"true"'
        case "${_json}" in
            *"\"sshd_unit\":\"ssh.service\""*|*"\"sshd_unit\":\"sshd.service\""*)
                t_pass "TP-SSHD-10 about names ssh.service or sshd.service"
                ;;
            *)
                t_fail "TP-SSHD-10 about names ssh.service or sshd.service (got '$(_trunc "${_json}")')"
                ;;
        esac
    else
        assert_contains "TP-SSHD-09 posix about sshd_systemd false (no systemd runtime)" "$_json" '"sshd_systemd":"false"'
        t_skip "TP-SSHD-10 unit name (no systemd runtime)"
    fi
    _json=$(TERMUX_VERSION=1 sh "${SCRIPT}" --json about 2>/dev/null)
    assert_contains "TP-SSHD-09 Termux about sshd_systemd false" "$_json" '"sshd_systemd":"false"'
    unset _json

    _src=$(cat "${SCRIPT}")
    assert_contains "TP-SSHD-11 source systemctl start" "$_src" 'systemctl start "${_unit}"'
    assert_contains "TP-SSHD-12 source systemctl stop" "$_src" 'systemctl stop "${_unit}"'
    assert_contains "TP-SSHD-12 source systemctl restart" "$_src" 'systemctl restart "${_unit}"'
    unset _src

    # TP-SSHD-13 Termux start never invokes systemctl
    ci_isolated_env
    mkdir -p "${CI_HOME}/stubbin"
    printf '%s\n' '#!/bin/sh' "echo \"\$*\" >> \"${CI_HOME}/systemctl-args.log\"" 'exit 0' > "${CI_HOME}/stubbin/systemctl"
    chmod +x "${CI_HOME}/stubbin/systemctl"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_HOME}/stubbin:${PATH}" TERMUX_VERSION=1 sh "${SCRIPT}" start >/dev/null 2>&1 || true
    if [ -f "${CI_HOME}/systemctl-args.log" ]; then
        t_fail "TP-SSHD-13 Termux start must not invoke systemctl"
    else
        t_pass "TP-SSHD-13 Termux start must not invoke systemctl"
    fi
    ci_cleanup_env
}
