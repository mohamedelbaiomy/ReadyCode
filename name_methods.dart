class NameMethods {
  static String getShortName(String fullName) {
    final List<String> words = fullName.split(' ');
    if (words.length <= 2) {
      return fullName;
    }
    return '${words[0]} ${words[1]}';
  }

  static String getShortNameCharacters(String fullName) {
    final List<String> words = fullName.split(' ');
    if (words.length < 2) {
      return fullName[0];
    }
    return '${words[0][0]}${words[1][0]}';
  }
}
