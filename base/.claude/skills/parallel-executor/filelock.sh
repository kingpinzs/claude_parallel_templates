#!/bin/bash
# File locking utilities for atomic session state updates
# Usage: source filelock.sh

# Default lock timeout in seconds
LOCK_TIMEOUT=${LOCK_TIMEOUT:-10}

# Atomically update a JSON file with jq
# Args: $1=file_path, $2...=jq arguments
# Uses flock for exclusive access
atomic_jq_update() {
    local file_path="$1"
    shift  # Remove file_path from arguments

    if [[ ! -f "$file_path" ]]; then
        echo "Error: File not found: $file_path" >&2
        return 1
    fi

    local lock_file="${file_path}.lock"
    local temp_file=$(mktemp)
    local result=0

    # Use flock for exclusive access
    (
        # Wait for lock with timeout
        if ! flock -w "$LOCK_TIMEOUT" 200; then
            echo "Error: Could not acquire lock for $file_path after ${LOCK_TIMEOUT}s" >&2
            rm -f "$temp_file"
            exit 1
        fi

        # Perform the jq operation
        if jq "$@" "$file_path" > "$temp_file" 2>/dev/null; then
            # Validate JSON before replacing
            if jq -e . "$temp_file" > /dev/null 2>&1; then
                mv "$temp_file" "$file_path"
            else
                echo "Error: jq produced invalid JSON for $file_path" >&2
                rm -f "$temp_file"
                exit 1
            fi
        else
            echo "Error: jq operation failed for $file_path" >&2
            rm -f "$temp_file"
            exit 1
        fi

    ) 200>"$lock_file"

    result=$?
    rm -f "$lock_file"
    return $result
}

# Read a JSON file with shared lock (allows concurrent reads)
# Args: $1=file_path, $2...=jq arguments (optional)
atomic_jq_read() {
    local file_path="$1"
    shift

    if [[ ! -f "$file_path" ]]; then
        echo "null"
        return 0
    fi

    local lock_file="${file_path}.lock"

    (
        # Shared lock for reading
        if ! flock -s -w "$LOCK_TIMEOUT" 200; then
            echo "Error: Could not acquire read lock for $file_path" >&2
            exit 1
        fi

        if [[ $# -eq 0 ]]; then
            cat "$file_path"
        else
            jq "$@" "$file_path"
        fi

    ) 200>"$lock_file"

    local result=$?
    rm -f "$lock_file"
    return $result
}

# Safe file write with exclusive lock
# Args: $1=file_path, stdin=content
atomic_write() {
    local file_path="$1"
    local lock_file="${file_path}.lock"
    local temp_file=$(mktemp)

    # Read content from stdin
    cat > "$temp_file"

    (
        if ! flock -w "$LOCK_TIMEOUT" 200; then
            echo "Error: Could not acquire lock for $file_path" >&2
            rm -f "$temp_file"
            exit 1
        fi

        mv "$temp_file" "$file_path"

    ) 200>"$lock_file"

    local result=$?
    rm -f "$lock_file"
    return $result
}

# Check if flock is available
check_flock() {
    if ! command -v flock &> /dev/null; then
        echo "Warning: flock not available, file locking disabled" >&2
        return 1
    fi
    return 0
}
