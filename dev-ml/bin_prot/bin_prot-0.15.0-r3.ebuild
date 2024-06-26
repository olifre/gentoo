# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit dune

DESCRIPTION="Binary protocol generator"
HOMEPAGE="https://github.com/janestreet/bin_prot"
SRC_URI="https://github.com/janestreet/bin_prot/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="amd64 arm arm64 ~ppc ppc64 ~riscv x86"
IUSE="+ocamlopt"

RDEPEND="
	dev-ml/base:${SLOT}
	dev-ml/findlib:=
	>=dev-ml/ppxlib-0.28:=
	dev-ml/ppx_compare:${SLOT}
	dev-ml/ppx_custom_printf:${SLOT}
	dev-ml/ppx_fields_conv:${SLOT}
	dev-ml/ppx_optcomp:${SLOT}
	dev-ml/ppx_sexp_conv:${SLOT}
	dev-ml/ppx_variants_conv:${SLOT}
	dev-ml/variantslib:${SLOT}
"
DEPEND="${RDEPEND}"
