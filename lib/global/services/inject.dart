import 'package:bingo/modules/home/presents/home_controller.dart';
import 'package:get_it/get_it.dart';

class Inject {
  static final Inject instance = Inject._();

  Inject._();

  Future<void> init() async {
    GetIt.I.registerFactory<HomeController>(() => HomeController());
  }
}
