import 'package:flutter/material.dart';
import 'package:sistema_triage/features/medico/domain/entities/profile/medico_profile_menu_item_data.dart';
import 'package:sistema_triage/features/medico/domain/entities/profile/medico_profile_section_data.dart';
import 'package:sistema_triage/features/medico/presentation/profile/widgets/medico_profile_header_widget.dart';
import 'package:sistema_triage/features/medico/presentation/profile/widgets/medico_profile_identity_card_widget.dart';
import 'package:sistema_triage/features/medico/presentation/profile/widgets/medico_profile_menu_widget.dart';
import 'package:sistema_triage/features/medico/presentation/profile/widgets/medico_profile_section_widget.dart';
import 'package:sistema_triage/features/medico/presentation/profile/widgets/medico_profile_sign_out_button_widget.dart';

/// Cascarón del perfil del médico (mockup 13); sin lógica de negocio
class MedicoProfilePage extends StatelessWidget {
  const MedicoProfilePage({
    super.key,
    required this.userName,
    required this.hospitalLabel,
    required this.sections,
    required this.menuItems,
    required this.loading,
    required this.onRefresh,
    required this.onBackTap,
    required this.onSignOutTap,
    this.errorMessage,
  });

  final String userName;
  final String hospitalLabel;
  final List<MedicoProfileSectionData> sections;
  final List<MedicoProfileMenuItemData> menuItems;
  final bool loading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback onBackTap;
  final VoidCallback onSignOutTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFEEF2F6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: MedicoProfileHeader(onBackTap: onBackTap),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  MedicoProfileIdentityCard(
                    name: userName,
                    hospitalLabel: hospitalLabel,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFC62828),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  if (loading && sections.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  for (final s in sections) ...[
                    const SizedBox(height: 16),
                    MedicoProfileSection(data: s),
                  ],
                  const SizedBox(height: 16),
                  MedicoProfileMenu(items: menuItems),
                  const SizedBox(height: 24),
                  MedicoProfileSignOutButton(onTap: onSignOutTap),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
