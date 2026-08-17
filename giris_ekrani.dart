                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Uzmanlik Alani (birden fazla secilebilir):',
                        style: TextStyle(color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _uzmanlikSecenekleri
                          .map((alan) {
                            final seciliMi = seciliUzmanliklar.contains(alan);
                            return FilterChip(
                              label: Text(al
