require 'tempfile'

module Travis
  module Build
    class Script
      class Lisp < Script
        DEFAULTS = {
          lisp: 'sbcl'
        }

        CIM_URL = "https://raw.githubusercontent.com/KeenS/CIM/master/scripts/cim_installer"
        CIM_HOME = "$HOME/cim"

        QL_URL = "https://beta.quicklisp.org/quicklisp.lisp"
        ASDF_URL= "https://common-lisp.net/project/asdf/asdf.lisp"
        ASDF_CONF_DIR = "$HOME/.config/common-lisp/source-registry.d"
        ASDF_CONF_FILE = ASDF_CONF_DIR + "/travis.conf"

        SYSTEM_MISSING = 'No test system or test script provided. ' +
                         'Please either override the script: key ' +
                         'or use the system: key to set a test (asdf) system.'

        def export
          super
          sh.export 'CIM_HOME', CIM_HOME
          sh.cmd "export PATH=$PATH:$CIM_HOME/bin"
        end

        def setup
          super
          install_cim
          install_implementation config[:lisp]
          install_asdf
          install_quicklisp
        end

        def script
          if config.has_key?(:system)
            system_keyword = ":" + config[:system]
            sh.cmd "cl -e '(ql:quickload #{system_keyword})' "\
                   "-e (unless (asdf:test-system #{system_keyword}) " +
                   "(uiop:quit 1))"
          else
            sh.failure SYSTEM_MISSING
          end
        end

        def announce
          super
          sh.cmd 'echo -n CIM version: '
          sh.cmd 'cl --version'
          sh.cmd 'cl -e "(format t \"~a: ~a~%\" ' +
                 '(lisp-implementation-type) ' +
                 '(lisp-implementation-version))"'
        end

        private
        def install_cim
          sh.echo "Installing CIM..."
          sh.export "CIM_HOME", CIM_HOME
          sh.cmd "curl -sL #{CIM_URL} | /bin/sh"
          sh.cmd ". $CIM_HOME/init.sh"
          sh.cmd "export PATH=$PATH:$CIM_HOME/bin"
        end

        def install_implementation(lisp_impl)
          sh.echo "Installing #{lisp_impl}..."
          sh.cmd "cim install #{lisp_impl}"
          sh.cmd "cim use #{lisp_impl} --default"
        end

        def install_quicklisp
          sh.echo "Installing quicklisp..."
          sh.cmd "curl -sL #{QL_URL}"
          sh.cmd 'cl -f quicklisp.lisp -e "(quicklisp-quickstart:install :path \"$CIM_HOME/quicklisp\")"'\
                 ' -e "(ql:add-to-init-file)"'
        end

        def install_asdf
          sh.echo "Installing asdf..."
          sh.cmd "curl -sL #{ASDF_URL}"
          sh.cmd 'echo "(load \"$HOME/asdf.lisp\")" >> $CIM_HOME/init.lisp'
          sh.echo "Compile asdf..."
          sh.cmd 'cl -c $HOME/asdf.lisp -Q'
          config_asdf
        end

        def config_asdf
          sh.mkdir ASDF_CONF_DIR, recursive: true
          sh.cmd 'echo "(:tree \"$TRAVIS_BUILD_DIR\")" >> ' + ASDF_CONF_FILE
          sh.cmd 'echo "(:tree \"$HOME/lisp\")" >> ' + ASDF_CONF_FILE
        end

      end
    end
  end
end
