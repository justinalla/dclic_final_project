// Fichier: lib/taches_interface.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/database_manager.dart';
import 'modele/tache_modele.dart';
import 'formulaire_taches.dart'; // Importation du formulaire (maintenant dans lib/)

class TachesInterface extends StatefulWidget {
  const TachesInterface({super.key});

  @override
  State<TachesInterface> createState() => _TachesInterfaceState();
}

class _TachesInterfaceState extends State<TachesInterface> {
  List<Tache> _tasks = [];
  int? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndTasks();
  }

  // 1. Chargement de l'ID utilisateur et des tâches
  Future<void> _loadUserIdAndTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    if (userId == null || userId == 0) {
      // Déconnexion si l'ID est perdu
      _handleLogout();
      return;
    }
    
    _currentUserId = userId;
    await _loadTasks();
  }

  // 2. Récupération des tâches
  Future<void> _loadTasks() async {
    if (_currentUserId == null) return;
    setState(() => _isLoading = true);
    
    try {
      final tasks = await DatabaseManager.instance.getTasksByUserId(_currentUserId!);
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur de chargement des tâches: $e");
      setState(() => _isLoading = false);
    }
  }

  // 3. Gestion de la déconnexion
  Future<void> _handleLogout() async {
    await DatabaseManager.instance.logOut();
    if (mounted) {
      // Retour à la page de connexion et suppression de l'historique
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  // 4. Mettre à jour le statut (Terminé / En cours)
  Future<void> _toggleTaskStatus(Tache task) async {
    final newStatus = task.isDone == 0 ? 1 : 0;
    
    await DatabaseManager.instance.updateTaskStatus(task.id!, _currentUserId!, newStatus == 1);
    
    // Rafraîchir la liste après la mise à jour
    _loadTasks(); 
  }

  // 5. Suppression d'une tâche (avec confirmation)
  Future<void> _confirmAndDeleteTask(int taskId) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Êtes-vous sûr de vouloir supprimer cette note ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && _currentUserId != null) {
      await DatabaseManager.instance.deleteTask(taskId, _currentUserId!);
      _loadTasks();
    }
  }
  
  // 6. Navigation vers le Formulaire d'ajout/modification
  void _navigateToFileForm({Tache? task}) async {
    // Le formulaire renvoie true si une modification ou un ajout a eu lieu
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(
          userId: _currentUserId!, 
          task: task,
        ),
      ),
    );
    
    // Si le formulaire a renvoyé true, rafraîchir la liste
    if (result == true) {
      _loadTasks();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Notes (To-Do)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text(
                      "Aucune note à afficher.\nCliquez sur le '+' pour ajouter votre première tâche !",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80.0), // Espace pour le FAB
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    final isDone = task.isDone == 1;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      color: isDone ? Colors.green.shade50 : Colors.white,
                      elevation: 2,
                      child: ListTile(
                        leading: Checkbox(
                          value: isDone,
                          onChanged: (_) => _toggleTaskStatus(task),
                          activeColor: Colors.green,
                        ),
                        title: Text(
                          task.titre,
                          style: TextStyle(
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: task.description != null && task.description!.isNotEmpty
                            ? Text(task.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
                            : null,
                        onTap: () => _navigateToFileForm(task: task), // Édition au tap
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmAndDeleteTask(task.id!),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToFileForm(),
        tooltip: 'Ajouter une note',
        child: const Icon(Icons.add),
      ),
    );
  }
}