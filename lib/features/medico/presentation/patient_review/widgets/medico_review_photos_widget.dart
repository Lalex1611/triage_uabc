import 'package:flutter/material.dart';

/// Fotografías del paramédico (mockup 02): miniaturas en fila horizontal; al
/// tocar una se abre en grande
class MedicoReviewPhotos extends StatelessWidget {
  const MedicoReviewPhotos({super.key, required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'El paramédico no adjuntó fotografías.',
          style: TextStyle(fontSize: 13, color: Color(0xFF8A949E)),
        ),
      );
    }
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: 6),
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _thumb(context, urls[i]),
      ),
    );
  }

  Widget _thumb(BuildContext context, String url) {
    return GestureDetector(
      onTap: () => _open(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 90,
          height: 90,
          color: const Color(0xFFB8C2CC),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.image_outlined, color: Colors.white, size: 28),
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: Image.network(url, fit: BoxFit.contain)),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Cerrar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
