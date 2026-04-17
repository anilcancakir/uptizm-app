import 'package:flutter/material.dart';
import 'package:magic/magic.dart';

import '../../../../app/enums/monitor_type.dart';
import '../common/collapsible_form_section.dart';
import '../common/form_field_label.dart';
import '../common/form_section_card.dart';
import '../common/segmented_choice.dart';
import '../common/setting_toggle_row.dart';
import 'region_multi_select.dart';

class MonitorFormHeader {
  const MonitorFormHeader({required this.name, required this.value});
  final String name;
  final String value;
}

enum MonitorFormTimeout {
  s5(5),
  s15(15),
  s30(30),
  s60(60);

  const MonitorFormTimeout(this.seconds);
  final int seconds;
  String get labelKey => 'monitor.create.timeout_label.$name';
}

/// Prefill payload for [MonitorFormShell]. Pass null to create-mode.
class MonitorFormInitial {
  const MonitorFormInitial({
    this.name = '',
    this.url = '',
    this.expectedStatus = '200',
    this.type = MonitorType.http,
    this.method = HttpMethod.get,
    this.interval = CheckInterval.m1,
    this.regions = const {'eu-west-1'},
    this.sslTracking = true,
    this.alertOnDown = true,
    this.alertOnWarn = false,
    this.timeout = MonitorFormTimeout.s30,
    this.headers = const [],
    this.authType = HttpAuthType.none,
    this.authUsername = '',
    this.authPassword = '',
    this.authToken = '',
    this.authApiKeyName = 'X-API-Key',
    this.authApiKeyValue = '',
  });

  final String name;
  final String url;
  final String expectedStatus;
  final MonitorType type;
  final HttpMethod method;
  final CheckInterval interval;
  final Set<String> regions;
  final bool sslTracking;
  final bool alertOnDown;
  final bool alertOnWarn;
  final MonitorFormTimeout timeout;
  final List<MonitorFormHeader> headers;
  final HttpAuthType authType;
  final String authUsername;
  final String authPassword;
  final String authToken;
  final String authApiKeyName;
  final String authApiKeyValue;

  /// Preloaded values used by the edit flow.
  factory MonitorFormInitial.sample() => const MonitorFormInitial(
    name: 'Production API',
    url: 'https://api.example.com/health',
    expectedStatus: '200',
    type: MonitorType.http,
    method: HttpMethod.get,
    interval: CheckInterval.m1,
    regions: {'eu-west-1', 'us-east-1'},
    sslTracking: true,
    alertOnDown: true,
    alertOnWarn: false,
    timeout: MonitorFormTimeout.s30,
  );
}

/// Snapshot handed to the footer's submit callback.
class MonitorFormValues {
  const MonitorFormValues({
    required this.name,
    required this.url,
    required this.expectedStatus,
    required this.type,
    required this.method,
    required this.interval,
    required this.regions,
    required this.sslTracking,
    required this.alertOnDown,
    required this.alertOnWarn,
    required this.timeout,
    required this.headers,
    required this.authType,
    required this.authUsername,
    required this.authPassword,
    required this.authToken,
    required this.authApiKeyName,
    required this.authApiKeyValue,
  });

  final String name;
  final String url;
  final String expectedStatus;
  final MonitorType type;
  final HttpMethod method;
  final CheckInterval interval;
  final Set<String> regions;
  final bool sslTracking;
  final bool alertOnDown;
  final bool alertOnWarn;
  final MonitorFormTimeout timeout;
  final List<MonitorFormHeader> headers;
  final HttpAuthType authType;
  final String authUsername;
  final String authPassword;
  final String authToken;
  final String authApiKeyName;
  final String authApiKeyValue;
}

/// Shared form body used by both monitor create and edit surfaces.
///
/// Owns the field state internally and delegates layout chrome (page header
/// + footer actions) to callers via [footerBuilder].
class MonitorFormShell extends StatefulWidget {
  const MonitorFormShell({
    super.key,
    this.initial,
    required this.footerBuilder,
  });

  final MonitorFormInitial? initial;
  final Widget Function(
    BuildContext context,
    MonitorFormValues Function() read,
  )
  footerBuilder;

  @override
  State<MonitorFormShell> createState() => _MonitorFormShellState();
}

