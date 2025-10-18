
#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
BRIDGES_ROOT="/Users/mere/git/evm-lisa/datasets/cross-chain/smartaxe/manually-labeled"
DOCKER_IMAGE_TAG="v1.2.1"
DOCKER_IMAGE_NAME="merendamattia/crosschain-policy-agent:${DOCKER_IMAGE_TAG}"
OUTPUT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/outputs/generated-policies-${DOCKER_IMAGE_TAG}"
ENV_FILE=".env"
CLIENT="google"  # "openai" or "google"
# -----------------------------

# Set DRY_RUN=1 to only print commands instead of executing them
DRY_RUN=0
# Delay (seconds) between operations to avoid API rate limits / too many operations per minute
DELAY_SECONDS=150
# -----------------------------

log() { printf "[%s] %s\n" "$(date --iso-8601=seconds 2>/dev/null || date)" "$*"; }

if [[ -z "$BRIDGES_ROOT" || ! -d "$BRIDGES_ROOT" ]]; then
	echo "ERROR: please set BRIDGES_ROOT to an existing directory inside this script." >&2
	exit 2
fi

mkdir -p "$OUTPUT_ROOT"

command -v docker >/dev/null 2>&1 || { echo "ERROR: docker not found. Install Docker." >&2; exit 4; }

log "Bridges root: $BRIDGES_ROOT"
log "Output root: $OUTPUT_ROOT"

# Decide env-file usage (ENV_FILE can be left empty to skip)
if [[ -n "$ENV_FILE" && ! -f "$ENV_FILE" ]]; then
	echo "ERROR: ENV_FILE is set but file does not exist: $ENV_FILE" >&2
	exit 5
fi

# Pull docker image from Docker Hub
log "Pulling Docker image: $DOCKER_IMAGE_NAME"
if [[ $DRY_RUN -eq 1 ]]; then
	echo "DRY-RUN: docker pull $DOCKER_IMAGE_NAME"
else
	docker pull "$DOCKER_IMAGE_NAME"
fi

shopt -s nullglob
COUNT=0
for entry in "$BRIDGES_ROOT"/*; do
	if [[ -d "$entry" ]]; then
		src_dir="$entry/source-code"
		if [[ ! -d "$src_dir" ]]; then
			log "Skipping $(basename "$entry"): no source-code/ directory found"
			continue
		fi

		sol_files=("$src_dir"/*.sol)
		if [[ ${#sol_files[@]} -eq 0 ]]; then
			log "Skipping $(basename "$entry"): no .sol files found in source-code/"
			continue
		fi

		bridge_name="$(basename "$entry")"
		out_dir="$OUTPUT_ROOT"
		mkdir -p "$out_dir"
		out_file="$out_dir/${bridge_name}.policy.json"

		docker_cmd=(docker run --rm)
		if [[ -n "$ENV_FILE" ]]; then
			docker_cmd+=(--env-file "$ENV_FILE")
		fi
	docker_cmd+=(-v "$src_dir:/data/sol:ro")
		docker_cmd+=(-v "$out_dir:/app/output")
		docker_cmd+=("$DOCKER_IMAGE_NAME")
		docker_cmd+=(--target-path /data/sol --output-file /app/output/"${bridge_name}.policy.json")
		docker_cmd+=(--client "$CLIENT")

		log "Processing bridge: $bridge_name"
		log " Source: $entry"
		log " Output: $out_file"

		if [[ $DRY_RUN -eq 1 ]]; then
			printf "DRY-RUN: %s\n" "${docker_cmd[*]}"
		else
			log "Running: ${docker_cmd[*]}"
			"${docker_cmd[@]}"
			rc=$?
			if [[ $rc -ne 0 ]]; then
				echo "WARNING: docker run for $bridge_name exited with code $rc" >&2
			else
				log "Generated: $out_file"
			fi

				# Sleep between per-bridge runs to limit operations/minute
				if [[ $DRY_RUN -eq 0 && $DELAY_SECONDS -gt 0 ]]; then
					log "Sleeping ${DELAY_SECONDS}s before next operation"
					sleep "$DELAY_SECONDS"
				fi
		fi

		COUNT=$((COUNT+1))
	fi
done

if [[ $COUNT -eq 0 ]]; then
	echo "ERROR: no bridges processed. Ensure $BRIDGES_ROOT contains subfolders with .sol files" >&2
	exit 6
fi

log "Done. $COUNT bridges processed. Output in: $OUTPUT_ROOT"

