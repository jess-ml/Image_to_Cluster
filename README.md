------------------------------------------------------------------------------------------------------
README A JOUR:
----------------
ATELIER FROM IMAGE TO CLUSTER
Objectif principal : Cet atelier a pour but d'industrialiser le cycle de vie d'une application web. Le processus part d'un code source statique pour aboutir à un déploiement fonctionnel sur un cluster Kubernetes. Nous utilisons Packer pour la création de l'image, K3d pour l'infrastructure de conteneurs, et Ansible pour l'automatisation du déploiement.

Séquence 1 : Codespace de Github
Objectif : Préparation de l'environnement de développement

La première étape consiste à créer un environnement de travail isolé et pré-configuré dans le cloud.

1. Création du Fork :
Pour travailler sur votre propre instance du projet, vous devez cliquer sur le bouton "Fork" en haut à droite de la page du dépôt original sur GitHub. Cela crée une copie exacte du projet sur votre compte personnel, vous permettant de modifier le code et de sauvegarder vos changements.

2. Lancement du Codespace :
Une fois sur votre fork :

Cliquez sur le bouton vert "Code".

Allez dans l'onglet "Codespaces".

Cliquez sur "Create codespace on main".
GitHub va alors construire une machine virtuelle Linux avec un terminal et un éditeur de code directement dans votre navigateur.

Séquence 2 : Création du cluster Kubernetes K3d
Objectif : Déploiement de l'infrastructure locale

Dans cette séquence, nous installons un orchestrateur de conteneurs pour héberger nos applications.

1. Installation de l'outil K3d :

Bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
2. Initialisation du cluster :
Nous créons un cluster nommé "lab" avec un nœud de contrôle et deux nœuds d'exécution.

Bash
k3d cluster create lab --servers 1 --agents 2
3. Test de déploiement (Application Mario) :

Déploiement : kubectl create deployment mario --image=sevenajay/mario

Création du service : kubectl expose deployment mario --type=NodePort --port=80

Accès web : Redirection du flux vers le port 8080 du Codespace :

Bash
kubectl port-forward svc/mario 8080:80 >/tmp/mario.log 2>&1 &
Séquence 3 : Exercice (Packer & Ansible)
Objectif : Industrialisation du Build et du Déploiement

Cette séquence remplace les manipulations manuelles par de l'Infrastructure as Code (IaC).

1. Installation des dépendances :

Bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install packer ansible -y
2. Fichiers de configuration créés :

Fichier build.pkr.hcl (Configuration Packer) :

Terraform
packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
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
Fichier deploy.yml (Playbook Ansible) :

YAML
---
- name: Déploiement de l'application customisée sur K3d
  hosts: localhost
  tasks:
    - name: Déployer l'image custom-nginx
      shell: kubectl create deployment app-custom --image=custom-nginx:latest --dry-run=client -o yaml | kubectl apply -f -

    - name: Exposer le service sur le port 80
      shell: kubectl expose deployment app-custom --type=NodePort --port=80 --name=svc-custom --dry-run=client -o yaml | kubectl apply -f -
3. Exécution du pipeline :

Build Packer : packer init build.pkr.hcl && packer build build.pkr.hcl

Import K3d : k3d image import custom-nginx:latest -c lab

Déploiement Ansible : ansible-playbook deploy.yml

Séquence 4 : Documentation
Objectif : Capitalisation et pérennité du projet

La dernière étape consiste à rédiger ce document pour expliquer la solution.

Ce README détaille chaque commande.

Les fichiers de configuration sont sauvegardés sur le dépôt.

Le processus est validé par des sauvegardes régulières (git add, commit, push).
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
