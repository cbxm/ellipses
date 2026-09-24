function sys_audio --description "Clear sticky default audio devices so wireplumber priorities apply"
    wpctl clear-default
end
