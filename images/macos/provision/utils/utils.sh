download_with_retries() {
# Due to restrictions of bash functions, positional arguments are used here.
# In case if you using latest argument NAME, you should also set value to all previous parameters.
# Example: download_with_retries $ANDROID_SDK_URL "." "android_sdk.zip"
    local URL="$1"
    local DEST="${2:-.}"
    local NAME="${3:-${URL##*/}}"

    echo "Downloading $URL..."
    wget $URL   --output-document="$DEST/$NAME" \
                --tries=30 \
                --wait 30 \
                --retry-connrefused \
                --retry-on-host-error \
                --retry-on-http-error=429,500,502,503 \
                --no-verbose

    if [ $? != 0 ]; then
        echo "Could not download $URL; Exiting build!"
        exit 1
    fi

    return 0
}

is_BigSur() {
    if [ "$OSTYPE" = "darwin20" ]; then
        true
    else
        false
    fi
}

is_Catalina() {
    if [ "$OSTYPE" = "darwin19" ]; then
        true
    else
        false
    fi
}

is_Mojave() {
    if [ "$OSTYPE" = "darwin18" ]; then
        true
    else
        false
    fi
}

is_HighSierra() {
    if [ "$OSTYPE" = "darwin17" ]; then
        true
    else
        false
    fi
}

is_Less_Catalina() {
    if is_HighSierra || is_Mojave; then
        true
    else
        false
    fi
}

is_Less_BigSur() {
    if is_HighSierra || is_Mojave || is_Catalina; then
        true
    else
        false
    fi
}

get_toolset_path() {
    echo "$HOME/image-generation/toolset.json"
}

get_toolset_value() {
    local toolset_path=$(get_toolset_path)
    local query=$1
    echo "$(jq -r "$query" $toolset_path)"
}

get_xcode_list_from_toolset() {
    echo $(get_toolset_value '.xcode.versions | reverse | .[]')
}

get_latest_xcode_from_toolset() {
    echo $(get_toolset_value '.xcode.versions[0]')
}

get_default_xcode_from_toolset() {
    echo $(get_toolset_value '.xcode.default')
}

install_clt() {
    echo "Searching online for the Command Line Tools"
    # This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
    clt_placeholder="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    sudo touch $clt_placeholder

    clt_label_command="/usr/sbin/softwareupdate -l |
                        grep -B 1 -E 'Command Line Tools' |
                        awk -F'*' '/^ *\\*/ {print \$2}' |
                        sed -e 's/^ *Label: //' -e 's/^ *//' |
                        sort -V |
                        tail -n1"

    retries=30
    sleepInterval=60

    until [[ $retries -le 0 ]]; do
        clt_label=$clt_label_command
        if [[ -z "$clt_label" ]]; then
            ((retries--))
        else
            echo "$clt_label_command found"
            break
        fi

        if [[ $retries -eq 0 ]]; then
            echo "Unable to find command line tools, all the attempts exhausted"
            exit 1
        fi

        echo "Unable to find command line tools, wait for $sleepInterval seconds, $retries attempts left"
        sleep $sleepInterval
    done

    if [[ -n "$clt_label" ]]; then
    echo "Installing $clt_label"
    sudo "/usr/sbin/softwareupdate" "-i" "$clt_label"
    sudo "/bin/rm" "-f" "$clt_placeholder"
    sudo "/usr/bin/xcode-select" "--switch" "/Library/Developer/CommandLineTools"
    fi
}