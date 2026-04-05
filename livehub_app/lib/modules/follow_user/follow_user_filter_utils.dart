enum FollowUserFilter {
  all,
  live,
  notLive,
}

class FollowUserFilterOption {
  final FollowUserFilter type;
  final String label;

  const FollowUserFilterOption({
    required this.type,
    required this.label,
  });
}

const kDefaultFollowFilters = <FollowUserFilterOption>[
  FollowUserFilterOption(type: FollowUserFilter.all, label: "全部"),
  FollowUserFilterOption(type: FollowUserFilter.live, label: "直播中"),
  FollowUserFilterOption(type: FollowUserFilter.notLive, label: "未开播"),
];
