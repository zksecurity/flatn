LIBS = $(PWD)/libs

$(LIBS)/omp:
	rm -rf openmp-19.1.6.src
	tar -xf deps/openmp-19.1.6.src.tar.xz
	mkdir -p $(LIBS)
	cd openmp-19.1.6.src \
		&& mkdir build \
		&& cd build \
		&& cmake .. \
		&& make -j
	rm -rf openmp-19.1.6.src

$(LIBS)/gmp:
	rm -rf gmp-6.3.0
	tar -xf deps/gmp-6.3.0.tar.xz
	mkdir -p $(LIBS)
	cd gmp-6.3.0 \
		&& ./configure --prefix $(LIBS)/gmp \
		&& make -j \
		&& make -j check \
		&& make install
	rm -rf gmp-6.3.0

$(LIBS)/mpfr: $(LIBS)/gmp
	rm -rf mpfr-4.2.1
	tar -xf deps/mpfr-4.2.1.tar.gz
	mkdir -p $(LIBS)
	cd mpfr-4.2.1 \
		&& ./configure --with-gmp=$(LIBS)/gmp --prefix $(LIBS)/mpfr \
		&& make -j \
		&& make -j check \
		&& make install
	rm -rf mpfr-4.2.1

$(LIBS)/fplll: $(LIBS)/gmp $(LIBS)/mpfr
	rm -rf fplll-5.3.2
	tar -xf deps/fplll-5.3.2.tar.gz
	cd fplll-5.3.2 \
		&& ./configure --with-gmp=$(LIBS)/gmp --with-mpfr=$(LIBS)/mpfr --prefix $(LIBS)/fplll \
		&& make -j \
		&& make -j check \
		&& make install
	rm -rf fplll-5.3.2

flatter-darwin libflatter.dylib: $(LIBS)/fplll $(LIBS)/gmp $(LIBS)/mpfr
	# untar the flatter source code
	rm -rf flatter
	mkdir flatter
	tar -xf deps/flatter.tar.gz --strip-components=1 -C flatter
	# build the flatter library
	cd flatter \
			&& mkdir build \
			&& cd build \
			&& CMAKE_INCLUDE_PATH=$(LIBS)/gmp/include:$(LIBS)/mpfr/include:$(LIBS)/fplll/include \
									CMAKE_LIBRARY_PATH=$(LIBS)/gmp/lib:$(LIBS)/mpfr/lib:$(LIBS)/fplll/lib \
											cmake .. \
		-DOpenMP_CXX_FLAGS="-Xpreprocessor -fopenmp -I/opt/homebrew/opt/libomp/include" \
		-DOpenMP_CXX_LIB_NAMES="omp" \
		-DOpenMP_omp_LIBRARY="/opt/homebrew/opt/libomp/lib/libomp.dylib" \
		-DCMAKE_PREFIX_PATH=$(LIBS)/gmp:$(LIBS)/mpfr:$(LIBS)/fplll \
		-DCMAKE_CXX_FLAGS="-I$(LIBS)/gmp/include -I$(LIBS)/mpfr/include -I$(LIBS)/fplll/include" \
			&& make -j

	# copy the library and the executable to the root directory
	cp flatter/build/lib/libflatter.dylib .
	cp flatter/build/bin/flatter flatter-darwin

	# a quick test
	echo "[[1 0 331 303]\n[0 1 456 225]\n[0 0 628 0]\n[0 0 0 628]]" | DYLD_LIBRARY_PATH=. ./flatter-darwin

flatter-linux libflatter.so:
	rm -rf flatter
	mkdir flatter
	tar -xf deps/flatter.tar.gz --strip-components=1 -C flatter

	# build the flatter library
	cd flatter \
		&& mkdir build \
		&& cd build \
		&& cmake .. \
		&& make -j

	# copy the library and the executable to the root directory
	cp flatter/build/lib/libflatter.so .
	cp flatter/build/bin/flatter flatter-linux

 	# a quick test
	echo "[[1 0 331 303]\n[0 1 456 225]\n[0 0 628 0]\n[0 0 0 628]]" | LD_PRELOAD=. ./flatter-linux

darwin: flatter-darwin libflatter.dylib

linux: flatter-linux libflatter.so

clean:
	rm -rf libs
	rm -rf gmp-6.3.0
	rm -rf mpfr-4.2.1
	rm -rf fplll-5.3.2
	rm -f flatter-darwin flatter-linux
	rm -f libflatter.dylib libflatter.so
	rm -rf dist
	rm -rf build
	rm -rf *.egg-info/
	rm -rf *.whl
	rm -f flatn/flatter*
	rm -f flatn/libflatter*

.PHONY: all clean darwin linux
