import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/util/colors.dart';

class PostText extends StatelessWidget {
  const PostText({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vAppLayoutBackground,
        borderRadius: radius(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 6, // how soft the shadow is
            offset: const Offset(0, 4), // x, y offset of the shadow
          ),
        ],
      ),
      child: TextField(
        autofocus: false,
        maxLines: 15,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Whats On Your Mind?',
          hintStyle: secondaryTextStyle(size: 12, color: vBodyWhite),
        ),
      ),
    );
  }
}
