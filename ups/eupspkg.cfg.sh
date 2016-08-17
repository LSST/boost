# EupsPkg config file. Sourced by 'eupspkg'

TAP_PACKAGE=1

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
	echo "Building boost with cxxflags=$CXX_CXX11_FLAG"

	./b2 -j $NJOBS cxxflags=$CXX_CXX11_FLAG
}

install()
{
	clean_old_install

	./b2 -j $NJOBS install

	install_ups

        if [[ $OSTYPE == darwin* && -f "$PREFIX"/lib/libboost_python.dylib ]]; then
            install_name_tool -change libpython2.7.dylib @rpath/libpython2.7.dylib "$PREFIX"/lib/libboost_python.dylib
        fi

}
