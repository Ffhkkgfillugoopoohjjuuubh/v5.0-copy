import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/project_model.dart';
import '../services/storage_service.dart';

final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, List<ProjectModel>>(
  (ref) => ProjectsNotifier(ref.watch(storageServiceProvider)),
);

class ProjectsNotifier extends StateNotifier<List<ProjectModel>> {
  ProjectsNotifier(this._storageService) : super(const <ProjectModel>[]) {
    _loadProjects();
  }

  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  Future<void> _loadProjects() async {
    state = await _storageService.loadProjects();
  }

  Future<ProjectModel> createProject(String name) async {
    final project = ProjectModel(
      id: _uuid.v4(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );

    state = <ProjectModel>[...state, project];
    await _storageService.saveProject(project);
    return project;
  }

  Future<void> renameProject(String id, String newName) async {
    final updated = <ProjectModel>[];

    for (final project in state) {
      if (project.id != id) {
        updated.add(project);
        continue;
      }

      final renamed = project.copyWith(name: newName.trim());
      updated.add(renamed);
      await _storageService.saveProject(renamed);
    }

    state = updated;
  }

  Future<void> deleteProject(String id) async {
    state = state.where((project) => project.id != id).toList();
    await _storageService.deleteProject(id);
  }
}
