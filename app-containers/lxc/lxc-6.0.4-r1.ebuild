# Copyright 2022-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit bash-completion-r1 linux-info meson optfeature systemd verify-sig

DESCRIPTION="A userspace interface for the Linux kernel containment features"
HOMEPAGE="https://linuxcontainers.org/ https://github.com/lxc/lxc"
SRC_URI="https://linuxcontainers.org/downloads/lxc/${P}.tar.gz
	verify-sig? ( https://linuxcontainers.org/downloads/lxc/${P}.tar.gz.asc )"

LICENSE="GPL-2 LGPL-2.1 LGPL-3"
SLOT="0/1.8" # SONAME liblxc.so.1 + ${PV//./} _if_ breaking ABI change while bumping.
KEYWORDS="amd64 ~arm ~arm64 ~ppc64 ~riscv x86"
IUSE="apparmor +caps examples io-uring man pam seccomp selinux ssl systemd test +tools"

RDEPEND="acct-group/lxc
	acct-user/lxc
	apparmor? ( sys-libs/libapparmor )
	caps? ( sys-libs/libcap )
	io-uring? ( >=sys-libs/liburing-2:= )
	pam? ( sys-libs/pam )
	seccomp? ( sys-libs/libseccomp )
	selinux? ( sys-libs/libselinux )
	ssl? ( dev-libs/openssl:0= )
	systemd? (
		sys-apps/dbus
		sys-apps/systemd:=
	)
	tools? ( sys-libs/libcap )"
DEPEND="${RDEPEND}
	caps? ( sys-libs/libcap[static-libs] )
	tools? ( sys-libs/libcap[static-libs] )
	sys-kernel/linux-headers"
BDEPEND="virtual/pkgconfig
	man? ( app-text/docbook2X )
	verify-sig? ( sec-keys/openpgp-keys-linuxcontainers )"

RESTRICT="!test? ( test )"

CONFIG_CHECK="~!NETPRIO_CGROUP
	~CGROUPS
	~CGROUP_CPUACCT
	~CGROUP_DEVICE
	~CGROUP_FREEZER

	~CGROUP_SCHED
	~CPUSETS
	~IPC_NS
	~MACVLAN

	~MEMCG
	~NAMESPACES
	~NET_NS
	~PID_NS

	~POSIX_MQUEUE
	~USER_NS
	~UTS_NS
	~VETH"

ERROR_CGROUP_FREEZER="CONFIG_CGROUP_FREEZER: needed to freeze containers"
ERROR_MACVLAN="CONFIG_MACVLAN: needed for internal (inter-container) networking"
ERROR_MEMCG="CONFIG_MEMCG: needed for memory resource control in containers"
ERROR_NET_NS="CONFIG_NET_NS: needed for unshared network"
ERROR_POSIX_MQUEUE="CONFIG_POSIX_MQUEUE: needed for lxc-execute command"
ERROR_UTS_NS="CONFIG_UTS_NS: needed to unshare hostnames and uname info"
ERROR_VETH="CONFIG_VETH: needed for internal (host-to-container) networking"

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/linuxcontainers.asc

DOCS=( AUTHORS CONTRIBUTING MAINTAINERS README.md doc/FAQ.txt )

PATCHES=(
	"${FILESDIR}"/${P}-start-Re-introduce-first-SET_DUMPABLE-call.patch
)

pkg_setup() {
	linux-info_pkg_setup
}

src_configure() {

	# -Dtools-multicall=false: will create a single binary called 'lxc' that conflicts with LXD.
	local emesonargs=(
		--localstatedir "${EPREFIX}/var"

		-Dcoverity-build=false
		-Dinstall-state-dirs=false
		-Doss-fuzz=false
		-Dspecfile=false
		-Dtools-multicall=false

		-Dcommands=true
		-Dinstall-init-files=true
		-Dmemfd-rexec=true
		-Dthread-safety=true

		$(meson_use apparmor)
		$(meson_use caps capabilities)
		$(meson_use examples)
		$(meson_use io-uring io-uring-event-loop)
		$(meson_use man)
		$(meson_use pam pam-cgroup)
		$(meson_use seccomp)
		$(meson_use selinux)
		$(meson_use ssl openssl)
		$(meson_use test tests)
		$(meson_use tools)

		$(usex systemd -Ddbus=true -Ddbus=false)
		$(usex systemd -Dinit-script="systemd" -Dinit-script="sysvinit")

		-Ddata-path=/var/lib/lxc
		-Ddoc-path=/usr/share/doc/${PF}
		-Dlog-path=/var/log/lxc
		-Drootfs-mount-path=/var/lib/lxc/rootfs
		-Druntime-path=/run
	)

	use tools && local emesonargs+=( -Dcapabilities=true )

	meson_src_configure
}

src_install() {
	meson_src_install

	# The main bash-completion file will collide with lxd, need to relocate and update symlinks.
	local lxcbashcompdir="${D}/$(get_bashcompdir)"
	mkdir -p "${lxcbashcompdir}" || die "Failed to create bashcompdir."
	mv "${lxcbashcompdir}"/_lxc "${lxcbashcompdir}"/lxc-start || die "Failed to move _lxc bash completion file."

	# Build system will install all bash completion files regardless of our 'tools' use flag.
	# Though installing them all will add bash completions for commands that don't exist, it's
	# cleaner than dealing with individual files based on the use flag status.
	bashcomp_alias lxc-start lxc-{attach,autostart,cgroup,checkpoint,config,console,copy,create,destroy,device,execute,freeze,info,ls,monitor,snapshot,stop,top,unfreeze,unshare,update-config,usernsexec,wait}

	find "${ED}" -name '*.la' -delete -o -name '*.a' -delete || die

	# Replace upstream sysvinit/systemd files.
	if use systemd ; then
		rm -r "${D}$(systemd_get_systemunitdir)" || die "Failed to remove systemd lib dir"
	else
		rm "${ED}"/etc/init.d/lxc-{containers,net} || die "Failed to remove sysvinit scripts"
	fi

	newinitd "${FILESDIR}/${PN}.initd.9" ${PN}
	systemd_newunit "${FILESDIR}"/lxc-monitord.service.5.0.0 lxc-monitord.service
	systemd_newunit "${FILESDIR}"/lxc-net.service.5.0.0 lxc-net.service
	systemd_newunit "${FILESDIR}"/lxc.service-5.0.0 lxc.service
	systemd_newunit "${FILESDIR}"/lxc_at.service.5.0.0 "lxc@.service"

	if ! use apparmor; then
		sed -i '/lxc-apparmor-load/d' "${D}$(systemd_get_systemunitdir)/lxc.service" ||
			die "Failed to remove apparmor references from lxc.service systemd unit."
	fi
}

pkg_postinst() {
	elog "Please refer to "
	elog "https://wiki.gentoo.org/wiki/LXC for introduction and usage guide."
	elog
	elog "Run 'lxc-checkconfig' to see optional kernel features."
	elog

	optfeature "creating your own LXC containers" app-containers/distrobuilder
	optfeature "automatic template scripts" app-containers/lxc-templates
	optfeature "Debian-based distribution container image support" dev-util/debootstrap
	optfeature "snapshot & restore functionality" sys-process/criu
}
