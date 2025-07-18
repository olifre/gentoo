# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: golang-base.eclass
# @MAINTAINER:
# William Hubbs <williamh@gentoo.org>
# @SUPPORTED_EAPIS: 7
# @BLURB: Eclass that provides base functions for Go packages.
# @DEPRECATED: go-module.eclass
# @DESCRIPTION:
# This eclass provides base functions for software written in the Go
# programming language; it also provides the build-time dependency on
# dev-lang/go.

case ${EAPI} in
	7) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_GOLANG_BASE} ]]; then

_GOLANG_BASE=1

GO_DEPEND=">=dev-lang/go-1.10"
if [[ ${EAPI:-0} == [56] ]]; then
	DEPEND="${GO_DEPEND}"
else
	BDEPEND="${GO_DEPEND}"
fi

# Do not complain about CFLAGS etc since go projects do not use them.
QA_FLAGS_IGNORED='.*'

# force GO111MODULE to be auto for bug https://bugs.gentoo.org/771129
export GO111MODULE=auto

# @ECLASS_VARIABLE: EGO_PN
# @REQUIRED
# @DESCRIPTION:
# This is the import path for the go package to build. Please emerge
# dev-lang/go and read "go help importpath" for syntax.
#
# Example:
# @CODE
# EGO_PN=github.com/user/package
# @CODE

# @FUNCTION: ego_pn_check
# @DESCRIPTION:
# Make sure EGO_PN has a value.
ego_pn_check() {
	[[ -z "${EGO_PN}" ]] &&
		die "${ECLASS}.eclass: EGO_PN is not set"
	return 0
}

# @FUNCTION: get_golibdir
# @DESCRIPTION:
# Return the non-prefixed library directory where Go packages
# should be installed
get_golibdir() {
	echo /usr/lib/go-gentoo
}

# @FUNCTION: get_golibdir_gopath
# @DESCRIPTION:
# Return the library directory where Go packages should be installed
# This is the prefixed version which should be included in GOPATH
get_golibdir_gopath() {
	echo "${EPREFIX}$(get_golibdir)"
}

# @FUNCTION: golang_install_pkgs
# @DESCRIPTION:
# Install Go packages.
# This function assumes that $cwd is a Go workspace.
golang_install_pkgs() {
	debug-print-function ${FUNCNAME} "$@"

	ego_pn_check
	insinto "$(get_golibdir)"
	insopts -m0644 -p # preserve timestamps for bug 551486
	doins -r pkg src
}

fi
