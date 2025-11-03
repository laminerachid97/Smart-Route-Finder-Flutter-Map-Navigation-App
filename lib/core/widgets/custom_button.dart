import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final bool cutTopsOnly;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = Colors.blue,
    this.cutTopsOnly = false
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: cutTopsOnly ? BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)) : BorderRadius.all(Radius.circular(12))
        ),
        padding: EdgeInsets.symmetric(vertical: 22, horizontal: 24)
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}