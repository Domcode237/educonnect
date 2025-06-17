import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:educonnect/coeur/constantes/textes.dart';
import 'package:educonnect/coeur/constantes/images.dart';
import 'package:educonnect/vues/commun/login.dart';

class Carousel extends StatefulWidget {
  @override
  State<Carousel> createState() => CarouselState();
}

class CarouselState extends State<Carousel> {
  final PageController _controleur = PageController();
  int indexPageCourant = 0;

  final List<Map<String, String>> Pages = [
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

  void pageSuivente() {
    if (indexPageCourant < Pages.length - 1) {
      _controleur.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void allerALaDernierePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void allerALaPageDeConnexion() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
    ? const Color.fromARGB(255, 255, 255, 255) // Blanc un peu gris
    : theme.scaffoldBackgroundColor,

     // backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controleur,
            onPageChanged: (index) => setState(() {
              indexPageCourant = index;
            }),
            itemCount: Pages.length,
            itemBuilder: (context, index) {
              return CarouselPageCard(page: Pages[index]);
            },
          ),

          // Bouton en haut à droite
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: allerALaDernierePage,
              child: const Text("Passer"),
            ),
          ),

          // Indicateur en bas à gauche
          Positioned(
            bottom: 38,
            left: 20,
            child: CarouselIndicator(
              currentPage: indexPageCourant,
              count: Pages.length,
            ),
          ),

          // Bouton flèche ou "Commencer"
          Positioned(
            bottom: 30,
            right: 20,
            child: indexPageCourant == Pages.length - 1
                ? ElevatedButton(
                    onPressed: allerALaPageDeConnexion,
                    style: theme.elevatedButtonTheme.style,
                    child: const Text(
                      "Commencer",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                : ElevatedButton(
                      onPressed: pageSuivente,
                      style: theme.elevatedButtonTheme.style?.copyWith(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50), // Ajuste ici pour plus ou moins arrondi
                          ),
                        ),
                        minimumSize: MaterialStateProperty.all(const Size(24, 40)),

                        //padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 5, vertical: 18)),
                      ),
                      child: const Icon(Icons.chevron_right,),
                    )
                  ),
                ],
              ),
            );
          }
        }

class CarouselPageCard extends StatelessWidget {
  final Map<String, String> page;
  const CarouselPageCard({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final imagePath = isDark ? page['darkImage']! : page['lightImage']!;

    final titleStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.textTheme.headlineMedium?.color,
    );

    final subtitleStyle = theme.textTheme.bodyLarge?.copyWith(
      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
      fontWeight: FontWeight.bold,
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

        return constraints.maxHeight > minHeight
            ? Center(child: content)
            : SafeArea(child: SingleChildScrollView(child: content));
      },
    );
  }
}

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
