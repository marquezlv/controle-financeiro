import 'package:flutter/material.dart';
import '../core/project_context.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
import '../widgets/project/create_project_modal.dart';

class SuspenseMenuButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SuspenseMenuButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 8),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.9 * 255).round()),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.12 * 255).round()),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded),
              color: const Color(0xFF1E4ED8),
              splashRadius: 22,
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}

class SuspenseMenuDrawer extends StatefulWidget {
  final ValueChanged<ProjectModel> onProjectSelected;

  const SuspenseMenuDrawer({
    super.key,
    required this.onProjectSelected,
  });

  @override
  State<SuspenseMenuDrawer> createState() => _SuspenseMenuDrawerState();
}

class _SuspenseMenuDrawerState extends State<SuspenseMenuDrawer> {
  late Future<List<ProjectModel>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _loadProjects() {
    _projectsFuture = ProjectService.getAll();
  }

  void _showCreateProjectModal() async {
    Navigator.of(context).pop();
    await CreateProjectModal.show(
      context,
      onCreated: () {
        if (mounted) {
          setState(() => _loadProjects());
        }
      },
    );
  }

  void _showEditProjectModal(ProjectModel project) async {
    Navigator.of(context).pop();
    await CreateProjectModal.show(
      context,
      project: project,
      onCreated: () {
        if (mounted) {
          setState(() => _loadProjects());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2F6BFF), Color(0xFF1E4ED8)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Minhas Planilhas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Selecione uma planilha para trabalhar',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ProjectModel>>(
                future: _projectsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erro ao carregar planilhas: ${snapshot.error}'),
                    );
                  }

                  final projects = snapshot.data ?? [];
                  final activeProjectId = ProjectContext.getActiveProjectId();

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: projects.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      final isSelected = project.id == activeProjectId;

                      return ListTile(
                        leading: Icon(
                          Icons.folder_rounded,
                          color: isSelected ? const Color(0xFF2F6BFF) : null,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project.name,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF2F6BFF)
                                          : null,
                                    ),
                                  ),
                                  Text(
                                    project.currencyCode,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, size: 18),
                                  onPressed: () => _showEditProjectModal(project),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded, size: 18),
                                  onPressed: () => _showEditProjectModal(project),
                                ),
                              ],
                            ),
                          ],
                        ),
                        selected: isSelected,
                        onTap: () {
                          ProjectContext.setActiveProject(project.id!);
                          widget.onProjectSelected(project);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showCreateProjectModal,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Criar Planilha Nova'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F6BFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
