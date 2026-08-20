// ... (Diğer kısımlar aynı kalıyor, sadece build metodundaki Stack içeriğini güncelliyoruz) ...

  @override
  Widget build(BuildContext context) {
    if (!_yuklendi) return const Scaffold(backgroundColor: Colors.black);

    // MİKROFON BUTONUNUN TASARIMDAKİ KOORDİNATLARI (BUNLAR ASLA DEĞİŞMEYECEK)
    double micLeft = MediaQuery.of(context).size.width * 0.665;
    double micBottom = MediaQuery.of(context).size.height * 0.08;
    double micWidth = 45;
    double micHeight = 45;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Arka Plan
          Positioned.fill(child: Image.asset(_bgImage, fit: BoxFit.fill)),

          // 2. Metin Alanı
          Positioned(
            left: MediaQuery.of(context).size.width * 0.26,
            right: MediaQuery.of(context).size.width * 0.30,
            top: MediaQuery.of(context).size.height * 0.38,
            height: 75,
            child: Container(color: Colors.black, alignment: Alignment.center, child: Text(_metin, style: const TextStyle(color: Colors.white))),
          ),

          // 3. BUTONLAR (Tasarımındaki orijinal yerleri)
          
          // --- MİKROFON BUTONU (ALTINDAKİ) ---
          Positioned(
            left: micLeft,
            bottom: micBottom,
            width: micWidth,
            height: micHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _otomatikDinlemeBaslat,
              child: Container(color: Colors.transparent), 
            ),
          ),

          // --- ANİMASYON KATMANI (BUTONUN ÜZERİNE BİNDİRİLEN) ---
          // Bu kısım butonun üzerine tam oturur ve dokunuşu engellemez (IgnorePointer)
          if (_dinliyor || _konusuyor)
            Positioned(
              left: micLeft,
              bottom: micBottom,
              width: micWidth,
              height: micHeight,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Halka Efekti (Butonun etrafında)
                          Container(
                            width: 30 + (_waveController.value * 20),
                            height: 30 + (_waveController.value * 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyan.withOpacity(1 - _waveController.value), 
                                width: 2
                              ),
                            ),
                          ),
                          // Ses Frekans Çubukları (Butonun tam merkezinde)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [1, 2, 3].map((i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              width: 3,
                              height: 10 + (sin(_waveController.value * 10 + i) * 8).abs(),
                              color: Colors.cyan,
                            )).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            
          // ... (Diğer butonların - Sessiz Mod vb. - Positioned blokları aynen kalacak) ...
        ],
      ),
    );
  }
