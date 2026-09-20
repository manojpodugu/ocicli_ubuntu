```bash
#!/bin/bash

sudo apt install -y python3 python3-pip python3-venv curl unzip


# Install OCI CLI
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" -- --accept-all-defaults

# Reload environment
source ~/.bashrc

# Install jq
apt update -y
apt upgrade -y
apt install -y jq

# Verify installations
echo
echo "OCI CLI version:"
oci --version

echo
echo "jq version:"
jq --version

echo "python version:"
python3 --version

echo
echo "Installation completed."
```
