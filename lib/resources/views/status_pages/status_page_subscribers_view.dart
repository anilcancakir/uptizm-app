import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../../../app/controllers/status_pages/status_page_subscriber_controller.dart';
import '../../../app/models/status_page_subscriber.dart';
import '../components/common/app_back_button.dart';
import '../components/common/empty_state.dart';
import '../components/common/error_banner.dart';
import '../components/common/refresh_icon_button.dart';
import '../components/common/skeleton_row.dart';

/// Admin list of email subscribers for a given status page.
///
/// Surfaces double opt-in state (`unconfirmed` / `active` / `unsubscribed` /
/// `quarantined`), confirmation timestamp, and whether the subscriber has a
/// component-scoped filter. Remove is optimistic and protected by a confirm
/// dialog — the public subscribe/confirm/unsubscribe flow happens via the
/// Blade SSR side, so the app only needs read + remove here.
class StatusPageSubscribersView
    extends MagicStatefulView<StatusPageSubscriberController> {
  const StatusPageSubscribersView({super.key, required this.statusPageId});

  final String statusPageId;

  @override
  State<StatusPageSubscribersView> createState() =>
      _StatusPageSubscribersViewState();
}

class _StatusPageSubscribersViewState
    extends
        MagicStatefulViewState<
          StatusPageSubscriberController,
          StatusPageSubscribersView
        > {
  @override
  void onInit() {
    super.onInit();
    controller.load(widget.statusPageId);
  }

  Future<void> _refresh() => controller.load(widget.statusPageId);

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'p-4 lg:p-6 flex flex-col gap-6',
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (_, _) => MagicStarterPageHeader(
            title: trans('subscriber.list.title'),
            subtitle: trans('subscriber.list.subtitle'),
            inlineActions: true,
            leading: const AppBackButton(fallbackPath: '/status-pages'),
            actions: [
              RefreshIconButton(
                onTap: _refresh,
                isRefreshing: controller.rxStatus.isLoading,
              ),
            ],
          ),
        ),
        RefreshIndicator(
          onRefresh: _refresh,
          child: controller.renderState(
            (subscribers) => _body(subscribers),
            onLoading: const SkeletonRowList(),
            onEmpty: _empty(),
            onError: (msg) => ErrorBanner(message: msg, onRetry: _refresh),
          ),
        ),
      ],
    );
  }

  Widget _body(List<StatusPageSubscriber> subscribers) {
    if (subscribers.isEmpty) return _empty();
    return WDiv(
      className: 'flex flex-col gap-2',
      children: [for (final subscriber in subscribers) _row(subscriber)],
    );
  }

  Widget _row(StatusPageSubscriber subscriber) {
    return WDiv(
      className: '''
        px-4 py-3 rounded-lg border
        bg-white dark:bg-gray-900
        border-gray-200 dark:border-gray-700
        flex flex-col gap-2
      ''',
      children: [
        WDiv(
          className: 'flex flex-row items-center justify-between gap-3',
          children: [
            WDiv(
              className: 'flex-1 min-w-0 flex flex-col gap-1',
              children: [
                WText(
                  subscriber.email,
                  className: '''
                    text-sm font-semibold
                    text-gray-900 dark:text-white truncate
                  ''',
                ),
                WDiv(
                  className: 'flex flex-row items-center gap-2 flex-wrap',
                  children: [
                    _statePill(subscriber),
                    _scopePill(subscriber),
                    if (subscriber.confirmedAt != null)
                      WText(
                        '${trans('subscriber.confirmed_at')} · '
                        '${Carbon.parse(subscriber.confirmedAt!.toIso8601String()).diffForHumans()}',
                        className: '''
                          text-[11px]
                          text-muted dark:text-muted-dark
                        ''',
                      ),
                  ],
                ),
              ],
            ),
            WButton(
              onTap: () => _remove(subscriber),
              className: '''
                px-3 py-2 rounded-lg
                bg-down-50 dark:bg-down-900/30
                border border-down-200 dark:border-down-800
                hover:bg-down-100 dark:hover:bg-down-900/50
              ''',
              child: WText(
                trans('subscriber.actions.remove'),
                className: '''
                  text-xs font-semibold
                  text-down-700 dark:text-down-300
                ''',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statePill(StatusPageSubscriber subscriber) {
    final tone = switch (subscriber.state) {
      'active' => 'up',
      'unconfirmed' => 'paused',
      'quarantined' => 'degraded',
      _ => 'gray',
    };
    return WDiv(
      className:
          '''
        px-2 py-0.5 rounded-full
        bg-$tone-50 dark:bg-$tone-900/30
        border border-$tone-200 dark:border-$tone-800
      ''',
      child: WText(
        trans('subscriber.state.${subscriber.state}'),
        className:
            '''
          text-[10px] font-bold uppercase tracking-wide
          text-$tone-700 dark:text-$tone-300
        ''',
      ),
    );
  }

  Widget _scopePill(StatusPageSubscriber subscriber) {
    final ids = subscriber.monitorIds;
    final label = ids == null || ids.isEmpty
        ? trans('subscriber.scope.all')
        : trans('subscriber.scope.filtered', {'count': ids.length.toString()});
    return WDiv(
      className: '''
        px-2 py-0.5 rounded-full
        bg-subtle dark:bg-subtle-dark
        border border-subtle dark:border-subtle-dark
      ''',
      child: WText(
        label,
        className: '''
          text-[10px] font-bold uppercase tracking-wide
          text-muted dark:text-muted-dark
        ''',
      ),
    );
  }

  Widget _empty() {
    return const EmptyState(
      titleKey: 'subscriber.empty',
      icon: Icons.mark_email_read_outlined,
    );
  }

  Future<void> _remove(StatusPageSubscriber subscriber) async {
    final ok = await Magic.confirm(
      title: trans('subscriber.actions.remove'),
      message: trans('subscriber.actions.confirm_remove'),
      isDangerous: true,
    );
    if (!ok) return;
    final removed = await controller.remove(subscriber.id);
    if (!mounted || !removed) return;
    Magic.toast(trans('subscriber.toast.removed'));
  }
}
