/// Ключ MapKit приходит при сборке из файла `mapkit_api_key.json`:
/// `flutter run --dart-define-from-file=mapkit_api_key.json`.
/// Сам файл в репозиторий не входит.
const mapkitApiKey = String.fromEnvironment('MAPKIT_API_KEY');
