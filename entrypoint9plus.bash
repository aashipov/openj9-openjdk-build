#!/bin/bash

set -ex

JAVA_VERSION="${1}"
JDK="jdk"
JRE="jre"
JDK_FLAVOR="${JDK}${JAVA_VERSION}u"
JRE_FLAVOR="${JRE}${JAVA_VERSION}u"
INSTRUCTION_SET="x86_64"
OPENJ9="openj9"
OPENJ9_OPENJDK="${OPENJ9}-openjdk"
GIT_CLONE_URL=https://github.com/ibmruntimes/${OPENJ9_OPENJDK}-${JDK}${JAVA_VERSION}.git

_SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$0")")
TAG_TO_BUILD=$(cat ${_SCRIPT_DIR}/.tag_to_build_${JAVA_VERSION})
if [[ "${TAG_TO_BUILD}" == "" ]]; then
    printf "Can not find ${_SCRIPT_DIR}/.tag_to_build_${JAVA_VERSION} file or it is empty\n"
    exit 1
fi

OS_TYPE="linux"
TOP_DIR=${HOME}
# https://github.com/archlinux/svntogit-packages/blob/packages/java11-openjdk/trunk/PKGBUILD
# Avoid optimization of HotSpot being lowered from O3 to O2
_CFLAGS="-O3 -pipe"
if [[ "${OSTYPE}" == "cygwin" || "${OSTYPE}" == "msys" ]]; then
    if [[ "${OSTYPE}" == "cygwin" ]]; then
        TOP_DIR="/cygdrive/c"
    elif [[ "${OSTYPE}" == "msys" ]]; then
        TOP_DIR="/c"
    fi
    OS_TYPE="windows"
    export JAVA_HOME=${TOP_DIR}/dev/tools/openjdk${JAVA_VERSION}
    _CFLAGS="/O2"
fi
JDK_DIR="${TOP_DIR}/${OPENJ9_OPENJDK}-${JDK}${JAVA_VERSION}"
JTREG_DIR="${TOP_DIR}/${JTREG}"
GTEST_DIR="${TOP_DIR}/${GTEST}"
OS_TYPE_AND_INSTRUCTION_SET="${OS_TYPE}-${INSTRUCTION_SET}"

git config --global user.email "anatoly.a.shipov@gmail.com"
git config --global user.name "Anatoly Shipov"

if [[ "${JAVA_VERSION}" = "11" ]]; then
    RELEASE_IMAGE_DIR=${JDK_DIR}/build/${OS_TYPE_AND_INSTRUCTION_SET}-normal-server-release/images/
elif [[ "${JAVA_VERSION}" = "17" ]]; then
    RELEASE_IMAGE_DIR=${JDK_DIR}/build/${OS_TYPE_AND_INSTRUCTION_SET}-server-release/images/
else
    printf "Version 11 or 17 only\n"
    exit 1
fi

DEFAULT_BRANCH=openj9
if [ ! -d "${JDK_DIR}/.git" ]; then
    cd ${TOP_DIR}
    git clone ${GIT_CLONE_URL}
    cd ${JDK_DIR}
    git checkout tags/${TAG_TO_BUILD}
else
    cd ${JDK_DIR}
    git checkout ${DEFAULT_BRANCH}
    git pull
    git checkout tags/${TAG_TO_BUILD}
fi

rm -rf ${JDK_DIR}/omr/ ${JDK_DIR}/${OPENJ9}/

BRANCH_FROM_TAG=$(printf "${TAG_TO_BUILD}\n" | cut -d '-' -f 2)
BRANCH_FROM_TAG="v${BRANCH_FROM_TAG}-release"
bash get_source.sh -openj9-branch=${BRANCH_FROM_TAG} -omr-branch=${BRANCH_FROM_TAG}

cd ${JDK_DIR}/omr/
git checkout tags/${TAG_TO_BUILD}

cd ${JDK_DIR}/${OPENJ9}/
git checkout tags/${TAG_TO_BUILD}

cd ${JDK_DIR}

VERSION_STRING=$(awk -F" := " '{print $2}' ${JDK_DIR}/closed/openjdk-tag.gmk)

CONFIGURE_DETAILS="--verbose --with-debug-level=release --with-native-debug-symbols=none --with-jvm-variants=server --with-freetype=bundled --with-version-pre=\"\" --with-version-opt=\"\" --with-extra-cflags=\"${_CFLAGS}\" --with-extra-cxxflags=\"${_CFLAGS}\" --with-extra-ldflags=\"${_CFLAGS}\" --enable-unlimited-crypto --disable-warnings-as-errors --disable-warnings-as-errors-omr --disable-warnings-as-errors-openj9 --disable-keep-packaged-modules --with-version-string=\"${VERSION_STRING#${JDK}-}\""
#CONFIGURE_DETAILS="${CONFIGURE_DETAILS} --with-toolchain-type=clang"
#CONFIGURE_DETAILS="${CONFIGURE_DETAILS} --with-jtreg=${JTREG_DIR}/build/images/jtreg"
#CONFIGURE_DETAILS="${CONFIGURE_DETAILS} --with-gtest=${GTEST_DIR}"
bash -c "bash configure ${CONFIGURE_DETAILS}"

make clean
STARTTIME=$(date +%s)
make images legacy-jre-image docs
ENDTIME=$(date +%s)
echo "Compilation took $((${ENDTIME} - ${STARTTIME})) seconds"

if [[ $? -eq 0 ]]; then
    cd ${RELEASE_IMAGE_DIR}
    DOT_TAR_DOT_GZ=".tar.gz"
    JDK_FILE_NAME=${JDK_FLAVOR}-${OS_TYPE_AND_INSTRUCTION_SET}-${VERSION_STRING}-${BRANCH_FROM_TAG}${DOT_TAR_DOT_GZ}
    JRE_FILE_NAME=${JRE_FLAVOR}-${OS_TYPE_AND_INSTRUCTION_SET}-${VERSION_STRING}-${BRANCH_FROM_TAG}${DOT_TAR_DOT_GZ}
    find "${PWD}" -type f -name '*.debuginfo' -exec rm {} \;
    find "${PWD}" -type f -name '*.diz' -exec rm {} \;
    GZIP=-9 tar -czhf ${JDK_FILE_NAME} jdk/
    GZIP=-9 tar -czhf ${JRE_FILE_NAME} jre/

    GITHUB_TOKEN=$(cat ${HOME}/.github_token)
    if [[ "${GITHUB_TOKEN}" != "" ]]; then
        GITHUB_OWNER=aashipov
        GITHUB_REPO=openj9jdk-build
        GITHUB_RELEASE_ID=77262219

        FILES_TO_UPLOAD=(${JDK_FILE_NAME} ${JRE_FILE_NAME})
        for file_to_upload in "${FILES_TO_UPLOAD[@]}"; do
            #https://stackoverflow.com/a/7506695
            FILE_NAME_URL_ENCODED=$(printf "${file_to_upload}" | hexdump -v -e '/1 "%02x"' | sed 's/\(..\)/%\1/g')
            curl \
                https://uploads.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/${GITHUB_RELEASE_ID}/assets?name=${FILE_NAME_URL_ENCODED} \
                -H "Authorization: Bearer ${GITHUB_TOKEN}" \
                -H "Content-type: application/gzip" \
                --data-binary @${RELEASE_IMAGE_DIR}/${file_to_upload}
        done
    fi

    #cd ${JDK_DIR}
    #make run-test-tier1
fi
