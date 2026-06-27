set -e

echo "Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y git curl build-essential python3 python3-pip python3-venv

echo "Installing Docker..."
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker coder || true
sudo dockerd > /tmp/dockerd.log 2>&1 &

sleep 5

cd ~/workspace

if [ -n "$REPO_URL" ]; then
  git clone "$REPO_URL" repo
  cd repo
fi

python3 -m venv .venv
source .venv/bin/activate

pip install --upgrade pip

pip install fastapi uvicorn jupyterlab pytest black ruff mypy ipykernel