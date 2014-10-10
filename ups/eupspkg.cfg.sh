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

	./bootstrap.sh --without-libraries=mpi --prefix="$PREFIX" $WITH_TOOLSET
}

build()
{
	set +e
	c++ -o ups/test_cpp11.o -std=c++11 ups/trivial.cc 2>/dev/null
	if (( $? == 0 )); then
		cxx11flags="-std=c++11"
	else
		cxx11flags="-std=c++0x"
	fi
	c++ -o ups/test_warn_deprecated_register.o $cxx11flags -Wno-deprecated-register ups/trivial.cc 2>/dev/null
	if (( $? == 0 )); then
		cxx11flags="$cxx11flags -Wno-deprecated-register"
	fi
	set -e
	echo "Building boost with cxxflags=\"$cxx11flags\""

	./b2 -j $NJOBS cxxflags="\"$cxx11flags\""
}

install()
{
	clean_old_install

	./b2 -j $NJOBS install

	install_ups
}
