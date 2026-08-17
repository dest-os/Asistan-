    final sonuc = await _apiBilgisiServisi.apiBilgisiGonder(api.apiAdresi, {
      'metin': _konustuguMetin,
    });
    if (sonuc != null) {
      setState(() {
        _konustuguMetin = sonuc['cevap'] ?? '';
      });
    }
  }

  Future<void> _paylas() async {
    final dosyaYolu = await _screenshotController.capture();
    await Share.shareFiles([dosyaYolu]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Screenshot(
        controller: _screenshotController,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'Merhaba ${widget.kullaniciAdi}, senin icin ne yapabilirim?',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height:
