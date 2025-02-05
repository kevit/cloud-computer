# Export cloud computer shell environment
eval "$(yarn environment)"

# Export local git config
eval "$(yarn --cwd ../git environment)"

yarn --cwd ../docker docker run \
  --env DOCKER_HOST=unix:///var/run/docker.sock \
  --env GIT_COMMITTER_EMAIL \
  --env GIT_COMMITTER_NAME \
  --env CLOUD_COMPUTER_CREDENTIALS \
  --env CLOUD_COMPUTER_HOME \
  --env CLOUD_COMPUTER_HOST_DNS \
  --env CLOUD_COMPUTER_HOST_ID \
  --env CLOUD_COMPUTER_NODEMON \
  --env CLOUD_COMPUTER_REPOSITORY \
  --env CLOUD_COMPUTER_TERRAFORM \
  --env CLOUD_COMPUTER_TMUX \
  --env CLOUD_COMPUTER_X11 \
  --env CLOUD_COMPUTER_YARN \
  --interactive \
  --name cloud-computer-shell-$(date +%M%S) \
  --rm \
  --tty \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume CLOUD_COMPUTER_CREDENTIALS:$CLOUD_COMPUTER_CREDENTIALS \
  --volume CLOUD_COMPUTER_HOME:$CLOUD_COMPUTER_HOME \
  --volume CLOUD_COMPUTER_REPOSITORY:$CLOUD_COMPUTER_REPOSITORY \
  --volume CLOUD_COMPUTER_TERRAFORM:$CLOUD_COMPUTER_TERRAFORM \
  --volume CLOUD_COMPUTER_TMUX:$CLOUD_COMPUTER_TMUX \
  --volume CLOUD_COMPUTER_X11:$CLOUD_COMPUTER_X11 \
  --volume CLOUD_COMPUTER_YARN:$CLOUD_COMPUTER_YARN \
  --workdir $CLOUD_COMPUTER_REPOSITORY \
  $CLOUD_COMPUTER_IMAGE zsh --login
