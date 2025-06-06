//importation de bivliotheques necessaires
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

//importation du fichier local contenant les texte
import 'package:educonnect/coeur/constantes/textes.dart';

//importation du fichier contenant les liens des images sur un format texte
import 'package:educonnect/coeur/constantes/images.dart';

//importation de la pages de connexion qui doit etrer apeler lors qu'on clique sur le bbouton "commencer"
import 'package:educonnect/vues/commun/login.dart';

//definir le widget principale qui est un carousel qui doit permetre de presenter l'application
class Carousel extends StatefulWidget{
  @override
  State<Carousel> createState() {
    return CarouselState();
  }
}

//classe avec etat pour gerer l'etat du carousel
class CarouselState extends State<Carousel> {

  //definir un controleur de page
  final PageController _controleur = PageController();

  //index de la pages
  int indexPageCourant = 0;

  //definir une liste pour les element des diferentes pages(titre, sous-titre, image pour theme claire et sombre)
  final List<Map<String, String>> Pages = 
  [
    {
      'title': TextesApp.carouselTitre1,
      'subtitle': TextesApp.carouselSousTitre1,
      'lightImage': ImagesApp.carouselImageLight1,
      'darkImage': ImagesApp.carouselImageDark1,
    },
    {
      'title': TextesApp.carouselTitre2,
      'subtitle': TextesApp.carouselSousTitre2,
      'lightImage': ImagesApp.carouselImageLight2,
      'darkImage': ImagesApp.carouselImageDark2,
    },
    {
      'title': TextesApp.carouselTitre3,
      'subtitle': TextesApp.carouselSousTitre3,
      'lightImage': ImagesApp.carouselImageLight3,
      'darkImage': ImagesApp.carouselImageDark3,
    },
    {
      'title': TextesApp.carouselTitre4,
      'subtitle': TextesApp.carouselSousTitre4,
      'lightImage': ImagesApp.carouselImageLight4,
      'darkImage': ImagesApp.carouselImageDark4,
    },
    {
      'title': TextesApp.carouselTitre5,
      'subtitle': TextesApp.carouselSousTitre5,
      'lightImage': ImagesApp.carouselImageLight5,
      'darkImage': ImagesApp.carouselImageDark5,
    },
  ];

  //methode qui doit permettree de naviger entre les pages du carousel
  void pageSuivente()
  {
    if(indexPageCourant < Pages.length -1){
      _controleur.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  //passer directement a la dirniere page grace au bouton souter
  void allerALaDernierePage()
  {
    _controleur.animateToPage(
      Pages.length-1,
      duration: const Duration(microseconds: 500), 
      curve: Curves.easeInOut
    );
  }

  //rediriger vers la pages de connexion apres le carousel
  void allerALaPageDeConnexion()
  {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => LoginPage())
    );
  }

  //construction de l'interface du carousel
  @override
  Widget build(BuildContext context) {
    //recuperer le theme du systeme
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controleur,
            onPageChanged: (index) => setState(() {
              indexPageCourant = index;
            }),
            itemCount: Pages.length,
            itemBuilder: (context, index)
            {
              return CarouselPageCard(page: Pages[index]);
            }
          ),

          //bouton placer en haut a droit
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: allerALaDernierePage, 
              child: Text("Passer"),
            )  
          ),

          //indicateur de page en bas a gauche
          Positioned(
            bottom: 30,
            left: 20,
            child: CarouselIndicator
            (
              currentPage: indexPageCourant,
              count: Pages.length,
            )
          ),

          //bouton fleche ou commencer
          // Flèche ou bouton "Commencer" en bas à droite selon la page actuelle
          Positioned(
            bottom: 20,
            right: 20,
            child: indexPageCourant == Pages.length - 1
                ? ElevatedButton(
                    onPressed: allerALaPageDeConnexion,
                    style: theme.elevatedButtonTheme.style,
                    child: const Text("Commencer"),
                  )
                : GestureDetector(
                    onTap: pageSuivente,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.primaryColor,
                      child: Icon(
                        Icons.chevron_right,
                        color: theme.brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ),
          )
        ],
      ),
    );
  }
}

//composent de la page
class CarouselPageCard extends StatelessWidget
{
  final Map<String, String> page;
  const CarouselPageCard({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Choisit l'image en fonction du thème
    final imagePath = isDark ? page['darkImage']! : page['lightImage']!;

    // Style pour le titre
    final titleStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    // Style pour le sous-titre
    final subtitleStyle = theme.textTheme.bodyLarge?.copyWith(
      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const minHeight = 300;

        final content = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Text(
                page['title']!,
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
              const SizedBox(height: 20),
              Image.asset(imagePath, height: 250),
              const SizedBox(height: 20),
              Text(
                page['subtitle']!,
                textAlign: TextAlign.center,
                style: subtitleStyle,
              ),
            ],
          ),
        );

        // Rend le contenu scrollable sur petits écrans
        return constraints.maxHeight > minHeight
            ? Center(child: content)
            : SafeArea(child: SingleChildScrollView(child: content));
      },
    );
  }
}

// === COMPOSANT DES INDICATEURS DE PAGE ===
// Affiche les petits points d'indication (avec animation)
class CarouselIndicator extends StatelessWidget {
  final int currentPage;
  final int count;

  const CarouselIndicator({
    required this.currentPage,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSmoothIndicator(
      activeIndex: currentPage,
      count: count,
      effect: ExpandingDotsEffect(
        dotHeight: 8,
        dotWidth: 16,
        expansionFactor: 2.5,
        spacing: 6,
        activeDotColor: theme.primaryColor,
        dotColor: theme.primaryColor.withOpacity(0.3),
      ),
    );
  }
}