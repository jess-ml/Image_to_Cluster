------------------------------------------------------------------------------------------------------
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


////////////
### Guide d'utilisation de la solution (Packer & Ansible)

Cette section documente le processus mis en place pour construire notre image Nginx customisée et la déployer de manière automatisée sur le cluster K3d.

#### 1. Prérequis et Installation
Avant de commencer, il est nécessaire d'installer les outils d'Infrastructure as Code sur notre environnement (Codespace) :
- **Packer** : Utilisé pour "packer" notre application web statique (`index.html`) à l'intérieur d'une image Nginx sur mesure.
- **Ansible** : Utilisé pour scripter et automatiser le déploiement sur notre cluster Kubernetes.

#### 2. Build de l'image customisée (Packer)
Nous avons créé un template `build.pkr.hcl` qui ordonne à Packer de :
1. Partir d'une image de base `nginx:latest`.
2. Copier notre fichier local `index.html` vers le répertoire web par défaut de Nginx (`/usr/share/nginx/html/`).
3. Tagger cette nouvelle image sous le nom `custom-nginx:latest`.

*Commandes pour lancer le build :*
`packer init build.pkr.hcl`
`packer build build.pkr.hcl`

#### 3. Importation de l'image dans K3d
Pour que notre cluster Kubernetes puisse instancier cette image locale (qui n'est pas hébergée sur le Docker Hub public), nous devons l'importer dans le registre de K3d :
`k3d image import custom-nginx:latest -c lab`

#### 4. Déploiement automatisé (Ansible)
Plutôt que d'exécuter nos commandes `kubectl` manuellement, nous utilisons un playbook Ansible (`deploy.yml`). Ce playbook effectue deux tâches séquentielles :
1. Créer le déploiement Kubernetes à partir de notre image locale (avec la politique `imagePullPolicy: Never` pour forcer la lecture en local).
2. Exposer ce déploiement via un service de type NodePort sur le port 80.

*Commande pour lancer le déploiement :*
`ansible-playbook deploy.yml`

#### 5. Ouverture des ports et vérification
Enfin, nous créons un tunnel pour exposer le service afin d'y accéder depuis notre navigateur web (via le port 8081) :
`kubectl port-forward svc/svc-custom 8081:80 >/tmp/custom.log 2>&1 &`