DEPS = deps
LIBS = libs
LIBS_PATH = $(PWD)/$(LIBS)

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
		&& if [ "$(shell uname -o 2>/dev/null)" = "Msys" ] || [[ "$(shell uname)" == MINGW* ]] || [[ "$(shell uname)" == MSYS* ]]; then \
			cmake ../../src \
				-G "MSYS Makefiles" \
				-DLIBOMP_ENABLE_SHARED=OFF \
				-DLIBOMP_INSTALL_ALIASES=OFF \
				-DOPENMP_ENABLE_LIBOMPTARGET=OFF \
				-DCMAKE_INSTALL_PREFIX=$(LIBS_PATH)/omp \
				-DCMAKE_BINARY_DIR=$(LIBS_PATH)/omp \
				-DCMAKE_POSITION_INDEPENDENT_CODE=ON; \
		else \
			cmake ../../src \
				-DLIBOMP_ENABLE_SHARED=OFF \
				-DLIBOMP_INSTALL_ALIASES=OFF \
				-DOPENMP_ENABLE_LIBOMPTARGET=OFF \
				-DCMAKE_INSTALL_PREFIX=$(LIBS_PATH)/omp \
				-DCMAKE_BINARY_DIR=$(LIBS_PATH)/omp \
				-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
				-DCMAKE_CXX_FLAGS="-fPIC" \
				-DCMAKE_C_FLAGS="-fPIC"; \
		fi \
		&& make -j \
		&& make install
	rm -rf _omp_build

$(LIBS)/gmp:
	rm -rf gmp-6.3.0
	tar -xf deps/gmp-6.3.0.tar.xz
	mkdir -p $(LIBS_PATH)
	cd gmp-6.3.0 \
		&& if [ "$(shell uname -o 2>/dev/null)" = "Msys" ] || [[ "$(shell uname)" == MINGW* ]] || [[ "$(shell uname)" == MSYS* ]]; then \
			./configure --enable-static --disable-shared --prefix $(LIBS_PATH)/gmp \
				--build=x86_64-w64-mingw32 --host=x86_64-w64-mingw32; \
		else \
			./configure --enable-static --disable-shared --prefix $(LIBS_PATH)/gmp \
				CFLAGS="-fPIC" \
				ABI=64; \
		fi \
		&& make -j \
		&& make -j check \
		&& make install
	rm -rf gmp-6.3.0

$(LIBS)/mpfr: $(LIBS)/gmp
	rm -rf mpfr-4.2.1
	tar -xf deps/mpfr-4.2.1.tar.gz
	mkdir -p $(LIBS_PATH)
	cd mpfr-4.2.1 \
		&& if [ "$(shell uname -o 2>/dev/null)" = "Msys" ] || [[ "$(shell uname)" == MINGW* ]] || [[ "$(shell uname)" == MSYS* ]]; then \
			./configure --enable-static --disable-shared --with-gmp=$(LIBS_PATH)/gmp --prefix $(LIBS_PATH)/mpfr \
				--build=x86_64-w64-mingw32 --host=x86_64-w64-mingw32; \
		else \
			./configure --enable-static --disable-shared --with-gmp=$(LIBS_PATH)/gmp --prefix $(LIBS_PATH)/mpfr CFLAGS="-fPIC"; \
		fi \
		&& make -j \
		&& make -j check \
		&& make install
	rm -rf mpfr-4.2.1

