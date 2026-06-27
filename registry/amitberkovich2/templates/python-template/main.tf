terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

provider "coder" {}

variable "repo_url" {
  type        = string
  default     = ""
  description = "Git repo to clone into workspace"
}

resource "coder_agent" "dev" {
  arch = "amd64"
  os   = "linux"

  startup_script = <<-EOT
    set -e

    echo "Installing system dependencies..."
    sudo apt-get update -y
    sudo apt-get install -y git curl build-essential python3 python3-pip python3-venv

    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker coder || true
    sudo dockerd > /tmp/dockerd.log 2>&1 &

    sleep 5

    echo "Preparing workspace..."
    mkdir -p ~/workspace
    cd ~/workspace

    if [ ! -z "${var.repo_url}" ]; then
      git clone ${var.repo_url} repo
      cd repo
    fi

    echo "Setting up Python venv..."
    python3 -m venv .venv
    source .venv/bin/activate

    pip install --upgrade pip

    pip install \
      fastapi uvicorn \
      jupyterlab \
      pytest black ruff mypy ipykernel

    echo "Environment ready."
  EOT

  env = {
    PYTHONUNBUFFERED = "1"
  }
}

resource "coder_app" "vscode" {
  agent_id     = coder_agent.dev.id
  slug         = "vscode"
  display_name = "VS Code"
  url          = "http://localhost:13337"
  subdomain    = true
}

resource "coder_app" "fastapi" {
  agent_id     = coder_agent.dev.id
  slug         = "fastapi"
  display_name = "FastAPI"
  url          = "http://localhost:8000"
  subdomain    = true
}

resource "coder_app" "jupyter" {
  agent_id     = coder_agent.dev.id
  slug         = "jupyter"
  display_name = "JupyterLab"
  url          = "http://localhost:8888"
  subdomain    = true
}