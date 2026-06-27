terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

provider "coder" {}

data "coder_workspace" "me" {}

# -------------------------
# Parameters (user inputs)
# -------------------------
variable "repo_url" {
  type        = string
  description = "Git repository to clone into the workspace"
  default     = ""
}

variable "python_version" {
  type        = string
  default     = "3.11"
}

# -------------------------
# Python Dev Agent
# -------------------------
resource "coder_agent" "python" {
  arch = "amd64"
  os   = "linux"

  startup_script = <<-EOT
    set -e

    echo "Updating system..."
    sudo apt-get update -y
    sudo apt-get install -y \
      git curl build-essential \
      python3 python3-pip python3-venv

    echo "Setting up workspace..."
    mkdir -p ~/workspace
    cd ~/workspace

    # Clone repo if provided
    if [ ! -z "${var.repo_url}" ]; then
      echo "Cloning repo..."
      git clone ${var.repo_url} repo
      cd repo
    fi

    echo "Creating virtual environment..."
    python3 -m venv .venv
    source .venv/bin/activate

    echo "Upgrading pip..."
    pip install --upgrade pip

    echo "Installing Python dev tools..."
    pip install \
      fastapi \
      uvicorn \
      jupyterlab \
      pytest \
      black \
      ruff \
      mypy \
      ipykernel

    echo "Setup complete."
  EOT

  env = {
    PYTHONUNBUFFERED = "1"
  }
}

# -------------------------
# VS Code (Coder built-in)
# -------------------------
resource "coder_app" "vscode" {
  agent_id     = coder_agent.python.id
  slug         = "vscode"
  display_name = "VS Code"
  url          = "http://localhost:13337"
  subdomain    = true
}

# -------------------------
# FastAPI App (example)
# -------------------------
resource "coder_app" "fastapi" {
  agent_id     = coder_agent.python.id
  slug         = "fastapi"
  display_name = "FastAPI Server"
  url          = "http://localhost:8000"
  subdomain    = true
}

# -------------------------
# JupyterLab App
# -------------------------
resource "coder_app" "jupyter" {
  agent_id     = coder_agent.python.id
  slug         = "jupyter"
  display_name = "JupyterLab"
  url          = "http://localhost:8888"
  subdomain    = true
}