$(LIBS)/fplll: $(LIBS)/gmp $(LIBS)/mpfr
	rm -rf fplll-5.5.0.tar.gz
	tar -xf deps/fplll-5.5.0.tar.gz
	mkdir -p $(LIBS_PATH)
	cd fplll-5.5.0 \
		&& if [ "$(shell uname -o 2>/dev/null)" = "Msys" ] || [[ "$(shell uname)" == MINGW* ]] || [[ "$(shell uname)" == MSYS* ]]; then \
			CXXFLAGS="-w -Wno-overloaded-virtual" ./configure --enable-static --disable-shared --with-gmp=$(LIBS_PATH)/gmp --with-mpfr=$(LIBS_PATH)/mpfr --prefix $(LIBS_PATH)/fplll \
				--build=x86_64-w64-mingw32 --host=x86_64-w64-mingw32; \
		else \
			CXXFLAGS="-w -Wno-overloaded-virtual -fPIC" ./configure --enable-static --disable-shared --with-gmp=$(LIBS_PATH)/gmp --with-mpfr=$(LIBS_PATH)/mpfr --prefix $(LIBS_PATH)/fplll; \
		fi \
		&& if [ "$(shell uname -o 2>/dev/null)" = "Msys" ] || [[ "$(shell uname)" == MINGW* ]] || [[ "$(shell uname)" == MSYS* ]]; then \
			make -j CXXFLAGS="-w -Wno-overloaded-virtual -static"; \
		else \
			make -j CXXFLAGS="-w -Wno-overloaded-virtual -static -fPIC"; \
		fi \
		&& make -j check \
		&& make install
	rm -rf fplll-5.5.0

$(LIBS)/openblas:
	rm -rf OpenBLAS-0.3.29
	tar -xf deps/OpenBLAS-0.3.29.tar.gz
	mkdir -p $(LIBS_PATH)
	cd OpenBLAS-0.3.29 \
		&& if [ "$(shell uname -o 2>/dev/null)" = "Msys" ] || [[ "$(shell uname)" == MINGW* ]] || [[ "$(shell uname)" == MSYS* ]]; then \
			make DYNAMIC_ARCH=1 USE_THREAD=1 NO_SHARED=1 BINARY=64 PREFIX=$(LIBS_PATH)/openblas TARGET=GENERIC -j; \
		else \
			make DYNAMIC_ARCH=1 USE_THREAD=1 NO_SHARED=1 FC=gfortran BINARY=64 PREFIX=$(LIBS_PATH)/openblas -j; \
		fi \
		&& make NO_SHARED=1 PREFIX=$(LIBS_PATH)/openblas install
	rm -rf OpenBLAS-0.3.29

flatter-darwin: $(LIBS)/fplll $(LIBS)/gmp $(LIBS)/mpfr $(LIBS)/omp
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
			-DCMAKE_CXX_FLAGS="-I$(LIBS_PATH)/gmp/include -I$(LIBS_PATH)/mpfr/include -I$(LIBS_PATH)/fplll/include -I$(LIBS_PATH)/omp/include -Wno-overloaded-virtual -Wno-error=overloaded-virtual -fPIC" \
			-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
			-DBUILD_SHARED_LIBS=OFF \
			-DGMP_LIBRARIES="$(LIBS_PATH)/gmp/lib/libgmp.a" \
			-DMPFR_LIBRARIES="$(LIBS_PATH)/mpfr/lib/libmpfr.a" \
			-DFPLLL_LIBRARIES="$(LIBS_PATH)/fplll/lib/libfplll.a" \
		&& make VERBOSE=1

	# Create a list of unique object files with full paths
	cd flatter/build && \
		find `pwd`/src/CMakeFiles/flatter.dir -name "*.o" | sort -u > obj_files.txt

	# Manual linking step with unique object files
	/usr/bin/clang++ \
		-o flatter-darwin \
		flatter/build/apps/CMakeFiles/flatter_bin.dir/flatter.cpp.o \
		`cat flatter/build/obj_files.txt` \
		$(LIBS_PATH)/fplll/lib/libfplll.a \
		$(LIBS_PATH)/mpfr/lib/libmpfr.a \
		$(LIBS_PATH)/gmp/lib/libgmp.a \
		$(LIBS_PATH)/omp/lib/libomp.a \
		-framework Accelerate \
		-lpthread -ldl -lm \
		-Xpreprocessor -fopenmp

	# clean up
	rm -rf flatter

	# a quick test
	echo "[[1 0 331 303]\n[0 1 456 225]\n[0 0 628 0]\n[0 0 0 628]]" | ./flatter-darwin

