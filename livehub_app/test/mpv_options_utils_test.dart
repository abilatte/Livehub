import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/services/mpv_options_utils.dart';

void main() {
  group('MpvOptionsUtils.mergeOptions', () {
    test('performance profile supplies scale/hwdec defaults', () {
      final merged = MpvOptionsUtils.mergeOptions(
        profile: 'performance',
        customPlayerOutput: false,
        videoOutputDriver: '',
        videoHardwareDecoder: '',
        audioOutputDriver: '',
        advancedOptionsRaw: '',
      );
      expect(merged.options['scale'], 'bilinear');
      expect(merged.options['hwdec'], 'auto-safe');
      expect(merged.options['cache'], 'yes');
      expect(merged.source['scale'], 'profile:performance');
    });

    test('balanced profile still forces safe hardware decode on desktop', () {
      final merged = MpvOptionsUtils.mergeOptions(
        profile: 'balanced',
        customPlayerOutput: false,
        videoOutputDriver: '',
        videoHardwareDecoder: '',
        audioOutputDriver: '',
        advancedOptionsRaw: '',
        hardwareDecode: true,
      );
      expect(merged.options['hwdec'], 'auto-safe');
      // vo must not be forced — otherwise media_kit opens a separate window
      expect(merged.options.containsKey('vo'), isFalse);
    });

    test('custom and advanced override profile', () {
      final merged = MpvOptionsUtils.mergeOptions(
        profile: 'quality',
        customPlayerOutput: true,
        videoOutputDriver: 'gpu',
        videoHardwareDecoder: 'no',
        audioOutputDriver: 'wasapi',
        advancedOptionsRaw: 'deband=no\n# comment\nscale=bilinear',
      );
      expect(merged.options['vo'], 'gpu');
      expect(merged.source['vo'], 'custom');
      expect(merged.options['hwdec'], 'no');
      expect(merged.options['deband'], 'no');
      expect(merged.source['deband'], 'advanced');
      expect(merged.options['scale'], 'bilinear');
      expect(merged.source['scale'], 'advanced');
    });

    test('hardwareDecode false forces hwdec=no', () {
      final merged = MpvOptionsUtils.mergeOptions(
        profile: 'performance',
        customPlayerOutput: false,
        videoOutputDriver: '',
        videoHardwareDecoder: '',
        audioOutputDriver: '',
        advancedOptionsRaw: '',
        hardwareDecode: false,
      );
      expect(merged.options['hwdec'], 'no');
    });

    test('parseOptions supports --key=value form', () {
      final parsed = MpvOptionsUtils.parseOptions('--hwdec=auto-safe');
      expect(parsed['hwdec'], 'auto-safe');
    });
  });
}
