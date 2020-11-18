#!/bin/sh
set -e

# Based on https://github.com/szanni/ios-autotools
usage () {
  echo "Usage: [VARIABLE...] $(basename $0) architecture [configure_parameters...]"
  echo ""
  echo "  architecture           Target architecture. [arm64|arm64e|x86_64]"
  echo "  configure_parameters   Params passed to configure script."
  echo ""
  echo "    CFLAGS CPPFLAGS CXXFLAGS LDFLAGS PKG_CONFIG_PATH"
  exit 1
}

# Sanity checks
if [ "$#" -lt 1 ]; then
  echo "Please supply an architecture name."
  usage
fi

if [ ! -x "./configure" ] ; then
  echo "No configure script found."
  usage
fi

# Export build ARCH
export ARCH=$1

# Export CHOST deduced by ARCH
case $ARCH in
arm64 )
  export CHOST='aarch64-apple-darwin*'
  ;;
arm64e )
  export CHOST='aarch64e-apple-darwin*'
  ;;
x86_64 )
  export CHOST='x86_64-apple-darwin*'
  ;;
* )
  echo "Invalid architecture name: $ARCH."
  usage
;;
esac

# Export SDK deduced by ARCH
case $ARCH in
arm64 | arm64e )
  export SDK=iphoneos
  ;;
x86_64 )
  export SDK=iphonesimulator
  ;;
* )
  echo "Invalid architecture name: $ARCH."
  usage
;;
esac

# Export supplied PREFIX or use default
if [ ! -z "$PREFIX" ]; then
  export PREFIX
else
  export PREFIX="$PWD/$ARCH"
fi

# Export use system default SDK
export SDKVERSION="$(xcrun --sdk $SDK --show-sdk-version)"
export SDKROOT="$(xcrun --sdk $SDK --show-sdk-path)"

# Binaries
export CC="$(xcrun --sdk $SDK --find gcc)"
export CPP="$(xcrun --sdk $SDK --find gcc) -E"
export CXX="$(xcrun --sdk $SDK --find g++)"
export LD="$(xcrun --sdk $SDK --find ld)"
export AR="$(xcrun --sdk $SDK --find ar)"
export RANLIB="$(xcrun --sdk $SDK --find ranlib)"
export NM="$(xcrun --sdk $SDK --find nm)"
export STRIP="$(xcrun --sdk $SDK --find strip)"

# Flags
export CFLAGS="$CFLAGS -arch $ARCH -isysroot $SDKROOT -miphoneos-version-min=12.0 -fembed-bitcode"
export CPPFLAGS="$CPPFLAGS -arch $ARCH -isysroot $SDKROOT -miphoneos-version-min=12.0 -fembed-bitcode"
export CXXFLAGS="$CXXFLAGS -arch $ARCH -isysroot $SDKROOT"
export LDFLAGS="$LDFLAGS -arch $ARCH -isysroot $SDKROOT"
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$SDKROOT/usr/lib/pkgconfig"

# Remove script parameters
shift 1

# Print configuration
echo "$(tput smul)Env variables:$(tput rmul)"
echo ""
echo "  ARCH:            $ARCH"
echo "  CHOST:           $CHOST"
echo "  SDK:             $SDK"
echo "  SDKVERSION:      $SDKVERSION"
echo "  SDKROOT:         $SDKROOT"
echo ""
echo "  CC:              $CC"
echo "  CPP:             $CPP"
echo "  CXX:             $CXX"
echo "  LD:              $LD"
echo "  AR:              $AR"
echo "  RANLIB:          $RANLIB"
echo "  NM:              $NM"
echo "  STRIP:           $STRIP"
echo ""
echo "  CFLAGS:          $CFLAGS"
echo "  CPPFLAGS:        $CPPFLAGS"
echo "  CXXFLAGS:        $CXXFLAGS"
echo "  LDFLAGS:         $LDFLAGS"
echo "  PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
echo ""
echo "$(tput smul)Configure parameters:$(tput rmul)"
echo ""
echo "  $@"
echo ""

# Run configure
./configure --prefix="$PREFIX" --host="$CHOST" $@
