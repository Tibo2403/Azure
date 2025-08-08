# 📦 Azure Deployment — App Service + Storage + Key Vault + App Insights

Ce dépôt contient un **template Bicep** pour déployer rapidement une stack complète sur Azure comprenant :

- **Storage Account** (sécurisé, TLS 1.2+, accès HTTPS only)
- **App Service Plan (Linux)** + **Web App**
- **Application Insights** pour la supervision
- **Key Vault** avec exemple de secret

---

## 📂 Structure

.
├── main.bicep # Template principal
├── parameters.json # Exemple de paramètres
└── README.md # Ce fichier


---

## ⚙️ Paramètres principaux

| Nom                  | Description                                           | Défaut               | Obligatoire |
|----------------------|-------------------------------------------------------|----------------------|-------------|
| `namePrefix`         | Préfixe pour nommer les ressources                    | —                    | ✅          |
| `location`           | Région Azure                                          | resourceGroup().location | ❌          |
| `appServiceSku`      | SKU du plan App Service (`B1`, `P1v3`, `P2v3`)         | `B1`                 | ❌          |
| `linuxFxVersion`     | Stack runtime de la Web App (ex. `PYTHON|3.12`)        | `PYTHON|3.12`        | ❌          |
| `tags`               | Tags appliqués à toutes les ressources                 | `{ env: 'dev', owner: 'infra', app: namePrefix }` | ❌ |
| `kvPublicNetworkAccess` | Activer/désactiver accès public au Key Vault         | `Enabled`            | ❌          |
| `exampleSecretValue` | Valeur du secret d’exemple dans Key Vault              | `ChangeMe_...`       | ❌          |

---

## 🚀 Déploiement

### 1️⃣ Créer un groupe de ressources
```bash
az group create -n rg-fitcoach-dev -l westeurope

az deployment group create \
  --resource-group rg-fitcoach-dev \
  --template-file main.bicep \
  --parameters @parameters.json




