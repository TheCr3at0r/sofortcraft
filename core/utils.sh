print_status() {
  echo "Minecraft containers:"
  docker ps -a --filter "name=minecraft-" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
}

show_logs() {
  local container="$2"
  
  check_container "$container"
  
  docker logs -f "$container"
}

attach_container() {
  local container="$2"

  check_container "$container"

  echo "Attaching to container '$container'..."
  echo "Press CTRL-P + CTRL-Q to detach without stopping the server."
  sleep 1

  docker attach "$container"
}

start_container() {
  local container="$2"

  check_container "$container"

  docker start "$container"
}

remove_container() {
  local container="$2"
  
  check_container "$container"

  docker stop "$container" && docker rm "$container"
}

set_property() {
  local container="$2"
  local key="$3"
  local value="$4"
  local file="/data/server.properties"
  
  check_container "$container"

  docker exec "$container" sh -c "
    [ -f '$file' ] || touch '$file'
    if grep -q '^$key=' '$file'; then
      sed -i \"s/^$key=.*/$key=$value/\" '$file'
    else
      echo '$key=$value' >> '$file'
    fi
  "
}

restart_container() {
  local container="$2"

  check_container "$container"

  docker restart "$container"
}

no_mode() {
    echo "sofortcraft v1.1.0"
    echo "Example usage:"
    echo "  sofortcraft --attach <container>"
    echo "  sofortcraft --logs <container>"
    echo "  sofortcraft --remove <container>"
    echo "  sofortcraft --restart <container>"
    echo "  sofortcraft --start <container>"
    echo "  sofortcraft --set-property <container> <property> <value>"
    echo "  sofortcraft --status"
    echo "  sofortcraft --vanilla <version> <target_dir> [OPTIONS]"

}

stringContain() { case $2 in *$1* ) return 0;; *) return 1;; esac ;}

find_arg_index() {
    local needle="$1"
    shift
    local i=0
    for arg in "$@"; do
        if [[ "$arg" == "$needle" ]]; then
            echo "$i"
            return 0
        fi
        ((i++))
    done
    echo "-1"
}

get_java_image_for_mc_version() {
  local ver="$1"

  # "1.20.5" is major=1, minor=20, patch=5
  major="${ver%%.*}"
  rest="${ver#*.}"
  minor="${rest%%.*}"
  patch="${rest#*.}"
  patch="${patch#*.}"

  # version --> Java 21
  # 1.20.5 > version --> Java 21
  # 1.17 <= version < 1.20.5 --> Java 17
  # < 1.17 --> Java 8

  if [[ "$major" -ge 2 ]]; then
    echo "eclipse-temurin:21"  # z. B. future 2.x Releases
  elif [[ "$major" -eq 1 && "$minor" -gt 20 ]]; then
    echo "eclipse-temurin:21"
  elif [[ "$major" -eq 1 && "$minor" -eq 20 && "$patch" -ge 5 ]]; then
    echo "eclipse-temurin:21"
  elif [[ "$major" -eq 1 && "$minor" -ge 17 ]]; then
    echo "openjdk:17"
  else
    echo "openjdk:8-jdk"
  fi
}

calculate_java_heap() {
    local mem="$1"
    # Convert G → M
    local unit="${mem: -1}"
    local value="${mem%?}"

    if [[ "$unit" =~ [gG] ]]; then
        echo "$((value * 75 / 100))G"
    elif [[ "$unit" =~ [mM] ]]; then
        echo "$((value * 75 / 100))M"
    else
        echo "Error: Invalid memory format: $mem" >&2
        exit 1
    fi
}

parse_flags() {
  local args=("$@")
  MEMORY=""
  PORT=""

  for ((i = 0; i < ${#args[@]}; i++)); do
    key="${args[$i]}"
    next="${args[$((i + 1))]:-}"

    case "$key" in
      -m|--memory)
        if [[ -z "$next" || "$next" == -* ]]; then
          echo "Error: Missing value for $key" >&2
          exit 1
        fi
        if ! [[ "$next" =~ ^[0-9]+[mMgG]$ ]]; then
          echo "Error: Invalid memory format '$next'. Use values like 512M, 2G, etc." >&2
          exit 1
        fi
        MEMORY="$next"
        ((i++))
        ;;
      -p|--port)
        if [[ -z "$next" || "$next" == -* ]]; then
          echo "Error: Missing value for $key" >&2
          exit 1
        fi
        if ! [[ "$next" =~ ^[0-9]+$ ]] || ((next < 1024 || next > 65535)); then
          echo "Error: Invalid port '$next'. Must be a number between 1024 and 65535." >&2
          exit 1
        fi
        PORT="$next"
        ((i++))
        ;;
      -h|--help)
        echo "Usage: sofortcraft $1 <version> <target> [options]"
        echo "Options:"
        echo "  -m, --memory      Set Memory for the docker container," 
        echo "                    the server uses 75% of that"
        echo "  -p, --port        Set Port for the docker container"
        exit 0
        ;;
      *)
        ;;
    esac
  done
}

check_container() {
  local container="$1"

  if [ -z "${container}" ]; then
    echo "Usage: sofortcraft $1 <container-name> ..." >&2
    exit 1
  fi
  
  if ! docker ps -a --format '{{.Names}}' | grep -wq "$container"; then
    echo "Error: Container '$container' does not exist." >&2
    exit 1
  fi
}