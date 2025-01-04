.PHONY: all clean build rebuild install

# Default target
all: build

# Create build directory
build/CMakeCache.txt:
	@mkdir -p build
	@cd build && cmake ..

# Build the project
build: build/CMakeCache.txt
	@echo "Building project..."
	@cd build && make

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf build/dist/

# Clean and rebuild
rebuild: clean build

# Install the plugin
install: build
	@echo "Installing plugin..."
	@cd build && make install

# Help target
help:
	@echo "Available targets:"
	@echo "  make          : Build the project (default)"
	@echo "  make clean    : Remove build artifacts"
	@echo "  make rebuild  : Clean and rebuild project"
	@echo "  make install  : Install the plugin"
	@echo "  make help     : Show this help message"
