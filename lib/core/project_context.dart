/// Manages the active project context for the current user session.
/// This is a simple in-memory state holder that tracks which project is currently selected.
/// Note: This resets to the default project (id=1) on app restart.
/// Future enhancement: Persist active projectId to SharedPreferences for continuity across sessions.
class ProjectContext {
  static int _activeProjectId = 1;

  /// Get the currently active project ID
  static int getActiveProjectId() => _activeProjectId;

  /// Set the active project ID
  static void setActiveProject(int projectId) {
    _activeProjectId = projectId;
  }

  /// Reset to default project (id=1)
  static void resetToDefault() {
    _activeProjectId = 1;
  }
}
