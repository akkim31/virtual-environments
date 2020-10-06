#!/bin/sh

# The script currently requires 2 external variables to be set: XCODE_INSTALL_USER
# and XCODE_INSTALL_PASSWORD, in order to access the Apple Developer Center

set -e

source ~/utils/utils.sh
source ~/utils/xcode-utils.sh

if [ -z $XCODE_INSTALL_USER ] || [ -z $XCODE_INSTALL_PASSWORD ]; then
    echo "Required environment variables XCODE_INSTALL_USER and XCODE_INSTALL_PASSWORD are not set"
    exit 1
fi

XCODE_LIST=($(get_xcode_list_from_toolset))
LATEST_XCODE_VERSION=$(get_latest_xcode_from_toolset)
DEFAULT_XCODE_VERSION=$(get_default_xcode_from_toolset)
WORK_DIR="${HOME}/Library/Caches/XcodeInstall"

# Update the list of available versions
xcversion update
NUMBER_OF_PARALLEL_INSTALLATIONS=3

for XCODE_VERSION in "${XCODE_LIST[@]}"
do
    ((i=i%NUMBER_OF_PARALLEL_INSTALLATIONS)); ((i++==0)) && wait
    (
    WORK_DIR="${WORK_DIR}_${XCODE_VERSION}"
    VERSION_TO_INSTALL="$(getXcodeVersionToInstall "$XCODE_VERSION")"
    if [[ -z "$VERSION_TO_INSTALL" ]]; then
        echo "No versions were found matching $XCODE_VERSION"
        exit 1
    fi

    echo "Downloading Xcode $VERSION_TO_INSTALL ..."
    xcversion install "$VERSION_TO_INSTALL" --no-install

    # Create destination folder and move xip
    mkdir ${WORK_DIR}

    # hack for beta
    if [[ $XCODE_VERSION == "12_beta" ]] && is_Catalina ; then
        find "${HOME}/Library/Caches/XcodeInstall/" -name "Xcode_${XCODE_VERSION}.xip" -o -name "Xcode_${XCODE_VERSION}_*.xip" -type f -exec mv -f {} "${WORK_DIR}" \;
    else
        mv -f "${HOME}/Library/Caches/XcodeInstall/Xcode_${XCODE_VERSION}.xip" "${WORK_DIR}/Xcode_${XCODE_VERSION}.xip"
    fi

    if [[ ! -d "${WORKING_DIR}/Xcode_${XCODE_VERSION}.xip" ]]; then
        echo "Xcode_${XCODE_VERSION}.xip doesn't exist before extracting"
        exit 1
    fi

    echo "Extracting Xcode.app ($VERSION_TO_INSTALL) to ${WORK_DIR} ..."
    extractXcodeXip $WORK_DIR "$VERSION_TO_INSTALL"

    # Remove "beta" postfix from version
    if [[ $XCODE_VERSION == "12_beta" ]] && is_Catalina ; then
        # trick to install Xcode 12 GM and Xcode 12 beta 6 side by side
        XCODE_VERSION="12_beta"
    else
        XCODE_VERSION=$(echo $XCODE_VERSION | cut -d"_" -f 1)
    fi

    echo "Checking if unpacked Xcode ${XCODE_VERSION} is valid"
    validateXcodeIntegrity "$WORK_DIR"

    # Move Xcode to /Applications
    mv -f "${WORK_DIR}/Xcode.app" "/Applications/Xcode_${XCODE_VERSION}.app"

    echo "Accepting license for Xcode ${XCODE_VERSION}..."
    approveLicense $XCODE_VERSION

    # Creating a symlink for all Xcode 10* and Xcode 9.3, 9.4 to stay backwards compatible with consumers of the Xcode beta version
    createBetaSymlink $XCODE_VERSION

    if [ ! $(echo $XCODE_VERSION | grep "beta") ]; then
        createXamarinProvisionatorSymlink "$XCODE_VERSION"
    fi

    find $WORK_DIR -mindepth 1 -delete
    ) &
done
wait
echo "All parallel installation completed"
echo "Configuring 'runFirstLaunch' for all Xcode versions"
if is_Less_Catalina; then
    echo "Install additional packages for Xcode ${LATEST_XCODE_VERSION}"
    installAdditionalPackages $LATEST_XCODE_VERSION
fi

for XCODE_VERSION in "${XCODE_LIST[@]}"
do
    if [[ $XCODE_VERSION == 8* || $XCODE_VERSION == 9* ]]; then
        continue
    fi

    if [[ $XCODE_VERSION == "12_beta" ]] && is_Catalina ; then
        # trick to install Xcode 12 GM and Xcode 12 beta 6 side by side
        XCODE_VERSION="12_beta"
    else
        XCODE_VERSION=$(echo $XCODE_VERSION | cut -d"_" -f 1)
    fi

    echo "Running 'runFirstLaunch' for Xcode ${XCODE_VERSION}..."
    runFirstLaunch $XCODE_VERSION
done

echo "Running 'runFirstLaunch' for default Xcode ${DEFAULT_XCODE_VERSION}..."
runFirstLaunch $DEFAULT_XCODE_VERSION

# Create symlinks for Xcode on Catalina: 11.3 -> 11.3.1, 11.2 -> 11.2.1
if is_Catalina; then
    ln -sf /Applications/Xcode_11.2.1.app /Applications/Xcode_11.2.app
    ln -sf /Applications/Xcode_11.3.1.app /Applications/Xcode_11.3.app
fi

echo "Setting Xcode ${DEFAULT_XCODE_VERSION} as default"
sudo xcode-select -s "/Applications/Xcode_${DEFAULT_XCODE_VERSION}.app/Contents/Developer"

echo "Adding symlink '/Applications/Xcode_${DEFAULT_XCODE_VERSION}.app' -> '/Applications/Xcode.app'"
ln -s "/Applications/Xcode_${DEFAULT_XCODE_VERSION}.app" "/Applications/Xcode.app"

echo "Enabling developer mode"
sudo /usr/sbin/DevToolsSecurity --enable

echo "Setting environment variables 'XCODE_<VERSION>_DEVELOPER_DIR'"
setXcodeDeveloperDirVariables

# Cleanup
echo "Doing cleanup. Emptying ${WORK_DIR}..."
rm -rf "$WORK_DIR"
