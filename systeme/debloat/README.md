# Auto-Debloat & Setup ULTIMATE (Version TUI Ultra-Stable)

Cette version a été spécialement conçue pour offrir une **stabilité absolue** en remplaçant l'interface graphique par une interface textuelle interactive (TUI) moderne et colorée. Elle élimine tout risque de conflit avec les pilotes graphiques tout en conservant l'intégralité des fonctionnalités "Ultimate".

## 🚀 Pourquoi cette version ?
- **Stabilité Totale** : Fonctionne directement dans votre terminal, sans dépendre de Zenity ou de GTK.
- **Légèreté** : Pas de surcharge graphique, exécution instantanée.
- **Compatibilité** : Testée pour fonctionner parfaitement sur Ubuntu, Arch et Fedora, même avec des pilotes graphiques complexes.

## 🔥 Fonctionnalités Conservées
1.  **Debloat & Optimisation** : Nettoyage des bloatwares, optimisation des miroirs système et configuration du pare-feu (UFW).
2.  **Setup de Base** : Mise à jour complète, installation de Docker, Node.js, et outils GNOME.
3.  **Personnalisation** : Copie automatique de vos thèmes et icônes depuis `.themes/` et `.icons/`.
4.  **Profils Logiciels** : Installation groupée de VS Code, Chrome, Ollama, etc.
5.  **Logging** : Suivi détaillé de chaque action dans `logs/setup.log`.

## 🛠 Utilisation
Le script est maintenant encore plus simple à utiliser :
1.  Ouvrez votre terminal.
2.  Accédez au dossier du projet.
3.  Lancez le script :
    ```bash
    chmod +x setup.sh
    ./setup.sh
    ```
4.  Naviguez dans les menus en utilisant les chiffres de votre clavier.

## 📂 Structure du Projet
- `setup.sh` : Le moteur TUI.
- `logs/` : Journal d'installation.
- `.themes/` & `.icons/` : Vos ressources de personnalisation.
- `my_extensions.txt` : Liste de vos extensions GNOME.
