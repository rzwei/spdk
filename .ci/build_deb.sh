#!/bin/bash -xe
# :vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4
# The script to (re)build SPDK DEB (Ubuntu) packags
# from the checked out source tree (spdk subdir)

# branch=$(git name-rev --name-only --refs *nvda* HEAD | awk -F/ '{print $NF}')
branch=$(git name-rev --name-only HEAD | awk -F/ '{print $NF}')
sha1=$(git rev-parse HEAD |cut -c -8)
BASEDIR=$(dirname $(readlink -f $0))
ODIR=$(readlink -f $BASEDIR/../)

if [ -z "$VER" ] ; then
    export VER=$(echo $branch | grep -o '[0-9]\+\(\.[0-9]\+\)*')
fi 

function pack_dist()
{
    git submodule init
    git submodule update
    test -n "$VER"
    set -x
    for mod in $(git submodule |awk '{print $2}') ; do
        (cd $mod;
          git archive \
                --format=tar.gz --prefix=$mod/ -o $ODIR/spdk-$mod-$VER.tar.gz  HEAD
        )
    done

    git archive --format=tar --prefix=spdk-$VER/ -o $ODIR/spdk-$VER.tar  HEAD
#    mkdir -p spdk-$VER
#    cp -pvr debian .ci contrib spdk-$VER/ 
#    cp -pvr scripts/setup.py spdk-$VER/scripts
#    tar --append -f $ODIR/spdk-$VER.tar spdk-$VER/debian spdk-$VER/.ci spdk-$VER/scripts/setup.py spdk-$VER/contrib
    rm -f $ODIR/spdk-$VER.tar.gz
    gzip $ODIR/spdk-$VER.tar
    rm -rf spdk-$VER

    pushd scripts
    python3 setup.py sdist -d $ODIR/
    popd
}

function generate_changelog()
{
    today=$(date +"%a, %d %b %Y %T %z")
    sed -e "s/@PACKAGE_VERSION@/$VER/" -e "s/@PACKAGE_REVISION@/${BUILD_NUMBER:-1}/" \
        -e 's/@PACKAGE_BUGREPORT@/support@mellanox.com/' -e "s/@BUILD_DATE_CHANGELOG@/$today/" \
        debian/changelog.in > debian/changelog
}

function apply_dpdk_patch()
{
    $BASEDIR/dpdk_patch.sh
    patch -p0 < $BASEDIR/dpdk_conf.patch
    # patch -p1 < $BASEDIR/0001-nvmf-Corrupt-ddigest-in-every-32-th-C2H-PDU.patch
}


function unpack_dist()
{
  if [ -e ./spdk-$VER ]; then
      rm -rf ./spdk-$VER
  fi

  tar xf spdk-$VER.tar.gz

  SPDK_MODS=$(git submodule |awk '{print $2}')
  pushd spdk-$VER
  for MOD in $SPDK_MODS ; do
    tar xf ../spdk-$MOD-$VER.tar.gz
  done
  generate_changelog
  apply_dpdk_patch
  popd

  tar zcf ./spdk_$VER.orig.tar.gz spdk-$VER
}

function build_main()
{
  pushd spdk-$VER
  dpkg-buildpackage -uc -us -rfakeroot
  popd
}

pack_dist
unpack_dist
build_main
