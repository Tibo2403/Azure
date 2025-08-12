# README – Déploiement d’une VM de pentesting sur Azure

Ce dépôt contient un **template Bicep** permettant de déployer rapidement une machine virtuelle Linux dédiée aux tests d’intrusion. Il fournit un réseau virtuel isolé, un groupe de sécurité minimal et une extension optionnelle pour installer quelques outils basiques de pentest.

> ⚠️ **Avertissement légal**  
> N’utilisez ce template qu’avec l’autorisation explicite des propriétaires des systèmes visés. Toute activité non autorisée peut être illégale et entraîner des poursuites.

---

## Contenu

- `pentest.bicep` – Template principal pour créer la VM et les ressources réseau.
- `README.md` (ce document) – Explications détaillées.

---

## Architecture déployée

- **Network Security Group (NSG)** : autorise uniquement le port 22/TCP (SSH) en entrée.
- **Virtual Network (VNet)** : réseau `10.0.0.0/16` avec un sous-réseau `10.0.0.0/24`.
- **Public IP dynamique** (facultative selon vos besoins).
- **Interface réseau (NIC)** liée au sous-réseau et à l’IP publique.
- **Machine virtuelle Ubuntu 20.04 LTS** (taille par défaut `Standard_B1s`).
- **Extension Custom Script** (facultative) pour installer automatiquement quelques outils (`nmap`, `curl`).

---

## Prérequis

- **Azure CLI** (`az`) ou Azure PowerShell.
- Un **groupe de ressources** préexistant.
- Une **clé SSH publique** pour l’authentification à la VM.
- Droits suffisants pour créer des ressources dans Azure.

---

## Paramètres principaux

| Paramètre        | Description                                              | Exemple                       |
|------------------|----------------------------------------------------------|------------------------------|
| `location`       | Région Azure du déploiement (par défaut : rg.location).  | `westeurope`                 |
| `adminUsername`  | Nom d’utilisateur admin de la VM.                        | `pentester`                  |
| `sshPublicKey`   | Contenu de la clé publique SSH.                          | `ssh-rsa AAAA...`            |

Vous pouvez ajuster les noms des ressources (VM, vnet, nsg, etc.) en modifiant les variables en début de fichier Bicep.

---

## Déploiement

1. **Connexion à Azure** :
   ```bash
   az login
   az account set --subscription <ID_ou_nom_de_subscription>
   ```

2. **Déploiement du template** :
   ```bash
   az deployment group create \
     --resource-group <NomDuGroupe> \
     --template-file pentest.bicep \
     --parameters adminUsername=<utilisateur> \
                  sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"
   ```

3. **Récupération de l’IP publique** :
   ```bash
   az network public-ip show \
     --resource-group <NomDuGroupe> \
     --name pentest-ip \
     --query "ipAddress" -o tsv
   ```

4. **Connexion à la VM** :
   ```bash
   ssh <utilisateur>@<adresse-ip>
   ```

---

## Personnalisation

- **Taille de la VM** : modifiez `vmSize` (`Standard_B1s`, `Standard_DS2_v2`, etc.).
- **Distribution Linux** : changez l’image (`publisher`, `offer`, `sku`, `version`).
- **Règles NSG** : ajoutez/éditez les règles de sécurité selon vos besoins (ports spécifiques, restrictions IP, etc.).
- **Outils supplémentaires** : ajustez la commande de l’extension `CustomScript` pour installer d’autres paquets (Metasploit, Nikto, etc.).

---

## Nettoyage

Pour supprimer toutes les ressources déployées, supprimez simplement le groupe de ressources :

```bash
az group delete --name <NomDuGroupe> --yes --no-wait
```

---

## Bonnes pratiques

- **Monitoring** : activez la journalisation NSG ou l’Azure Monitor pour suivre le trafic et les actions.
- **Automatisation** : utilisez des pipelines CI/CD (GitHub Actions, Azure DevOps) pour gérer les déploiements de manière reproductible.
- **Sécurité** : mettez à jour régulièrement la VM (`apt-get upgrade`), appliquez les correctifs de sécurité et contrôlez l’accès via des NSG plus restrictifs ou Azure Firewall.
- **Conformité** : vérifiez la conformité aux réglementations locales et aux politiques de votre organisation.

---

## Licence

Ce template est fourni “tel quel”. Utilisez-le à vos risques et périls. Assurez-vous de respecter la législation applicable et d’obtenir les autorisations nécessaires avant toute activité de test d’intrusion.

---

### Contribution

Les contributions sont les bienvenues ! Veuillez soumettre une _pull request_ ou ouvrir une _issue_ pour signaler un problème ou proposer une amélioration.

---

### Contact

Pour toute question ou suggestion, vous pouvez créer une issue dans ce dépôt GitHub.

---

Merci d’utiliser ce template et bon pentesting !
