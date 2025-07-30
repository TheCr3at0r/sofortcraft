DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/utils.sh"

run_vanilla(){
  local VERSION="$2"
  local TARGET_DIR="$3"

  parse_flags "$@"

  PORT="${PORT:-25565}"
  MEMORY="${MEMORY:-1G}"

  if [[ -z "$VERSION" || -z "$TARGET_DIR" ]]; then
      echo "Usage: sofortcraft -v <version> <target>" >&2
      exit 0
  fi

  mkdir -p "$TARGET_DIR"
  cd "$TARGET_DIR"

  MANIFEST_URL="https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"
  VERSION_URL=$(curl -s "$MANIFEST_URL" | jq -r --arg VER "$VERSION" '.versions[] | select(.id == $VER) | .url')

  if [[ -z "$VERSION_URL" ]]; then
      echo "Error: Version $VERSION not found."
      exit 1
  fi

  SERVER_JAR_URL=$(curl -s "$VERSION_URL" | jq -r '.downloads.server.url')

  if [[ -z "$SERVER_JAR_URL" ]]; then
      echo "Error: No server JAR found for version $VERSION"
      exit 1
  fi

  JAR_NAME="minecraft_server.$VERSION.jar"
  if [[ ! -f "$JAR_NAME" ]]; then
      echo "Downloading server $VERSION..."
      curl -L "$SERVER_JAR_URL" -o "$JAR_NAME"
  fi

  echo "eula=true" > eula.txt

  JAVA_IMAGE=$(get_java_image_for_mc_version "$VERSION")
  echo "Using Docker image: $JAVA_IMAGE"

  JAVA_HEAP=$(calculate_java_heap "$MEMORY")
  echo "Using memory: Docker limit = $MEMORY, Java heap = $JAVA_HEAP"
  echo "Using port: $PORT"

  echo "Starting Minecraft $VERSION in Docker..."
  docker run -dit \
      --name "minecraft-$VERSION" \
      -p "$PORT":25565 \
      -v "$PWD":/data \
      -e EULA=TRUE \
      -w /data \
      --memory "$MEMORY" \
      --restart unless-stopped \
      "$JAVA_IMAGE" \
      java -Xmx$JAVA_HEAP -Xms$JAVA_HEAP -jar "$JAR_NAME" nogui

  exit 0
}

