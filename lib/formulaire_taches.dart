// Fichier: lib/formulaire_taches.dart

import 'package:flutter/material.dart';
import 'services/database_manager.dart';
import 'modele/tache_modele.dart';

class TaskFormScreen extends StatefulWidget {
  final int userId;
  final Tache? task; // Nullable pour l'ajout, non-null pour l'édition

  const TaskFormScreen({
    super.key,
    required this.userId,
    this.task,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    // Initialisation des contrôleurs avec les données existantes si c'est une édition
    _titleController = TextEditingController(text: widget.task?.titre ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    final Tache newOrUpdatedTask;

    if (isEditing) {
      // Cas de la MODIFICATION
      newOrUpdatedTask = Tache(
        id: widget.task!.id,
        userId: widget.userId,
        titre: _titleController.text,
        // Si la description est vide, on stocke null
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        isDone: widget.task!.isDone, // On conserve l'ancien statut
      );
      await DatabaseManager.instance.updateTask(newOrUpdatedTask);
    } else {
      // Cas de la CREATION
      newOrUpdatedTask = Tache.sansId(
        userId: widget.userId,
        titre: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        isDone: 0, // Par défaut, non terminée
      );
      await DatabaseManager.instance.createTask(newOrUpdatedTask);
    }
    
    // Fermer l'écran et retourner 'true' pour signaler que la liste doit se rafraîchir
    if (mounted) {
      Navigator.of(context).pop(true); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier la Note' : 'Nouvelle Note'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Champ Titre (obligatoire)
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre de la Note',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Le titre est obligatoire.' : null,
              ),
              const SizedBox(height: 20),

              // Champ Description (optionnel)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Détails de la Note (Optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 30),

              // Bouton Enregistrer
              ElevatedButton.icon(
                onPressed: _handleSave,
                icon: const Icon(Icons.save),
                label: Text(
                  isEditing ? 'Sauvegarder les modifications' : 'Ajouter la Note', 
                  style: const TextStyle(fontSize: 18)
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}