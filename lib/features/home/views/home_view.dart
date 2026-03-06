import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../database/database_helper.dart';
import '../../../models/project.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/project_card.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<Project> _projects = [];
  List<Project> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    final projects = await DatabaseHelper.instance.getProjects();
    setState(() {
      _projects = projects;
      _filtered = projects;
      _loading = false;
    });
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _projects
          : _projects
                .where(
                  (p) =>
                      p.name.toLowerCase().contains(q) ||
                      p.clientName.toLowerCase().contains(q),
                )
                .toList();
    });
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(projectName: project.name),
    );
    if (confirmed == true && project.id != null) {
      await DatabaseHelper.instance.deleteProject(project.id!);
      _loadProjects();
    }
  }

  Future<void> _changeStatus(Project project, ProjectStatus status) async {
    if (project.id != null) {
      await DatabaseHelper.instance.updateProjectStatus(project.id!, status);
      _loadProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.black;
    final bgColor = isDark ? AppColors.grey900 : AppColors.white;
    final borderColor = isDark ? AppColors.white : AppColors.black;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOP APP BAR ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo/icon.png',
                  height: 150,
                  fit: BoxFit.cover,
                ),
                const Spacer(),
                _NeuIconBtn(
                  icon: Icons.settings_outlined,
                  onTap: () => context.go('/settings'),
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ],
            ),
          ),
          // ── CONTENT ──────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadProjects,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Proyectos',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _NeuSearchBar(
                                  controller: _searchCtrl,
                                  isDark: isDark,
                                  borderColor: borderColor,
                                  bgColor: bgColor,
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                        if (_projects.isEmpty)
                          const SliverFillRemaining(child: EmptyStateWidget())
                        else if (_filtered.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'Sin resultados',
                                style: TextStyle(
                                  color: textColor.withAlpha(160),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final project = _filtered[index];
                                return ProjectCard(
                                  project: project,
                                  onDelete: () => _deleteProject(project),
                                  onStatusChange: (s) =>
                                      _changeStatus(project, s),
                                );
                              }, childCount: _filtered.length),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NeuIconBtn extends StatelessWidget {
  const _NeuIconBtn({
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.borderColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.grey800 : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: AppColors.borderWidth),
          boxShadow: [
            BoxShadow(
              color: borderColor,
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: borderColor),
      ),
    );
  }
}

class _NeuSearchBar extends StatelessWidget {
  const _NeuSearchBar({
    required this.controller,
    required this.isDark,
    required this.borderColor,
    required this.bgColor,
  });

  final TextEditingController controller;
  final bool isDark;
  final Color borderColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: AppColors.borderWidth),
        boxShadow: [
          BoxShadow(
            color: borderColor,
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? AppColors.white : AppColors.black),
        decoration: InputDecoration(
          hintText: 'Buscar proyecto o cliente...',
          hintStyle: TextStyle(
            color: (isDark ? AppColors.white : AppColors.black).withAlpha(120),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: (isDark ? AppColors.white : AppColors.black).withAlpha(160),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.projectName});

  final String projectName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.white
              : AppColors.black,
          width: AppColors.borderWidth,
        ),
      ),
      title: const Text(
        'Eliminar proyecto',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text('Deseas eliminar "$projectName"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}
