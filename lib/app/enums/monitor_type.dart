/// Supported monitor check methods for the create form.
enum MonitorType {
  http,
  tcp;

  String get labelKey => 'monitor.type.$name';
  String get hintKey => 'monitor.type_hint.$name';
}

/// HTTP methods selectable for HTTP monitors.
enum HttpMethod {
  get,
  post,
  head;

  String get label => name.toUpperCase();
}

/// Authentication scheme applied to outgoing HTTP checks.
enum HttpAuthType {
  none,
  basic,
  bearer,
  apiKey;

  String get labelKey => 'monitor.create.auth.type.$name';
}

/// Check frequency preset values.
enum CheckInterval {
  s30('30s', 30),
  m1('1m', 60),
  m5('5m', 300),
  m15('15m', 900),
  h1('1h', 3600);

  const CheckInterval(this.label, this.seconds);
  final String label;
  final int seconds;
}
