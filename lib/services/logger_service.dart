import 'package:logging/logging.dart';

class LoggerService {
  static final Logger _logger = Logger('VisualizationLogger');

  static Logger get logger => _logger;
}
