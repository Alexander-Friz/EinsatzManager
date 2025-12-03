import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/einsatz.dart';
import '../services/einsatz_service.dart';
import 'einsatz_detail_screen.dart';
import 'new_einsatz_screen.dart';
import 'dokumentation_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('EinsatzManager'),
          centerTitle: true,
          elevation: 0,
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.priority_high), text: 'Aktiv'),
              Tab(icon: Icon(Icons.pending_actions), text: 'Ausstehend'),
              Tab(icon: Icon(Icons.check_circle), text: 'Abgeschlossen'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildActiveTab(context),
            _buildPendingTab(context),
            _buildCompletedTab(context),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DokumentationScreen()),
                );
              },
              tooltip: 'Einsatz Dokumentieren',
              heroTag: 'dokumentation',
              backgroundColor: Colors.white,
              child: const Icon(Icons.description),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NewEinsatzScreen()),
                );
              },
              tooltip: 'Neuer Einsatz',
              heroTag: 'neuer_einsatz',
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab(BuildContext context) {
    return Consumer<EinsatzService>(
      builder: (context, service, _) {
        final activeEinsaetze = service.activeEinsaetze;
        if (activeEinsaetze.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Keine aktiven Einsätze',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: activeEinsaetze.length,
          itemBuilder: (context, index) =>
              _buildEinsatzCard(context, activeEinsaetze[index]),
        );
      },
    );
  }

  Widget _buildPendingTab(BuildContext context) {
    return Consumer<EinsatzService>(
      builder: (context, service, _) {
        final pendingEinsaetze = service.pendingEinsaetze;
        if (pendingEinsaetze.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.done_all, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Keine ausstehenden Einsätze',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: pendingEinsaetze.length,
          itemBuilder: (context, index) =>
              _buildEinsatzCard(context, pendingEinsaetze[index]),
        );
      },
    );
  }

  Widget _buildCompletedTab(BuildContext context) {
    return Consumer<EinsatzService>(
      builder: (context, service, _) {
        final completedEinsaetze = service.completedEinsaetze;
        if (completedEinsaetze.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Keine abgeschlossenen Einsätze',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: completedEinsaetze.length,
          itemBuilder: (context, index) =>
              _buildEinsatzCard(context, completedEinsaetze[index]),
        );
      },
    );
  }

  Widget _buildEinsatzCard(BuildContext context, Einsatz einsatz) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EinsatzDetailScreen(einsatz: einsatz),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(12),
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: _getPriorityColor(einsatz.priority),
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            einsatz.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            einsatz.type.label,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(einsatz.status.label),
                      backgroundColor: _getStatusColor(einsatz.status),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        einsatz.address,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      einsatz.formattedCreatedAt,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                ),
                if (einsatz.assignedPersonnel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: einsatz.assignedPersonnel.take(3).map((person) {
                      return Chip(
                        label: Text(
                          person,
                          style: const TextStyle(fontSize: 11),
                        ),
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                  if (einsatz.assignedPersonnel.length > 3)
                    Text(
                      '+${einsatz.assignedPersonnel.length - 3} mehr',
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(EinsatzPriority priority) {
    switch (priority) {
      case EinsatzPriority.high:
        return Colors.red;
      case EinsatzPriority.medium:
        return Colors.orange;
      case EinsatzPriority.low:
        return Colors.green;
    }
  }

  Color _getStatusColor(EinsatzStatus status) {
    switch (status) {
      case EinsatzStatus.active:
        return Colors.red;
      case EinsatzStatus.pending:
        return Colors.orange;
      case EinsatzStatus.completed:
        return Colors.green;
      case EinsatzStatus.cancelled:
        return Colors.grey;
    }
  }
}
