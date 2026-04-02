------------------------------------------------------------------------------------------------------
ATELIER FROM IMAGE TO CLUSTER
Objectif principal : Cet atelier consiste à industrialiser le cycle de vie d'une application simple en construisant une image applicative Nginx personnalisée avec Packer, puis en déployant automatiquement cette application sur un cluster Kubernetes léger (K3d) à l'aide d'Ansible, le tout dans un environnement reproductible via GitHub Codespaces.

Séquence 1 : Codespace de Github
Objectif : Création d'un Codespace Github

Pour garantir un environnement de développement reproductible et éviter les problèmes de dépendances sur nos machines locales, nous avons initialisé le projet dans le Cloud :

Création du Fork : Sur la page du dépôt original, cliquez sur le bouton Fork en haut à droite. Cela crée une copie du projet sur votre compte.

Ouverture du Codespace : Sur votre nouveau dépôt, cliquez sur le bouton vert Code, puis sur l'onglet Codespaces et enfin sur Create codespace on main.

Séquence 2 : Création du cluster Kubernetes K3d
Objectif : Créer votre cluster Kubernetes K3d

L'infrastructure est mise en place en utilisant K3d pour simuler un cluster Kubernetes complet.

1. Installation de K3d et Création du Cluster (1 master, 2 workers) :

Bash
curl -s [https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh](https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh) | bash
k3d cluster create lab --servers 1 --agents 2
2. Déploiement de l'application de test (Docker Mario) :

Bash
kubectl create deployment mario --image=sevenajay/mario
kubectl expose deployment mario --type=NodePort --port=80
kubectl port-forward svc/mario 8080:80 >/tmp/mario.log 2>&1 &
Séquence 3 : Exercice (Packer & Ansible)
Objectif : Customisez une image Docker avec Packer et déploiement sur K3d via Ansible

Cette étape automatise la création de l'image et son déploiement sur le cluster.

1. Installation des outils requis :

Bash
wget -O- [https://apt.releases.hashicorp.com/gpg](https://apt.releases.hashicorp.com/gpg) | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] [https://apt.releases.hashicorp.com](https://apt.releases.hashicorp.com) $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install packer ansible -y
2. Fichier de Build Packer (build.pkr.hcl) :

Terraform
packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "[github.com/hashicorp/docker](https://github.com/hashicorp/docker)"
    }
  }
}

source "docker" "nginx" {
  image  = "nginx:latest"
  commit = true
}

build {
  sources = ["source.docker.nginx"]
  provisioner "file" {
    source      = "index.html"
    destination = "/usr/share/nginx/html/index.html"
  }
  post-processor "docker-tag" {
    repository = "custom-nginx"
    tags       = ["latest"]
  }
}
3. Fichier de Déploiement Ansible (deploy.yml) :

YAML
---
- name: Déploiement de l'application customisée sur K3d
  hosts: localhost
  tasks:
    - name: Déployer l'image custom-nginx
      shell: kubectl create deployment app-custom --image=custom-nginx:latest --dry-run=client -o yaml | kubectl apply -f -
    - name: Exposer le service sur le port 80
      shell: kubectl expose deployment app-custom --type=NodePort --port=80 --name=svc-custom --dry-run=client -o yaml | kubectl apply -f -
4. Exécution du pipeline :

Bash
packer init build.pkr.hcl
packer build build.pkr.hcl
k3d image import custom-nginx:latest -c lab
ansible-playbook deploy.yml
kubectl patch deployment app-custom -p '{"spec":{"template":{"spec":{"containers":[{"name":"custom-nginx","imagePullPolicy":"Never"}]}}}}'
kubectl port-forward svc/svc-custom 8081:80 >/tmp/custom.log 2>&1 &
Séquence 4 : Documentation
Objectif : Documenter et expliquer la solution

La documentation finale assure la pérennité et la compréhension du projet.

Ce README.md détaille chaque étape technique.

Les fichiers de configuration sont versionnés sur GitHub.

