void main() {
  int entityId = 123;
  Object obj = {'tripId': entityId};
  print(obj.runtimeType);
  try {
    final map = obj as Map<String, dynamic>;
    print("Cast Success: ${map.runtimeType}");
  } catch (e) {
    print("Cast Error: $e");
  }
}
