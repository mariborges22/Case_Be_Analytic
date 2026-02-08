#!/bin/bash
# Check if tests exist for new files

echo "Checking for missing tests..."

# Check Silver Layer
if [ ! -f "tests/test_silver.py" ]; then
  echo "❌ Missing tests for Silver Layer (tests/test_silver.py)"
  exit 1
fi

echo "✅ Silver Layer tests found."
echo "All required tests are present."
exit 0
