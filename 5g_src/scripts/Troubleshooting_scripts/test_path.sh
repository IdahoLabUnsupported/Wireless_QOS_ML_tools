


config_setup_script="env | grep PATH"
echo "config setup"
ssh -l ubuntu 192.168.1.100 "${config_setup_script}"