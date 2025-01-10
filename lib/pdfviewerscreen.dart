import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class WebPdfViewer extends StatelessWidget {
  final Uint8List pdfData;
  final String downloadFileName;

  const WebPdfViewer({
    Key? key,
    required this.pdfData,
    this.downloadFileName = 'document.pdf',
  }) : super(key: key);

  void _downloadPdf() {
    try {
      final blob = html.Blob([pdfData], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..download = downloadFileName
        ..style.display = 'none';

      html.document.body?.append(anchor);
      anchor.click();

      // Clean up
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error downloading PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _downloadPdf,
          icon: const Icon(Icons.download),
          label: const Text('Download PDF'),
        ),
      ),
    );
  }
}


