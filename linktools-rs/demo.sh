#!/bin/bash
# Run linktools-rs tests and benchmarks

set -e

cd "$(dirname "$0")"

echo "Running tests..."
cargo test --lib
echo ""

echo "Running benchmarks..."
echo ""
echo "=== MAC Parsing ==="
cargo bench --quiet mac_parse 2>&1 | grep "time:" || true
echo ""
echo "=== OUI Lookup ==="
cargo bench --quiet oui_lookup 2>&1 | grep "time:" || true
echo ""
echo "=== Random MAC Generation ==="
cargo bench --quiet random 2>&1 | grep "time:" || true
echo ""
echo "Done."
