import 'package:fluttersdk_artisan/artisan.dart';

class HelloWorldCommand extends ArtisanCommand {
  @override
  String get name => 'HelloWorld'; // TODO: choose name, e.g. 'foo:bar'

  @override
  String get description => 'TODO: describe what this command does.';

  @override
  CommandBoot get boot => CommandBoot.none;

  @override
  Future<int> handle(ArtisanContext ctx) async {
    ctx.output.success('Hello from HelloWorldCommand');
    return 0;
  }
}
