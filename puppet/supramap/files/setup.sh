SUPRAMAP_HOME=/opt/supramap/app
mkdir -p $SUPRAMAP_HOME/log

RUBY_ROOT=$SUPRAMAP_HOME/ruby

export GEM_HOME=$SUPRAMAP_HOME/ruby/.gems
export GEM_INSTALL=$SUPRAMAP_HOME/ruby/gems
export PATH=$PATH:$GEM_INSTALL/bin
export PATH=$GEM_HOME/bin:$PATH

export RUBYLIB=/usr/local/lib/ruby:$GEM_INSTALL/lib
export RUBYOPT="rubygems"

export RUBY_HOME=$RUBY_ROOT/ruby-2.0.0-p0
export PATH=$RUBY_HOME/bin:$PATH

# http://www.ruby-lang.org/en/downloads/
# ./configure --prefix=/home/scox/dev/poy/ruby/ruby-2.0.0-p0 --with-openssl-include=/usr/include/openssl

# http://stackoverflow.com/questions/4262616/ruby-1-9-2-blows-up-with-json-gem-dependency
# gem update --system; gem pristine --all

