class FormatModel {
  List<String> formats = ['WAV', 'MP3', 'AAC', 'FLAC', 'WMA', 'OGG', 'AC3', 'M4A'];
  String selectedFormat = 'AAC';

  void setSelectedFormat(String format) {
    selectedFormat = format;
  }
}