Le processus de travail est validé par des commits réguliers.
/////////////////////////////////////////////
-------------------------
ATELIER FROM IMAGE TO CLUSTER
------------------------------------------------------------------------------------------------------
L’idée en 30 secondes : Cet atelier consiste à **industrialiser le cycle de vie d’une application** simple en construisant une **image applicative Nginx** personnalisée avec **Packer**, puis en déployant automatiquement cette application sur un **cluster Kubernetes** léger (K3d) à l’aide d’**Ansible**, le tout dans un environnement reproductible via **GitHub Codespaces**.
L’objectif est de comprendre comment des outils d’Infrastructure as Code permettent de passer d’un artefact applicatif maîtrisé à un déploiement cohérent et automatisé sur une plateforme d’exécution.
  
-------------------------------------------------------------------------------------------------------
Séquence 1 : Codespace de Github
-------------------------------------------------------------------------------------------------------
Objectif : Création d'un Codespace Github  
Difficulté : Très facile (~5 minutes)
-------------------------------------------------------------------------------------------------------
**Faites un Fork de ce projet**. Si besion, voici une vidéo d'accompagnement pour vous aider dans les "Forks" : [Forker ce projet](https://youtu.be/p33-7XQ29zQ) 
  
Ensuite depuis l'onglet [CODE] de votre nouveau Repository, **ouvrez un Codespace Github**.
  
---------------------------------------------------
Séquence 2 : Création du cluster Kubernetes K3d
---------------------------------------------------
Objectif : Créer votre cluster Kubernetes K3d  
Difficulté : Simple (~5 minutes)
---------------------------------------------------
Vous allez dans cette séquence mettre en place un cluster Kubernetes K3d contenant un master et 2 workers.  
Dans le terminal du Codespace copier/coller les codes ci-dessous etape par étape :  

**Création du cluster K3d**  
```
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```
```
k3d cluster create lab \
  --servers 1 \
  --agents 2
```
**vérification du cluster**  
```
kubectl get nodes
```
**Déploiement d'une application (Docker Mario)**  
```
kubectl create deployment mario --image=sevenajay/mario
kubectl expose deployment mario --type=NodePort --port=80
kubectl get svc
```
**Forward du port 80**  
```
kubectl port-forward svc/mario 8080:80 >/tmp/mario.log 2>&1 &
```
**Réccupération de l'URL de l'application Mario** 
Votre application Mario est déployée sur le cluster K3d. Pour obtenir votre URL cliquez sur l'onglet **[PORTS]** dans votre Codespace et rendez public votre port **8080** (Visibilité du port).
Ouvrez l'URL dans votre navigateur et jouer !

---------------------------------------------------
Séquence 3 : Exercice
---------------------------------------------------
Objectif : Customisez un image Docker avec Packer et déploiement sur K3d via Ansible
Difficulté : Moyen/Difficile (~2h)
---------------------------------------------------  
Votre mission (si vous l'acceptez) : Créez une **image applicative customisée à l'aide de Packer** (Image de base Nginx embarquant le fichier index.html présent à la racine de ce Repository), puis déployer cette image customisée sur votre **cluster K3d** via **Ansible**, le tout toujours dans **GitHub Codespace**.  

**Architecture cible :** Ci-dessous, l'architecture cible souhaitée.   
  
![Screenshot Actions](Architecture_cible.png)   
  
---------------------------------------------------  
## Processus de travail (résumé)

1. Installation du cluster Kubernetes K3d (Séquence 1)
2. Installation de Packer et Ansible
3. Build de l'image customisée (Nginx + index.html)
4. Import de l'image dans K3d
5. Déploiement du service dans K3d via Ansible
6. Ouverture des ports et vérification du fonctionnement

---------------------------------------------------
Séquence 4 : Documentation  
Difficulté : Facile (~30 minutes)
---------------------------------------------------
**Complétez et documentez ce fichier README.md** pour nous expliquer comment utiliser votre solution.  
Faites preuve de pédagogie et soyez clair dans vos expliquations et processus de travail.  
   
---------------------------------------------------
Evaluation
---------------------------------------------------
Cet atelier, **noté sur 20 points**, est évalué sur la base du barème suivant :  
- Repository exécutable sans erreur majeure (4 points)
- Fonctionnement conforme au scénario annoncé (4 points)
- Degré d'automatisation du projet (utilisation de Makefile ? script ? ...) (4 points)
- Qualité du Readme (lisibilité, erreur, ...) (4 points)
- Processus travail (quantité de commits, cohérence globale, interventions externes, ...) (4 points) 
