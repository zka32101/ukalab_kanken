import 'package:flutter/material.dart';
import 'package:ukalab_core/ui.dart' show UkalabCertProp, UkalabProps;

/// 漢検の資格小物。筆立てに立てた筆（[UkalabCertProp.brushes]）を使う。
/// 装飾のみ（読み上げ・タップ対象外）。画像の読み込みに失敗したら何も出さない。
class CertPropBadge extends StatelessWidget {
  const CertPropBadge({
    super.key,
    this.size = 36,
    this.prop = UkalabCertProp.brushes,
  });

  final double size;
  final UkalabCertProp prop;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Image(
          image: UkalabProps.certImage(prop),
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
