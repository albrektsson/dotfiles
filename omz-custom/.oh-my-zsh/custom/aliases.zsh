alias kubectl="kubecolor"


jwt () {
  echo -n $1 | jc --jwt | jq
}

jwttime () {
  jwt $1 | jq -r ".payload.$2" | xargs date -r
}

whowrotethisshit() {
  git shortlog -s "$@"
}

revoke-gh-token() {
  curl -L -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/credentials/revoke \
    -d "{\"credentials\":[\"$1\"]}"
}

goGo () {
  name=$1
  dirname=${name#*/}
  basename=${name##*/}
  set -x
  cd ~/IdeaProjects
  mkdir -p ${dirname}
  cd ${dirname}
  mkdir -p cmd/${basename}
  mkdir pkg/
  go mod init ${name}
  git init
  echo "# ${basename}" > README.md
  echo "package main" > cmd/${basename}/main.go
  echo "${basename}:\n\tgo build -o bin/${basename} cmd/${basename}/*.go\n" > Makefile
  git add .
  git commit -a -m "initial commit"
}

extract_docker_image() {
  if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 <docker-image>"
    return 1
  fi

  local image="$1"
  local dir="${image##*/}"  # Extract the image name and tag after the last /
  mkdir -p "$dir/extracted-blobs"

  # Save the Docker image and handle errors
  if ! docker save "$image" | tar -x -C "$dir"; then
    echo "Error: Failed to save and extract Docker image."
    rm -rf "$dir"
    exit 1
  fi

  for layer in "$dir/blobs/sha256/"*; do
    tar -xf "$layer" -C "$dir/extracted-blobs" 2>/dev/null
  done

  rm -rf "$dir/blobs" # Dont need the unextracted blobs
  local size=$(du -sh "$dir" | cut -f1)
  echo "Success! Extracted $size to $dir."
}

function checkGithubTokenScopes() {
  curl https://api.github.com/users -I -H "Accept: application/vnd.github.v3+json" -H "Authorization: token $1"
}

function gitclean() {
  branch=${1:-main}
  echo "Cleaning branch $branch..."
  git fetch origin && git reset --hard origin/$branch && git clean -f -d && git fetch --prune
}

function gitmergeupstreamchanges() {
  branch=${1:-main}
  git fetch origin $branch
  git pull --rebase origin $branch
}

whouses () {
  lsof -sTCP:LISTEN -i:$1 | awk 'NR>1 {print $1}' | uniq
}

rmd () {
  pandoc $1 | lynx -stdin
}
