/// The package's SVG icons, as asset paths inside this package. Load them
/// with `package: CommunityIcons.package`.
///
/// Every icon the package draws is listed in [all], and
/// test/core/community_icons_test.dart loads each one from the asset
/// bundle, so a missing or broken file fails the tests instead of the app.
abstract final class CommunityIcons {
  static const package = 'community_package';

  static const add = 'assets/icons/add.svg';
  static const arrowLeft = 'assets/icons/arrow_left.svg';
  static const arrowRight = 'assets/icons/arrow_right.svg';
  static const filter = 'assets/icons/filter.svg';
  static const search = 'assets/icons/search.svg';
  static const sort = 'assets/icons/sort.svg';

  static const all = [add, arrowLeft, arrowRight, filter, search, sort];
}
