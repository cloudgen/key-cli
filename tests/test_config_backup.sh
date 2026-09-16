# =============================================================================
# tests/test_config_backup.sh — ~/.ssh folder archive backup / restore / sudoers
# =============================================================================
# Primary REQs: requirement-shell-config-backup, requirement-shell-sudoer,
# requirement-domain-key
# TP family: TP-CFG-*
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

run_test_config_backup() {
    t_header "SSH folder archive (TP-CFG)"

    require_cmd sh
    require_cmd tar
    require_cmd grep

    _user=$(id -un 2>/dev/null || echo unknown)

    # TP-CFG-01 Type 0 backup into KEY_CLI_ROOT (no sudo; writable dest)
    ci_isolated_env
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}/${_user}/.ssh"
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyMaterialOnly test-key\n' > "${_homes}/${_user}/.ssh/authorized_keys"
    printf 'Host x\n  HostName example.test\n' > "${_homes}/${_user}/.ssh/config"
    chmod 700 "${_homes}/${_user}/.ssh"
    chmod 600 "${_homes}/${_user}/.ssh/authorized_keys" "${_homes}/${_user}/.ssh/config"
    _day=$(date +%Y%m%d)
    _out=$(HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" backup 2>&1)
    _ec=$?
    assert_eq "TP-CFG-01 backup exit 0" 0 "$_ec"
    assert_file_exists "TP-CFG-01 archive exists" "${_store}/${_user}/ssh-${_day}-1.tar.gz"
    assert_contains "TP-CFG-01 backup complete" "$_out" "Backup complete"
    _mode=$(stat -c '%a' "${_store}/${_user}/ssh-${_day}-1.tar.gz" 2>/dev/null || stat -f '%OLp' "${_store}/${_user}/ssh-${_day}-1.tar.gz")
    assert_eq "TP-CFG-01 archive mode 600" "600" "${_mode}"
    ci_cleanup_env

    # TP-CFG-02 same-day second backup increments N
    ci_isolated_env
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}/${_user}/.ssh"
    printf 'k\n' > "${_homes}/${_user}/.ssh/id_ed25519"
    chmod 700 "${_homes}/${_user}/.ssh"
    HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" backup >/dev/null 2>&1
    HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" backup >/dev/null 2>&1
    _day=$(date +%Y%m%d)
    assert_file_exists "TP-CFG-02 first archive" "${_store}/${_user}/ssh-${_day}-1.tar.gz"
    assert_file_exists "TP-CFG-02 second archive" "${_store}/${_user}/ssh-${_day}-2.tar.gz"
    ci_cleanup_env

    # TP-CFG-03 missing source fail-closed + Next
    ci_isolated_env
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}"
    _err=$(HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" backup 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CFG-03 missing source exit 1" 1 "$_ec"
    assert_contains "TP-CFG-03 missing source Next" "$_err" "Next:"
    ci_cleanup_env

    # TP-CFG-04 Termux: backup fail-closed
    ci_isolated_env
    _err=$(HOME="${CI_HOME}" TERMUX_VERSION=1 sh "${SCRIPT}" backup 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CFG-04 Termux backup exit 1" 1 "$_ec"
    assert_contains "TP-CFG-04 Termux not available" "$_err" "not available for termux"
    ci_cleanup_env

    # TP-CFG-05 restore extracts and --force overwrites
    ci_isolated_env
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}/${_user}/.ssh"
    printf 'secret-a\n' > "${_homes}/${_user}/.ssh/id_ed25519"
    chmod 700 "${_homes}/${_user}/.ssh"
    chmod 600 "${_homes}/${_user}/.ssh/id_ed25519"
    HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" backup >/dev/null 2>&1
    printf 'secret-b\n' > "${_homes}/${_user}/.ssh/id_ed25519"
    _day=$(date +%Y%m%d)
    _err=$(HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" restore "${_user}" "ssh-${_day}-1.tar.gz" 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CFG-05 restore without --force exit 1" 1 "$_ec"
    _out=$(HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" --force restore "${_user}" "ssh-${_day}-1.tar.gz" 2>&1)
    _ec=$?
    assert_eq "TP-CFG-05 restore --force exit 0" 0 "$_ec"
    assert_contains "TP-CFG-05 restore complete" "$_out" "Restore complete"
    _got=$(cat "${_homes}/${_user}/.ssh/id_ed25519")
    assert_eq "TP-CFG-05 restored secret-a" "secret-a" "${_got}"
    ci_cleanup_env

    # TP-CFG-06 print-sudoers --allow-test-local names backup (not OS tools)
    ci_isolated_env
    _draft="${CI_HOME}/sudoers.fragment"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" ALLOW_TEST_LOCAL_SUDOERS=1 sh "${SCRIPT}" print-sudoers --allow-test-local "${_draft}" 2>&1)
    _ec=$?
    assert_eq "TP-CFG-06 print-sudoers exit 0" 0 "$_ec"
    assert_file_exists "TP-CFG-06 draft written" "${_draft}"
    _txt=$(cat "${_draft}")
    assert_contains "TP-CFG-06 grant backup" "${_txt}" " backup"
    assert_contains "TP-CFG-06 grant restore *" "${_txt}" " restore *"
    assert_contains "TP-CFG-06 --json backup twin" "${_txt}" " --json backup"
    assert_not_contains "TP-CFG-06 no mkdir" "${_txt}" "/bin/mkdir"
    assert_not_contains "TP-CFG-06 no tar Cmnd" "${_txt}" "/bin/tar"
    ci_cleanup_env

    # TP-CFG-07 generate-sudoer-request JSON contains backup
    ci_isolated_env
    _jsonf="${CI_HOME}/grant.json"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" ALLOW_TEST_LOCAL_SUDOERS=1 sh "${SCRIPT}" generate-sudoer-request --allow-test-local "${_jsonf}" 2>&1)
    _ec=$?
    assert_eq "TP-CFG-07 generate exit 0" 0 "$_ec"
    _txt=$(cat "${_jsonf}")
    assert_contains "TP-CFG-07 json backup" "${_txt}" '"backup"'
    assert_not_contains "TP-CFG-07 json no mkdir" "${_txt}" "mkdir"
    ci_cleanup_env

    # TP-CFG-08 on-behalf other user refused for this login
    ci_isolated_env
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}/alice/.ssh" "${_homes}/${_user}/.ssh"
    printf 'x\n' > "${_homes}/alice/.ssh/id_ed25519"
    _err=$(HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" backup alice 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CFG-08 on-behalf exit 1" 1 "$_ec"
    assert_contains "TP-CFG-08 on-behalf refused" "$_err" "Cannot act on behalf"
    ci_cleanup_env

    # TP-CFG-09 restore list
    ci_isolated_env
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}/${_user}/.ssh"
    printf 'k\n' > "${_homes}/${_user}/.ssh/id_ed25519"
    HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" backup >/dev/null 2>&1
    _out=$(HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" restore list 2>&1)
    _ec=$?
    assert_eq "TP-CFG-09 restore list exit 0" 0 "$_ec"
    assert_contains "TP-CFG-09 list names archive" "$_out" "ssh-"
    ci_cleanup_env

    # TP-CFG-10 auth-keys add this login takes a global backup first
    ci_isolated_env
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}/${_user}/.ssh"
    chmod 700 "${_homes}/${_user}/.ssh"
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExamplePublicKeyMaterialOnly laptop\n' > "${CI_HOME}/laptop.pub"
    _out=$(HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" auth-keys add "${CI_HOME}/laptop.pub" 2>&1)
    _ec=$?
    assert_eq "TP-CFG-10 auth-keys add exit 0" 0 "$_ec"
    assert_file_exists "TP-CFG-10 authorized_keys" "${_homes}/${_user}/.ssh/authorized_keys"
    assert_contains "TP-CFG-10 key appended" "$(cat "${_homes}/${_user}/.ssh/authorized_keys")" "laptop"
    assert_contains "TP-CFG-10 add ran global backup" "$_out" "Backup complete"
    _day=$(date +%Y%m%d)
    _narch=$(find "${_store}/${_user}" -name "ssh-${_day}-*.tar.gz" 2>/dev/null | wc -l | tr -d ' ')
    if [ "${_narch}" -ge 1 ]; then
        t_pass "TP-CFG-10 global archive exists after add"
    else
        t_fail "TP-CFG-10 global archive exists after add (count=${_narch})"
    fi
    _out=$(HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" auth-keys add "${CI_HOME}/laptop.pub" 2>&1)
    assert_contains "TP-CFG-10 duplicate no-op" "$_out" "already"
    ci_cleanup_env

    # TP-CFG-11 Termux: auth-keys add fail-closed (global backup required)
    ci_isolated_env
    mkdir -p "${CI_HOME}/.ssh"
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExamplePublicKeyMaterialOnly laptop\n' > "${CI_HOME}/laptop.pub"
    _err=$(HOME="${CI_HOME}" TERMUX_VERSION=1 sh "${SCRIPT}" auth-keys add "${CI_HOME}/laptop.pub" 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CFG-11 Termux add exit 1" 1 "$_ec"
    assert_contains "TP-CFG-11 Termux add needs global backup" "$_err" "not available for termux"
    ci_cleanup_env

    # TP-CFG-12 Git Bash: backup fail-closed
    ci_isolated_env
    _err=$(HOME="${CI_HOME}" MSYSTEM=MINGW64 env -u TERMUX_VERSION sh "${SCRIPT}" backup 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CFG-12 Git Bash backup exit 1" 1 "$_ec"
    assert_contains "TP-CFG-12 Git Bash not available" "$_err" "not available for gitbash"
    ci_cleanup_env

    # TP-CFG-13 Windows cmd: backup fail-closed
    ci_isolated_env
    _err=$(HOME="${CI_HOME}" env -u TERMUX_VERSION -u MSYSTEM -u WSL_DISTRO_NAME OS=Windows_NT COMSPEC='C:\\Windows\\system32\\cmd.exe' sh "${SCRIPT}" backup 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CFG-13 Windows cmd backup exit 1" 1 "$_ec"
    assert_contains "TP-CFG-13 Windows cmd not available" "$_err" "not available for windows-cmd"
    ci_cleanup_env

    # TP-CFG-15 setup is root-only (fail closed off-root; skip host mutate if already root)
    _uid=$(id -u 2>/dev/null || echo 1)
    if [ "${_uid}" -eq 0 ]; then
        t_skip "TP-CFG-15 setup non-root (suite running as root)"
    else
        _err=$(sh "${SCRIPT}" setup 2>&1 >/dev/null)
        _ec=$?
        assert_eq "TP-CFG-15 setup non-root exit 1" 1 "$_ec"
        assert_contains "TP-CFG-15 setup Next sudo" "$_err" "sudo ${APP_NAME} setup"
    fi

    # TP-CFG-16 remove-lpu needs --force off-TTY; non-root still fail closed first
    if [ "${_uid}" -eq 0 ]; then
        _err=$(sh "${SCRIPT}" --json remove-lpu 2>&1 >/dev/null)
        _ec=$?
        assert_eq "TP-CFG-16 remove-lpu json no-force exit 1" 1 "$_ec"
        assert_contains "TP-CFG-16 remove-lpu needs --force" "$_err" "--force"
    else
        _err=$(sh "${SCRIPT}" remove-lpu 2>&1 >/dev/null)
        _ec=$?
        assert_eq "TP-CFG-16 remove-lpu non-root exit 1" 1 "$_ec"
        assert_contains "TP-CFG-16 remove-lpu Next sudo" "$_err" "sudo ${APP_NAME} remove-lpu"
    fi
    unset _uid

    # TP-CFG-17 TTY sudoers submenu unknown choice warns and redisplays
    ci_isolated_env
    _out=$(printf '%s\n' '1' '14' 'xyz' '0' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u TERMUX_VERSION -u MSYSTEM sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CFG-17 sudoers unknown then Back exit 0" 0 "$_ec"
    assert_contains "TP-CFG-17 unknown sudoers token named" "$_out" "Unknown sudoers choice 'xyz'"
    _n=$(t_count_substr "$_out" "generate-sudoer-request")
    if [ "${_n}" -ge 2 ]; then
        t_pass "TP-CFG-17 redisplays sudoers list"
    else
        t_fail "TP-CFG-17 redisplays sudoers list (count=${_n})"
    fi
    ci_cleanup_env

    # TP-CFG-18 nested backup from auth-keys add --json emits one JSON object
    ci_isolated_env
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}/${_user}/.ssh"
    chmod 700 "${_homes}/${_user}/.ssh"
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExamplePublicKeyMaterialOnly laptop\n' > "${CI_HOME}/laptop.pub"
    _out=$(HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" --json auth-keys add "${CI_HOME}/laptop.pub" 2>/dev/null)
    _ec=$?
    assert_eq "TP-CFG-18 auth-keys add json exit 0" 0 "$_ec"
    _n=$(printf '%s\n' "$_out" | grep -c '"type":' || true)
    assert_eq "TP-CFG-18 one JSON object" "1" "${_n}"
    assert_not_contains "TP-CFG-18 no nested backup type" "$_out" '"type":"backup"'
    ci_cleanup_env

    # TP-CFG-19 backup reports verify counts (no extract)
    ci_isolated_env
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}/${_user}/.ssh"
    printf 'k\n' > "${_homes}/${_user}/.ssh/id_ed25519"
    chmod 700 "${_homes}/${_user}/.ssh"
    _out=$(HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" backup 2>&1)
    assert_contains "TP-CFG-19 verify source_files" "$_out" "source_files="
    assert_contains "TP-CFG-19 verify members" "$_out" "members="
    assert_contains "TP-CFG-19 verify size" "$_out" "size="
    _fn=$(sed -n '/^key_cmd_backup()/,/^key_resolve_archive()/p' "${SCRIPT}")
    assert_not_contains "TP-CFG-19 backup does not extract to verify" "${_fn}" 'tar -xzf'
    unset _fn
    ci_cleanup_env

    # TP-CFG-20 restore dest directory mode 0700
    ci_isolated_env
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}/${_user}/.ssh"
    printf 'secret-a\n' > "${_homes}/${_user}/.ssh/id_ed25519"
    chmod 700 "${_homes}/${_user}/.ssh"
    HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" backup >/dev/null 2>&1
    _day=$(date +%Y%m%d)
    rm -rf "${_homes}/${_user}/.ssh"
    HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" --force restore "${_user}" "ssh-${_day}-1.tar.gz" >/dev/null 2>&1
    _mode=$(stat -c '%a' "${_homes}/${_user}/.ssh" 2>/dev/null || stat -f '%OLp' "${_homes}/${_user}/.ssh")
    assert_eq "TP-CFG-20 restored .ssh mode 700" "700" "${_mode}"
    ci_cleanup_env

    # TP-CFG-21 auth-keys list
    ci_isolated_env
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}/${_user}/.ssh"
    chmod 700 "${_homes}/${_user}/.ssh"
    printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExamplePublicKeyMaterialOnly laptop\n' > "${CI_HOME}/laptop.pub"
    HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" auth-keys add "${CI_HOME}/laptop.pub" >/dev/null 2>&1
    _out=$(HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" auth-keys list 2>&1)
    _ec=$?
    assert_eq "TP-CFG-21 auth-keys list exit 0" 0 "$_ec"
    assert_contains "TP-CFG-21 list names authorized_keys" "$_out" "authorized_keys"
    assert_contains "TP-CFG-21 list shows laptop comment" "$_out" "laptop"
    ci_cleanup_env

    # TP-CFG-22 TTY restore picker unknown choice warns and redisplays
    ci_isolated_env
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}/${_user}/.ssh"
    printf 'k\n' > "${_homes}/${_user}/.ssh/id_ed25519"
    chmod 700 "${_homes}/${_user}/.ssh"
    HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" backup >/dev/null 2>&1
    _out=$(printf '%s\n' 'xyz' '0' | HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" TTY=1 sh "${SCRIPT}" restore 2>&1)
    _ec=$?
    assert_eq "TP-CFG-22 restore unknown then Back exit 0" 0 "$_ec"
    assert_contains "TP-CFG-22 unknown restore token named" "$_out" "Unknown restore choice 'xyz'"
    _n=$(t_count_substr "$_out" "Choose an archive number:")
    assert_eq "TP-CFG-22 redisplays restore picker" "2" "$_n"
    ci_cleanup_env

    # TP-CFG-23 path-unsafe username fail closed
    ci_isolated_env
    _homes="${CI_HOME}/homes"
    _store="${CI_HOME}/store"
    mkdir -p "${_homes}"
    _err=$(HOME="${CI_HOME}" KEY_HOME_ROOT="${_homes}" KEY_CLI_ROOT="${_store}" sh "${SCRIPT}" backup '../etc' 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CFG-23 slash-dot username exit 1" 1 "$_ec"
    assert_contains "TP-CFG-23 invalid username" "$_err" "Invalid username"
    ci_cleanup_env

    # TP-CFG-24 Termux: print-sudoers fail closed
    ci_isolated_env
    _err=$(HOME="${CI_HOME}" TERMUX_VERSION=1 sh "${SCRIPT}" print-sudoers 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CFG-24 Termux print-sudoers exit 1" 1 "$_ec"
    assert_contains "TP-CFG-24 Termux print-sudoers not available" "$_err" "not available for termux"
    ci_cleanup_env

    # TP-CFG-25 Termux: setup / remove-lpu fail closed (Type 2 unused)
    ci_isolated_env
    _err=$(HOME="${CI_HOME}" TERMUX_VERSION=1 sh "${SCRIPT}" setup 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CFG-25 Termux setup exit 1" 1 "$_ec"
    assert_contains "TP-CFG-25 Termux setup not available" "$_err" "not available for termux"
    _err=$(HOME="${CI_HOME}" TERMUX_VERSION=1 sh "${SCRIPT}" remove-lpu --force 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CFG-25 Termux remove-lpu exit 1" 1 "$_ec"
    assert_contains "TP-CFG-25 Termux remove-lpu not available" "$_err" "not available for termux"
    ci_cleanup_env

    # TP-CFG-26 static: key-adm F6 is product Cmnds (backup/restore/auth-keys add+queue), not ALL / tar
    _fn=$(sed -n '/^key_lpu_sudoers_fragment_text()/,/^key_sudoers_json_text_compact()/p' "${SCRIPT}")
    assert_contains "TP-CFG-26 F6 backup *" "${_fn}" 'backup *'
    assert_contains "TP-CFG-26 F6 restore *" "${_fn}" 'restore *'
    assert_contains "TP-CFG-26 F6 auth-keys add *" "${_fn}" 'auth-keys add *'
    assert_contains "TP-CFG-26 F6 auth-keys pending" "${_fn}" 'auth-keys pending'
    assert_contains "TP-CFG-26 F6 auth-keys approve *" "${_fn}" 'auth-keys approve *'
    assert_contains "TP-CFG-26 F6 auth-keys reject *" "${_fn}" 'auth-keys reject *'
    assert_contains "TP-CFG-26 F6 auth-keys interactive" "${_fn}" 'auth-keys interactive'
    assert_contains "TP-CFG-26 F6 --json backup *" "${_fn}" '--json backup *'
    assert_contains "TP-CFG-26 F6 --json restore *" "${_fn}" '--json restore *'
    assert_contains "TP-CFG-26 F6 --json auth-keys add *" "${_fn}" '--json auth-keys add *'
    assert_contains "TP-CFG-26 F6 --json auth-keys approve *" "${_fn}" '--json auth-keys approve *'
    assert_not_contains "TP-CFG-26 F6 no ALL ALL" "${_fn}" 'ALL=(ALL) ALL'
    assert_not_contains "TP-CFG-26 F6 no /bin/tar" "${_fn}" '/bin/tar'
    unset _fn

    # TP-CFG-27 static: F7 does not delete the key store; userdel is the account path
    _fn=$(sed -n '/^key_cmd_remove_lpu()/,/^key_menu_show_on_behalf()/p' "${SCRIPT}")
    assert_contains "TP-CFG-27 F7 userdel -r" "${_fn}" 'userdel -r'
    assert_contains "TP-CFG-27 F7 archives kept copy" "${_fn}" 'Archives under'
    assert_not_contains "TP-CFG-27 F7 no rm -rf store" "${_fn}" 'rm -rf -- "$(key_cli_root)"'
    unset _fn
}
