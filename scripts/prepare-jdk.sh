#!/bin/bash
# SDKMAN! with Travis
# https://objectcomputing.com/news/2019/01/07/sdkman-travis
set -eEuo pipefail

[ -z "${_source_mark_of_prepare_jdk:+dummy}" ] || return 0
export _source_mark_of_prepare_jdk=true


# shellcheck source=common.sh
source "$(dirname "$(readlink -f "$BASH_SOURCE")")/common.sh"


if [ ! -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    [ -d "$HOME/.sdkman" ] && rm -rf "$HOME/.sdkman"
    curl -s get.sdkman.io | bash || die "fail to install sdkman"
    echo sdkman_auto_answer=true >> "$HOME/.sdkman/etc/config"

    this_time_install_sdk_man=true
fi
set +u
# shellcheck disable=SC1090
source "$HOME/.sdkman/bin/sdkman-init.sh"
[ -n "$this_time_install_sdk_man" ] && runCmd sdk ls java
set -u

jdks_install_by_sdkman=(
    7.0.282-zulu
    8.0.275-amzn

    9.0.7-zulu
    10.0.2-zulu
    11.0.9-zulu

    12.0.2-open
    13.0.5-zulu
    14.0.2-zulu
    15.0.1-zulu
    16.ea.29-open
    17.ea.2-open
)
java_home_var_names=()

setJdkHomeVarsAndInstallJdk() {
    blueEcho "prepared jdks:"

    JDK6_HOME="${JDK6_HOME:-/usr/lib/jvm/java-6-openjdk-amd64}"
    java_home_var_names=(JDK6_HOME)
    printf '%s :\n\t%s\n' "JDK6_HOME" "${JDK6_HOME}"

    local i
    for (( i = 0; i < ${#jdks_install_by_sdkman[@]}; i++ )); do
        local jdkVersion=$((i + 7))
        # jdkHomeVarName like JDK7_HOME, JDK11_HOME
        local jdkHomeVarName="JDK${jdkVersion}_HOME"
        local jdkNameOfSdkman="${jdks_install_by_sdkman[i]}"

        if [ ! -d "${!jdkHomeVarName:-}" ]; then
            local jdkHomePath="$SDKMAN_CANDIDATES_DIR/java/$jdkNameOfSdkman"

            # set JDK7_HOME ~ JDK1x_HOME to global var java_home_var_names
            eval "$jdkHomeVarName='${jdkHomePath}'"

            # install jdk by sdkman
            [ ! -d "$jdkHomePath" ] && {
                set +u
                runCmd sdk install java "$jdkNameOfSdkman" || die "fail to install jdk $jdkNameOfSdkman by sdkman"
                set -u
            }
        fi

        java_home_var_names=("${java_home_var_names[@]}" "$jdkHomeVarName")
        printf '%s :\n\t%s\n\tspecified is %s\n' "$jdkHomeVarName" "${!jdkHomeVarName}" "$jdkNameOfSdkman"
    done

    echo
    blueEcho "ls $SDKMAN_CANDIDATES_DIR/java/ :"
    ls -la "$SDKMAN_CANDIDATES_DIR/java/"
}
setJdkHomeVarsAndInstallJdk


switch_to_jdk() {
    [ $# == 1 ] || die "${FUNCNAME[0]} need 1 argument! But provided: $*"

    local javaHomeVarName="JDK${1}_HOME"
    export JAVA_HOME="${!javaHomeVarName}"

    [ -n "$JAVA_HOME" ] || die "jdk $1 env not found: $javaHomeVarName"
    [ -e "$JAVA_HOME" ] || die "jdk $1 not existed: $JAVA_HOME"
    [ -d "$JAVA_HOME" ] || die "jdk $1 is not directory: $JAVA_HOME"
}
