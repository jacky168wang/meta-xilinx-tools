inherit xsct-tc

BIF_COMMON_ATTR ?= ''
BIF_PARTITION_ATTR ?= ''
BIF_PARTITION_IMAGE ?= ''
BIF_PARTITION_DEPENDS ?= ''
BIF_FILE_PATH = "${WORKDIR}/bootgen.bif"

def create_bif(config, attrflags, attrimage, common_attr, biffd, d):
    import re, os
    for cfg in config:
        if cfg not in attrflags and common_attr:
            error_msg = "%s: invalid ATTRIBUTE" % (cfg)
            bb.error("BIF attribute Error: %s " % (error_msg))
        else:
            if common_attr:
                cfgval = attrflags[cfg].split(',')
                cfgstr = "\t [%s] %s\n" % (cfg,', '.join(cfgval))
            else:
                if cfg not in attrimage:
                    error_msg = "%s: invalid or missing elf or image" % (cfg)
                    bb.error("BIF atrribute Error: %s " % (error_msg))
                imagestr = d.expand(attrimage[cfg])
                if os.stat(imagestr).st_size == 0:
                    bb.warn("Empty file %s, excluding from bif file" %(imagestr))
                    continue
                if cfg in attrflags:
                    cfgval = attrflags[cfg].split(',')
                    cfgstr = "\t [%s] %s\n" % (', '.join(cfgval), imagestr)
                else:
                    cfgstr = "\t %s\n" % (imagestr)
            biffd.write(cfgstr)

    return

python do_create_bif() {

    fp = d.getVar("BIF_FILE_PATH", True)
    biffd = open(fp, 'w')
    biffd.write("the_ROM_image:\n")
    biffd.write("{\n")

    bifattr = (d.getVar("BIF_COMMON_ATTR", True) or "").split()
    if bifattr:
        attrflags = d.getVarFlags("BIF_COMMON_ATTR") or {}
        create_bif(bifattr, attrflags,'', 1, biffd, d)

    bifpartition = (d.getVar("BIF_PARTITION_ATTR", True) or "").split()
    if bifpartition:
        attrflags = d.getVarFlags("BIF_PARTITION_ATTR") or {}
        attrimage = d.getVarFlags("BIF_PARTITION_IMAGE") or {}
        create_bif(bifpartition, attrflags, attrimage, 0, biffd, d)

    biffd.write("}")
    biffd.close()
}
addtask do_create_bif before do_xilinx_bootbin

do_create_bif[vardeps] += "BIF_PARTITION_ATTR BIF_PARTITION_IMAGE BIF_COMMON_ATTR"
do_create_bif[depends] += "${@get_bootbin_depends(d)}"

def get_bootbin_depends(d):
    bootbindeps = ""
    bifpartition = (d.getVar("BIF_PARTITION_ATTR", True) or "").split()
    attrdepends = d.getVarFlags("BIF_PARTITION_DEPENDS") or {}
    for cfg in bifpartition:
        if cfg in attrdepends:
            bootbindeps = bootbindeps + " " + attrdepends[cfg] + ":do_deploy"

    return bootbindeps

do_xilinx_bootbin[depends] += "${@get_bootbin_depends(d)}"

do_xilinx_bootbin () {
    cd ${WORKDIR}
    rm -f BOOT.bin
    bootgen -image ${BIF_FILE_PATH} -arch ${KMACHINE} -w -o BOOT.bin
    if [ ! -e BOOT.bin ]; then
        bbfatal "bootgen failed. See log"
    fi
    install -m 0644 BOOT.bin  ${DEPLOY_DIR_IMAGE}/BOOT.bin
}
addtask do_xilinx_bootbin before do_image
