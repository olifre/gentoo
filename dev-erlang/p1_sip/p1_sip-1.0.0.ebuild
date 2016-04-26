# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit multilib

DESCRIPTION="ProcessOne SIP server component"
HOMEPAGE="https://github.com/processone/p1_sip"
SRC_URI="https://github.com/processone/${PN}/archive/${PV}.tar.gz
	-> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

CDEPEND=">=dev-erlang/p1_stun-0.9.0
	>=dev-erlang/p1_tls-1.0.0
	>=dev-erlang/p1_utils-1.0.2
	>=dev-lang/erlang-17.1"
DEPEND="${CDEPEND}
	dev-util/rebar"
RDEPEND="${CDEPEND}"

get_erl_libs() {
	echo "/usr/$(get_libdir)/erlang/lib"
}

find_dep() {
	local dep="$1"
	local d
	local erl_libs="${EPREFIX}$(get_erl_libs)"

	for d in ${erl_libs}/${dep} ${erl_libs}/${dep}-*; do
		if [[ -d ${d} ]]; then
			echo "${d}"
			return 0
		fi
	done

	return 1
}

make_includes_list() {
	local dep
	local dep_path
	local includes="{i, \"include\"}"

	for dep in "$@"; do
		dep_path="$(find_dep "${dep}")" || return 1
		includes+=", {i, \"${dep_path}/include\"}"
	done

	echo "[${includes}]"
}

src_prepare() {
	local includes="$(make_includes_list p1_stun)"

	# Suppress deps check.
	cat<<EOF >"${S}/rebar.config"
{erl_opts, ${includes}}.
{deps, []}.
EOF
}

src_configure() {
	export ERL_LIBS="${EPREFIX}$(get_erl_libs)"
	econf --libdir="${ERL_LIBS}"
}

src_compile() {
	export ERL_LIBS="${EPREFIX}$(get_erl_libs)"
	rebar compile || die 'rebar compile failed'
}

src_install() {
	insinto "$(get_erl_libs)/${P}"
	doins -r ebin include priv src
}
