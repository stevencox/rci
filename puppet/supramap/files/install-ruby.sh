#!/bin/bash

set -e
set -x

script_home=$1
source $script_home/setup.sh

if [ -f $SUPRAMAP_HOME/setup.sh ]; then
    echo Looks like supramap is alrady installed.
    exit 0
fi
cp $script_home/setup.sh $SUPRAMAP_HOME


mkdir -p $RUBY_ROOT

install_ruby () {
    cd $RUBY_ROOT
    wget http://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p0.tar.gz
    tar xvzf ruby-2.0.0-p0.tar.gz
    cd ruby-2.0.0-p0
    ./configure --prefix=$RUBY_HOME
    make
    make install
}

install_gems () {
    cd $RUBY_ROOT
    wget http://rubyforge.org/frs/download.php/76729/rubygems-1.8.25.tgz
    tar xvzf rubygems-1.8.25.tgz
    cd rubygems-1.8.25
    ruby setup.rb --prefix=$GEM_INSTALL
}

install_ruby > $SUPRAMAP_HOME/log/ruby-install.log
install_gems > $SUPRAMAP_HOME/log/rubygems-install.log

exit 0
