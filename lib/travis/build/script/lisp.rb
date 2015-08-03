require 'tempfile'

module Travis
  module Build
    class Script
      class Lisp < Script
        DEFAULTS = {
          lisp: 'sbcl'
        }

        ROS_URL = "https://raw.githubusercontent.com/snmsts/roswell/release/scripts/install-for-ci.sh"

        def configure
          super
          sh.cmd 'sudo apt-get update'
          sh.cmd 'sudo apt-get install libc6:i386 libc6-dev libc6-dev-i386 libffi-dev libffi-dev:i386'
          sh.fold('roswell-install') do
            sh.echo "Installing roswell..."
            sh.export "LISP", lisp_impl
            sh.cmd "curl -sL #{ROS_URL} | /bin/sh"
          end
        end

        def export
          super
          sh.export 'LISP', lisp_impl
        end

        def announce
          super
          sh.cmd 'ros version'
          sh.cmd 'ros -e "(format t \"Lisp Version: ~a -- ~a~%\" ' +
                 '(lisp-implementation-type) ' +
                 '(lisp-implementation-version))"'
        end

        def script
          # There isn't a standard way to test lisp code
          # so fail the build unless a script was provided.
          # maybe at some point we can provide config for popular
          # testing frameworks like fiveam and prove
          sh.failure "No script provided."
        end

        private

        def lisp_impl
          config[:lisp]
        end

      end
    end
  end
end