flatter-linux: $(LIBS)/fplll $(LIBS)/gmp $(LIBS)/mpfr $(LIBS)/omp $(LIBS)/openblas
	rm -rf flatter
	mkdir flatter
	tar -xf deps/flatter.tar.gz --strip-components=1 -C flatter

	# First build flatter as a static library
	cd flatter \
		&& rm -rf build \
		&& mkdir build \
		&& cd build \
		&& CXXFLAGS="-fPIC" CFLAGS="-fPIC" cmake .. \
			-DCMAKE_BUILD_TYPE=Release \
			-DOpenMP_CXX_FLAGS="-fopenmp" \
			-DOpenMP_CXX_LIB_NAMES="omp" \
			-DBLA_VENDOR=OpenBLAS \
			-DBLAS_LIBRARIES=$(LIBS_PATH)/openblas/lib/libopenblas.a \
			-DLAPACK_LIBRARIES=$(LIBS_PATH)/openblas/lib/libopenblas.a \
			-DOpenMP_omp_LIBRARY="$(LIBS_PATH)/omp/lib/libomp.a" \
			-DCMAKE_PREFIX_PATH=$(LIBS_PATH)/gmp:$(LIBS_PATH)/mpfr:$(LIBS_PATH)/fplll:$(LIBS_PATH)/omp:$(LIBS_PATH)/openblas \
			-DCMAKE_CXX_FLAGS="-I$(LIBS_PATH)/gmp/include -I$(LIBS_PATH)/mpfr/include -I$(LIBS_PATH)/fplll/include -I$(LIBS_PATH)/omp/include -I$(LIBS_PATH)/openblas/include -Wno-overloaded-virtual -Wno-error=overloaded-virtual -fPIC" \
			-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
			-DBUILD_SHARED_LIBS=OFF \
			-DGMP_LIBRARIES="$(LIBS_PATH)/gmp/lib/libgmp.a" \
			-DMPFR_LIBRARIES="$(LIBS_PATH)/mpfr/lib/libmpfr.a" \
			-DMPFR_INCLUDES="$(LIBS_PATH)/mpfr/include" \
			-DFPLLL_LIBRARIES="$(LIBS_PATH)/fplll/lib/libfplll.a" \
			-DFPLLL_INCLUDE_DIR="$(LIBS_PATH)/fplll/include" \
			-DFPLLL_LIBRARY="$(LIBS_PATH)/fplll/lib/libfplll.a" \
			-DFPLLL_INCLUDE_DIRS="$(LIBS_PATH)/fplll/include" \
			-DCMAKE_CXX_STANDARD_LIBRARIES="-static-libgcc -static-libstdc++" \
			-DBLAS_ROOT=$(LIBS_PATH)/openblas \
			-DLAPACK_ROOT=$(LIBS_PATH)/openblas \
		&& make VERBOSE=1

	# Create a list of unique object files with full paths
	cd flatter/build && \
		find `pwd`/src/CMakeFiles/flatter.dir -name "*.o" | sort -u > obj_files.txt

	# Manual linking step with unique object files
	$(CXX) \
		-o flatter-linux \
		flatter/build/apps/CMakeFiles/flatter_bin.dir/flatter.cpp.o \
		`cat flatter/build/obj_files.txt` \
		$(LIBS_PATH)/openblas/lib/libopenblas.a \
		$(LIBS_PATH)/fplll/lib/libfplll.a \
		$(LIBS_PATH)/mpfr/lib/libmpfr.a \
		$(LIBS_PATH)/gmp/lib/libgmp.a \
		$(LIBS_PATH)/omp/lib/libomp.a \
		-static-libgcc -static-libstdc++ \
		-lpthread -ldl -lm -fopenmp \
		$(LIBS_PATH)/gmp/lib/libgmp.a

	# clean up
	rm -rf flatter

	# a quick test
	echo "[[1 0 331 303]\n[0 1 456 225]\n[0 0 628 0]\n[0 0 0 628]]" | ./flatter-linux

