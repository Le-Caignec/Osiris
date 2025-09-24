# OSIRIS Frontend

Frontend React pour la plateforme OSIRIS - Automatisation des investissements DeFi avec Dollar-Cost Averaging (DCA).

## Fonctionnalités

### 🔗 Connexion Wallet

- Support pour Sepolia (testnet) et Ethereum (mainnet)
- Intégration avec RainbowKit pour une connexion wallet facile
- Support de MetaMask, WalletConnect et autres wallets

### 💰 Gestion des Balances

- **Balance totale du vault USDC** : Montant total de USDC déposé dans le contrat
- **Balance USDC de l'utilisateur** : Montant de USDC disponible pour le DCA
- **Balance ETH native** : ETH disponible pour retrait après exécution DCA
- **Balance ETH de l'utilisateur** : ETH dans le wallet de l'utilisateur

### 📈 Plan DCA

- **Création de plan** : Définir la fréquence (Daily, Weekly, Monthly) et le montant
- **Visualisation** : Voir les détails du plan actuel
- **Modification** : Changer la fréquence et le montant
- **Pause/Reprise** : Contrôler l'exécution du plan
- **Prochaine exécution** : Date et heure du prochain DCA automatique

### 💸 Dépôts et Retraits

- **Dépôt USDC** : Ajouter des fonds au vault pour le DCA
- **Retrait USDC** : Retirer des fonds du vault
- **Claim ETH** : Récupérer les ETH accumulés par le DCA

## Installation

```bash
cd packages/front
npm install
```

## Configuration

### 1. Adresses des Contrats

Modifiez le fichier `src/config/contracts.ts` avec les adresses réelles :

```typescript
export const CONTRACT_ADDRESSES = {
  ethereum: {
    osiris: '0x...', // Adresse du contrat Osiris sur Ethereum
    usdc: '0x...',   // Adresse USDC sur Ethereum
  },
  sepolia: {
    osiris: '0x...', // Adresse du contrat Osiris sur Sepolia
    usdc: '0x...',   // Adresse USDC sur Sepolia
  },
};
```

### 2. Project ID WalletConnect

Dans `src/config/contracts.ts`, remplacez `YOUR_PROJECT_ID` par votre Project ID WalletConnect :

```typescript
export const WALLETCONNECT_PROJECT_ID = 'your_project_id_here';
```

### 3. URLs RPC

Dans `src/config/contracts.ts`, configurez vos URLs RPC :

```typescript
export const NETWORKS = {
  ethereum: {
    chainId: 1,
    name: 'Ethereum',
    rpcUrl: 'https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY',
    blockExplorer: 'https://etherscan.io',
  },
  sepolia: {
    chainId: 11155111,
    name: 'Sepolia',
    rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY',
    blockExplorer: 'https://sepolia.etherscan.io',
  },
};
```

## Démarrage

```bash
npm start
```

L'application sera disponible sur `http://localhost:3000`

## Structure du Projet

```
src/
├── components/          # Composants React
│   ├── Header.tsx       # En-tête avec navigation
│   ├── Hero.tsx         # Section principale
│   ├── DcaPlanForm.tsx  # Formulaire de création DCA
│   ├── Features.tsx     # Section fonctionnalités
│   ├── Roadmap.tsx      # Section roadmap
│   ├── Dashboard.tsx    # Tableau de bord principal
│   ├── BalanceCard.tsx  # Affichage des balances
│   ├── DcaPlanCard.tsx  # Gestion du plan DCA
│   └── WithdrawCard.tsx # Retraits de fonds
├── providers/           # Contextes React
│   └── WalletProvider.tsx # Gestion wallet et contrats
├── config/             # Configuration
│   └── contracts.ts    # ABI et adresses des contrats
└── App.tsx             # Composant principal
```

## Utilisation

### 1. Connexion Wallet

- Cliquez sur "Connect Wallet" dans l'en-tête
- Sélectionnez votre wallet préféré
- Autorisez la connexion

### 2. Création d'un Plan DCA

- Sur la page d'accueil, remplissez le formulaire "Create DCA Plan"
- Sélectionnez le token à acheter (ETH)
- Définissez le montant par achat
- Choisissez la fréquence (Daily, Weekly, Monthly)
- Activez le filtre de volatilité si souhaité
- Cliquez sur "Start DCA Plan"

### 3. Dépôt de Fonds

- Dans le formulaire DCA ou sur le dashboard
- Entrez le montant de USDC à déposer
- Cliquez sur "Deposit"
- Autorisez la transaction dans votre wallet

### 4. Gestion du Plan

- Allez sur le Dashboard
- Visualisez votre plan DCA actuel
- Modifiez la fréquence ou le montant
- Pausez ou reprenez le plan
- Voir la date de la prochaine exécution

### 5. Retraits

- Sur le Dashboard, section "Withdraw Funds"
- Retirez vos USDC du vault
- Claim vos ETH accumulés par le DCA

## Technologies Utilisées

- **React 18** : Framework frontend
- **TypeScript** : Typage statique
- **Tailwind CSS** : Styling
- **Wagmi** : Hooks Ethereum
- **RainbowKit** : Connexion wallet
- **Viem** : Bibliothèque Ethereum
- **React Query** : Gestion d'état et cache

## Déploiement

```bash
npm run build
```

Les fichiers de production seront dans le dossier `build/`.

## Support

Pour toute question ou problème, consultez la documentation du contrat Osiris ou contactez l'équipe de développement.
