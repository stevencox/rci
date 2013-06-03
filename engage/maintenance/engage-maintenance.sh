#!/bin/bash

# create a work directory in a place the site asks us to use
function create_work_dir()
{
    unset TMPDIR
    TARGETS="$OSG_WN_TMP $OSG_DATA/engage/tmp /tmp"
    echo "Possible targets for WORK_DIR: $TARGETS"
    for DER in $TARGETS; do
        echo "Trying to create workdir: $DER"
        WORK_DIR=`/bin/mktemp -d -p $DER job.XXXXXXXXXX`
        if [ $? = 0 ]; then
            echo "Created workdir: $DER"
            export WORK_DIR
            return 0
        fi
        echo "Failed to create workdir: $DER"
    done
    return 1
}


function install_software()
{
    # assumption: OSG_APP is writable, and WORK_DIR has been defined

    # java 1.5
    echo
    echo "Checking to see if we need to install Java 1.5"
    cd $OSG_APP
    if [ -e "engage/jdk1.5.0_09/bin/java" ]; then
        echo "Java15 exists"
    else
        echo "Installing..."
        mkdir -p engage
        cd engage
        rm -rf jdk1.5*
        wget -nv http://engage-central.renci.org/software/jdk1.5.0_09.tar.gz
        tar xzfm jdk1.5.0_09.tar.gz
        rm -f jdk1.5.0_09.tar.gz
    fi
    
    # java 1.6.0_16
    #echo
    #echo "Checking to see if we need to install Java 1.6.0_16"
    #cd $OSG_APP
    #if [ -e "engage/jdk1.6.0_16/bin/java" ]; then
    #    echo "Java 1.6.0_16 exists"
    #else
    #    echo "Installing..."
    #    mkdir -p engage
    #    cd engage
    #    rm -rf jdk1.6.0_16*
    #    wget -nv http://engage-central.renci.org/~osgmm/software/jdk1.6.0_16.tar.gz
    #    tar xzfm jdk1.6.0_16.tar.gz
    #    rm -f jdk1.6.0_16.tar.gz
    #fi

#    # java 1.6.0_03
#    echo
#    echo "Checking to see if we need to install Java 1.6.0_03"
#    cd $OSG_APP
#    if [ -e "engage/jdk1.6.0_03/bin/java" ]; then
#        echo "Java 1.6.0_03 exists"
#    else
#        echo "Installing..."
#        mkdir -p engage
#        cd engage
#        rm -rf jdk1.6.0_03*
#        wget -nv http://engage-central.renci.org/software/jdk1.6.0_03.tar.gz
#        tar xzfm jdk1.6.0_03.tar.gz
#        rm -f jdk1.6.0_03.tar.gz
#    fi

    # java 1.6.0_25
    echo
    echo "Checking to see if we need to install Java 1.6.0_25"
    cd $OSG_APP
    if [ -e "engage/jdk1.6.0_25/bin/java" ]; then
        echo "Java 1.6.0_25 exists"
    else
        echo "Installing..."
        mkdir -p engage
        cd engage
        rm -rf jdk1.6.0_25*
        wget -nv http://engage-central.renci.org/software/jdk1.6.0_25.tar.gz
        tar xzfm jdk1.6.0_25.tar.gz
        rm -f jdk1.6.0_25.tar.gz
    fi
    
#    # stanford parser
#    echo
#    echo "Checking to see if we need to install Stanford Parser"
#    SOFTWARE_STANFORD_PARSER="FALSE"
#    cd $OSG_APP
#    if [ -e "engage/blake" ]; then
#        echo "engage/blake exists"
#    else
#        mkdir -p engage/blake
#    fi
#    cd engage/blake
#    if [ -e "stanford-parser-2007-08-19.9/parse.sh" ]; then
#        echo "Stanford Parser already installed"
#    else
#        echo "Installing..."
#        rm -rf stanford-parser-*
#        sleep 5s
#        wget -nv http://www.renci.org/~rynge/osg/blake/stanford-parser-2007-08-19.tar.gz
#        tar xzfm stanford-parser-2007-08-19.tar.gz
#        rm -f stanford-parser-2007-08-19.tar.gz
#        
#        # current version
#        mv stanford-parser-2007-08-19 stanford-parser-2007-08-19.9
#    fi
#
#    # rosetta
#    echo
#    echo "Checking to see if we need to install Rosetta"
#    SOFTWARE_ROSETTA="FALSE"
#    cd $OSG_APP
#    if [ -e "engage/rosetta" ]; then
#        echo "engage/rosetta exists"
#    else
#        mkdir -p engage/rosetta
#    fi
#    cd engage/rosetta
#    if [ -e "rosetta.3/rosetta.gcc" ]; then
#        echo "Rosetta already installed"
#    else
#        echo "Installing..."
#        rm -rf rosetta*
#        mkdir rosetta.3
#        cd rosetta.3
#        sleep 5s
#
#        # db
#        wget -nv http://www.renci.org/~rynge/osg/rosetta/rosetta_database.tar.gz
#        tar xzfm rosetta_database.tar.gz
#        rm -f rosetta_database.tar.gz
#
#        # app
#        wget -nv http://www.renci.org/~rynge/osg/rosetta/rosetta.gcc.gz
#        gunzip rosetta.gcc.gz
#        chmod 755 rosetta.gcc
#        touch rosetta.gcc
#    fi

    
    # blast
    #echo
    #echo "Checking and installing blast..."
    #cd $WORK_DIR
    #rm -f install-blast
    #wget -nv http://engage-central.renci.org/~osgmm/software/blast/install-blast
    #chmod 755 install-blast
    #./install-blast
    
    # pegasus
#    cd $WORK_DIR
#    wget -nv http://engage-central.renci.org/software/pegasus.sh
#    chmod 755 pegasus.sh
#    ./pegasus.sh
#    rm -f pegasus.sh

    cd $OSG_APP
    echo Checking to see if we need to install the pegasus worker...
    if [ -e engage/pegasus-3.0.3 ]; then
	echo "   Already present."
    else
        echo "   Installing the pegasus worker."
	mkdir -p engage
	cd engage
        wget -nv http://pegasus.isi.edu/wms/download/3.0/pegasus-worker-3.0.3-x86_64_rhel_5.tar.gz
        tar xvzf pegasus-worker-3.0.3-x86_64_rhel_5.tar.gz
        rm -f pegasus-worker-3.0.3-x86_64_rhel_5.tar.gz
    fi

    # LSST
    #echo
    #echo "Checking and installing LSST software ..."
    #cd $WORK_DIR
    #rm -f install-lsst
    #wget -nv http://engage-central.renci.org/~osgmm/software/install-lsst
    #chmod 755 install-lsst
    #./install-lsst
  
    # Clean up software area due to script problem.
    for i in $OSG_APP/engage/LSST/*/raytrace; do
        rm -rv $i/chip_*.{out,err} 2>/dev/null && echo "Removed erroneously-placed LSST application output files from OSG_APP area $i" 1>&2
    done

    # EIC (Electron Ion Collider)
    echo
    echo "Checking and installing EIC software ..."
    cd $OSG_APP
    mkdir -p engage/EIC
    cd engage/EIC
    rm -f install-eic
    wget -nv http://engage-central.renci.org/software/install-eic
    chmod 755 install-eic
    ./install-eic
    rm -f ./install-eic

    # SLAC Phenomenology Group
    echo
    echo "Checking and installing SLAC pheno software ..."
    if cd $OSG_APP && mkdir -p engage/pheno && cd engage/pheno
    then	
       rm -f install-tar
       if wget -nv http://engage-central.renci.org/software/install-tar
       then
         chmod 755 install-tar
         ./install-tar combined_dirsB.tgz gsiftp://engage-submit3.renci.org:2811//home/mslyz/phenoA 'engage/pheno' combined_dirsB
         rm -f ./install-tar
       fi
    fi




    # UNC Environmental Science and Engineering
    echo
    echo "Checking and installing UNC ES&E data ..."
    rm -rf $OSG_APP/engage/uncese
    if cd $OSG_DATA && mkdir -p $OSG_DATA/engage/uncese && cd engage/uncese
    then
	wget --timestamping --no-check-certificate https://engage-submit3.renci.org/pub/input.tar.gz
    fi	   





    cd $OSG_APP
    echo Checking to see if we need to install Python...
    python_version=2.7.1
    python_home=$OSG_APP/engage/Python-${python_version}
    #rm -rf ${python_home}

    rm -rf $OSG_APP/engage/Python-*

  function python_later () {
    if [ -e ${python_home} ]; then
	echo "   Already present."
    else

	set -x

        echo "   Installing Python."
	mkdir -p engage
	cd engage

	rm -rf Python-*.tar.gz*

        wget --quiet http://www.renci.org/~scox/bin/Python-${python_version}.tgz
        tar xvzf Python-${python_version}.tgz
        cd Python*
        ./configure --prefix=${python_home} --enable-shared
        make
        make install

	pwd

	ln -s python python2.7

	cd $OSG_APP/engage

        # Create Python init script
        echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${python_home}/lib" >  engage-python.sh
        echo "export PATH=${python_home}:\$PATH"                           >> engage-python.sh

	# Set up Python path
	source ./engage-python.sh

        # Install easy_install and virtualenv
	rm -rf setuptools-*
        
        wget --quiet http://pypi.python.org/packages/2.7/s/setuptools/setuptools-0.6c11-py2.7.egg#md5=fe1f997bc722265116870bc7919059ea
        sh setuptools-*

	easy_install virtualenv

        echo "echo initializing python virtualenv \$1"                           >> engage-python.sh
        echo "virtualenv \$1"                                               >> engage-python.sh

    fi
   }

}

#############################################################################
#
#  install software


if touch $OSG_APP/engage/.verified; then

    # make sure we have a minimal system path
    export PATH=/usr/local/bin:/usr/bin:/bin

    # create a work directory we can reuse for our builds
    if create_work_dir; then
        install_software
        rm -rf $WORK_DIR
    fi

else
    echo "WARNING: Could not install any software because OSG_APP is not writable"
fi


