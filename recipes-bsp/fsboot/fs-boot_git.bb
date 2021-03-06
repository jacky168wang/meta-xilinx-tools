DESCRIPTION = "FS-BOOT generator"

PROVIDES = "virtual/fsboot"

inherit xsctfsboot deploy

COMPATIBLE_MACHINE = "^$"
COMPATIBLE_MACHINE_microblaze = "microblaze"

XSCTH_APP = "mba_fs_boot"

PARALLEL_MAKE = ""
EXTRA_OEMAKE_BSP = ""
EXTRA_OEMAKE_APP = ""

do_compile() {
        oe_runmake -C ${XSCTH_WS}/${XSCTH_PROJ}/${XSCTH_APP}_bsp ${EXTRA_OEMAKE_BSP} -j 1 && \
        oe_runmake -C ${XSCTH_WS}/${XSCTH_PROJ} ${EXTRA_OEMAKE_APP} -j 1
}

do_deploy_append() {
        ln -sf ${PN}-${MACHINE}.elf ${DEPLOYDIR}/fsboot-${MACHINE}.elf
}
