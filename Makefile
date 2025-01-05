LIBS = $(PWD)/libs

gmp-6.3.0.tar.xz:
	wget https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz

mpfr-4.2.1.tar.gz:
	wget https://www.mpfr.org/mpfr-current/mpfr-4.2.1.tar.gz

fplll-5.3.2.tar.gz:
	wget https://github.com/fplll/fplll/releases/download/5.3.2/fplll-5.3.2.tar.gz

flatter.tar.gz:
	wget https://github.com/keeganryan/flatter/archive/c2ed0ee94b6d281df7bcbce31ca275197ef9a562.tar.gz
	mv c2ed0ee94b6d281df7bcbce31ca275197ef9a562.tar.gz flatter.tar.gz

openmp-19.1.6.src.tar.xz:
	wget https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.6/openmp-19.1.6.src.tar.xz

$(LIBS)/omp: openmp-19.1.6.src.tar.xz
	rm -rf openmp-19.1.6.src
	tar -xf openmp-19.1.6.src.tar.xz
	mkdir -p $(LIBS)
	cd openmp-19.1.6.src \
       && mkdir build \
       && cd build \
       && cmake .. \
       && make -j
	rm -rf openmp-19.1.6.src

$(LIBS)/gmp: gmp-6.3.0.tar.xz
	rm -rf gmp-6.3.0
	tar -xf gmp-6.3.0.tar.xz
	mkdir -p $(LIBS)
	cd gmp-6.3.0 \
	   && ./configure --prefix $(LIBS)/gmp \
	   && make -j \
	   && make -j check \
	   && make install
	rm -rf gmp-6.3.0

$(LIBS)/mpfr: mpfr-4.2.1.tar.gz $(LIBS)/gmp
	rm -rf mpfr-4.2.1
	tar -xf mpfr-4.2.1.tar.gz
	mkdir -p $(LIBS)
	cd mpfr-4.2.1 \
	   && ./configure --with-gmp=$(LIBS)/gmp --prefix $(LIBS)/mpfr \
	   && make -j \
	   && make -j check \
	   && make install
	rm -rf mpfr-4.2.1

$(LIBS)/fplll: fplll-5.3.2.tar.gz $(LIBS)/gmp $(LIBS)/mpfr
	rm -rf fplll-5.3.2
	tar -xf fplll-5.3.2.tar.gz
	cd fplll-5.3.2 \
	   && ./configure --with-gmp=$(LIBS)/gmp --with-mpfr=$(LIBS)/mpfr --prefix $(LIBS)/fplll \
	   && make -j \
	   && make -j check \
	   && make install
	rm -rf fplll-5.3.2

flatter-darwin libflatter.dylib: flatter.tar.gz $(LIBS)/fplll $(LIBS)/gmp $(LIBS)/mpfr
	rm -rf flatter-tmp
	mkdir flatter-tmp
	tar -xf flatter.tar.gz -C flatter-tmp --strip-components 1
	cd flatter-tmp \
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

	# copy the binary and the library
	cp flatter-tmp/build/bin/flatter flatter-darwin
	cp flatter-tmp/build/lib/libflatter.dylib .

	# a quick test
	echo "[[1 0 331 303]\n[0 1 456 225]\n[0 0 628 0]\n[0 0 0 628]]" | DYLD_LIBRARY_PATH=. ./flatter-darwin

flatter-linux libflatter.so: flatter.tar.gz $(LIBS)/fplll $(LIBS)/gmp $(LIBS)/mpfr $(LIBS)/omp
	rm -rf flatter-tmp
	mkdir flatter-tmp
	tar -xf flatter.tar.gz -C flatter-tmp --strip-components 1
	cd flatter-tmp \
	   && mkdir build \
       && cd build \
       && CMAKE_INCLUDE_PATH=$(LIBS)/gmp/include:$(LIBS)/mpfr/include:$(LIBS)/fplll/include \
          CMAKE_LIBRARY_PATH=$(LIBS)/gmp/lib:$(LIBS)/mpfr/lib:$(LIBS)/fplll/lib \
          cmake .. \
            -DCMAKE_PREFIX_PATH=$(LIBS)/gmp:$(LIBS)/mpfr:$(LIBS)/fplll \
            -DCMAKE_CXX_FLAGS="-I$(LIBS)/gmp/include -I$(LIBS)/mpfr/include -I$(LIBS)/fplll/include -fopenmp" \
       && make -j

	# copy the binary and the library
	cp flatter-tmp/build/bin/flatter flatter-linux
	cp flatter-tmp/build/lib/libflatter.so .

 	# a quick test
	echo "[[1 0 331 303]\n[0 1 456 225]\n[0 0 628 0]\n[0 0 0 628]]" | LD_PRELOAD=. ./flatter-linux

wheel-darwin: flatter-darwin libflatter.dylib setup.py pyproject.toml
	rm -rf pyflatter/bin
	mkdir -p pyflatter/bin
	cp libflatter.dylib pyflatter/bin
	cp flatter-darwin pyflatter/bin
	python -m build
	cp dist/*.whl .

clean:
	rm -rf libs
	rm -rf gmp-6.3.0
	rm -rf mpfr-4.2.1
	rm -rf fplll-5.3.2
	rm -rf flatter-tmp
	rm -f flatter-darwin flatter-linux
	rm -f libflatter.dylib libflatter.so
	rm -rf dist
	rm -rf *.egg-info/

.PHONY: all clean build-darwin
