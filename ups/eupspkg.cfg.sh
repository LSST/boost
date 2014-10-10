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
		cxxstring_str="-std=c++11"
	else
		cxxstring_str="-std=c++0x"
	fi
	c++ -o ups/test_warn_deprecated_register.o $cxxstring_str -Wno-deprecated-register ups/trivial.cc 2>/dev/null
	if (( $? == 0 )); then
		cxxstring_str="$cxxstring_str -Wno-deprecated-register"
	fi
	set -e
	# double quotes are required if there are spaces in cxxstring_str
	cxxstring_str = "\"$cxxstring_str"\"
	echo "Building boost with cxxflags=$cxxstring_str"

	./b2 -j $NJOBS cxxflags=$cxxstring_str
}

install()
{
	clean_old_install

	./b2 -j $NJOBS install

	install_ups
}
