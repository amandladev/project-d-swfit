# Rust FFI Libraries

Place the compiled Rust static library and C header here:

- `libfinance_ffi.a` — Static library compiled for iOS Simulator (`aarch64-apple-ios-sim`)
- `finance_ffi.h` — C header file (already included as a template)

## Building the Rust library for iOS Simulator

From your Rust project directory:

```bash
# Add the iOS Simulator target
rustup target add aarch64-apple-ios-sim

# Build the static library
cargo build --release --target aarch64-apple-ios-sim

# Copy the output
cp target/aarch64-apple-ios-sim/release/libfinance_ffi.a /path/to/project-d-swift/libs/
```

## For a universal (device + simulator) build

```bash
# Add both targets
rustup target add aarch64-apple-ios
rustup target add aarch64-apple-ios-sim

# Build for device
cargo build --release --target aarch64-apple-ios

# Build for simulator
cargo build --release --target aarch64-apple-ios-sim

# Create universal library (optional)
lipo -create \
  target/aarch64-apple-ios/release/libfinance_ffi.a \
  target/aarch64-apple-ios-sim/release/libfinance_ffi.a \
  -output libs/libfinance_ffi.a
```
