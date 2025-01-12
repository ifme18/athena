import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

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

  Future<void> _sharePdf() async {
    try {
      // For web platform
      if (kIsWeb) {
        final blob = html.Blob([pdfData], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Create a temporary link and trigger the share dialog
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', downloadFileName)
          ..click();

        // Clean up
        html.Url.revokeObjectUrl(url);
      }
      // For mobile platforms
      else {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$downloadFileName';
        final file = File(filePath);
        await file.writeAsBytes(pdfData);

        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Sharing PDF: $downloadFileName',
        );
      }
    } catch (e) {
      print('Error sharing PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.download),
              label: const Text('Download PDF'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _sharePdf,
              icon: const Icon(Icons.share),
              label: const Text('Share PDF'),
            ),
          ],
        ),
      ),
    );
  }
}


