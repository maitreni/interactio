# ⚡ Interactio

Outil d'interactions pédagogiques en temps réel. Sondages, remue-méninges, questionnaires et nuages de mots — sans inscription pour les participants.

---

## Sommaire

1. [Présentation](#présentation)
2. [Fichiers fournis](#fichiers-fournis)
3. [Installation et configuration](#installation-et-configuration)
4. [Schéma de base de données](#schéma-de-base-de-données)
5. [Authentification par PIN](#authentification-par-pin)
6. [Types d'interactions](#types-dinteractions)
7. [Minuteur](#minuteur)
8. [Export et import](#export-et-import)
9. [Participation anonyme](#participation-anonyme)
10. [Déploiement](#déploiement)
11. [Mode hors ligne](#mode-hors-ligne)
12. [Sécurité](#sécurité)

---

## Présentation

Interactio est une application web **single-file** (un seul fichier HTML) conçue pour les animateurs pédagogiques. Elle permet de créer des activités interactives et d'en afficher les résultats en temps réel devant un groupe.

**Aucune installation** n'est requise côté participants — ils rejoignent via un code à 6 caractères ou un QR code, sans créer de compte.

### Fonctionnalités principales

- 4 types d'interactions : sondage, remue-méninges, questionnaire, nuage de mots
- Résultats en temps réel via WebSockets (Supabase Realtime)
- Identification animateur par identifiant + PIN (sans e-mail ni mot de passe)
- Minuteur configurable par interaction
- Export des réponses en Excel (XLSX) et PDF
- Export / import des interactions en JSON
- Mode hors ligne avec stockage local (localStorage)

---

## Fichiers fournis

| Fichier | Description |
|---|---|
| `interactio-pin.html` | Application complète (à héberger ou ouvrir directement) |
| `schema-v2.sql` | Schéma de base de données Supabase |
| `README.md` | Ce fichier |

---

## Installation et configuration

### Étape 1 — Créer un projet Supabase

1. Aller sur [supabase.com](https://supabase.com) et créer un compte gratuit
2. Créer un nouveau projet
3. Noter l'**URL du projet** et la **clé anon publique** (Project Settings → API)

### Étape 2 — Créer le schéma de base de données

1. Dans Supabase, aller dans **SQL Editor**
2. Copier-coller le contenu de `schema-v2.sql`
3. Cliquer sur **Run**

### Étape 3 — Configurer l'application

Ouvrir `interactio-pin.html` dans un éditeur de texte et modifier les deux constantes au début du script :

```javascript
const SUPABASE_URL = 'https://VOTRE-PROJET.supabase.co';
const SUPABASE_KEY = 'VOTRE-CLE-ANON-PUBLIQUE';
```

Remplacer par vos vraies valeurs. La clé à utiliser est la clé **anon** (publique), jamais la clé `service_role`.

> **Alternative sans modifier le fichier** : laisser les valeurs par défaut et renseigner l'URL et la clé via la bannière de configuration qui apparaît au chargement de la page. Ces valeurs sont mémorisées dans le navigateur.

### Étape 4 — Lancer l'application

Ouvrir `interactio-pin.html` dans un navigateur. L'application est prête.

---

## Schéma de base de données

Le fichier `schema-v2.sql` crée les tables suivantes :

### `animators`
Stocke les animateurs identifiés par PIN. Le PIN n'est jamais stocké en clair — seul son empreinte SHA-256 (combinée à l'identifiant) est conservée.

| Colonne | Type | Description |
|---|---|---|
| `id` | uuid | Identifiant unique |
| `pin_hash` | text | SHA-256 de `identifiant:pin` |
| `pin_hint` | text | Indice mémo-technique (facultatif) |
| `failed_attempts` | int | Compteur anti brute-force |
| `locked_until` | timestamptz | Verrouillage temporaire |

### `interactions`
Les activités créées par les animateurs.

| Colonne | Type | Description |
|---|---|---|
| `id` | uuid | Identifiant unique |
| `animator_id` | uuid | Référence à l'animateur |
| `code` | text | Code d'accès à 6 caractères (unique) |
| `title` | text | Titre de l'interaction |
| `type` | text | `poll`, `brainstorm`, `quiz` ou `wordcloud` |
| `content` | jsonb | Questions, options, consignes |
| `options` | jsonb | Paramètres (anonymat, réponses multiples, minuteur) |

### `sessions`
Chaque lancement d'une interaction crée une nouvelle session. Une même interaction peut être lancée plusieurs fois avec des résultats séparés.

### `responses`
Les réponses des participants. Toujours anonymes — aucune donnée personnelle n'est stockée.

---

## Authentification par PIN

L'accès animateur (création d'interactions, tableau de bord) est protégé par un système **identifiant + PIN à 6 chiffres**.

### Création d'un espace animateur

1. Cliquer sur **Créer** ou **Mes interactions** depuis l'accueil
2. Choisir un identifiant unique (prénom, initiales, pseudonyme…)
3. Saisir un PIN à 6 chiffres
4. Confirmer le PIN

L'identifiant et le PIN sont combinés (`identifiant:pin`) avant le hachage SHA-256. Deux animateurs ayant le même PIN mais des identifiants différents ont des espaces totalement séparés.

### Connexion

L'identifiant est mémorisé dans le navigateur. Les visites suivantes demandent uniquement le PIN.

### Sécurité anti brute-force

Après 5 tentatives incorrectes consécutives, le compte est verrouillé pendant 5 minutes.

### PIN oublié

En cas d'oubli, l'option **Changer d'identifiant** permet de repartir sur un nouvel espace. L'ancien espace reste en base mais n'est plus accessible sans le PIN d'origine.

> ⚠️ Il n'existe pas de récupération de PIN. Choisissez un PIN mémorable ou notez-le.

---

## Types d'interactions

### 📊 Sondage (`poll`)
Question à choix multiples. Les résultats s'affichent en barres horizontales avec pourcentages mis à jour en temps réel.

**Configuration** : question + 2 à 16 options de réponse.

### 💡 Remue-méninges (`brainstorm`)
Zone de saisie libre. Les idées soumises apparaissent en cartes animées sur l'écran de l'animateur.

**Configuration** : consigne ou question ouverte.

### 🎓 Questionnaire (`quiz`)
QCM avec correction immédiate. Les participants voient si leur réponse est correcte ou incorrecte. L'animateur voit la distribution des réponses par option.

**Configuration** : questions + réponses + cases à cocher pour indiquer la ou les bonne(s) réponse(s).

### ☁ Nuage de mots (`wordcloud`)
Les participants soumettent 1 à 3 mots séparés par des virgules. Le nuage se forme en temps réel avec des tailles proportionnelles à la fréquence des mots.

**Configuration** : consigne ou question.

---

## Minuteur

Un minuteur peut être ajouté à n'importe quelle interaction lors de sa création.

### Configuration
Dans l'éditeur d'interaction, cocher **Minuteur** et saisir la durée en minutes.

### Comportement pendant la session
- Affichage du temps restant en grand dans l'écran live
- Boutons **Pause** et **Remettre à zéro**
- Passage en orange à 1 minute restante
- Passage en rouge clignotant à 30 secondes
- À la fin du temps : overlay avec le choix de **continuer la session** ou de **la terminer**

---

## Export et import

### Export des réponses

Disponible depuis deux endroits :

- **Session live** : boutons 📊 et 📄 en bas de l'écran de résultats
- **Tableau de bord** : icônes 📊 et 📄 sur chaque interaction

#### Format Excel (XLSX)
Deux feuilles :
- **Réponses** : résultats selon le type (options + votes + pourcentages pour les sondages, idées pour le remue-méninges, mots + occurrences pour le nuage de mots)
- **Infos** : métadonnées (titre, type, code, date, nombre de réponses)

#### Format PDF
Document A4 avec en-tête (titre, code, date) et résultats mis en forme. Les sondages et questionnaires incluent des barres de résultats visuelles.

---

### Export des interactions

Bouton **📤 Exporter** dans le tableau de bord. Génère un fichier JSON contenant toutes vos interactions (sans les réponses).

```json
{
  "version": 2,
  "exported_at": "2025-03-06T10:00:00.000Z",
  "interactions": [
    {
      "title": "Mon sondage",
      "type": "poll",
      "content": { "question": "...", "options": ["A", "B", "C"] },
      "options": { "anonymous": true, "multiple": false, "timer": 5 }
    }
  ]
}
```

### Import des interactions

Bouton **📥 Importer** dans le tableau de bord. Accepte un fichier JSON exporté depuis Interactio.

- Chaque interaction importée reçoit un **nouveau code** pour éviter les conflits
- Les interactions importées sont associées à votre espace animateur actuel
- Compatible avec les exports d'autres animateurs

---

## Participation anonyme

Les participants n'ont besoin d'aucun compte. Leur seule identification est un **token aléatoire** généré dans leur navigateur (`sessionStorage`) — aucune donnée personnelle n'est collectée ni transmise.

### Rejoindre une session

Trois méthodes :
1. Aller sur l'URL de l'application et saisir le code à 6 caractères
2. Scanner le QR code affiché par l'animateur
3. Ouvrir directement l'URL avec paramètre : `interactio.html?join=ABC123`

---

## Déploiement

Interactio est un fichier HTML autonome. Il peut être hébergé de multiples façons :

### GitHub Pages (gratuit)
1. Créer un dépôt GitHub
2. Placer `interactio-pin.html` à la racine (renommer en `index.html`)
3. Activer GitHub Pages dans les paramètres du dépôt

### Netlify / Vercel (gratuit)
Glisser-déposer le fichier HTML dans l'interface de déploiement.

### Serveur web
Copier le fichier dans le répertoire public de n'importe quel serveur web (Apache, Nginx, Caddy…).

### En local (développement)
```bash
npx serve .
# ou
python3 -m http.server 8080
```

> ⚠️ Certaines fonctionnalités (SHA-256 natif, WebSockets Supabase) nécessitent HTTPS ou `localhost`. L'ouverture directe en `file://` fonctionne grâce au fallback SHA-256 intégré, mais le temps réel Supabase sera inactif.

---

## Mode hors ligne

Si Supabase n'est pas configuré ou inaccessible, l'application bascule automatiquement en **mode local** :

- Les interactions sont stockées dans le `localStorage` du navigateur
- Les réponses sont également stockées localement
- Le temps réel n'est pas disponible
- Les exports fonctionnent normalement

Ce mode est utile pour tester l'application sans connexion internet.

---

## Sécurité

### Clé Supabase
La clé `anon` utilisée dans le fichier est une **clé publique** conçue pour être exposée côté client. Elle ne donne accès qu'aux opérations autorisées par les politiques Row Level Security (RLS) définies dans le schéma.

Ne jamais utiliser la clé `service_role` dans le fichier HTML.

### Row Level Security
Toutes les tables ont RLS activé. Les politiques actuelles permettent la lecture et l'écriture publiques, ce qui est intentionnel pour garantir la participation anonyme sans authentification Supabase.

Pour renforcer la sécurité en production, il est possible de restreindre les domaines autorisés depuis **Supabase → Authentication → URL Configuration**.

### Données personnelles
Aucune donnée personnelle n'est collectée côté participants. Les animateurs ne stockent qu'un identifiant (choisi librement) et une empreinte SHA-256 de leur PIN — jamais le PIN lui-même.

---

*Interactio — Application pédagogique open source*
