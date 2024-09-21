import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_quill/flutter_quill.dart' as fq;
import 'package:meta/meta.dart' show immutable;

import '../flutter_quill_extensions.dart';

@immutable
class FlutterQuillEmbeds {
  const FlutterQuillEmbeds._();

  /// Returns a list of embed builders for [fq.QuillEditor].
  ///
  /// This method provides a collection of embed builders to enhance the
  /// functionality
  /// of a [fq.QuillEditor]. It offers customization options for
  /// handling various types of
  /// embedded content, such as images, videos, and formulas.
  ///
  /// The method returns a list of [fq.EmbedBuilder] objects that can be used with
  ///  QuillEditor
  /// to enable embedded content features like images, videos, and formulas.
  ///
  ///
  /// final quillEditor = QuillEditor(
  ///   // Other editor configurations
  ///   embedBuilders: embedBuilders,
  /// );
  /// ```
  ///
  static List<fq.EmbedBuilder> editorBuilders() {
    if (kIsWeb) {
      throw UnsupportedError(
        'The editorBuilders() is not for web, please use editorWebBuilders() '
        'instead',
      );
    }
    return [
      QuillEditorTableEmbedBuilder(),
    ];
  }

  /// Returns a list of embed builders specifically designed for web support.
  ///
  /// [QuillEditorWebImageEmbedBuilder] is the embed builder for handling
  ///  images on the web. this will use <img> tag of HTML
  ///
  /// [QuillEditorWebVideoEmbedBuilder] is the embed builder for handling
  ///  videos iframe on the web. this will use <iframe> tag of HTML
  ///
  static List<fq.EmbedBuilder> editorWebBuilders() {
    if (!kIsWeb) {
      throw UnsupportedError(
        'The editorsWebBuilders() is only for web, please use editorBuilders() '
        'instead for other platforms',
      );
    }
    return [];
  }

  /// Returns a list of default embed builders for QuillEditor.
  ///
  /// It will use [editorWebBuilders] for web and [editorBuilders] for others
  ///
  /// It's not customizable with minimal configurations
  static List<fq.EmbedBuilder> defaultEditorBuilders() {
    return kIsWeb ? editorWebBuilders() : editorBuilders();
  }

  /// Returns a list of embed button builders to customize the toolbar buttons.
  ///
  /// If you don't want to show one of the buttons for soem reason,
  /// pass null to the options of it
  ///
  /// The returned list contains embed button builders for the Quill toolbar.
  static List<fq.EmbedButtonBuilder> toolbarButtons({
    QuillToolbarTableButtonOptions? tableButtonOptions,
  }) =>
      [
        if (tableButtonOptions != null)
          (controller, toolbarIconSize, iconTheme, dialogTheme) =>
              QuillToolbarTableButton(
                controller: controller,
                options: tableButtonOptions,
              ),
      ];
}
