# EupsPkg config file. Sourced by 'eupspkg'

config()
{
	detect_compiler

	# warn about non-clang builds on Macs
	if [[ "$(uname)" == "Darwin" && "$COMPILER_TYPE" != clang ]]; then
		warn "boost needs clang on OS X (you're compiling it with $COMPILER_TYPE. hope you know what you're doing."
	fi

	if [[ "$COMPILER_TYPE" == clang ]]; then
		WITH_TOOLSET="--with-toolset=clang"
	fi

        # Disable unicode regex support to make the binary more portable
	./bootstrap.sh --without-libraries=mpi --without-icu --prefix="$PREFIX" $WITH_TOOLSET

    # On Python 3 boost can not find the include directory if it uses an architecture
    # specifier such as 3.5m (PEP-3149). We therefore have to modify the config jam file
    # to add the include file as determined by asking python.
    PYTHON_VERSION=$(python -c 'import sys; print(sys.version_info.major)')
    if [ $PYTHON_VERSION -ne 2 ]; then
        export PYINCLUDE=$(python -c 'import distutils.sysconfig as s; print(s.get_python_inc())')
        perl -pi -e 's/using python (.*) ;/using python $1 : $ENV{PYINCLUDE} ;/' project-config.jam
    fi
}

build()
{
    # Check if the user has a user-config.jam, and warn
    if [[ -e $HOME/user-config.jam ]]; then
        echo "WARNING: a user-config.jam file has been detectedi\n"\
             "This can break the LSST boost build process"
    fi

	detect_compiler

	#
	# Try to find appropriate setting for CXX_CXX14_FLAG if not already set (to possibly empty value).
	# This duplicates code recently added to detect_compiler in eupspkg.sh; it is here temporarily as a
	# seatbelt to enable this build until we can be sure that eupspkg.sh has been updated from upstream.
	#
	# --** PLEASE REMOVE WHEN EUPS + EUPSPKG.SH ARE UPDATED FROM UPSTREAM **--
	#

	if [ -z "${CXX_CXX14_FLAG+1}" ] ; then
		local SCXX="$(mktemp -t comptest.XXXXX)".cxx
		echo "int main() { return 0; }" > "$SCXX"
		local OCXX=$(mktemp -t comptest.XXXXX)
		if   "$CXX1" "$SCXX" -std=c++14 -o "$OCXX" 2>/dev/null; then
			CXX_CXX14_FLAG="-std=c++14"
		elif   "$CXX1" "$SCXX" -std=c++11 -o "$OCXX" 2>/dev/null; then
			CXX_CXX14_FLAG="-std=c++11"
		elif "$CXX1" "$SCXX" -std=c++0x -o "$OCXX" 2>/dev/null; then
			CXX_CXX14_FLAG="-std=c++0x"
		else
			CXX_CXX14_FLAG=
		fi
	fi

	#
	# --** END PLEASE REMOVE **--
	#

	echo "Building boost with cxxflags=$CXX_CXX14_FLAG"

	./b2 -j $NJOBS cxxflags=$CXX_CXX14_FLAG

}

install()
{
	clean_old_install

	./b2 -j $NJOBS install

	install_ups
}
