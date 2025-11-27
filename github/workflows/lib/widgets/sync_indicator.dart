import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import 'dart:async';

class SyncIndicator extends StatefulWidget {
  final SyncService syncService;
  final VoidCallback? onSync;
  final bool autoSync;

  const SyncIndicator({
    Key? key,
    required this.syncService,
    this.onSync,
    this.autoSync = false,
  }) : super(key: key);

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  bool _isOnline = false;
  int _pendingCount = 0;
  bool _isSyncing = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    
    // Configurar un temporizador para actualizar el estado periódicamente
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _checkStatus();
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _checkStatus() async {
    if (!mounted) return;
    
    final isOnline = await widget.syncService.hasInternetConnection();
    final pendingCount = await widget.syncService.getPendingSyncCount();
    
    setState(() {
      _isOnline = isOnline;
      _pendingCount = pendingCount;
    });
    
    // Auto-sincronizar si está habilitado y hay elementos pendientes
    if (widget.autoSync && _isOnline && _pendingCount > 0 && !_isSyncing) {
      _syncNow();
    }
  }
  
  Future<void> _syncNow() async {
    if (_isSyncing || !_isOnline) return;
    
    setState(() {
      _isSyncing = true;
    });
    
    try {
      if (widget.onSync != null) {
        widget.onSync!();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        _checkStatus(); // Actualizar estado después de sincronizar
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.greenAccent.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.cloud_done : Icons.cloud_off,
            size: 16,
            color: _isOnline ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          if (_pendingCount > 0)
            Text(
              '$_pendingCount pendiente${_pendingCount > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: _isOnline ? Colors.green[700] : Colors.grey[700],
              ),
            )
          else
            Text(
              _isOnline ? 'Sincronizado' : 'Sin conexión',
              style: TextStyle(
                fontSize: 12,
                color: _isOnline ? Colors.green[700] : Colors.grey[700],
              ),
            ),
        ],
      ),
    );
  }
}