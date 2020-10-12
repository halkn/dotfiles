# fuzzy gcloud compute ssh
gssh() {
  local host
  host=$(gcloud compute instances list | tail +2 | awk '{print $1}' | fzf)
  if [ -z "${host}" ]; then
    return 0
  fi
  gcloud compute ssh --tunnel-through-iap "${host}"
}

# fuzzy gcloud compute scp
gscp() {
  local src host
  host=$(gcloud compute instances list | tail +2 | awk '{print $1}' | fzf --header 'Select destination hostname.')
  if [ -z "${host}" ]; then
    return 0
  fi
  src=$(
    fd --type f --hidden --maxdepth 1 |\
      fzf --header 'Select file to be sent. (To '"${host}"')'
  )
  if [ -z "${src}" ]; then
    return 0
  fi
  gcloud compute scp --tunnel-through-iap "${src}" "${host}":~
}

# fuzzy gcloud config activate
gca() {
  local selected
  selected=$(
    gcloud config configurations list | \
      tail +2 | \
      awk '{if($2 == "False"){print $1}}' | \
      fzf --preview 'echo {} | xargs -I@ cat $HOME/.config/gcloud/configurations/config_@' \
  )
  if [ -z "${selected}" ]; then
    return 0
  fi
  gcloud config configurations activate ${selected}
}

source ${HOME}/google-cloud-sdk/completion.zsh.inc
