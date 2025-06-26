# TP Terraform - Infrastructure AWS scalable

## Auteur
Wassim BEDIDI

## Description
Ce projet a été réalisé dans le cadre d’un TP de Master visant à mettre en pratique l’utilisation de Terraform pour la création d’une infrastructure scalable sur AWS.

L’objectif était de créer :
- Un **Application Load Balancer (ALB)**
- Un **Target Group**
- Un **Auto Scaling Group (ASG)** avec un **Launch Template**
- Des instances EC2 (type `t2.micro`) générées automatiquement par l'ASG

Chaque instance EC2 devait générer automatiquement un fichier `index.html` contenant son **ID d'instance**, permettant de vérifier le fonctionnement via l’ALB.

## Fichiers présents

- `main.tf` : Définit les ressources principales (ALB, ASG, Target Group, etc.)
- `variables.tf` : Contient les variables utilisées dans le projet
- `outputs.tf` : Définit les sorties utiles (ex: URL de l'ALB)
- `provider.tf` : Configuration du provider AWS
- `user_data.sh` : Script de démarrage des instances EC2 (génération du fichier HTML)
- `terraform.tfvars` : Valeurs spécifiques à ce déploiement
- `README.md` : Ce fichier

## Étapes pour déployer

```bash
terraform init
terraform plan
terraform apply
```

🧨 **N’oubliez pas de détruire les ressources après usage :**

```bash
terraform destroy
```

## Tests effectués

- Modification du nombre d'instances dans l'ASG
- Vérification du bon enregistrement des instances dans le Target Group
- Affichage correct de l'`index.html` via le Load Balancer

## Date
26/06/2025
