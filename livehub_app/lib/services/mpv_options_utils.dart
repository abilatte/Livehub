/// Pure MPV option merge (profile + custom + advanced). No Flutter / media_kit.
class MpvOptionsUtils {
  static const Map<String, String> profileLabels = {
    "performance": "流畅",
    "balanced": "均衡",
    "quality": "画质",
  };

  static const Map<String, Map<String, String>> desktopProfiles = {
    "performance": {
      "profile": "fast",
      "hwdec": "auto-safe",
      "vo": "gpu",
      "scale": "bilinear",
      "cscale": "bilinear",
      "dscale": "bilinear",
      "correct-downscaling": "no",
      "sigmoid-upscaling": "no",
      "deband": "no",
    },
    "balanced": <String, String>{},
    "quality": {
      "profile": "gpu-hq",
      "hwdec": "auto-safe",
      "vo": "gpu-next",
      "scale": "ewa_lanczossharp",
      "cscale": "ewa_lanczossoft",
      "dscale": "mitchell",
      "correct-downscaling": "yes",
      "sigmoid-upscaling": "yes",
      "deband": "yes",
    },
  };

  /// Merge profile defaults, optional custom vo/hwdec/ao, and advanced lines.
  static MpvEffectiveOptions mergeOptions({
    required String profile,
    required bool customPlayerOutput,
    required String videoOutputDriver,
    required String videoHardwareDecoder,
    required String audioOutputDriver,
    required String advancedOptionsRaw,
  }) {
    final profileKey =
        desktopProfiles.containsKey(profile) ? profile : "balanced";
    final profileOptions = Map<String, String>.from(
      desktopProfiles[profileKey] ?? const {},
    );
    final options = <String, String>{...profileOptions};
    final source = <String, String>{
      for (final key in profileOptions.keys) key: "profile:$profileKey",
    };

    if (customPlayerOutput) {
      final vo = videoOutputDriver.trim();
      final hwdec = videoHardwareDecoder.trim();
      final ao = audioOutputDriver.trim();
      if (vo.isNotEmpty) {
        options["vo"] = vo;
        source["vo"] = "custom";
      }
      if (hwdec.isNotEmpty) {
        options["hwdec"] = hwdec;
        source["hwdec"] = "custom";
      }
      if (ao.isNotEmpty) {
        options["ao"] = ao;
        source["ao"] = "custom";
      }
    }

    final advanced = parseOptions(advancedOptionsRaw);
    options.addAll(advanced);
    for (final key in advanced.keys) {
      source[key] = "advanced";
    }

    return MpvEffectiveOptions(options, source);
  }

  static Map<String, String> parseOptions(String raw) {
    final result = <String, String>{};
    for (final rawLine in raw.split(RegExp(r"\r?\n"))) {
      final line = _stripComment(rawLine).trim();
      if (line.isEmpty) {
        continue;
      }
      final entry = _parseLine(line);
      if (entry != null) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  static MapEntry<String, String>? _parseLine(String line) {
    final normalized =
        line.startsWith("--") ? line.substring(2).trimLeft() : line;
    final equalIndex = normalized.indexOf("=");
    if (equalIndex > 0) {
      return MapEntry(
        normalized.substring(0, equalIndex).trim(),
        normalized.substring(equalIndex + 1).trim(),
      );
    }
    final match = RegExp(r"^([^\s]+)\s+(.+)$").firstMatch(normalized);
    if (match == null) {
      return null;
    }
    return MapEntry(match.group(1)!.trim(), match.group(2)!.trim());
  }

  static String _stripComment(String line) {
    final index = line.indexOf("#");
    if (index < 0) {
      return line;
    }
    return line.substring(0, index);
  }
}

class MpvEffectiveOptions {
  final Map<String, String> options;
  final Map<String, String> source;

  const MpvEffectiveOptions(this.options, this.source);
}
