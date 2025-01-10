import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;

class WebPdfViewer extends StatefulWidget {
  final Uint8List pdfData;
  final String title;
  final String downloadFileName;
  final Color? appBarColor;
  final bool showDownloadButton;

  const WebPdfViewer({
    Key? key,
    required this.pdfData,
    this.title = 'PDF Viewer',
    this.downloadFileName = 'document.pdf',
    this.appBarColor,
    this.showDownloadButton = true,
  }) : super(key: key);

  @override
  State<WebPdfViewer> createState() => _WebPdfViewerState();
}

class _WebPdfViewerState extends State<WebPdfViewer> {
  late final String viewId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    viewId = 'pdf-viewer-${DateTime.now().millisecondsSinceEpoch}';
    _initializePdfViewer();
  }

  Future<void> _initializePdfViewer() async {
    try {
      if (widget.pdfData.isEmpty) {
        throw Exception('PDF data is empty');
      }

      _registerView();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load PDF: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _registerView() {
    final base64 = base64Encode(widget.pdfData);
    final pdfUrl = 'data:application/pdf;base64,$base64';

    // Using the correct platform views registry
    if (kIsWeb) {
      final viewFactory = (int viewId) {
        final iframe = html.IFrameElement()
          ..style.border = 'none'
          ..style.height = '100%'
          ..style.width = '100%'
          ..src = pdfUrl;

        // Add load event listener
        iframe.onLoad.listen((_) {
          setState(() {
            _isLoading = false;
          });
        });

        return iframe;
      };

      // Register the view factory

    }
  }

  void _downloadPdf() {
    try {
      final blob = html.Blob([widget.pdfData], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..style.display = 'none'
        ..download = widget.downloadFileName;

      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download PDF: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.appBarColor ?? Theme.of(context).primaryColor,
        actions: [
          if (widget.showDownloadButton)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _isLoading ? null : _downloadPdf,
              tooltip: 'Download PDF',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Center(
      child: SizedBox.expand(
        child: HtmlElementView(
          viewType: viewId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}