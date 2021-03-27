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

# fuzzy gsutil
fgs() {
  local current selected laststr cand obj
  current="$1"
  while true; do
    cand=$(echo ".."; gsutil ls ${current})
    selected=$(echo $cand| fzf -m --info=inline --header="Current: ${current}")
    if [ -z "${selected}" ]; then
      return 0
    fi
    laststr=${selected: -1}
    if [ ${laststr} = "/" ]; then
      current=${selected}
    elif [ ${selected} = ".." ]; then
      if [ "${current}" != "" ]; then
        current=${current%/*/*}
        if [ ${current} = "gs:" -o ${current} = "gs:/" ]; then
          current=""
        fi
      fi
    else
      while read -r line; do
        gsutil cp ${line} .
      done < <(echo "${selected}")
      return 0
    fi
  done
}
