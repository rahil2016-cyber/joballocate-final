import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../models/job.dart';
import '../navigation/app_navigator.dart';
import '../screens/job_seeker/job_detail_screen.dart';
import '../services/app_session.dart';
import '../services/job_seeker_api_service.dart';

/// Listens for `joballocate://job/{id}` and opens [JobDetailScreen].
class JobDeepLinkListener extends StatefulWidget {
  const JobDeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  State<JobDeepLinkListener> createState() => _JobDeepLinkListenerState();
}

class _JobDeepLinkListenerState extends State<JobDeepLinkListener> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    _initLinks();
  }

  Future<void> _initLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handleUri(initial);
      }
    } catch (_) {}

    _sub = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String? _parseJobId(Uri uri) {
    if (uri.scheme == 'joballocate' && uri.host == 'job') {
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first;
      }
      final p = uri.path.replaceFirst('/', '');
      if (p.isNotEmpty) return p;
    }

    final segs = uri.pathSegments;
    if (segs.length >= 2 && segs[0] == 'job') {
      return segs[1];
    }
    if (segs.length == 1 && segs[0] == 'job' && uri.queryParameters['id'] != null) {
      return uri.queryParameters['id'];
    }

    return null;
  }

  Future<void> _handleUri(Uri uri) async {
    final jobId = _parseJobId(uri);
    if (jobId == null || jobId.isEmpty || _handling) return;

    _handling = true;
    try {
      final job = await JobSeekerApiService.instance.getJob(jobId);
      final nav = rootNavigatorKey.currentState;
      if (nav == null) return;

      await nav.push(
        MaterialPageRoute<void>(
          builder: (_) => JobDetailScreen(
            job: job,
            userId: AppSession.userId ?? 'guest',
            token: AppSession.token ?? '',
          ),
        ),
      );
    } catch (_) {
      // Job missing or network error — ignore silently.
    } finally {
      _handling = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
