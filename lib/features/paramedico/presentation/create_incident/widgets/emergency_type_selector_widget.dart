import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sistema_triage/core/theme/app_theme.dart';
import 'package:sistema_triage/core/constants/app_icons.dart';
import 'package:sistema_triage/features/paramedico/domain/entities/create_incident/emergency_type.dart';

// Selector en forma de rejilla (chips) para definir la categoría de la emergencia
class EmergencyTypeSelector extends StatefulWidget {
  final List<EmergencyType> availableTypes;
  final void Function(String? selectedTypeId, String customOtroText)? onSelectionChanged;
  final String? initialSelectedTypeId;

  const EmergencyTypeSelector({
    super.key,
    required this.availableTypes,
    this.onSelectionChanged,
    this.initialSelectedTypeId,
  });

  @override
  State<EmergencyTypeSelector> createState() => _EmergencyTypeSelectorState();
}

class _EmergencyTypeSelectorState extends State<EmergencyTypeSelector> {
  // Identificador único del tipo de emergencia seleccionado para evitar dependencias de strings literales
  String? selectedTypeId;

  // Texto personalizado para la categoría 'Otro', permite especificación manual
  String customOtroText = 'Otro';

  @override
  void initState() {
    super.initState();
    selectedTypeId = widget.initialSelectedTypeId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  void _notify() {
    widget.onSelectionChanged?.call(selectedTypeId, customOtroText);
  }

  bool get _isAnyTypeSelected {
    return selectedTypeId != null;
  }

  // Despliegue de diálogo interactivo para la captura de un tipo de emergencia no listado
  Future<void> _handleEditOtro() async {
    String initialText = '';
    if (customOtroText != 'Otro') {
      initialText = customOtroText;
    }

    final controller = TextEditingController(text: initialText);

    final newText = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Editar tipo de emergencia',
            style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
              fontSize: 16,
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Especificar...'),
          ),
          actions: [
            // Acción de cancelación para mantener el estado previo de la opción
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            // Confirmación y persistencia del texto personalizado ingresado
            TextButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text(
                'Guardar',
                style: TextStyle(color: Color(0xFFCE1125)),
              ),
            ),
          ],
        );
      },
    );

    if (newText != null && newText.trim().isNotEmpty) {
      setState(() {
        customOtroText = newText.trim();
        // Forzado de selección tras la edición exitosa del texto personalizado
        selectedTypeId = 'OTRO';
      });
      _notify();
    }
  }

  // Alternancia de la selección basada en el ID; permite deseleccionar si el ID coincide con el actual
  void _handleTypeSelection(String typeId) {
    setState(() {
      if (selectedTypeId == typeId) {
        selectedTypeId = null;
      } else {
        selectedTypeId = typeId;
      }
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [_buildTitle(), const SizedBox(height: 4), _buildTypeGrid()],
      ),
    );
  }

  // Título dinámico que cambia de color y simbología según el estado de selección
  Widget _buildTitle() {
    String indicatorText = ' *:';
    Color indicatorColor = const Color(0xFFCE1125);

    if (_isAnyTypeSelected) {
      indicatorText = ':';
      indicatorColor = Colors.black;
    }

    return RichText(
      text: TextSpan(
        text: 'Tipo de emergencia',
        style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
          fontSize: 20.0,
          color: Colors.black,
        ),
        children: [
          TextSpan(
            text: indicatorText,
            style: AppTextStyles.ESC_SemiBold_displayLarge.copyWith(
              fontSize: 20.0,
              color: indicatorColor,
            ),
          ),
        ],
      ),
    );
  }

  // Generación dinámica de la rejilla de tipos, incluyendo la opción 'Otro' por defecto
  Widget _buildTypeGrid() {
    final List<EmergencyType> displayTypes = List.from(widget.availableTypes)
      ..add(const EmergencyType(id: 'OTRO', name: 'Otro'));

    return Wrap(
      spacing: 11.4,
      runSpacing: 10.0,
      children: displayTypes.map(_buildTypeChip).toList(),
    );
  }

  // Componente visual para cada opción de tipo, maneja estados de selección e interacción para edición
  Widget _buildTypeChip(EmergencyType type) {
    bool isOtroOption = type.id == 'OTRO';
    bool isSelected = selectedTypeId == type.id;

    String displayText = type.name;
    if (isOtroOption) {
      displayText = customOtroText;
    }

    Color chipColor = const Color(0xFF999A9D);
    Color borderColor = const Color(0xFFD9D9D9);

    if (isSelected) {
      chipColor = const Color(0xFFCE1125);
      borderColor = const Color(0xFFCE1125);
    }

    final chipHeight = isOtroOption ? 36.0 : 30.0;
    final chipWidth = isOtroOption ? 102.0 : 85.0;
    const double otroEditHitWidth = 44;

    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor, width: 1),
    );

    final textStyle = AppTextStyles.ESC_Regular_bodyMedium.copyWith(
      fontSize: 10.0,
      color: chipColor,
    );

    Widget chipText() {
      return Text(
        displayText,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    if (isOtroOption) {
      return Container(
        width: chipWidth,
        height: chipHeight,
        padding: const EdgeInsets.only(left: 6),
        decoration: decoration,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _handleTypeSelection(type.id),
                child: Center(child: chipText()),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleEditOtro,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(19),
                ),
                child: SizedBox(
                  width: otroEditHitWidth,
                  height: chipHeight,
                  child: Center(
                    child: SvgPicture.asset(
                      AppIcons.paramedicoIncidenteEdit,
                      width: 14,
                      height: 14,
                      colorFilter: ColorFilter.mode(chipColor, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        _handleTypeSelection(type.id);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: chipWidth,
        height: chipHeight,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: decoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: chipText(),
            ),
          ],
        ),
      ),
    );
  }
}
