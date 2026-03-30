# 🎮 GameRank

GameRank is a full-stack web application built with Django for exploring, rating, and commenting on videogames. It aggregates data from multiple external sources (XML and public JSON APIs) and allows users to interact with games by posting reviews, voting on comments, and customizing their experience.

> 🌐 **Previous live demo:** [https://noelito.pythonanywhere.com/](https://noelito.pythonanywhere.com/)  
> 🕒 Historical deployment used during the academic project

---

## ✨ Features

- 🔐 **Authentication system** (login with protected resources):
  - **Global login password**: `xx34d23` (to access any resource different from the main -> `/`).
  - **User login or registration**: Use individual profiles getting registered and login in this app.
- 🎲 **Game catalog**: Games are loaded from an XML source and two public APIs (FreeToGame and MMOBomb), ordered by average score.
- 💬 **User interactions**: Comment, rate (0–5 stars), like/dislike comments.
- 🔎 **Game filters** by platform, genre, and publisher.
- 🧾 **Game detail pages** with user ratings, average score, and comment threads.
- 🧠 **Profile customization**: Font size and type, and username modifications.
- 📥 **Game import/export**: Automatically import data from external sources and export each game's data with a simple click.
- 🧪 **Test coverage**: Django's built-in test suite (unit and end-to-end).
- 🌍 **Internationalization**: Available in Spanish and English.
- 📱 **Responsive UI**: Bootstrap-based modern frontend.

---

## 🧩 Tech Stack

- **Backend**: Python 3.13, Django 5
- **Frontend**: HTML5, Bootstrap 4, HTMX
- **Database**: SQLite
- **DevOps & Deployment**: Docker, Kubernetes (K8s), Minikube, Nginx Ingress
- **Hosting**: PythonAnywhere (Cloud) & Localhost (Django runserver / K8s cluster)
- **External APIs**: FreeToGame, MMOBomb

---

## 🖥️ Deployment (Online)

Historical public deployment:

🔗 [https://noelito.pythonanywhere.com/](https://noelito.pythonanywhere.com/)  
🗓️ Availability depended on the PythonAnywhere academic environment  
🔐 Default credentials (for demo purposes):

### 🔐 Users Credentials

- **Admin Panel**: `noelito / 123`
- **Regular Users**: `gonza / gonzagonza14`, `lucia / lucialucia12`

---

## 📹 Demo Videos

- 🎥 [Basic Functionality](https://youtu.be/sqMIz6oc28I)
- 🎥 [Optional Features](https://youtu.be/3WCI0hEX_Mw)

---

## 🧑‍💻 Author

**Noel Rodríguez Pérez** Bachelor’s Degree in Telecommunications Engineering  
📫 [n.rodriguezp.2022@alumnos.urjc.es](mailto:n.rodriguezp.2022@alumnos.urjc.es) | [noelrp240514@gmail.com](mailto:noelrp240514@gmail.com)  
🌐 GitHub: [@nowelito28](https://github.com/nowelito28)

---

## 🚀 Quickstart (Local Setup - Traditional)

### 📦 Requirements

- Python 3.11+
- pip
- Virtual environment (recommended)

### 🔧 Installation (Linux/macOS)

```bash
# Clone the repository
git clone [https://github.com/nowelito28/GameRank_Full-Stack_API.git](https://github.com/nowelito28/GameRank_Full-Stack_API.git)
cd GameRank_Full-Stack_API  # or the real repo name

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install project dependencies
pip install -r requirements.txt

# Apply migrations
python3 manage.py migrate

# Create a superuser to access the database -> /admin (optional)
python3 manage.py createsuperuser

# Run the development server
python3 manage.py runserver
```

## 🐳 Local Deployment with Helm, Minikube(Kubernetes-kubectl), Docker and GitHub Actions

The current local deployment flow is based on:

- a Docker image built by the workflow
- a local Minikube cluster
- a Helm chart located in `chart_helm/`
- a self-hosted GitHub Actions runner with the label `gamerank-runner`

The old manual guide based on `kubectl create deployment`, `kubectl expose`, and handwritten ingress manifests is obsolete for this repository state.

### 📋 Runtime Requirements

The self-hosted runner machine must be prepared before the workflow runs.

#### Common requirements

- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- enough permissions to start Minikube and create Kubernetes resources
- internet access to install missing tools such as `helm`, `kubectl`, `curl`, (and `gsudo` or Git for Windows when required)

#### macOS

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- `sudo` access
- GitHub Actions runner registered with labels `self-hosted` and `gamerank-runner`
- repository secret `PASS`

#### Linux

- Docker installed and startable through the local service manager
- `sudo` access
- GitHub Actions runner registered with labels `self-hosted` and `gamerank-runner`
- repository secret `PASS`

#### Windows

- Docker Desktop
- PowerShell (`pwsh`)
- `winget` or Chocolatey available if the workflow needs to install missing tools
- GitHub Actions runner registered with labels `self-hosted` and `gamerank-runner`
- repository secret: `W_PASS`

### 🔐 Required GitHub Secrets

Create these repository secrets in `Settings -> Secrets and variables -> Actions`:

| Secret   | Used on      | Description                                                            |
| -------- | ------------ | ---------------------------------------------------------------------- |
| `PASS`   | macOS, Linux | Local admin/sudo password used to start the Minikube tunnel            |
| `W_PASS` | Windows      | Windows administrator password used by `gsudo` for the Minikube tunnel |

### 🤖 Self-Hosted Runner Setup

The workflow uses:

```yaml
runs-on: [self-hosted, gamerank-runner]
```

This means the runner must:

- be registered as a self-hosted runner for the repository
- have the custom label `gamerank-runner`
- ideally be a single dedicated machine, so the `ci` and `cd` jobs share the same local Docker and Minikube state

Basic setup path in GitHub:

1. Open `Settings -> Actions -> Runners -> New self-hosted runner`.
2. Choose your operating system in GitHub and copy the commands shown there.
3. Install and register the runner on the target machine.
4. Start the runner and verify it appears as `Idle`.
5. Add the custom label `gamerank-runner` to that runner.

Mini guide:

```bash
# Create a folder for the runner and enter it
mkdir actions-runner && cd actions-runner

# Download the runner package using the URL provided by GitHub
# Extract it
# Run the configuration command shown by GitHub:
# ./config.sh --url https://github.com/<owner>/<repo> --token <token>

# Start the runner
./run.sh
```

On Windows, GitHub provides the equivalent `config.cmd` and `run.cmd` commands in PowerShell.

### ⚙️ Current CI/CD Flow

The active workflow is:

- `.github/workflows/deploy_helm.yml`

It is triggered on:

- `push` to `main`
- `workflow_dispatch`

The pipeline is split into two jobs:

#### `ci`

- checks that Docker and Minikube are available
- installs missing helper tools when needed depending on the OS
- starts Docker and Minikube if they are not already running
- builds the image `nowelito28/gamerank:latest`
- loads that image into the local Minikube image cache

#### `cd`

- checks or installs `kubectl`, `helm`, and OS-specific helper tools
- starts Docker and Minikube again if needed
- verifies Kubernetes cluster connectivity
- creates or reuses the namespace `gamerank-ns`
- enables the Minikube NGINX Ingress addon
- validates the Helm chart
- renders the Helm templates
- starts `minikube tunnel`
- deploys the Helm release into `gamerank-ns`
- validates rollout status and prints the final URL

### 🛠️ Running the Deployment Successfully

To make the automated deployment work reliably:

1. Prepare one self-hosted machine with Docker, Minikube, and the `gamerank-runner` label.
2. Make sure Docker can start correctly on that machine.
3. Make sure `minikube start` works manually before relying on the workflow.
4. Add the required repository secrets: `PASS` for macOS/Linux or `W_PASS` for Windows.
5. Push to `main` or launch the workflow manually from the Actions tab.

### 🌐 Resulting Local URL

If the workflow finishes successfully, the app is exposed through the Minikube ingress at:

👉 **[http://gamerank.127.0.0.1.nip.io](http://gamerank.127.0.0.1.nip.io)**

The `nip.io` hostname resolves automatically to `127.0.0.1`, so no manual `/etc/hosts` changes are needed.

### ⚠️ Operational Notes

- This deployment is local to the self-hosted runner machine.
- The workflow currently uses the mutable Docker tag `latest`.
- The `ci` and `cd` jobs share local Docker and Minikube state, so they are intended to run on the same dedicated runner.
- SQLite is still used inside the container, so pod recreation may discard runtime data if no persistent volume is configured.
- Creating users directly inside the running pod is possible, but those changes follow the same SQLite persistence limitations.

---
