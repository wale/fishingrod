# Initialise variables for later use.
set _rod_os ""
set _rod_distro ""
set _rod_host ""
set _rod_uptime ""

# Set the _rod_kernel output to uname -s.
set _rod_kernel (uname -s)
set _rod_kernel_ver (uname -r)

function _rod_get_os
    switch $_rod_kernel
        case "Linux*" "GNU*"
            if test -d /system/app && test -d /system/priv-app
                set _rod_os Android
            else
                set _rod_os Linux
            end
        case "SunOS"
            set _rod_os Solaris
        case "Haiku"
            set _rod_os Haiku
        case "Darwin"
            set _rod_os MacOS
        case "CYGWIN*" "MSYS*" "MINGW*"
            set _rod_os Windows
        case "*"
			printf "%s\n" "Unknown/unsupported OS detected: $_rod_kernel_name, aborting..."
            echo "Create an issue on GitHub for your operating system."
    end
end

function _rod_get_distro
    switch $_rod_os
        case Linux
            # You cannot exactly make a fetch tool efficient
            # if you have a case for EVERY distro, so instead
            # we take shortcuts, like with `lsb_release`.
            # Although exceptions are made for independent
            # distros that do *not* follow standards, as well
            # as Android.
            #
            # These checks are based on the methods that 
            # pfetch/neofetch utilises, just ported to Fish.
            if type -q lsb_release
                set _rod_distro (lsb_release -sd)
            else if test -f /etc/os-release
                # Fish does not respect the IFS variable anymore, so I
                # have to do something a little different (i.e. splitting
                # the string in two and parsing the result.)
                while read -l line
                    set kv (string split -m 1 = -- $line)
                    if contains PRETTY_NAME $kv[1]
                        set _rod_distro $kv[2]
                    end
                end </etc/os-release
            else
                # Special cases for distributions that do
                # not follow any (os|lsb_)release standards.
                if type -q crux
                    set _rod_distro (crux)
                else if type -q guix
                    set _rod_distro Guix
                end
            end

            # lsb_release and /etc/os-release tend to sometimes surround the string
            # in quotes, trim 'em.
            set _rod_distro (string trim --chars '"' $_rod_distro)

            # Check for Windows Linux Subsystem, and append a string accordingly.
            # WSL2 has the $WSLENV variable exported, while WSL1 has a custom
            # localversion with the -Microsoft string appended.
            if test -n "$WSLENV"
                set _rod_distro $_rod_distro "on Windows 10 (WSL2)"
            else if contains (uname -r) -Microsoft
                set _rod_distro $_rod_distro "on Windows 10 (WSL1)"
            end
        case Android
            set -g _rod_distro "Android " (getprop ro.build.version.release)
        case MacOS
            set -l macos_ver (sw_vers -productVersion)

            switch $macos_ver
                case "10.4"
                    set _rod_distro "Mac OS X Tiger"
                case "10.5"
                    set _rod_distro "Mac OS X Leopard"
                case "10.6"
                    set _rod_distro "Mac OS X Snow Leopard"
                case "10.7"
                    set _rod_distro "Mac OS X Lion"
                case "10.8"
                    set _rod_distro "OS X Mountain Lion"
                case "10.9"
                    set _rod_distro "OS X Mavericks"
                case "10.10"
                    set _rod_distro "OS X Yosemite"
                case "10.11"
                    set _rod_distro "OS X El Capitan"
                case "10.12"
                    set _rod_distro "macOS Sierra"
                case "10.13"
                    set _rod_distro "macOS High Sierra"
                case "10.14"
                    set _rod_distro "macOS Mojave"
                case "10.15"
                    set _rod_distro "macOS Catalina"
                case "11.1"
                    set _rod_distro "macOS Big Sur"
                case "*"
                    set _rod_distro macOS
            end
        case Haiku
            # Haiku uses 'uname -v' for version information
            # instead of 'uname -r' which only prints '1'.
            set _rod_distro (uname -sv)
        case "*"
            # Catch all to ensure '$distro' is never blank.
            set _rod_distro "$_rod_os $_rod_kernel"
        ;;
    end
end

function _rod_get_host
    switch $_rod_kernel
        case Linux
            # The files are playing tricks on us.
            # The names of the files don't always reflect the content.
            if test -d /system/app && test -d /system/priv-app
                set _rod_model_brand (getprop ro.product.brand)
                set _rod_model_name (getprop ro.product.model)
                set _rod_host "$_rod_model_brand $_rod_model_name"
            else if test -f /sys/devices/virtual/dmi/id/product_name && test -f /sys/devices/virtual/dmi/id/product_version
                read -l model_name < /sys/devices/virtual/dmi/id/product_name
                read -l model_version < /sys/devices/virtual/dmi/id/product_version
                set _rod_host "$model_name $model_version"
            else if test -f /sys/firmware/devicetree/base/model
                set _rod_host (cat /sys/firmware/devicetree/base/model)
            else if test -f /tmp/sysinfo/model
                set _rod_host (cat /tmp/sysinfo/model)
            end
        case Darwin
            set _rod_host (sysctl -n hw.model)
    end
    # todo: strip unwanted strings (e.g. 'to be filled by OEM')
end



function _rod_get_uptime
    switch $_rod_kernel
        case Linux
            set seconds +(math (cat /proc/uptime | cut -f1 -d " "))
            set days (math floor $seconds/3600/24)
            set _rod_uptime (date -ud "@$seconds" +"$daysd %Hh %Mm %Ss" | string trim)
    end
end

function _rod_format_output
    set _rod_user_info "$USER@$hostname"
    set_color -o magenta; echo $_rod_user_info
    set_color normal
    set_color -o blue; echo "host: "(set_color normal)$_rod_host
    set_color -o blue; echo "os: "(set_color normal)$_rod_os
    set_color -o blue; echo "distro: "(set_color normal)$_rod_distro
    set_color -o blue; echo "kernel: "(set_color normal)$_rod_kernel_ver
    set_color -o blue; echo "uptime: "(set_color normal)$_rod_uptime
end


function rod -d "System information tool"
    _rod_get_os
    _rod_get_distro
    _rod_get_host
    _rod_get_uptime
    _rod_format_output
end