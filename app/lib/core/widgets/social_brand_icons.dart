import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// โลโก้ทางการของ LINE (กรอบคำพูดสีขาวบนพื้นเขียว #06C755)
class LineLogoIcon extends StatelessWidget {
  const LineLogoIcon({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.string(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
            '<path fill="#ffffff" d="M12 2.5C6.2 2.5 1.5 6.4 1.5 11.2'
            'c0 4.3 3.7 7.9 8.7 8.6.34.07.8.22.92.51.11.26.07.67.03.93'
            'l-.15.9c-.05.27-.21 1.05.92.57 1.13-.48 6.1-3.6 8.32-6.16'
            'C21.82 14.9 22.5 13.15 22.5 11.2 22.5 6.4 17.8 2.5 12 2.5z"/>'
            '</svg>',
            width: size,
            height: size,
          ),
          Padding(
            padding: EdgeInsets.only(bottom: size * 0.1),
            child: Text(
              'LINE',
              style: TextStyle(
                fontSize: size * 0.27,
                fontWeight: FontWeight.w900,
                color: AppColors.brandLine,
                height: 1,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// โลโก้ตัว f ของ Facebook (เส้นเวกเตอร์ทางการ ไม่ใช้ตัวอักษรฟอนต์ระบบ)
class FacebookLogoIcon extends StatelessWidget {
  const FacebookLogoIcon({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path fill="#ffffff" d="M15.12 5.32H17V2.14A26.11 26.11 0 0 0 14.26 2'
      'c-2.72 0-4.58 1.66-4.58 4.7v2.62H6.61v3.56h3.07V22h3.68v-9.12'
      'h3.06l.46-3.56h-3.52V7.05c0-1.05.28-1.73 1.76-1.73z"/>'
      '</svg>',
      width: size,
      height: size,
    );
  }
}

/// โลโก้กล้องของ Instagram สำหรับปุ่มแชร์วงกลมพื้นไล่สี IG
class InstagramLogoIcon extends StatelessWidget {
  const InstagramLogoIcon({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="none" stroke="#ffffff" stroke-width="2" '
      'stroke-linecap="round" stroke-linejoin="round">'
      '<rect width="20" height="20" x="2" y="2" rx="5" ry="5"/>'
      '<path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/>'
      '<line x1="17.5" x2="17.51" y1="6.5" y2="6.5"/></svg>',
      width: size,
      height: size,
    );
  }
}

/// โลโก้โน้ตดนตรี 3 มิติของ TikTok (ฟ้า/แดง/ขาว)
class TikTokLogoIcon extends StatelessWidget {
  const TikTokLogoIcon({super.key, this.size = 26});

  final double size;

  static const _d =
      'M16.5 3c.4 2.3 1.9 3.8 4.2 4v3.1c-1.5 0-2.9-.4-4.2-1.2v6.3c0 3.4-2.6 5.8-5.8 5.8S5 18.6 5 15.4s2.7-5.9 6.2-5.6v3.2c-1.5-.3-3 .9-3 2.4 0 1.4 1.1 2.5 2.6 2.5s2.6-1.1 2.6-2.6V3Z';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path d="$_d" fill="#25F4EE" transform="translate(-1 -1)"/>'
      '<path d="$_d" fill="#FE2C55" transform="translate(1 1)"/>'
      '<path d="$_d" fill="#ffffff"/></svg>',
      width: size,
      height: size,
    );
  }
}

/// โลโก้ G 4 สีทางการของ Google
class GoogleLogoIcon extends StatelessWidget {
  const GoogleLogoIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path fill="#4285F4" d="M23.49 12.27c0-.79-.07-1.54-.2-2.27H12v4.3h6.45c-.28 1.49-1.12 2.75-2.38 3.6v2.99h3.85c2.25-2.07 3.57-5.12 3.57-8.62z"/>'
      '<path fill="#34A853" d="M12 24c3.24 0 5.95-1.07 7.93-2.91l-3.85-2.99c-1.07.72-2.44 1.15-4.08 1.15-3.14 0-5.8-2.12-6.75-4.97H1.28v3.08C3.25 21.28 7.31 24 12 24z"/>'
      '<path fill="#FBBC05" d="M5.25 14.28c-.24-.72-.38-1.49-.38-2.28s.14-1.56.38-2.28V6.64H1.28C.47 8.25 0 10.07 0 12s.47 3.75 1.28 5.36l3.97-3.08z"/>'
      '<path fill="#EA4335" d="M12 4.75c1.76 0 3.34.61 4.58 1.8l3.43-3.43C17.95 1.19 15.24 0 12 0 7.31 0 3.25 2.72 1.28 6.64l3.97 3.08c.95-2.85 3.61-4.97 6.75-4.97z"/>'
      '</svg>',
      width: size,
      height: size,
    );
  }
}
