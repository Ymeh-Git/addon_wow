# Warrior_Aura_1_0

Addon World of Warcraft 3.3.5 (Wrath of the Lich King) pour le Guerrier Protection.

# Le concept de base :
c'est un annonceur de sorts pour la classe Guerrier, plus précisément la spécialisation Protection. Il a pour but d'annoncer les sorts d'intérêts, tels que 'Vengeance', 'Onde de choc', 'Heurt bouclier', dès qu'ils sont disponibles que ce soit par leur temps de recharge et leur activation, exemple 'Vengeance' n'est actif qu'après un blocage, 'Onde de choc' est disponible qu'avec de la rage et son temps de récupération.

# L'aspect visuel :
Un équivalent de l'addon 'Cheese', une aura autour du centre de l'écran, deux icones qui se répètent dans un sens et dans l'autre. Donc un effet visuel à l'écran et un petit effet sonore pour indiquer la disponibilité.

# Les interactions :
Avoir un icone sur la map en haut à droite pour on / off l'addon, adapter la taille du visuel, réduire, augmenter ou enlever le son.

# Les déclencheurs :
Comme indiqué dans le concept de base :

- 'Vengeance' : disponible après blocage, esquive ou parade, nécessite 5 de rage et 5s de recharge.

- 'Onde de choc' : 20s de recharge, 15 de rage

- 'Heurt bouclier' : si [Epée et bouclier] talent actif

---

# Version 1.0 : ce qui est fait

## Affichage à l'écran
- 3 positions autour du centre de l'écran : **Gauche**, **Haut** et **Droite**.
- Chaque position affiche soit l'**icône du sort**, soit une **aura** lumineuse façon Cheese.
- Les auras des côtés sont affichées en miroir (gauche / droite), et tournées d'un quart de tour si une aura prévue pour le haut est placée sur un côté (et inversement).
- **Fondu** à l'apparition et à la disparition de l'image.
- **Pulsation** de l'image tant que le chrono de recharge s'affiche.

## Déclencheurs
Chaque position peut recevoir n'importe quel sort de la liste, avec trois types de déclencheurs :

| Type | Quand l'image apparaît | Chrono |
|---|---|---|
| Utilisable (Vengeance) | Dès que le sort est utilisable, après un blocage, une esquive ou une parade | Temps de recharge complet, tant que l'image est affichée |
| Recharge (Onde de choc et les autres) | Quand la recharge est finie et que la rage est suffisante | Pendant les 5 dernières secondes de recharge |
| Proc (Heurt de bouclier) | Tant que le buff Épée et bouclier est actif | Aucun |

Sorts disponibles : Vengeance, Onde de choc, Heurt de bouclier (au proc d'Épée et bouclier ou à la recharge), Charge, Interception, Intervention, Coup de tonnerre, Provocation, Cri de défi, Coup de bouclier, Renvoi de sort, Désarmement, Coup traumatisant, Lancer héroïque, Maîtrise du blocage, Mur protecteur, Dernier rempart.

Par défaut : Vengeance à gauche, Heurt de bouclier (Épée et bouclier) en haut, Onde de choc à droite.

## Interface
- **Bouton sur la minimap** : un clic ouvre ou ferme la fenêtre, un glisser le déplace autour de la minimap.
- **Fenêtre d'options** déplaçable, fermeture avec la croix ou la touche Échap.
- **Onglet « Sons »**, pour chaque position :
  - un menu déroulant avec 6 sons (Alerte raid, Appel prêt, Ping carte, Réveil, Drapeau JcJ, Niveau gagné), avec aperçu au choix ;
  - une case « Muet ».
- **Onglet « Sorts & Auras »**, pour chaque position :
  - un menu déroulant pour le sort ;
  - un menu déroulant pour l'aura (icône du sort, auras des côtés, auras du haut) ;
  - les menus restent ouverts après un clic pour enchaîner les essais ;
  - **mode test** : tant que l'onglet est ouvert, les 3 images s'affichent en continu, sans son, pour régler le visuel.
- Un bouton **« Paramètres par défaut »** dans chaque onglet.
- Tous les réglages sont sauvegardés (`Warrior_Aura_1_0_DB`) : sons, muet, sorts, auras, position du bouton de la minimap et de la fenêtre.

## Pistes pour la suite
Prévu dans le pitch mais pas encore fait :
- activer / désactiver l'addon depuis l'interface ;
- régler la taille du visuel.

---

# Crédits

- **Textures des auras** (dossier `Textures/Auras`) : © Blizzard Entertainment. Ce sont les « Spell Activation Overlays » de World of Warcraft, récupérées via l'addon Cheese. Elles ne sont pas libres de droits et restent la propriété de Blizzard Entertainment.
- **Icônes des sorts et sons** : fichiers du jeu World of Warcraft, © Blizzard Entertainment.
- World of Warcraft est une marque de Blizzard Entertainment. Warrior_Aura_1_0 est un addon non officiel, non affilié à Blizzard Entertainment.
