lib/
├── main.dart                                # Point d'entrée
├── app.dart                                 # Widget racine (MaterialApp)
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart                  # Palette (rouge, jaune, vert)
│   │   └── app_theme.dart                   # ThemeData global
│   └── constants/
│       └── app_constants.dart               # Textes fixes, tailles, durées
│
├── data/
│   └── local/
│       ├── database_helper.dart             # Init SQLite + schéma
│       ├── models/
│       │   ├── materiel_model.dart
│       │   └── user_model.dart
│       └── repositories/
│           ├── materiel_repository.dart     # CRUD matériels
│           └── auth_repository.dart         # Auth locale (PIN/mot de passe)
│
├── presentation/
│   ├── screens/
│   │   ├── splash/splash_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── home/home_screen.dart
│   │   ├── materiels/
│   │   │   ├── materiels_screen.dart
│   │   │   └── add_materiel_screen.dart
│   │   └── import_export/
│   │       ├── import_screen.dart
│   │       └── export_screen.dart
│   └── widgets/
│       ├── bottom_nav_bar.dart               # Barre verte (accueil/importer/matériels/exporter)
│       ├── primary_button.dart               # Bouton jaune arrondi
│       └── stat_card.dart                    # Cartes "Nombre d'import/export"
│
└── routes/
    └── app_routes.dart                       # Table de routes nommées