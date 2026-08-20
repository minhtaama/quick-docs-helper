import 'package:flutter/material.dart';
import 'app_container.dart';

class QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? color;
  final VoidCallback onTap;
  final Widget? bottomWidget;
  final double? height;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.color,
    required this.onTap,
    this.bottomWidget,
    this.height,
  });

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = widget.color ?? theme.colorScheme.primary;

    final headerContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AppContainer(
            width: 46,
            height: 46,
            color: cardColor.withValues(alpha: 0.12),
            borderRadius: 10,
            alignment: Alignment.center,
            child: Icon(widget.icon, color: cardColor, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.badge != null) ...[
                      const SizedBox(width: 6),
                      AppContainer.badge(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        color: cardColor.withValues(alpha: 0.15),
                        borderRadius: 10,
                        child: Text(
                          widget.badge!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: cardColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: _isHovered
                ? cardColor
                : theme.iconTheme.color?.withValues(alpha: 0.3),
          ),
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: widget.height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isHovered
                ? cardColor.withValues(alpha: 0.5)
                : theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? cardColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: widget.bottomWidget == null
              ? InkWell(
                  borderRadius: BorderRadius.circular(8),
                  hoverColor: cardColor.withValues(alpha: 0.05),
                  focusColor: cardColor.withValues(alpha: 0.05),
                  highlightColor: cardColor.withValues(alpha: 0.05),
                  splashColor: cardColor.withValues(alpha: 0.1),
                  onTap: widget.onTap,
                  child: widget.height != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            headerContent,
                            Expanded(
                              child: Center(
                                child: Icon(
                                  widget.icon,
                                  size: 48,
                                  color: cardColor.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                          ],
                        )
                      : headerContent,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      hoverColor: cardColor.withValues(alpha: 0.05),
                      focusColor: cardColor.withValues(alpha: 0.05),
                      highlightColor: cardColor.withValues(alpha: 0.05),
                      splashColor: cardColor.withValues(alpha: 0.1),
                      onTap: widget.onTap,
                      child: headerContent,
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: theme.dividerColor.withValues(alpha: 0.12),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        child: widget.bottomWidget!,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
