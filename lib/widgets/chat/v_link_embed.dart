import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import 'v_message_content.dart';

/// Lightweight URL unfurl card below a message.
class VLinkEmbed extends StatelessWidget {
  final String url;

  const VLinkEmbed({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return const SizedBox.shrink();

    final host = uri.host.isNotEmpty ? uri.host : url;
    final path = uri.path.isNotEmpty && uri.path != '/'
        ? uri.path
        : '';

    return Padding(
      padding: const EdgeInsets.only(top: VSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
          borderRadius: BorderRadius.circular(VRadius.md),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(VSpacing.sm),
            decoration: BoxDecoration(
              color: VCommuneColors.surfaceTertiary,
              borderRadius: BorderRadius.circular(VRadius.md),
              border: Border.all(color: VCommuneColors.dividerSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  host,
                  style: const TextStyle(
                    fontSize: VFontSize.labelSm,
                    fontWeight: VFontWeight.semiBold,
                    color: VCommuneColors.textLink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (path.isNotEmpty)
                  Text(
                    path,
                    style: const TextStyle(
                      fontSize: VFontSize.labelSm,
                      color: VCommuneColors.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show embed when [content] has a non-image URL.
  static Widget? forMessageContent(String content) {
    final url = VMessageContent.firstUrl(content);
    if (url == null) return null;
    if (VMessageContent.imageUrlsInContent(content).contains(url)) {
      return null;
    }
    return VLinkEmbed(url: url);
  }
}
