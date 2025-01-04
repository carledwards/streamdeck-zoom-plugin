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

# Package the Stream Deck plugin
package: install
	@echo "Packaging Stream Deck plugin..."
	@if [ ! -d "build/dist" ]; then \
		echo "Error: build/dist directory not found. Did the install succeed?"; \
		exit 1; \
	fi
	@echo "Creating plugin package with correct directory structure..."
	@cd build && \
	rm -rf com.lostdomain.zoom.sdPlugin && \
	mkdir -p com.lostdomain.zoom.sdPlugin && \
	cp -R dist/* com.lostdomain.zoom.sdPlugin/ && \
	zip -r com.lostdomain.zoom.streamDeckPlugin com.lostdomain.zoom.sdPlugin && \
	echo "Created Stream Deck plugin package: build/com.lostdomain.zoom.streamDeckPlugin"

# Help target
help:
	@echo "Available targets:"
	@echo "  make          : Build the project (default)"
	@echo "  make clean    : Remove build artifacts"
	@echo "  make rebuild  : Clean and rebuild project"
	@echo "  make install  : Install the plugin"
	@echo "  make package  : Create Stream Deck plugin package"
	@echo "  make help     : Show this help message"
