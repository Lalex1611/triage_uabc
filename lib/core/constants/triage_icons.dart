/// Set de íconos del rediseño (Figma "TRIAGE/Ícono/*"), 24×24 de un solo color
///
/// Se pintan con `SvgPicture.asset(TriageIcons.x,
/// colorFilter: ColorFilter.mode(color, BlendMode.srcIn))`.
/// Sustituyen a [AppIcons] conforme se migra cada pantalla.
class TriageIcons {
  TriageIcons._();

  static const String _base = 'assets/icons/triage';

  // Navegación y acciones
  static const String arrowLeft = '$_base/arrow_left.svg';
  static const String arrowRight = '$_base/arrow_right.svg';
  static const String arrowDown = '$_base/arrow_down.svg';
  static const String arrowUp = '$_base/arrow_up.svg';
  static const String chevronDown = '$_base/chevron_down.svg';
  static const String chevronRight = '$_base/chevron_right.svg';
  static const String chevronUp = '$_base/chevron_up.svg';
  static const String close = '$_base/close.svg';
  static const String check = '$_base/check.svg';
  static const String checkCircle = '$_base/check_circle.svg';
  static const String plus = '$_base/plus.svg';
  static const String minus = '$_base/minus.svg';
  static const String more = '$_base/more.svg';
  static const String search = '$_base/search.svg';
  static const String filter = '$_base/filter.svg';
  static const String sort = '$_base/sort.svg';
  static const String bell = '$_base/bell.svg';
  static const String user = '$_base/user.svg';
  static const String users = '$_base/users.svg';
  static const String location = '$_base/location.svg';
  static const String map = '$_base/map.svg';
  static const String list = '$_base/list.svg';
  static const String camera = '$_base/camera.svg';
  static const String image = '$_base/image.svg';

  // Clínicos y operación
  static const String ambulance = '$_base/ambulance.svg';
  static const String hospital = '$_base/hospital.svg';
  static const String pulse = '$_base/pulse.svg';
  static const String heart = '$_base/heart.svg';
  static const String breathing = '$_base/breathing.svg';
  static const String walk = '$_base/walk.svg';
  static const String head = '$_base/head.svg';
  static const String drop = '$_base/drop.svg';
  static const String thermometer = '$_base/thermometer.svg';
  static const String medicalCross = '$_base/medical_cross.svg';
  static const String medicalBag = '$_base/medical_bag.svg';
  static const String qr = '$_base/qr.svg';
  static const String scan = '$_base/scan.svg';
  static const String alert = '$_base/alert.svg';
  static const String navigation = '$_base/navigation.svg';
  static const String phone = '$_base/phone.svg';
  static const String clock = '$_base/clock.svg';
  static const String lock = '$_base/lock.svg';
  static const String eye = '$_base/eye.svg';
  static const String pencil = '$_base/pencil.svg';
  static const String info = '$_base/info.svg';
  static const String home = '$_base/home.svg';
  static const String share = '$_base/share.svg';
  static const String offline = '$_base/offline.svg';
  static const String online = '$_base/online.svg';

  // Sistema
  static const String settings = '$_base/settings.svg';
  static const String logout = '$_base/logout.svg';
  static const String stats = '$_base/stats.svg';
  static const String layers = '$_base/layers.svg';
  static const String target = '$_base/target.svg';
  static const String trash = '$_base/trash.svg';
  static const String tag = '$_base/tag.svg';
  static const String calendar = '$_base/calendar.svg';
  static const String document = '$_base/document.svg';
  static const String history = '$_base/history.svg';
  static const String message = '$_base/message.svg';
  static const String send = '$_base/send.svg';
  static const String download = '$_base/download.svg';
  static const String copy = '$_base/copy.svg';
  static const String expand = '$_base/expand.svg';
  static const String shield = '$_base/shield.svg';
  static const String clipboard = '$_base/clipboard.svg';
  static const String reject = '$_base/reject.svg';
  static const String reassign = '$_base/reassign.svg';
  static const String drag = '$_base/drag.svg';
  static const String dot = '$_base/dot.svg';
  static const String pending = '$_base/pending.svg';

  /// Todos los íconos (lo usa el test que verifica que cada asset existe)
  static const List<String> all = [
    arrowLeft,
    arrowRight,
    arrowDown,
    arrowUp,
    chevronDown,
    chevronRight,
    chevronUp,
    close,
    check,
    checkCircle,
    plus,
    minus,
    more,
    search,
    filter,
    sort,
    bell,
    user,
    users,
    location,
    map,
    list,
    camera,
    image,
    ambulance,
    hospital,
    pulse,
    heart,
    breathing,
    walk,
    head,
    drop,
    thermometer,
    medicalCross,
    medicalBag,
    qr,
    scan,
    alert,
    navigation,
    phone,
    clock,
    lock,
    eye,
    pencil,
    info,
    home,
    share,
    offline,
    online,
    settings,
    logout,
    stats,
    layers,
    target,
    trash,
    tag,
    calendar,
    document,
    history,
    message,
    send,
    download,
    copy,
    expand,
    shield,
    clipboard,
    reject,
    reassign,
    drag,
    dot,
    pending,
  ];
}
