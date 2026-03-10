#!/bin/bash
# UCX Build and Logging Guide
# This script demonstrates how to compile UCX with enhanced communication device logging

set -e

echo "========================================"
echo "UCX Communication Logging Setup Guide"
echo "========================================"
echo ""

# Configuration
UCX_SOURCE_DIR="${1:-.}"
BUILD_DIR="${UCX_SOURCE_DIR}/build"
INSTALL_DIR="${UCX_SOURCE_DIR}/install"

echo "Source Directory: $UCX_SOURCE_DIR"
echo "Build Directory: $BUILD_DIR"
echo "Install Directory: $INSTALL_DIR"
echo ""

# Check if source directory exists
if [ ! -f "$UCX_SOURCE_DIR/configure.ac" ]; then
    echo "Error: UCX source not found in $UCX_SOURCE_DIR"
    exit 1
fi

# Create build directory
if [ ! -d "$BUILD_DIR" ]; then
    echo "Creating build directory..."
    mkdir -p "$BUILD_DIR"
fi

# Run autogen if needed
if [ ! -f "$UCX_SOURCE_DIR/configure" ]; then
    echo "Running autogen.sh..."
    cd "$UCX_SOURCE_DIR"
    ./autogen.sh
    cd -
fi

# Configure UCX
echo ""
echo "Configuring UCX..."
cd "$BUILD_DIR"
"$UCX_SOURCE_DIR/configure" \
    --prefix="$INSTALL_DIR" \
    --enable-debug \
    --disable-optimizations \
    --with-ucx-version="1.0-enhanced-logging"

# Build
echo ""
echo "Building UCX (this may take a while)..."
make -j$(nproc)

# Install
echo ""
echo "Installing UCX..."
make install

echo ""
echo "========================================"
echo "UCX Installation Complete!"
echo "========================================"
echo ""
echo "Installation Summary:"
echo "  - Installation path: $INSTALL_DIR"
echo "  - Include files: $INSTALL_DIR/include"
echo "  - Library files: $INSTALL_DIR/lib"
echo ""
echo "To use the enhanced logging:"
echo ""
echo "1. Set environment variables:"
echo "   export UCX_LOG_LEVEL=info"
echo "   export LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH"
echo "   export PATH=$INSTALL_DIR/bin:\$PATH"
echo ""
echo "2. Run any UCX application:"
echo "   Your application will now show detailed communication device information"
echo ""
echo "Example: Check available transports"
echo "   $INSTALL_DIR/bin/ucx_info -f -v"
echo ""
echo "3. View detailed logs:"
echo "   export UCX_DEBUG_LOG_FILE=ucx.log"
echo "   Your application will write detailed logs to ucx.log"
echo ""