class _MonitorFormShellState extends State<MonitorFormShell> {
  late final TextEditingController _name;
  late final TextEditingController _url;
  late final TextEditingController _expectedStatus;

  late MonitorType _type;
  late HttpMethod _method;
  late CheckInterval _interval;
  late Set<String> _regions;
  late bool _sslTracking;
  late bool _alertOnDown;
  late bool _alertOnWarn;
  late MonitorFormTimeout _timeout;
  late List<MonitorFormHeader> _headers;
  late HttpAuthType _authType;
  late final TextEditingController _authUsername;
  late final TextEditingController _authPassword;
  late final TextEditingController _authToken;
  late final TextEditingController _authApiKeyName;
  late final TextEditingController _authApiKeyValue;

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? const MonitorFormInitial();
    _name = TextEditingController(text: i.name);
    _url = TextEditingController(text: i.url);
    _expectedStatus = TextEditingController(text: i.expectedStatus);
    _type = i.type;
    _method = i.method;
    _interval = i.interval;
    _regions = Set<String>.from(i.regions);
    _sslTracking = i.sslTracking;
    _alertOnDown = i.alertOnDown;
    _alertOnWarn = i.alertOnWarn;
    _timeout = i.timeout;
    _headers = List<MonitorFormHeader>.from(i.headers);
    _authType = i.authType;
    _authUsername = TextEditingController(text: i.authUsername);
    _authPassword = TextEditingController(text: i.authPassword);
    _authToken = TextEditingController(text: i.authToken);
    _authApiKeyName = TextEditingController(text: i.authApiKeyName);
    _authApiKeyValue = TextEditingController(text: i.authApiKeyValue);
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _expectedStatus.dispose();
    _authUsername.dispose();
    _authPassword.dispose();
    _authToken.dispose();
    _authApiKeyName.dispose();
    _authApiKeyValue.dispose();
    super.dispose();
  }

  MonitorFormValues _read() => MonitorFormValues(
    name: _name.text,
    url: _url.text,
    expectedStatus: _expectedStatus.text,
    type: _type,
    method: _method,
    interval: _interval,
    regions: _regions,
    sslTracking: _sslTracking,
    alertOnDown: _alertOnDown,
    alertOnWarn: _alertOnWarn,
    timeout: _timeout,
    headers: _headers,
    authType: _authType,
    authUsername: _authUsername.text,
    authPassword: _authPassword.text,
    authToken: _authToken.text,
    authApiKeyName: _authApiKeyName.text,
    authApiKeyValue: _authApiKeyValue.text,
  );

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'flex flex-col gap-6',
      children: [
        _basicsSection(),
        _checkSettingsSection(),
        if (_type == MonitorType.http) _authSection(),
        if (_type == MonitorType.http) _advancedSection(),
        _regionsSection(),
        _alertsSection(),
        widget.footerBuilder(context, _read),
      ],
    );
  }

  Widget _basicsSection() {
    return FormSectionCard(
      titleKey: 'monitor.create.basics.title',
      subtitleKey: 'monitor.create.basics.subtitle',
      icon: Icons.description_outlined,
      child: WDiv(
        className: 'flex flex-col gap-4',
        children: [
          WDiv(
            className: 'flex flex-col',
            children: [
              const FormFieldLabel(
                labelKey: 'monitor.create.fields.name',
                hintKey: 'monitor.create.fields.name_hint',
                required: true,
              ),
              WInput(
                value: _name.text,
                onChanged: (v) => _name.text = v,
                placeholder: 'Production API',
                className: '''
                  w-full px-3 py-2.5 rounded-lg
                  bg-white dark:bg-gray-900
                  border border-gray-200 dark:border-gray-700
                  text-sm text-gray-900 dark:text-white
                  focus:border-primary-500 dark:focus:border-primary-400
                ''',
              ),
            ],
          ),
          WDiv(
            className: 'flex flex-col',
            children: [
              const FormFieldLabel(
                labelKey: 'monitor.create.fields.type',
                hintKey: 'monitor.create.fields.type_hint',
              ),
              SegmentedChoice<MonitorType>(
                options: MonitorType.values,
                selected: _type,
                onChanged: (v) => setState(() => _type = v),
                labelBuilder: (v) => trans(v.labelKey),
                iconBuilder: (v) => switch (v) {
                  MonitorType.http => Icons.public_rounded,
                  MonitorType.tcp => Icons.lan_outlined,
                },
              ),
            ],
          ),
          WDiv(
            className: 'flex flex-col',
            children: [
              FormFieldLabel(
                labelKey: _type == MonitorType.http
                    ? 'monitor.create.fields.url'
                    : 'monitor.create.fields.host',
                hintKey: _type.hintKey,
                required: true,
              ),
              WInput(
                value: _url.text,
                onChanged: (v) => _url.text = v,
                placeholder: _type == MonitorType.http
                    ? 'https://api.example.com/health'
                    : 'db.example.com:5432',
                className: '''
                  w-full px-3 py-2.5 rounded-lg
                  bg-white dark:bg-gray-900
                  border border-gray-200 dark:border-gray-700
                  text-sm text-gray-900 dark:text-white
                  focus:border-primary-500 dark:focus:border-primary-400
                ''',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkSettingsSection() {
    return FormSectionCard(
      titleKey: 'monitor.create.check.title',
      subtitleKey: 'monitor.create.check.subtitle',
      icon: Icons.tune_rounded,
      child: WDiv(
        className: 'flex flex-col gap-4',
        children: [
          if (_type == MonitorType.http)
            WDiv(
              className: 'flex flex-col',
              children: [
                const FormFieldLabel(
                  labelKey: 'monitor.create.fields.method',
                ),
                SegmentedChoice<HttpMethod>(
                  options: HttpMethod.values,
                  selected: _method,
                  onChanged: (v) => setState(() => _method = v),
                  labelBuilder: (v) => v.label,
                ),
              ],
            ),
          WDiv(
            className: 'flex flex-col',
            children: [
              const FormFieldLabel(
                labelKey: 'monitor.create.fields.interval',
                hintKey: 'monitor.create.fields.interval_hint',
                required: true,
              ),
              SegmentedChoice<CheckInterval>(
                options: CheckInterval.values,
                selected: _interval,
                onChanged: (v) => setState(() => _interval = v),
                labelBuilder: (v) => v.label,
              ),
            ],
          ),
          if (_type == MonitorType.http)
            SettingToggleRow(
              icon: Icons.lock_outline_rounded,
              titleKey: 'monitor.create.fields.ssl_title',
              subtitleKey: 'monitor.create.fields.ssl_subtitle',
              value: _sslTracking,
              onChanged: (v) => setState(() => _sslTracking = v),
            ),
        ],
      ),
    );
  }

  Widget _authSection() {
    return FormSectionCard(
      titleKey: 'monitor.create.auth.title',
      subtitleKey: 'monitor.create.auth.subtitle',
      icon: Icons.key_outlined,
      child: WDiv(
        className: 'flex flex-col gap-4',
        children: [
          SegmentedChoice<HttpAuthType>(
            options: HttpAuthType.values,
            selected: _authType,
            onChanged: (v) => setState(() => _authType = v),
            labelBuilder: (v) => trans(v.labelKey),
            iconBuilder: (v) => switch (v) {
              HttpAuthType.none => Icons.lock_open_rounded,
              HttpAuthType.basic => Icons.person_outline_rounded,
              HttpAuthType.bearer => Icons.vpn_key_outlined,
              HttpAuthType.apiKey => Icons.badge_outlined,
            },
          ),
          if (_authType == HttpAuthType.basic) _authBasicFields(),
          if (_authType == HttpAuthType.bearer) _authBearerField(),
          if (_authType == HttpAuthType.apiKey) _authApiKeyFields(),
          if (_authType != HttpAuthType.none) _authSecurityNote(),
        ],
      ),
    );
  }

  Widget _authBasicFields() {
    return WDiv(
      className: 'flex flex-col gap-3',
      children: [
        WDiv(
          className: 'flex flex-col',
          children: [
            const FormFieldLabel(
              labelKey: 'monitor.create.auth.basic.username',
              required: true,
            ),
            WInput(
              value: _authUsername.text,
              onChanged: (v) => _authUsername.text = v,
              placeholder: trans(
                'monitor.create.auth.basic.username_placeholder',
              ),
              className: '''
                w-full px-3 py-2.5 rounded-lg
                bg-white dark:bg-gray-900
                border border-gray-200 dark:border-gray-700
                text-sm text-gray-900 dark:text-white
                focus:border-primary-500 dark:focus:border-primary-400
              ''',
            ),
          ],
        ),
        WDiv(
          className: 'flex flex-col',
          children: [
            const FormFieldLabel(
              labelKey: 'monitor.create.auth.basic.password',
              required: true,
            ),
            WInput(
              value: _authPassword.text,
              onChanged: (v) => _authPassword.text = v,
              type: InputType.password,
              placeholder: trans(
                'monitor.create.auth.basic.password_placeholder',
              ),
              className: '''
                w-full px-3 py-2.5 rounded-lg
                bg-white dark:bg-gray-900
                border border-gray-200 dark:border-gray-700
                text-sm font-mono text-gray-900 dark:text-white
                focus:border-primary-500 dark:focus:border-primary-400
              ''',
            ),
          ],
        ),
      ],
    );
  }

  Widget _authBearerField() {
    return WDiv(
      className: 'flex flex-col',
      children: [
        const FormFieldLabel(
          labelKey: 'monitor.create.auth.bearer.token',
          hintKey: 'monitor.create.auth.bearer.token_hint',
          required: true,
        ),
        WInput(
          value: _authToken.text,
          onChanged: (v) => _authToken.text = v,
          type: InputType.password,
          placeholder: trans('monitor.create.auth.bearer.token_placeholder'),
          className: '''
            w-full px-3 py-2.5 rounded-lg
            bg-white dark:bg-gray-900
            border border-gray-200 dark:border-gray-700
            text-sm font-mono text-gray-900 dark:text-white
            focus:border-primary-500 dark:focus:border-primary-400
          ''',
        ),
      ],
    );
  }

  Widget _authApiKeyFields() {
    return WDiv(
      className: 'flex flex-col gap-3',
      children: [
        WDiv(
          className: 'flex flex-col',
          children: [
            const FormFieldLabel(
              labelKey: 'monitor.create.auth.api_key.header_name',
              hintKey: 'monitor.create.auth.api_key.header_name_hint',
              required: true,
            ),
            WInput(
              value: _authApiKeyName.text,
              onChanged: (v) => _authApiKeyName.text = v,
              placeholder: 'X-API-Key',
              className: '''
                w-full px-3 py-2.5 rounded-lg
                bg-white dark:bg-gray-900
                border border-gray-200 dark:border-gray-700
                text-sm font-mono text-gray-900 dark:text-white
                focus:border-primary-500 dark:focus:border-primary-400
              ''',
            ),
          ],
        ),
        WDiv(
          className: 'flex flex-col',
          children: [
            const FormFieldLabel(
              labelKey: 'monitor.create.auth.api_key.value',
              required: true,
            ),
            WInput(
              value: _authApiKeyValue.text,
              onChanged: (v) => _authApiKeyValue.text = v,
              type: InputType.password,
              placeholder: trans('monitor.create.auth.api_key.value_placeholder'),
              className: '''
                w-full px-3 py-2.5 rounded-lg
                bg-white dark:bg-gray-900
                border border-gray-200 dark:border-gray-700
                text-sm font-mono text-gray-900 dark:text-white
                focus:border-primary-500 dark:focus:border-primary-400
              ''',
            ),
          ],
        ),
      ],
    );
  }

  Widget _authSecurityNote() {
    return WDiv(
      className: '''
        rounded-lg px-3 py-2
        bg-primary-50 dark:bg-primary-900/20
        border border-primary-200 dark:border-primary-800/50
        flex flex-row items-start gap-2
      ''',
      children: [
        WIcon(
          Icons.shield_outlined,
          className: '''
            text-sm text-primary-600 dark:text-primary-300
            mt-0.5
          ''',
        ),
        WDiv(
          className: 'flex-1 min-w-0',
          child: WText(
            trans('monitor.create.auth.security_note'),
            className: '''
              text-xs leading-relaxed
              text-primary-700 dark:text-primary-200
            ''',
          ),
        ),
      ],
    );
  }

  Widget _advancedSection() {
    return CollapsibleFormSection(
      titleKey: 'monitor.create.advanced.title',
      subtitleKey: 'monitor.create.advanced.subtitle',
      icon: Icons.settings_suggest_outlined,
      child: WDiv(
        className: 'flex flex-col gap-5',
        children: [
          WDiv(
            className: 'flex flex-col',
            children: [
              const FormFieldLabel(
                labelKey: 'monitor.create.advanced.expected_status',
                hintKey: 'monitor.create.advanced.expected_status_hint',
              ),
              WInput(
                value: _expectedStatus.text,
                onChanged: (v) => _expectedStatus.text = v,
                placeholder: '200',
                className: '''
                  w-full px-3 py-2.5 rounded-lg
                  bg-white dark:bg-gray-900
                  border border-gray-200 dark:border-gray-700
                  text-sm text-gray-900 dark:text-white
                  focus:border-primary-500 dark:focus:border-primary-400
                ''',
              ),
            ],
          ),
          WDiv(
            className: 'flex flex-col',
            children: [
              const FormFieldLabel(
                labelKey: 'monitor.create.advanced.timeout',
                hintKey: 'monitor.create.advanced.timeout_hint',
              ),
              SegmentedChoice<MonitorFormTimeout>(
                options: MonitorFormTimeout.values,
                selected: _timeout,
                onChanged: (v) => setState(() => _timeout = v),
                labelBuilder: (v) => trans(v.labelKey),
              ),
            ],
          ),
          WDiv(
            className: 'flex flex-col gap-2',
            children: [
              const FormFieldLabel(
                labelKey: 'monitor.create.advanced.headers',
                hintKey: 'monitor.create.advanced.headers_hint',
              ),
              _headerPresets(),
              for (var i = 0; i < _headers.length; i++) _headerRow(i),
              _addHeaderButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerPresets() {
    final presets = [
      ('Accept', 'application/json', 'monitor.create.advanced.preset_accept_json'),
      ('User-Agent', 'Uptizm/1.0', 'monitor.create.advanced.preset_user_agent'),
      ('Authorization', 'Bearer ', 'monitor.create.advanced.preset_authorization'),
    ];
    return WDiv(
      className: 'flex flex-row flex-wrap gap-2',
      children: [
        for (final p in presets)
          WButton(
            onTap: () => setState(
              () => _headers.add(MonitorFormHeader(name: p.$1, value: p.$2)),
            ),
            className: '''
              px-2.5 py-1.5 rounded-full
              bg-gray-100 dark:bg-gray-800
              border border-gray-200 dark:border-gray-700
              hover:bg-gray-200 dark:hover:bg-gray-700
              flex flex-row items-center gap-1.5
            ''',
            child: WDiv(
              className: 'flex flex-row items-center gap-1.5',
              children: [
                WIcon(
                  Icons.add_rounded,
                  className: 'text-xs text-gray-600 dark:text-gray-300',
                ),
                WText(
                  trans(p.$3),
                  className: '''
                    text-xs font-mono
                    text-gray-700 dark:text-gray-200
                  ''',
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _headerRow(int index) {
    final h = _headers[index];
    return WDiv(
      className: 'flex flex-row items-center gap-2',
      children: [
        WDiv(
          className: 'w-1/3',
          child: WInput(
            value: h.name,
            onChanged: (v) => setState(
              () => _headers[index] = MonitorFormHeader(
                name: v,
                value: h.value,
              ),
            ),
            placeholder: trans(
              'monitor.create.advanced.header_name_placeholder',
            ),
            className: '''
              w-full px-3 py-2 rounded-lg
              bg-white dark:bg-gray-900
              border border-gray-200 dark:border-gray-700
              text-xs font-mono text-gray-900 dark:text-white
              focus:border-primary-500 dark:focus:border-primary-400
            ''',
          ),
        ),
        WDiv(
          className: 'flex-1',
          child: WInput(
            value: h.value,
            onChanged: (v) => setState(
              () => _headers[index] = MonitorFormHeader(
                name: h.name,
                value: v,
              ),
            ),
            placeholder: trans(
              'monitor.create.advanced.header_value_placeholder',
            ),
            className: '''
              w-full px-3 py-2 rounded-lg
              bg-white dark:bg-gray-900
              border border-gray-200 dark:border-gray-700
              text-xs font-mono text-gray-900 dark:text-white
              focus:border-primary-500 dark:focus:border-primary-400
            ''',
          ),
        ),
        WButton(
          onTap: () => setState(() => _headers.removeAt(index)),
          className: '''
            p-2 rounded-lg
            hover:bg-down-50 dark:hover:bg-down-900/30
            flex items-center justify-center
          ''',
          child: WIcon(
            Icons.close_rounded,
            className: 'text-sm text-gray-500 dark:text-gray-400',
          ),
        ),
      ],
    );
  }

  Widget _addHeaderButton() {
    return WButton(
      onTap: () => setState(
        () => _headers.add(const MonitorFormHeader(name: '', value: '')),
      ),
      className: '''
        w-full px-3 py-2.5 rounded-lg
        border border-dashed border-gray-300 dark:border-gray-600
        hover:bg-gray-50 dark:hover:bg-gray-800
        flex flex-row items-center justify-center gap-1.5
      ''',
      child: WDiv(
        className: 'flex flex-row items-center gap-1.5',
        children: [
          WIcon(
            Icons.add_rounded,
            className: 'text-sm text-gray-500 dark:text-gray-400',
          ),
          WText(
            trans('monitor.create.advanced.add_header'),
            className: '''
              text-sm font-semibold
              text-gray-600 dark:text-gray-300
            ''',
          ),
        ],
      ),
    );
  }

  Widget _regionsSection() {
    const options = [
      RegionOption(
        value: 'eu-west-1',
        code: 'EU-W1',
        flag: '🇮🇪',
        city: 'Dublin',
        country: 'Ireland',
      ),
      RegionOption(
        value: 'eu-central-1',
        code: 'EU-C1',
        flag: '🇩🇪',
        city: 'Frankfurt',
        country: 'Germany',
      ),
      RegionOption(
        value: 'us-east-1',
        code: 'US-E1',
        flag: '🇺🇸',
        city: 'Virginia',
        country: 'United States',
      ),
      RegionOption(
        value: 'us-west-2',
        code: 'US-W2',
        flag: '🇺🇸',
        city: 'Oregon',
        country: 'United States',
      ),
      RegionOption(
        value: 'ap-southeast-1',
        code: 'AP-SE1',
        flag: '🇸🇬',
        city: 'Singapore',
        country: 'Singapore',
      ),
      RegionOption(
        value: 'ap-northeast-1',
        code: 'AP-NE1',
        flag: '🇯🇵',
        city: 'Tokyo',
        country: 'Japan',
      ),
      RegionOption(
        value: 'sa-east-1',
        code: 'SA-E1',
        flag: '🇧🇷',
        city: 'São Paulo',
        country: 'Brazil',
      ),
    ];

    return FormSectionCard(
      titleKey: 'monitor.create.regions.title',
      subtitleKey: 'monitor.create.regions.subtitle',
      icon: Icons.public_rounded,
      child: WDiv(
        className: 'flex flex-col gap-3',
        children: [
          RegionMultiSelect(
            options: options,
            selected: _regions,
            onChanged: (v) => setState(() => _regions = v),
          ),
          WText(
            trans(
              'monitor.create.regions.count',
              {'count': '${_regions.length}'},
            ),
            className: 'text-xs text-gray-500 dark:text-gray-400',
          ),
        ],
      ),
    );
  }

  Widget _alertsSection() {
    return FormSectionCard(
      titleKey: 'monitor.create.alerts.title',
      subtitleKey: 'monitor.create.alerts.subtitle',
      icon: Icons.notifications_active_outlined,
      child: WDiv(
        className: 'flex flex-col gap-2',
        children: [
          SettingToggleRow(
            icon: Icons.error_outline_rounded,
            titleKey: 'monitor.create.fields.alert_down_title',
            subtitleKey: 'monitor.create.fields.alert_down_subtitle',
            value: _alertOnDown,
            onChanged: (v) => setState(() => _alertOnDown = v),
          ),
          SettingToggleRow(
            icon: Icons.warning_amber_rounded,
            titleKey: 'monitor.create.fields.alert_warn_title',
            subtitleKey: 'monitor.create.fields.alert_warn_subtitle',
            value: _alertOnWarn,
            onChanged: (v) => setState(() => _alertOnWarn = v),
          ),
        ],
      ),
    );
  }
}
