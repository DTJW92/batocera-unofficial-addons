#!/bin/bash

# Step 1: Detect system architecture
echo "Detecting system architecture..."
arch=$(uname -m)

if [ "$arch" == "x86_64" ]; then
    echo "Architecture: x86_64 detected."
    app_url="https://github.com/zencodes1/amazonluna-client/releases/download/release/amazonluna-electron-client.tar.xz"
else
    echo "Unsupported architecture: $arch. Exiting."
    exit 1
fi

# Step 2: Download the application
echo "Downloading Amazon Luna client from $app_url..."
app_dir="/userdata/system/pro/amazonluna"
mkdir -p "$app_dir"
temp_dir="${app_dir}/temp"
mkdir -p "$temp_dir"

wget -q --show-progress -O "${temp_dir}/amazonluna.tar.xz" "$app_url"
if [ $? -ne 0 ]; then
    echo "Failed to download Amazon Luna client. Exiting."
    exit 1
fi

# Step 3: Extract the application
echo "Extracting Amazon Luna client..."
tar -xf "${temp_dir}/amazonluna.tar.xz" -C "$temp_dir"
mv "${temp_dir}/amazonluna"/* "$app_dir/"
chmod a+x "${app_dir}/AmazonLuna"
rm -rf "$temp_dir"
echo "Amazon Luna client installed successfully."

# Step 4: Create launcher script
echo "Creating Amazon Luna script in Ports..."
ports_dir="/userdata/roms/ports"
mkdir -p "$ports_dir"
cat << 'EOF' > "${ports_dir}/AmazonLuna.sh"
#!/bin/bash

# Environment setup
export $(cat /proc/1/environ | tr '\0' '\n')
export DISPLAY=:0.0
export HOME="/userdata/system/pro/amazonluna"

# Paths
app_dir="/userdata/system/pro/amazonluna"
app_bin="${app_dir}/AmazonLuna"
log_dir="/userdata/system/logs"
log_file="${log_dir}/amazonluna.log"

# Ensure log directory exists
mkdir -p "${log_dir}"

# Append all output to the log file
exec &> >(tee -a "$log_file")
echo "$(date): Launching Amazon Luna"

# Launch Amazon Luna
if [ -x "${app_bin}" ]; then
    cd "${app_dir}"
    ./AmazonLuna --no-sandbox --test-type "$@" > "${log_file}" 2>&1
    echo "Amazon Luna exited."
else
    echo "AmazonLuna binary not found or not executable."
    exit 1
fi
EOF

chmod +x "${ports_dir}/AmazonLuna.sh"

# Step 5: Refresh the Ports menu
echo "Refreshing Ports menu..."
curl http://127.0.0.1:1234/reloadgames

echo
echo "Installation complete! You can now launch Amazon Luna from the Ports menu."