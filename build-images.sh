#!/bin/bash

# 定义默认值或初始化变量
TAG=""
OUTPUT_FILE=""
VERBOSE=false

# 使用 getopt 解析命令行参数
TEMP=$(getopt --longoptions tag:,output:,verbose --options "" --name "$0" -- "$@")

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

while true; do
  case "$1" in
    --tag )
      TAG="$2"
      shift 2
      ;;
    --output )
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --verbose )
      VERBOSE=true
      shift
      ;;
    -- )
      shift
      break
      ;;
    * )
      break
      ;;
  esac
done

echo "Tag provided: $TAG"
echo "Output file: $OUTPUT_FILE"
echo "Verbose mode: $VERBOSE"

ROOT_DIR="build/images"
for dir in "$ROOT_DIR"/*/; do
    # Find Dockerfile or *.dockerfile in a case-insensitive manner
    dockerfile=$(find "$dir" -maxdepth 1 -type f \( -iname 'dockerfile' -o -iname '*.dockerfile' \) | head -n 1)

    if [ -n "$dockerfile" ] && [ -f "$dockerfile" ]; then
        IMAGE_NAME=$(basename "$dir")
        echo "Building Docker image $dockerfile for $IMAGE_NAME with tags: $TAG"

        # Initialize arguments
        build_args=()
        build_args+=(--tag "$OUTPUT_FILE/$IMAGE_NAME:$TAG")
        if [ $VERBOSE == true ]; then
            build_args+=(--push)
        fi
        build_args+=(.)
        echo "Building Args: ${build_args[*]}"

        # Build and push the Docker image with all tags
        docker buildx build --platform linux/amd64 --file "$dockerfile" "${build_args[@]}"

    else
        echo "No valid Dockerfile found in $dir"
    fi
done
