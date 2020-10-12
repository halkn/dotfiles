#! /bin/bash
if [ -f $HOME/.config/gcloud/active_config ]; then
  _pj=$(cat $HOME/.config/gcloud/active_config)
  _gcp_proj=$(
    echo ${_pj} |
      xargs -I@ awk '/project/{print $3}' $HOME/.config/gcloud/configurations/config_@
  )
  if [ ${_pj} == "default" ]; then
    echo -n "#[fg=colour4,bg=colour238] "
  else
    echo -n "#[fg=colour7,bg=colour1] "
  fi
  echo -n "[GCP:"
  echo -n ${_gcp_proj}
  echo -n "]"
  echo -n "#[fg=colour246,bg=colour238]|"
fi
if type battery > /dev/null 2>&1; then
  echo -n " "
  _battery=$(battery -t)
  echo -n ${_battery}
fi
exit 0
