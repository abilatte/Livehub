int resolveSearchSiteIndex({
  required List<String> supportSiteIds,
  String? initialSiteId,
}) {
  if (initialSiteId == null || initialSiteId.isEmpty) {
    return 0;
  }
  final index = supportSiteIds.indexOf(initialSiteId);
  return index >= 0 ? index : 0;
}
