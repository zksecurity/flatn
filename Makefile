LIBS = libs
LIBS_PATH = $(PWD)/$(LIBS)
DEPS = deps

$(LIBS)/omp:
	rm -rf _omp_build
	mkdir -p _omp_build
	cd _omp_build \
		&& tar -xf ../deps/openmp-19.1.7.src.tar.xz \
		&& tar -xf ../deps/cmake-19.1.7.src.tar.xz \
		&& mkdir -p $(LIBS_PATH) \
		&& mv openmp-19.1.7.src src \
		&& mv cmake-19.1.7.src cmake \
		&& mkdir -p build/static \
		&& cd build/static \
		&& cmake ../../src \
			-DLIBOMP_ENABLE_SHARED=OFF \
			-DLIBOMP_INSTALL_ALIASES=OFF \
			-DOPENMP_ENABLE_LIBOMPTARGET=OFF \
			-DCMAKE_INSTALL_PREFIX=$(LIBS_PATH)/omp \
			-DCMAKE_BINARY_DIR=$(LIBS_PATH)/omp \
		&& make -j \
		&& make install
	rm -rf _omp_build

$(LIBS)/gmp:
	rm -rf gmp-6.3.0
	tar -xf deps/gmp-6.3.0.tar.xz
	mkdir -p $(LIBS_PATH)
	cd gmp-6.3.0 \
		&& ./configure --enable-static --disable-shared --prefix $(LIBS_PATH)/gmp \
		&& make -j \
		&& make -j check \
		&& make install
	rm -rf gmp-6.3.0

$(LIBS)/mpfr: $(LIBS)/gmp
	rm -rf mpfr-4.2.1
	tar -xf deps/mpfr-4.2.1.tar.gz
	mkdir -p $(LIBS_PATH)
	cd mpfr-4.2.1 \
		&& ./configure --enable-static --disable-shared --with-gmp=$(LIBS_PATH)/gmp --prefix $(LIBS_PATH)/mpfr \
		&& make -j \
		&& make -j check \
		&& make install
	rm -rf mpfr-4.2.1

$(LIBS)/fplll: $(LIBS)/gmp $(LIBS)/mpfr
	rm -rf fplll-5.5.0.tar.gz
	tar -xf deps/fplll-5.5.0.tar.gz
	mkdir -p $(LIBS_PATH)
	cd fplll-5.5.0 \
		&& CXXFLAGS="-w -Wno-overloaded-virtual" ./configure --enable-static --disable-shared --with-gmp=$(LIBS_PATH)/gmp --with-mpfr=$(LIBS_PATH)/mpfr --prefix $(LIBS_PATH)/fplll \
		&& make -j CXXFLAGS="-w -Wno-overloaded-virtual" \
		&& make -j check \
		&& make install
	rm -rf fplll-5.5.0

$(LIBS)/openblas:
	rm -rf OpenBLAS-0.3.29
	tar -xf deps/OpenBLAS-0.3.29.tar.gz
	mkdir -p $(LIBS_PATH)
	cd OpenBLAS-0.3.29 \
		&& make DYNAMIC_ARCH=1 NO_SHARED=1 USE_THREAD=1 PREFIX=$(LIBS_PATH)/openblas -j \
		&& make install PREFIX=$(LIBS_PATH)/openblas
	rm -rf OpenBLAS-0.3.29

flatter-darwin libflatter.dylib: $(LIBS)/fplll $(LIBS)/gmp $(LIBS)/mpfr $(LIBS)/omp
	# untar the flatter source code
	rm -rf flatter
	mkdir flatter
	tar -xf deps/flatter.tar.gz --strip-components=1 -C flatter

	# build the flatter library
	cd flatter \
    	&& mkdir build \
    	&& cd build \
        && CMAKE_INCLUDE_PATH=$(LIBS_PATH)/gmp/include:$(LIBS_PATH)/mpfr/include:$(LIBS_PATH)/fplll/include:$(LIBS_PATH)/omp/include \
           CMAKE_LIBRARY_PATH=$(LIBS_PATH)/gmp/lib:$(LIBS_PATH)/mpfr/lib:$(LIBS_PATH)/fplll/lib:$(LIBS_PATH)/omp/lib \
           cmake .. \
            -DCMAKE_CXX_COMPILER=/usr/bin/clang++ \
            -DOpenMP_CXX_FLAGS="-Xpreprocessor -fopenmp" \
            -DOpenMP_CXX_LIB_NAMES="omp" \
            -DOpenMP_omp_LIBRARY="$(LIBS_PATH)/omp/lib/libomp.a" \
            -DCMAKE_PREFIX_PATH=$(LIBS_PATH)/gmp:$(LIBS_PATH)/mpfr:$(LIBS_PATH)/fplll:$(LIBS_PATH)/omp \
            -DCMAKE_CXX_FLAGS="-I$(LIBS_PATH)/gmp/include -I$(LIBS_PATH)/mpfr/include -I$(LIBS_PATH)/fplll/include -I$(LIBS_PATH)/omp/include -Wno-overloaded-virtual -Wno-error=overloaded-virtual" \
            -DBUILD_SHARED_LIBS=OFF \
            -DCMAKE_FIND_LIBRARY_SUFFIXES=".a;.dylib" \
        && make -j

	# copy the library and the executable to the root directory
	cp flatter/build/lib/libflatter.dylib .
	cp flatter/build/bin/flatter flatter-darwin

	# a quick test
	echo "[[1 0 331 303]\n[0 1 456 225]\n[0 0 628 0]\n[0 0 0 628]]" | DYLD_LIBRARY_PATH=. ./flatter-darwin

flatter-linux libflatter.so: $(LIBS)/fplll $(LIBS)/gmp $(LIBS)/mpfr $(LIBS)/omp $(LIBS)/openblas
	rm -rf flatter
	mkdir flatter
	tar -xf deps/flatter.tar.gz --strip-components=1 -C flatter

	cd flatter \
		&& mkdir build \
		&& cd build \
		&& cmake .. \
			-DCMAKE_PREFIX_PATH=$(LIBS_PATH)/gmp:$(LIBS_PATH)/mpfr:$(LIBS_PATH)/fplll:$(LIBS_PATH)/omp:$(LIBS_PATH)/openblas \
			-DCMAKE_CXX_FLAGS="-I$(LIBS_PATH)/gmp/include -I$(LIBS_PATH)/mpfr/include -I$(LIBS_PATH)/fplll/include -I$(LIBS_PATH)/omp/include" \
			-DBLA_VENDOR=OpenBLAS \
			-DBLAS_LIBRARIES=$(LIBS_PATH)/openblas/lib/libopenblas.a \
		&& make -j

	cp flatter/build/lib/libflatter.so .
	cp flatter/build/bin/flatter flatter-linux

	echo "[[1 0 331 303]\n[0 1 456 225]\n[0 0 628 0]\n[0 0 0 628]]" | LD_LIBRARY_PATH=. ./flatter-linux

darwin: flatter-darwin libflatter.dylib

linux: flatter-linux libflatter.so

clean:
	rm -rf libs
	rm -rf gmp-6.3.0
	rm -rf mpfr-4.2.1
	rm -rf fplll-5.3.2
	rm -rf openmp-19.1.7.src
	rm -rf cmake-19.1.7.src
	rm -f flatter-darwin flatter-linux
	rm -f libflatter.dylib libflatter.so
	rm -rf dist
	rm -rf build
	rm -rf *.egg-info/
	rm -rf *.whl
	rm -f flatn/flatter*
	rm -f flatn/libflatter*

.PHONY: all clean darwin linux