flatter-windows: $(LIBS)/fplll $(LIBS)/gmp $(LIBS)/mpfr $(LIBS)/omp $(LIBS)/openblas
	rm -rf flatter
	mkdir flatter
	tar -xf deps/flatter.tar.gz --strip-components=1 -C flatter

	# Build the flatter library for Windows with MSYS2/MinGW-w64
	cd flatter \
		&& rm -rf build \
		&& mkdir build \
		&& cd build \
		&& CXXFLAGS="-fPIC" CFLAGS="-fPIC" cmake .. \
			-G "MSYS Makefiles" \
			-DCMAKE_BUILD_TYPE=Release \
			-DOpenMP_CXX_FLAGS="-fopenmp" \
			-DOpenMP_CXX_LIB_NAMES="omp" \
			-DBLA_VENDOR=OpenBLAS \
			-DBLAS_LIBRARIES=$(LIBS_PATH)/openblas/lib/libopenblas.a \
			-DLAPACK_LIBRARIES=$(LIBS_PATH)/openblas/lib/libopenblas.a \
			-DOpenMP_omp_LIBRARY="$(LIBS_PATH)/omp/lib/libomp.a" \
			-DCMAKE_PREFIX_PATH=$(LIBS_PATH)/gmp:$(LIBS_PATH)/mpfr:$(LIBS_PATH)/fplll:$(LIBS_PATH)/omp:$(LIBS_PATH)/openblas \
			-DCMAKE_CXX_FLAGS="-I$(LIBS_PATH)/gmp/include -I$(LIBS_PATH)/mpfr/include -I$(LIBS_PATH)/fplll/include -I$(LIBS_PATH)/omp/include -I$(LIBS_PATH)/openblas/include -Wno-overloaded-virtual -Wno-error=overloaded-virtual -fPIC" \
			-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
			-DBUILD_SHARED_LIBS=OFF \
			-DGMP_LIBRARIES="$(LIBS_PATH)/gmp/lib/libgmp.a" \
			-DMPFR_LIBRARIES="$(LIBS_PATH)/mpfr/lib/libmpfr.a" \
			-DMPFR_INCLUDES="$(LIBS_PATH)/mpfr/include" \
			-DFPLLL_LIBRARIES="$(LIBS_PATH)/fplll/lib/libfplll.a" \
			-DFPLLL_INCLUDE_DIR="$(LIBS_PATH)/fplll/include" \
			-DFPLLL_LIBRARY="$(LIBS_PATH)/fplll/lib/libfplll.a" \
			-DFPLLL_INCLUDE_DIRS="$(LIBS_PATH)/fplll/include" \
			-DCMAKE_CXX_STANDARD_LIBRARIES="-static-libgcc -static-libstdc++" \
			-DBLAS_ROOT=$(LIBS_PATH)/openblas \
			-DLAPACK_ROOT=$(LIBS_PATH)/openblas \
		&& make VERBOSE=1

	# Create a list of unique object files with full paths
	cd flatter/build && \
		find `pwd`/src/CMakeFiles/flatter.dir -name "*.o" | sort -u > obj_files.txt

	# Manual linking step with unique object files
	$(CXX) \
		-o flatter-windows.exe \
		flatter/build/apps/CMakeFiles/flatter_bin.dir/flatter.cpp.o \
		`cat flatter/build/obj_files.txt` \
		$(LIBS_PATH)/openblas/lib/libopenblas.a \
		$(LIBS_PATH)/fplll/lib/libfplll.a \
		$(LIBS_PATH)/mpfr/lib/libmpfr.a \
		$(LIBS_PATH)/gmp/lib/libgmp.a \
		$(LIBS_PATH)/omp/lib/libomp.a \
		-static-libgcc -static-libstdc++ \
		-lpthread -lm -fopenmp \
		$(LIBS_PATH)/gmp/lib/libgmp.a

	# clean up
	rm -rf flatter

	# a quick test
	echo "[[1 0 331 303]\n[0 1 456 225]\n[0 0 628 0]\n[0 0 0 628]]" | ./flatter-windows.exe

darwin: flatter-darwin

linux: flatter-linux

windows: flatter-windows

clean:
	rm -rf libs
	rm -rf gmp-*
	rm -rf mpfr-*
	rm -rf fplll-*
	rm -rf openmp-*
	rm -rf cmake-*
	rm -rf OpenBLAS-*
	rm -rf flatter
	rm -f flatter-darwin flatter-linux flatter-windows.exe
	rm -f libflatter.dylib libflatter.so
	rm -rf dist
	rm -rf build
	rm -rf *.egg-info/
	rm -rf *.whl
	rm -f flatn/flatter*
	rm -f flatn/libflatter*
	rm -f flatn/*.exe

.PHONY: all clean darwin linux windows
