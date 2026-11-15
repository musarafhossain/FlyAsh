import 'dart:math' as math;
import 'dart:ui';

/// A colour from OKLCH: [l] lightness 0–1, [c] chroma (about 0–0.3) and
/// [h] hue in degrees. In OKLCH, colours with the same lightness look
/// equally light to the eye (unlike HSL), so a set of hues made with one
/// L and C reads as one family. Out-of-range sRGB values are clamped.
Color oklch(double l, double c, double h) {
  final hr = h * math.pi / 180;
  final a = c * math.cos(hr);
  final b = c * math.sin(hr);

  // OKLab → linear sRGB (Björn Ottosson's matrices).
  final l_ = l + 0.3963377774 * a + 0.2158037573 * b;
  final m_ = l - 0.1055613458 * a - 0.0638541728 * b;
  final s_ = l - 0.0894841775 * a - 1.2914855480 * b;
  final l3 = l_ * l_ * l_;
  final m3 = m_ * m_ * m_;
  final s3 = s_ * s_ * s_;
  final r = 4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3;
  final g = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3;
  final bl = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3;

  int channel(double linear) {
    final v = linear <= 0.0031308
        ? 12.92 * linear
        : 1.055 * math.pow(linear, 1 / 2.4) - 0.055;
    return (v.clamp(0.0, 1.0) * 255).round();
  }

  return Color.fromARGB(255, channel(r), channel(g), channel(bl));
}
