#! /bin/bash
if [ -f $HOME/.config/gcloud/active_config ]; then
  _gcp_proj=$(
    cat $HOME/.config/gcloud/active_config |
      xargs -I@ awk '/project/{print $3}' $HOME/.config/gcloud/configurations/config_@
  )
  echo -n "#[fg=#b3deef,bg=#3e4249] [GCP:"
  echo -n ${_gcp_proj}
  echo -n "]"
  echo -n "#[fg=#b7bec9,bg=#3e4249]|"
fi
if type battery > /dev/null 2>&1; then
  echo -n " "
  _battery=$(battery -t)
  echo -n ${_battery}
fi
exit 0
