import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/v_colors.dart';
import '../../theme/v_commune_chat_theme.dart';
import '../../theme/v_tokens.dart';

/// Commune chat markdown: bold, italic, code, spoilers, mentions, links.
class VMessageContent extends StatelessWidget {
  final String content;
  final Color textColor;
  final bool selectable;
  /// When set, @mentions matching this handle render with accent styling.
  final String? accentMentionHandle;

  const VMessageContent({
    super.key,
    required this.content,
    required this.textColor,
    this.selectable = true,
    this.accentMentionHandle,
  });

  static final _spoilerPattern = RegExp(r'\|\|([^|]+)\|\|');
  static final _mentionPattern = RegExp(r'@(\w+)');
  static final _urlPattern = RegExp(r'https?://[^\s<>]+', caseSensitive: false);

  /// Detects if a message is emoji-only (1-8 emoji characters, no text).
  static final _emojiOnlyPattern = RegExp(
    r'^[\p{Emoji_Presentation}\p{Emoji}\uFE0F\u200D\U0001F1E0-\U0001F1FF]{1,8}$',
    unicode: true,
  );

  static bool isEmojiOnly(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    return _emojiOnlyPattern.hasMatch(trimmed);
  }

  /// Preprocess Discord-style spoilers into inline markers for parsing.
  static String preprocessSpoilers(String raw) {
    return raw.replaceAllMapped(_spoilerPattern, (m) => '§SPOILER§${m[1]}§/SPOILER§');
  }

  @override
  Widget build(BuildContext context) {
    // Emoji-only messages: render at 2x size for visual delight.
    if (isEmojiOnly(content)) {
      return Text(
        content.trim(),
        style: TextStyle(
          fontSize: VFontSize.displayLg,
          color: textColor,
          height: 1.2,
        ),
      );
    }

    final handle = accentMentionHandle?.trim();
    if (handle != null &&
        handle.isNotEmpty &&
        VMessagePlainContent.contentMentionsHandle(content, handle)) {
      return VMessagePlainContent(
        content: content,
        textColor: textColor,
        accentMentionHandle: handle,
      );
    }
    final normalized = preprocessSpoilers(content);
    if (!normalized.contains('§SPOILER§')) {
      return _buildMarkdown(context, normalized);
    }
    return _buildWithSpoilers(context, normalized);
  }

  Widget _buildWithSpoilers(BuildContext context, String text) {
    final parts = <InlineSpan>[];
    var cursor = 0;
    final spoilerMarker = RegExp(r'§SPOILER§([^§]+)§/SPOILER§');

    for (final match in spoilerMarker.allMatches(text)) {
      if (match.start > cursor) {
        parts.addAll(
          _markdownSpans(context, text.substring(cursor, match.start)),
        );
      }
      parts.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _SpoilerChip(
            text: match.group(1) ?? '',
            textColor: textColor,
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      parts.addAll(_markdownSpans(context, text.substring(cursor)));
    }

    return SelectableText.rich(
      TextSpan(children: parts, style: TextStyle(color: textColor)),
    );
  }

  List<InlineSpan> _markdownSpans(BuildContext context, String segment) {
    if (segment.trim().isEmpty) return [];
    return [
      WidgetSpan(
        child: _buildMarkdown(context, segment),
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
      ),
    ];
  }

  Widget _buildMarkdown(BuildContext context, String data) {
    final brightness = Theme.of(context).brightness;
    final withMentions = _injectMentionStyles(data);
    final sheet = VCommuneChatTheme.markdownStyle(
      textColor: textColor,
      brightness: brightness,
    ).copyWith(
      strong: TextStyle(
        fontSize: VFontSize.bodyMd,
        fontWeight: VFontWeight.semiBold,
        color: VCommuneChatTheme.mentionColor,
      ),
      a: TextStyle(
        fontSize: VFontSize.bodyMd,
        color: VCommuneChatTheme.linkColorOf(brightness),
        decoration: TextDecoration.underline,
      ),
    );
    return MarkdownBody(
      data: withMentions,
      // Do not enable [selectable] here — selectable markdown inside chat
      // list cells often paints an empty gray box on Prestige Noir.
      styleSheet: sheet,
      onTapLink: (text, href, title) {
        if (href == null) return;
        launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
      },
    );
  }

  String _injectMentionStyles(String data) {
    return data.replaceAllMapped(_mentionPattern, (m) => '**@${m[1]}**');
  }

  /// Extract the first http(s) URL from message text (for embed cards).
  static String? firstUrl(String content) {
    final match = _urlPattern.firstMatch(content);
    return match?.group(0);
  }

  /// Image URLs from message body (excluding embed targets handled separately).
  static List<String> imageUrlsInContent(String content) {
    return _urlPattern
        .allMatches(content)
        .map((m) => m.group(0)!)
        .where(_looksLikeImageUrl)
        .toList();
  }

  static bool _looksLikeImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.contains('giphy.com') ||
        lower.contains('tenor.com');
  }
}

