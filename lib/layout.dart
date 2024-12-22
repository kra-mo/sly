import 'package:flutter/material.dart';

isWide(BuildContext context) => MediaQuery.of(context).size.width > 600;
isTall(BuildContext context) => MediaQuery.of(context).size.height > 380;
