import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/connectivity/app_connectivity_notifier.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/app_snackbar.dart';

/*
Variantes visuales de la cabecera según el contexto de navegación
*/
enum HeaderType { home, search, incident, paramedicoFlow }

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  /*
  Color de fondo inyectado por cada pantalla para reflejar el contexto visual
  */
  final Color color;

  /*
  Tipo de cabecera a renderizar que determina la disposición de los elementos
  */
  final HeaderType type;

  /*
  Reservado por compatibilidad; el ícono Wi‑Fi usa [AppConnectivityNotifier] en vivo.
  */
  final bool isConnected;

  /*
  Indicador de notificaciones pendientes para actualización visual del icono
  */
  final bool hasNotifications;

  /*
  Etiqueta de texto para la navegación de retorno en la variante de incidente
  */
  final String? backLabel;

  /*
  Texto del botón de acción principal en la variante de incidente
  */
  final String? actionLabel;

  /*
  Ejecución al presionar el botón de retroceso
  */
  final VoidCallback? onBack;

  /*
  Ejecución al presionar el botón de acción principal
  */
  final VoidCallback? onAction;

  /*
  Ejecución al presionar el ícono de perfil (variante inicio / búsqueda).
  */
  final VoidCallback? onProfileTap;

  /*
  Ejecución al presionar el ícono de notificaciones.
  */
  final VoidCallback? onNotificationTap;

  /*
  Título junto al botón atrás en [HeaderType.paramedicoFlow] (p. ej. «Nuevo incidente»).
  */
  final String? toolbarTitle;

  /*
  Texto secundario bajo el título principal en la variante de inicio
  */
  final String? subtitle;

  /*
  Ruta opcional al logo del header (PNG o SVG). Si no se provee, usa el logo SVG del paramédico.
  */
  final String? logoPath;

  /*
  Ruta opcional al ícono de wifi del header (PNG). Si no se provee, usa los SVGs del paramédico.
  */
  final String? wifiIconPath;

  /*
  Ruta opcional al ícono de notificación del header (PNG). Si no se provee, usa el SVG del paramédico.
  */
  final String? notificationIconPath;

  /*
  Ruta opcional al ícono de perfil del header (PNG). Si no se provee, usa el SVG del paramédico.
  Si se pasa null explícitamente con hideProfile=true, se oculta el ícono de perfil.
  */
  final String? profileIconPath;

  /*
  Control de busqueda para [HeaderType.search]. Cada pantalla conecta su
  propio filtro sin duplicar la variante visual del header.
  */
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;

  const AppHeader({
    super.key,
    required this.type,
    required this.color,
    required this.isConnected,
    required this.hasNotifications,
    this.backLabel,
    this.actionLabel,
    this.onBack,
    this.onAction,
    this.onProfileTap,
    this.onNotificationTap,
    this.toolbarTitle,
    this.subtitle,
    this.logoPath,
    this.wifiIconPath,
    this.notificationIconPath,
    this.profileIconPath,
    this.searchController,
    this.onSearchChanged,
    this.searchHint = 'Buscar incidentes',
  });

  @override
  /*
  Altura calculada desde la fuente única de dimensiones globales
  */
  Size get preferredSize => const Size.fromHeight(AppDimensions.headerHeight);

  /*
  Renderiza un ícono desde una ruta. Detecta si es SVG o PNG
  y usa el widget correspondiente.
  */
  Widget _buildIcon(
    String path, {
    double? width,
    double? height,
    ColorFilter? colorFilter,
  }) {
    if (path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.contain,
        colorFilter: colorFilter,
      );
    } else {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.contain,
      );
    }
  }

  /*
  Construcción del logo UABC
  */
  Widget _buildLogo() {
    String path = AppIcons.paramedicoHeaderLogo;
    if (logoPath != null) {
      path = logoPath!;
    }

    return _buildIcon(
      path,
      width: AppDimensions.headerLogoSize,
      height: AppDimensions.headerLogoSize,
    );
  }

  /*
  Renderizado de iconos de estado con orden y espaciado predefinido
  */
  Widget _buildWifiIcon(BuildContext context) {
    if (wifiIconPath != null) {
      return _buildIcon(
        wifiIconPath!,
        height: AppDimensions.headerStatusIconSize,
        width: AppDimensions.headerStatusIconSize,
      );
    }

    return ListenableBuilder(
      listenable: AppConnectivityNotifier.instance,
      builder: (context, _) {
        final notifier = AppConnectivityNotifier.instance;
        final connected = notifier.isConnected;
        final path = connected
            ? AppIcons.paramedicoHeaderWifiConnected
            : AppIcons.paramedicoHeaderWifiNotConnected;
        final icon = SvgPicture.asset(
          path,
          height: AppDimensions.headerStatusIconSize,
          width: AppDimensions.headerStatusIconSize,
        );

        return GestureDetector(
          onTap: () async {
            await notifier.refresh();
            if (!context.mounted) return;
            showAppSnackBar(
              context,
              notifier.statusMessage,
              isError: !notifier.isConnected,
            );
          },
          behavior: HitTestBehavior.opaque,
          child: icon,
        );
      },
    );
  }

  Widget _buildStatusIcons(BuildContext context) {
    final wifiIcon = _buildWifiIcon(context);

    /*
    Ícono de notificación
    */
    Widget notifIcon;
    if (notificationIconPath != null) {
      notifIcon = _buildIcon(
        notificationIconPath!,
        height: AppDimensions.headerStatusIconSize,
        width: AppDimensions.headerStatusIconSize,
      );
    } else {
      notifIcon = SvgPicture.asset(
        AppIcons.paramedicoHeaderNotification,
        height: AppDimensions.headerStatusIconSize,
        width: AppDimensions.headerStatusIconSize,
      );
    }

    Widget notifWithBadge = SizedBox(
      width: AppDimensions.headerStatusIconSize,
      height: AppDimensions.headerStatusIconSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          notifIcon,
          if (hasNotifications)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB020),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );

    final notifWidget = onNotificationTap != null
        ? GestureDetector(
            onTap: onNotificationTap,
            behavior: HitTestBehavior.opaque,
            child: notifWithBadge,
          )
        : notifWithBadge;

    /*
    Ícono de perfil (solo se muestra si hay ruta)
    */
    Widget profileIcon;
    if (profileIconPath != null) {
      profileIcon = _buildIcon(
        profileIconPath!,
        height: AppDimensions.headerStatusIconSize,
        width: AppDimensions.headerStatusIconSize,
      );
    } else {
      profileIcon = SvgPicture.asset(
        AppIcons.paramedicoHeaderProfile,
        height: AppDimensions.headerStatusIconSize,
        width: AppDimensions.headerStatusIconSize,
      );
    }

    final profileWidget = onProfileTap != null
        ? GestureDetector(
            onTap: onProfileTap,
            behavior: HitTestBehavior.opaque,
            child: profileIcon,
          )
        : profileIcon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        wifiIcon,
        const SizedBox(width: AppDimensions.headerStatusIconGap),
        notifWidget,
        const SizedBox(width: AppDimensions.headerStatusIconGap),
        profileWidget,
      ],
    );
  }

  Widget _arrowBackIcon() {
    return SvgPicture.asset(
      AppIcons.paramedicoHeaderArrowBack,
      height: AppDimensions.headerStatusIconSize,
      width: AppDimensions.headerStatusIconSize,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    );
  }

  /*
  Flecha atrás (solo icono). En búsqueda no se enlaza el campo de texto.
  */
  Widget _buildArrowBack() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onBack,
      child: Padding(padding: const EdgeInsets.all(6), child: _arrowBackIcon()),
    );
  }

  /*
  Flecha + título en una sola zona táctil (incidente, flujos paramédico).
  Evita que solo el icono pequeño reciba el toque mientras «Regresar» no hace nada.
  */
  Widget _buildTappableBackWithTitle(Widget title) {
    final row = Row(
      children: [
        _arrowBackIcon(),
        const SizedBox(width: AppDimensions.headerNavGap),
        Expanded(child: title),
      ],
    );
    if (onBack == null) {
      return row;
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onBack,
        child: row,
      ),
    );
  }

  /*
  Contenedor base que aplica color de fondo, SafeArea y padding estándar
  */
  Widget _wrap(Widget child) {
    return ColoredBox(
      color: color,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: AppDimensions.headerHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.headerPaddingH,
              0,
              AppDimensions.headerPaddingH,
              AppDimensions.headerBottomClearance,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /*
  Configuración para la pantalla de inicio con logo y títulos
  */
  Widget _buildHome(BuildContext context) {
    return _wrap(
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildLogo(),
          const SizedBox(width: AppDimensions.headerLogoTextGap),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistema de emergencias',
                  style: AppTextStyles.ESC_Bold_titleLarge.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle ?? '',
                  style: AppTextStyles.ESC_Bold_titleSmall.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _buildStatusIcons(context),
        ],
      ),
    );
  }

  /*
  Configuración con barra de búsqueda integrada y navegación de retroceso
  */
  Widget _buildSearch(BuildContext context) {
    final hintStyle = AppTextStyles.ESC_Regular_bodyMedium.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w100,
      color: AppColors.searchHint,
    );
    return _wrap(
      Row(
        children: [
          _buildArrowBack(),
          const SizedBox(width: AppDimensions.headerNavGap),
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD9D9D9), width: 1.31),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  SvgPicture.asset(
                    AppIcons.paramedicoHeaderSearch,
                    height: 18,
                    width: 18,
                    colorFilter: ColorFilter.mode(
                      AppColors.searchHint,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      style: hintStyle,
                      decoration: InputDecoration(
                        hintText: searchHint,
                        hintStyle: hintStyle,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.headerNavGap),
          _buildStatusIcons(context),
        ],
      ),
    );
  }

  /*
  Atrás + título + iconos (sin búsqueda): flujos como crear incidente.
  */
  Widget _buildParamedicoFlow(BuildContext context) {
    return _wrap(
      Row(
        children: [
          Expanded(
            child: _buildTappableBackWithTitle(
              Text(
                toolbarTitle ?? '',
                style: AppTextStyles.ESC_Medium_titleMedium.copyWith(
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _buildStatusIcons(context),
        ],
      ),
    );
  }

  /*
  Configuración para gestión de incidentes con etiquetas de retorno y botón de acción
  */
  Widget _buildIncident(BuildContext context) {
    return _wrap(
      Row(
        children: [
          Expanded(
            child: _buildTappableBackWithTitle(
              Text(
                backLabel ?? '',
                style: AppTextStyles.ESC_Medium_titleMedium.copyWith(
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.headerActionGap),
          if (actionLabel != null)
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white, width: 0.8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.5),
                ),
              ),
              child: Text(
                actionLabel!,
                style: AppTextStyles.ESC_Regular_bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      HeaderType.home => _buildHome(context),
      HeaderType.search => _buildSearch(context),
      HeaderType.incident => _buildIncident(context),
      HeaderType.paramedicoFlow => _buildParamedicoFlow(context),
    };
  }
}