class _SpoilerChip extends StatefulWidget {
  final String text;
  final Color textColor;

  const _SpoilerChip({required this.text, required this.textColor});

  @override
  State<_SpoilerChip> createState() => _SpoilerChipState();
}

class _SpoilerChipState extends State<_SpoilerChip> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _revealed = !_revealed),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: _revealed
              ? widget.textColor.withValues(alpha: 0.08)
              : VCommuneChatTheme.timestampMuted.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(VRadius.xs),
        ),
        child: Text(
          _revealed ? widget.text : 'spoiler',
          style: TextStyle(
            fontSize: VFontSize.bodyMd,
            color: _revealed ? widget.textColor : Colors.transparent,
            shadows: _revealed
                ? null
                : [
                    Shadow(
                      color: widget.textColor.withValues(alpha: 0.9),
                      blurRadius: 8,
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

/// Plain text with @mention highlighting for DM bubbles.
class VMessagePlainContent extends StatelessWidget {
  final String content;
  final Color textColor;
  final String? accentMentionHandle;

  const VMessagePlainContent({
    super.key,
    required this.content,
    required this.textColor,
    this.accentMentionHandle,
  });

  static bool contentMentionsHandle(String content, String handle) {
    final pattern = RegExp(r'@(\w+)');
    return pattern.allMatches(content).any(
          (m) => m.group(1)!.toLowerCase() == handle.toLowerCase(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final pattern = RegExp(
      r'(@\w+)|(https?://[^\s]+)',
      caseSensitive: false,
    );
    var lastEnd = 0;
    final accent = accentMentionHandle?.toLowerCase();

    for (final match in pattern.allMatches(content)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: content.substring(lastEnd, match.start)));
      }
      final raw = match.group(0)!;
      final isMention = match.group(1) != null;
      final isSelfMention = isMention &&
          accent != null &&
          raw.substring(1).toLowerCase() == accent;
      spans.add(
        TextSpan(
          text: raw,
          style: TextStyle(
            color: isMention
                ? (isSelfMention
                    ? VColors.primary
                    : VCommuneChatTheme.mentionColor)
                : VCommuneChatTheme.linkColor,
            fontWeight: isMention ? VFontWeight.semiBold : VFontWeight.regular,
            backgroundColor: isMention
                ? (isSelfMention
                    ? VColors.primary.withValues(alpha: 0.18)
                    : VCommuneChatTheme.mentionColor.withValues(alpha: 0.12))
                : null,
            decoration: isMention ? null : TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (!isMention) {
                launchUrl(
                  Uri.parse(raw),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      spans.add(TextSpan(text: content.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        children: spans.isEmpty ? [TextSpan(text: content)] : spans,
        style: TextStyle(color: textColor, fontSize: VFontSize.bodyMd),
      ),
    );
  }
}
